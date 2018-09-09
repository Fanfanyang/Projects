//=========================================================================
// Base Cache Control
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V
`define PLAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V

`include "vc-mem-msgs.v"

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

  output                                        memreq_val,
  input                                         memreq_rdy,

  // Memory Response

  input                                         memresp_val,
  output                                        memresp_rdy,
  
  // input from datapath
  
  input [`VC_MEM_REQ_MSG_TYPE_NBITS(8,abw,dbw)-1:0]  cachereq_type,
  input                                              tag_match1,
  input                                              tag_match2,
  input [31:0]  addr_in,     
  
  // alt
  output    new_bit,
  
  // different type control signal
  output    [1:0] memreq_type2,
  
  output    cachereq_en,
  
  output    tag_array_wen1,
  output    tag_array_wen2,
  output    tag_array_ren,
  output    [2:0]   tag_array_wben,

  output    data_array_wen,
  output    data_array_ren,
  output    [15:0]  data_array_wben,
  
  output    memresp_en,
  output    is_refill,
  
  output    read_data_reg_en,
  output    [1:0]   read_byte_sel,
  output    read_tag_reg_en,
  output    memreq_type
);
//------------------------------------------------------------------------------------
  // pass through the request and response signals in the null cache

 // assign memreq_val    = cachereq_val;
//  assign cachereq_rdy  = memreq_rdy;
  
//  assign cacheresp_val = memresp_val;
//  assign memresp_rdy   = cacheresp_rdy;
  //-------------------------------------------------------------------------------
 
 assign memreq_type2 = ((state == 5)||(state == 6)||(cachereq_type == 2'd2))?
                       (((state == 5)||(state == 6))?2'd1:
                       (((state == 5)||(state == 6))?2'd0:
					   ((cachereq_type == 2'd2)?2'd2:2'dx))):cachereq_type;
					   

 
  reg cacheresp_val;
  reg cachereq_rdy;
reg memreq_val;
reg memresp_rdy;
  
//mux sel
  wire [1:0] read_byte_sel1;
  assign read_byte_sel1 = addr_in[3:2];
  reg [1:0]  read_byte_sel;

/////////////////////////////////////////////////////////////////////////
// FSM
/////////////////////////////////////////////////////////////////////////

reg tag_match_1;
wire [3:0] idx_2;
wire [3:0] idx_3;
//reg valid_b;


assign idx_2 = {1'd1,idx};
assign idx_3 = {1'd0,idx};
always @(*)
begin
tag_match_1 <= (tag_match1||tag_match2);
//valid_b <= (valid_bits[idx_1]||valid_bits[idx_2]);
end


reg [3:0] state, next_state;
always @(posedge clk)
begin
  state <= next_state;  
  end
  
always @(*) begin
  //cachereq_rdy =1;
  //mem(n, n, n, n, n, n_n, n, n, n, n, n);
  casez (state)
    4'd0: begin
	        cacheresp_val <= 0;
             cachereq_rdy <= 1;
			 memreq_val <= 0;
             memresp_rdy <= 0;
        	if (cachereq_val) 
			begin
			  next_state <= 4'd1;
			//  cachereq_rdy <= 0;
			end
	        else next_state <= 4'd0;
		  end
    4'd1: begin 
	        cachereq_rdy <= 0;
	        read_byte_sel <= read_byte_sel1;
			case (cachereq_type)
	          `VC_MEM_REQ_MSG_TYPE_WRITE_INIT: next_state <= 4'd2;
			  `VC_MEM_REQ_MSG_TYPE_READ:    	next_state <= ((((valid_bits[idx_2])&&(tag_match2))
			                                                  ||((valid_bits[idx_3])&&(tag_match1)))?4'd11:
					                                          (dirty_bits[idx_1]
															  ?4'd4:4'd7));
															  //(dirty_bits[idx_2]&&dirty_bits[idx_3])
															  
			  `VC_MEM_REQ_MSG_TYPE_WRITE:       next_state <= ((((valid_bits[idx_2])&&(tag_match2))
			                                                  ||((valid_bits[idx_3])&&(tag_match1)))?4'd10:
					                                          (dirty_bits[idx_1]?4'd4:4'd7));												  

			  default: next_state <= 4'd1;
			endcase 
		  end
	4'd2: next_state <= 4'd3;
	4'd3: begin 
			 cacheresp_val <= 1;
	        if (cacheresp_rdy) 
			  begin
			 // cachereq_rdy <= 0;
			    next_state <= 4'd0;
			  end
	        else next_state <= 4'd3; 
		  end
		  
	4'd4: next_state <= 4'd5;
	4'd5: begin
	        memreq_val <= 1;
			if (memreq_rdy) next_state <= 4'd6;
		  end
	4'd6: begin
	            memreq_val <= 0;
	            memresp_rdy <= 1; 
				dirty_bits[idx_1] <= 0;
				valid_bits[idx_1] <= 0;
               	if (memresp_val) next_state <= 4'd7;
			  end
	        
	
    4'd7: begin
	            memresp_rdy <= 0;
	            memreq_val <= 1;
	            if (memreq_rdy)   next_state <= 4'd8;
			 end

	4'd8: begin
	            memreq_val <= 0;
	            memresp_rdy <= 1; // not sure
               	if (memresp_val) next_state <= 4'd9;
			  end
	4'd9: begin
	            memresp_rdy <= 0;
				if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_READ) next_state <= 4'd11;
				else if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE) next_state <= 4'd10;
			 end
	        
	
	4'd10: begin
               	if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE) dirty_bits[idx_1] <= 1;
				next_state <= 4'd3;
               end				
	4'd11: next_state <= 4'd3; 
	        
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
wire n_b;

assign n_b = (tag_match2?1:0);


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
reg new_bit;


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
input m_new_bit
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
	  4'd0: mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
	  4'd1: mem(n, y, n, n, n, n_n, n, n, n, n, n, new_bit1);
	  4'd2: mem(n, n, n, y, n, y_y, n, n, n, n, n, new_bit1);
	  4'd3: begin 
	          mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			  dirty_bits[idx_1] <=0;
			  valid_bits[idx_1] <=1;
			  end
			  
	  endcase
	  end	
	
	`VC_MEM_REQ_MSG_TYPE_READ:  
	  begin
	    if (((valid_bits[idx_2])&&(tag_match2))||((valid_bits[idx_3])&&(tag_match1)))
		  begin
		    case (state)
			  4'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, n_b);
			  4'd1:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			  4'd11: mem(n, n, y, n, y, n_n, n, n, y, n, n, n_b);
			  4'd3:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			  endcase
			  end
			    
		else begin
		  case (state)
		    4'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			4'd1:  
			begin
			  if (!dirty_bits[idx]) mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			  else mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			end
			//evict
			4'd4:  mem(n, n, y, n, y, n_n, n, n, y, y, n, new_bit1);
			4'd5:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			//4'd6:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			4'd6:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			
			
			// refill
			4'd7:  mem(n, n, y, n, n, n_n, n, n, n, n, y, new_bit1);
			4'd8:  mem(n, y, n, y, n, y_i, y, y, n, n, y, new_bit1);
			4'd9:  mem(n, y, n, y, n, y_i, n, y, n, n, y, new_bit1);
			
			4'd11: mem(n, n, n, n, y, n_n, n, n, y, n, n, new_bit1);
			4'd3:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			
			endcase
			end
			end
				  
		//  if ((state == 4'd1)&&(!dirty_bits[idx]))  mem(n, n, n, y, n,  y_i, y, y, n, y, n);
		//  if ((state == 4'd10)&&(!dirty_bits[idx])) mem (n, n, n, n, y, y_i, n, n, y, n, n);
		
	`VC_MEM_REQ_MSG_TYPE_WRITE:
	  begin
	    if (((valid_bits[idx_2])&&(tag_match2))||((valid_bits[idx_3])&&(tag_match1)))
		  begin
		    case (state)
			  4'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, n_b);
			  4'd1:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			  4'd10: mem(n, n, y, y, n, y_y, n, n, n, n, n, n_b);
			  4'd3:  mem(n, n, y, n, n, n_n, n, n, n, n, n, n_b);
			  endcase
			  end
			    
		else begin
		  case (state)
		    4'd0:  mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			4'd1:  
			begin
			  if (!dirty_bits[idx_1]) mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			  else mem(n, n, y, n, n, n_n, n, n, n, n, n, new_bit1);
			end
			//evict
			4'd4:  mem(n, n, y, n, y, n_n, n, n, y, y, n, new_bit1);
			4'd5:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			//4'd6:  mem(n, n, y, n, y, n_n, n, n, y, y, n, new_bit1);
			4'd6:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1); 
			
			//refill
			4'd7:  mem(n, n, y, n, n, n_n, n, n, n, n, y, new_bit1);
			4'd8:  mem(n, y, n, y, n, y_i, y, y, n, n, y, new_bit1);
			4'd9:  mem(n, y, n, y, n, y_i, n, y, n, n, y, new_bit1);
			
			4'd10: mem(n, n, n, y, n, y_y, n, n, n, n, n, new_bit1);
			4'd3:  mem(n, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
			
			
			endcase
			end
			end
	  
	  
	  
	  
	  
	  
	  
	  
	default: mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
	endcase
  end
  
//------------------------------------------------------------------
// control for alt
//------------------------------------------------------------------
reg tag_array_wen1;
reg tag_array_wen2;

always @(*)
begin
  if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)
  begin
    tag_array_wen2 <= 1;
	tag_array_wen1 <= 0;
  end
  
  else begin
  if (tag_array_wen)
  begin
    case (LRU[idx])
	  0: begin
	       tag_array_wen2 <= 1;
		   tag_array_wen1 <= 0;
		 end
	  1: begin
	       tag_array_wen2 <= 0;
		   tag_array_wen1 <= 1;
		 end
		 endcase
		 end
  else begin
           tag_array_wen2 <= 0;
		   tag_array_wen1 <= 0;
		   end
		   end
		   end
		 



	
//------------------------------------------------------------------
// dirty, value, LRU
//------------------------------------------------------------------

  reg [15:0] valid_bits;
  reg [15:0] dirty_bits;
  reg [7:0]  LRU;
  
  reg valid,dirty;

wire [2:0] idx;
wire [3:0] idx_1;
wire new_bit1;

assign idx = addr_in[6:4];
assign idx_1 = {new_bit,idx};

/*always@(*)
  if (state == 4'd3)
  begin
	if (cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE) dirty_bits[idx] <= 1;
  end*/
  
always@(*)
    if (data_array_wen) valid_bits[idx_1] <= 1;

always @(*)
  begin
	if ((state == 4'd3)&&(cachereq_type != `VC_MEM_REQ_MSG_TYPE_WRITE_INIT))
      begin
        if (((valid_bits[idx_2])&&(tag_match2))
		   ||((valid_bits[idx_3])&&(tag_match1)))	  
	    LRU[idx] = (LRU[idx]);
	    else LRU[idx] = !(LRU[idx]);
		end
	if (state == 4'd2) LRU[idx] = 1;
	end
  
assign new_bit1 = ((cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT)?1
                  :(!LRU[idx]));
//------------------------------------------------------------------------------
//reset
//------------------------------------------------------------------------------

always @(posedge clk)
   if (reset)
     begin
      cachereq_rdy <= 0;
      cacheresp_val <= 0; 
      memreq_val <= 0;
      memresp_rdy <= 0;
      mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
      state <= 3'd0;
      next_state <= 3'd0;
      valid_bits <= 16'd0;
      dirty_bits <= 16'd0;
      LRU <= 8'd0;
      tag_match_1 <= 0;
      tag_array_wen1 <= 0;
      tag_array_wen2 <= 0;
//new_bit = 0;
     end  

//-----------------------------------------------------------------------------
//initial
//-----------------------------------------------------------------------------

initial
begin
cachereq_rdy <= 0;
cacheresp_val <= 0; 
memreq_val <= 0;
memresp_rdy <= 0;
mem(y, n, n, n, n, n_n, n, n, n, n, n, new_bit1);
state <= 3'd0;
next_state <= 3'd0;
valid_bits <= 16'd0;
dirty_bits <= 16'd0;
LRU <= 8'd0;
tag_match_1 <= 0;
tag_array_wen1 <= 0;
tag_array_wen2 <= 0;
//new_bit = 0;
end  
//assign tag_array_wen1 = 0;
endmodule

`endif
