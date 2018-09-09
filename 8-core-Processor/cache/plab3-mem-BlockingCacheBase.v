//=========================================================================
// Base Cache
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_BASE_V
`define PLAB3_MEM_BLOCKING_CACHE_BASE_V

`include "vc-mem-msgs.v"
`include "plab3-mem-BlockingCacheBaseCtrl.v"
`include "plab3-mem-BlockingCacheBaseDpath.v"


module plab3_mem_BlockingCacheBase
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

  input [`VC_MEM_REQ_MSG_NBITS(8,abw,dbw)-1:0]  cachereq_msg,
  input                                         cachereq_val,
  output                                        cachereq_rdy,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(8,dbw)-1:0]    cacheresp_msg,
  output                                        cacheresp_val,
  input                                         cacheresp_rdy,

  // Memory Request

  output [`VC_MEM_REQ_MSG_NBITS(8,abw,clw)-1:0] memreq_msg,
  output                                        memreq_val,
  input                                         memreq_rdy,

  // Memory Response

  input [`VC_MEM_RESP_MSG_NBITS(8,clw)-1:0]     memresp_msg,
  input                                         memresp_val,
  output                                        memresp_rdy
);

  //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------

  // control signals (ctrl->dpath)

  // add the control signal wires here

  // status signals (dpath->ctrl)

  // add the status signal wires here
       // add1:init
   wire [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0] cachereq_type; 
   wire  cachereq_en;
   

   wire tag_array_wen; 
   wire tag_array_ren; 
   wire tag_match;
  

   wire data_array_wen;
   wire data_array_ren;  
   wire [15:0] data_array_wben; 
  
  wire memresp_en;
  wire is_refill;
  
  wire read_data_reg_en;
  wire [1:0] read_byte_sel;
  wire read_tag_reg_en;
  wire memreq_type;
  
  wire [31:0] addr_in;
  wire [2:0]  tag_array_wben;
  wire [1:0]  memreq_type2;

  //----------------------------------------------------------------------
  // Control
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheBaseCtrl ctrl
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_val      (cachereq_val),
   .cachereq_rdy      (cachereq_rdy),

   // Cache Response

   .cacheresp_val     (cacheresp_val),
   .cacheresp_rdy     (cacheresp_rdy),

   // Memory Request

   .memreq_val        (memreq_val),
   .memreq_rdy        (memreq_rdy),

   // Memory Response

   .memresp_val       (memresp_val),
   .memresp_rdy       (memresp_rdy),
   
     // input from datapath
   .cachereq_type (cachereq_type),
   .tag_match     (tag_match),
   .addr_in       (addr_in),
   
     //different type control signal
	.memreq_type2    (memreq_type2), 
	 
   .cachereq_en      (cachereq_en),
		
		
   .tag_array_wen  (tag_array_wen),
   .tag_array_ren  (tag_array_ren),
   .tag_array_wben (tag_array_wben),
  
   .data_array_wen  (data_array_wen),
   .data_array_ren  (data_array_ren),
   .data_array_wben  (data_array_wben),
   
   .memresp_en      (memresp_en),
   .is_refill       (is_refill),
   
   .read_data_reg_en (read_data_reg_en),
   .read_byte_sel   (read_byte_sel),
   .read_tag_reg_en (read_tag_reg_en),
   .memreq_type     (memreq_type)
   
  );

  //----------------------------------------------------------------------
  // Datapath
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheBaseDpath#(p_mem_nbytes) dpath
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_msg      (cachereq_msg),

   // Cache Response

   .cacheresp_msg     (cacheresp_msg),

   // Memory Request

   .memreq_msg        (memreq_msg),

   // Memory Response

   .memresp_msg       (memresp_msg),
   
     // input from datapath
     // input from datapath
   .cachereq_type (cachereq_type),
   .tag_match     (tag_match),
   .addr_in       (addr_in),
   
     //different type control signal
	 .memreq_type2    (memreq_type2),
	 
   .cachereq_en      (cachereq_en),
		
		
   .tag_array_wen  (tag_array_wen),
   .tag_array_ren  (tag_array_ren),
   .tag_array_wben (tag_array_wben),
  
   .data_array_wen  (data_array_wen),
   .data_array_ren  (data_array_ren),
   .data_array_wben  (data_array_wben),
   
   .memresp_en      (memresp_en),
   .is_refill       (is_refill),
   
   .read_data_reg_en (read_data_reg_en),
   .read_byte_sel   (read_byte_sel),
   .read_tag_reg_en (read_tag_reg_en),
   .memreq_type     (memreq_type)
  );

  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------

  `include "vc-trace-tasks.v"

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    // add line tracing here

    vc_trace_str( trace, "forw" );

  end
  endtask

endmodule

`endif
