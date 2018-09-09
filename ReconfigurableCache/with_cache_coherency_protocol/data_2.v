
`include "vc-srams.v"
`include "vc-arithmetic.v"

module data_2
(
  input                      clk,
  input                      reset,

  input                      tag_read_en,
  input  				[2:0]  addr,
  output 		 [31:0]  tag_read_data,
  input                      tag_write_en,
  input 			 [31:0]  tag_write_data,
   
  input                      data_read_en,
  output  		[127:0]  data_read_data,
  input                      data_write_en,
  input  				[15:0] data_write_byte_en,
  input  			[127:0]  data_write_data,
  
  output 				tag_match,
  
  input			tag_read_en2,
  input	[2:0] 	addr2,
  input [31:0]	tag_tag,
  output 		tag_match2  
);

	wire [31:0]	tag_read_data2;

  vc_CombinationalSRAM_dual_port_1rw#(32,8) tag_array
  (
    .clk           (clk),
	.reset         (reset),
	.read_en       (tag_read_en),
	.read_addr     (addr),
	.read_data     (tag_read_data),
	.write_en      (tag_write_en),
	.write_byte_en (4'b1111),
	.write_addr    (addr),
	.write_data    (tag_write_data),
	
	.read_en2      (tag_read_en2),
	.read_addr2    (addr2),
	.read_data2    (tag_read_data2)
  );
  
  vc_CombinationalSRAM_1rw#(128,8) data_array
  (
    .clk           (clk),
	.reset         (reset),
	.read_en       (data_read_en),
	.read_addr     (addr),
	.read_data     (data_read_data),
	.write_en      (data_write_en),
	.write_byte_en (data_write_byte_en),
	.write_addr    (addr),
	.write_data    (data_write_data)
  ); 
  
    vc_EqComparator #(32) compa
  (
    .in0  (tag_write_data),
    .in1  (tag_read_data),
    .out  (tag_match)
  );
  
    vc_EqComparator #(32) compa2
  (
    .in0  (tag_tag),
    .in1  (tag_read_data2),
    .out  (tag_match2)
  );
  endmodule
  
  
  
  
  
  
  