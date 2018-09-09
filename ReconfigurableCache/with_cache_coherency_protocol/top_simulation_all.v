`timescale 1 ns/1 ps

`include "top.v"
//`include "test.v"

//`include "vc-mem-msgs.v"
module top_simulation;

reg clk;
reg reset;
  reg [75:0]  cachereq_msg_1;
  reg                                         cachereq_val_1;
  wire                                        cachereq_rdy_1;

  // Cache Response

  wire [43:0]    cacheresp_msg_1;
  wire                                        cacheresp_val_1;
  reg                                         cacheresp_rdy_1;
  
  reg [75:0]  cachereq_msg_2;
  reg                                         cachereq_val_2;
  wire                                        cachereq_rdy_2;

  // Cache Response

  wire [43:0]    cacheresp_msg_2;
  wire                                        cacheresp_val_2;
  reg                                         cacheresp_rdy_2;
  
  reg [1:0] type_1;
  reg [7:0] opaque_1;
  reg [31:0] address_1;
  reg [1:0] len_1;
  reg [31:0] data_1;
  
  reg [1:0] type_2;
  reg [7:0] opaque_2;
  reg [31:0] address_2;
  reg [1:0] len_2;
  reg [31:0] data_2;

//------------------------------------------------
//connect to top
//------------------------------------------------
top simulation

(
	 .clk(clk),
	 .reset(reset),
	
	
  // Cache Request 
                                          .cachereq_msg_1(cachereq_msg_1),
                                           .cachereq_val_1(cachereq_val_1),
                                          .cachereq_rdy_1(cachereq_rdy_1),

  // Cache Response

                                        .cacheresp_msg_1(cacheresp_msg_1),
                                          .cacheresp_val_1(cacheresp_val_1),
                                           .cacheresp_rdy_1(cacheresp_rdy_1),
										   
  // Cache Request 
                                          .cachereq_msg_2(cachereq_msg_2),
                                           .cachereq_val_2(cachereq_val_2),
                                          .cachereq_rdy_2(cachereq_rdy_2),

  // Cache Response

                                        .cacheresp_msg_2(cacheresp_msg_2),
                                          .cacheresp_val_2(cacheresp_val_2),
                                           .cacheresp_rdy_2(cacheresp_rdy_2)
										

);






//------------------------------------------------

initial begin
clk = 0;
forever #10 clk = ~clk;
end

initial begin
cachereq_msg_1 = 76'b0;
forever #10 cachereq_msg_1 = {type_1,opaque_1,address_1,len_1,data_1};
end

initial begin
cachereq_msg_2 = 76'b0;
forever #10 cachereq_msg_2 = {type_2,opaque_2,address_2,len_2,data_2};
end


initial begin

reset = 1;

cachereq_val_1 = 0;
cacheresp_rdy_1 = 0;
cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_1 = 2'd0;
opaque_1 = 8'h00;
address_1 = 32'h00000000;
len_1 = 2'd0;
data_1 = 32'h00000000;

type_2 = 2'd0;
opaque_2 = 8'h00;
address_2 = 32'h00000000;
len_2 = 2'd0;
data_2 = 32'h00000000;

//reconfiguration = 2'd0;

#100
reset = 0;

#100
//---------------------------------------------------------
// write 
//----------------------------------------------------------
//first write
#100
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 0;
cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_1 = 2'd1;
opaque_1 = 8'h00;
address_1 = 32'h00000000;
len_1 = 2'd0;
data_1 = 32'h0a0b0c0d; //01

type_2 = 2'd1;
opaque_2 = 8'h00;
address_2 = 32'h00000100;
len_2 = 2'd0;
data_2 = 32'h0a0b0c0d; //01

#40
cachereq_val_1 = 1;
cachereq_val_2 = 1;

#200
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 1;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;


//second write
#100
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 0;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_1 = 2'd1;  
opaque_1 = 8'h01;
address_1 = 32'h00000100;
len_1 = 2'd0;
data_1 = 32'h0e0f0102;  //10

type_2 = 2'd1;
opaque_2 = 8'h01;
address_2 = 32'h00000000;
len_2 = 2'd0;
data_2 = 32'h0e0f0102;  //10

#40
cachereq_val_1 = 1;
cachereq_val_2 = 1;

#200
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 1;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

#200

#400
//reconfiguration = 2'd1;
#200


//third write
 
#100
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 0;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;


type_1 = 2'd1;
opaque_1 = 8'h02;
address_1 = 32'h00000200;
len_1 = 2'd0;
data_1 = 32'h0000ffff;

type_2 = 2'd1;
opaque_2 = 8'h02;
address_2 = 32'h00000100;
len_2 = 2'd0;
data_2 = 32'h0000ffff;

#40
cachereq_val_1 = 1;
cachereq_val_2 = 1;

#400
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 1;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

#400
#200
//---------------------------------------------------------
// read 
//----------------------------------------------------------
#300
//first read
#100
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 0;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_1 = 2'd0;
opaque_1 = 8'h02;
address_1 = 32'h00000200;
len_1 = 2'd0;
data_1 = 32'h00000000;

type_2 = 2'd0;
opaque_2 = 8'h02;
address_2 = 32'h00000100;
len_2 = 2'd0;
data_2 = 32'h00000000;

#40
cachereq_val_1 = 1;
cachereq_val_2 = 1;
#200
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 1;
 
cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

//second read
#300
#100
#200

cachereq_val_1 = 0;
cacheresp_rdy_1 = 0;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_1 = 2'd0;
opaque_1 = 8'h03;
address_1 = 32'h00000200;
len_1 = 2'd0;
data_1 = 32'h00000000;

type_2 = 2'd0;
opaque_2 = 8'h03;
address_2 = 32'h00000100;
len_2 = 2'd0;
data_2 = 32'h00000000;

#40
cachereq_val_1 = 1;
cachereq_val_2 = 1;

#200
 
cachereq_val_1 = 0;
cacheresp_rdy_1 = 1;
 
cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;


#200 $stop;
end

// pipes the ASCII results to the terminal or text editor
initial begin
$timeformat(-9,1,"ns",12);
$display(" Time clk reset cachereq_val cachereq_rdy cachereq_msg data_1");
$monitor("%t %b %b %b %b %b %b", $realtime,
clk, reset, cachereq_val_1, cachereq_rdy_1, cachereq_msg_1, data_1);
end

endmodule

















