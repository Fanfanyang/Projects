`timescale 1 ns/1 ps

`include "top.v"
//`include "test.v"

//`include "vc-mem-msgs.v"
module top_simulation_all;

reg clk;
reg reset;
  reg [75:0]  cachereq_msg;
  reg                                         cachereq_val;
  wire                                        cachereq_rdy;

  // Cache Response

  wire [43:0]    cacheresp_msg;
  wire                                        cacheresp_val;
  reg                                         cacheresp_rdy;
  reg [1:0] type;
  reg [7:0] opaque;
  reg [31:0] address;
  reg [1:0] len;
  reg [31:0] data;
  reg [1:0] reconfiguration;

//------------------------------------------------
//connect to top
//------------------------------------------------
top simulation

(
	 .clk(clk),
	 .reset(reset),
	
	
  // Cache Request 
                                          .cachereq_msg(cachereq_msg),
                                           .cachereq_val(cachereq_val),
                                          .cachereq_rdy(cachereq_rdy),

  // Cache Response

                                        .cacheresp_msg(cacheresp_msg),
                                          .cacheresp_val(cacheresp_val),
                                           .cacheresp_rdy(cacheresp_rdy),
										   .reconfiguration (reconfiguration)

);






//------------------------------------------------

initial begin
clk = 0;
forever #10 clk = ~clk;
end

initial begin
cachereq_msg = 76'b0;
forever #10 cachereq_msg = {type,opaque,address,len,data};
end



initial begin

reset = 1;

cachereq_val = 0;
cacheresp_rdy = 0;
type = 2'd0;
opaque = 8'h00;
address = 32'h00000000;
len = 2'd0;
data = 32'h00000000;
reconfiguration = 2'd0;

#100
reset = 0;

//---------------------------------------------------------
// write 
//----------------------------------------------------------
//first write
#100
 
cachereq_val = 0;
cacheresp_rdy = 0;

type = 2'd1;
opaque = 8'h00;
address = 32'h00000000;
len = 2'd0;
data = 32'h0a0b0c0d; //01

#40
cachereq_val = 1;

#200
 
cachereq_val = 0;
cacheresp_rdy = 1;

#300
reconfiguration = 2'd1;

//second write
#300
 
cachereq_val = 0;
cacheresp_rdy = 0;

type = 2'd1;
opaque = 8'h01;
address = 32'h00000100;
len = 2'd0;
data = 32'h0e0f0102;  //10

#40
cachereq_val = 1;

#200
 
cachereq_val = 0;
cacheresp_rdy = 1;

//third write
#300
 
cachereq_val = 0;
cacheresp_rdy = 0;

type = 2'd1;
opaque = 8'h02;
address = 32'h00000200;
len = 2'd0;
data = 32'h0000ffff;

#40
cachereq_val = 1;

#200
 
cachereq_val = 0;
cacheresp_rdy = 1;

#300
reconfiguration = 2'd0;
#300

// forth write
#300
 
cachereq_val = 0;
cacheresp_rdy = 0;

type = 2'd1;
opaque = 8'h02;
address = 32'h00000300;
len = 2'd0;
data = 32'h0000000f;

#40
cachereq_val = 1;

#200
 
cachereq_val = 0;
cacheresp_rdy = 1;

#300
reconfiguration = 2'd2;
#300
//---------------------------------------------------------
// read 
//----------------------------------------------------------
#300
//first read
#100
 
cachereq_val = 0;
cacheresp_rdy = 0;

type = 2'd0;
opaque = 8'h02;
address = 32'h00000100;
len = 2'd0;
data = 32'h00000000;  //10

#40
cachereq_val = 1;

#200
 
cachereq_val = 0;
cacheresp_rdy = 1;

#300
reconfiguration = 2'd0;

//second read
#300
 
cachereq_val = 0;
cacheresp_rdy = 0;

type = 2'd0;
opaque = 8'h03;
address = 32'h00000200;  //11
len = 2'd0;
data = 32'h00000000;

#40
cachereq_val = 1;

#200
 
cachereq_val = 0;
cacheresp_rdy = 1;

#200 $stop;
end

// pipes the ASCII results to the terminal or text editor
initial begin
$timeformat(-9,1,"ns",12);
$display(" Time clk reset cachereq_val cachereq_rdy cachereq_msg data");
$monitor("%t %b %b %b %b %b %b", $realtime,
clk, reset, cachereq_val, cachereq_rdy, cachereq_msg, data);
end

endmodule

















