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
  input clk,
  input reset,
  
  input  [c_dest_nbits-1:0]    dest,

  input                        in_val,
  output                       in_rdy,

  input [p_num_free_nbits-1:0] num_free_west,
  input [p_num_free_nbits-1:0] num_free_east,

  output [2:0]                 reqs,
  input  [2:0]                 grants,
  
  input                       out0_rdy, 
  input                       out2_rdy,
  
  input                       out2_rdy_1,
  input                       out0_rdy_1,
  input                       out2_rdy_3,
  input                       out0_rdy_3
  
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
  wire [2:0] reqs4;
  wire [2:0] reqs5;
  wire [2:0] reqs6;
  wire [2:0] reqs7;
  
  //wire [2:0] reqs2;
  
  // the first time
  
 /*assign reqs = (((((compare1_1 == 1)&&((sub_1 >= 4)||((sub_1 == 4)&&(out2_rdy == 1))))
                ||((compare1_2 == 1)&&((sub_2 <= 4)||((sub_2 == 4)&&(out2_rdy == 1)))))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&((sub_1 < 4)||((sub_1 == 4)&&(out0_rdy == 1))))
				||((compare1_2 == 1)&&((sub_2 > 4)||((sub_1 == 4)&&(out0_rdy == 1)))))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));*/
				
				
	// try now			
				
  /*assign reqs = (((((compare1_1 == 1)&&(sub_1 >= 4))||((compare1_2 == 1)&&(sub_2 <= 4))
                 ||((out2_rdy)&&(!out0_rdy)))
                 &&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4))
				||((out0_rdy)&&(!out2_rdy)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));*/

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


  //---------------------------------------------------------------------
  // three neighbour part
  //----------------------------------------------------------------------

  wire [3:0] sub_1_1;
  wire [3:0] sub_2_1;
  wire [3:0] sub_2_l;
  wire [3:0] sub_1_r;
  
  wire [6:0] grant_1_r;
  wire [6:0] grant_1_l;
  wire [6:0] grant_2_r;
  wire [6:0] grant_2_l;
  
  assign sub_1_1 = {1'b0, sub_1};
  assign sub_2_1 = {1'b0, sub_2};
  
 /* vc_Subtractor #(4) sub3
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
  );*/

  assign sub_2_l = 4'd8 - sub_2_1;
  assign sub_1_r = 4'd8 - sub_1_1;
  
/*  assign grant_1_r = sub_1_r + 7'd7 - (2*out2_rdy + out2_rdy_1 + out2_rdy_3) ;
  assign grant_1_l = sub_1 + 7'd7 - (2*out0_rdy + out0_rdy_1 + out0_rdy_3) ;
  assign grant_2_r = sub_2 + 7'd7 - (2*out2_rdy + out2_rdy_1 + out2_rdy_3) ;
  assign grant_2_l = sub_2_l + 7'd7 - (2*out0_rdy + out0_rdy_1 + out0_rdy_3) ;

  assign reqs = (((!compare1_1)&&(!compare1_2)&&(in_val)) ? 3'b010:
                (((((compare1_1)&&(grant_1_r < grant_1_l)) 
                || ((compare1_2)&&(grant_2_r < grant_2_l)))
				&& (num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1)&&(grant_1_r > grant_1_l)) 
                || ((compare1_2)&&(grant_2_r > grant_2_l)))
				&& (num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				reqs0)));
				
  assign reqs0 = (((((compare1_1 == 1)&&((sub_1 >= 4)||((sub_1 == 4)&&(out2_rdy == 1))))
                ||((compare1_2 == 1)&&((sub_2 <= 4)||((sub_2 == 4)&&(out2_rdy == 1)))))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&((sub_1 < 4)||((sub_1 == 4)&&(out0_rdy == 1))))
				||((compare1_2 == 1)&&((sub_2 > 4)||((sub_1 == 4)&&(out0_rdy == 1)))))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));*/
  
 /* initial
   begin
   assign  out0_rdy = 0; 
   assign  out2_rdy = 0;
  
   assign   out2_rdy_1 = 0;
   assign   out0_rdy_1 = 0;
   assign   out2_rdy_3 = 0;
   assign   out0_rdy_3 = 0;
    end */
  
  //---------------------------------------------------------------------
  // <=2 : greedy ; 3 : global rdy + greedy, 4: global rdy
  //----------------------------------------------------------------------
  
  wire [1:0] reqs3_refer;
	
  vc_RoundRobinArb #(2) random
  (
    .clk (clk),
	.reset (reset),
	.reqs (2'b11),
	.grants (reqs3_refer)
  );
  
  assign reqs3 = (((reqs3_refer[0])&&(num_free_west >= p_num_free_nbits)&&(in_val))
                  ? 3'b100 : 
				  ((reqs3_refer[1])&&(num_free_east >= p_num_free_nbits)&&(in_val))
				  ? 3'b001 : 3'b000);
  
  assign grant_1_r = sub_1_r + 7'd7 - (3*out2_rdy + 2*out2_rdy_1 + out2_rdy_3) ;
  assign grant_1_l = sub_1_1 + 7'd7 - (3*out0_rdy + 2*out0_rdy_1 + out0_rdy_3) ;
  assign grant_2_r = sub_2_1 + 7'd7 - (3*out2_rdy + 2*out2_rdy_1 + out2_rdy_3) ;
  assign grant_2_l = sub_2_l + 7'd7 - (3*out0_rdy + 2*out0_rdy_1 + out0_rdy_3) ;
  
 /* assign grant_1_r = 7'd9 - (4*out2_rdy + 3*out2_rdy_1 + 2*out2_rdy_3) ;
  assign grant_1_l = 7'd9 - (4*out0_rdy + 3*out0_rdy_1 + 2*out0_rdy_3) ;
  assign grant_2_r = 7'd9 - (4*out2_rdy + 3*out2_rdy_1 + 2*out2_rdy_3) ;
  assign grant_2_l = 7'd9 - (4*out0_rdy + 3*out0_rdy_1 + 2*out0_rdy_3) ;*/
	
	wire [6:0] grant1;//1=3
	wire [6:0] grant2;
	
  assign grant1 = 4*out2_rdy + 3*out2_rdy_1 + 2*out2_rdy_3 ;
  assign grant2 = 4*out0_rdy + 3*out0_rdy_1 + 2*out0_rdy_3 ;
	
    assign reqs = ((((compare1_1 == 1)&&((sub_1 <= 2)||(sub_1 >= 6)))
	             ||((compare1_2 == 1)&&((sub_2 <= 2)||(sub_2 >= 6))))
                 ? reqs1 : 
				 ((((compare1_1 == 1)&&((sub_1 == 3)||(sub_1 == 5)))
	             ||((compare1_2 == 1)&&((sub_2 == 3)||(sub_2 == 5)))) ?
				 reqs0 : reqs2));
	
    assign reqs1 = (((((compare1_1 == 1)&&(sub_1 > 4))||((compare1_2 == 1)&&(sub_2 < 4)))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));
				
	// second in here
	
	assign reqs4 = (((((compare1_1 == 1)&&(sub_1 > 4))||((compare1_2 == 1)&&(sub_2 < 4)))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: 3'b000)));
				
	assign reqs0 = (((!compare1_1)&&(!compare1_2)&&(in_val)) ? 3'b010:
                (((((compare1_1 == 1)&&(grant_1_r < grant_1_l)) //sub_1_r < sub_1_1
                || ((compare1_2 == 1)&&(grant_2_r < grant_2_l))) //sub_2_1 < sub_2_l
				&& (num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(grant_1_r > grant_1_l)) //sub_1_r > sub_1_1 
                || ((compare1_2 == 1)&&(grant_2_r > grant_2_l))) //sub_2_1 > sub_2_l 
				&& (num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				reqs4)));
	
   assign reqs2 = (((!compare1_1)&&(!compare1_2)&&(in_val)) ? 3'b010:
                (((grant1 > grant2)
				&& (num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((grant1 < grant2)
				&& (num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				reqs3)));
				
  //assign reqs2 = (((!compare1_1)&&(!compare1_2)&&(in_val)) ? 3'b010: reqs3);
 
	
				
	// first in here

  /*  assign reqs0 = (((!compare1_1)&&(!compare1_2)&&(in_val)) ? 3'b010:
                (((((compare1_1)&&(grant_1_r < grant_1_l)) 
                || ((compare1_2)&&(grant_2_r < grant_2_l)))
				&& (num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1)&&(grant_1_r > grant_1_l)) 
                || ((compare1_2)&&(grant_2_r > grant_2_l)))
				&& (num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				reqs2)));
				
  assign reqs2 = (((((compare1_1 == 1)&&(sub_1 > 4))||((compare1_2 == 1)&&(sub_2 < 4)))
				&&(num_free_west >= p_num_free_nbits)&&(in_val)) ? 3'b100:
				(((((compare1_1 == 1)&&(sub_1 < 4))||((compare1_2 == 1)&&(sub_2 > 4)))
				&&(num_free_east >= p_num_free_nbits)&&(in_val)) ? 3'b001:
				(((!compare1_1)&&(!compare1_2)&&(in_val)) ? 
				3'b010: reqs3)));	*/

  
				
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
