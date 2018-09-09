`timescale 1 ns/1 ps

`include "top.v"
`include "test.v"

//`include "vc-mem-msgs.v"
module top_simulation;

reg clk;
reg reset;
  wire [75:0]  cachereq_msg_1;
  reg                                         cachereq_val_1;
  wire                                        cachereq_rdy_1;

  // Cache Response

  wire [43:0]    cacheresp_msg_1;
  wire                                        cacheresp_val_1;
  wire                                         cacheresp_rdy_1;
  
  wire [75:0]  cachereq_msg_2; // wire
  reg                                         cachereq_val_2;
  wire                                        cachereq_rdy_2;

  // Cache Response

  wire [43:0]    cacheresp_msg_2;
  wire                                        cacheresp_val_2;
  wire                                         cacheresp_rdy_2; //wire
  
  reg [1:0] type_1;
  reg [7:0] opaque_1;

  reg [31:0] data_1;
  
  reg [1:0] type_2;
  reg [7:0] opaque_2;

  reg [31:0] data_2;
  
  wire [9:0] cnt_req_a;
  wire [9:0] cnt_miss_a;
  wire [9:0] cnt_req_b;
  wire [9:0] cnt_miss_b;
  wire [10:0] cnt_req_total;
  wire [10:0] cnt_miss_total;
  
  assign cnt_req_total = cnt_req_a + cnt_req_b;
  assign cnt_miss_total = cnt_miss_a + cnt_miss_b;
  
  wire [31:0] cacheresp_data_1;
  wire [31:0] cacheresp_data_2;
  wire [9:0] cachereq_address_1;
  wire [9:0] cachereq_address_2;
  wire [31:0] cachereq_data_1;
  wire [31:0] cachereq_data_2;
  
  assign cacheresp_data_1 = cacheresp_msg_1[31:0];
  assign cacheresp_data_2 = cacheresp_msg_2[31:0];
  assign cachereq_address_1 = cachereq_msg_1[43:34];
  assign cachereq_address_2 = cachereq_msg_2[43:34];
  assign cachereq_data_1 = cachereq_msg_1[31:0];
  assign cachereq_data_2 = cachereq_msg_2[31:0];

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
                                           .cacheresp_rdy_2(cacheresp_rdy_2),
										   
	.cnt_req_a (cnt_req_a),
	.cnt_miss_a (cnt_miss_a),
	.cnt_req_b (cnt_req_b),
	.cnt_miss_b (cnt_miss_b)

);

reg [15:0] cycle;

initial begin
clk = 0;
forever #10 begin
clk = ~clk;
cycle <= cycle + 16'd1;
end
end

initial begin
reset = 1;
#100
reset = 0;
end

//---------------------------------------------------------------------
// simulate cache 1
//---------------------------------------------------------------------
reg [9:0] address_1;
reg [9:0] addrb;
reg count1;
reg count1_1;
reg [3:0] offset;
reg [2:0] idx;
reg [2:0] tag;

reg idx_rdy;

reg [2:0] state1;
reg [2:0] next_state1;

reg [2:0] state1_1;
reg [2:0] next_state1_1;

wire [75:0] dina;
reg [9:0] addra;
reg [9:0] final;

blk_mem_gen_0 cache_1_input (
  .clka(clk),    // input wire clka, continuously assign  value
  .ena(1),      // input wire ena
  .wea(1),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [9 : 0] addra
  .dina(dina),    // input wire [75 : 0] dina
  
  .clkb(clk),    // input wire clkb
  .enb(cachereq_rdy_1),      // input wire enb
  .addrb(addrb),  // input wire [9 : 0] addrb
  .doutb(cachereq_msg_1)  // output wire [75 : 0] doutb
);

always @(posedge clk)
	state1 <= next_state1;
	
always @(*)
	begin
		case (state1)
			3'd0: begin
					cachereq_val_1 <= 0;
					if (cachereq_rdy_1) next_state1 <= 3'd1;
					end
			3'd1: begin
					count1 <= 1;
					next_state1 <= 3'd2;
					end
			3'd2: next_state1 <= 3'd3;
			3'd3: next_state1 <= 3'd4;
			3'd4: begin
					cachereq_val_1 <= 1;
					next_state1 <= 3'd5;
					end
			3'd5: begin
					next_state1 <= 3'd0;
					end
		endcase
	end

always @(posedge clk)
	if (count1 == 1)
		begin
			addrb <= addrb + 10'd1; 
			final <= final + 9'd1;
			count1 <= 0;
		end
	
delay_change_1 #(1) delay1
(	
	.clk (clk),
	.reset (reset),
	.a (cacheresp_val_1),
	.b (cacheresp_rdy_1)
);

assign dina = {type_1,opaque_1,22'd0,tag,idx,offset,2'd0,data_1};

always @(posedge clk)
	state1_1 <= next_state1_1;

always @(posedge clk)
	begin
		case (state1_1)
			3'd0: begin
					type_1 <= 2'd1;
					next_state1_1 <= 3'd1;
					end
			3'd1: begin
					
					next_state1_1 <= 3'd2;
					end
			3'd2: begin
					next_state1_1 <= 3'd3;
					end
			3'd3: begin
					
					next_state1_1 <= 3'd4;
					end
			3'd4: begin
					count1_1 <= 1;
					next_state1_1 <= 3'd0;
					end
		endcase
	end
	
always @(posedge clk)
	if (count1_1 == 1)
		begin
			opaque_1 <= opaque_1 + 8'd1;
			tag <= tag + 1;
			idx <= idx;
			offset <= offset;
			data_1 <= data_1 + 32'd1;
			addra <= addra + 10'd1;
			count1_1 <= 0;
		end
		
always @(posedge clk)
	if (tag == 3'd2)
		begin
			//idx_rdy <= 1;
			idx <= idx + 3'd1;
			tag <= 0;
		end
		
always @(posedge clk)
	if (idx == 3'd3)
		begin
			idx <= 0;
		end
always @(posedge clk)
	if (final == 50)
		$stop;
		
/*
always @(posedge clk)
	if (idx_rdy)
		begin
			idx <= idx + 3'd1;
			idx_rdy <= 0;
			tag == 3'd0;
		end
*/		
/*always @ (posedge clk)
	if (opaque_1 == 8'd255)
		$stop;*/
//---------------------------------------------------------------------
// simulate cache 2
//---------------------------------------------------------------------
reg [9:0] address_2;
reg [9:0] addrb2;
reg count2;
reg count2_2;
reg [3:0] offset2;
reg [2:0] idx2;
reg [2:0] tag2;

reg idx_rdy2;

reg [2:0] state2;
reg [2:0] next_state2;

reg [2:0] state2_2;
reg [2:0] next_state2_2;

wire [75:0] dina2;
reg [9:0] addra2;

blk_mem_gen_0 cache_2_input (
  .clka(clk),    // input wire clka, continuously assign  value
  .ena(1),      // input wire ena
  .wea(1),      // input wire [0 : 0] wea
  .addra(addra2),  // input wire [9 : 0] addra
  .dina(dina2),    // input wire [75 : 0] dina
  
  .clkb(clk),    // input wire clkb
  .enb(cachereq_rdy_2),      // input wire enb
  .addrb(addrb2),  // input wire [9 : 0] addrb
  .doutb(cachereq_msg_2)  // output wire [75 : 0] doutb
);

always @(posedge clk)
	state2 <= next_state2;
	
always @(*)
	begin
		case (state2)
			3'd0: begin
					cachereq_val_2 <= 0;
					if (cachereq_rdy_2) next_state2 <= 3'd1;
					end
			3'd1: begin
					count2 <= 1;
					next_state2 <= 3'd2;
					end
			3'd2: next_state2 <= 3'd3;
			3'd3: next_state2 <= 3'd4;
			3'd4: begin
					cachereq_val_2 <= 1;
					next_state2 <= 3'd5;
					end
			3'd5: begin
					next_state2 <= 3'd0;
					end
		endcase
	end

always @(posedge clk)
	if (count2 == 1)
		begin
			addrb2 <= addrb2 + 10'd1; 
			//final <= final + 9'd1;
			count2 <= 0;
		end
	
delay_change_1 #(1) delay2
(	
	.clk (clk),
	.reset (reset),
	.a (cacheresp_val_2),
	.b (cacheresp_rdy_2)
);

assign dina2 = {type_2,opaque_2,22'd0,tag2,idx2,offset2,2'd0,data_2};

always @(posedge clk)
	state2_2 <= next_state2_2;

always @(posedge clk)
	begin
		case (state2_2)
			3'd0: begin
					type_2 <= 2'd1;
					next_state2_2 <= 3'd1;
					end
			3'd1: begin
					
					next_state2_2 <= 3'd2;
					end
			3'd2: begin
					next_state2_2 <= 3'd3;
					end
			3'd3: begin
					
					next_state2_2 <= 3'd4;
					end
			3'd4: begin
					count2_2 <= 1;
					next_state2_2 <= 3'd0;
					end
		endcase
	end
	
always @(posedge clk)
	if (count2_2 == 1)
		begin
			opaque_2 <= opaque_2 + 8'd1;
			tag2 <= tag2 + 1;
			idx2 <= idx2;
			offset2 <= offset2;
			data_2 <= data_2 + 32'd1;
			addra2 <= addra2 + 10'd1;
			count2_2 <= 0;
		end
		
always @(posedge clk)
	if (tag2 == 3'd6)
		begin
			//idx_rdy <= 1;
			idx2 <= idx2 + 3'd1;
			tag2 <= 3'd4;
		end
		
always @(posedge clk)
	if (idx2 == 3'd3)
		begin
			idx2 <= 0;
		end
/*
reg [1:0] len_2;
reg [31:0] address_2;

initial begin
cachereq_msg_2 = 76'b0;
forever #10 cachereq_msg_2 = {type_2,opaque_2,address_2,len_2,data_2};
end

initial begin

reset = 1;

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_2 = 2'd0;
opaque_2 = 8'h00;
address_2 = 32'h00000000;
len_2 = 2'd0;
data_2 = 32'h00000000;

reconfiguration = 2'd0;

#100
reset = 0;

#100
reconfiguration = 2'd0;
#100

//---------------------------------------------------------
// read 
//----------------------------------------------------------
//first read
#100
 
cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_2 = 2'd0;
opaque_2 = 8'h00;
address_2 = 32'h00000300;
len_2 = 2'd0;
data_2 = 32'h0a0b0c0d; //01

#40
cachereq_val_2 = 1;

#200

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;


//second write
#1000

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_2 = 2'd0; // read
opaque_2 = 8'h01;
address_2 = 32'h00000200;
len_2 = 2'd0;
data_2 = 32'h0e0f0102;  //10

#40
cachereq_val_2 = 1;

#200

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

#200



#1000

//third write
 
#100

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;


type_2 = 2'd0; //read
opaque_2 = 8'h02;
address_2 = 32'h00000100;
len_2 = 2'd0;
data_2 = 32'h0000ffff;

#40

cachereq_val_2 = 1;

#400

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

#400

#1000
//---------------------------------------------------------
// read 
//----------------------------------------------------------

//first read
#100


cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_2 = 2'd0;
opaque_2 = 8'h02;
address_2 = 32'd32;
len_2 = 2'd0;
data_2 = 32'h00000000;

#40

cachereq_val_2 = 1;
#200

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

#1000
//second read


#200

cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;


type_2 = 2'd0;
opaque_2 = 8'h03;
address_2 = 32'd144;
len_2 = 2'd0;
data_2 = 32'h00000000;

#40

cachereq_val_2 = 1;

#200

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

//---------------------------------------------------------
// read 3
//----------------------------------------------------------

//first read

#1000


cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;

type_2 = 2'd0;
opaque_2 = 8'h02;
address_2 = 32'h00000300;
len_2 = 2'd0;
data_2 = 32'h00000000;

#40

cachereq_val_2 = 1;
#200

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;

#1000
//second read

#100


cachereq_val_2 = 0;
cacheresp_rdy_2 = 0;


type_2 = 2'd0;
opaque_2 = 8'h03;
address_2 = 32'h00000000;
len_2 = 2'd0;
data_2 = 32'h00000000;

#40

cachereq_val_2 = 1;

#200

cachereq_val_2 = 0;
cacheresp_rdy_2 = 1;
end
*/
always @(posedge clk)
	if (reset)
		begin
			state1 <= 0;
			next_state1 <= 0;
			addrb <= 0;
			state1_1 <= 0;
			next_state1_1 <= 0;
			type_1 <= 0;
			opaque_1 <= 0;
			address_1 <= 0;
			tag <= 0;
			idx <= 0;
			offset <= 0;
			data_1 <= 0;
			addra <= 0;
			idx_rdy <= 0;
			final <= 0;
			cycle <= 0;
			
			state2 <= 0;
			next_state2 <= 0;
			addrb2 <= 0;
			state2_2 <= 0;
			next_state2_2 <= 0;
			type_2 <= 0;
			opaque_2 <= 0;
			address_2 <= 0;
			tag2 <= 3'd4;
			idx2 <= 0;
			offset2 <= 0;
			data_2 <= 0;
			addra2 <= 0;
			idx_rdy2 <= 0;
			
			
		end

endmodule















