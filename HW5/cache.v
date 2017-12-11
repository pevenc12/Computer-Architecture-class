module cache(
    clk,
    proc_reset,
    proc_read,
    proc_write,
    proc_addr,
    proc_wdata,
    proc_stall,
    proc_rdata,
    mem_read,
    mem_write,
    mem_addr,
    mem_rdata,
    mem_wdata,
    mem_ready
);
    
//==== input/output definition ============================
    input          clk;
    // processor interface
    input          proc_reset;
    input          proc_read, proc_write;
    input   [29:0] proc_addr;
    input   [31:0] proc_wdata;
    output 	reg        proc_stall;
    output  reg [31:0] proc_rdata;
    // memory interface
    input  [127:0] mem_rdata;
    input          mem_ready;
    output   reg    mem_read, mem_write;
    output reg [27:0] mem_addr;
    output reg [127:0] mem_wdata;
    
//==== wire/reg definition ================================
    wire [1:0]read_and_write;
	assign read_and_write = {proc_read , proc_write};
	
	reg [127:0]block_0, block_1, block_2, block_3, block_4, block_5, block_6, block_7,block;
	reg [127:0]block_next_0, block_next_1, block_next_2, block_next_3, block_next_4, block_next_5, block_next_6, block_next_7, block_next;
	reg [7:0]dirty;
	reg [7:0]dirty_next;
	reg [7:0]valid;
	reg [7:0]valid_next;
	reg [24:0]tag_0, tag_1, tag_2, tag_3, tag_4, tag_5, tag_6, tag_7;
	reg [24:0]tag_next_0, tag_next_1, tag_next_2, tag_next_3, tag_next_4, tag_next_5, tag_next_6, tag_next_7;
	
	reg [31:0] block_to_read;
	reg [127:0]block_to_write;
	reg [24:0]tag;
	reg [1:0]block_offset;
	reg dirty_now;
	reg valid_now;
	reg [31:0] proc_wdata_place;
	reg [1:0] state, next_state;						//00:read/write 	01:write_to_mem		10:read_from_mem
	reg hit, stall;
	
//==== combinational circuit ==============================

	always@(*)							//handle the address
	begin
		case (proc_addr[4:2])
			3'b000:
				begin
					tag = tag_0;
					dirty_now = dirty[0];
					valid_now = valid[0];
					block = block_0;
				end
			3'b001:
				begin
					tag = tag_1;
					dirty_now = dirty[1];
					valid_now = valid[1];
					block = block_1;
				end
			3'b010:
				begin
					tag = tag_2;
					dirty_now = dirty[2];
					valid_now = valid[2];
					block = block_2;
				end
			3'b011:
				begin
					tag = tag_3;
					dirty_now = dirty[3];
					valid_now = valid[3];
					block = block_3;
				end
			3'b100:
				begin
					tag = tag_4;
					dirty_now = dirty[4];
					valid_now = valid[4];
					block = block_4;
				end
			3'b101:
				begin
					tag = tag_5;
					dirty_now = dirty[5];
					valid_now = valid[5];
					block = block_5;
				end
			3'b110:
				begin
					tag = tag_6;
					dirty_now = dirty[6];
					valid_now = valid[6];
					block = block_6;
				end
			3'b111:
				begin
					tag = tag_7;
					dirty_now = dirty[7];
					valid_now = valid[7];
					block = block_7;
				end
		endcase
	end
				
				
	always@(*)					//read from cache
	begin
	
		if (proc_read)
		begin
		
		case(proc_addr[1:0])
			2'b00:
				begin
					block_to_read = block[31:0];
				end
			2'b01:
				begin
					block_to_read = block[63:32];
				end
			2'b10:
				begin
					block_to_read = block[95:64];
				end
			2'b11:
				begin
					block_to_read = block[127:96];
				end
			endcase
		end
		
		else
		begin
			block_to_read = 32'b0;
		
		end
		
	end
	
	always@(*)					//proc write to cache
	begin
		if (proc_write)
		begin
		
			case (proc_addr[1:0])
			2'b00:
				begin
					block_to_write = {block[127:32], proc_wdata};
				end
			2'b01:
				begin
					block_to_write = {block[127:64], proc_wdata, block[31:0]};
				end
			2'b10:
				begin
					block_to_write = {block[127:96], proc_wdata, block[63:0]};
				end
			2'b11:
				begin
					block_to_write = {proc_wdata , block[95:0]};
				end
			endcase
		
		end
		
		else
		begin
			block_to_write = 128'd0;
		
		end
	end
	
	
	
	
	
	always@(*)					//hit or stall
	begin
		if (valid_now && ~state[1] && ~state[0] && (proc_addr[29:5] == tag ))
			begin
				hit = 1'b1;
				stall = 1'b0;
			end
		else
			begin
				hit = 1'b0;
				stall = 1'b1;
			end
	end
	
	always@(*)					//cache refresh
	begin
		case (state)
			2'b00:				//read and write
				begin
					tag_next_0 = tag_0;
					tag_next_1 = tag_1;
					tag_next_2 = tag_2;
					tag_next_3 = tag_3;
					tag_next_4 = tag_4;
					tag_next_5 = tag_5;
					tag_next_6 = tag_6;
					tag_next_7 = tag_7;
					
					if (proc_write && hit)
						begin
							case(proc_addr[4:2])
								3'b000:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[0] = 1'b1;
										dirty_next[0] = 1'b1;
										block_next_0 = block_to_write;
										block_next_1 = block_1;
										block_next_2 = block_2;
										block_next_3 = block_3;
										block_next_4 = block_4;
										block_next_5 = block_5;
										block_next_6 = block_6;
										block_next_7 = block_7;
									end
								3'b001:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[1] = 1'b1;
										dirty_next[1] = 1'b1;
										block_next_0 = block_0;
										block_next_1 = block_to_write;
										block_next_2 = block_2;
										block_next_3 = block_3;
										block_next_4 = block_4;
										block_next_5 = block_5;
										block_next_6 = block_6;
										block_next_7 = block_7;
									end
								3'b010:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[2] = 1'b1;
										dirty_next[2] = 1'b1;
										block_next_0 = block_0;
										block_next_1 = block_1;
										block_next_2 = block_to_write;
										block_next_3 = block_3;
										block_next_4 = block_4;
										block_next_5 = block_5;
										block_next_6 = block_6;
										block_next_7 = block_7;
									end
								3'b011:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[3] = 1'b1;
										dirty_next[3] = 1'b1;
										block_next_0 = block_0;
										block_next_1 = block_1;
										block_next_2 = block_2;
										block_next_3 = block_to_write;
										block_next_4 = block_4;
										block_next_5 = block_5;
										block_next_6 = block_6;
										block_next_7 = block_7;
									end
								3'b100:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[4] = 1'b1;
										dirty_next[4] = 1'b1;
										block_next_0 = block_0;
										block_next_1 = block_1;
										block_next_2 = block_2;
										block_next_3 = block_3;
										block_next_4 = block_to_write;
										block_next_5 = block_5;
										block_next_6 = block_6;
										block_next_7 = block_7;
									end
								3'b101:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[5] = 1'b1;
										dirty_next[5] = 1'b1;
										block_next_0 = block_0;
										block_next_1 = block_1;
										block_next_2 = block_2;
										block_next_3 = block_3;
										block_next_4 = block_4;
										block_next_5 = block_to_write;
										block_next_6 = block_6;
										block_next_7 = block_7;
									end
								3'b110:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[6] = 1'b1;
										dirty_next[6] = 1'b1;
										block_next_0 = block_0;
										block_next_1 = block_1;
										block_next_2 = block_2;
										block_next_3 = block_3;
										block_next_4 = block_4;
										block_next_5 = block_5;
										block_next_6 = block_to_write;
										block_next_7 = block_7;
									end
								3'b111:
									begin
										valid_next = valid;
										dirty_next = dirty;
										valid_next[7] = 1'b1;
										dirty_next[7] = 1'b1;
										block_next_0 = block_0;
										block_next_1 = block_1;
										block_next_2 = block_2;
										block_next_3 = block_3;
										block_next_4 = block_4;
										block_next_5 = block_5;
										block_next_6 = block_6;
										block_next_7 = block_to_write;
									end
								endcase
						end
					
					else
						begin
							valid_next = valid;
							dirty_next = dirty;
							
							block_next_0 = block_0;
							block_next_1 = block_1;
							block_next_2 = block_2;
							block_next_3 = block_3;
							block_next_4 = block_4;
							block_next_5 = block_5;
							block_next_6 = block_6;
							block_next_7 = block_7;
						end
				end
			
			2'b01:					//write_to_mem
				begin
					valid_next = valid;
					dirty_next = dirty;				
							
					tag_next_0 = tag_0;
					tag_next_1 = tag_1;
					tag_next_2 = tag_2;
					tag_next_3 = tag_3;
					tag_next_4 = tag_4;
					tag_next_5 = tag_5;
					tag_next_6 = tag_6;
					tag_next_7 = tag_7;
							
					block_next_0 = block_0;
					block_next_1 = block_1;
					block_next_2 = block_2;
					block_next_3 = block_3;
					block_next_4 = block_4;
					block_next_5 = block_5;
					block_next_6 = block_6;
					block_next_7 = block_7;
				end
			2'b10:			//mem write to cache
				begin
					case (proc_addr[4:2])
						3'b000:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[0] = 1'b1;
							dirty_next[0] = 1'b0;
							
							tag_next_0 = proc_addr[29:5];
							tag_next_1 = tag_1;
							tag_next_2 = tag_2;
							tag_next_3 = tag_3;
							tag_next_4 = tag_4;
							tag_next_5 = tag_5;
							tag_next_6 = tag_6;
							tag_next_7 = tag_7;
							
							block_next_0 = mem_rdata;
							block_next_1 = block_1;
							block_next_2 = block_2;
							block_next_3 = block_3;
							block_next_4 = block_4;
							block_next_5 = block_5;
							block_next_6 = block_6;
							block_next_7 = block_7;
							end
						
						3'b001:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[1] = 1'b1;
							dirty_next[1] = 1'b0;
							
							tag_next_0 = tag_0;
							tag_next_1 = proc_addr[29:5];
							tag_next_2 = tag_2;
							tag_next_3 = tag_3;
							tag_next_4 = tag_4;
							tag_next_5 = tag_5;
							tag_next_6 = tag_6;
							tag_next_7 = tag_7;
							
							block_next_0 = block_0;
							block_next_1 = mem_rdata;
							block_next_2 = block_2;
							block_next_3 = block_3;
							block_next_4 = block_4;
							block_next_5 = block_5;
							block_next_6 = block_6;
							block_next_7 = block_7;	
						
							end
							
						3'b010:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[2] = 1'b1;
							dirty_next[2] = 1'b0;
							
							tag_next_0 = tag_0;
							tag_next_1 = tag_1;
							tag_next_2 = proc_addr[29:5];
							tag_next_3 = tag_3;
							tag_next_4 = tag_4;
							tag_next_5 = tag_5;
							tag_next_6 = tag_6;
							tag_next_7 = tag_7;
							
							block_next_0 = block_0;
							block_next_1 = block_1;
							block_next_2 = mem_rdata;
							block_next_3 = block_3;
							block_next_4 = block_4;
							block_next_5 = block_5;
							block_next_6 = block_6;
							block_next_7 = block_7;	
													
							end
							
						3'b011:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[3] = 1'b1;
							dirty_next[3] = 1'b0;
							
							tag_next_0 = tag_0;
							tag_next_1 = tag_1;
							tag_next_2 = tag_2;
							tag_next_3 = proc_addr[29:5];
							tag_next_4 = tag_4;
							tag_next_5 = tag_5;
							tag_next_6 = tag_6;
							tag_next_7 = tag_7;
							
							block_next_0 = block_0;
							block_next_1 = block_1;
							block_next_2 = block_2;
							block_next_3 = mem_rdata;
							block_next_4 = block_4;
							block_next_5 = block_5;
							block_next_6 = block_6;
							block_next_7 = block_7;	
													
							end
							
						3'b100:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[4] = 1'b1;
							dirty_next[4] = 1'b0;
							
							tag_next_0 = tag_0;
							tag_next_1 = tag_1;
							tag_next_2 = tag_2;
							tag_next_3 = tag_3;
							tag_next_4 = proc_addr[29:5];
							tag_next_5 = tag_5;
							tag_next_6 = tag_6;
							tag_next_7 = tag_7;
							
							block_next_0 = block_0;
							block_next_1 = block_1;
							block_next_2 = block_2;
							block_next_3 = block_3;
							block_next_4 = mem_rdata;
							block_next_5 = block_5;
							block_next_6 = block_6;
							block_next_7 = block_7;	
													
							end
							
						3'b101:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[5] = 1'b1;
							dirty_next[5] = 1'b0;
							
							tag_next_0 = tag_0;
							tag_next_1 = tag_1;
							tag_next_2 = tag_2;
							tag_next_3 = tag_3;
							tag_next_4 = tag_4;
							tag_next_5 = proc_addr[29:5];
							tag_next_6 = tag_6;
							tag_next_7 = tag_7;
							
							block_next_0 = block_0;
							block_next_1 = block_1;
							block_next_2 = block_2;
							block_next_3 = block_3;
							block_next_4 = block_4;
							block_next_5 = mem_rdata;
							block_next_6 = block_6;
							block_next_7 = block_7;	
													
							end
							
						3'b110:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[6] = 1'b1;
							dirty_next[6] = 1'b0;
							
							tag_next_0 = tag_0;
							tag_next_1 = tag_1;
							tag_next_2 = tag_2;
							tag_next_3 = tag_3;
							tag_next_4 = tag_4;
							tag_next_5 = tag_5;
							tag_next_6 = proc_addr[29:5];
							tag_next_7 = tag_7;
							
							block_next_0 = block_0;
							block_next_1 = block_1;
							block_next_2 = block_2;
							block_next_3 = block_3;
							block_next_4 = block_4;
							block_next_5 = block_5;
							block_next_6 = mem_rdata;
							block_next_7 = block_7;	
													
							end
							
						3'b111:
							begin
							valid_next = valid;
							dirty_next = dirty;
							valid_next[7] = 1'b1;
							dirty_next[7] = 1'b0;
							
							tag_next_0 = tag_0;
							tag_next_1 = tag_1;
							tag_next_2 = tag_2;
							tag_next_3 = tag_3;
							tag_next_4 = tag_4;
							tag_next_5 = tag_5;
							tag_next_6 = tag_6;
							tag_next_7 = proc_addr[29:5];
							
							block_next_0 = block_0;
							block_next_1 = block_1;
							block_next_2 = block_2;
							block_next_3 = block_3;
							block_next_4 = block_4;
							block_next_5 = block_5;
							block_next_6 = block_6;
							block_next_7 = mem_rdata;					
							end
					endcase
				end
			
			2'b11:					//nothing
				begin
					valid_next = valid;
					dirty_next = dirty;				
							
					tag_next_0 = tag_0;
					tag_next_1 = tag_1;
					tag_next_2 = tag_2;
					tag_next_3 = tag_3;
					tag_next_4 = tag_4;
					tag_next_5 = tag_5;
					tag_next_6 = tag_6;
					tag_next_7 = tag_7;
							
					block_next_0 = block_0;
					block_next_1 = block_1;
					block_next_2 = block_2;
					block_next_3 = block_3;
					block_next_4 = block_4;
					block_next_5 = block_5;
					block_next_6 = block_6;
					block_next_7 = block_7;
				end
	
			endcase	
	end
	
	always@(*)					//handle the output
	begin
		case(state)
			2'b00:				//read/write
				begin
					proc_stall = stall;
					mem_read = 1'b0;
					mem_write= 1'b0;
					mem_addr = 28'b0;
					mem_wdata= 128'b0;
					if (proc_read && hit)
						begin
							proc_rdata = block_to_read;
						end
					else
						begin
							proc_rdata = 32'b0;
						end
				
				end
			2'b01:				//write to memory
				begin
					proc_stall = 1'b1;
					proc_rdata = 32'b0;
					mem_read = 1'b0;
					mem_write= 1'b1;
					mem_addr = {tag , proc_addr[4:2]};
					mem_wdata= block;
				end
				
			2'b10:				//write from memory
				begin
					proc_stall = 1'b1;
					proc_rdata = 32'b0;
					mem_read = 1'b1;
					mem_write= 1'b0;
					mem_addr = proc_addr[29:2];					
					mem_wdata=128'b0;
					
				end
			2'b11:
				begin
					proc_stall = 1'b1;
					proc_rdata = 32'b0;
					mem_read = 1'b1;
					mem_write= 1'b0;
					mem_addr = proc_addr[29:2];					
					mem_wdata=128'b0;
					
				end
		endcase
	end
	
	always@(*)						//next_state
	begin
		case(state)
			2'b00:					//read and write
				begin
					if (hit)
						begin
							next_state = 2'b00;
						end
					else if (dirty)
						begin
							next_state = 2'b01;
						end
					else
						begin
							next_state = 2'b10;
						end
				end
		
			2'b01:					//write back to memory
				begin
					if (mem_ready)
						begin
						next_state = 2'b10;
						end
					else
						begin
						next_state = 2'b01;
						end
				end
				
			2'b10:					//read from memory
				begin
					if (mem_ready)
						begin
							next_state = 2'b00;
						end
					else
						begin
							next_state = 2'b10;
						end
				end
			
			2'b11:
				begin
					next_state = 2'b11;
				end
			endcase
	end
	
	
	


//==== sequential circuit =================================



always@( posedge clk or posedge proc_reset ) begin
    if( proc_reset ) begin
			state <= 2'b00;
			
			block_0 <= 128'b0;
			block_1 <= 128'b0;
			block_2 <= 128'b0;
			block_3 <= 128'b0;
			block_4 <= 128'b0;
			block_5 <= 128'b0;
			block_6 <= 128'b0;
			block_7 <= 128'b0;
			
			valid <= 8'd0;
			dirty <= 8'd0;
							
			tag_0 <= 25'd0;
			tag_1 <= 25'd0;
			tag_2 <= 25'd0;
			tag_3 <= 25'd0;
			tag_4 <= 25'd0;
			tag_5 <= 25'd0;
			tag_6 <= 25'd0;
			tag_7 <= 25'd0;
	
    end
    else begin
	
		valid <= valid_next;
		dirty <= dirty_next;
		
		tag_0 <= tag_next_0;
		tag_1 <= tag_next_1;
		tag_2 <= tag_next_2;
		tag_3 <= tag_next_3;
		tag_4 <= tag_next_4;
		tag_5 <= tag_next_5;
		tag_6 <= tag_next_6;
		tag_7 <= tag_next_7;
	
		state <= next_state;
		
		block_0 <= block_next_0;
		block_1 <= block_next_1;
		block_2 <= block_next_2;
		block_3 <= block_next_3;
		block_4 <= block_next_4;
		block_5 <= block_next_5;
		block_6 <= block_next_6;
		block_7 <= block_next_7;
		
    
    end
end

endmodule
