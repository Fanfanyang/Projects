//========================================================================
// plab4-net-RingNetBase
//========================================================================

`ifndef PLAB4_NET_RING_NET_BASE
`define PLAB4_NET_RING_NET_BASE

`include "vc-net-msgs.v"
`include "vc-param-utils.v"
`include "vc-queues.v"
`include "plab4-net-RouterBase.v"

// macros to calculate previous and next router ids

`define PREV(i_)  ( ( i_ + c_num_ports - 1 ) % c_num_ports )
`define NEXT(i_)  i_

module plab4_net_RingNetBase
#(
  parameter p_payload_nbits  = 32,
  parameter p_opaque_nbits   = 3,
  parameter p_srcdest_nbits  = 3,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits,

  parameter c_num_ports = 8,
  parameter c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s),

  parameter m = c_net_msg_nbits
)
(
  input clk,
  input reset,

  input  [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] in_val,
  output [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] in_rdy,
  input  [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] in_msg,

  output [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] out_val,
  input  [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] out_rdy,
  output [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] out_msg
);

  //----------------------------------------------------------------------
  // Router-router connection wires
  //----------------------------------------------------------------------

  // forward (increasing router id) wires

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] forw_out_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] forw_out_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] forw_out_msg;

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] forw_in_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] forw_in_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] forw_in_msg;

  // backward (decreasing router id) wires

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] backw_out_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] backw_out_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] backw_out_msg;

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] backw_in_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] backw_in_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] backw_in_msg;

  //----------------------------------------------------------------------
  // Router generation
  //----------------------------------------------------------------------

  genvar i;

  generate
    for ( i = 0; i < c_num_ports; i = i + 1 ) begin: ROUTER

      plab4_net_RouterBase
      #(
        .p_payload_nbits  (p_payload_nbits),
        .p_opaque_nbits   (p_opaque_nbits),
        .p_srcdest_nbits  (p_srcdest_nbits),

        .p_router_id      (i),
        .p_num_routers    (c_num_ports)
      )
      router
      (
        .clk      (clk),
        .reset    (reset),

        .in0_val  (forw_in_val[`VC_PORT_PICK_FIELD(1,`PREV(i))]),
        .in0_rdy  (forw_in_rdy[`VC_PORT_PICK_FIELD(1,`PREV(i))]),
        .in0_msg  (forw_in_msg[`VC_PORT_PICK_FIELD(m,`PREV(i))]),

        .in1_val  (in_val[`VC_PORT_PICK_FIELD(1,i)]),
        .in1_rdy  (in_rdy[`VC_PORT_PICK_FIELD(1,i)]),
        .in1_msg  (in_msg[`VC_PORT_PICK_FIELD(m,i)]),

        .in2_val  (backw_in_val[`VC_PORT_PICK_FIELD(1,`NEXT(i))]),
        .in2_rdy  (backw_in_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(i))]),
        .in2_msg  (backw_in_msg[`VC_PORT_PICK_FIELD(m,`NEXT(i))]),

        .out0_val (backw_out_val[`VC_PORT_PICK_FIELD(1,`PREV(i))]),
        .out0_rdy (backw_out_rdy[`VC_PORT_PICK_FIELD(1,`PREV(i))]),
        .out0_msg (backw_out_msg[`VC_PORT_PICK_FIELD(m,`PREV(i))]),

        .out1_val (out_val[`VC_PORT_PICK_FIELD(1,i)]),
        .out1_rdy (out_rdy[`VC_PORT_PICK_FIELD(1,i)]),
        .out1_msg (out_msg[`VC_PORT_PICK_FIELD(m,i)]),

        .out2_val (forw_out_val[`VC_PORT_PICK_FIELD(1,`NEXT(i))]),
        .out2_rdy (forw_out_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(i))]),
        .out2_msg (forw_out_msg[`VC_PORT_PICK_FIELD(m,`NEXT(i))])
      );


    end
  endgenerate

  //----------------------------------------------------------------------
  // Channel generation
  //----------------------------------------------------------------------

  generate
    for ( i = 0; i < c_num_ports; i = i + 1 ) begin: CHANNEL

      vc_Queue
      #(
        .p_type       (`VC_QUEUE_NORMAL),
        .p_msg_nbits  (c_net_msg_nbits),
        .p_num_msgs   (2)
      )
      forw_channel_queue
      (
        .clk      (clk),
        .reset    (reset),

        .enq_val  (forw_out_val[`VC_PORT_PICK_FIELD(1,i)]),
        .enq_rdy  (forw_out_rdy[`VC_PORT_PICK_FIELD(1,i)]),
        .enq_msg  (forw_out_msg[`VC_PORT_PICK_FIELD(m,i)]),

        .deq_val  (forw_in_val[`VC_PORT_PICK_FIELD(1,i)]),
        .deq_rdy  (forw_in_rdy[`VC_PORT_PICK_FIELD(1,i)]),
        .deq_msg  (forw_in_msg[`VC_PORT_PICK_FIELD(m,i)])
      );

      vc_Queue
      #(
        .p_type       (`VC_QUEUE_NORMAL),
        .p_msg_nbits  (c_net_msg_nbits),
        .p_num_msgs   (2)
      )
      backw_channel_queue
      (
        .clk      (clk),
        .reset    (reset),

        .enq_val  (backw_out_val[`VC_PORT_PICK_FIELD(1,i)]),
        .enq_rdy  (backw_out_rdy[`VC_PORT_PICK_FIELD(1,i)]),
        .enq_msg  (backw_out_msg[`VC_PORT_PICK_FIELD(m,i)]),

        .deq_val  (backw_in_val[`VC_PORT_PICK_FIELD(1,i)]),
        .deq_rdy  (backw_in_rdy[`VC_PORT_PICK_FIELD(1,i)]),
        .deq_msg  (backw_in_msg[`VC_PORT_PICK_FIELD(m,i)])
      );

    end
  endgenerate


  //----------------------------------------------------------------------
  // Line Tracing
  //----------------------------------------------------------------------

  `include "vc-trace-tasks.v"

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin
    ROUTER[0].router.trace_module( trace );
    ROUTER[1].router.trace_module( trace );
    ROUTER[2].router.trace_module( trace );
    ROUTER[3].router.trace_module( trace );
    ROUTER[4].router.trace_module( trace );
    ROUTER[5].router.trace_module( trace );
    ROUTER[6].router.trace_module( trace );
    ROUTER[7].router.trace_module( trace );
  end
  endtask

endmodule

`endif /* PLAB4_NET_RING_NET_BASE */
