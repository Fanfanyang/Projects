//========================================================================
// Router Input Terminal Ctrl
//========================================================================

`ifndef PLAB4_NET_ROUTER_INPUT_TERMINAL_CTRL_V
`define PLAB4_NET_ROUTER_INPUT_TERMINAL_CTRL_V

`include "vc-arithmetic.v"
`include "vc-arbiters.v"

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
  input  [2:0]                 grants,
  
  input                       out0_rdy, 
  input                       out2_rdy,
  
  input  clk,
  input  reset
  
//  input                       out2_rdy_1,
//  input                       out0_rdy_1
  
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

  wire [2:0] reqs0;
  wire [2:0] reqs1;
  wire [2:0] reqs2;
  wire [2:0] reqs3;
  
  //----------------------------------------------------------------
  // second try
  //----------------------------------------------------------------
  /*
  wire [3:0] sub_2_l;
  wire [3:0] sub_1_r;
  wire [2:0] free_l;
  wire [2:0] free_r;
  wire [3:0] free_west;
  wire [3:0] free_east;
  
  wire [3:0] sub_1_1;
  wire [3:0] sub_2_1;
  wire [2:0] num_free_west_1;
  wire [2:0] num_free_east_1;
  
  assign sub_1_1 = {1'b0, sub_1};
  assign sub_2_1 = {1'b0, sub_2};
  assign num_free_west_1 = {1'b0, num_free_west};
  assign num_free_east_1 = {1'b0, num_free_east};
  
  vc_Subtractor #(4) sub3
  (
    .in0 (4'd8),
	.in1 (sub_2_1),
	.out (sub_2_l)
  );
  
  vc_Subtractor #(4) sub4
  (
    .in0 (4'd8),
	.in1 (sub_1_1),
	.out (sub_1_r)
  );
  
  vc_Subtractor #(3) sub5
  (
    .in0 (3'd4),
	.in1 (num_free_west_1),
	.out (free_l)
  );
  
  vc_Subtractor #(3) sub6
  (
    .in0 (3'd4),
	.in1 (num_free_east_1),
	.out (free_r)
  );
  
  assign free_west = {1'b0, free_l};
  assign free_east = {1'b0, free_r};
  
  wire [3:0] differ1;
  wire [3:0] differ2;
  wire [3:0] differ3;
  wire [3:0] differ4;
  
  vc_SimpleAdder #(4) adder1
  (
  .in0 (free_west),
  .in1 (sub_2_l),
  .out (differ1)
  );
  
  vc_SimpleAdder #(4) adder2
  (
  .in0 (free_east),
  .in1 (sub_2_l),
  .out (differ2)
  );
  
  vc_SimpleAdder #(4) adder3
  (
  .in0 (free_west),
  .in1 (sub_1_r),
  .out (differ3)
  );
  
  vc_SimpleAdder #(4) adder4
  (
  .in0 (free_east),
  .in1 (sub_1_r),
  .out (differ4)
  );
  
  assign reqs = ((((num_free_west >= p_num_free_nbits)&&(in_val))
                 && (((compare1_2 == 1) && (differ1 > differ2)) 
				 || ((compare1_1 == 1) && (differ3 > differ4)))
				 ) ? 3'b100 :
				 ((((num_free_east >= p_num_free_nbits)&&(in_val))
                 && (((compare1_2 == 1) && (differ1 < differ2)) 
				 || ((compare1_1 == 1) && (differ3 < differ4)))
				 ) ? 3'b001 :
				 (((!compare1_1)&&(!compare1_2)&&(in_val)) ?
				 3'b010 : reqs1)));
	
  wire [1:0] reqs3_refer;	
	
  vc_RoundRobinArb #(2) random
  (
    .clk (clk),
	.reset (reset),
	.reqs (2'b11),
	.grants (reqs3_refer)
  );
	
  assign reqs1 = ((((compare1_2 == 1) && (differ1 == differ2)) 
				 || ((compare1_1 == 1) && (differ3 == differ4)))
				 &&(in_val)
				 && (reqs3_refer[0])) ?
				 ((num_free_west >= p_num_free_nbits) ? 3'b100 : 3'b000) :
				 ((((compare1_2 == 1) && (differ1 == differ2)) 
				 || ((compare1_1 == 1) && (differ3 == differ4)))
				 &&(in_val)
				 && (!reqs3_refer[0])) ?
				 ((num_free_east >= p_num_free_nbits) ? 3'b001 : 3'b000) : 
				 3'b000;
 
 */				 
  
  
  
  
  
  
  // the first time
  
 /*assign reqs = (((((compare1_1 == 1)&&((sub_1 >= 4)||((sub_1 == 4)&&(out2_rdy == 1))))
                ||((compare1_2 == 1)&&((sub_2 <= 4)||((sub_2 == 4)&&(out2_rdy == 1)))))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&((sub_1 < 4)||((sub_1 == 4)&&(out0_rdy == 1))))
				||((compare1_2 == 1)&&((sub_2 > 4)||((sub_1 == 4)&&(out0_rdy == 1)))))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));*/
				
				
	// try 1			
				
 /* assign reqs = (((((compare1_1 == 1)&&(sub_1 >= 4))||((compare1_2 == 1)&&(sub_2 <= 4))
                 ||((out2_rdy)&&(!out0_rdy)))
                 &&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4))
				||((out0_rdy)&&(!out2_rdy)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));*/
				
    //try 2
	
/*	wire [1:0] reqs3_refer;
	
  vc_RoundRobinArb #(2) random
  (
    .clk (clk),
	.reset (reset),
	.reqs (2'b11),
	.grants (reqs3_refer)
  );
  
  assign reqs3 = ((reqs3_refer[0]) ? 3'b100 : 3'b001); 
	
  assign reqs = (((compare1_1 == 1)&&(sub_1 <= 2))||((compare1_2 == 1)&&(sub_2 <= 2)))
                 ? reqs1 : reqs0;
	
  assign reqs1 = (((((compare1_1 == 1)&&(sub_1 >= 4))||((compare1_2 == 1)&&(sub_2 <= 4)))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));
  
  assign reqs0 = (((num_free_west >= p_num_free_nbits)&&(in_val)&&
                  (out2_rdy)&&(!out0_rdy)) ? 3'b100:
				  (((num_free_east >= p_num_free_nbits)&&(in_val)&&
				  (out0_rdy)&&(!out2_rdy)) ? 3'b001: reqs2));

  assign reqs2 = (((in_val)&&(num_free_west >= p_num_free_nbits)&&(num_free_east < p_num_free_nbits))
				  ? 3'b100 :
				  (((in_val)&&(num_free_east >= p_num_free_nbits)&&(num_free_west < p_num_free_nbits))
				  ? 3'b001 : 
				  (((in_val)&&(num_free_west >= p_num_free_nbits)&&(num_free_east >= p_num_free_nbits))
				  ? reqs3 : 3'b000)));	*/	 
	

  // base and want try	
  
 /* assign reqs0 = (((((compare1_1 == 1)&&(sub_1 >= 4))||((compare1_2 == 1)&&(sub_2 <= 4)))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));
				
  assign reqs1 = (((num_free_west >= p_num_free_nbits)&&(in_val)&&(out2_rdy_1)&&(!out0_rdy_1))?
                3'b100:
                (((num_free_east >= p_num_free_nbits)&&(in_val)&&(out0_rdy_1)&&(!out2_rdy_1))?
                3'b001:reqs0));

  assign reqs = (((num_free_west >= p_num_free_nbits)&&(in_val)&&(out2_rdy)&&(!out0_rdy))?
                3'b100:
                (((num_free_east >= p_num_free_nbits)&&(in_val)&&(out0_rdy)&&(!out2_rdy))?
                3'b001:reqs1));		*/		
				
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
