//========================================================================
// Router Output Ctrl
//========================================================================

`ifndef PLAB4_NET_ROUTER_OUTPUT_CTRL_V
`define PLAB4_NET_ROUTER_OUTPUT_CTRL_V

`include "vc-arbiters.v"

module plab4_net_RouterOutputCtrl
(
  input        clk,
  input        reset,

  input  [2:0] reqs,
  output [2:0] grants,

  output       out_val,
  input        out_rdy,
  output [1:0] xbar_sel
);

  // add logic here

 // assign grants = 0;
 // assign out_val = 0;
 // assign xbar_sel = 0;
  
  wire [2:0] grants0;
 
  vc_RoundRobinArb #(3) roar1
  (
    .clk (clk),
	.reset (reset),
	.reqs (reqs),
	.grants (grants0)
  );
  
	//  assign grants =( out_rdy? grants :3'b000);
  assign grants = (out_rdy ? grants0 : 3'b000);
  
  assign xbar_sel = (grants[0]?2'd0
                    :(grants[1]?2'd1
                    :(grants[2]?2'd2:2'dx)));
				
  assign out_val = ((grants == 3'b000)?0:1);	

  
endmodule

`endif /* PLAB4_NET_ROUTER_OUTPUT_CTRL_V */
