//=========================================================================
// 5-Stage Stall Pipelined Processor Control
//=========================================================================

`ifndef PLAB2_PROC_PIPELINED_PROC_STALL_CTRL_V
`define PLAB2_PROC_PIPELINED_PROC_STALL_CTRL_V

`include "vc-PipeCtrl.v"
`include "vc-assert.v"
`include "pisa-inst.v"

module plab2_proc_PipelinedProcStallCtrl
(
  input clk,
  input reset,

  // Instruction Memory Port

  output        imemreq_val,
  input         imemreq_rdy,

  input         imemresp_val,
  output        imemresp_rdy,

  output        imemresp_drop,

  // Data Memory Port

  output        dmemreq_val,
  input         dmemreq_rdy,

  input         dmemresp_val,
  output        dmemresp_rdy,
  
  output        dmemreq_msg_type,

  // mngr communication port

  input         from_mngr_val,
  output        from_mngr_rdy,

  output        to_mngr_val,
  input         to_mngr_rdy,

  // control signals (ctrl->dpath)

  output  [1:0] pc_sel_F,
  output        reg_en_F,
  output        reg_en_D,
  output        reg_en_X,
  output        reg_en_M,
  output        reg_en_W,
  output [1:0]  op0_sel_D,
  output [2:0]  op1_sel_D,
  output [3:0]  alu_fn_X,
  output        wb_result_sel_M,
  output [4:0]  rf_waddr_W,
  output        rf_wen_W,

  // status signals (dpath->ctrl)

  input [31:0]  inst_D,
  input         br_cond_eq_X,
  
  //mul
  output         in_val_0,
  output         out_rdy_0,
  input          in_rdy_1,
  input          out_val_1,
  
  output         ex_sel_X 

);

  //----------------------------------------------------------------------
  // F stage
  //----------------------------------------------------------------------

  wire reg_en_F;
  wire val_F;
  wire stall_F;
  wire squash_F;

  wire val_FD;
  wire stall_FD;
  wire squash_FD;

  wire stall_PF;
  wire squash_PF;

  vc_PipeCtrl pipe_ctrl_F
  (
    .clk         ( clk       ),
    .reset       ( reset     ),

    .prev_val    ( 1'b1      ),
    .prev_stall  ( stall_PF  ),
    .prev_squash ( squash_PF ),

    .curr_reg_en ( reg_en_F  ),
    .curr_val    ( val_F     ),
    .curr_stall  ( stall_F   ),
    .curr_squash ( squash_F  ),

    .next_val    ( val_FD    ),
    .next_stall  ( stall_FD  ),
    .next_squash ( squash_FD )
  );

  // PC Mux select

  localparam pm_x     = 2'dx; // Don't care
  localparam pm_p     = 2'd0; // Use pc+4
  localparam pm_b     = 2'd1; // Use branch address
  localparam pm_j     = 2'd2;// Use jump address  

  wire [1:0]  br_pc_sel_X;
  wire [1:0] j_pc_sel_D;

  assign pc_sel_F = ( br_pc_sel_X ? br_pc_sel_X :
                    (  j_pc_sel_D ? j_pc_sel_D  :
                                           pm_p ) );

  wire stall_imem_F;

  assign imemreq_val = !stall_PF;

  assign imemresp_rdy = !stall_FD;
  assign stall_imem_F = !imemresp_val && !imemresp_drop;

  // we drop the mem response when we are getting squashed

  assign imemresp_drop = squash_FD && !stall_FD;

  assign stall_F = stall_imem_F;
  assign squash_F = 1'b0;


  //----------------------------------------------------------------------
  // D stage
  //----------------------------------------------------------------------

  wire reg_en_D;
  wire val_D;
  wire stall_D;
  wire squash_D;

  wire val_DX;
  wire stall_DX;
  wire squash_DX;

  vc_PipeCtrl pipe_ctrl_D
  (
    .clk         ( clk       ),
    .reset       ( reset     ),

    .prev_val    ( val_FD    ),
    .prev_stall  ( stall_FD  ),
    .prev_squash ( squash_FD ),

    .curr_reg_en ( reg_en_D  ),
    .curr_val    ( val_D     ),
    .curr_stall  ( stall_D   ),
    .curr_squash ( squash_D  ),

    .next_val    ( val_DX    ),
    .next_stall  ( stall_DX  ),
    .next_squash ( squash_DX )
  );

  // decode logic

  // Parse instruction fields

  wire   [4:0] inst_rs_D;
  wire   [4:0] inst_rt_D;
  wire   [4:0] inst_rd_D;

  pisa_InstUnpack inst_unpack
  (
    .inst     (inst_D),
    .opcode   (),
    .rs       (inst_rs_D),
    .rt       (inst_rt_D),
    .rd       (inst_rd_D),
    .shamt    (),
    .func     (),
    .imm      (),
    .target   ()
  );

  // Shorten register specifier name for table

  wire [4:0] rs = inst_rs_D;
  wire [4:0] rt = inst_rt_D;
  wire [4:0] rd = inst_rd_D;

  // Generic Parameters

  localparam n = 1'd0;
  localparam y = 1'd1;

  // Register specifiers

  localparam rx = 5'bx;
  localparam r0 = 5'd0;
  localparam rL = 5'd31;

  // Branch type

  localparam br_x     = 2'dx; // Don't care
  localparam br_none  = 2'd0; // No branch
  localparam br_bne   = 2'd1; // bne
  localparam br_beq   = 2'd2; // beq
  
  // Operand 0 Mux Select
  localparam pm_xn    = 2'dx; // Don't care
  localparam pm_rdat  = 2'd0; // use data rs
  localparam pm_s     = 2'd1; // use shamt
  localparam pm_i     = 2'd2; // 16
  
  // Operand 1 Mux Select

  localparam bm_x     = 3'bx; // Don't care
  localparam bm_rdat  = 3'd0; // Use data from register file
  localparam bm_si    = 3'd1; // Use sign-extended immediate
  localparam bm_fhst  = 3'd2; // Use from mngr data
  localparam bm_pc    = 3'd3; // Use from pc+4
  localparam bm_zi    = 3'd4; // zext

  // ALU Function

  localparam alu_x    = 4'bx;
  localparam alu_add  = 4'd0;
  localparam alu_sub  = 4'd1;
  localparam alu_sll  = 4'd2;
  localparam alu_or   = 4'd3;
  localparam alu_lt   = 4'd4;
  localparam alu_ltu  = 4'd5;
  localparam alu_and  = 4'd6;
  localparam alu_xor  = 4'd7;
  localparam alu_nor  = 4'd8;
  localparam alu_srl  = 4'd9;
  localparam alu_sra  = 4'd10;
  localparam alu_cp0  = 4'd11;
  localparam alu_cp1  = 4'd12;

  // Memory Request Type

  localparam nr       = 2'd0; // No request
  localparam ld       = 2'd1; // Load
  localparam st       = 2'd2; // Store

  // Writeback Mux Select

  localparam wm_x     = 1'bx; // Don't care
  localparam wm_a     = 1'b0; // Use ALU output
  localparam wm_m     = 1'b1; // Use data memory response

  // Instruction Decode

  reg       inst_val_D;
  reg [1:0] br_type_D;
  reg       rs_en_D;
  reg [1:0] op0_sel_D;
  reg       rt_en_D;
  reg [2:0] op1_sel_D;
  reg [3:0] alu_fn_D;
  reg [1:0] dmemreq_type_D;
  reg       wb_result_sel_D;
  reg       rf_wen_D;
  reg [4:0] rf_waddr_D;
  reg       to_mngr_val_D;
  reg       from_mngr_rdy_D;
  reg [1:0] j_type_D;
  reg       ex_sel_D;
 
  // Jump type
  localparam j_x = 2'dx; // Don't care
  localparam j_n = 2'd0; // No jump
  localparam j_j = 2'd1; // jump (imm)
  localparam j_r = 2'd2; // jr
  
  // mul
  localparam sel_n = 1'dx;
  localparam sel_0 = 1'd0;
  localparam sel_1 = 1'd1;
  
  task cs
  (
    input       cs_val,
    input [1:0] cs_j_type,
    input [1:0] cs_br_type,
    input       cs_rs_en,
	input [1:0] cs_op0_sel,
    input [2:0] cs_op1_sel,
    input       cs_rt_en,
    input [3:0] cs_alu_fn,
    input [1:0] cs_dmemreq_type,
    input       cs_wb_result_sel,
    input       cs_rf_wen,
    input [4:0] cs_rf_waddr,
	input       cs_ex_sel_X,
    input       cs_to_mngr_val,
    input       cs_from_mngr_rdy
  );
  begin
    inst_val_D       = cs_val;
    j_type_D         = cs_j_type;
    br_type_D        = cs_br_type;
    rs_en_D          = cs_rs_en;
	op0_sel_D        = cs_op0_sel;
    op1_sel_D        = cs_op1_sel;
    rt_en_D          = cs_rt_en;
    alu_fn_D         = cs_alu_fn;
    dmemreq_type_D   = cs_dmemreq_type;
    wb_result_sel_D  = cs_wb_result_sel;
    rf_wen_D         = cs_rf_wen;
    rf_waddr_D       = cs_rf_waddr;
	ex_sel_D         = cs_ex_sel_X;
    to_mngr_val_D    = cs_to_mngr_val;
    from_mngr_rdy_D  = cs_from_mngr_rdy;
  end
  endtask


  always @ (*) begin

    casez ( inst_D )

      //                         j      br      rs op1      op0      rt alu      dmm wbmux rf            thst fhst
      //                     val type   type    en muxsel            en fn       typ sel   wen wa        val  rdy
      `PISA_INST_NOP     :cs( y, j_n,  br_none, n, pm_xn,   bm_x,    n, alu_x,   nr, wm_a, n,  rx, sel_0, n,   n   );

      `PISA_INST_ADDU    :cs( y, j_n,  br_none, y, pm_rdat, bm_rdat, y, alu_add, nr, wm_a, y,  rd, sel_0, n,   n   );

      `PISA_INST_BNE     :cs( y, j_n,  br_bne,  y, pm_rdat, bm_rdat, y, alu_x,   nr, wm_a, n,  rx, sel_0, n,   n   );

      `PISA_INST_LW      :cs( y, j_n,  br_none, y, pm_rdat, bm_si,   n, alu_add, ld, wm_m, y,  rt, sel_0, n,   n   );

      `PISA_INST_MFC0    :cs( y, j_n,  br_none, n, pm_xn,   bm_fhst, n, alu_cp1, nr, wm_a, y,  rt, sel_0, n,   y   );
      `PISA_INST_MTC0    :cs( y, j_n,  br_none, n, pm_xn,   bm_rdat, y, alu_cp1, nr, wm_a, n,  rx, sel_0, y,   n   );
      `PISA_INST_J       :cs( y, j_j,  br_none, n, pm_xn,   bm_x,    n, alu_x,   nr, wm_x, n,  rx, sel_0, n,   n   );
      `PISA_INST_JAL     :cs( y, j_j,  br_none, n, pm_xn,   bm_pc,   n, alu_cp1, nr, wm_a, y,  rL, sel_0, n,   n   );
      `PISA_INST_BEQ     :cs( y, j_n,  br_beq,  y, pm_rdat, bm_rdat, y, alu_x,   nr, wm_a, n,  rx, sel_0, n,   n   );
	  `PISA_INST_ADDIU   :cs( y, j_n,  br_none, y, pm_rdat, bm_si,   n, alu_add, nr, wm_a, y,  rt, sel_0, n,   n   );
      `PISA_INST_ORI     :cs( y, j_n,  br_none, y, pm_rdat, bm_zi,   n, alu_or,  nr, wm_a, y,  rt, sel_0, n,   n   );
	  `PISA_INST_OR      :cs( y, j_n,  br_none, y, pm_rdat, bm_rdat, y, alu_or,  nr, wm_a, y,  rd, sel_0, n,   n   );
	  `PISA_INST_AND     :cs( y, j_n,  br_none, y, pm_rdat, bm_rdat, y, alu_and, nr, wm_a, y,  rd, sel_0, n,   n   );
	  `PISA_INST_SRA     :cs( y, j_n,  br_none, n, pm_s,    bm_rdat, y, alu_sra, nr, wm_a, y,  rd, sel_0, n,   n   );
	  `PISA_INST_SLL     :cs( y, j_n,  br_none, n, pm_s,    bm_rdat, y, alu_sll, nr, wm_a, y,  rd, sel_0, n,   n   );
	  `PISA_INST_LUI     :cs( y, j_n,  br_none, n, pm_i,    bm_zi,   y, alu_sll, nr, wm_a, y,  rt, sel_0, n,   n   );
	  `PISA_INST_SUBU    :cs( y, j_n,  br_none, y, pm_rdat, bm_rdat, y, alu_sub, nr, wm_a, y,  rd, sel_0, n,   n   );
	  `PISA_INST_SLT     :cs( y, j_n,  br_none, y, pm_rdat, bm_rdat, y, alu_lt,  nr, wm_a, y,  rd, sel_0, n,   n   );
	  `PISA_INST_SW      :cs( y, j_n,  br_none, y, pm_rdat, bm_si,   y, alu_add, st, wm_x, n,  rx, sel_0, n,   n   );
      `PISA_INST_JR      :cs( y, j_r,  br_none, y, pm_xn,   bm_x,    n, alu_x,   nr, wm_x, n,  rx, sel_0, n,   n   );
	  
	  `PISA_INST_MUL     :cs( y, j_n,  br_none, y, pm_rdat, bm_rdat, y, alu_x,   nr, wm_a, y,  rd, sel_1, n,   n   ); 
	   
	   
      default            :cs( n, j_n,   br_x,   n, pm_xn,   bm_x,    n, alu_x,   nr, wm_x, n,  rx, sel_0, n,   n   );

    endcase
  end

  //mul begin

  //assign in_val_0 = ((inst_D == `PISA_INST_MUL)?(1'd1):(1'd0));
 // assign in_val_0 = 1'd0;
  assign in_val_0 = ((ex_sel_D == sel_1)?(1'd1):(1'd0));
  //mul end
  
  wire stall_from_mngr_D;
  wire stall_hazard_D;
  
  assign j_pc_sel_D = (val_D && (j_type_D == j_j))? pm_j:pm_p; 

  // from mngr rdy signal for mfc0 instruction

  assign from_mngr_rdy =     ( val_D
                            && from_mngr_rdy_D
                            && !stall_FD );

  assign stall_from_mngr_D = ( val_D
                            && from_mngr_rdy_D
                            && !from_mngr_val );

  // Stall for data hazards if either of the operand read addresses are
  // the same as the write addresses of instruction later in the pipeline

  assign stall_hazard_D     = val_D && (
                            ( rs_en_D && val_X && rf_wen_X
                              && ( inst_rs_D == rf_waddr_X )
                              && ( rf_waddr_X != 5'd0 ) )
                         || ( rs_en_D && val_M && rf_wen_M
                              && ( inst_rs_D == rf_waddr_M )
                              && ( rf_waddr_M != 5'd0 ) )
                         || ( rs_en_D && val_W && rf_wen_W
                              && ( inst_rs_D == rf_waddr_W )
                              && ( rf_waddr_W != 5'd0 ) )
                         || ( rt_en_D && val_X && rf_wen_X
                              && ( inst_rt_D == rf_waddr_X )
                              && ( rf_waddr_X != 5'd0 ) )
                         || ( rt_en_D && val_M && rf_wen_M
                              && ( inst_rt_D == rf_waddr_M )
                              && ( rf_waddr_M != 5'd0 ) )
                         || ( rt_en_D && val_W && rf_wen_W
                              && ( inst_rt_D == rf_waddr_W )
                              && ( rf_waddr_W != 5'd0 ) ) );


//  assign stall_D = ((in_rdy_1)?(stall_from_mngr_D || stall_hazard_D):((out_val_1)?(stall_from_mngr_D || stall_hazard_D):(1'd1)));
 // assign stall_D = ((in_rdy_1)?(stall_from_mngr_D || stall_hazard_D):(0));
 
  wire  stall_D_mul;
  assign stall_D_mul = (!in_rdy_1); 
 
  assign stall_D = (stall_from_mngr_D||stall_hazard_D)||(stall_D_mul);
 
  wire squash_j_D;
  // assign squash_j_D = (j_pc_sel_D == pm_j);
  assign out_rdy_0 = 1'd1;
	
  assign squash_j_D = (val_D && ((j_type_D ==j_j)||(j_type_D == j_r)));
  assign squash_D = squash_j_D;
  //----------------------------------------------------------------------
  // X stage
  //----------------------------------------------------------------------

  wire reg_en_X;
  wire val_X;
  wire stall_X;
  wire squash_X;

  wire val_XM;
  wire stall_XM;
  wire squash_XM;

  vc_PipeCtrl pipe_ctrl_X
  (
    .clk         ( clk       ),
    .reset       ( reset     ),

    .prev_val    ( val_DX    ),
    .prev_stall  ( stall_DX  ),
    .prev_squash ( squash_DX ),

    .curr_reg_en ( reg_en_X  ),
    .curr_val    ( val_X     ),
    .curr_stall  ( stall_X   ),
    .curr_squash ( squash_X  ),

    .next_val    ( val_XM    ),
    .next_stall  ( stall_XM  ),
    .next_squash ( squash_XM )
  );

  reg [31:0] inst_X;
  reg [3:0]  alu_fn_X;
  reg [1:0]  dmemreq_type_X;
  reg        wb_result_sel_X;
  reg        rf_wen_X;
  reg [4:0]  rf_waddr_X;
  reg        to_mngr_val_X;
  reg [1:0]  br_type_X;
  reg        ex_sel_X;

  always @(posedge clk) begin
    if (reset) begin
      rf_wen_X      <= 1'b0;
    end else if (reg_en_X) begin
      inst_X          <= inst_D;
      alu_fn_X        <= alu_fn_D;
      dmemreq_type_X  <= dmemreq_type_D;
      wb_result_sel_X <= wb_result_sel_D;
      rf_wen_X        <= rf_wen_D;
      rf_waddr_X      <= rf_waddr_D;
      to_mngr_val_X   <= to_mngr_val_D;
      br_type_X       <= br_type_D;
	  ex_sel_X        <= ex_sel_D;
    end
  end

  // branch logic

  reg        br_taken_X;
  wire       squash_br_X;

  always @(*) begin
    if ( val_X ) begin

      case ( br_type_X )
        br_bne:  br_taken_X = !br_cond_eq_X;
		br_beq:  br_taken_X =  br_cond_eq_X;
        default: br_taken_X = 1'b0;
      endcase

    end else
     br_taken_X = 1'b0;
  end

  assign br_pc_sel_X = br_taken_X ? pm_b : pm_p;

  // squash the previous instructions on branch
  //assign squash_br_X =((br_type_X == br_beq)||(br_type_X == br_bne));
  assign squash_br_X = br_taken_X;

  wire dmemreq_val_X;
  wire stall_dmem_X;

  assign dmemreq_val_X = val_X && ( dmemreq_type_X != nr );

  assign dmemreq_val  = dmemreq_val_X && !stall_XM;
  assign stall_dmem_X = dmemreq_val_X && !dmemreq_rdy;

  //mul stall
  wire stall_X_mul;
  assign stall_X_mul = (!out_val_1)&&(!in_rdy_1);
  
  // stall in X if dmem is not rdy

  assign stall_X = stall_dmem_X||(stall_X_mul);
  assign squash_X = squash_br_X;
  
  //assign dmemreq_msg_type = (!nr==0)&&(dmemreq_type_X == st);
  assign dmemreq_msg_type = dmemreq_type_X[1];
  //----------------------------------------------------------------------
  // M stage
  //----------------------------------------------------------------------

  wire reg_en_M;
  wire val_M;
  wire stall_M;
  wire squash_M;

  wire val_MW;
  wire stall_MW;
  wire squash_MW;

  vc_PipeCtrl pipe_ctrl_M
  (
    .clk         ( clk       ),
    .reset       ( reset     ),

    .prev_val    ( val_XM    ),
    .prev_stall  ( stall_XM  ),
    .prev_squash ( squash_XM ),

    .curr_reg_en ( reg_en_M  ),
    .curr_val    ( val_M     ),
    .curr_stall  ( stall_M   ),
    .curr_squash ( squash_M  ),

    .next_val    ( val_MW    ),
    .next_stall  ( stall_MW  ),
    .next_squash ( squash_MW )
  );

  reg [31:0] inst_M;
  reg [1:0]  dmemreq_type_M;
  reg        wb_result_sel_M;
  reg        rf_wen_M;
  reg [4:0]  rf_waddr_M;
  reg        to_mngr_val_M;

  always @(posedge clk) begin
    if (reset) begin
      rf_wen_M        <= 1'b0;
    end 
	else if (reg_en_M) begin
      inst_M          <= inst_X;
      dmemreq_type_M  <= dmemreq_type_X;
      wb_result_sel_M <= wb_result_sel_X;
      rf_wen_M        <= rf_wen_X;
      rf_waddr_M      <= rf_waddr_X;
      to_mngr_val_M   <= to_mngr_val_X;
    end
  end

  wire dmemreq_val_M;
  wire stall_dmem_M;

  assign dmemresp_rdy = dmemreq_val_M && !stall_MW;

  assign dmemreq_val_M = val_M && ( dmemreq_type_M != nr );
  assign stall_dmem_M = ( dmemreq_val_M && !dmemresp_val );

  assign stall_M = stall_dmem_M;
  assign squash_M = 1'b0;
  
  //assign dmemreq_msg_type = (dmemreq_type_M == st); 

  //----------------------------------------------------------------------
  // W stage
  //----------------------------------------------------------------------

  wire reg_en_W;
  wire val_W;
  wire stall_W;
  wire squash_W;

  wire next_stall_W;
  wire next_squash_W;

  assign next_stall_W = 1'b0;
  assign next_squash_W = 1'b0;

  vc_PipeCtrl pipe_ctrl_W
  (
    .clk         ( clk       ),
    .reset       ( reset     ),

    .prev_val    ( val_MW    ),
    .prev_stall  ( stall_MW  ),
    .prev_squash ( squash_MW ),

    .curr_reg_en ( reg_en_W  ),
    .curr_val    ( val_W     ),
    .curr_stall  ( stall_W   ),
    .curr_squash ( squash_W  ),

    .next_stall  ( next_stall_W  ),
    .next_squash ( next_squash_W )
  );

  reg [31:0] inst_W;
  reg        rf_wen_W;
  reg [4:0]  rf_waddr_W;
  reg        to_mngr_val_W;
  wire       stall_to_mngr_W;

  always @(posedge clk) begin
    if (reset) begin
      rf_wen_W      <= 1'b0;
    end else if (reg_en_W) begin
      inst_W        <= inst_M;
      rf_wen_W      <= rf_wen_M;
      rf_waddr_W    <= rf_waddr_M;
      to_mngr_val_W <= to_mngr_val_M;
    end
  end

  assign to_mngr_val = ( val_W
                      && to_mngr_val_W
                      && !stall_MW );

  assign stall_to_mngr_W = ( val_W
                          && to_mngr_val_W
                          && !to_mngr_rdy );

  assign stall_W = stall_to_mngr_W;
  assign squash_W = 1'b0;

endmodule

`endif

