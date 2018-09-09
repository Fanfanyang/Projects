//========================================================================
// Router Input Ctrl
//========================================================================

`ifndef PLAB4_NET_ROUTER_INPUT_CTRL_V
`define PLAB4_NET_ROUTER_INPUT_CTRL_V

`include "vc-arithmetic.v"

module plab4_net_RouterInputCtrl
#(
  parameter p_router_id   = 0,
  parameter p_num_routers = 8,

  // parameter not meant to be set outside this module

  parameter c_dest_nbits = $clog2( p_num_routers )

)
(
  input  [c_dest_nbits-1:0] dest,

  input                     in_val,
  output                    in_rdy,

  output [2:0]              reqs,
  input  [2:0]              grants
);

//---------------------------------------------------------------
// use arithmetic
//----------------------------------------------------------------

  wire compare1_1;
  wire compare1_2;
  wire [2:0] sub_1;
  wire [2:0] sub_2;
  
  vc_LtComparator #(3) compare1
  (
    .in0 (dest),
	.in1 (p_router_id[2:0]),
	.out (compare1_1)
  );
  
  vc_GtComparator #(3) compare2
  (
    .in0 (dest),
	.in1 (p_router_id[2:0]),
	.out (compare1_2)
  );
  
  vc_Subtractor #(3) sub1
  (
    .in0 (p_router_id[2:0]),
	.in1 (dest),
	.out (sub_1)
  );
  
  vc_Subtractor #(3) sub2
  (
    .in0 (dest),
	.in1 (p_router_id[2:0]),
	.out (sub_2)
  );

  assign reqs = ((!in_val)? 3'b000:
                ((((compare1_1 == 1)&&(sub_1 >= 4))||((compare1_2 == 1)&&(sub_2 <= 4)))?3'b100:
				((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4)))?3'b001:
				3'b010)));

  assign in_rdy = (((reqs == 3'b100)&&(grants[2] == 1)
                  ||(reqs == 3'b010)&&(grants[1] == 1)
				  ||(reqs == 3'b001)&&(grants[0] == 1))
				  ? 1'b1 : 1'b0);


endmodule

`endif  /* PLAB4_NET_ROUTER_INPUT_CTRL_V */
