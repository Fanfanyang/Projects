//=========================================================================
// Base Cache Datapath
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_ALT_DPATH_V
`define PLAB3_MEM_BLOCKING_CACHE_ALT_DPATH_V

`include "vc-mem-msgs.v"
`include "vc-arithmetic.v"
`include "vc-srams.v"
`include "vc-regs.v"
`include "vc-muxes.v"

module plab3_mem_BlockingCacheAltDpath
#(
  parameter size    = 256,            // Cache size in bytes

  // local parameters not meant to be set from outside
  parameter dbw     = 32,             // Short name for data bitwidth
  parameter abw     = 32,             // Short name for addr bitwidth
  parameter clw     = 128,            // Short name for cacheline bitwidth
  parameter nblocks = size*8/clw,     // Number of blocks in the cache
  parameter idw     = $clog2(nblocks) // Short name for index width
)
(
  input                                         clk,
  input                                         reset,

  // Cache Request

  input [`VC_MEM_REQ_MSG_NBITS(8,abw,dbw)-1:0]  cachereq_msg,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(8,dbw)-1:0]    cacheresp_msg,

  // Memory Request

  output [`VC_MEM_REQ_MSG_NBITS(8,abw,clw)-1:0] memreq_msg,

  // Memory Response

  input [`VC_MEM_RESP_MSG_NBITS(8,clw)-1:0]     memresp_msg,

  // output state to control
  
  output [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0]  cachereq_type,
  output                                              tag_match1_0,

  output [31:0]  addr_in,                              
  // alt
  input  [1:0]  new_bit,
  
  // receive different type control signal
  input    [1:0] memreq_type2,
  
  input    cachereq_en,
  
  input    tag_array_wen1,

  input    tag_array_ren,
  input    [2:0]   tag_array_wben,

  input    data_array_wen1,

  input    data_array_ren,
  input    [15:0]  data_array_wben1,

  
  input    memresp_en,
  input    is_refill,
  
  input    read_data_reg_en,
  input    [1:0]   read_byte_sel,
  input    read_tag_reg_en,
  input    memreq_type,
  
  output [2:0] idx,
  output [31:0] tag_tag,
  input [31:0] tag2_read,
  
  input [127:0] data2_read,
  output [127:0] refill_data,
  
  input [31:0] tag3_read,
  
  input [127:0] data3_read
);

  //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------

  // cache request

  wire [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0]   cachereq_type1;
    wire [7:0] cachereq_opaque;
  wire [7:0] cachereq_opaque2;
 // wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(8,abw,dbw)-1:0] cachereq_opaque;
 // wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(8,abw,dbw)-1:0] cachereq_opaque2;
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(8,abw,dbw)-1:0]   cachereq_addr;
  wire [`VC_MEM_REQ_MSG_LEN_NBITS(8,abw,dbw)-1:0]    cachereq_len;
 //wire [1:0] cachereq_len;
  wire [`VC_MEM_REQ_MSG_DATA_NBITS(8,abw,dbw)-1:0]   cachereq_data;

  // memory response

  wire [`VC_MEM_RESP_MSG_TYPE_NBITS(8,clw)-1:0]      memresp_type;
  wire [`VC_MEM_RESP_MSG_OPAQUE_NBITS(8,clw)-1:0]    memresp_opaque;
  wire [`VC_MEM_RESP_MSG_LEN_NBITS(8,clw)-1:0]       memresp_len;
 // wire [3:0]       memresp_len;
  wire [`VC_MEM_RESP_MSG_DATA_NBITS(8,clw)-1:0]      memresp_data;

  // memory request

  wire [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,clw)-1:0]   memreq_type1;
  wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(8,abw,clw)-1:0] memreq_opaque;
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(8,abw,clw)-1:0]   memreq_addr;
  wire [`VC_MEM_REQ_MSG_LEN_NBITS(8,abw,clw)-1:0]    memreq_len;
  //wire [3:0] memreq_len;
 // wire [`VC_MEM_REQ_MSG_DATA_NBITS(8,abw,clw)-1:0]   memreq_data;

  // cache response

  wire [`VC_MEM_RESP_MSG_TYPE_NBITS(8,dbw)-1:0]      cacheresp_type;
  wire [`VC_MEM_RESP_MSG_OPAQUE_NBITS(8,dbw)-1:0]    cacheresp_opaque;
  wire [`VC_MEM_RESP_MSG_LEN_NBITS(8,dbw)-1:0]       cacheresp_len;
  //wire [1:0]       cacheresp_len;
  wire [`VC_MEM_RESP_MSG_DATA_NBITS(8,dbw)-1:0]      cacheresp_data;

  //----------------------------------------------------------------------
  // Unpack
  //----------------------------------------------------------------------

  // Unpack cache request

  vc_MemReqMsgUnpack#(8,abw,dbw) cachereq_msg_unpack
  (
    // input

    .msg    (cachereq_msg),  //76b

    // outputs

    .type   (cachereq_type1),  //2b
    .opaque (cachereq_opaque), //8b
    .addr   (cachereq_addr),   //32b	
    .len    (cachereq_len),   //2b
    .data   (cachereq_data)   //32b
  );

  // Unpack memory response

  vc_MemRespMsgUnpack#(8,clw) memresp_msg_unpack
  (
    // input

    .msg    (memresp_msg),

    // outputs

    .type   (memresp_type),
//    .type   (memreq_type1),
    .opaque (memresp_opaque),
    .len    (memresp_len),
    .data   (memresp_data)
  );

  //----------------------------------------------------------------------
  // Datapath logic
  //----------------------------------------------------------------------
  
  //------------------------------------------------------------------------
  // registers
  //------------------------------------------------------------------------
  
 // wire [31:0]  addr_in;
  wire [31:0]  data_in;
  
  vc_EnResetReg#(2) cachereq_type_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (cachereq_type),
	.d     (cachereq_type1),
	.en    (cachereq_en)
  );
  
  vc_EnResetReg#(32) cachereq_addr_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (addr_in),
	.d     (cachereq_addr),
	.en    (cachereq_en)
  );  
  
 // assign addr_in = cachereq_addr;
  
  vc_EnResetReg#(8) cachereq_opaque_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (cachereq_opaque2),
	.d     (cachereq_opaque),
	.en    (cachereq_en)
  );  
  
  vc_EnResetReg#(32) cachereq_data_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (data_in),
	.d     (cachereq_data),
	.en    (cachereq_en)
  );  
 // assign data_in = cachereq_data;
  
  //-------------------------------------------------------------------
  // tag
  //-------------------------------------------------------------------
  
  wire [2:0]   idx;
  wire [24:0]  tag;
  wire [31:0]  tag_read;
  wire [31:0]  tag2_read;
  wire [31:0]  tag3_read;
  wire [31:0]  tag_read2;
  wire [31:0]  tag2_read2;
  wire [31:0]  tag3_read2;
  wire [31:0]  tag_read3;
  wire [31:0]  tag_read4;
  wire [24:0]  tag_mem;
  wire [31:0]  tag_tag;
//  wire [31:0]  memreq_addr;
//wire tag_array_wen1;
//wire tag_array_wen2;
    
  assign idx = addr_in[6:4];
  assign tag = addr_in[31:7];
  assign tag_tag = {7'd0,tag};
  
  vc_CombinationalSRAM_1rw#(32,8) tag_array
  (
    .clk           (clk),
	.reset         (reset),
	.read_en       (tag_array_ren),
	.read_addr     (idx),
	.read_data     (tag_read),
	.write_en      (tag_array_wen1),
	.write_byte_en (4'b1111),
	.write_addr    (idx),
	.write_data    (tag_tag)
  );

  
  vc_EqComparator #(32) compa1
  (
    .in0  (tag_tag),
    .in1  (tag_read),
    .out  (tag_match1_0)
  );

  vc_EnResetReg#(32) read_tag_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (tag_read2),
	.d     (tag_read),
	.en    (read_tag_reg_en)
  );  
  
  vc_EnResetReg#(32) read_tag_reg2
  (
    .clk   (clk),
	.reset (reset),
	.q     (tag2_read2),
	.d     (tag2_read),
	.en    (read_tag_reg_en)
  );
  
  vc_EnResetReg#(32) read_tag_reg3
  (
    .clk   (clk),
	.reset (reset),
	.q     (tag3_read2),
	.d     (tag3_read),
	.en    (read_tag_reg_en)
  );
  
  vc_Mux3#(32) mux_tag_choose
  (
    .in0 (tag_read2),
	.in1 (tag2_read2),
	.in2 (tag3_read2),
	.sel (new_bit),
	.out (tag_read3)
  );
  
  vc_Mux2#(32) mux_read_tag
  (
    .in0 (tag_read3),
	.in1 (tag_tag),
	.sel (memreq_type),
	.out (tag_read4)
  );
  
  assign tag_mem = tag_read4[25:0];
  assign memreq_addr = {tag_mem, idx, 4'd0};
  
  
  
  
  //----------------------------------------------------------------------
  // data array
  //----------------------------------------------------------------------
  wire [127:0]   data_read;
  wire [127:0]   data_in2;
  
  wire [127:0]	 data2_read;

  wire [127:0]   data_read2;
  wire [127:0]   data_read3;
  wire [127:0]	 data3_read;
  
  wire [31:0]    data_read2_3;
  wire [31:0]    data_read2_2;
  wire [31:0]    data_read2_1;
  wire [31:0]    data_read2_0;
  
  wire [127:0]   memresp_data2;
  wire [127:0]   refill_data;
   
  assign data_in2 = {4{data_in}};
  
  vc_EnResetReg#(128) memresp_data_Reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (memresp_data2),
	.d     (memresp_data),
	.en    (memresp_en)
  );  
  
  vc_Mux2#(128) refill_mux
  (
    .in0 (data_in2),
	.in1 (memresp_data2),
	.sel (is_refill),
	.out (refill_data)
  );
  
  
  
  
  
  vc_CombinationalSRAM_1rw#(128,8) data_array1
  (
    .clk           (clk),
	.reset         (reset),
	.read_en       (data_array_ren),
	.read_addr     (idx),
	.read_data     (data_read),
	.write_en      (data_array_wen1),
	.write_byte_en (data_array_wben1),
	.write_addr    (idx),
	.write_data    (refill_data)
  );

    
    vc_EnResetReg#(128) read_data_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (data_read3),
	.d     (data_read2),
	.en    (read_data_reg_en)
  );   
  
    vc_Mux3#(128) mux_data_choose
  (
    .in0 (data_read),
	.in1 (data2_read),
	.in2 (data3_read),
	.sel (new_bit),
	.out (data_read2)
  );
  
  assign data_read2_3 = data_read3[127:96];
  assign data_read2_2 = data_read3[95:64];
  assign data_read2_1 = data_read3[63:32];
  assign data_read2_0 = data_read3[31:0];
  
  vc_Mux4#(32) mux_read
  (
    .in0 (data_read2_0),
	.in1 (data_read2_1),
	.in2 (data_read2_2),
	.in3 (data_read2_3),
	.sel (read_byte_sel),
	.out (cacheresp_data)
  );
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  assign memreq_type1 = memreq_type2;

 assign memreq_opaque    = 0;
 assign memreq_len       = 0;
 

 assign cacheresp_type   = cachereq_type;
  assign cacheresp_len    =  0;
  assign cacheresp_opaque =  cachereq_opaque2;
  //----------------------------------------------------------------------
  // Unpack
  //----------------------------------------------------------------------

  // Pack cache response

  vc_MemRespMsgPack#(8,dbw) cacheresp_msg_pack
  (
    // inputs

    .type   (cacheresp_type), //2b
    .opaque (cacheresp_opaque), //8b
    .len    (cacheresp_len),    //2b
    .data   (cacheresp_data),  //32b

    // output

    .msg    (cacheresp_msg)   //32b
  );

  // Pack memory request

  vc_MemReqMsgPack#(8,abw,clw) memreq_msg_pack
  (
    // inputs

    .type   (memreq_type1), //2
    .opaque (memreq_opaque), //8
    .addr   (memreq_addr), //32
    .len    (memreq_len), //2
    .data   (data_read3), //128

    // output

    .msg    (memreq_msg)
  );  
  
endmodule

`endif
