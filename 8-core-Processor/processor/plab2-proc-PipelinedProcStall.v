//=========================================================================
// 5-Stage Stall Pipelined Processor
//=========================================================================

`ifndef PLAB2_PROC_PIPELINED_PROC_STALL_V
`define PLAB2_PROC_PIPELINED_PROC_STALL_V

`include "vc-mem-msgs.v"
`include "vc-DropUnit.v"
`include "plab2-proc-PipelinedProcStallCtrl.v"
`include "plab2-proc-PipelinedProcStallDpath.v"
`include "pisa-inst.v"

`define PLAB2_PROC_FROM_MNGR_MSG_NBITS 32
`define PLAB2_PROC_TO_MNGR_MSG_NBITS 32

module plab2_proc_PipelinedProcStall
(
  input                                       clk,
  input                                       reset,

  // Instruction Memory Request Port

  output [`VC_MEM_REQ_MSG_NBITS(8,32,32)-1:0] imemreq_msg,
  output                                      imemreq_val,
  input                                       imemreq_rdy,

  // Instruction Memory Response Port

  input [`VC_MEM_RESP_MSG_NBITS(8,32)-1:0]    imemresp_msg,
  input                                       imemresp_val,
  output                                      imemresp_rdy,

  // Data Memory Request Port

  output [`VC_MEM_REQ_MSG_NBITS(8,32,32)-1:0] dmemreq_msg,
  output                                      dmemreq_val,
  input                                       dmemreq_rdy,

  // Data Memory Response Port

  input [`VC_MEM_RESP_MSG_NBITS(8,32)-1:0]    dmemresp_msg,
  input                                       dmemresp_val,
  output                                      dmemresp_rdy,
  //output                                      dmemreq_msg_type,

  // From mngr streaming port

  input [`PLAB2_PROC_FROM_MNGR_MSG_NBITS-1:0] from_mngr_msg,
  input                                       from_mngr_val,
  output                                      from_mngr_rdy,

  // To mngr streaming port

  output [`PLAB2_PROC_TO_MNGR_MSG_NBITS-1:0]  to_mngr_msg,
  output                                      to_mngr_val,
  input                                       to_mngr_rdy

);
  //mul
    //mul
  wire         in_val_0;
  wire         out_rdy_0;
  wire         in_rdy_1;
  wire         out_val_1;
  
  wire         ex_sel_X; 
  
  
  //----------------------------------------------------------------------
  // data mem req/resp
  //----------------------------------------------------------------------

  wire [31:0] dmemreq_msg_addr;
  wire [31:0] dmemreq_msg_data;
  wire [31:0] dmemresp_msg_data;

  wire [31:0] imemreq_msg_addr;
  wire [31:0] imemresp_msg_data;

  // imemresp signals after the dropping unit


  wire [`VC_MEM_RESP_MSG_NBITS(8,32)-1:0] imemresp_msg_drop;
  wire                                    imemresp_val_drop;
  wire                                    imemresp_rdy_drop;

  wire                                    imemresp_drop;

  // control signals (ctrl->dpath)

  wire [1:0]  pc_sel_F;
  wire        reg_en_F;
  wire        reg_en_D;
  wire        reg_en_X;
  wire        reg_en_M;
  wire        reg_en_W;
  wire [1:0]  op0_sel_D;
  wire [2:0]  op1_sel_D;
  wire [3:0]  alu_fn_X;
  wire        wb_result_sel_M;
  wire [4:0]  rf_waddr_W;
  wire        rf_wen_W;

  // status signals (dpath->ctrl)

  wire [31:0] inst_D;
  wire        br_cond_eq_X;


  //----------------------------------------------------------------------
  // Pack Memory Request Messages
  //----------------------------------------------------------------------

  wire        dmemreq_msg_type;
  
  vc_MemReqMsgPack#(8,32,32) imemreq_msg_pack
  (
    .type   (`VC_MEM_REQ_MSG_TYPE_READ),
    .opaque (8'b0),
    .addr   (imemreq_msg_addr),
    .len    (2'd0),
    .data   (32'bx),
    .msg    (imemreq_msg)
  );

  vc_MemReqMsgPack#(8,32,32) dmemreq_msg_pack
  (
    .type   (dmemreq_msg_type),
    .opaque (8'b0),
    .addr   (dmemreq_msg_addr),
    .len    (2'd0),
    .data   (dmemreq_msg_data),
    .msg    (dmemreq_msg)
  );


  //-------------------------------------------------------------------D---
  // Unpack Memory Response Messages
  //----------------------------------------------------------------------

  vc_MemRespMsgUnpack#(8,32) imemresp_msg_unpack
  (
    .msg    (imemresp_msg),
    .opaque (),
    .type   (),
    .len    (),
    .data   (imemresp_msg_data)
  );

  vc_MemRespMsgUnpack#(8,32) dmemresp_msg_unpack
  (
    .msg    (dmemresp_msg),
    .opaque (),
    .type   (),
    .len    (),
    .data   (dmemresp_msg_data)
  );

  //----------------------------------------------------------------------
  // Imem Drop Unit
  //----------------------------------------------------------------------

  vc_DropUnit #(`VC_MEM_RESP_MSG_NBITS(8,32)) imem_drop_unit
  (
    .clk      (clk),
    .reset    (reset),

    .drop     (imemresp_drop),

    .in_msg   (imemresp_msg),
    .in_val   (imemresp_val),
    .in_rdy   (imemresp_rdy),

    .out_msg  (imemresp_msg_drop),
    .out_val  (imemresp_val_drop),
    .out_rdy  (imemresp_rdy_drop)
  );

  //----------------------------------------------------------------------
  // Control Unit
  //----------------------------------------------------------------------

  plab2_proc_PipelinedProcStallCtrl ctrl
  (
    .clk                    (clk),
    .reset                  (reset),

    // Instruction Memory Port

    .imemreq_val            (imemreq_val),
    .imemreq_rdy            (imemreq_rdy),
    .imemresp_val           (imemresp_val_drop),
    .imemresp_rdy           (imemresp_rdy_drop),
    .imemresp_drop          (imemresp_drop),

    // Data Memory Port

    .dmemreq_val            (dmemreq_val),
    .dmemreq_rdy            (dmemreq_rdy),
    .dmemresp_val           (dmemresp_val),
    .dmemresp_rdy           (dmemresp_rdy),
	.dmemreq_msg_type       (dmemreq_msg_type),

    // mngr communication ports

    .from_mngr_val          (from_mngr_val),
    .from_mngr_rdy          (from_mngr_rdy),
    .to_mngr_val            (to_mngr_val),
    .to_mngr_rdy            (to_mngr_rdy),

    // control signals (ctrl->dpath)

    .pc_sel_F               (pc_sel_F),
    .reg_en_F               (reg_en_F),
    .reg_en_D               (reg_en_D),
    .reg_en_X               (reg_en_X),
    .reg_en_M               (reg_en_M),
    .reg_en_W               (reg_en_W),
	.op0_sel_D              (op0_sel_D),
    .op1_sel_D              (op1_sel_D),
    .wb_result_sel_M        (wb_result_sel_M),
    .alu_fn_X               (alu_fn_X),
    .rf_waddr_W             (rf_waddr_W),
    .rf_wen_W               (rf_wen_W),

    // status signals (dpath->ctrl)

    .inst_D                 (inst_D),
    .br_cond_eq_X           (br_cond_eq_X),

	//mul
   .in_val_0                (in_val_0),
   .out_rdy_0               (out_rdy_0),
   .in_rdy_1                (in_rdy_1),
   .out_val_1               (out_val_1),
  
   .ex_sel_X                (ex_sel_X)
  );

  //----------------------------------------------------------------------
  // Datapath
  //----------------------------------------------------------------------

  plab2_proc_PipelinedProcStallDpath dpath
  (
    .clk                     (clk),
    .reset                   (reset),

    // Instruction Memory Port

    .imemreq_msg_addr        (imemreq_msg_addr),
    .imemresp_msg_data       (imemresp_msg_data),

    // Data Memory Port

    .dmemreq_msg_addr        (dmemreq_msg_addr),
	.dmemreq_msg_data        (dmemreq_msg_data),
    .dmemresp_msg_data       (dmemresp_msg_data),

    // mngr communication ports

    .from_mngr_data          (from_mngr_msg),
    .to_mngr_data            (to_mngr_msg),

    // control signals (ctrl->dpath)

    .pc_sel_F                (pc_sel_F),
    .reg_en_F                (reg_en_F),
    .reg_en_D                (reg_en_D),
    .reg_en_X                (reg_en_X),
    .reg_en_M                (reg_en_M),
    .reg_en_W                (reg_en_W),
	.op0_sel_D               (op0_sel_D),
    .op1_sel_D               (op1_sel_D),
    .alu_fn_X                (alu_fn_X),
    .wb_result_sel_M         (wb_result_sel_M),
    .rf_waddr_W              (rf_waddr_W),
    .rf_wen_W                (rf_wen_W),

    // status signals (dpath->ctrl)

    .inst_D                  (inst_D),
    .br_cond_eq_X            (br_cond_eq_X),
	
	//mul
   .in_val_0                (in_val_0),
   .out_rdy_0               (out_rdy_0),
   .in_rdy_1                (in_rdy_1),
   .out_val_1               (out_val_1),
  
   .ex_sel_X                (ex_sel_X)
  );


  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------

  `include "vc-trace-tasks.v"

  pisa_InstTasks pisa();

  reg[`VC_TRACE_NBITS_TO_NCHARS(32)*8-1:0] f_str;
  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    $sformat( f_str, "%x", dpath.pc_F );
    ctrl.pipe_ctrl_F.trace_pipe_stage( trace, f_str, 8 );

    vc_trace_str( trace, "|" );

    ctrl.pipe_ctrl_D.trace_pipe_stage( trace,
                              pisa.disasm(ctrl.inst_D ), 22 );

    vc_trace_str( trace, "|" );

    ctrl.pipe_ctrl_X.trace_pipe_stage( trace,
                              pisa.disasm_tiny(ctrl.inst_X ), 4 );

    vc_trace_str( trace, "|" );

    ctrl.pipe_ctrl_M.trace_pipe_stage( trace,
                              pisa.disasm_tiny(ctrl.inst_M ), 4 );

    vc_trace_str( trace, "|" );

    ctrl.pipe_ctrl_W.trace_pipe_stage( trace,
                              pisa.disasm_tiny(ctrl.inst_W ), 4 );


  end
  endtask

endmodule

`endif

