`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

`include "cpu_types_pkg.vh"

module icache #(
	parameter SETS = 16,
	parameter BLKS_PER_SET = 1, // Associativity
	parameter WORDS_PER_BLK = 1,
    parameter CPUID			= 0
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
} dblock_t;

typedef struct {
	dblock_t blocks[BLKS_PER_SET];
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

state cur_state;
state nxt_state;
logic mem_ready;
icachef_t iaddr;
word_t nxt_data;
logic [ITAG_W-1:0] nxt_tag;
logic nxt_valid;

dset_t sets[SETS];
logic [WORDS_PER_BLK:0] off_write;
logic [WORDS_PER_BLK:0] off_read;
logic [WORDS_PER_BLK:0] nxt_off_write;
logic [WORDS_PER_BLK:0] nxt_off_read;

logic [IIDX_W-1:0] set;
logic block;
logic nxt_block;
logic block_arb;

logic [4:0] cop;
logic dp_read;
logic dp_write;

// Halt Write Back Counters
logic [2:0] set_cntr;
logic block_cntr;
logic word_cntr;
logic [2:0] nxt_set_cntr;
logic nxt_block_cntr;
logic nxt_word_cntr;
logic [5:0] halt_cntr;
logic [5:0] nxt_halt_cntr;
logic int_ihit;


// Cache operation variables

assign cop = ({1'b0, dcif.imemREN, 1'b0, 1'b0, int_ihit});
assign dp_read = dcif.imemREN;
assign dp_write = 1'b0;

// Selection variables
assign iaddr = icachef_t'(dcif.imemaddr);//'
assign set = iaddr.idx;

// Variables for HALT state
assign set_cntr = halt_cntr[4:2];
assign block_cntr = halt_cntr[1];
assign word_cntr = halt_cntr[0];

// Hit Counter
word_t hit_cntr;
word_t nxt_hit_cntr;
logic quick_hit;
logic nxt_quick_hit;


//assign block_arb = (int_ihit)?(nxt_block):(block);
assign block_arb = 1'b0;
always_ff @(posedge CLK, negedge nRST) begin
	if (!nRST) begin
		sets <= '{default: 0};//'
		cur_state <= IDLE;
		off_read <= '0;//'
		off_write <= '0;//'
		halt_cntr <= 0;
		hit_cntr <= 0;
	end
	else begin
		sets[set].blocks[block_arb].data[0] <= nxt_data;
		sets[set].blocks[block_arb].tag <= nxt_tag;
		sets[set].blocks[block_arb].valid <= nxt_valid;
		cur_state <= nxt_state;
		off_read <= nxt_off_read;
		off_write <= nxt_off_write;
		halt_cntr <= nxt_halt_cntr;
		block <= nxt_block;
		hit_cntr <= nxt_hit_cntr;
		quick_hit <= nxt_quick_hit;	
	end
end

//
// Next State Logic
//
always_comb begin
	casez(cur_state)
		IDLE: begin
			casez(cop)
				5'b01000: begin
					nxt_state = ALLOC_RD;
				end
				default: begin
					nxt_state = IDLE;
				end
			endcase
		end
		ALLOC_RD: begin
			if (mem_ready && off_read == WORDS_PER_BLK-1) begin
				nxt_state = IDLE;
			end else begin
				nxt_state = ALLOC_RD;
			end
		end
	endcase
end

// Output logic
assign dcif.ihit = int_ihit;
assign int_ihit = 
			((iaddr.tag == sets[iaddr.idx].blocks[0].tag) && (sets[iaddr.idx].blocks[0].valid));
assign mem_ready = !ccif.iwait[CPUID];

always_comb begin
	ccif.iREN[CPUID] = 1'b0;
	ccif.iaddr[CPUID] = {iaddr.tag, iaddr.idx, 2'b00};

	dcif.imemload = sets[set].blocks[block_arb].data[0];
	
	nxt_off_read = 0;
	nxt_off_write = 0;
	nxt_halt_cntr = 0;
	nxt_hit_cntr = hit_cntr;

	nxt_data = sets[set].blocks[block_arb].data[0];
	nxt_tag = sets[set].blocks[block_arb].tag;
	nxt_valid = sets[set].blocks[block_arb].valid;
	nxt_block = 1'b0;

	nxt_quick_hit = 1'b0;
	
	casez(cur_state)
		IDLE: begin
			// Reset counters
			nxt_off_read = 0;
			nxt_off_write = 0;
			nxt_halt_cntr = 0;
			nxt_quick_hit = 1'b1;

			// Only do something if we have a valid command sent to the cache
			// AND we have a ihit
			if ((dp_read) && int_ihit) begin
				
				// Increment the hit counter
				nxt_hit_cntr = (quick_hit)?(hit_cntr + 1):(hit_cntr);
				
				
				// Select the appropriate block
				if (iaddr.tag == sets[iaddr.idx].blocks[0].tag) begin
					nxt_block = 1'b0;
				end

				// Check whether we are reading or writing
				if (dp_read) begin
					// Send appropriate data to processor using:
					// - Address index (iaddr.idx)
					// - Block that matches tag (nxt_block_sel)
					// - Address block offset (iaddr.blkoff)
					dcif.imemload = sets[iaddr.idx].blocks[nxt_block].data[0];
					//$display("C2P: m[%h] : c[%h:%h:%h] = %h", dcif.dmemaddr, set, block_arb, blkoff, dcif.imemload);
				end
			end else if(dp_read) begin
				// There was a miss, but still a valid command,
				// so we prepare the block offset to be 0 for
				// the alloc/wb state, the selected block to be
				// the LRU block, and leave the hit counter alone.
				nxt_hit_cntr = hit_cntr;
			end
		end
		ALLOC_RD: begin
			// Send address and REN/WEN to memory controller
			ccif.iaddr[CPUID] = {iaddr.tag, iaddr.idx, 2'b00};
			ccif.iREN[CPUID] = 1'b1;

			// Wait for memory to be readable
			if (mem_ready) begin
				// Strictly load data into the block
				nxt_off_read = off_read + 1;
				nxt_data = ccif.iload[CPUID];
				//nxt_data = 32'hDEADBEEF;

				// We now know everything has been written to cache from memory,
				// so we update the tag, set the block offset according to 
				// the address from the processor, validate the block, and
				// reset the dirty bit. This just determines when the last piece 
				// of data is written to the cache.
				if (off_read == WORDS_PER_BLK-1) begin
					nxt_tag = iaddr.tag;
					nxt_valid = 1'b1;
					ccif.iREN[CPUID] = 1'b0;
				end

				//$display("M2C: c[%h:%h:%h] <= %h = m[%h]", set, block_arb, blkoff, ccif.dload, ccif.iaddr);
			end else begin
				nxt_off_read = off_read;
				nxt_data = sets[set].blocks[block_arb].data[0];
				nxt_tag = sets[set].blocks[block_arb].tag;
				nxt_valid = sets[set].blocks[block_arb].valid;
			end
		end
	endcase
end

endmodule