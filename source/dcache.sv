`include "datapath_cache_if.vh"
`include "cache_control_if.vh"

`include "cpu_types_pkg.vh"

module dcache #(
    parameter SETS          = 8,
    parameter BLKS_PER_SET  = 2,  // Associativity
    parameter WORDS_PER_BLK = 2,
    parameter CPUID			= 0
) 
(
  input CLK, nRST,
  datapath_cache_if.dcache dcif,
  cache_control_if.dcache ccif
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

typedef enum logic [3:0] {
	IDLE = 4'b0000,
	READ = 4'b0001,
	WRITE = 4'b0010,
	ALLOC_RD = 4'b0011,
	ALLOC_WB = 4'b0100,
	HALT = 4'b0101,
	HALT_CNTR = 4'b0110,
	DONE = 4'b0111,
	SNOOP = 4'b1000,
	BUS_WB = 4'b1001
} state;

state cur_state;
state nxt_state;
logic mem_ready;
dcachef_t daddr, nxt_daddr, pre_daddr;
word_t nxt_data;
logic [DTAG_W-1:0] nxt_tag;
logic nxt_valid;
logic dirty;
logic nxt_dirty;
dblock_t lru_block;
logic nxt_lru;

dset_t sets[SETS];
logic [WORDS_PER_BLK:0] off_write;
logic [WORDS_PER_BLK:0] off_read;
logic [WORDS_PER_BLK:0] nxt_off_write;
logic [WORDS_PER_BLK:0] nxt_off_read;

logic [DIDX_W-1:0] set;
logic block;
logic nxt_block;
logic block_arb;
logic blkoff;
logic nxt_blkoff;
logic blkoff_arb;

logic [5:0] cop;
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
logic int_dhit;

// Flushing
logic flushed;
logic nxt_flushed;

// Cache operation variables
assign cop = ({dcif.halt, ccif.ccwait[CPUID], dcif.dmemREN, dcif.dmemWEN, dirty, int_dhit});
assign dp_read = (dcif.dmemREN & !dcif.dmemWEN);
assign dp_write = (dcif.dmemWEN & !dcif.dmemREN);

// Selection variables
//assign daddr = dcachef_t'(dcif.dmemaddr);//'
assign set = daddr.idx;
assign lru_block = sets[set].blocks[sets[set].lru];
assign dirty = lru_block.dirty;

// Variables for HALT state
assign set_cntr = halt_cntr[4:2];
assign block_cntr = halt_cntr[1];
assign word_cntr = halt_cntr[0];

// Hit Counter
word_t hit_cntr;
word_t nxt_hit_cntr;
logic quick_hit;
logic nxt_quick_hit;

// Bus
logic nxt_cctrans;

assign block_arb = (int_dhit)?(nxt_block):(block);
assign blkoff_arb = (int_dhit)?(daddr.blkoff):(blkoff);
always_ff @(posedge CLK, negedge nRST) begin
	if (!nRST) begin
		sets <= '{default: 0};//'
		cur_state <= IDLE;
		off_read <= '0;//'
		off_write <= '0;//'
		halt_cntr <= 0;
		blkoff <= 0;
		flushed <= 0;
		hit_cntr <= 0;
		daddr <= 0;
	end
	else begin
		sets[set].blocks[block_arb].data[blkoff_arb] <= nxt_data;
		sets[set].blocks[block_arb].tag <= nxt_tag;
		sets[set].blocks[block_arb].valid <= nxt_valid;
		sets[set].blocks[block_arb].dirty <= nxt_dirty;
		sets[set].lru <= nxt_lru;
		cur_state <= nxt_state;
		off_read <= nxt_off_read;
		off_write <= nxt_off_write;
		halt_cntr <= nxt_halt_cntr;
		block <= nxt_block;
		blkoff <= nxt_blkoff;
		flushed <= nxt_flushed;
		hit_cntr <= nxt_hit_cntr;
		quick_hit <= nxt_quick_hit;	
		daddr <= nxt_daddr;
		ccif.cctrans[CPUID] <= nxt_cctrans;
	end
end

//
// Next State Logic
//
always_comb begin
	casez(cur_state)
		IDLE: begin
			casez(cop)
				6'b10????: begin
					nxt_state = HALT;
				end
				6'b001010: begin
					nxt_state = ALLOC_WB;
				end 
				6'b000110: begin
					nxt_state = ALLOC_WB;
				end
				6'b000100: begin
					nxt_state = ALLOC_RD;
				end
				6'b001000: begin
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
		ALLOC_WB: begin
			if (mem_ready && off_write == WORDS_PER_BLK-1) begin
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
			if (mem_ready) begin
				nxt_state = DONE;
			end else begin
				nxt_state = HALT_CNTR;
			end
		end
		DONE: begin
			nxt_state = DONE;
		end
	endcase
end

// Output logic
assign dcif.dhit = int_dhit;
assign dcif.flushed = flushed;
assign int_dhit = 
			((daddr.tag == sets[daddr.idx].blocks[0].tag) && (sets[daddr.idx].blocks[0].valid)) ||
			((daddr.tag == sets[daddr.idx].blocks[1].tag) && (sets[daddr.idx].blocks[1].valid))
		;
assign mem_ready = !ccif.dwait[CPUID];

assign pre_daddr = dcachef_t'(dcif.dmemaddr);//'

always_comb begin
	ccif.dREN[CPUID] = 1'b0;
	ccif.dWEN[CPUID] = 1'b0;
	ccif.daddr[CPUID] = {daddr.tag, daddr.idx, off_read[0], 2'b00};
	ccif.dstore[CPUID] = sets[set].blocks[block_arb].data[blkoff];

	nxt_cctrans = 1'b0;
	ccif.ccwrite[CPUID] = 1'b0;

	dcif.dmemload = sets[set].blocks[block_arb].data[blkoff];
	
	nxt_off_read = 0;
	nxt_off_write = 0;
	nxt_halt_cntr = 0;
	nxt_hit_cntr = hit_cntr;

	nxt_data = sets[set].blocks[block_arb].data[blkoff_arb];
	nxt_blkoff = daddr.blkoff;
	nxt_tag = sets[set].blocks[block_arb].tag;
	nxt_valid = sets[set].blocks[block_arb].valid;
	nxt_dirty = sets[set].blocks[block_arb].dirty;
	nxt_lru = sets[set].lru;
	nxt_block = sets[set].lru;

	nxt_flushed = 1'b0;

	nxt_quick_hit = 1'b0;
	
	casez(cur_state)
		IDLE: begin
			// Reset counters
			nxt_off_read = 0;
			nxt_off_write = 0;
			nxt_halt_cntr = 0;
			nxt_quick_hit = 1'b1;
			nxt_daddr = pre_daddr;

			// Only do something if we have a valid command sent to the cache
			// AND we have a dhit
			if ((dp_write || dp_read) && int_dhit) begin
				// Least Recently Used (LRU) detection
				if (pre_daddr.tag == sets[pre_daddr.idx].blocks[0].tag) begin
					nxt_lru = 1'b1;
				end else if (pre_daddr.tag == sets[pre_daddr.idx].blocks[1].tag) begin
					nxt_lru = 1'b0;
				end
				
				// Increment the hit counter
				nxt_hit_cntr = (quick_hit && !dcif.halt)?(hit_cntr + 1):(hit_cntr);
				
				
				// Select the appropriate block
				if (pre_daddr.tag == sets[pre_daddr.idx].blocks[0].tag) begin
					nxt_block = 1'b0;
				end else if (pre_daddr.tag == sets[pre_daddr.idx].blocks[1].tag) begin
					nxt_block = 1'b1;
				end

				// Check whether we are reading or writing
				if (dp_read) begin
					// Send appropriate data to processor using:
					// - Address index (daddr.idx)
					// - Block that matches tag (nxt_block_sel)
					// - Address block offset (daddr.blkoff)
					dcif.dmemload = sets[pre_daddr.idx].blocks[nxt_block].data[pre_daddr.blkoff];
					//$display("C2P: m[%h] : c[%h:%h:%h] = %h", dcif.dmemaddr, set, block_arb, blkoff, dcif.dmemload);
				end else if (dp_write) begin
					// Write data to cache
					nxt_data = dcif.dmemstore;
					nxt_dirty = 1'b1;
					//$display("P2C: m[%h] : c[%h:%h:%h] <= %h", dcif.dmemaddr, set, block_arb, blkoff, dcif.dmemstore);
				end
			end else if(dp_write || dp_read) begin
				// There was a miss, but still a valid command,
				// so we prepare the block offset to be 0 for
				// the alloc/wb state, the selected block to be
				// the LRU block, and leave the hit counter alone.
				nxt_hit_cntr = hit_cntr;
				nxt_block = sets[set].lru;
				nxt_blkoff = 1'b0;
				nxt_cctrans = 1'b1;
			end
		end
		ALLOC_RD: begin
			// Send address and REN/WEN to memory controller
			ccif.daddr[CPUID] = {daddr.tag, daddr.idx, off_read[0], 2'b00};
			//ccif.daddr[CPUID] = 32'h00000000;
			ccif.dREN[CPUID] = 1'b1;
			ccif.dWEN[CPUID] = 1'b0;

			// Wait for memory to be readable
			if (mem_ready) begin
				// Strictly load data into the block
				nxt_off_read = off_read + 1;
				nxt_data = ccif.dload[CPUID];
				nxt_blkoff = nxt_off_read[0];

				// We now know everything has been written to cache from memory,
				// so we update the tag, set the block offset according to 
				// the address from the processor, validate the block, and
				// reset the dirty bit. This just determines when the last piece 
				// of data is written to the cache.
				if (off_read == WORDS_PER_BLK-1) begin
					nxt_blkoff = daddr.blkoff;
					nxt_tag = daddr.tag;
					nxt_valid = 1'b1;
					nxt_dirty = 1'b0;
					nxt_cctrans = 1'b0;
				end

				//$display("M2C: c[%h:%h:%h] <= %h = m[%h]", set, block_arb, blkoff, ccif.dload, ccif.daddr);
			end else begin
				nxt_off_read = off_read;
				nxt_data = sets[set].blocks[block_arb].data[blkoff_arb];
				nxt_tag = sets[set].blocks[block_arb].tag;
				nxt_valid = sets[set].blocks[block_arb].valid;
				nxt_dirty = sets[set].blocks[block_arb].dirty;
				nxt_blkoff = blkoff;
			end
		end
		ALLOC_WB: begin
			// Send address, data, and REN/WEN to memory controller
			ccif.daddr[CPUID] = {sets[set].blocks[block].tag, set, off_write[0], 2'b00};
			ccif.dstore[CPUID] = sets[set].blocks[block].data[blkoff];
			ccif.dREN[CPUID] = 1'b0;
			ccif.dWEN[CPUID] = 1'b1;
			nxt_cctrans = 1'b1;
			

			if (mem_ready) begin
				nxt_off_write = off_write + 1;
				nxt_blkoff = nxt_off_write[0];

				// We now know that everything has been writen back to memory,
				// so we just set the block offset to be 0 since we have to
				// go directly to the allocate state.
				if (off_write == WORDS_PER_BLK-1) begin
					//nxt_blkoff = daddr.blkoff;
					nxt_blkoff = 1'b0;
				end
			end else begin
				nxt_off_write = off_write;
				nxt_blkoff = blkoff;
			end

			//$display("C2M: c[%h:%h:%h] = %h => m[%h]", set, block_arb, blkoff, ccif.dstore, ccif.daddr);
		end
		HALT: begin
			// Send address, data, and REN/WEN to memory controller
			ccif.daddr[CPUID] = {sets[set_cntr].blocks[block_cntr].tag, set_cntr, word_cntr, 2'b00};
			ccif.dstore[CPUID] = sets[set_cntr].blocks[block_cntr].data[word_cntr];

			// Also invalidate all blocks
			nxt_valid = 1'b0;

			// Wait for memory controller to write successfully and keep 
			// incrementing counter to keep iterating through cache blocks.
			if (!ccif.ccwait[CPUID] && (!sets[set_cntr].blocks[block_cntr].dirty || mem_ready) && halt_cntr != 32) begin
				nxt_halt_cntr = halt_cntr + 1;
			end else begin
				nxt_halt_cntr = halt_cntr;
			end

			// Only write back to memory if the block is dirty
			if (!ccif.ccwait[CPUID] && sets[set_cntr].blocks[block_cntr].dirty) begin
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b1;
				//$display("Writing %h to %h", ccif.dstore, ccif.daddr);
				//$display("MWb: m[%h] <= c[%h:%h:%h] = %h", ccif.daddr, set_cntr, block_cntr, word_cntr, ccif.dstore);
			end else begin
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b0;
			end
		end
		HALT_CNTR: begin
			ccif.daddr[CPUID] = 32'h00003100;
			ccif.dstore[CPUID] = hit_cntr;
			ccif.dREN[CPUID] = 1'b0;
			ccif.dWEN[CPUID] = 1'b1;
			if (mem_ready) begin
				nxt_flushed = 1'b1;
			end
		end
		DONE: begin
			nxt_flushed = 1'b1;
		end
	endcase
end

endmodule