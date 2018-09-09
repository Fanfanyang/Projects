//=========================================================================
// Base Cache Datapath
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_BASE_DPATH_V
`define PLAB3_MEM_BLOCKING_CACHE_BASE_DPATH_V

`include "vc-mem-msgs.v"
`include "vc-arithmetic.v"
`include "vc-srams.v"
`include "vc-regs.v"

module plab3_mem_BlockingCacheBaseDpath
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
  output                                              tag_match,
  output [31:0]  addr_in,                              
  
  // receive different type control signal
  input    [1:0] memreq_type2,
  
  input    cachereq_en,
  
  input    tag_array_wen,
  input    tag_array_ren,
  input    [2:0]   tag_array_wben,

  input    data_array_wen,
  input    data_array_ren,
  input    [15:0]  data_array_wben,
  
  input    memresp_en,
  input    is_refill,
  
  input    read_data_reg_en,
  input    [1:0]   read_byte_sel,
  input    read_tag_reg_en,
  input    memreq_type
);

  //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------

  // cache request

  wire [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0]   cachereq_type1;
  wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(8,abw,dbw)-1:0] cachereq_opaque;
  wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(8,abw,dbw)-1:0] cachereq_opaque2;
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(8,abw,dbw)-1:0]   cachereq_addr;
  wire [`VC_MEM_REQ_MSG_LEN_NBITS(8,abw,dbw)-1:0]    cachereq_len;
  wire [`VC_MEM_REQ_MSG_DATA_NBITS(8,abw,dbw)-1:0]   cachereq_data;

  // memory response

  wire [`VC_MEM_RESP_MSG_TYPE_NBITS(8,clw)-1:0]      memresp_type;
  wire [`VC_MEM_RESP_MSG_OPAQUE_NBITS(8,clw)-1:0]    memresp_opaque;
  wire [`VC_MEM_RESP_MSG_LEN_NBITS(8,clw)-1:0]       memresp_len;
  wire [`VC_MEM_RESP_MSG_DATA_NBITS(8,clw)-1:0]      memresp_data;

  // memory request

  wire [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,clw)-1:0]   memreq_type1;
  wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(8,abw,clw)-1:0] memreq_opaque;
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(8,abw,clw)-1:0]   memreq_addr;
  wire [`VC_MEM_REQ_MSG_LEN_NBITS(8,abw,clw)-1:0]    memreq_len;
 // wire [`VC_MEM_REQ_MSG_DATA_NBITS(8,abw,clw)-1:0]   memreq_data;

  // cache response

  wire [`VC_MEM_RESP_MSG_TYPE_NBITS(8,dbw)-1:0]      cacheresp_type;
  wire [`VC_MEM_RESP_MSG_OPAQUE_NBITS(8,dbw)-1:0]    cacheresp_opaque;
  wire [`VC_MEM_RESP_MSG_LEN_NBITS(8,dbw)-1:0]       cacheresp_len;
  wire [`VC_MEM_RESP_MSG_DATA_NBITS(8,dbw)-1:0]      cacheresp_data;

  //----------------------------------------------------------------------
  // Unpack
  //----------------------------------------------------------------------

  // Unpack cache request

  vc_MemReqMsgUnpack#(8,abw,dbw) cachereq_msg_unpack
  (
    // input

    .msg    (cachereq_msg),

    // outputs

    .type   (cachereq_type1),
    .opaque (cachereq_opaque),
    .addr   (cachereq_addr),
    .len    (cachereq_len),
    .data   (cachereq_data)
  );

  // Unpack memory response

  vc_MemRespMsgUnpack#(8,clw) memresp_msg_unpack
  (
    // input

    .msg    (memresp_msg),

    // outputs

    .type   (memresp_type),
 //   .type   (memreq_type1),
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
  
  wire [3:0]   idx;
  wire [23:0]  tag;
  wire [23:0]  tag_read;
  wire [23:0]  tag_read2;
  wire [23:0]  tag_mem;
//  wire [31:0]  memreq_addr;
    
  assign idx = addr_in[7:4];
  assign tag = addr_in[31:8];
  
  vc_CombinationalSRAM_1rw#(24,16) tag_array
  (
    .clk           (clk),
	.reset         (reset),
	.read_en       (tag_array_ren),
	.read_addr     (idx),
	.read_data     (tag_read),
	.write_en      (tag_array_wen),
	.write_byte_en (3'b111),
	.write_addr    (idx),
	.write_data    (tag)
  );
  
  vc_EqComparator #(24) compa1
  (
    .in0  (tag),
    .in1  (tag_read),
    .out  (tag_match)
  );
  
  vc_EnResetReg#(24) read_tag_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (tag_read2),
	.d     (tag_read),
	.en    (read_tag_reg_en)
  );  
  
  vc_Mux2#(24) mux_read_tag
  (
    .in0 (tag_read2),
	.in1 (tag),
	.sel (memreq_type),
	.out (tag_mem)
  );
  
  assign memreq_addr = {tag_mem, idx, 4'd0};
  
  
  
  
  //----------------------------------------------------------------------
  // data array
  //----------------------------------------------------------------------
  wire [127:0]   data_read;
  wire [127:0]   data_in2;
  
  wire [127:0]   data_read2;
  
  wire [31:0]    data_read2_3;
  wire [31:0]    data_read2_2;
  wire [31:0]    data_read2_1;
  wire [31:0]    data_read2_0;
  
  wire [127:0]   memresp_data2;
  wire [127:0]   refill_data;
  
  //data_in2 = {data_in,data_in,data_in,data_in};
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
  
  
  
  
  
  vc_CombinationalSRAM_1rw#(128,16) data_array
  (
    .clk           (clk),
	.reset         (reset),
	.read_en       (data_array_ren),
	.read_addr     (idx),
	.read_data     (data_read),
	.write_en      (data_array_wen),
	.write_byte_en (data_array_wben),
	.write_addr    (idx),
	.write_data    (refill_data)
  );
  
  vc_EnResetReg#(128) read_data_reg
  (
    .clk   (clk),
	.reset (reset),
	.q     (data_read2),
	.d     (data_read),
	.en    (read_data_reg_en)
  );   
    
  assign data_read2_3 = data_read2[127:96];
  assign data_read2_2 = data_read2[95:64];
  assign data_read2_1 = data_read2[63:32];
  assign data_read2_0 = data_read2[31:0];
  
  vc_Mux4#(32) mux_read
  (
    .in0 (data_read2_0),
	.in1 (data_read2_1),
	.in2 (data_read2_2),
	.in3 (data_read2_3),
	.sel (read_byte_sel),
	.out (cacheresp_data)
  );
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  // null cache behavior: pass the transaction to the main memory
  assign memreq_type1 = memreq_type2;
 // assign memreq_type1      = cachereq_type;
 // assign memreq_opaque    = cachereq_opaque;
 // assign memreq_addr      = cachereq_addr;
 // assign memreq_len       = cachereq_len == 0 ? 3'b100 : cachereq_len;
 // assign memreq_data      = cachereq_data;
 assign memreq_opaque    = 0;
 assign memreq_len       = 0;
 

 // assign cacheresp_type   = memresp_type;
//  assign cacheresp_opaque = memresp_opaque;
 // assign cacheresp_len    = memresp_len;
 // assign cacheresp_data   = memresp_data;
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

    .type   (cacheresp_type),
    .opaque (cacheresp_opaque),
    .len    (cacheresp_len),
    .data   (cacheresp_data),

    // output

    .msg    (cacheresp_msg)
  );

  // Pack memory request

  vc_MemReqMsgPack#(8,abw,clw) memreq_msg_pack
  (
    // inputs

    .type   (memreq_type1),
    .opaque (memreq_opaque),
    .addr   (memreq_addr),
    .len    (memreq_len),
    .data   (data_read2),

    // output

    .msg    (memreq_msg)
  );  
  
endmodule

`endif
