//========================================================================
// Test Harness for plab4-net-RouterAlt
//========================================================================

`include "vc-TestRandDelaySource.v"
`include "vc-TestRandDelayUnorderedSink.v"
`include "vc-test.v"
`include "vc-net-msgs.v"
`include "plab4-net-RouterAlt.v"

//------------------------------------------------------------------------
// Test Harness
//------------------------------------------------------------------------

module TestHarness
#(
  parameter p_payload_nbits = 8,
  parameter p_opaque_nbits  = 8,
  parameter p_srcdest_nbits = 2
)
(
  input         clk,
  input         reset,
  input  [31:0] src_max_delay,
  input  [31:0] sink_max_delay,
  output [31:0] num_failed,
  output        done
);

  // Local parameters

  localparam c_num_routers = 8;
  localparam c_router_id   = 2;
  localparam c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s);

  // shorter names

  localparam p = p_payload_nbits;
  localparam o = p_opaque_nbits;
  localparam s = p_srcdest_nbits;


  //----------------------------------------------------------------------
  // Test sources
  //----------------------------------------------------------------------

  wire                       src0_val;
  wire                       src0_rdy;
  wire [c_net_msg_nbits-1:0] src0_msg;
  wire                       src0_done;

  wire                       src1_val;
  wire                       src1_rdy;
  wire [c_net_msg_nbits-1:0] src1_msg;
  wire                       src1_done;

  wire                       src2_val;
  wire                       src2_rdy;
  wire [c_net_msg_nbits-1:0] src2_msg;
  wire                       src2_done;


  vc_TestRandDelaySource#(c_net_msg_nbits) src0
  (
    .clk        (clk),
    .reset      (reset),
    .max_delay  (src_max_delay),
    .val        (src0_val),
    .rdy        (src0_rdy),
    .msg        (src0_msg),
    .done       (src0_done)
  );

  vc_TestRandDelaySource#(c_net_msg_nbits) src1
  (
    .clk        (clk),
    .reset      (reset),
    .max_delay  (src_max_delay),
    .val        (src1_val),
    .rdy        (src1_rdy),
    .msg        (src1_msg),
    .done       (src1_done)
  );

  vc_TestRandDelaySource#(c_net_msg_nbits) src2
  (
    .clk        (clk),
    .reset      (reset),
    .max_delay  (src_max_delay),
    .val        (src2_val),
    .rdy        (src2_rdy),
    .msg        (src2_msg),
    .done       (src2_done)
  );

  //----------------------------------------------------------------------
  // Router under test
  //----------------------------------------------------------------------

  wire                       sink0_val;
  wire                       sink0_rdy;
  wire [c_net_msg_nbits-1:0] sink0_msg;

  wire                       sink1_val;
  wire                       sink1_rdy;
  wire [c_net_msg_nbits-1:0] sink1_msg;

  wire                       sink2_val;
  wire                       sink2_rdy;
  wire [c_net_msg_nbits-1:0] sink2_msg;
  
  wire out2_rdy_1;
  wire out2_rdy_0;
  wire out0_rdy_1;
  wire out0_rdy_0;
  
  wire out2_rdy_3;
  wire out2_rdy_2;
  wire out0_rdy_3;
  wire out0_rdy_2;


  plab4_net_RouterAlt
  #(
    .p_payload_nbits (p_payload_nbits),
    .p_opaque_nbits  (p_opaque_nbits),
    .p_srcdest_nbits (p_srcdest_nbits),

    .p_router_id     (c_router_id),
    .p_num_routers   (c_num_routers)
  )
  router
  (
    .clk      (clk),
    .reset    (reset),

    .in0_val  (src0_val),
    .in0_rdy  (src0_rdy),
    .in0_msg  (src0_msg),

    .in1_val  (src1_val),
    .in1_rdy  (src1_rdy),
    .in1_msg  (src1_msg),

    .in2_val  (src2_val),
    .in2_rdy  (src2_rdy),
    .in2_msg  (src2_msg),

    .out0_val (sink0_val),
    .out0_rdy (sink0_rdy),
    .out0_msg (sink0_msg),

    .out1_val (sink1_val),
    .out1_rdy (sink1_rdy),
    .out1_msg (sink1_msg),

    .out2_val (sink2_val),
    .out2_rdy (sink2_rdy),
    .out2_msg (sink2_msg),
	
	.out2_rdy_1 (out2_rdy_1),
	.out2_rdy_0 (out2_rdy_0),
	.out0_rdy_1 (out0_rdy_1),
	.out0_rdy_0 (out0_rdy_0),
	
	.out2_rdy_3 (out2_rdy_3),
	.out2_rdy_2 (out2_rdy_2),
	.out0_rdy_3 (out0_rdy_3),
	.out0_rdy_2 (out0_rdy_2)
  );

  //----------------------------------------------------------------------
  // Test sinks
  //----------------------------------------------------------------------

  wire [31:0] sink0_num_failed;
  wire [31:0] sink1_num_failed;
  wire [31:0] sink2_num_failed;

  wire sink0_done;
  wire sink1_done;
  wire sink2_done;

  // We use unordered sinks because the messages can come out of order

  vc_TestRandDelayUnorderedSink#(c_net_msg_nbits) sink0
  (
    .clk        (clk),
    .reset      (reset),
    .max_delay  (sink_max_delay),
    .val        (sink0_val),
    .rdy        (sink0_rdy),
    .msg        (sink0_msg),
    .num_failed (sink0_num_failed),
    .done       (sink0_done)
  );

  vc_TestRandDelayUnorderedSink#(c_net_msg_nbits) sink1
  (
    .clk        (clk),
    .reset      (reset),
    .max_delay  (sink_max_delay),
    .val        (sink1_val),
    .rdy        (sink1_rdy),
    .msg        (sink1_msg),
    .num_failed (sink1_num_failed),
    .done       (sink1_done)
  );

  vc_TestRandDelayUnorderedSink#(c_net_msg_nbits) sink2
  (
    .clk        (clk),
    .reset      (reset),
    .max_delay  (sink_max_delay),
    .val        (sink2_val),
    .rdy        (sink2_rdy),
    .msg        (sink2_msg),
    .num_failed (sink2_num_failed),
    .done       (sink2_done)
  );


  // Done when all of sources and sinks are done

  assign done = src0_done  && src1_done  && src2_done  &&
                sink0_done && sink1_done && sink2_done;

  // Num failed is the sum of all sinks

  assign num_failed = sink0_num_failed + sink1_num_failed +
                      sink2_num_failed;


  //----------------------------------------------------------------------
  // Line Tracing
  //----------------------------------------------------------------------

  `include "vc-trace-tasks.v"
  reg [4*8-1:0] src0_str;
  reg [4*8-1:0] src1_str;
  reg [4*8-1:0] src2_str;

  reg [4*8-1:0] sink0_str;
  reg [4*8-1:0] sink1_str;
  reg [4*8-1:0] sink2_str;

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    $sformat( src0_str, "%x>%x",
              src0_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)],
              src0_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)] );
    vc_trace_str_val_rdy( trace, src0_val, src0_rdy, src0_str );

    vc_trace_str( trace, "|" );

    $sformat( src1_str, "%x>%x",
              src1_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)],
              src1_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)] );
    vc_trace_str_val_rdy( trace, src1_val, src1_rdy, src1_str );

    vc_trace_str( trace, "|" );

    $sformat( src2_str, "%x>%x",
              src2_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)],
              src2_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)] );
    vc_trace_str_val_rdy( trace, src2_val, src2_rdy, src2_str );

    vc_trace_str( trace, " > " );

    router.trace_module( trace );

    vc_trace_str( trace, " > " );

    $sformat( sink0_str, "%x>%x",
              sink0_msg[`VC_NET_MSG_SRC_FIELD(p,o,s)],
              sink0_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );
    vc_trace_str_val_rdy( trace, sink0_val, sink0_rdy, sink0_str );

    vc_trace_str( trace, "|" );

    $sformat( sink1_str, "%x>%x",
              sink1_msg[`VC_NET_MSG_SRC_FIELD(p,o,s)],
              sink1_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );
    vc_trace_str_val_rdy( trace, sink1_val, sink1_rdy, sink1_str );

    vc_trace_str( trace, "|" );

    $sformat( sink2_str, "%x>%x",
              sink2_msg[`VC_NET_MSG_SRC_FIELD(p,o,s)],
              sink2_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );
    vc_trace_str_val_rdy( trace, sink2_val, sink2_rdy, sink2_str );
  end
  endtask

endmodule

//------------------------------------------------------------------------
// Main Tester Module
//------------------------------------------------------------------------

module top;
  `VC_TEST_SUITE_BEGIN( "plab4-net-RouterAlt" )

  //----------------------------------------------------------------------
  // Test setup
  //----------------------------------------------------------------------

  // Local parameters

  localparam p_num_ports     = 8;

  localparam c_payload_nbits = 8;
  localparam c_opaque_nbits  = 8;
  localparam c_srcdest_nbits = 3;

  // shorter names

  localparam p = c_payload_nbits;
  localparam o = c_opaque_nbits;
  localparam s = c_srcdest_nbits;

  localparam c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s);

  reg         th_reset = 1;
  reg  [31:0] th_src_max_delay;
  reg  [31:0] th_sink_max_delay;
  wire [31:0] th_num_failed;
  wire        th_done;

  reg [10:0] th_src_index  [2:0];
  reg [10:0] th_sink_index [2:0];

  TestHarness
  #(
    .p_payload_nbits    (c_payload_nbits),
    .p_opaque_nbits     (c_opaque_nbits),
    .p_srcdest_nbits    (c_srcdest_nbits)
  )
  th
  (
    .clk            (clk),
    .reset          (th_reset),
    .src_max_delay  (th_src_max_delay),
    .sink_max_delay (th_sink_max_delay),
    .num_failed     (th_num_failed),
    .done           (th_done)
  );

  // Helper task to initialize source/sink delays
  integer i;
  task init_rand_delays
  (
    input [31:0] src_max_delay,
    input [31:0] sink_max_delay
  );
  begin
    // we also reset the src/sink indexes
    th_src_index[0] = 0;
    th_src_index[1] = 0;
    th_src_index[2] = 0;
    th_sink_index[0] = 0;
    th_sink_index[1] = 0;
    th_sink_index[2] = 0;

    th_src_max_delay  = src_max_delay;
    th_sink_max_delay = sink_max_delay;
  end
  endtask


  task init_src
  (
    input [31:0]   port,

    input [c_net_msg_nbits-1:0] msg
  );
  begin

    case ( port )
      0: begin
        th.src0.src.m[ th_src_index[port] ] = msg;

        // we load xs for the next address so that src/sink messages don't
        // bleed to the next one

        th.src0.src.m[ th_src_index[port] + 1] = 'hx;
      end
      1: begin
        th.src1.src.m[ th_src_index[port] ] = msg;

        // we load xs for the next address so that src/sink messages don't
        // bleed to the next one

        th.src1.src.m[ th_src_index[port] + 1] = 'hx;
      end
      2: begin
        th.src2.src.m[ th_src_index[port] ] = msg;

        // we load xs for the next address so that src/sink messages don't
        // bleed to the next one

        th.src2.src.m[ th_src_index[port] + 1] = 'hx;
      end
    endcase

    // increment the index
    th_src_index[port] = th_src_index[port] + 1;

  end
  endtask

  task init_sink
  (
    input [31:0]   port,

    input [c_net_msg_nbits-1:0] msg
  );
  begin

    case ( port )
      0: begin
        th.sink0.sink.m[ th_sink_index[port] ] = msg;

        // we load xs for the next address so that sink/sink messages don't
        // bleed to the next one

        th.sink0.sink.m[ th_sink_index[port] + 1] = 'hx;
      end
      1: begin
        th.sink1.sink.m[ th_sink_index[port] ] = msg;

        // we load xs for the next address so that sink/sink messages don't
        // bleed to the next one

        th.sink1.sink.m[ th_sink_index[port] + 1] = 'hx;
      end
      2: begin
        th.sink2.sink.m[ th_sink_index[port] ] = msg;

        // we load xs for the next address so that sink/sink messages don't
        // bleed to the next one

        th.sink2.sink.m[ th_sink_index[port] + 1] = 'hx;
      end
    endcase

    // increment the index
    th_sink_index[port] = th_sink_index[port] + 1;

  end
  endtask


  reg [c_net_msg_nbits-1:0] th_port_msg;

  task init_net_msg
  (
    input [1:0]                                  in_port,
    input [1:0]                                  out_port,

    input [`VC_NET_MSG_SRC_NBITS(p,o,s)-1:0]     src,
    input [`VC_NET_MSG_DEST_NBITS(p,o,s)-1:0]    dest,
    input [`VC_NET_MSG_OPAQUE_NBITS(p,o,s)-1:0]  opaque,
    input [`VC_NET_MSG_PAYLOAD_NBITS(p,o,s)-1:0] payload
  );
  begin

    th_port_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)]    = dest;
    th_port_msg[`VC_NET_MSG_SRC_FIELD(p,o,s)]     = src;
    th_port_msg[`VC_NET_MSG_PAYLOAD_FIELD(p,o,s)] = payload;
    th_port_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)]  = opaque;

    init_src(  in_port,  th_port_msg );
    init_sink( out_port, th_port_msg );

  end
  endtask

  // Load the common dataset

  task init_common;
  begin
    //            in    out   src   dest  opq    payload
    init_net_msg( 2'h0, 2'h2, 3'h1, 3'h3, 8'h00, 8'hce );
    init_net_msg( 2'h2, 2'h0, 3'h7, 3'h0, 8'h05, 8'hfe );
    init_net_msg( 2'h1, 2'h1, 3'h2, 3'h2, 8'h30, 8'h09 );
    init_net_msg( 2'h2, 2'h0, 3'h4, 3'h1, 8'h10, 8'hfe );
    init_net_msg( 2'h0, 2'h2, 3'h1, 3'h4, 8'h15, 8'h9f );
    init_net_msg( 2'h2, 2'h1, 3'h3, 3'h2, 8'h32, 8'hdf );
    init_net_msg( 2'h0, 2'h2, 3'h1, 3'h3, 8'h23, 8'hfe );
    init_net_msg( 2'h0, 2'h1, 3'h1, 3'h2, 8'h31, 8'hb0 );
    init_net_msg( 2'h1, 2'h0, 3'h2, 3'h1, 8'h70, 8'h89 );
  end
  endtask

  // Helper task to run test

  task run_test;
  begin
    #1;   th_reset = 1'b1;
    #20;  th_reset = 1'b0;

    while ( !th_done && (th.trace_cycles < 500) ) begin
      th.trace_display();
      #10;
    end

    `VC_TEST_INCREMENT_NUM_FAILED( th_num_failed );
    `VC_TEST_NET( th_done, 1'b1 );
  end
  endtask

  //----------------------------------------------------------------------
  // basic test, no delay
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 1, "basic test, no delay" )
  begin
    init_rand_delays( 0, 0 );
    init_common;
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // basic test, src delay = 3, sink delay = 10
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 2, "basic test, src delay = 3, sink delay = 10" )
  begin
    init_rand_delays( 3, 10 );
    init_common;
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // basic test, src delay = 10, sink delay = 3
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 3, "basic test, src delay = 10, sink delay = 3" )
  begin
    init_rand_delays( 10, 3 );
    init_common;
    run_test;
  end
  `VC_TEST_CASE_END


  `VC_TEST_SUITE_END
endmodule

