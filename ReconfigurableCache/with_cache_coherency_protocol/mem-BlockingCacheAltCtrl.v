//=========================================================================
// Base Cache Control
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V
`define PLAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V

`include "vc-mem-msgs.v"
`include "vc-regs.v"
`include "vc-arithmetic.v"

module plab3_mem_BlockingCacheAltCtrl
#(
  parameter size    = 256,            // Cache size in bytes

  // local parameters not meant to be set from outside
  parameter dbw     = 32,             // Short name for data bitwidth
  parameter abw     = 32,             // Short name for addr bitwidth
  parameter clw     = 128,            // Short name for cacheline bitwidth
  parameter nblocks = size*8/clw      // Number of blocks in the cache
)
(
  input                                         clk,
  input                                         reset,

  // Cache Request

  input                                         cachereq_val,
  output                                        cachereq_rdy,

  // Cache Response

  output                                        cacheresp_val,
  input                                         cacheresp_rdy,

  // Memory Request

  output           [1:0]                       memreq_val,
  input                                         memreq_rdy,

  // Memory Response

  input                                         memresp_val,
  output                                        memresp_rdy,
  
  // input from datapath
  
  input [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0]  cachereq_type,
  input                                              tag_match1_0,
  input                                              tag_match2_0,
  input                                              tag_match3_0,
  input [31:0]  addr_in,     
  
  // alt
  output [1:0]   new_bit,
  
  // different type control signal
  output    [1:0] memreq_type2,
  
  output    cachereq_en,
  
  output    tag_array_wen1,
  output    tag_array_wen2,
  output  reg  tag_array_wen3,
  output    tag_array_ren,
  output    [2:0]   tag_array_wben,

  output  reg  data_array_wen1,
  output  reg  data_array_wen2,
  output  reg  data_array_wen3,
  output    data_array_ren,
  output  reg  [15:0]  data_array_wben1,
  output  reg  [15:0]  data_array_wben2,
  output  reg  [15:0]  data_array_wben3,
  
  output    memresp_en,
  output    is_refill,
  
  output    read_data_reg_en,
  output    [1:0]   read_byte_sel,
  output    read_tag_reg_en,
  output    memreq_type,
  
  output reg [1:0] reconfiguration,
  output reg sel,
  
  //----------------------------------------------------------------------
  // cache coherence protocol
  //----------------------------------------------------------------------
  
  // from  data, tag
  output reg coherence_read,
  input coherence_match1,
  input coherence_match2,
  input coherence_match3,
  
  // between cache control
  output reg [1:0] coherence_rdy,
  input [1:0] coherence_val,
  
  output reg [1:0] coherence_respond,
  input [1:0] coherence_receive,
  
  output reg coherence_used,
  input coherence_zero,
    
  output reg coherence_3_out,
  input coherence_3_in,
  
  input [2:0] coherence_idx,
  
  //----------------------------------------------------------------------
  // cache coherence reconfiguration valid dirty
  //----------------------------------------------------------------------
  output reg [23:0] reconfiguration_bits_send,
  input [23:0] reconfiguration_bits_receive,
  
  output reg reconfiguration_send,
  input reconfiguration_receive,
  output reg reconfiguration_send2,
  input reconfiguration_receive2,
  
  output reg [9:0] cache_req_cnt1,
  output reg [9:0] cache_miss_cnt1,
  
  output reg coherence_sel
  
);
//-------------------------------------------------------------------------------
//reconfiguration structure prepare
//-------------------------------------------------------------------------------
 wire [1:0] reconfiguration_1;
 wire reconfiguration_change;
 reg state1_en;
 
 reg [9:0] cache_req_cnt;
 reg [9:0] cache_miss_cnt;
 
 vc_EnResetReg #(2) reconfiguration_reg
 (
	.clk (clk),
	.reset (reset),
	.q (reconfiguration_1),
	.d (reconfiguration),
	.en (state1_en)	
 );
 
   vc_EqComparator #(2) reconfiguration_compa
  (
    .in0  (reconfiguration),
    .in1  (reconfiguration_1),
    .out  (reconfiguration_change)
  );
//-------------------------------------------------------------------------------
reg tag_match1;
reg tag_match2;
reg tag_match3;
always @(*)
begin
case (reconfiguration_1)
	2'd0: begin
			tag_match1 = tag_match1_0;
			tag_match2 = tag_match2_0;
			tag_match3 = 0;
		  end
	2'd1: begin
			tag_match1 = tag_match1_0;
			tag_match2 = tag_match2_0;
			tag_match3 = tag_match3_0;
		  end
	2'd2: begin
			tag_match1 = tag_match1_0;
			tag_match2 = 0;
			tag_match3 = 0;
		  end
endcase
end
//-------------------------------------------------------------------------------
 assign memreq_type2 = ((state == 5)||(state == 6)||(cachereq_type == 2'd2))?
                       (((state == 5)||(state == 6))?2'd1:
                       (((state == 5)||(state == 6))?2'd0:
					   ((cachereq_type == 2'd2)?2'd2:2'dx))):cachereq_type;
					   

 
  reg cacheresp_val;
  reg cachereq_rdy;
reg [1:0] memreq_val;
reg memresp_rdy;
  
//mux sel
  wire [1:0] read_byte_sel1;
  assign read_byte_sel1 = addr_in[3:2];
  reg [1:0]  read_byte_sel;

/////////////////////////////////////////////////////////////////////////
// FSM
/////////////////////////////////////////////////////////////////////////

wire [4:0] idx_2;
wire [4:0] idx_3;
wire [4:0] idx_4;
reg [4:0]	idx_5; // for 2>>1
reg [1:0] change_bit;
reg [2:0] idx_state;
reg [9:0] cache_miss_th1; // excess, large
reg [9:0] cache_miss_th2; // smaller, small
reg [9:0] cache_req_th; // how long ce yi ci

always @(posedge clk)
	begin
		cache_miss_th1 <= 7;
		cache_miss_th2 <= 3;
		cache_req_th <= 10;
	end

assign idx_2 = {2'd1,idx}; // 8-15
assign idx_3 = {2'd0,idx}; // 0-7
assign idx_4 = {2'd2,idx}; // 16-23


reg [4:0] state, next_state;

reg coherence_write_back;
wire [4:0] coherence_new_idx;
assign coherence_new_idx = {coherence_new_bit,coherence_idx};

reg [2:0] cnt_state;
reg [2:0] cnt_next_state;

//------------------------------------------------------------------
//counting for when to reconfigure
//------------------------------------------------------------------

always @(posedge clk)
begin
	cnt_state <= cnt_next_state;
	end
	
always @(*) begin

case (cnt_state)
		3'd0:  begin
					if (cache_req_cnt == cache_req_th) 
					begin 
						cnt_next_state <= 3'd3;
					end
					else cnt_next_state <= 3'd0;
				end
			
		3'd3:	begin
					cache_req_cnt <= 0;
					if (cache_miss_cnt > cache_miss_th1) cnt_next_state <= 3'd1;
					else if (cache_miss_cnt < cache_miss_th2) cnt_next_state <= 3'd2;
						else cnt_next_state <= 3'd4;
				end

		3'd1: begin
				cache_miss_cnt <= 0;
				case (reconfiguration_1)
					2'd0: reconfiguration <= 2'd1;
					2'd1: reconfiguration <= 2'd1;
					2'd2: reconfiguration <= 2'd0;
				endcase
				cnt_next_state <= 3'd0;
				end
		3'd2: begin
				cache_miss_cnt <= 0;
				case (reconfiguration_1)
					2'd0: reconfiguration <= 2'd2;
					2'd1: reconfiguration <= 2'd0;
					2'd2: reconfiguration <= 2'd2;
				endcase
				cnt_next_state <= 3'd0;
				end
		3'd4: begin
				cache_miss_cnt <= 0;
				cnt_next_state <= 3'd0;
				end
endcase
			end

reg miss_rdy;
reg req_rdy;

always @(posedge clk)
	begin
		if (miss_rdy)
			begin
				cache_miss_cnt <= cache_miss_cnt + 1'b1;
				cache_miss_cnt1 <= cache_miss_cnt1 + 1'b1;
				miss_rdy <= 0;
			end
    end		
always @(posedge clk)
	begin
		if (req_rdy)
			begin
				cache_req_cnt <= cache_req_cnt + 1'b1;
				cache_req_cnt1 <= cache_req_cnt1 + 1'b1;
				req_rdy <= 0;
			end
    end		
			
//------------------------------------------------------------------
//basic state machine
//------------------------------------------------------------------

always @(posedge clk)
begin
  state <= next_state;  
  end
  
always @(*) begin
  //cachereq_rdy =1;
  //mem(n, n, n, n, n, n_n, n, n, n, n, n);
  casez (state)
    5'd0: begin
		cacheresp_val <= 0;
		coherence_write_back <= 0;
		if (coherence_respond == 2'd3)
			begin
				next_state <=5'd19;
				coherence_sel <= 1;
			end
		else begin
			if (!reconfiguration_change)
			next_state <= 5'd12;
			else
			begin
			sel <= reconfiguration[1];
             cachereq_rdy <= 1;
			 memreq_val <= 2'd0;
             memresp_rdy <= 0;
        	if (cachereq_val) 
			begin
			  next_state <= 5'd1;
			  req_rdy <= 1;
			end
	        else next_state <= 5'd0;
		  end
		  end
		  end
    5'd1: begin 
	        cachereq_rdy <= 0;
	        read_byte_sel <= read_byte_sel1;
			
			case (cachereq_type)
	          `VC_MEM_REQ_MSG_TYPE_WRITE_INIT: next_state <= 5'd2;
			  `VC_MEM_REQ_MSG_TYPE_READ: begin   next_state <= ((((valid_bits[idx_2])&&(tag_match2))
			                                                  ||((valid_bits[idx_3])&&(tag_match1))
															  ||((valid_bits[idx_4])&&(tag_match3)))?5'd11:
					                                          (dirty_bits[idx_1]
															  ?5'd4:5'd7));
												miss_rdy <= ((((valid_bits[idx_2])&&(tag_match2))
			                                                  ||((valid_bits[idx_3])&&(tag_match1))
															  ||((valid_bits[idx_4])&&(tag_match3)))?0:1);
											end				 
															  
			  `VC_MEM_REQ_MSG_TYPE_WRITE:begin  next_state <= ((((valid_bits[idx_2])&&(tag_match2))
			                                                  ||((valid_bits[idx_3])&&(tag_match1))
															  ||((valid_bits[idx_4])&&(tag_match3)))?
															  ((((valid_bits[idx_2]==2'd2)&&(tag_match2))
			                                                  ||((valid_bits[idx_3]==2'd2)&&(tag_match1))
															  ||((valid_bits[idx_4]==2'd2)&&(tag_match3)))?
															  5'd18 : 5'd10):
															  (dirty_bits[idx_1]?5'd4:5'd7));	
												miss_rdy <= ((((valid_bits[idx_2])&&(tag_match2))
			                                                  ||((valid_bits[idx_3])&&(tag_match1))
															  ||((valid_bits[idx_4])&&(tag_match3)))?0:1);
											end
			  default: next_state <= 5'd1;
			endcase 
		  end
	5'd2: next_state <= 5'd3;
	5'd3: begin 
			coherence_read <= 0;
			coherence_rdy <= 2'd0;
			 cacheresp_val <= 1;
	        if (cacheresp_rdy) 
			  begin
			 // cachereq_rdy <= 0;
			    next_state <= 5'd0;
			  end
	        else next_state <= 5'd3; 
		  end
		  
	5'd4: begin
			next_state <= 5'd5;
			end
	5'd5: begin
	        memreq_val <= 2'd2;
			if (memreq_rdy) next_state <= 5'd6;
		  end
	5'd6: begin
	            memreq_val <= 2'd0;
	            memresp_rdy <= 1; 
				dirty_bits[idx_1] <= 0;
				valid_bits[idx_1] <= 0;
               	if (memresp_val) next_state <= 5'd7;
			  end
	        
	
    5'd7: begin
	            memresp_rdy <= 0;
	            memreq_val <= 2'd1;
				coherence_used <= 0;
				coherence_rdy <= 2'd1;
				coherence_read <= 1;
	            if (memreq_rdy)   next_state <= 5'd8;
			 end

	5'd8: begin
				coherence_rdy <= 2'd0;
				
	            memreq_val <= 2'd0;
	            memresp_rdy <= 1; // not sure
               	if (memresp_val) next_state <= 5'd9;
			  end
	5'd9: begin
	            memresp_rdy <= 0;
				if (coherence_receive == 2'd3) next_state <= 5'd17;
					else begin
						coherence_read <= 0;
						case (coherence_receive)
							2'd1: valid_bits[idx_1] <= 2'd1;
							2'd2: valid_bits[idx_1] <= 2'd2;
						endcase
						coherence_used <= 1;
						if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_READ) next_state <= 5'd11;
						else if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE) next_state <= 5'd18;
						end
			 end
	        
	5'd17: begin
				if (coherence_3_in == 1)
					begin
					next_state <= 5'd7;
					coherence_used <= 1;
					end
					else if (coherence_respond == 2'd3)
						begin
						next_state <= 5'd19;
						coherence_write_back <= 1;
						end
			end
	
	5'd10: begin
               	//if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE) 
				dirty_bits[idx_1] <= 1;
				next_state <= 5'd3;
               end				
			   
	5'd11:	begin
				coherence_used <= 0;
				next_state <= 5'd3; 
			end
	5'd12: begin
			case (reconfiguration)
				2'd0: begin
						next_state <= 5'd14;
						change_bit <= 2'd2;
						end
				2'd1: next_state <= 5'd13;
				2'd2: begin
						next_state <= 5'd15; //2>>1
						change_bit <= 2'd1;
						end
			endcase
		   end
	5'd13: begin //2>>3
			state1_en <=1;
			LRU_3[0] <= {0,LRU[0]}; // LRU: 0 : 2
			LRU_3[1] <= {0,LRU[1]}; //      1 : 1
			LRU_3[2] <= {0,LRU[2]}; //
			LRU_3[3] <= {0,LRU[3]}; // LRU_3: 00 : 2
			LRU_3[4] <= {0,LRU[4]}; //        01 : 1
			LRU_3[5] <= {0,LRU[5]}; //        10 : 3
			LRU_3[6] <= {0,LRU[6]};
			LRU_3[7] <= {0,LRU[7]};
			
			if (reconfiguration_receive) begin
			
			valid_bits[16] <= reconfiguration_bits_receive[1:0];
			valid_bits[17] <= reconfiguration_bits_receive[3:2];
			valid_bits[18] <= reconfiguration_bits_receive[5:4];
			valid_bits[19] <= reconfiguration_bits_receive[7:6];
			valid_bits[20] <= reconfiguration_bits_receive[9:8];
			valid_bits[21] <= reconfiguration_bits_receive[11:10];
			valid_bits[22] <= reconfiguration_bits_receive[13:12];
			valid_bits[23] <= reconfiguration_bits_receive[15:14];
			
			dirty_bits[23:16] <= reconfiguration_bits_receive[23:16];
			
			reconfiguration_send2 <= 1;
			next_state <= 5'd16;
			end
			
		   end
		
	5'd16: begin
			state1_en <= 0;
			reconfiguration_send <= 0;
			reconfiguration_send2 <= 0;
			next_state <= 5'd0;
		   end
			
	5'd15:begin	
			state1_en <= 1;
			LRU[0] <= 0;
			LRU[1] <= 0;
			LRU[2] <= 0;
			LRU[3] <= 0;
			LRU[4] <= 0;
			LRU[5] <= 0;
			LRU[6] <= 0;
			LRU[7] <= 0;
			
			reconfiguration_bits_send <= {dirty_bits[15:8],1'b0,valid_bits[15][0],1'b0,valid_bits[14][0],
										  1'b0,valid_bits[13][0],1'b0,valid_bits[12][0],1'b0,valid_bits[11][0],
										  1'b0,valid_bits[10][0],1'b0,valid_bits[9][0],1'b0,valid_bits[8][0]};
			reconfiguration_send <= 1;
			
			dirty_bits[15:8] <= 8'd0;
			valid_bits[15] <= 2'd0;
			valid_bits[14] <= 2'd0;
			valid_bits[13] <= 2'd0;
			valid_bits[12] <= 2'd0;
			valid_bits[11] <= 2'd0;
			valid_bits[10] <= 2'd0;
			valid_bits[9] <= 2'd0;
			valid_bits[8] <= 2'd0;
			
			if (reconfiguration_receive2)
			next_state <= 5'd16;
			end
			
	5'd14: begin
			case (reconfiguration_1)
				2'd1: next_state <= 5'd31; //3>>2
				2'd2: next_state <= 5'd28;
			endcase
			end
			
	5'd31: begin
			state1_en <= 1;
			LRU[0] <= LRU_3[0][0];
			LRU[1] <= LRU_3[1][0];
			LRU[2] <= LRU_3[2][0];
			LRU[3] <= LRU_3[3][0];
			LRU[4] <= LRU_3[4][0];
			LRU[5] <= LRU_3[5][0];
			LRU[6] <= LRU_3[6][0];
			LRU[7] <= LRU_3[7][0];
			
			reconfiguration_bits_send <= {dirty_bits[23:16],1'b0,valid_bits[23][0],1'b0,valid_bits[22][0],
										  1'b0,valid_bits[21][0],1'b0,valid_bits[20][0],1'b0,valid_bits[19][0],
										  1'b0,valid_bits[18][0],1'b0,valid_bits[17][0],1'b0,valid_bits[16][0]};
			reconfiguration_send <= 1;
						
			dirty_bits[23:16] <= 8'd0;
			valid_bits[23] <= 2'd0;
			valid_bits[22] <= 2'd0;
			valid_bits[21] <= 2'd0;
			valid_bits[20] <= 2'd0;
			valid_bits[19] <= 2'd0;
			valid_bits[18] <= 2'd0;
			valid_bits[17] <= 2'd0;
			valid_bits[16] <= 2'd0;
			
			if (reconfiguration_receive2)
			next_state <= 5'd16;
			end
	5'd28: begin
			state1_en <=1;
			
			if (reconfiguration_receive) begin
			
			valid_bits[8] <= reconfiguration_bits_receive[1:0];
			valid_bits[9] <= reconfiguration_bits_receive[3:2];
			valid_bits[10] <= reconfiguration_bits_receive[5:4];
			valid_bits[11] <= reconfiguration_bits_receive[7:6];
			valid_bits[12] <= reconfiguration_bits_receive[9:8];
			valid_bits[13] <= reconfiguration_bits_receive[11:10];
			valid_bits[14] <= reconfiguration_bits_receive[13:12];
			valid_bits[15] <= reconfiguration_bits_receive[15:14];
			
			dirty_bits[15:8] <= reconfiguration_bits_receive[23:16];
			
			reconfiguration_send2 <= 1;
			next_state <= 5'd16;
			end
			end
	// coherence write back	
	5'd19: begin
			next_state <= 5'd20;
			end
	5'd20: begin
			 memreq_val <= 2'd2;
			 if (memreq_rdy) next_state <= 5'd21;
			end
	5'd21:  begin
	            memreq_val <= 2'd0;
	            memresp_rdy <= 1; 
				dirty_bits[coherence_new_idx] <= 0;
				valid_bits[coherence_new_idx] <= 2'd2;
               	if (memresp_val) next_state <= 5'd22;
			  end
	5'd22: begin
			coherence_3_out <= 1;
			coherence_sel <= 0;
			if (coherence_write_back) next_state <= 5'd17;
				else next_state <= 5'd0;
			end
	5'd18: begin
			coherence_used <= 0;
			coherence_rdy <= 2'd2;
			coherence_read <= 1;
			//if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE) 
				dirty_bits[idx_1] <= 1;
				valid_bits[idx_1] <= 2'd1;
				next_state <= 5'd3;
			end
	
	endcase
  end

//--------------------------------------------------------------
//contrtol different type
//--------------------------------------------------------------

wire [3:0]addr_byte_en;


assign  addr_byte_en = addr_in[3:0];

reg [15:0] y_y;

always @(*) begin
            //addr_byte_en <= addr_in[3:0];
            casez (addr_byte_en)
			    4'b0000:  y_y <= 16'b0000000000001111;
				4'b0100:  y_y <= 16'b0000000011110000;
				4'b1000:  y_y <= 16'b0000111100000000;
				4'b1100:  y_y <= 16'b1111000000000000;
			endcase
			end


localparam y = 1'd1;
localparam n = 1'd0;

localparam y_i = 16'hffff;
localparam n_n = 16'h0000;

localparam r_0 = 2'd0;
localparam r_1 = 2'd1;
localparam r_2 = 2'd2;
localparam r_3 = 2'd3;
reg [1:0] n_b;

always @(posedge clk)
	begin
	 n_b <= (((valid_bits[idx_2])&&(tag_match2)) ? 2'd1: 
			(((valid_bits[idx_3])&&(tag_match1)) ? 2'd0:
			2'd2));
	end
	
reg cachereq_en;
reg tag_array_wen;
reg tag_array_ren;


reg data_array_wen;
reg data_array_ren;
reg [15:0] data_array_wben;

reg memresp_en;
reg is_refill;

reg read_data_reg_en;
reg read_tag_reg_en;
reg memreq_type;
reg [1:0] new_bit;


task mem
(
input m_cachereq_en,
input m_tag_array_wen,
input m_tag_array_ren,

input m_data_array_wen,
input m_data_array_ren,
input [15:0] m_data_array_wben,

input m_memresp_en,
input m_is_refill,

input m_read_data_reg_en,
input m_read_tag_reg_en,
input m_memreq_type,
input [1:0] m_new_bit
);
begin
  cachereq_en = m_cachereq_en;
  tag_array_wen = m_tag_array_wen;
  tag_array_ren = m_tag_array_ren;

  data_array_wen = m_data_array_wen;
  data_array_ren = m_data_array_ren;
  data_array_wben = m_data_array_wben;

  memresp_en = m_memresp_en;
  is_refill = m_is_refill;

  read_data_reg_en = m_read_data_reg_en;
  read_tag_reg_en = m_read_tag_reg_en;
  memreq_type = m_memreq_type;
  new_bit = m_new_bit;
  
end
endtask
	
//--------------------------------------------------------------------
// begin control signal
//--------------------------------------------------------------------

always @( *)
  begin
  casez (cachereq_type)
    `VC_MEM_REQ_MSG_TYPE_WRITE_INIT: begin
	case (state)
	  5'd0: mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
	  5'd1: mem(n, y, n, n, n, n_n, n, n, n, n, n, new_bit1);
	  5'd2: mem(n, n, n, y, n, y_y, n, n, n, n, n, new_bit1);
	  5'd3: begin 
	          mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			  dirty_bits[idx_1] <=0;
			  valid_bits[idx_1] <=2'd1;
			  end
			5'd24:  mem(n, n, y, n, y, n_n, n, n, y, y, n, change_bit);
			5'd26:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit); 
			5'd27:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit);
			
			5'd19:  mem(n, n, y, n, y, n_n, n, n, y, y, n, coherence_new_bit);
			5'd20:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			5'd21:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 			
			  
	  endcase
	  end	
	
	`VC_MEM_REQ_MSG_TYPE_READ:  
	  begin
	    if (((valid_bits[idx_2])&&(tag_match2))||((valid_bits[idx_3])&&(tag_match1))
			||((valid_bits[idx_4])&&(tag_match3)))
		  begin
		    case (state)
			  5'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, n_b);
			  5'd1:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			  5'd11: mem(n, n, y, n, y, n_n, n, n, y, n, n, n_b);
			  5'd3:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			5'd24:  mem(n, n, y, n, y, n_n, n, n, y, y, n, change_bit);
			5'd26:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit); 
			5'd27:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit);
			
			5'd19:  mem(n, n, y, n, y, n_n, n, n, y, y, n, coherence_new_bit);
			5'd20:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			5'd21:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			
			  endcase
			  end
			    
		else begin
		  case (state)
		    5'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			5'd1:  
			begin
			  if (!dirty_bits[idx_1]) mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			  else mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			end
			//evict
			5'd4:  mem(n, n, y, n, y, n_n, n, n, y, y, n, new_bit1);
			5'd5:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			5'd6:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			
			
			// refill
			5'd7:  mem(n, n, y, n, n, n_n, n, n, n, n, y, new_bit1);
			5'd8:  mem(n, y, n, y, n, y_i, y, y, n, n, y, new_bit1);
			5'd9:  mem(n, y, n, y, n, y_i, n, y, n, n, y, new_bit1);
			
			5'd11: mem(n, n, n, n, y, n_n, n, n, y, n, n, new_bit1);
			5'd3:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			
			5'd24:  mem(n, n, y, n, y, n_n, n, n, y, y, n, change_bit);
			5'd26:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit); 
			5'd27:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit);
			
			5'd19:  mem(n, n, y, n, y, n_n, n, n, y, y, n, coherence_new_bit);
			5'd20:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			5'd21:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			endcase
			end
			end

	`VC_MEM_REQ_MSG_TYPE_WRITE:
	  begin
	    if (((valid_bits[idx_2])&&(tag_match2))||((valid_bits[idx_3])&&(tag_match1))
			||((valid_bits[idx_4])&&(tag_match3)))
		  begin
		    case (state)
			  5'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, n_b);
			  5'd1:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			  5'd10: mem(n, n, y, y, n, y_y, n, n, n, n, n, n_b);
			  5'd3:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			  5'd18: mem(n, n, y, y, n, y_y, n, n, n, n, n, n_b);
			  
			5'd24:  mem(n, n, y, n, y, n_n, n, n, y, y, n, change_bit);
			5'd26:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit); 
			5'd27:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit);
			
			5'd19:  mem(n, n, y, n, y, n_n, n, n, y, y, n, coherence_new_bit);
			5'd20:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			5'd21:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 			
			  endcase
			  end
			    
		else begin
		  case (state)
		    5'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			5'd1:  
			begin
			  if (!dirty_bits[idx_1]) mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			  else mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			end
			//evict
			5'd4:  mem(n, n, y, n, y, n_n, n, n, y, y, n, new_bit1);
			5'd5:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			//4'd6:  mem(n, n, y, n, y, n_n, n, n, y, y, n, new_bit1);
			5'd6:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			
			//refill
			5'd7:  mem(n, n, y, n, n, n_n, n, n, n, n, y, new_bit1);
			5'd8:  mem(n, y, n, y, n, y_i, y, y, n, n, y, new_bit1);
			5'd9:  mem(n, y, n, y, n, y_i, n, y, n, n, y, new_bit1);
			
			5'd18: mem(n, n, n, y, n, y_y, n, n, n, n, n, new_bit1);
			//5'd10: mem(n, n, n, y, n, y_y, n, n, n, n, n, new_bit1);
			5'd3:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			
			5'd24:  mem(n, n, y, n, y, n_n, n, n, y, y, n, change_bit);
			5'd26:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit); 
			5'd27:  mem(n, n, n, n, n, n_n, n, n, n, n, n, change_bit);
			
			5'd19:  mem(n, n, y, n, y, n_n, n, n, y, y, n, coherence_new_bit);
			5'd20:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			5'd21:  mem(n, n, n, n, n, n_n, n, n, n, n, n, coherence_new_bit); 
			
			endcase
			end
			end
	  
	  
	  
	  
	  
	  
	  
	  
	default: mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
	endcase
  end
  
//------------------------------------------------------------------
// control for tag
//------------------------------------------------------------------
reg tag_array_wen1;
reg tag_array_wen2;

always @(*) begin
case (reconfiguration_1)
  2'd0: begin
		if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)
		begin
			tag_array_wen2 <= 1;
			tag_array_wen1 <= 0;
			tag_array_wen3 <= 0;
		end
  
		else begin
		if (tag_array_wen)
		begin
			case (LRU[idx])
			0: begin
				tag_array_wen2 <= 1;
				tag_array_wen1 <= 0;
				tag_array_wen3 <= 0;
				end
			1: begin
				tag_array_wen2 <= 0;
				tag_array_wen1 <= 1;
				tag_array_wen3 <= 0;
				end
				endcase
				end
		else begin
				tag_array_wen2 <= 0;
				tag_array_wen1 <= 0;
				tag_array_wen3 <= 0;
				end
				end
				end
  2'd1: begin
		if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)
		begin
			tag_array_wen2 <= 1;
			tag_array_wen1 <= 0;
			tag_array_wen3 <= 0;
		end
  
		else begin
		if (tag_array_wen)
		begin
			case (LRU_3[idx])
		2'd0: begin
				tag_array_wen2 <= 1;
				tag_array_wen1 <= 0;
				tag_array_wen3 <= 0;
				end
		2'd1: begin
				tag_array_wen2 <= 0;
				tag_array_wen1 <= 1;
				tag_array_wen3 <= 0;
				end
		2'd2: begin
				tag_array_wen2 <= 0;
				tag_array_wen1 <= 0;
				tag_array_wen3 <= 1;
				end
				endcase
				end
		else begin
				tag_array_wen2 <= 0;
				tag_array_wen1 <= 0;
				tag_array_wen3 <= 0;
				end
				end
				end
	2'd2: begin
				tag_array_wen2 <= 0;
				tag_array_wen1 <= tag_array_wen;
				tag_array_wen3 <= 0;
			end
endcase
end				
//------------------------------------------------------------------
// control for data
//------------------------------------------------------------------

always @(*) begin

if (data_array_wen) begin

		if (((valid_bits[idx_2])&&(tag_match2))
			||((valid_bits[idx_3])&&(tag_match1))
			||((valid_bits[idx_4])&&(tag_match3))) 
			begin
		case (n_b)
			2'd0: begin
					data_array_wen2 <= 0;
					data_array_wen1 <= 1;
					data_array_wen3 <= 0;

				end
			2'd1: begin
					data_array_wen2 <= 1;
					data_array_wen1 <= 0;
					data_array_wen3 <= 0;

				end
			2'd2: begin
					data_array_wen2 <= 0;
					data_array_wen1 <= 0;
					data_array_wen3 <= 1;

				end
		endcase
end

else begin
case (reconfiguration_1)
  2'd0: begin
		if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)
		begin
			data_array_wen2 <= 1;
			data_array_wen1 <= 0;
			data_array_wen3 <= 0;
		end
  
		else begin

			case (LRU[idx])
			0: begin
				data_array_wen2 <= 1;
				data_array_wen1 <= 0;
				data_array_wen3 <= 0;
				end
			1: begin
				data_array_wen2 <= 0;
				data_array_wen1 <= 1;
				data_array_wen3 <= 0;
				end
				endcase

				end
				end
  2'd1: begin
		if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)
		begin
			data_array_wen2 <= 1;
			data_array_wen1 <= 0;
			data_array_wen3 <= 0;
		end
  
		else begin
			case (LRU_3[idx])
		2'd0: begin
				data_array_wen2 <= 1;
				data_array_wen1 <= 0;
				data_array_wen3 <= 0;
				end
		2'd1: begin
				data_array_wen2 <= 0;
				data_array_wen1 <= 1;
				data_array_wen3 <= 0;
				end
		2'd2: begin
				data_array_wen2 <= 0;
				data_array_wen1 <= 0;
				data_array_wen3 <= 1;
				end
				endcase

				end
				end
	2'd2: begin
				data_array_wen2 <= 0;
				data_array_wen1 <= data_array_wen;
				data_array_wen3 <= 0;
			end
endcase
end
end
		else begin
				data_array_wen2 <= 0;
				data_array_wen1 <= 0;
				data_array_wen3 <= 0;
				end
end


always @(*) begin
if (data_array_wben) begin

		if (((valid_bits[idx_2])&&(tag_match2))
			||((valid_bits[idx_3])&&(tag_match1))
			||((valid_bits[idx_4])&&(tag_match3))) 
			begin
		case (n_b)
			2'd0: begin
					data_array_wben2 <= 0;
					data_array_wben1 <= data_array_wben;
					data_array_wben3 <= 0;

				end
			2'd1: begin
					data_array_wben2 <= data_array_wben;
					data_array_wben1 <= 0;
					data_array_wben3 <= 0;

				end
			2'd2: begin
					data_array_wben2 <= 0;
					data_array_wben1 <= 0;
					data_array_wben3 <= data_array_wben;

				end
		endcase
end

else begin
case (reconfiguration_1)
  2'd0: begin
		if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)
		begin
			data_array_wben2 <= 16'hffff;
			data_array_wben1 <= 0;
			data_array_wben3 <= 0;
		end
  
		else begin

			case (LRU[idx])
			0: begin
				data_array_wben2 <= data_array_wben;
				data_array_wben1 <= 0;
				data_array_wben3 <= 0;
				end
			1: begin
				data_array_wben2 <= 0;
				data_array_wben1 <= data_array_wben;
				data_array_wben3 <= 0;
				end
				endcase

				end
				end
  2'd1: begin
		if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)
		begin
			data_array_wben2 <= 16'hffff;
			data_array_wben1 <= 0;
			data_array_wben3 <= 0;
		end
  
		else begin

			case (LRU_3[idx])
		2'd0: begin
				data_array_wben2 <= data_array_wben;
				data_array_wben1 <= 0;
				data_array_wben3 <= 0;
				end
		2'd1: begin
				data_array_wben2 <= 0;
				data_array_wben1 <= data_array_wben;
				data_array_wben3 <= 0;
				end
		2'd2: begin
				data_array_wben2 <= 0;
				data_array_wben1 <= 0;
				data_array_wben3 <= data_array_wben;
				end
				endcase

				end
				end
	2'd2: begin
				data_array_wben2 <= 0;
				data_array_wben1 <= data_array_wben;
				data_array_wben3 <= 0;
			end
endcase
end
end
		else begin
				data_array_wben2 <= 0;
				data_array_wben1 <= 0;
				data_array_wben3 <= 0;

				end
end
		   
//------------------------------------------------------------------
// dirty, value, LRU
//------------------------------------------------------------------

  reg [1:0] valid_bits [31:0];
  reg [23:0] dirty_bits;
  reg [7:0]  LRU;
  reg [1:0] LRU_3 [7:0];


wire [2:0] idx;
wire [4:0] idx_1;
reg [1:0] new_bit1;

assign idx = addr_in[6:4];
assign idx_1 = {new_bit,idx};
 
/* 
always@(*)
    if (data_array_wen) valid_bits[idx_1] <= 1;
*/

always @(*)
  begin
  case (reconfiguration_1)
	2'd0:  begin
			if ((state == 5'd3)&&(cachereq_type != `VC_MEM_REQ_MSG_TYPE_WRITE_INIT))
			begin
				if (((valid_bits[idx_2])&&(tag_match2))
				||((valid_bits[idx_3])&&(tag_match1)))	  
					begin
						if ((valid_bits[idx_2])&&(tag_match2)) LRU[idx] = 1;
							else LRU[idx] = 0;
					end
				else LRU[idx] = !(LRU[idx]);
				end
			if (state == 5'd2) LRU[idx] = 1; 
			end
	2'd1:  begin
			if ((state == 5'd3)&&(cachereq_type != `VC_MEM_REQ_MSG_TYPE_WRITE_INIT))
		    begin
				if (((valid_bits[idx_2])&&(tag_match2))
				||((valid_bits[idx_3])&&(tag_match1))	
				||((valid_bits[idx_4])&&(tag_match3))) // havnt solve
					begin
						if ((valid_bits[idx_2])&&(tag_match2)) LRU_3[idx] = 2'd2; //3
							else if ((valid_bits[idx_3])&&(tag_match1)) LRU_3[idx] = 2'd0; //2
								else LRU_3[idx] = 2'd1; //1
					end
				else case (LRU_3[idx])
						2'd0: LRU_3[idx] = 2'd2;
						2'd1: LRU_3[idx] = 2'd0;
						2'd2: LRU_3[idx] = 2'd1;
					  endcase
				end
			if (state == 5'd2) LRU_3[idx] = 1; 
			end
	2'd2: LRU[idx] = 2'd0;
	endcase
	end

  always @ (*)
  begin
  case (reconfiguration_1)
		2'd0:  new_bit1 <= ((cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)?2'd1
                  :{0,!LRU[idx]});
		2'd1:  new_bit1 <= ((cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)?2'd1
                  :((LRU_3[idx] == 2'd0) ? 2'd1 : ((LRU_3[idx] == 2'd1) ? 2'd0 
				  : 2'd2)));
		2'd2:  new_bit1 <= 2'd0;
	endcase
  end
  
//--------------------------------------------------------------
//coherence protocol
//--------------------------------------------------------------
  wire [4:0] coherence_idx2;
  wire [4:0] coherence_idx3;
  wire [4:0] coherence_idx1;
  wire [4:0] coherence_idx4;
  wire [1:0] c_b;
  
  assign coherence_idx2 = {2'd1,coherence_idx}; // 8-15
  assign coherence_idx3 = {2'd0,coherence_idx}; // 0-7
  assign coherence_idx4 = {2'd2,coherence_idx}; //16-23
  
  assign c_b = (((valid_bits[coherence_idx2])&&(coherence_match2))
				? 2'd1: (((valid_bits[coherence_idx3])&&(coherence_match1))
				? 2'd0 : 2'd2));
  assign coherence_idx1 = {c_b, coherence_idx};
	
	// shen me shi hou xin hao jie shu, state machine
	reg [2:0] coherence_state;
	reg [2:0] coherence_next_state;
	
always @(posedge clk)
begin
  coherence_state <= coherence_next_state;  
  end
  
always @(*) begin
  case (coherence_state)
    3'd0: begin 
			coherence_3_out <= 0;
			coherence_respond <= 2'd0;
			if (coherence_val == 2'd1) begin
	coherence_next_state <= ((((valid_bits[coherence_idx2])&&(coherence_match2))
							||((valid_bits[coherence_idx3])&&(coherence_match1))
							||((valid_bits[coherence_idx4])&&(coherence_match3)))
							? (dirty_bits[coherence_idx1] ? 3'd3 : 3'd2) :3'd1);
			end
			end
	
	3'd1: begin
			coherence_respond <= 2'd1;
			if (coherence_zero == 1) coherence_next_state <= 3'd0;
				else coherence_next_state <= 3'd1;
			end
	3'd2: begin
			coherence_respond <= 2'd2;
			valid_bits[coherence_idx1] <= 2'd2;
			if (coherence_zero == 1) coherence_next_state <= 3'd0;
				else coherence_next_state <= 3'd2;
			end
	3'd3: begin
			coherence_respond <= 2'd3;
			if (coherence_zero == 1) coherence_next_state <= 3'd0;
				else coherence_next_state <= 3'd3;
			end		
	endcase
	end

		// bu tong coherence_respond de xiang yin, E>>S


reg [1:0] coherence_new_bit;
always @(*)
	begin
		coherence_new_bit <= (((valid_bits[coherence_idx2])&&(coherence_match2))?
					2'd1 : (((valid_bits[coherence_idx3])&&(coherence_match1))?
					2'd0 : 2'd2));
	end
	
always @(*)
	begin
		if (coherence_val == 2'd2)
		begin
			if((valid_bits[coherence_idx2])&&(coherence_match2)) 
				valid_bits[coherence_idx2] <= 2'd0;
			if((valid_bits[coherence_idx3])&&(coherence_match1)) 
				valid_bits[coherence_idx3] <= 2'd0;
			if((valid_bits[coherence_idx4])&&(coherence_match3)) 
				valid_bits[coherence_idx4] <= 2'd0;
		end	
	end
	
//------------------------------------------------------------------------------
//reset
//------------------------------------------------------------------------------

always @(posedge clk)
   if (reset)
     begin
      //cachereq_rdy <= 0;
      cacheresp_val <= 0; 
      memreq_val <= 2'd0;
      memresp_rdy <= 0;
      mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
      state <= 5'd0;
      next_state <= 5'd0;
	  
	  coherence_state <= 3'd0;
	  coherence_next_state <= 3'd0;
      
	  valid_bits[0] <= 2'd0;
	  valid_bits[1] <= 2'd0;
	  valid_bits[2] <= 2'd0;
	  valid_bits[3] <= 2'd0;
	  valid_bits[4] <= 2'd0;
	  valid_bits[5] <= 2'd0;
	  valid_bits[6] <= 2'd0;
	  valid_bits[7] <= 2'd0;
	  valid_bits[8] <= 2'd0;
	  valid_bits[9] <= 2'd0;
	  valid_bits[10] <= 2'd0;
	  valid_bits[11] <= 2'd0;
	  valid_bits[12] <= 2'd0;
	  valid_bits[13] <= 2'd0;
	  valid_bits[14] <= 2'd0;
	  valid_bits[15] <= 2'd0;
	  valid_bits[16] <= 2'd0;
	  valid_bits[17] <= 2'd0;
	  valid_bits[18] <= 2'd0;
	  valid_bits[19] <= 2'd0;
	  valid_bits[20] <= 2'd0;
	  valid_bits[21] <= 2'd0;
	  valid_bits[22] <= 2'd0;
	  valid_bits[23] <= 2'd0;
	  valid_bits[24] <= 2'd0;
	  valid_bits[25] <= 2'd0;
	  valid_bits[26] <= 2'd0;
	  valid_bits[27] <= 2'd0;
	  valid_bits[28] <= 2'd0;
	  valid_bits[29] <= 2'd0;
	  valid_bits[30] <= 2'd0;
	  valid_bits[31] <= 2'd0;
	  
      dirty_bits <= 24'd0;
      LRU <= 8'd0;
      tag_array_wen1 <= 0;
      tag_array_wen2 <= 0;
	  tag_array_wen3 <= 0;
	  data_array_wen3 <= 0;
	  data_array_wben3 <= 0;
	  data_array_wen2 <= 0;
	  data_array_wben2 <= 0;
	  data_array_wen1 <= 0;
	  data_array_wben1 <= 0;
	  
	  coherence_rdy <= 2'd0;
	  coherence_respond <= 2'd0;
	  coherence_used <= 0;;
	  
	  reconfiguration_bits_send <= 24'd0;
	  coherence_read <= 0;
	  coherence_write_back <= 0;	
	  coherence_3_out <= 0;
	  
	  cache_req_cnt <= 0;
	  cache_miss_cnt <= 0;
	  cache_req_cnt1 <= 0;
	  cache_miss_cnt1 <= 0;
	  reconfiguration <= 2'd0;
	  cnt_state <= 0;
	  cnt_next_state <= 0;
	  coherence_sel <= 0;
	  
     end  

endmodule

`endif
