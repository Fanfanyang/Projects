`include "vc-regs.v"

module delay_cycles1 #(parameter p = 1)
(
	input clk,
	input reset,
	input [p-1:0] a,
	output  [p-1:0] b
);

vc_ResetReg #(p) reg1
(
	.clk(clk),
	.reset (reset),
	.q (b),
	.d (a)
);


endmodule

module delay_cycles2 #(parameter p = 1)
(
	input clk,
	input reset,
	input [p-1:0] a,
	output  [p-1:0] b
);

wire [p-1:0] a1;

vc_ResetReg #(p) reg1
(
	.clk(clk),
	.reset (reset),
	.q (a1),
	.d (a)
);

vc_ResetReg #(p) reg2
(
	.clk(clk),
	.reset (reset),
	.q (b),
	.d (a1)
);

endmodule


module delay_cycles3 #(parameter p = 1)
(
	input clk,
	input reset,
	input  [p-1:0]a,
	output [p-1:0] b
);

wire [p-1:0] a1;
wire [p-1:0] a2;

vc_ResetReg #(p) reg1
(
	.clk(clk),
	.reset (reset),
	.q (a1),
	.d (a)
);

vc_ResetReg #(p) reg2
(
	.clk(clk),
	.reset (reset),
	.q (a2),
	.d (a1)
);

vc_ResetReg #(p) reg3
(
	.clk(clk),
	.reset (reset),
	.q (b),
	.d (a2)
);


endmodule

//-------------------------------------------------------------------
// after delay, immediately change to 0
// ------------------------------------------------------------------

module delay_change_3 #(parameter p = 1)
(
	input clk,
	input reset,
	input  [p-1:0]a,
	output [p-1:0] b
);

reg [2:0] state;
reg [2:0] next_state;
reg [p-1:0] c;

always @ (posedge clk)
begin
	if (reset) state <= 0;
	else state <= next_state;
end

always @(*) begin
		casez(state)
			3'd0: begin
					 c <= 0;
					if (a) 
						next_state <= 3'd1;
					else next_state <= 3'd0;
				  end
			3'd1: next_state <= 3'd2;
			3'd2: next_state <= 3'd3;

			3'd3: begin
					 c <= 1;
					next_state <= 3'd4;
				  end
			3'd4: begin
					c <= 0;
					next_state <= 3'd0;
				  end
		  endcase
	

end

vc_ResetReg #(p) reg3
(
	.clk(clk),
	.reset (reset),
	.q (b),
	.d (c)
);

endmodule
//-------------------------------------------------------------------
// after delay, immediately change to 0
// ------------------------------------------------------------------

module delay_change_1 #(parameter p = 1)
(
	input clk,
	input reset,
	input  [p-1:0]a,
	output [p-1:0] b
);

reg [2:0] state;
reg [2:0] next_state;
reg [p-1:0] c;

always @ (posedge clk)
begin
	if (reset) state <= 0;
	else state <= next_state;
end

always @(*) begin
		casez(state)
			3'd0: begin
					 c <= 0;
					if (a) 
						next_state <= 3'd3;
					else next_state <= 3'd0;
				  end

			3'd3: begin
					 c <= 1;
					next_state <= 3'd4;
				  end
			3'd4: begin
					c <= 0;
					next_state <= 3'd0;
				  end
		  endcase
	

end

vc_ResetReg #(p) reg3
(
	.clk(clk),
	.reset (reset),
	.q (b),
	.d (c)
);

endmodule




