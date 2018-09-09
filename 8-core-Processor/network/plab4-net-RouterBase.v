//========================================================================
// plab4-net-RouterBase
//========================================================================

`ifndef PLAB4_NET_ROUTER_BASE_V
`define PLAB4_NET_ROUTER_BASE_V

`include "vc-crossbars.v"
`include "vc-queues.v"
`include "vc-mem-msgs.v"
`include "plab4-net-RouterInputCtrl.v"
`include "plab4-net-RouterInputTerminalCtrl.v"
`include "plab4-net-RouterOutputCtrl.v"
`include  "vc-net-msgs.v"

module plab4_net_RouterBase
#(
  parameter p_payload_nbits  = 32,
  parameter p_opaque_nbits   = 3,
  parameter p_srcdest_nbits  = 3,

  parameter p_router_id      = 0,
  parameter p_num_routers    = 8,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits,

  parameter c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s)
)
(
  input                        clk,
  input                        reset,

  input                        in0_val,
  output                       in0_rdy,
  input  [c_net_msg_nbits-1:0] in0_msg,

  input                        in1_val,
  output                       in1_rdy,
  input  [c_net_msg_nbits-1:0] in1_msg,

  input                        in2_val,
  output                       in2_rdy,
  input  [c_net_msg_nbits-1:0] in2_msg,

  output                       out0_val,
  input                        out0_rdy,
  output [c_net_msg_nbits-1:0] out0_msg,

  output                       out1_val,
  input                        out1_rdy,
  output [c_net_msg_nbits-1:0] out1_msg,

  output                       out2_val,
  input                        out2_rdy,
  output [c_net_msg_nbits-1:0] out2_msg

);

  //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------

  wire                       in0_deq_val;
  wire                       in0_deq_rdy;
  wire [c_net_msg_nbits-1:0] in0_deq_msg;

  wire                       in1_deq_val;
  wire                       in1_deq_rdy;
  wire [c_net_msg_nbits-1:0] in1_deq_msg;

  wire                       in2_deq_val;
  wire                       in2_deq_rdy;
  wire [c_net_msg_nbits-1:0] in2_deq_msg;
  
  wire [2:0] num_free_west;
  wire [2:0] num_free_east;
  wire [2:0] num_free;
  
  wire [2:0]       dest0;
  wire [2:0]       dest1;
  wire [2:0]       dest2;

  // instantiate input queues, crossbar and control modules here
  //--------------------------------------------------------------------------
  //input queues
  //--------------------------------------------------------------------------
  
  vc_Queue #(`VC_QUEUE_NORMAL, c_net_msg_nbits, 4) inque_1
  (
    .clk (clk),
	.reset (reset),
	.enq_val (in0_val),
	.enq_rdy (in0_rdy),
	.enq_msg (in0_msg),
	.deq_val (in0_deq_val),
	.deq_rdy (in0_deq_rdy),
	.deq_msg (in0_deq_msg),
	.num_free_entries (num_free_west)
  );
  
  vc_Queue #(`VC_QUEUE_NORMAL, c_net_msg_nbits, 4) inque_2
  (
    .clk (clk),
	.reset (reset),
	.enq_val (in1_val),
	.enq_rdy (in1_rdy),
	.enq_msg (in1_msg),
	.deq_val (in1_deq_val),
	.deq_rdy (in1_deq_rdy),
	.deq_msg (in1_deq_msg),
	.num_free_entries (num_free)
  );
  
  vc_Queue #(`VC_QUEUE_NORMAL, c_net_msg_nbits, 4) inque_3
  (
    .clk (clk),
	.reset (reset),
	.enq_val (in2_val),
	.enq_rdy (in2_rdy),
	.enq_msg (in2_msg),
	.deq_val (in2_deq_val),
	.deq_rdy (in2_deq_rdy),
	.deq_msg (in2_deq_msg),
	.num_free_entries (num_free_east)
  );
  
  //------------------------------------------------------------------
  //unpack message
  //------------------------------------------------------------------
  
  assign dest0 = {in0_deq_msg[(c_net_msg_nbits-1) : (c_net_msg_nbits-3)]};
  assign dest1 = {in1_deq_msg[(c_net_msg_nbits-1) : (c_net_msg_nbits-3)]};
  assign dest2 = {in2_deq_msg[(c_net_msg_nbits-1) : (c_net_msg_nbits-3)]};
//  assign dest0 = in0_deq_msg[21:19];
  
  
  //-------------------------------------------------------------------
  // cross bar
  //-------------------------------------------------------------------
  
  wire [1:0] xbar_sel0;
  wire [1:0] xbar_sel1;
  wire [1:0] xbar_sel2;

  
  
  vc_Crossbar3 #(c_net_msg_nbits) crossbar_1
  (
    .in0 (in0_deq_msg),
	.in1 (in1_deq_msg),
	.in2 (in2_deq_msg),
	.sel0 (xbar_sel0),
	.sel1 (xbar_sel1),
	.sel2 (xbar_sel2),
	.out0 (out0_msg),
	.out1 (out1_msg),
	.out2 (out2_msg)
  );
  
  
  //-------------------------------------------------------------------
  // control unit with bubble flow
  //-------------------------------------------------------------------
  
  //-------------------------------------------------------------------
  // datapath for figure 3
  //-------------------------------------------------------------------
  
  wire [2:0] in_reqs0;
  wire [2:0] in_grants0;
  wire [2:0] in_reqs1;
  wire [2:0] in_grants1;
  wire [2:0] in_reqs2;
  wire [2:0] in_grants2;
  
  wire [2:0] out_reqs0;
  wire [2:0] out_reqs1;
  wire [2:0] out_reqs2;
  
  wire [2:0] out_grants0;
  wire [2:0] out_grants1;
  wire [2:0] out_grants2;
  
  plab4_net_RouterInputCtrl #(p_router_id, p_num_routers) incon1
  (
    .dest (dest0),
	.in_val (in0_deq_val),
    .in_rdy (in0_deq_rdy),
	.reqs (in_reqs0),
	.grants (in_grants0)
  );
  
  plab4_net_RouterInputTerminalCtrl #(p_router_id, p_num_routers, 3) intercon1
  (
    .dest (dest1),
	.in_val (in1_deq_val),
    .in_rdy (in1_deq_rdy),
	.num_free_west (num_free_west),
	.num_free_east (num_free_east),
	.reqs (in_reqs1),
	.grants (in_grants1)
  );
  
  plab4_net_RouterInputCtrl #(p_router_id, p_num_routers) incon2
  (
    .dest (dest2),
	.in_val (in2_deq_val),
    .in_rdy (in2_deq_rdy),
	.reqs (in_reqs2),
	.grants (in_grants2)
  );
  
  //----------------------------------------------------------------------
  // connect reqs & grants
  //----------------------------------------------------------------------
  
  assign out_reqs0 = {in_reqs2[0], in_reqs1[0], in_reqs0[0]};
  assign out_reqs1 = {in_reqs2[1], in_reqs1[1], in_reqs0[1]};
  assign out_reqs2 = {in_reqs2[2], in_reqs1[2], in_reqs0[2]};
  
  assign in_grants0 = {out_grants2[0], out_grants1[0], out_grants0[0]};
  assign in_grants1 = {out_grants2[1], out_grants1[1], out_grants0[1]};
  assign in_grants2 = {out_grants2[2], out_grants1[2], out_grants0[2]};
  
  
  
  
  //---------------------------------------------------------------------
  // output control
  //---------------------------------------------------------------------
  
  plab4_net_RouterOutputCtrl outcon1
  (
    .clk (clk),
	.reset (reset),
	.reqs (out_reqs0),
	.grants (out_grants0),
	.out_val (out0_val),
	.out_rdy (out0_rdy),
	.xbar_sel (xbar_sel0)
  );
  
  plab4_net_RouterOutputCtrl outcon2
  (
    .clk (clk),
	.reset (reset),
	.reqs (out_reqs1),
	.grants (out_grants1),
	.out_val (out1_val),
	.out_rdy (out1_rdy),
	.xbar_sel (xbar_sel1)
  );
  
  plab4_net_RouterOutputCtrl outcon3
  (
    .clk (clk),
	.reset (reset),
	.reqs (out_reqs2),
	.grants (out_grants2),
	.out_val (out2_val),
	.out_rdy (out2_rdy),
	.xbar_sel (xbar_sel2)
  );
  
  
  
  
  
  
  
  


  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------

  `include "vc-trace-tasks.v"

  reg [2*8-1:0] in0_str;
  reg [4*8-1:0] in1_str;
  reg [2*8-1:0] in2_str;

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    $sformat( in0_str, "%x",
              in0_deq_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );
    $sformat( in1_str, "%x>%x",
              in1_deq_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)],
              in1_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)] );
    $sformat( in2_str, "%x",
              in2_deq_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );

    vc_trace_str( trace, "(" );
    vc_trace_str_val_rdy( trace, in0_deq_val, in0_deq_rdy, in0_str );
    vc_trace_str( trace, "|" );
    vc_trace_str_val_rdy( trace, in1_deq_val, in1_deq_rdy, in1_str );
    vc_trace_str( trace, "|" );
    vc_trace_str_val_rdy( trace, in2_deq_val, in2_deq_rdy, in2_str );
    vc_trace_str( trace, ")" );
  end
  endtask

endmodule
`endif /* PLAB4_NET_ROUTER_BASE_V */
