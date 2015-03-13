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
  datapath_cache_if.cache dcif,
  cache_control_if.caches ccif
);

  // import types
  import cpu_types_pkg::*;

typedef enum logic [1:0] {
	IDLE = 2'b00,
	READ = 2'b01,
	ALLOCATE = 2'b10
} state;

typedef struct packed {
    logic valid;
    logic [ITAG_W-1:0] tag;
    word_t [WORDS_PER_BLK-1:0] data; // Accessed through block offset
} iblock_t;

typedef struct {
	iblock_t blocks[BLKS_PER_SET];
} iset_t;
  
icachef_t iaddr;
assign iaddr = icachef_t'(dcif.imemaddr);//'
iset_t sets[SETS]; // Accessed through index

logic [IIDX_W-1:0] set_sel;
logic block_sel;
logic data_sel;
logic cache_write;
word_t nxt_data;
logic [ITAG_W-1:0] nxt_tag;
logic mem_ready, ihit, valid, nxt_valid;
state cur_state, nxt_state;


always_ff @(posedge CLK, negedge nRST) begin
	if (!nRST) begin
		cur_state <= IDLE;
	end
	else begin
		cur_state <= nxt_state;
	end
end

always_comb begin
	valid = 0;
	ihit = 0;
	if (sets[iaddr.idx].blocks[0].tag) begin
		ihit = 1;
	end
	if (sets[iaddr.idx].blocks[0].valid) begin
		valid = 1;
	end
end

always_comb begin
	casez(cur_state)
		IDLE: begin
			if (dcif.imemREN) begin
				nxt_state = READ;
			end
			else begin
				nxt_state = IDLE;
			end
		end
		READ: begin
			if (ihit && valid) begin
				nxt_state = IDLE;
			end
			else begin
				nxt_state = ALLOCATE;
			end
		end
		ALLOCATE: begin
			if (mem_ready) begin
				nxt_state = READ;
			end
			else begin
				nxt_state = ALLOCATE;
			end
		end
	endcase
end

// Output logic
always_comb begin
	casez(cur_state)
	IDLE: begin

	end
	READ: begin
		dcif.ihit = (iaddr.tag == sets[iaddr.idx].blocks[0].tag) && (sets[iaddr.idx].blocks[0].valid);
	end
	ALLOCATE: begin
		ccif.iaddr = dcif.imemaddr;
		ccif.iREN = dcif.imemREN;
		mem_ready = !ccif.iwait;

	end
	endcase
end

//
// Data Store
//
always_ff @(posedge CLK, negedge nRST) begin
	if (!nRST) begin
		sets = '{default: 0};//'
	end else begin
		sets[set_sel].blocks[block_sel].data[data_sel] = nxt_data;
		sets[set_sel].blocks[block_sel].valid = nxt_valid;
  	end
end

//
// Tag Store
//
always_ff @(posedge CLK, negedge nRST) begin
	if (!nRST) begin
		sets = '{default: 0};//'
	end else begin
		sets[set_sel].blocks[block_sel].tag = nxt_tag;
  	end
end

//
// Next data
//
assign set_sel = iaddr.idx;
assign block_sel = 0;
assign data_sel = 0;
assign cache_write = (cur_state == ALLOCATE) && (mem_ready);
always_comb begin
	nxt_data = sets[set_sel].blocks[block_sel].data[data_sel];
	if (cache_write) begin
		nxt_data = ccif.iload;
	end
end

//
// Next tag
//
always_comb begin
	nxt_tag = sets[set_sel].blocks[block_sel].tag;
	nxt_valid = sets[set_sel].blocks[block_sel].valid;
	if(cache_write) begin
		nxt_tag = iaddr.tag;
		nxt_valid = 1;
	end
end

endmodule