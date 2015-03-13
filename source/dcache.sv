`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

`include "cpu_types_pkg.vh"

module dcache #(
    parameter SETS          = 8,
    parameter BLKS_PER_SET  = 2,  // Associativity
    parameter WORDS_PER_BLK = 2
) 
(
  input CLK, nRST,
  datapath_cache_if.cache dcif,
  cache_control_if.caches ccif
);

  // import types
  import cpu_types_pkg::*;

typedef enum logic [2:0] {
	IDLE = 3'b000,
	READ = 3'b001,
	ALLOCATE = 3'b010,
	WRITE = 3'b011,
	HALT_WB = 3'b100,
	HALT = 3'b101
} state;
logic [WORDS_PER_BLK:0] off_write;
logic [WORDS_PER_BLK:0] off_read;
logic [WORDS_PER_BLK:0] nxt_off_write;
logic [WORDS_PER_BLK:0] nxt_off_read;

typedef struct packed {
    logic valid;
    logic dirty;
    logic [ITAG_W-1:0] tag;
    word_t [WORDS_PER_BLK-1:0] data; // Accessed through block offset
} dblock_t;

typedef struct {
	dblock_t blocks[BLKS_PER_SET];
	logic lru;
} dset_t;
  
dcachef_t daddr;
assign daddr = icachef_t'(dcif.dmemaddr);//'
dset_t sets[SETS]; // Accessed through index

logic [IIDX_W-1:0] set_sel;
logic block_sel;
logic data_sel;
logic nxt_data_sel;
logic cache_write;
word_t nxt_data;
logic [ITAG_W-1:0] nxt_tag;
logic nxt_valid;
logic nxt_dirty;
logic nxt_lru;

logic mem_ready, dhit, miss, dirty;

state cur_state, nxt_state;

dblock_t lru_block;
assign lru_block = sets[set_sel].blocks[sets[set_sel].lru];

logic dp_read, dp_write;
assign dp_read = dcif.dmemREN & !dcif.dmemWEN;
assign dp_write = dcif.dmemWEN & !dcif.dmemREN;

assign set_sel = daddr.idx;
assign block_sel = sets[set_sel].lru;
//assign data_sel = WORDS_PER_BLK - daddr.blkoff;


// Halt Write Back Counters
logic [2:0] set_cntr;
logic block_cntr;
logic word_cntr;
logic [2:0] nxt_set_cntr;
logic nxt_block_cntr;
logic nxt_word_cntr;
logic [4:0] halt_cntr;
logic [4:0] nxt_halt_cntr;
assign set_cntr = halt_cntr[4:2];
assign block_cntr = halt_cntr[1];
assign word_cntr = halt_cntr[0];


always_ff @(posedge CLK, negedge nRST) begin
	if (!nRST) begin
		cur_state <= IDLE;
		off_read <= '0;//'
		off_write <= '0;//'
		sets <= '{default: 0};//'
		data_sel <= 0;
		//set_cntr <= 0;
		//block_cntr <= 0;
		//word_cntr <= 0;
		halt_cntr <= 0;
	end
	else begin
		cur_state <= nxt_state;
		off_read <= nxt_off_read;
		off_write <= nxt_off_write;
		sets[set_sel].blocks[block_sel].data[data_sel] <= nxt_data;
		sets[set_sel].blocks[block_sel].tag <= nxt_tag;
		sets[set_sel].blocks[block_sel].valid <= nxt_valid;
		sets[set_sel].blocks[block_sel].dirty <= nxt_dirty;
		data_sel <= nxt_data_sel;
		sets[set_sel].lru <= nxt_lru;

		//set_cntr <= nxt_set_cntr;
		//block_cntr <= nxt_block_cntr;
		//word_cntr <= nxt_word_cntr;
		halt_cntr <= nxt_halt_cntr;
	end
end

//
// Next State Logic
//
always_comb begin
	casez(cur_state)
		IDLE: begin
			if (dcif.halt) begin
				nxt_state = HALT_WB;
			end else if (dp_read || dp_write) begin
				nxt_state = READ;
			end else begin
				nxt_state = IDLE;
			end
		end
		READ: begin
			if (dhit) begin
				nxt_state = IDLE;
			end else if(dirty) begin
				nxt_state = WRITE;
			end else begin
				nxt_state = ALLOCATE;
			end
		end
		ALLOCATE: begin
			if (mem_ready && off_read == WORDS_PER_BLK-1) begin
				nxt_state = READ;
			end else begin
				nxt_state = ALLOCATE;
			end
		end
		WRITE: begin
			if (mem_ready && off_write == WORDS_PER_BLK-1) begin
				nxt_state = ALLOCATE;
			end else begin
				nxt_state = WRITE;
			end
		end
		HALT_WB: begin
			if (set_cntr == 3'b111 && block_cntr == 1'b1 && word_cntr == 1'b1) begin
				nxt_state = HALT;
			end else begin
				nxt_state = HALT_WB;
			end
		end
		HALT: begin
			nxt_state = HALT;
		end
	endcase
end

// Output logic

always_comb begin
	mem_ready = !ccif.dwait;
	nxt_off_read = 0;
	nxt_off_write = 0;
	nxt_data = sets[set_sel].blocks[block_sel].data[data_sel];
	nxt_data_sel = daddr.blkoff;
	nxt_tag = sets[set_sel].blocks[block_sel].tag;
	nxt_valid = sets[set_sel].blocks[block_sel].valid;
	nxt_dirty = sets[set_sel].blocks[block_sel].dirty;
	nxt_lru = sets[set_sel].lru;
	//nxt_set_cntr = 0;
	//nxt_block_cntr = 0;
	//nxt_word_cntr = 0;
	nxt_halt_cntr = 0;
	casez(cur_state)
		IDLE: begin
			dhit = 1'b0;
			dirty = 0;
			nxt_off_read = 0;
			nxt_off_write = 0;
		end
		READ: begin
			dhit = 
				((daddr.tag == sets[daddr.idx].blocks[0].tag) && (sets[daddr.idx].blocks[0].valid)) ||
				((daddr.tag == sets[daddr.idx].blocks[1].tag) && (sets[daddr.idx].blocks[1].valid))
			;
			dirty = lru_block.dirty;
			nxt_off_read = 0;
			nxt_off_write = 0;

			if (dhit && (daddr.tag == sets[daddr.idx].blocks[0].tag)) begin
				nxt_lru = 1'b1;
				dcif.dmemload = sets[set_sel].blocks[block_sel].data[data_sel];
			end else if (dhit && (daddr.tag == sets[daddr.idx].blocks[1].tag)) begin
				nxt_lru = 1'b0;
			end

			if (dhit && dp_read) begin
				dcif.dmemload = sets[set_sel].blocks[block_sel].data[data_sel];
			end else if (dhit && dp_write) begin
				nxt_data = dcif.dmemstore;
				nxt_dirty = 1'b1;
			end

		end
		ALLOCATE: begin
			ccif.daddr = (dcif.dmemaddr&32'hFFFFFFFE) + off_read;
			ccif.dREN = dcif.dmemREN;
			ccif.dWEN = dcif.dmemWEN;
			if (mem_ready) begin
				nxt_off_read = off_read + 1;
				nxt_data = ccif.dload;
				nxt_tag = daddr.tag;
				nxt_valid = 1'b1;
				nxt_dirty = 1'b0;
				nxt_data_sel = data_sel + off_read + 1;
			end else begin
				nxt_off_read = off_read;
				nxt_data = sets[set_sel].blocks[block_sel].data[data_sel];
				nxt_tag = sets[set_sel].blocks[block_sel].tag;
				nxt_valid = sets[set_sel].blocks[block_sel].valid;
				nxt_dirty = sets[set_sel].blocks[block_sel].dirty;
				nxt_data_sel = data_sel;
			end

		end
		WRITE: begin
			ccif.daddr = {sets[set_sel].blocks[block_sel].tag,set_sel,off_write,2'b00};
			ccif.dREN = dcif.dmemREN;
			ccif.dWEN = dcif.dmemWEN;
			ccif.dstore = sets[set_sel].blocks[block_sel].data[data_sel];
			if (mem_ready) begin
				nxt_off_write = off_write + 1;
				nxt_data_sel = data_sel + off_read + 1;
			end else begin
				nxt_off_write = off_write;
				nxt_data_sel = data_sel;
			end
		end
		HALT_WB: begin
			ccif.daddr = {sets[set_cntr].blocks[block_cntr].tag,set_cntr,block_cntr,2'b00};
			ccif.dstore = sets[set_cntr].blocks[block_cntr].data[word_cntr];
			/*
			if (mem_ready) begin
				if (word_cntr == WORDS_PER_BLK-1) begin
					nxt_word_cntr = 0;
					if (block_cntr == BLKS_PER_SET-1) begin
						nxt_block_cntr = 0;
						if (set_cntr == SETS-1) begin
							nxt_set_cntr = 0;
						end else begin
							nxt_set_cntr = set_cntr + 1;
						end
					end else begin
						nxt_block_cntr = block_cntr + 1;
					end
				end else begin
					nxt_word_cntr = word_cntr + 1;
				end
			end else begin
				nxt_set_cntr = set_cntr;
				nxt_block_cntr = block_cntr;
				nxt_word_cntr = word_cntr;
			end
			*/
			if (mem_ready) begin
				if (halt_cntr != 31) begin
					nxt_halt_cntr = halt_cntr + 1;
				end else begin
					nxt_halt_cntr = halt_cntr;
				end
			end

			if (sets[set_cntr].blocks[block_cntr].dirty) begin
				ccif.dREN = 1'b0;
				ccif.dWEN = 1'b1;
			end else begin
				ccif.dREN = 1'b0;
				ccif.dWEN = 1'b0;
			end
		end
	endcase
end

endmodule