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

typedef enum logic [2:0] {
	IDLE = 3'b000,
	READ = 3'b001,
	WRITE = 3'b010,
	ALLOC_RD = 3'b011,
	ALLOC_WB = 3'b100,
	HALT = 3'b101,
	HALT_CNTR = 3'b110
} state;
  
dcachef_t daddr;
dset_t sets[SETS]; // Accessed through index
logic [WORDS_PER_BLK:0] off_write;
logic [WORDS_PER_BLK:0] off_read;
logic [WORDS_PER_BLK:0] nxt_off_write;
logic [WORDS_PER_BLK:0] nxt_off_read;
logic [DIDX_W-1:0] set_sel;
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
logic dp_read, dp_write;
logic nxt_block_sel;
state cur_state, nxt_state;
dblock_t lru_block;
// Halt Write Back Counters
logic [2:0] set_cntr;
logic block_cntr;
logic word_cntr;
logic [2:0] nxt_set_cntr;
logic nxt_block_cntr;
logic nxt_word_cntr;
logic [5:0] halt_cntr;
logic [5:0] nxt_halt_cntr;
logic nxt_dhit;
logic int_dhit;
// Flushing
logic flushed;
logic nxt_flushed;

// Cache operation variables
cacheop_t cop;
assign cop = cacheop_t'({dcif.halt, dcif.dmemREN, dcif.dmemWEN, dirty, int_dhit});//'
assign dp_read = (dcif.dmemREN & !dcif.dmemWEN);
assign dp_write = (dcif.dmemWEN & !dcif.dmemREN);

// Selection variables
assign daddr = icachef_t'(dcif.dmemaddr);//'
assign set_sel = daddr.idx;
assign lru_block = sets[set_sel].blocks[sets[set_sel].lru];
assign dirty = lru_block.dirty;

// Variables for HALT state
assign set_cntr = halt_cntr[4:2];
assign block_cntr = halt_cntr[1];
assign word_cntr = halt_cntr[0];

// Hit Counter
word_t hit_cntr;
word_t nxt_hit_cntr;

always_ff @(posedge CLK, negedge nRST) begin
	if (!nRST) begin
		cur_state <= IDLE;
		off_read <= '0;//'
		off_write <= '0;//'
		sets <= '{default: 0};//'
		data_sel <= 0;
		halt_cntr <= 0;
		flushed <= 0;
		dhit <= 0;
		hit_cntr <= 0;
	end
	else begin
		cur_state <= nxt_state;
		off_read <= nxt_off_read;
		off_write <= nxt_off_write;
		halt_cntr <= nxt_halt_cntr;
		flushed <= nxt_flushed;
		sets[set_sel].blocks[block_sel].data[data_sel] <= nxt_data;
		sets[set_sel].blocks[block_sel].tag <= nxt_tag;
		sets[set_sel].blocks[block_sel].valid <= nxt_valid;
		sets[set_sel].blocks[block_sel].dirty <= nxt_dirty;
		data_sel <= nxt_data_sel;
		block_sel <= nxt_block_sel;
		sets[set_sel].lru <= nxt_lru;
		dhit <= nxt_dhit;
		hit_cntr <= nxt_hit_cntr;
	end
end

//
// Next State Logic
//
always_comb begin
	casez(cur_state)
		IDLE: begin
			casez(cop)
				5'b1????: begin
					nxt_state = HALT;
				end
				5'b01001: begin
					nxt_state = READ;
				end
				5'b01011: begin
					nxt_state = READ;
				end
				5'b00111: begin
					nxt_state = WRITE;
				end
				5'b00101: begin
					nxt_state = WRITE;
				end
				5'b01010: begin
					nxt_state = ALLOC_WB;
				end 
				5'b00110: begin
					nxt_state = ALLOC_WB;
				end
				5'b00100: begin
					nxt_state = ALLOC_RD;
				end
				5'b01000: begin
					nxt_state = ALLOC_RD;
				end
				default: begin
					nxt_state = IDLE;
				end
			endcase
		end
		READ: begin
			nxt_state = IDLE;
		end
		WRITE: begin
			nxt_state = IDLE;
		end
		ALLOC_RD: begin
			if (mem_ready && off_read == WORDS_PER_BLK-1) begin
				nxt_state = (dp_write)?(WRITE):(READ);
			end else begin
				nxt_state = ALLOC_RD;
			end
		end
		ALLOC_WB: begin
			if (mem_ready && off_write == WORDS_PER_BLK-1) begin
				//nxt_state = (dp_write)?(WRITE):(ALLOC_RD);
				nxt_state = ALLOC_RD;
			end else begin
				nxt_state = ALLOC_WB;
			end
		end
		HALT: begin
			if (halt_cntr != 32) begin
				nxt_state = HALT;
			end else begin
				nxt_state = HALT_CNTR;
			end
		end
		HALT_CNTR: begin
			nxt_state = HALT_CNTR;
		end
	endcase
end

// Output logic
assign dcif.dhit = dhit;
assign dcif.flushed = flushed;
assign int_dhit = 
			((daddr.tag == sets[daddr.idx].blocks[0].tag) && (sets[daddr.idx].blocks[0].valid)) ||
			((daddr.tag == sets[daddr.idx].blocks[1].tag) && (sets[daddr.idx].blocks[1].valid))
		;
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
	nxt_halt_cntr = 0;
	nxt_dhit = 1'b0;
	nxt_block_sel = sets[set_sel].lru;
	nxt_flushed = 1'b0;
	ccif.dREN = 1'b0;
	ccif.dWEN = 1'b0;
	nxt_hit_cntr = hit_cntr;
	ccif.daddr = {daddr.tag, daddr.idx, off_read[0], 2'b00};
	dcif.dmemload = sets[set_sel].blocks[block_sel].data[data_sel];
	ccif.dstore = sets[set_sel].blocks[block_sel].data[data_sel];

	casez(cur_state)
		IDLE: begin
			nxt_off_read = 0;
			nxt_off_write = 0;
			nxt_halt_cntr = 0;
			
			
			//if (!dcif.halt && dp_write && !dirty) begin
			//	nxt_dhit = 1'b1;
			//end else begin
			//	nxt_dhit = int_dhit;
			//end
			nxt_dhit = ((dp_write || dp_read) && !dcif.halt)?(int_dhit):(1'b0);
			nxt_hit_cntr = (nxt_dhit && (dp_write || dp_read) && !dcif.halt)?(hit_cntr + 1):(hit_cntr);

			// Select the appropriate block
			if (daddr.tag == sets[daddr.idx].blocks[0].tag) begin
				nxt_block_sel = 1'b0;
			end else if (daddr.tag == sets[daddr.idx].blocks[1].tag) begin
				nxt_block_sel = 1'b1;
			end

			// Select the appropriate data
			if (cop == cacheop_t'(5'b01000)) begin
				nxt_data_sel = nxt_off_read;
			end else if (cop == cacheop_t'(5'b00110) || cop == cacheop_t'(5'b01010)) begin
				nxt_data_sel = nxt_off_write;
			end
		end
		READ: begin
			// If we are in this state, then we know we had a dhit
			dcif.dmemload = sets[set_sel].blocks[block_sel].data[data_sel];
			//nxt_tag = daddr.tag;

			// LRU Logic
			if (daddr.tag == sets[daddr.idx].blocks[0].tag) begin
				nxt_lru = 1'b1;
			end else if (daddr.tag == sets[daddr.idx].blocks[1].tag) begin
				nxt_lru = 1'b0;
			end
		end
		WRITE: begin
			nxt_data = dcif.dmemstore;
			nxt_tag = daddr.tag;
			nxt_dirty = 1'b1;
			nxt_valid = 1'b1;

			// LRU Logic
			if (daddr.tag == sets[daddr.idx].blocks[0].tag) begin
				nxt_lru = 1'b1;
			end else if (daddr.tag == sets[daddr.idx].blocks[1].tag) begin
				nxt_lru = 1'b0;
			end
		end
		ALLOC_RD: begin
			ccif.daddr = {daddr.tag, daddr.idx, off_read[0], 2'b00};
			ccif.dREN = 1'b1;
			ccif.dWEN = 1'b0;
			if (mem_ready) begin
				nxt_off_read = off_read + 1;
				nxt_data = ccif.dload;
				nxt_tag = daddr.tag;
				nxt_valid = 1'b1;
				nxt_dirty = 1'b0;
				nxt_data_sel = nxt_off_read[0];
			end else begin
				nxt_off_read = off_read;
				nxt_data = sets[set_sel].blocks[block_sel].data[data_sel];
				nxt_tag = sets[set_sel].blocks[block_sel].tag;
				nxt_valid = sets[set_sel].blocks[block_sel].valid;
				nxt_dirty = sets[set_sel].blocks[block_sel].dirty;
				nxt_data_sel = data_sel;
			end

			// Prepare dhit for datapath
			if (mem_ready && off_read == WORDS_PER_BLK-1) begin
				nxt_dhit = int_dhit;
				nxt_data_sel = daddr.blkoff;
			end
			
		end
		ALLOC_WB: begin
			//$display("%h", sets[set_sel].blocks[block_sel].tag);
			//$display("%b-%b-%b-%b", sets[set_sel].blocks[block_sel].tag, set_sel, off_write[0], 2'b00);
			//$display("%h", {sets[set_sel].blocks[block_sel].tag, set_sel, off_write[0], 2'b00});
			ccif.daddr = {sets[set_sel].blocks[block_sel].tag, set_sel, off_write[0], 2'b00};
			ccif.dREN = 1'b0;
			ccif.dWEN = 1'b1;
			ccif.dstore = sets[set_sel].blocks[block_sel].data[data_sel];
			if (mem_ready) begin
				nxt_off_write = off_write + 1;
				nxt_data_sel = nxt_off_write[0];
			end else begin
				nxt_off_write = off_write;
				nxt_data_sel = data_sel;
			end

			// Prepare dhit for datapath
			if (dp_write && mem_ready && off_write == WORDS_PER_BLK-1) begin
				//nxt_dhit = 1'b1;
				nxt_data_sel = daddr.blkoff;
			end
		end
		HALT: begin
			ccif.daddr = {sets[set_cntr].blocks[block_cntr].tag,set_cntr,word_cntr,2'b00};
			ccif.dstore = sets[set_cntr].blocks[block_cntr].data[word_cntr];
			nxt_valid = 1'b0;
			if ((!sets[set_cntr].blocks[block_cntr].dirty || mem_ready) && halt_cntr != 32) begin
				nxt_halt_cntr = halt_cntr + 1;
			end else begin
				nxt_halt_cntr = halt_cntr;
			end

			//if (halt_cntr == 31) begin
			//	nxt_flushed = 1'b1;
			//end

			if (sets[set_cntr].blocks[block_cntr].dirty) begin
				ccif.dREN = 1'b0;
				ccif.dWEN = 1'b1;
			end else begin
				ccif.dREN = 1'b0;
				ccif.dWEN = 1'b0;
			end
		end
		HALT_CNTR: begin
			ccif.daddr = 32'h00003100;
			ccif.dstore = hit_cntr;
			ccif.dREN = 1'b0;
			ccif.dWEN = 1'b1;
			if (mem_ready) begin
				nxt_halt_cntr = halt_cntr + 1;
			end
			if (halt_cntr == 33) begin
				nxt_flushed = 1'b1;
			end
		end
	endcase
end

endmodule