//=========================================================================
// Base Cache
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_ALT_V
`define PLAB3_MEM_BLOCKING_CACHE_ALT_V

`include "vc-mem-msgs.v"
`include "mem-BlockingCacheAltCtrl.v"
`include "mem-BlockingCacheAltCtrl2.v"
`include "mem-BlockingCacheAltDpath.v"
`include "data_2.v"
`include "vc-muxes.v"


module plab3_mem_BlockingCacheAlt
#(
  parameter p_mem_nbytes = 256,            // Cache size in bytes

  // local parameters not meant to be set from outside
  parameter dbw          = 32,             // Short name for data bitwidth
  parameter abw          = 32,             // Short name for addr bitwidth
  parameter clw          = 128             // Short name for cacheline bitwidth
)
(
  input                                         clk,
  input                                         reset,

  // Cache Request

  input [`VC_MEM_REQ_MSG_NBITS(8,abw,dbw)-1:0]  cachereq_msg_a,
  input                                         cachereq_val_a,
  output                                        cachereq_rdy_a,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(8,dbw)-1:0]    cacheresp_msg_a,
  output                                        cacheresp_val_a,
  input                                         cacheresp_rdy_a,
  
  // processor 2
  input [`VC_MEM_REQ_MSG_NBITS(8,abw,dbw)-1:0]  cachereq_msg_b,
  input                                         cachereq_val_b,
  output                                        cachereq_rdy_b,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(8,dbw)-1:0]    cacheresp_msg_b,
  output                                        cacheresp_val_b,
  input                                         cacheresp_rdy_b,

  // Memory Request

  output [`VC_MEM_REQ_MSG_NBITS(8,abw,clw)-1:0] memreq_msg,
  output       [1:0]                           memreq_val,
  input                                         memreq_rdy,

  // Memory Response

  input [`VC_MEM_RESP_MSG_NBITS(8,clw)-1:0]     memresp_msg,
  input                                         memresp_val,
  output                                        memresp_rdy,
  
  output [`VC_MEM_REQ_MSG_NBITS(8,abw,clw)-1:0] memreq_msg_2,
  output       [1:0]                           memreq_val_2,
  input                                         memreq_rdy_2,

  // Memory Response

  input [`VC_MEM_RESP_MSG_NBITS(8,clw)-1:0]     memresp_msg_2,
  input                                         memresp_val_2,
  output                                        memresp_rdy_2,
  
  output [9:0] cache_req_cnt_a,
  output [9:0] cache_miss_cnt_a,
  output [9:0] cache_req_cnt_b,
  output [9:0] cache_miss_cnt_b
  
);

  //----------------------------------------------------------------------
  // preparing connection
  //----------------------------------------------------------------------
wire [1:0] reconfiguration_a;
wire [1:0] reconfiguration_b;

assign reconfiguration_b = (reconfiguration_a == 2'd0 ? 2'd0 
							: (reconfiguration_a == 2'd1 ? 2'd2
							: 2'd1));

  //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------
  
  wire [`VC_MEM_REQ_MSG_NBITS(8,abw,clw)-1:0] memreq_msg_a;
  wire       [1:0]                           memreq_val_a;
  wire                                         memreq_rdy_a;

  // Memory Response

  wire [`VC_MEM_RESP_MSG_NBITS(8,clw)-1:0]     memresp_msg_a;
  wire                                         memresp_val_a;
  wire                                        memresp_rdy_a;
  
  wire [`VC_MEM_REQ_MSG_NBITS(8,abw,clw)-1:0] memreq_msg_b;
  wire       [1:0]                           memreq_val_b;
  wire                                         memreq_rdy_b;

  // Memory Response

  wire [`VC_MEM_RESP_MSG_NBITS(8,clw)-1:0]     memresp_msg_b;
  wire                                         memresp_val_b;
  wire                                        memresp_rdy_b;
  
  assign memreq_msg = memreq_msg_a;
  assign memreq_val = memreq_val_a;
  assign memreq_rdy_a = memreq_rdy;
  assign memresp_msg_a = memresp_msg;
  assign memresp_val_a = memresp_val;
  assign memresp_rdy = memresp_rdy_a;
  
    assign memreq_msg_2 = memreq_msg_b;
  assign memreq_val_2 = memreq_val_b;
  assign memreq_rdy_b = memreq_rdy_2;
  assign memresp_msg_b = memresp_msg_2;
  assign memresp_val_b = memresp_val_2;
  assign memresp_rdy_2 = memresp_rdy_b;
  
  
   wire [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0] cachereq_type_a; 
   wire  cachereq_en_a;
   

   wire tag_array_wen1_a;
   wire tag_array_wen2_a; 
   wire tag_array_wen3_a;
   wire tag_array_ren_a; 
   wire tag_match1_0_a;
   wire tag_match2_0_a;
   wire tag_match3_0_a;
   wire [1:0] new_bit_a;

   wire data_array_wen1_a; 
   wire data_array_wen2_a; 
   wire data_array_wen3_a;
   wire data_array_ren_a;  
   wire [15:0] data_array_wben1_a; 
   wire [15:0] data_array_wben2_a;
   wire [15:0] data_array_wben3_a;
  
  wire memresp_en_a;
  wire is_refill_a;
  
  wire read_data_reg_en_a;
  wire [1:0] read_byte_sel_a;
  wire read_tag_reg_en_a;
  wire memreq_type_a;
  
  wire [31:0] addr_in_a;
  wire [2:0]  tag_array_wben_a;
  wire [1:0]  memreq_type2_a;
  
  wire [2:0] idx_a;
  wire [31:0] tag_tag_a;
  wire [31:0] tag2_read_a;
  
  wire [127:0] data2_read_a;
  wire [127:0] refill_data_a;
  
  wire [31:0] tag3_read_a;
  
  wire [127:0] data3_read_a;
  wire sel_a;
   //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------

   wire [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0] cachereq_type_b; 
   wire  cachereq_en_b;
   

   wire tag_array_wen1_b;
   wire tag_array_wen2_b; 
   wire tag_array_wen3_b;
   wire tag_array_ren_b; 
   wire tag_match1_0_b;
   wire tag_match2_0_b;
   wire tag_match3_0_b;
   wire [1:0] new_bit_b;

   wire data_array_wen1_b; 
   wire data_array_wen2_b; 
   wire data_array_wen3_b;
   wire data_array_ren_b;  
   wire [15:0] data_array_wben1_b; 
   wire [15:0] data_array_wben2_b;
   wire [15:0] data_array_wben3_b;
  
  wire memresp_en_b;
  wire is_refill_b;
  
  wire read_data_reg_en_b;
  wire [1:0] read_byte_sel_b;
  wire read_tag_reg_en_b;
  wire memreq_type_b;
  
  wire [31:0] addr_in_b;
  wire [2:0]  tag_array_wben_b;
  wire [1:0]  memreq_type2_b;
  
  wire [2:0] idx_b;
  wire [31:0] tag_tag_b;
  wire [31:0] tag2_read_b;
  
  wire [127:0] data2_read_b;
  wire [127:0] refill_data_b;
  
  wire [31:0] tag3_read_b;
  
  wire [127:0] data3_read_b;
  wire sel_b;

  //----------------------------------------------------------------------
  // Control
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheAltCtrl ctrl1
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_val      (cachereq_val_a),
   .cachereq_rdy      (cachereq_rdy_a),

   // Cache Response

   .cacheresp_val     (cacheresp_val_a),
   .cacheresp_rdy     (cacheresp_rdy_a),

   // Memory Request

   .memreq_val        (memreq_val_a),
   .memreq_rdy        (memreq_rdy_a),

   // Memory Response

   .memresp_val       (memresp_val_a),
   .memresp_rdy       (memresp_rdy_a),
   
     // input from datapath
   .cachereq_type (cachereq_type_a),
   .tag_match1_0     (tag_match1_0_a),
   .tag_match2_0     (tag_match2_0_a),
   .tag_match3_0     (tag_match3_0_a),
   .addr_in       (addr_in_a),
   .new_bit       (new_bit_a),
   
     //different type control signal
	.memreq_type2    (memreq_type2_a), 
	 
   .cachereq_en      (cachereq_en_a),	
		
   .tag_array_wen1  (tag_array_wen1_a),
   .tag_array_wen2  (tag_array_wen2_a),
   .tag_array_wen3  (tag_array_wen3_a),
   .tag_array_ren  (tag_array_ren_a),
   .tag_array_wben (tag_array_wben_a),
  
   .data_array_wen1  (data_array_wen1_a),
   .data_array_wen2  (data_array_wen2_a),
   .data_array_wen3  (data_array_wen3_a),
   .data_array_ren  (data_array_ren_a),
   .data_array_wben1  (data_array_wben1_a),
   .data_array_wben2  (data_array_wben2_a),
   .data_array_wben3  (data_array_wben3_a),
   
   .memresp_en      (memresp_en_a),
   .is_refill       (is_refill_a),
   
   .read_data_reg_en (read_data_reg_en_a),
   .read_byte_sel   (read_byte_sel_a),
   .read_tag_reg_en (read_tag_reg_en_a),
   .memreq_type     (memreq_type_a),
   
   .reconfiguration (reconfiguration_a),
   .sel (sel_a),
   
   .cache_req_cnt1 (cache_req_cnt_a),
   .cache_miss_cnt1 (cache_miss_cnt_a)
   
  );

  //----------------------------------------------------------------------
  // Datapath
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheAltDpath#(p_mem_nbytes) dpath1
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_msg      (cachereq_msg_a),

   // Cache Response

   .cacheresp_msg     (cacheresp_msg_a),

   // Memory Request

   .memreq_msg        (memreq_msg_a),

   // Memory Response

   .memresp_msg       (memresp_msg_a),
   
     // input from datapath
     // input from datapath
   .cachereq_type (cachereq_type_a),
   .tag_match1_0     (tag_match1_0_a),

   .addr_in       (addr_in_a),
   .new_bit       (new_bit_a),
   
     //different type control signal
	.memreq_type2    (memreq_type2_a), 
	 
   .cachereq_en      (cachereq_en_a),	
		
   .tag_array_wen1  (tag_array_wen1_a),

   .tag_array_ren  (tag_array_ren_a),
   .tag_array_wben (tag_array_wben_a),
  
   .data_array_wen1  (data_array_wen1_a),

   .data_array_ren  (data_array_ren_a),
   .data_array_wben1  (data_array_wben1_a),

   
   .memresp_en      (memresp_en_a),
   .is_refill       (is_refill_a),
   
   .read_data_reg_en (read_data_reg_en_a),
   .read_byte_sel   (read_byte_sel_a),
   .read_tag_reg_en (read_tag_reg_en_a),
   .memreq_type     (memreq_type_a),
   
   .idx (idx_a),
   .tag_tag (tag_tag_a),
   .tag2_read (tag2_read_a), 
   .data2_read (data2_read_a),
   .refill_data (refill_data_a),
   .tag3_read (tag3_read_a),
  
   .data3_read (data3_read_a)
  );

  //----------------------------------------------------------------------
  // mux preparation for data 2
  //----------------------------------------------------------------------
 
 wire tag_array_ren_2;
 wire [2:0] idx_2;
 wire [31:0] tag2_read;
 wire tag_array_wen2;
 wire [31:0] tag_tag_2;
 
 wire data_array_ren_2;
 wire [127:0] data2_read;
 wire data_array_wen2;
 wire [15:0] data_array_wben2;
 wire [127:0] refill_data_2;
 wire tag_match2_0;
 
   vc_Mux2#(1) mux_2_tag_read_en_2
  (
    .in0 (tag_array_ren_a),
	.in1 (tag_array_ren_b),
	.sel (sel_a),
	.out (tag_array_ren_2)
  );
  
  vc_Mux2#(3) mux_2_idx_2
  (
    .in0 (idx_a),
	.in1 (idx_b),
	.sel (sel_a),
	.out (idx_2)
  );
  
  assign tag2_read_a = tag2_read;
  assign tag3_read_b = tag2_read;
  
  vc_Mux2#(1) mux_2_tag_array_wen2
  (
    .in0 (tag_array_wen2_a),
	.in1 (tag_array_wen3_b),
	.sel (sel_a),
	.out (tag_array_wen2)
  );
  
  vc_Mux2#(32) mux_2_tag_tag_2
  (
    .in0 (tag_tag_a),
	.in1 (tag_tag_b),
	.sel (sel_a),
	.out (tag_tag_2)
  );
  
  vc_Mux2#(1) mux_2_data_array_ren_2
  (
    .in0 (data_array_ren_a),
	.in1 (data_array_ren_b),
	.sel (sel_a),
	.out (data_array_ren_2)
  );

  
  assign data2_read_a = data2_read;
  assign data3_read_b = data2_read;
  
  vc_Mux2#(1) mux_2_data_array_wen2
  (
    .in0 (data_array_wen2_a),
	.in1 (data_array_wen3_b),
	.sel (sel_a),
	.out (data_array_wen2)
  );
  
  vc_Mux2#(16) mux_2_data_array_wben2
  (
    .in0 (data_array_wben2_a),
	.in1 (data_array_wben3_b),
	.sel (sel_a),
	.out (data_array_wben2)
  );
  
  vc_Mux2#(128) mux_2_refill_data_2
  (
    .in0 (refill_data_a),
	.in1 (refill_data_b),
	.sel (sel_a),
	.out (refill_data_2)
  );
  
  assign tag_match2_0_a = tag_match2_0;
  assign tag_match3_0_b = tag_match2_0;
  
  
  //----------------------------------------------------------------------
  // data_2
  //----------------------------------------------------------------------
  
  
 data_2 cache_data_2
(
  .clk (clk),
  .reset (reset),

  .tag_read_en (tag_array_ren_2),
  .addr (idx_2),
  .tag_read_data (tag2_read),
  .tag_write_en (tag_array_wen2),
  .tag_write_data (tag_tag_2),
   
  .data_read_en (data_array_ren_2),
  .data_read_data (data2_read),
  .data_write_en (data_array_wen2),
  .data_write_byte_en (data_array_wben2),
  .data_write_data (refill_data_2),
  
  .tag_match (tag_match2_0)
);

  //----------------------------------------------------------------------
  // mux preparation for data 3
  //----------------------------------------------------------------------
 
 wire tag_array_ren_3;
 wire [2:0] idx_3;
 wire [31:0] tag3_read;
 wire tag_array_wen3;
 wire [31:0] tag_tag_3;
 
 wire data_array_ren_3;
 wire [127:0] data3_read;
 wire data_array_wen3;
 wire [15:0] data_array_wben3;
 wire [127:0] refill_data_3;
 wire tag_match3_0;
 
   vc_Mux2#(1) mux_2_tag_read_en_3
  (
    .in0 (tag_array_ren_b),
	.in1 (tag_array_ren_a),
	.sel (sel_b),
	.out (tag_array_ren_3)
  );
  
  vc_Mux2#(3) mux_2_idx_3
  (
    .in0 (idx_b),
	.in1 (idx_a),
	.sel (sel_b),
	.out (idx_3)
  );
  
  assign tag2_read_b = tag3_read;
  assign tag3_read_a = tag3_read;
  
  vc_Mux2#(1) mux_2_tag_array_wen3
  (
    .in0 (tag_array_wen2_b),
	.in1 (tag_array_wen3_a),
	.sel (sel_b),
	.out (tag_array_wen3)
  );
  
  vc_Mux2#(32) mux_2_tag_tag_3
  (
    .in0 (tag_tag_b),
	.in1 (tag_tag_a),
	.sel (sel_b),
	.out (tag_tag_3)
  );
  
  vc_Mux2#(1) mux_2_data_array_ren_3
  (
    .in0 (data_array_ren_b),
	.in1 (data_array_ren_a),
	.sel (sel_b),
	.out (data_array_ren_3)
  );

  assign data2_read_b = data3_read;
  assign data3_read_a = data3_read;
  
  vc_Mux2#(1) mux_2_data_array_wen3
  (
    .in0 (data_array_wen2_b),
	.in1 (data_array_wen3_a),
	.sel (sel_b),
	.out (data_array_wen3)
  );
  
  vc_Mux2#(16) mux_2_data_array_wben3
  (
    .in0 (data_array_wben2_b),
	.in1 (data_array_wben3_a),
	.sel (sel_b),
	.out (data_array_wben3)
  );
  
  vc_Mux2#(128) mux_2_refill_data_3
  (
    .in0 (refill_data_b),
	.in1 (refill_data_a),
	.sel (sel_b),
	.out (refill_data_3)
  );
  
  assign tag_match2_0_b = tag_match3_0;
  assign tag_match3_0_a = tag_match3_0;
  
  //----------------------------------------------------------------------
  // data_3
  //----------------------------------------------------------------------
 data_2 cache_data_3
(
  .clk (clk),
  .reset (reset),

  .tag_read_en (tag_array_ren_3),
  .addr (idx_3),
  .tag_read_data (tag3_read),
  .tag_write_en (tag_array_wen3),
  .tag_write_data (tag_tag_3),
   
  .data_read_en (data_array_ren_3),
  .data_read_data (data3_read),
  .data_write_en (data_array_wen3),
  .data_write_byte_en (data_array_wben3),
  .data_write_data (refill_data_3),
  
  .tag_match (tag_match3_0)
);

  //----------------------------------------------------------------------
  // the second processor
  //----------------------------------------------------------------------

  //----------------------------------------------------------------------
  // Control
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheAltCtrl2 ctrl2
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_val      (cachereq_val_b),
   .cachereq_rdy      (cachereq_rdy_b),

   // Cache Response

   .cacheresp_val     (cacheresp_val_b),
   .cacheresp_rdy     (cacheresp_rdy_b),

   // Memory Request

   .memreq_val        (memreq_val_b),
   .memreq_rdy        (memreq_rdy_b),

   // Memory Response

   .memresp_val       (memresp_val_b),
   .memresp_rdy       (memresp_rdy_b),
   
     // input from datapath
   .cachereq_type (cachereq_type_b),
   .tag_match1_0     (tag_match1_0_b),
   .tag_match2_0     (tag_match2_0_b),
   .tag_match3_0     (tag_match3_0_b),
   .addr_in       (addr_in_b),
   .new_bit       (new_bit_b),
   
     //different type control signal
	.memreq_type2    (memreq_type2_b), 
	 
   .cachereq_en      (cachereq_en_b),	
		
   .tag_array_wen1  (tag_array_wen1_b),
   .tag_array_wen2  (tag_array_wen2_b),
   .tag_array_wen3  (tag_array_wen3_b),
   .tag_array_ren  (tag_array_ren_b),
   .tag_array_wben (tag_array_wben_b),
  
   .data_array_wen1  (data_array_wen1_b),
   .data_array_wen2  (data_array_wen2_b),
   .data_array_wen3  (data_array_wen3_b),
   .data_array_ren  (data_array_ren_b),
   .data_array_wben1  (data_array_wben1_b),
   .data_array_wben2  (data_array_wben2_b),
   .data_array_wben3  (data_array_wben3_b),
   
   .memresp_en      (memresp_en_b),
   .is_refill       (is_refill_b),
   
   .read_data_reg_en (read_data_reg_en_b),
   .read_byte_sel   (read_byte_sel_b),
   .read_tag_reg_en (read_tag_reg_en_b),
   .memreq_type     (memreq_type_b),
   
   .reconfiguration (reconfiguration_b),
   .sel (sel_b),
   
   .cache_req_cnt (cache_req_cnt_b),
   .cache_miss_cnt (cache_miss_cnt_b)
  );

  //----------------------------------------------------------------------
  // Datapath
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheAltDpath#(p_mem_nbytes) dpath2
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_msg      (cachereq_msg_b),

   // Cache Response

   .cacheresp_msg     (cacheresp_msg_b),

   // Memory Request

   .memreq_msg        (memreq_msg_b),

   // Memory Response

   .memresp_msg       (memresp_msg_b),
   
     // input from datapath
     // input from datapath
   .cachereq_type (cachereq_type_b),
   .tag_match1_0     (tag_match1_0_b),

   .addr_in       (addr_in_b),
   .new_bit       (new_bit_b),
   
     //different type control signal
	.memreq_type2    (memreq_type2_b), 
	 
   .cachereq_en      (cachereq_en_b),	
		
   .tag_array_wen1  (tag_array_wen1_b),

   .tag_array_ren  (tag_array_ren_b),
   .tag_array_wben (tag_array_wben_b),
  
   .data_array_wen1  (data_array_wen1_b),

   .data_array_ren  (data_array_ren_b),
   .data_array_wben1  (data_array_wben1_b),

   
   .memresp_en      (memresp_en_b),
   .is_refill       (is_refill_b),
   
   .read_data_reg_en (read_data_reg_en_b),
   .read_byte_sel   (read_byte_sel_b),
   .read_tag_reg_en (read_tag_reg_en_b),
   .memreq_type     (memreq_type_b),
   
   .idx (idx_b),
   .tag_tag (tag_tag_b),
   .tag2_read (tag2_read_b), 
   .data2_read (data2_read_b),
   .refill_data (refill_data_b),
   .tag3_read (tag3_read_b),
  
   .data3_read (data3_read_b)
  );
  
  
  
  
  
  

endmodule

`endif











