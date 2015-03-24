`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

`include "cpu_types_pkg.vh"

module icache #(
    parameter SETS          = 16,
    parameter BLKS_PER_SET  = 1,  // Associativity
    parameter WORDS_PER_BLK = 1
) 
(
  input CLK, nRST,
  datapath_cache_if.icache dcif,
  cache_control_if.icache ccif
);

  // import types
  import cpu_types_pkg::*;

typedef struct packed {
    logic valid;
    logic [ITAG_W-1:0] tag;
    word_t [WORDS_PER_BLK-1:0] data; // Accessed through block offset
} iblock_t;

typedef struct {
	iblock_t blocks[BLKS_PER_SET];
} iset_t;

typedef enum logic [2:0] {
	IDLE = 3'b000,
	READ = 3'b001,
	WRITE = 3'b010,
	ALLOC_RD = 3'b011,
	ALLOC_WB = 3'b100,
	HALT = 3'b101
} state;
  
icachef_t iaddr;
iset_t sets[SETS]; // Accessed through index
logic [WORDS_PER_BLK:0] off_write;
logic [WORDS_PER_BLK:0] off_read;
logic [WORDS_PER_BLK:0] nxt_off_write;
logic [WORDS_PER_BLK:0] nxt_off_read;
logic [IIDX_W-1:0] set_sel;
logic block_sel;
logic data_sel;
logic nxt_data_sel;
logic cache_write;
word_t nxt_data;
logic [ITAG_W-1:0] nxt_tag;
logic nxt_valid;
logic mem_ready, ihit;
logic dp_read, dp_write;
logic nxt_block_sel;
state cur_state, nxt_state;
// Halt Write Back Counters
logic [2:0] set_cntr;
logic block_cntr;
logic word_cntr;
logic [2:0] nxt_set_cntr;
logic nxt_block_cntr;
logic nxt_word_cntr;
logic [4:0] halt_cntr;
logic [4:0] nxt_halt_cntr;
logic nxt_ihit;
logic int_ihit;

// Cache operation variables
cacheop_t cop;
assign cop = cacheop_t'({1'b0, dcif.imemREN, 1'b0, 1'b0, int_ihit});//'
assign dp_read = (dcif.imemREN);
assign dp_write = 1'b0;

// Selection variables
assign iaddr = icachef_t'(dcif.imemaddr);//'
assign set_sel = iaddr.idx;

// Variables for HALT state
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
		halt_cntr <= 0;
		ihit <= 0;
	end
	else begin
		cur_state <= nxt_state;
		off_read <= nxt_off_read;
		off_write <= nxt_off_write;
		halt_cntr <= nxt_halt_cntr;
		sets[set_sel].blocks[block_sel].data[data_sel] <= nxt_data;
		sets[set_sel].blocks[block_sel].tag <= nxt_tag;
		sets[set_sel].blocks[block_sel].valid <= nxt_valid;
		data_sel <= nxt_data_sel;
		block_sel <= nxt_block_sel;
		ihit <= nxt_ihit;
	end
end

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
		ALLOC_RD: begin
			if (mem_ready && off_read == WORDS_PER_BLK-1) begin
				nxt_state = READ;
			end else begin
				nxt_state = ALLOC_RD;
			end
		end
		HALT: begin
			nxt_state = HALT;
		end
	endcase
end

// Output logic
assign dcif.ihit = ihit;
assign int_ihit = 
			((iaddr.tag == sets[iaddr.idx].blocks[0].tag) && (sets[iaddr.idx].blocks[0].valid))
		;
always_comb begin
	mem_ready = !ccif.iwait;
	nxt_off_read = 0;
	nxt_off_write = 0;
	nxt_data = sets[set_sel].blocks[block_sel].data[data_sel];
	nxt_data_sel = 1'b0;
	nxt_tag = sets[set_sel].blocks[block_sel].tag;
	nxt_valid = sets[set_sel].blocks[block_sel].valid;
	nxt_halt_cntr = 0;
	nxt_ihit = 1'b0;
	ccif.iREN = 1'b0;
	ccif.iaddr = {iaddr.tag, iaddr.idx, 2'b00};
	dcif.imemload = sets[set_sel].blocks[block_sel].data[data_sel];
	nxt_block_sel = 1'b0;
	
	casez(cur_state)
		IDLE: begin
			nxt_off_read = 0;
			nxt_off_write = 0;
			nxt_halt_cntr = 0;
			
			//if (!dcif.halt && dp_write) begin
			//	nxt_ihit = 1'b1;
			//end else begin
			//	nxt_ihit = int_ihit;
			//end
			nxt_ihit = (dp_read)?(int_ihit):(1'b0);
			//nxt_hit_cntr = (nxt_ihit && (dp_write || dp_read) && !dcif.halt)?(hit_cntr + 1):(hit_cntr);

			// Select the appropriate block
			if (iaddr.tag == sets[iaddr.idx].blocks[0].tag) begin
				nxt_block_sel = 1'b0;
			end

			// Select the appropriate data
			if (cop == cacheop_t'(5'b01000)) begin
				nxt_data_sel = nxt_off_read;
			end
		end
		READ: begin
			// If we are in this state, then we know we had a ihit
			dcif.imemload = sets[set_sel].blocks[block_sel].data[data_sel];
			nxt_tag = iaddr.tag;
		end
		ALLOC_RD: begin
			ccif.iaddr = {iaddr.tag, iaddr.idx, 2'b00};
			ccif.iREN = 1'b1;
			if (mem_ready) begin
				nxt_off_read = off_read + 1;
				nxt_data = ccif.iload;
				nxt_tag = iaddr.tag;
				nxt_valid = 1'b1;
				nxt_data_sel = nxt_off_read[0];
			end else begin
				nxt_off_read = off_read;
				nxt_data = sets[set_sel].blocks[block_sel].data[data_sel];
				nxt_tag = sets[set_sel].blocks[block_sel].tag;
				nxt_valid = sets[set_sel].blocks[block_sel].valid;
				nxt_data_sel = data_sel;
			end

			// Prepare ihit for datapath
			if (mem_ready && off_read == WORDS_PER_BLK-1) begin
				// HACK
				// Possibly just move this to READ/WRITE state
				nxt_ihit = 1'b1;
				nxt_data_sel = 1'b0;
			end
			
		end
		HALT: begin
			if (halt_cntr != 31) begin
				nxt_halt_cntr = halt_cntr + 1;
			end else begin
				nxt_halt_cntr = halt_cntr;
			end
			nxt_valid = 1'b0;
		end
	endcase
end

endmodule