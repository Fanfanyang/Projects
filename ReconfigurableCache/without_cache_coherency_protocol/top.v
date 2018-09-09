
`include "mem-BlockingCacheAlt.v"
`include "vc-mem-msgs.v"
`include "test.v"

module top

(
	input clk,
	input reset,
	
	
  // Cache Request 

  input [`VC_MEM_REQ_MSG_NBITS(8,32,32)-1:0]  cachereq_msg_1,
  input                                         cachereq_val_1,
  output                                        cachereq_rdy_1,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(8,32)-1:0]    cacheresp_msg_1,
  output                                        cacheresp_val_1,
  input                                         cacheresp_rdy_1,
  
  input [`VC_MEM_REQ_MSG_NBITS(8,32,32)-1:0]  cachereq_msg_2,
  input                                         cachereq_val_2,
  output                                        cachereq_rdy_2,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(8,32)-1:0]    cacheresp_msg_2,
  output                                        cacheresp_val_2,
  input                                         cacheresp_rdy_2,
  
  output [9:0] cache_req_cnt_a,
  output [9:0] cache_miss_cnt_a,
  output [9:0] cache_req_cnt_b,
  output [9:0] cache_miss_cnt_b

);

  // Memory Request

  wire [`VC_MEM_REQ_MSG_NBITS(8,32,128)-1:0] memreq_msg;
  wire        [1:0]                      memreq_val;
  wire                                         memreq_rdy;

  // Memory Response

  wire [`VC_MEM_RESP_MSG_NBITS(8,128)-1:0]     memresp_msg;
  wire                                         memresp_val;
  wire                                        memresp_rdy;
  
    wire [`VC_MEM_REQ_MSG_NBITS(8,32,128)-1:0] memreq_msg_2;
  wire        [1:0]                      memreq_val_2;
  wire                                         memreq_rdy_2;

  // Memory Response

  wire [`VC_MEM_RESP_MSG_NBITS(8,128)-1:0]     memresp_msg_2;
  wire                                         memresp_val_2;
  wire                                        memresp_rdy_2;

plab3_mem_BlockingCacheAlt connect_module_1
(
	.clk (clk),
	.reset (reset),
	
	.cachereq_msg_a (cachereq_msg_1),
	.cachereq_val_a (cachereq_val_1),
	.cachereq_rdy_a (cachereq_rdy_1),
	
	.cacheresp_msg_a (cacheresp_msg_1),
	.cacheresp_val_a (cacheresp_val_1),
	.cacheresp_rdy_a (cacheresp_rdy_1),
	
	.cachereq_msg_b (cachereq_msg_2),
	.cachereq_val_b (cachereq_val_2),
	.cachereq_rdy_b (cachereq_rdy_2),
	
	.cacheresp_msg_b (cacheresp_msg_2),
	.cacheresp_val_b (cacheresp_val_2),
	.cacheresp_rdy_b (cacheresp_rdy_2),
	
	.memreq_msg (memreq_msg),
	.memreq_val (memreq_val),
	.memreq_rdy (memreq_rdy),
	
	.memresp_msg (memresp_msg),
	.memresp_val (memresp_val),
	.memresp_rdy (memresp_rdy),
	
	.memreq_msg_2 (memreq_msg_2),
	.memreq_val_2 (memreq_val_2),
	.memreq_rdy_2 (memreq_rdy_2),
	
	.memresp_msg_2 (memresp_msg_2),
	.memresp_val_2 (memresp_val_2),
	.memresp_rdy_2 (memresp_rdy_2),
	
	.cache_req_cnt_a (cache_req_cnt_a),
    .cache_miss_cnt_a (cache_miss_cnt_a),
    .cache_req_cnt_b (cache_req_cnt_b),
    .cache_miss_cnt_b (cache_miss_cnt_b)
	
);

//-------------------------------------------------------------------
// memreq_rdy wait for 3 cycles
//-------------------------------------------------------------------

wire memreq_rdy1;
assign memreq_rdy1 = ((memreq_val == 2'd1) || (memreq_val == 2'd2)); 

delay_cycles3 #(1) delay3
(	
	.clk (clk),
	.reset (reset),
	.a (memreq_rdy1),
	.b (memreq_rdy)
);

wire memreq_rdy1_2;
assign memreq_rdy1_2 = ((memreq_val_2 == 2'd1) || (memreq_val_2 == 2'd2)); 

delay_cycles3 #(1) delay3_2
(	
	.clk (clk),
	.reset (reset),
	.a (memreq_rdy1_2),
	.b (memreq_rdy_2)
);

//-------------------------------------------------------------------
// memresp_val wait for 3 cycles
//-------------------------------------------------------------------
wire memresp_val1;
assign memresp_val1 = (memresp_rdy && (!memreq_val));

delay_change_3 #(1) delay2
(	
	.clk (clk),
	.reset (reset),
	.a (memresp_val1),
	.b (memresp_val)
);

wire memresp_val1_2;
assign memresp_val1_2 = (memresp_rdy_2 && (!memreq_val_2));

delay_change_3 #(1) delay2_2
(	
	.clk (clk),
	.reset (reset),
	.a (memresp_val1_2),
	.b (memresp_val_2)
);

//----------------------------------------------------------------------

wire [9:0] address;
wire [127:0] data_1;
wire [127:0] data_2;

assign address = memreq_msg[139:130];   //total 172
assign data_1 = memreq_msg[127:0];
assign type = memreq_msg[171:170];

wire [9:0] address_2;
wire [127:0] data_1_2;
wire [127:0] data_2_2;

assign address_2 = memreq_msg_2[139:130];   //total 172
assign data_1_2 = memreq_msg_2[127:0];
assign type_2 = memreq_msg_2[171:170];


blk_mem_gen_1 bram_1 (
  .clka(clk),    // input wire clka
  .ena(memresp_rdy || memreq_val),      // input wire ena
  .wea(memreq_val == 2'd2),      // input wire [0 : 0] wea
  .addra(address),  // input wire [9 : 0] addra
  .dina(data_1),    // input wire [127 : 0] dina
  .douta(data_2),  // output wire [127 : 0] douta
  .clkb(clk),    // input wire clkb
  .enb(memresp_rdy_2 || memreq_val_2),      // input wire enb
  .web(memreq_val_2 == 2'd2),      // input wire [0 : 0] web
  .addrb(address_2),  // input wire [9 : 0] addrb
  .dinb(data_1_2),    // input wire [127 : 0] dinb
  .doutb(data_2_2)  // output wire [127 : 0] doutb
);

//assign memresp_msg =(memresp_rdy?{16'b0,data_2}:144'b0);
assign memresp_msg ={16'b0,data_2};
assign memresp_msg_2 ={16'b0,data_2_2};

endmodule
