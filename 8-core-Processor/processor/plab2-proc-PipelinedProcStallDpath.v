//=========================================================================
// 5-Stage Stall Pipelined Processor Datapath
//=========================================================================

`ifndef PLAB2_PROC_PIPELINED_PROC_STALL_DPATH_V
`define PLAB2_PROC_PIPELINED_PROC_STALL_DPATH_V

`include "plab2-proc-dpath-components.v"
`include "vc-arithmetic.v"
`include "vc-muxes.v"
`include "vc-regs.v"
`include "pisa-inst.v"
`include "plab1-imul-IntMulVarLat.v"

module plab2_proc_PipelinedProcStallDpath
(
  input clk,
  input reset,

  // Instruction Memory Port

  output [31:0] imemreq_msg_addr,
  input  [31:0] imemresp_msg_data,

  // Data Memory Port

  output [31:0] dmemreq_msg_addr,
  output [31:0] dmemreq_msg_data,
  input  [31:0] dmemresp_msg_data,

  // mngr communication ports

  input  [31:0] from_mngr_data,
  output [31:0] to_mngr_data,

  // control signals (ctrl->dpath)

  input [1:0]   pc_sel_F,
  input         reg_en_F,
  input         reg_en_D,
  input         reg_en_X,
  input         reg_en_M,
  input         reg_en_W,
  input [1:0]   op0_sel_D,
  input [2:0]   op1_sel_D,
  input [3:0]   alu_fn_X,
  input         wb_result_sel_M,
  input [4:0]   rf_waddr_W,
  input         rf_wen_W,

  // status signals (dpath->ctrl)

  output [31:0] inst_D,
  output        br_cond_eq_X,
  
  //mul
  input         in_val_0,
  input         out_rdy_0,
  output        in_rdy_1,
  output        out_val_1,
  
  input         ex_sel_X 

);

  localparam c_reset_vector = 32'h1000;
  localparam c_reset_inst   = 32'h00000000;


  //--------------------------------------------------------------------
  // F stage
  //--------------------------------------------------------------------

  wire [31:0] pc_F;
  wire [31:0] pc_next_F;
  wire [31:0] pc_plus4_F;
  wire [31:0] pc_plus4_next_F;
  wire [31:0] br_target_X;
  wire [31:0] j_target_D;

  vc_EnResetReg #(32, c_reset_vector) pc_plus4_reg_F
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_F),
    .d      (pc_plus4_next_F),
    .q      (pc_plus4_F)
  );

  vc_Incrementer #(32, 4) pc_incr_F
  (
    .in   (pc_next_F),
    .out  (pc_plus4_next_F)
  ); 
  
  vc_Mux4#(32) pc_sel_mux_F
  (
    .in0 (pc_plus4_F),
    .in1 (br_target_X),
    .in2 (j_target_D),
	.in3 (rf_rdata0_D),
    .sel (pc_sel_F),
    .out (pc_next_F)
  ); 

  assign imemreq_msg_addr = pc_next_F;

  // note: we don't need pc_F except to draw the line tracing

  vc_EnResetReg #(32) pc_reg_F
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_F),
    .d      (pc_next_F),
    .q      (pc_F)
  );

  //--------------------------------------------------------------------
  // D stage
  //--------------------------------------------------------------------

  wire  [31:0] pc_plus4_D;
  wire  [31:0] inst_D;
  wire   [4:0] inst_rs_D;
  wire   [4:0] inst_rt_D;
  wire   [4:0] inst_rd_D;
  wire   [4:0] inst_shamt_D;
  wire  [15:0] inst_imm_D;
  wire  [31:0] inst_imm_sext_D;
  wire  [25:0] inst_target_D;
  wire  [31:0] inst_imm_zext_D;
  wire  [31:0] shamt_out;

  vc_EnResetReg #(32) pc_plus4_reg_Df
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_D),
    .d      (pc_plus4_F),
    .q      (pc_plus4_D)
  );

  vc_EnResetReg #(32, c_reset_inst) inst_D_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_D),
    .d      (imemresp_msg_data),
    .q      (inst_D)
  );

  pisa_InstUnpack inst_unpack
  (
    .inst     (inst_D),
    .opcode   (),
    .rs       (inst_rs_D),
    .rt       (inst_rt_D),
    .rd       (inst_rd_D),
    .shamt    (inst_shamt_D),
    .func     (),
    .imm      (inst_imm_D),
    .target   (inst_target_D)
  );

  wire [ 4:0] rf_raddr0_D = inst_rs_D;
  wire [31:0] rf_rdata0_D;
  wire [ 4:0] rf_raddr1_D = inst_rt_D;
  wire [31:0] rf_rdata1_D;

  plab2_proc_Regfile rfile
  (
    .clk         (clk),
    .reset       (reset),
    .read_addr0  (rf_raddr0_D),
    .read_data0  (rf_rdata0_D),
    .read_addr1  (rf_raddr1_D),
    .read_data1  (rf_rdata1_D),
    .write_en    (rf_wen_W),
    .write_addr  (rf_waddr_W),
    .write_data  (rf_wdata_W)
  );

  wire [31:0] op0_D;
  wire [31:0] op1_D;

  //assign op0_D = rf_rdata0_D;

  vc_SignExtender #(16, 32) imm_sext_D
  (
    .in   (inst_imm_D),
    .out  (inst_imm_sext_D)
  );

  vc_Mux5 #(32) op1_sel_mux_D
  (
    .in0  (rf_rdata1_D),
    .in1  (inst_imm_sext_D),
    .in2  (from_mngr_data),
    .in3  (pc_plus4_D),
	.in4  (inst_imm_zext_D),
    .sel  (op1_sel_D),
    .out  (op1_D)
  );

  wire [31:0] br_target_D;

  plab2_proc_BrTarget br_target_calc_D
  (
    .pc_plus4  (pc_plus4_D),
    .imm_sext  (inst_imm_sext_D),
    .br_target (br_target_D)
  );

  plab2_proc_JTarget j_target_calc_D
  (
    .pc_plus4 (pc_plus4_D),
    .imm_target (inst_target_D),
    .j_target (j_target_D)
  );
  
  vc_ZeroExtender #(16, 32) imm_zext_D
  (
    .in  (inst_imm_D),
	.out (inst_imm_zext_D)
  );
  
  vc_SignExtender #(5, 32) shamt_D
  (
    .in  (inst_shamt_D),
	.out (shamt_out)
  );

  vc_Mux3 #(32) op0_sel_mux_D
  (
    .in0 (rf_rdata0_D),
	.in1 (shamt_out),
	.in2 (32'd16),
	.sel (op0_sel_D),
	.out (op0_D)
  );
 
  //--------------------------------------------------------------------
  // X stage
  //--------------------------------------------------------------------

  wire [31:0] op0_X;
  wire [31:0] op1_X;
  
  //mul
  wire [66:0] op01_D;
  wire [31:0] imul_out;
  

  vc_EnResetReg #(32, 0) op0_reg_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (op0_D),
    .q      (op0_X)
  );

  vc_EnResetReg #(32, 0) op1_reg_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (op1_D),
    .q      (op1_X)
  );


  vc_EnResetReg #(32, 0) br_target_reg_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (br_target_D),
    .q      (br_target_X)
  );


  vc_EqComparator #(32) br_cond_eq_comp_X
  (
    .in0  (op0_X),
    .in1  (op1_X),
    .out  (br_cond_eq_X)
  );

  wire [31:0] alu_result_X;
  wire [31:0] ex_result_X;

  plab2_proc_Alu alu
  (
    .in0  (op0_X),
    .in1  (op1_X),
    .fn   (alu_fn_X),
    .out  (alu_result_X)
  );
  
  vc_EnResetReg #(32, 0) dmem_write_data_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (rf_rdata1_D),
    .q      (dmemreq_msg_data)
  );
  
  plab1_imul_MulDivReqMsgPack plab1_1
  (
    .func  (3'd0),
	.a     (op0_D),
	.b     (op1_D),
	.msg   (op01_D)
  );
  
  plab1_imul_IntMulVarLat plab1_2
  (
    .clk     (clk),
	.reset   (reset),
	.in_val  (in_val_0),
	.in_rdy  (in_rdy_1),
	.in_msg  (op01_D),
	.out_val (out_val_1),
	.out_rdy (out_rdy_0),
	.out_msg (imul_out)
  );
  
  vc_Mux2 #(32) ex_result_mux
  (
    .in0    (alu_result_X),
    .in1    (imul_out),
    .sel    (ex_sel_X),
    .out    (ex_result_X)
  );
  
  //assign ex_result_X = alu_result_X;

  assign dmemreq_msg_addr = alu_result_X;

  //--------------------------------------------------------------------
  // M stage
  //--------------------------------------------------------------------

  wire [31:0] ex_result_M;

  vc_EnResetReg #(32, 0) ex_result_reg_M
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_M),
    .d      (ex_result_X),
    .q      (ex_result_M)
  );

  wire [31:0] dmem_result_M;
  wire [31:0] wb_result_M;

  assign dmem_result_M = dmemresp_msg_data;

  vc_Mux2 #(32) wb_result_sel_mux_M
  (
    .in0    (ex_result_M),
    .in1    (dmem_result_M),
    .sel    (wb_result_sel_M),
    .out    (wb_result_M)
  );


  //--------------------------------------------------------------------
  // W stage
  //--------------------------------------------------------------------

  wire [31:0] wb_result_W;

  vc_EnResetReg #(32, 0) wb_result_reg_W
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_W),
    .d      (wb_result_M),
    .q      (wb_result_W)
  );

  assign to_mngr_data = wb_result_W;

  wire [31:0] rf_wdata_W = wb_result_W;

endmodule

`endif

