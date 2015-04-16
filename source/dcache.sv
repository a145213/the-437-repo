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
	BUS_WB = 4'b1001,
	ALLOC_RD_WAIT = 4'b1010,
	HALT_WAIT = 4'b1011
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

// Hit Counter
word_t hit_cntr;
word_t nxt_hit_cntr;
logic quick_hit;
logic nxt_quick_hit;

// Bus Capability
logic bus_hit;
dcachef_t snoopaddr;
word_t nxt_snoopaddr;
logic nxt_cctrans;
logic ccwait;
logic ccinv;
logic dwait;

// LL and SC Capability
word_t link_address, nxt_link_address;
logic link_valid, nxt_link_valid;

// Cache operation variables
assign cop = ({dcif.halt, ccwait, dcif.dmemREN, dcif.dmemWEN, dirty, int_dhit});
assign dp_read = (dcif.dmemREN & !dcif.dmemWEN);
assign dp_write = (dcif.dmemWEN & !dcif.dmemREN);

// Selection variables
//assign daddr = dcachef_t'(dcif.dmemaddr);//'
//assign set = (bus_hit)?(snoopaddr.idx):(daddr.idx);
//assign set = (bus_hit)?(snoopaddr.idx):((cur_state = HALT)?(set_cntr):(daddr.idx));
assign lru_block = sets[set].blocks[sets[set].lru];
assign dirty = lru_block.dirty;

// Variables for HALT state
assign set_cntr = halt_cntr[4:2];
assign block_cntr = halt_cntr[1];
assign word_cntr = halt_cntr[0];





//assign block_arb = (!int_dhit || bus_hit)?(nxt_block):(block);
//assign blkoff_arb = (int_dhit || bus_hit)?(daddr.blkoff):(blkoff);

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
		block <= 0;
		blkoff <= 0;
		link_address <= 0;
		link_valid <= 0;
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
		//ccif.cctrans[CPUID] <= nxt_cctrans;
		snoopaddr <= dcachef_t'(nxt_snoopaddr);//'
		ccwait <= ccif.ccwait[CPUID];
		ccinv <= ccif.ccinv[CPUID];
		dwait <= ccif.dwait[CPUID];
		link_address <= nxt_link_address;
		link_valid <= nxt_link_valid;
	end
end

//
// Next State Logic
//
always_comb begin
	casez(cur_state)
		IDLE: begin
			casez(cop)
				6'b100000: begin
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
				6'b010100: begin
					nxt_state = ALLOC_RD_WAIT;
				end
				6'b011000: begin
					nxt_state = ALLOC_RD_WAIT;
				end
				6'b01????: begin
					nxt_state = SNOOP;
				end
				
				default: begin
					nxt_state = IDLE;
				end
			endcase
		end
		ALLOC_RD_WAIT: begin
			if (!ccwait) begin
				nxt_state = IDLE;
			end else begin
				nxt_state = SNOOP;
			end 
		end
		ALLOC_RD: begin
			if (ccwait) begin
				nxt_state = SNOOP;
			end else if (mem_ready && off_read == WORDS_PER_BLK-1) begin
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
		HALT_WAIT: begin
			if (ccwait || bus_hit) begin
				nxt_state = SNOOP;
			end else begin
				nxt_state = HALT;
			end
		end
		HALT: begin
			if (ccwait) begin
				nxt_state = SNOOP;
			end else if (halt_cntr != 32) begin
				nxt_state = HALT;
			end else begin
				nxt_state = DONE;
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
		SNOOP: begin
			
			if (bus_hit) begin
				nxt_state = BUS_WB;
				//nxt_state = (ccinv)?(ALLOC_RD):(BUS_WB);
			end else if (ccwait) begin
				nxt_state = SNOOP;
			end else begin
				nxt_state = IDLE;
			end
			
			/*
			if (bus_hit) begin
				nxt_state = BUS_WB;
			end else begin
				nxt_state = IDLE;
			end
			*/
		end
		BUS_WB: begin
			if (!ccwait) begin
				nxt_state = IDLE;
			end else if (mem_ready && off_write == WORDS_PER_BLK-1) begin
				nxt_state = (ccwait && dcif.halt)?(HALT):(IDLE);
			end else begin
				nxt_state = BUS_WB;
			end
		end
	endcase
end

// Output logic
assign dcif.dhit = int_dhit;
assign dcif.flushed = flushed;
//assign int_dhit = 
//			((daddr.tag == sets[daddr.idx].blocks[0].tag) && (sets[daddr.idx].blocks[0].valid)) ||
//			((daddr.tag == sets[daddr.idx].blocks[1].tag) && (sets[daddr.idx].blocks[1].valid))
//		;
assign mem_ready = !dwait;

assign pre_daddr = dcachef_t'(dcif.dmemaddr);//'

always_comb begin
	set = daddr.idx;
	block_arb = block;
	blkoff_arb = daddr.blkoff;
	int_dhit = 
		((daddr.tag == sets[daddr.idx].blocks[0].tag) && (sets[daddr.idx].blocks[0].valid)) ||
		((daddr.tag == sets[daddr.idx].blocks[1].tag) && (sets[daddr.idx].blocks[1].valid))
	;

	ccif.dREN[CPUID] = 1'b0;
	ccif.dWEN[CPUID] = 1'b0;
	ccif.daddr[CPUID] = {daddr.tag, daddr.idx, off_read[0], 2'b00};
	ccif.dstore[CPUID] = sets[set].blocks[block_arb].data[blkoff];

	//nxt_cctrans = 1'b0;
	ccif.cctrans[CPUID] = 1'b0;
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

	
	bus_hit = 
				((snoopaddr.tag == sets[snoopaddr.idx].blocks[0].tag) && (sets[snoopaddr.idx].blocks[0].valid)) ||
				((snoopaddr.tag == sets[snoopaddr.idx].blocks[1].tag) && (sets[snoopaddr.idx].blocks[1].valid))
			;
	nxt_snoopaddr = ccif.ccsnoopaddr[CPUID];
	
	casez(cur_state)
		IDLE: begin
			// Reset counters
			nxt_off_read = 0;
			nxt_off_write = 0;
			nxt_halt_cntr = 0;
			nxt_quick_hit = 1'b1;
			nxt_daddr = pre_daddr;
			nxt_snoopaddr = ccif.ccsnoopaddr[CPUID];
			int_dhit = 
				((pre_daddr.tag == sets[pre_daddr.idx].blocks[0].tag) && (sets[pre_daddr.idx].blocks[0].valid)) ||
				((pre_daddr.tag == sets[pre_daddr.idx].blocks[1].tag) && (sets[pre_daddr.idx].blocks[1].valid))
			;

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
					dcif.dmemload = sets[pre_daddr.idx].blocks[block].data[pre_daddr.blkoff];
					//$display("C2P: m[%h] : c[%h:%h:%h] = %h", dcif.dmemaddr, set, block_arb, blkoff, dcif.dmemload);
				end else if (dp_write) begin
					// Write data to cache
					nxt_data = dcif.dmemstore;
					nxt_dirty = 1'b1;
					nxt_valid = 1'b1;
					nxt_tag = pre_daddr.tag;
					set = pre_daddr.idx;
					block_arb = nxt_block;
					blkoff_arb = pre_daddr.blkoff;
					//$display("P2C: m[%h] : c[%h:%h:%h] <= %h", dcif.dmemaddr, set, block_arb, blkoff, dcif.dmemstore);
				end
			end else if(dp_write || dp_read) begin
				// There was a miss, but still a valid command,
				// so we prepare the block offset to be 0 for
				// the alloc/wb state, the selected block to be
				// the LRU block, and leave the hit counter alone.
				nxt_hit_cntr = hit_cntr;
				nxt_block = sets[set].lru;
				block_arb = nxt_block;
				nxt_blkoff = 1'b0;
				ccif.cctrans[CPUID] = 1'b1;
				ccif.dREN[CPUID] = 1'b1;
				ccif.dWEN[CPUID] = 1'b0;
			end

			// LL
			if (dcif.datomic && dp_read) begin
				nxt_link_address = dcif.dmemaddr;
				nxt_link_valid = 1'b1;
			end else begin
				nxt_link_address = link_address;
				nxt_link_valid = link_valid;
			end

			// SC
			if (dcif.datomic && dp_write) begin
				// Compare link register and incoming address and
				// test valid bit
				if (link_address == dcif.dmemaddr && link_valid) begin
					// If successful store like normal
					nxt_data = dcif.dmemstore;
					nxt_dirty = 1'b1;
					nxt_valid = 1'b1;
					nxt_tag = pre_daddr.tag;
					set = pre_daddr.idx;
					block_arb = nxt_block;
					blkoff_arb = pre_daddr.blkoff;
					dcif.dmemload = 32'h00000001;
				end else begin
					// Else return with failure
					dcif.dmemload = 32'h00000000;
				end
			end

			if (ccwait) begin
				set = snoopaddr.idx;
				block_arb = nxt_block;
				nxt_snoopaddr = ccif.ccsnoopaddr[CPUID];
				nxt_valid = sets[set].blocks[block_arb].valid;
				nxt_tag = sets[set].blocks[block_arb].tag;
			end
		end
		ALLOC_RD_WAIT: begin
			//ccif.dREN[CPUID] = 1'b1;
			//ccif.dWEN[CPUID] = 1'b0;
			//ccif.cctrans[CPUID] = 1'b1;
			//ccif.ccwrite[CPUID] = dcif.dmemWEN;
		end
		ALLOC_RD: begin
			blkoff_arb = blkoff;
			int_dhit = 1'b0;

			// Send address and REN/WEN to memory controller
			ccif.daddr[CPUID] = {daddr.tag, daddr.idx, off_read[0], 2'b00};
			//ccif.daddr[CPUID] = 32'h00000000;
			ccif.dREN[CPUID] = 1'b1;
			ccif.dWEN[CPUID] = 1'b0;
			ccif.cctrans[CPUID] = 1'b1;
			ccif.ccwrite[CPUID] = dcif.dmemWEN;

			// Wait for memory to be readable
			if (mem_ready) begin
				// Strictly load data into the block
				nxt_off_read = off_read + 1;
				nxt_data = ccif.dload[CPUID];
				nxt_blkoff = nxt_off_read[0];
				ccif.daddr[CPUID] = {daddr.tag, daddr.idx, nxt_off_read[0], 2'b00};

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
					//nxt_data = sets[set].blocks[block_arb].data[blkoff_arb];

				end else if (off_read == WORDS_PER_BLK-2) begin
					ccif.cctrans[CPUID] = 1'b0;
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
			//nxt_cctrans = 1'b1;
			

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
			set = set_cntr;
			block_arb = block_cntr;
			blkoff_arb = word_cntr;
			nxt_block = block;

			// Send address, data, and REN/WEN to memory controller
			ccif.daddr[CPUID] = {sets[set_cntr].blocks[block_cntr].tag, set_cntr, word_cntr, 2'b00};
			ccif.dstore[CPUID] = sets[set_cntr].blocks[block_cntr].data[word_cntr];
			nxt_data = sets[set_cntr].blocks[block_cntr].data[word_cntr];
			nxt_tag = sets[set_cntr].blocks[block_cntr].tag;
			nxt_dirty = sets[set_cntr].blocks[block_cntr].dirty;
			nxt_valid = sets[set_cntr].blocks[block_cntr].valid;
			ccif.ccwrite[CPUID] = 1'b1;

			// Wait for memory controller to write successfully and keep 
			// incrementing counter to keep iterating through cache blocks.
			if ((!sets[set_cntr].blocks[block_cntr].dirty || !sets[set_cntr].blocks[block_cntr].valid || mem_ready) && halt_cntr != 32) begin
				nxt_halt_cntr = halt_cntr + 1;
			end else begin
				nxt_halt_cntr = halt_cntr;
			end

			// Only write back to memory if the block is dirty
			if (sets[set_cntr].blocks[block_cntr].dirty && sets[set_cntr].blocks[block_cntr].valid) begin
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b1;
				//$display("Writing %h to %h", ccif.dstore, ccif.daddr);
				//$display("MWb: m[%h] <= c[%h:%h:%h] = %h", ccif.daddr, set_cntr, block_cntr, word_cntr, ccif.dstore);
			end else begin
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b0;
			end

			if (mem_ready) begin
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b0;
				//ccif.daddr[CPUID] = 32'h00000000;
				nxt_off_write = off_write + 1;
				if (off_write == WORDS_PER_BLK-1) begin
					nxt_off_write = 0;
					nxt_valid = 1'b0;
					nxt_dirty = 1'b0;
				end
			end

			if (ccwait) begin
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b0;
				ccif.ccwrite[CPUID] = 1'b0;
				blkoff_arb = word_cntr;
				nxt_data = sets[set].blocks[block_arb].data[off_write[0]];
			end else if (halt_cntr == 32) begin
				ccif.ccwrite[CPUID] = 1'b0;
			end
		end
		HALT_CNTR: begin
			ccif.daddr[CPUID] = 32'h00003100;
			ccif.dstore[CPUID] = hit_cntr;
			ccif.dREN[CPUID] = 1'b0;
			ccif.dWEN[CPUID] = 1'b1;
			ccif.ccwrite[CPUID] = 1'b1;
			if (mem_ready) begin
				nxt_flushed = 1'b1;
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b0;
				ccif.ccwrite[CPUID] = 1'b0;
			end
		end
		DONE: begin
			nxt_flushed = 1'b1;
			ccif.ccwrite[CPUID] = 1'b1;
		end
		SNOOP: begin
			set = snoopaddr.idx;
			block_arb = nxt_block;
			nxt_snoopaddr = ccif.ccsnoopaddr[CPUID];

			/////////
			//nxt_data = 32'hFFFFFFFF;
			nxt_tag = sets[set].blocks[block_arb].tag;
			nxt_dirty = sets[set].blocks[block_arb].dirty;
			nxt_valid = sets[set].blocks[block_arb].valid;




			//snoopaddr = dcachef_t'(ccif.ccsnoopaddr[CPUID]);//'
			bus_hit = 
				((snoopaddr.tag == sets[snoopaddr.idx].blocks[0].tag) && (sets[snoopaddr.idx].blocks[0].valid)) ||
				((snoopaddr.tag == sets[snoopaddr.idx].blocks[1].tag) && (sets[snoopaddr.idx].blocks[1].valid))
			;
			if (bus_hit) begin
				//nxt_valid = !ccinv;
				nxt_blkoff = snoopaddr.blkoff;
				if (snoopaddr.tag == sets[snoopaddr.idx].blocks[0].tag) begin
					nxt_block = 1'b0;
				end else if (snoopaddr.tag == sets[snoopaddr.idx].blocks[1].tag) begin
					nxt_block = 1'b1;
				end
				block_arb = nxt_block;
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b1;
				//ccif.cctrans[CPUID] = 1'b1;
				nxt_data = sets[set].blocks[block_arb].data[blkoff_arb];
				nxt_tag = sets[set].blocks[block_arb].tag;
				nxt_dirty = sets[set].blocks[block_arb].dirty;
				nxt_valid = sets[set].blocks[block_arb].valid;
			end else if (!ccwait) begin
				nxt_data = sets[set].blocks[block_arb].data[blkoff_arb];
			end else begin
				//nxt_cctrans = 1'b0;
				ccif.ccwrite[CPUID] = 1'b1;
			end
		end
		BUS_WB: begin
			set = snoopaddr.idx;
			//block_arb = nxt_block;
			nxt_halt_cntr = halt_cntr;
			
			bus_hit = 
				((snoopaddr.tag == sets[snoopaddr.idx].blocks[0].tag) && (sets[snoopaddr.idx].blocks[0].valid)) ||
				((snoopaddr.tag == sets[snoopaddr.idx].blocks[1].tag) && (sets[snoopaddr.idx].blocks[1].valid))
			;
			
			/*
			bus_hit = 
				(snoopaddr.tag == sets[snoopaddr.idx].blocks[0].tag) ||
				(snoopaddr.tag == sets[snoopaddr.idx].blocks[1].tag)
			;
			*/
			nxt_block = block;
			// Send address, data, and REN/WEN to memory controller
			ccif.daddr[CPUID] = {sets[set].blocks[block_arb].tag, set, off_write[0], 2'b00};
			ccif.dstore[CPUID] = sets[set].blocks[block_arb].data[blkoff];
			nxt_data = sets[set].blocks[block_arb].data[off_write[0]];
			nxt_tag = sets[set].blocks[block_arb].tag;
			nxt_dirty = sets[set].blocks[block_arb].dirty;
			nxt_valid = sets[set].blocks[block_arb].valid;
			ccif.dREN[CPUID] = 1'b0;
			ccif.dWEN[CPUID] = 1'b1;
			//ccif.cctrans[CPUID] = 1'b0;
			//ccif.ccwrite[CPUID] = 1'b1;
			

			if (mem_ready) begin
				nxt_off_write = off_write + 1;
				nxt_blkoff = nxt_off_write[0];

				// We now know that everything has been writen back to memory,
				// so we just set the block offset to be 0 since we have to
				// go directly to the allocate state.
				if (off_write == WORDS_PER_BLK-1) begin
					//nxt_blkoff = daddr.blkoff;
					nxt_blkoff = 1'b0;
					nxt_dirty = 1'b0;
					nxt_valid = !ccinv;
					ccif.dREN[CPUID] = 1'b0;
					ccif.dWEN[CPUID] = 1'b0;
					ccif.ccwrite[CPUID] = 1'b0;
					nxt_data = sets[set].blocks[block_arb].data[nxt_blkoff];
				end
			end else begin
				nxt_off_write = off_write;
				nxt_blkoff = blkoff;
			end

			if (!ccwait) begin
				ccif.dREN[CPUID] = 1'b0;
				ccif.dWEN[CPUID] = 1'b0;
				ccif.ccwrite[CPUID] = 1'b0;
				//blkoff_arb = word_cntr;
			end else if (ccwait) begin

			end

			//$display("C2M: c[%h:%h:%h] = %h => m[%h]", set, block_arb, blkoff, ccif.dstore, ccif.daddr);
		end
	endcase
end

endmodule