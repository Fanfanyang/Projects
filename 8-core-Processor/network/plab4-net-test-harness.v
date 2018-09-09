//========================================================================
// Test Harness for Ring Network
//========================================================================

`include "vc-TestRandDelaySource.v"
`include "vc-TestRandDelayUnorderedSink.v"
`include "vc-test.v"
`include "vc-net-msgs.v"
`include "vc-param-utils.v"

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
  input             clk,
  input             reset,
  input      [31:0] src_max_delay,
  input      [31:0] sink_max_delay,
  output reg [31:0] num_failed,
  output reg        done
);

  // Local parameters

  parameter  c_num_ports     = 8;

  // shorter names

  localparam p = p_payload_nbits;
  localparam o = p_opaque_nbits;
  localparam s = p_srcdest_nbits;

  localparam c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s);

  // Test network wires

  wire [c_num_ports-1:0]                 net_in_val;
  wire [c_num_ports-1:0]                 net_in_rdy;
  wire [c_num_ports*c_net_msg_nbits-1:0] net_in_msg;

  wire [c_num_ports-1:0]                 net_out_val;
  wire [c_num_ports-1:0]                 net_out_rdy;
  wire [c_num_ports*c_net_msg_nbits-1:0] net_out_msg;

  //----------------------------------------------------------------------
  // Generate loop for source/sink
  //----------------------------------------------------------------------

  genvar i;

  generate
  for ( i = 0; i < c_num_ports; i = i + 1 ) begin: SRC_SINK_INIT

    // local wires for the source and sink iteration

    wire                        src_val;
    wire                        src_rdy;
    wire [c_net_msg_nbits-1:0]  src_msg;
    wire                        src_done;

    wire                        sink_val;
    wire                        sink_rdy;
    wire [c_net_msg_nbits-1:0]  sink_msg;

    wire [31:0]                 sink_num_failed;
    wire                        sink_done;

    // connect the local wires to the wide network ports

    assign net_in_val[`VC_PORT_PICK_FIELD(1,i)] = src_val;
    assign net_in_msg[`VC_PORT_PICK_FIELD(c_net_msg_nbits,i)] = src_msg;
    assign src_rdy = net_in_rdy[`VC_PORT_PICK_FIELD(1,i)];

    assign sink_val = net_out_val[`VC_PORT_PICK_FIELD(1,i)];
    assign sink_msg = net_out_msg[`VC_PORT_PICK_FIELD(c_net_msg_nbits,i)];
    assign net_out_rdy[`VC_PORT_PICK_FIELD(1,i)] = sink_rdy;

    vc_TestRandDelaySource#(c_net_msg_nbits) src
    (
      .clk        (clk),
      .reset      (reset),
      .max_delay  (src_max_delay),
      .val        (src_val),
      .rdy        (src_rdy),
      .msg        (src_msg),
      .done       (src_done)
    );

    // We use an unordered sink because the messages can come out of order

    vc_TestRandDelayUnorderedSink#(c_net_msg_nbits) sink
    (
      .clk        (clk),
      .reset      (reset),
      .max_delay  (sink_max_delay),
      .val        (sink_val),
      .rdy        (sink_rdy),
      .msg        (sink_msg),
      .num_failed (sink_num_failed),
      .done       (sink_done)
    );

    // line tracing for the source and sink

    reg [`VC_TRACE_NBITS_TO_NCHARS(c_net_msg_nbits)*8-1:0] src_str;
    reg [`VC_TRACE_NBITS_TO_NCHARS(c_net_msg_nbits)*8-1:0] sink_str;

    task trace_module_src( inout [vc_trace_nbits-1:0] trace );
    begin
      $sformat( src_str, "%x>%x",
                src_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)],
                src_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)] );
      vc_trace_str_val_rdy( trace, src_val, src_rdy, src_str );
    end
    endtask

    task trace_module_sink( inout [vc_trace_nbits-1:0] trace );
    begin
      $sformat( sink_str, "%x>%x",
                sink_msg[`VC_NET_MSG_SRC_FIELD(p,o,s)],
                sink_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );
      vc_trace_str_val_rdy( trace, sink_val, sink_rdy, sink_str );
    end
    endtask


  end
  endgenerate

  //----------------------------------------------------------------------
  // Ring Network under test
  //----------------------------------------------------------------------

  `PLAB4_NET_IMPL
  #(
    .p_payload_nbits  (p_payload_nbits  ),
    .p_opaque_nbits   (p_opaque_nbits   ),
    .p_srcdest_nbits  (p_srcdest_nbits  )
  )
  net
  (
    .clk      (clk),
    .reset    (reset),

    .in_val   (net_in_val),
    .in_rdy   (net_in_rdy),
    .in_msg   (net_in_msg),

    .out_val  (net_out_val),
    .out_rdy  (net_out_rdy),
    .out_msg  (net_out_msg)
  );

  // Accumulate num failed and done signals from all sources and sinks

  integer j;
  always @(*) begin
    num_failed = 0;
    done       = 1;
    for ( j = 0; j < c_num_ports; j = j + 1 ) begin
      `VC_GEN_CALL_8( num_failed = num_failed + SRC_SINK_INIT, j,
                      sink_num_failed );
      `VC_GEN_CALL_8( done = done & SRC_SINK_INIT, j, src_done );
      `VC_GEN_CALL_8( done = done & SRC_SINK_INIT, j, sink_done );
    end
  end

  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------

  `include "vc-trace-tasks.v"

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    for ( j = 0; j < c_num_ports; j = j + 1 ) begin
      if ( j != 0 )
        vc_trace_str( trace, "|" );

      `VC_GEN_CALL_8( SRC_SINK_INIT, j, trace_module_src( trace ) );
    end

    vc_trace_str( trace, " > " );

    net.trace_module( trace );

    vc_trace_str( trace, " > " );

    for ( j = 0; j < c_num_ports; j = j + 1 ) begin
      if ( j != 0 )
        vc_trace_str( trace, "|" );

      `VC_GEN_CALL_8( SRC_SINK_INIT, j, trace_module_sink( trace ) );
    end

  end
  endtask

endmodule

//------------------------------------------------------------------------
// Main Tester Module
//------------------------------------------------------------------------

module top;
  `VC_TEST_SUITE_BEGIN( `PLAB4_NET_IMPL_STR )

  //----------------------------------------------------------------------
  // Test setup
  //----------------------------------------------------------------------

  // Local parameters

  localparam c_num_ports     = 8;

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

  reg [10:0] th_src_index  [10:0];
  reg [10:0] th_sink_index [10:0];

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
    // we also clear the src/sink indexes and contents
    for ( i = 0; i < c_num_ports; i = i + 1 ) begin
      th_src_index[i] = 0;
      th_sink_index[i] = 0;
      `VC_GEN_CALL_8( th.SRC_SINK_INIT, i,
                      src.src.m[0] = 'hx );
      `VC_GEN_CALL_8( th.SRC_SINK_INIT, i,
                      sink.sink.m[0] = 'hx );
    end
    th_src_max_delay  = src_max_delay;
    th_sink_max_delay = sink_max_delay;
  end
  endtask


  task init_src
  (
    input [31:0]                port,

    input [c_net_msg_nbits-1:0] msg
  );
  begin

    `VC_GEN_CALL_8( th.SRC_SINK_INIT, port,
                    src.src.m[th_src_index[port]] = msg );

    `VC_GEN_CALL_8( th.SRC_SINK_INIT, port,
                    src.src.m[th_src_index[port] + 1] = 'hx );

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

    `VC_GEN_CALL_8( th.SRC_SINK_INIT, port,
                    sink.sink.m[th_sink_index[port]] = msg );

    `VC_GEN_CALL_8( th.SRC_SINK_INIT, port,
                    sink.sink.m[th_sink_index[port] + 1] = 'hx );

    // increment the index
    th_sink_index[port] = th_sink_index[port] + 1;

  end
  endtask

  reg [c_net_msg_nbits-1:0] th_port_msg;

  task init_net_msg
  (
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

    // call the respective src and sink
    init_src(  src,  th_port_msg );
    init_sink( dest, th_port_msg );

  end
  endtask

  // Helper task to run test

  task run_test;
  begin
    #1;   th_reset = 1'b1;
    #20;  th_reset = 1'b0;

    while ( !th_done && (th.trace_cycles < 1500) ) begin
      th.trace_display();
      #10;
    end

    `VC_TEST_INCREMENT_NUM_FAILED( th_num_failed );
    `VC_TEST_NET( th_done, 1'b1 );
  end
  endtask

  //----------------------------------------------------------------------
  // single source
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 1, "single source" )
  begin
    init_rand_delays( 0, 0 );

    //            src   dest  opq    payload
    init_net_msg( 3'h0, 3'h0, 8'h00, 8'hce );
    init_net_msg( 3'h0, 3'h1, 8'h01, 8'hff );
    init_net_msg( 3'h0, 3'h2, 8'h02, 8'h80 );
    init_net_msg( 3'h0, 3'h3, 8'h03, 8'hc0 );
    init_net_msg( 3'h0, 3'h4, 8'h04, 8'h55 );
    init_net_msg( 3'h0, 3'h5, 8'h05, 8'h96 );
    init_net_msg( 3'h0, 3'h6, 8'h06, 8'h32 );
    init_net_msg( 3'h0, 3'h7, 8'h07, 8'h2e );

    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // single destination
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 2, "single dest" )
  begin
    init_rand_delays( 0, 0 );

    //            src   dest  opq    payload
    init_net_msg( 3'h0, 3'h0, 8'h00, 8'hce );
    init_net_msg( 3'h1, 3'h0, 8'h01, 8'hff );
    init_net_msg( 3'h2, 3'h0, 8'h02, 8'h80 );
    init_net_msg( 3'h3, 3'h0, 8'h03, 8'hc0 );
    init_net_msg( 3'h4, 3'h0, 8'h04, 8'h55 );
    init_net_msg( 3'h5, 3'h0, 8'h05, 8'h96 );
    init_net_msg( 3'h6, 3'h0, 8'h06, 8'h32 );
    init_net_msg( 3'h7, 3'h0, 8'h07, 8'h2e );

    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // neighbor
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 3, "neighbor" )
  begin
    init_rand_delays( 0, 0 );

    //            src   dest  opq    payload
    init_net_msg( 3'h0, 3'h1, 8'h00, 8'hce );
    init_net_msg( 3'h1, 3'h2, 8'h01, 8'hff );
    init_net_msg( 3'h2, 3'h3, 8'h02, 8'h80 );
    init_net_msg( 3'h3, 3'h4, 8'h03, 8'hc0 );
    init_net_msg( 3'h4, 3'h5, 8'h04, 8'h55 );
    init_net_msg( 3'h5, 3'h6, 8'h05, 8'h96 );
    init_net_msg( 3'h6, 3'h7, 8'h06, 8'h32 );
    init_net_msg( 3'h7, 3'h0, 8'h07, 8'h2e );

    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // streaming neighbor
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 4, "streaming neighbor" )
  begin
    init_rand_delays( 0, 0 );

    for ( i = 0; i < 50; i = i + 1 ) begin
      //            src   dest  opq    payload
      init_net_msg( 3'h0, 3'h1, 8'h00, 8'hce );
      init_net_msg( 3'h1, 3'h2, 8'h01, 8'hff );
      init_net_msg( 3'h2, 3'h3, 8'h02, 8'h80 );
      init_net_msg( 3'h3, 3'h4, 8'h03, 8'hc0 );
      init_net_msg( 3'h4, 3'h5, 8'h04, 8'h55 );
      init_net_msg( 3'h5, 3'h6, 8'h05, 8'h96 );
      init_net_msg( 3'h6, 3'h7, 8'h06, 8'h32 );
      init_net_msg( 3'h7, 3'h0, 8'h07, 8'h2e );

    end

    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // hot spot
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 5, "hot spot" )
  begin
    init_rand_delays( 0, 0 );

    for ( i = 0; i < 50; i = i + 1 ) begin
      //            src   dest  opq    payload
      init_net_msg( 3'h0, 3'h3, 8'h00, 8'hce );
      init_net_msg( 3'h1, 3'h3, 8'h01, 8'hff );
      init_net_msg( 3'h2, 3'h3, 8'h02, 8'h80 );
      init_net_msg( 3'h3, 3'h3, 8'h03, 8'hc0 );
      init_net_msg( 3'h4, 3'h3, 8'h04, 8'h55 );
      init_net_msg( 3'h5, 3'h3, 8'h05, 8'h96 );
      init_net_msg( 3'h6, 3'h3, 8'h06, 8'h32 );
      init_net_msg( 3'h7, 3'h3, 8'h07, 8'h2e );
    end

    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // short sequence
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 6, "short sequence" )
  begin
    init_rand_delays( 0, 0 );

    //            src   dest  opq    payload
    init_net_msg( 3'h0, 3'h1, 8'h00, 8'hce );
    init_net_msg( 3'h2, 3'h0, 8'h01, 8'hfe );
    init_net_msg( 3'h1, 3'h3, 8'h02, 8'h09 );
    init_net_msg( 3'h4, 3'h3, 8'h03, 8'hfe );
    init_net_msg( 3'h1, 3'h0, 8'h04, 8'h9f );
    init_net_msg( 3'h1, 3'h5, 8'h05, 8'hdf );
    init_net_msg( 3'h0, 3'h3, 8'h06, 8'hc9 );
    init_net_msg( 3'h3, 3'h1, 8'h07, 8'hfe );
    init_net_msg( 3'h2, 3'h2, 8'h08, 8'h09 );
    init_net_msg( 3'h0, 3'h1, 8'h09, 8'hfe );
    init_net_msg( 3'h6, 3'h0, 8'h0a, 8'hda );
    init_net_msg( 3'h1, 3'h0, 8'h0b, 8'hd3 );
    init_net_msg( 3'h0, 3'h1, 8'h0c, 8'hce );
    init_net_msg( 3'h2, 3'h0, 8'h0d, 8'hfe );
    init_net_msg( 3'h1, 3'h3, 8'h0e, 8'ha9 );
    init_net_msg( 3'h0, 3'h3, 8'h0f, 8'hfe );
    init_net_msg( 3'h7, 3'h0, 8'h10, 8'h9f );
    init_net_msg( 3'h7, 3'h6, 8'h11, 8'haf );
    init_net_msg( 3'h0, 3'h3, 8'h12, 8'hc9 );
    init_net_msg( 3'h3, 3'h1, 8'h13, 8'hfe );
    init_net_msg( 3'h2, 3'h2, 8'h14, 8'h29 );
    init_net_msg( 3'h0, 3'h1, 8'h15, 8'hfe );
    init_net_msg( 3'h6, 3'h0, 8'h16, 8'hda );
    init_net_msg( 3'h1, 3'h0, 8'h17, 8'hd0 );

    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // random test, no delay
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 7, "random test, no delay" )
  begin
    init_rand_delays( 0, 0 );
    `include "plab4-net-input-gen_urandom.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // random test, src delay = 3, sink delay = 10
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 8, "random test, src delay = 3, sink delay = 10" )
  begin
    init_rand_delays( 3, 10 );
    `include "plab4-net-input-gen_urandom.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // random test, src delay = 10, sink delay = 3
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 9, "random test, src delay = 10, sink delay = 3" )
  begin
    init_rand_delays( 10, 3 );
    `include "plab4-net-input-gen_urandom.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // tornado test, no delay
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN(10, "tornado test, no delay" )
  begin
    init_rand_delays( 0, 0 );
    `include "plab4-net-input-gen_tornado.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // tornado test, src delay = 3, sink delay = 10
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN(11, "tornado test, src delay = 3, sink delay = 10" )
  begin
    init_rand_delays( 3, 1 );//3,10
    `include "plab4-net-input-gen_tornado.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // tornado test, src delay = 10, sink delay = 3
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN(12, "tornado test, src delay = 10, sink delay = 3" )
  begin
    init_rand_delays(10, 1 );//10,3
    `include "plab4-net-input-gen_tornado.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  `VC_TEST_SUITE_END
endmodule

