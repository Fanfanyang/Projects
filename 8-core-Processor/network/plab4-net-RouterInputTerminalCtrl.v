//========================================================================
// Router Input Terminal Ctrl
//========================================================================

`ifndef PLAB4_NET_ROUTER_INPUT_TERMINAL_CTRL_V
`define PLAB4_NET_ROUTER_INPUT_TERMINAL_CTRL_V

`include "vc-arithmetic.v"

module plab4_net_RouterInputTerminalCtrl
#(
  parameter p_router_id      = 0,
  parameter p_num_routers    = 8,
  parameter p_num_free_nbits = 2,

  // parameter not meant to be set outside this module

  parameter c_dest_nbits = $clog2( p_num_routers )

)
(
  input  [c_dest_nbits-1:0]    dest,

  input                        in_val,
  output                       in_rdy,

  input [p_num_free_nbits-1:0] num_free_west,
  input [p_num_free_nbits-1:0] num_free_east,

  output [2:0]                 reqs,
  input  [2:0]                 grants
);

//----------------------------------------------------------------------
// same as input part
//----------------------------------------------------------------------

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

  assign reqs = (((((compare1_1 == 1)&&(sub_1 >= 4))||((compare1_2 == 1)&&(sub_2 <= 4)))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));

				  
  //----------------------------------------------------------------------
  // bubble control part
  //----------------------------------------------------------------------

  assign in_rdy = ((((reqs == 3'b100)&&(grants[2] == 1)&&(num_free_west >= p_num_free_nbits))
                  ||((reqs == 3'b010)&&(grants[1] == 1))
				  ||((reqs == 3'b001)&&(grants[0] == 1)&&(num_free_east >= p_num_free_nbits)))
				  ? 1'b1 : 1'b0);

  // add logic here

 // assign in_rdy = 0;
 // assign reqs = 0;

endmodule

`endif  /* PLAB4_NET_ROUTER_INPUT_TERMINAL_CTRL_V */
