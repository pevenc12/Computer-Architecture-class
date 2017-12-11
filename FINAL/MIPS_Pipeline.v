module MIPS_Pipeline (
		clk, 
		rst_n,
		ICACHE_ren,
		ICACHE_wen,
		ICACHE_addr,
		ICACHE_wdata,
		ICACHE_stall,
		ICACHE_rdata,
		DCACHE_ren,
		DCACHE_wen,
		DCACHE_addr,
		DCACHE_wdata,
		DCACHE_stall,
		DCACHE_rdata
	);
	
//=======================in/output============================
	input clk, rst_n;
	output reg [29:0] ICACHE_addr, DCACHE_addr;
	output reg [31:0] ICACHE_wdata, DCACHE_wdata;
	
	input ICACHE_stall, DCACHE_stall;
	input [31:0] ICACHE_rdata, DCACHE_rdata;
	output reg ICACHE_wen, ICACHE_ren, DCACHE_wen, DCACHE_ren;
	
//=======================declaration==========================
	wire rst;
	assign rst = ~(rst_n);


	
	reg MemRead_ID, MemRead_EX, MemRead_MEM, MemWrite_ID, MemWrite_EX, MemWrite_MEM, RegWrite_ID, RegWrite_EX, RegWrite_MEM, RegWrite_WB, Jump, JumpToReg;
	reg [1:0] ALUSrc_ID, ALUSrc_EX;
	reg [1:0] RegDst_ID, RegDst_EX , MemToReg_ID, MemToReg_EX, MemToReg_MEM;
	reg [4:0] Read_register_1, Read_register_2, Write_register_ID, Write_register_EX;	
	reg [4:0] IFID_Rs, IFID_Rt, IFID_Rd, IDEX_Rt;
	reg [4:0] MEM_Rd;
	reg [4:0] WB_Rd;
	reg [4:0] EX_Rs, EX_Rt, EX_Rd;
	reg [3:0] ALUctrl;
	reg Jump_ID, Jump_EX, Jump_MEM;
	reg [4:0] Sa_ID, Sa_EX;
	reg seton_ID, seton_EX;
	reg ID_FLUSH, ID_FLUSH_next;
	reg jr, jalr;
	reg [31:0] jalr_addr_ID;
	reg [31:0] PC_FLUSH, PC_FLUSH_next;
	reg [31:0] Sign_extend_0_ID, Sign_extend_0_EX;

	reg [5:0] IR_EX_5;
	reg [31:0] beq_addr_ID, jr_addr_ID;

	reg hazard_lw, jalr_WB, jalr_EX, jalr_MEM;
	integer i;
	reg Branch_ID, Branch_EX, Branch_MEM;
	reg [2:0] 	ALUOp_ID, ALUOp_EX;
	reg [31:0] Sign_extend_ID, Sign_extend_EX;
	reg [31:0] MUX_Branch, MUX_Jump;

	reg [4:0] Reg_R1, Reg_R2, Reg_W;
	reg [31:0] ReadData_1_ID, ReadData_1_EX, ReadData_2_ID, ReadData_2_EX, ReadData_2_MEM;
	reg [31:0]	Register[31:0];
	reg [31:0]	Register_next[31:0];
	reg [31:0] IR;
	reg [31:0] ALUin1, ALUin2, ALU_in_2_00;
	reg [1:0] ForwardA, ForwardB;
	reg [31:0] ALU_result_EX, ALU_result_MEM, ALU_result_EX0, ALU_result_EX1, ALU_result_EX2, ALU_result_EX3;
	reg [3:0] ALU_ctrl;
	reg [31:0] Writeback_MEM, Writeback_WB;
	reg [31:0] ReadDataMem;
	reg [31:0] PCin_ID, PCin_EX, PCin_MEM, JumpAddr_ID, BranchAddr_ID, Branch_result_ID, ICACHE_addr_ID, ICACHE_addr_MEM, ICACHE_addr_EX;
	reg [31:0] ICACHE_addr_next;
	wire [31:0] addr_plus_four;
	wire [4:0] amount;
	wire stall;
	reg branch_enable;
	reg [2:0]Forward_ID, Forward_EX;

	reg [15:0] all_time, miss_time, down_time;
	
	assign addr_plus_four = ICACHE_addr + 32'd4;
	assign amount = Sa_EX;


	assign stall =  ICACHE_stall || DCACHE_stall ;

	
//=======================combinational part===================
	always@(*)
	begin
		case (IR[31:26])
			6'b000000:begin					//R-type
				RegDst_ID = 2'b01;
				ALUSrc_ID = 2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				Branch_ID	=	0;
				ALUOp_ID	= 	3'b010;
				Jump_ID 	=	0; 
			
			if (IR[5:0] == 6'd9) begin		//jalr
				MemToReg_ID =  2'b10;
				jalr        =	1'b1;
				jr=0;
				RegWrite_ID =  1'b1;
			end
				
			else if (IR[5:0]==6'b001000) begin
				MemToReg_ID =	2'b00;
				jalr=0;
				jr= 1'b1;
				RegWrite_ID =	0;
			end
			else begin
				MemToReg_ID =	2'b00;
				jalr=0;
				jr=0;
				RegWrite_ID =  1'b1;
			end
			end
			
			6'd35:begin					//lw
				RegDst_ID = 2'b00;
				ALUSrc_ID = 2'b01;
				MemToReg_ID = 2'b01;
				MemRead_ID	= 1'b1;
				MemWrite_ID =	0;
				RegWrite_ID = 1'b1;
				Branch_ID	=	0;
				ALUOp_ID	=	3'b000;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			6'd43:begin					//sw
				RegDst_ID = 2'b00;
				ALUSrc_ID = 2'b01;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =  1'b1;
				RegWrite_ID =	0;
				Branch_ID	=	0;
				ALUOp_ID	=	3'b000;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			6'd4:begin					//beq
				RegDst_ID = 2'b00;
				ALUSrc_ID = 2'b00;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID =	0;
				Branch_ID	=  1'b1;
				ALUOp_ID	= 3'b001;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			6'd8:begin					//addi
				RegDst_ID = 2'b00;
				ALUSrc_ID =  2'b01;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID =  1'b1;
				Branch_ID	=	0;
				ALUOp_ID	=	3'b000;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			
			6'd12:begin					//andi
				RegDst_ID = 2'b00;
				ALUSrc_ID = 2'b11;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID = 1'b1;
				Branch_ID	=	0;
				ALUOp_ID	= 	3'b011;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			
			6'd13:begin					//ori
				RegDst_ID = 2'b00;
				ALUSrc_ID =  2'b11;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID =  1'b1;
				Branch_ID	=	0;
				ALUOp_ID	= 	3'b100;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			6'd14:begin					//xori
				RegDst_ID = 2'b00;
				ALUSrc_ID =  2'b11;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID =  1'b1;
				Branch_ID	=	0;
				ALUOp_ID	=  3'b101;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			6'd10:begin					//slti
				RegDst_ID = 2'b00;
				ALUSrc_ID = 2'b01;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID = 1'b1;
				Branch_ID	=	0;
				ALUOp_ID	= 	3'b110;
				Jump_ID 	=	0;
				jr			=	0;
				jalr		=	0;
				
			end
			
			
			6'd2:begin					//j
				RegDst_ID = 2'b00;
				ALUSrc_ID =  2'b11;
				MemToReg_ID =	2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID =	0;
				Branch_ID	=	0;
				ALUOp_ID	= 	3'b110;
				Jump_ID 	= 1'b1;
				jr			=	0;
				jalr		=	0;
				
			end
			
			
			6'd3:begin					//jal
				RegDst_ID =  2'b10;
				ALUSrc_ID = 2'b11;
				MemToReg_ID =  2'b10;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID =  1'b1;
				Branch_ID	=	0;
				ALUOp_ID	= 	3'b110;
				Jump_ID 	=  1'b1;
				jr			=	0;
				jalr		=	0;
				
			end
			
			default:begin
			
				RegDst_ID = 2'b00;
				ALUSrc_ID = 2'b00;
				MemToReg_ID = 2'b00;
				MemRead_ID	=	0;
				MemWrite_ID =	0;
				RegWrite_ID =	0;
				Branch_ID	=	0;
				ALUOp_ID	=	3'b000;
				Jump_ID 	= 	0;
				jr			=	0;
				jalr		=	0;
			end
			
			endcase
		
	end
	
	
	always@(*)										//FLUSH - BEQ
	begin
	
		PCin_ID = {ICACHE_addr , 2'b0} + 32'd4;
		JumpAddr_ID = { PCin_ID[31:28] , IR[25:0] , 2'b00};
		jalr_addr_ID = ReadData_1_ID;
		beq_addr_ID = PCin_ID + { {14{IR[15]}} , IR[15:0] , 2'b00} - 32'd4;
		jr_addr_ID = ReadData_1_ID;
	
		if ( (IR[31:26] == 6'd4) && branch_enable )	//beq
		begin
			ICACHE_addr_next = beq_addr_ID;
			ID_FLUSH_next = 1'b1;
		end
		
		else if ( (IR[31:26] == 6'd2)  || (IR[31:26] == 6'd3) )		//j jal
		begin

			PCin_ID = {ICACHE_addr , 2'b0} ;
			ICACHE_addr_next = JumpAddr_ID;
			ID_FLUSH_next = 1'b1;
		end
		
		else if ( (IR[31:26] == 6'd0) && (IR[5:0] == 6'd9) )		//jalr
		begin

			PCin_ID = {ICACHE_addr , 2'b0} ;
			ICACHE_addr_next = jalr_addr_ID;
			ID_FLUSH_next = 1'b1;
		
		end
		
		else if ( (IR[31:26] == 6'd0) && (IR[5:0] == 6'd8) )		//jr
		begin

			ICACHE_addr_next = jr_addr_ID;
			ID_FLUSH_next = 1'b1;
		end
		
		else
		begin
			ICACHE_addr_next = PCin_ID;
			ID_FLUSH_next = 1'b0;
		end
	end
	
	
	always@(*)										//ID-PART   AND Sa
	begin
		Read_register_1 = IR[25:21];
		Read_register_2 = IR[20:16];
		Sa_ID = IR[10:6];
		
		case (RegDst_ID)
			2'b00:begin

				if ( (IR[31:26] == 6'd43) || (IR[31:26] == 6'd4) )
				begin
					IFID_Rt = IR[20:16];
					Write_register_ID = 32'd0;
				end
				else begin
					IFID_Rt = 5'd0;
					Write_register_ID = IR[20:16];
				end
				
			end 
			2'b01:begin
			Write_register_ID = IR[15:11];
					IFID_Rt = IR[20:16];
				
			end
			2'b10: begin

			Write_register_ID = 5'd31;
					IFID_Rt = IR[20:16];
			end

			2'b11: begin

			Write_register_ID = IR[20:16];
					IFID_Rt = IR[20:16];
			end
		endcase

		IFID_Rs = IR[25:21];
		ReadData_1_ID = Register_next [Read_register_1];
		ReadData_2_ID = Register_next [Read_register_2];

		
	end
	
	
	
	
	always@(*)										//sign-extend 
	begin
		Sign_extend_ID = {{16{IR[15]}}, IR[15:0]};
		Sign_extend_0_ID = { 16'd0 , IR[15:0] };
		
	end
	
	always@(*)										//ALUSRC PART
	begin
		
		case (ALUSrc_EX)
			2'b00: ALUin2 = ALU_in_2_00;
			2'b01: ALUin2 = Sign_extend_EX;
			2'b11: ALUin2 = Sign_extend_0_EX;
			2'b10: ALUin2 = ALU_in_2_00;
		endcase
		
	end
	
	always@ (*)										//Hazard detection for lw
	begin
		if (   ( MemRead_EX &&( (Write_register_EX == IFID_Rs) || (Write_register_EX == IFID_Rt) ) &&　(|Write_register_EX) ) ||
			( Branch_ID &&   ( ( ( ( Write_register_EX == IFID_Rs) || (Write_register_EX == IFID_Rt ) ) &&  (|Write_register_EX) ) || (  ( MEM_Rd == IFID_Rs)||(MEM_Rd == IFID_Rt)) && (|MEM_Rd) )  ) )
			
			hazard_lw = 1;
		else
			hazard_lw = 0;

		if(Branch_ID && (Write_register_EX == IFID_Rs) &&　|Write_register_EX)
			Forward_ID = 3'b001;
		else if(Branch_ID && (Write_register_EX == IFID_Rt) &&　|Write_register_EX)
			Forward_ID = 3'b010;
		else if(Branch_ID && (MEM_Rd == IFID_Rs) && |MEM_Rd )
			Forward_ID = 3'b011;
		else if(Branch_ID && (MEM_Rd == IFID_Rt) && |MEM_Rd)
			Forward_ID = 3'b100;
		else
			Forward_ID = 3'b000;
	end

	always @(*)begin
		if( (Forward_EX==3'b001) && (ALU_result_MEM == ReadData_2_ID)) 
			branch_enable = 1'b1;
		else if( (Forward_EX == 3'b010) &&(ALU_result_MEM == ReadData_1_ID))
			branch_enable = 1'b1;

		else if ( (Forward_EX==3'b011) && (Writeback_MEM == ReadData_2_ID) )
			branch_enable = 1'b1;
		else if ( (Forward_EX== 3'b100) && (Writeback_MEM == ReadData_1_ID) )
			branch_enable = 1'b1;

		else if ( Forward_EX == 3'b000 && Branch_ID && (ReadData_1_ID == ReadData_2_ID) )
			branch_enable = 1'b1;

		else
			branch_enable = 1'b0;
	end
	
	
	always@(*)										//forwarding unit
	begin
		if ((MEM_Rd == EX_Rs)&& (|MEM_Rd) &&(|EX_Rs))
			ForwardA = 2'b10;
		else if ((WB_Rd == EX_Rs) && (|WB_Rd) && (|EX_Rs))
			ForwardA = 2'b01;
		else
			ForwardA = 2'b00;
	
	end
	
	always@(*)										//forwarding unit
	begin
		if ((MEM_Rd == EX_Rt)&& (|MEM_Rd) && (|EX_Rt))
			ForwardB = 2'b10;
		else if ((WB_Rd == EX_Rt)&& (|WB_Rd) && (|EX_Rt))
			ForwardB = 2'b01;
		else
			ForwardB = 2'b00;
	end
	
	
	always@(*)																			//ALU control 10 for R-type
	begin
		case (ALUOp_EX)
		3'b010:
			begin
			case(IR_EX_5)
				6'b100000:ALU_ctrl=4'b0010;						//add
				6'b100010:ALU_ctrl=4'b0110;						//sub
				6'b100100:ALU_ctrl=4'b0000;						//and
				6'b100101:ALU_ctrl=4'b0001;						//or
				6'b101010:ALU_ctrl=4'b0111;						//slt
				6'd39	 :ALU_ctrl=4'b0100;						//nor
				6'd0	 :ALU_ctrl=4'b0101;						//sll
				6'd2	 :ALU_ctrl=4'b1000;						//srl
				6'd3	 :ALU_ctrl=4'b1001;						//sra	
			default: ALU_ctrl=4'b0010;
			endcase
			end
		3'b000:ALU_ctrl=4'b0010;
		3'b001:ALU_ctrl=4'b0110;
		3'b011:ALU_ctrl=4'b0000;
		3'b100:ALU_ctrl=4'b0001;
		3'b101:ALU_ctrl=4'b0011;								//xor
		3'b110:ALU_ctrl=4'b0111;
		default:ALU_ctrl=4'b0010;
		endcase
	end
	
	
	always@(*)										//EX-PART with ALU
	begin
		case (ForwardA)
			2'b00: ALUin1 = ReadData_1_EX;
			2'b01: ALUin1 = Writeback_WB;
			2'b10: ALUin1 = Writeback_MEM;
			2'b11: ALUin1 = ReadData_1_EX;
			endcase
		case (ForwardB)
			2'b00: ALU_in_2_00 = ReadData_2_EX;
			2'b01: ALU_in_2_00 = Writeback_WB;
			2'b10: ALU_in_2_00 = Writeback_MEM;
			2'b11: ALU_in_2_00 = ReadData_2_EX;
			endcase
		ALU_result_EX0 = ALUin1;
		ALU_result_EX1 = ALUin1;
		ALU_result_EX2 = ALUin1;
		ALU_result_EX3 = ALUin1;
		case (ALU_ctrl)
			4'b0000: ALU_result_EX = ALUin1 & ALUin2;
			4'b0001: ALU_result_EX = ALUin1 | ALUin2;
			4'b0010: ALU_result_EX = ALUin1 + ALUin2;
			4'b0110: ALU_result_EX = ALUin1 - ALUin2;
			4'b0111: ALU_result_EX = (ALUin1 < ALUin2)? 32'b1 : 32'b0;
			4'b0011: ALU_result_EX = ALUin1 ^ ALUin2;
			4'b0100: ALU_result_EX = ~ (ALUin1 | ALUin2);
			4'b0101: begin

					if(amount[0]) 
						ALU_result_EX0 = ALUin2 << 1;
					else 
						ALU_result_EX0 = ALUin2;

					if(amount[1]) 
						ALU_result_EX1 = ALU_result_EX0 << 2;
					else 
						ALU_result_EX1 = ALU_result_EX0;

					if(amount[2]) 
						ALU_result_EX2 = ALU_result_EX1 << 4;
					else 
						ALU_result_EX2 = ALU_result_EX1;

					if(amount[3]) 
						ALU_result_EX3 = ALU_result_EX2 << 8;
					else 
						ALU_result_EX3 = ALU_result_EX2;				

					if(amount[4]) 
						ALU_result_EX = ALU_result_EX3 << 16;
					else 
						ALU_result_EX = ALU_result_EX3;
					end
									//sll
			4'b1000:begin
				
					if(amount[0]) 
						ALU_result_EX0 = ALUin2 >> 1;
					else 
						ALU_result_EX0 = ALUin2;

					if(amount[1]) 
						ALU_result_EX1 = ALU_result_EX0 >> 2;
					else 
						ALU_result_EX1 = ALU_result_EX0;

					if(amount[2]) 
						ALU_result_EX2 = ALU_result_EX1 >> 4;
					else 
						ALU_result_EX2 = ALU_result_EX1;

					if(amount[3]) 
						ALU_result_EX3 = ALU_result_EX2 >> 8;
					else 
						ALU_result_EX3 = ALU_result_EX2;				

					if(amount[4]) 
						ALU_result_EX = ALU_result_EX3 >> 16;
					else 
						ALU_result_EX = ALU_result_EX3;
					
			end 																			//srl

			4'b1001:begin
				
					if(amount[0]) 
						ALU_result_EX0 = {ALUin2[0],ALUin2[31:1]};
					else 
						ALU_result_EX0 = ALUin2;

					if(amount[1]) 
						ALU_result_EX1 = {ALU_result_EX0[1:0],ALU_result_EX0[31:2]};
					else 
						ALU_result_EX1 = ALU_result_EX0;

					if(amount[2]) 
						ALU_result_EX2 = {ALU_result_EX1[3:0],ALU_result_EX1[31:4]};
					else 
						ALU_result_EX2 = ALU_result_EX1;

					if(amount[3]) 
						ALU_result_EX3 = {ALU_result_EX2[7:0],ALU_result_EX2[31:8]};
					else 
						ALU_result_EX3 = ALU_result_EX2;				

					if(amount[4]) 
						ALU_result_EX = {ALU_result_EX3[15:0],ALU_result_EX3[31:16]};
					else 
						ALU_result_EX = ALU_result_EX3;
					
			end 		//sra
			default: ALU_result_EX = 32'b1;
		endcase
		

	end
	
	always@(*)																			//DCACHE
	begin
		if (MemRead_MEM)
		begin
			DCACHE_ren = 1'b1;
			DCACHE_wen = 1'b0;
			DCACHE_addr= ALU_result_MEM[31:2];
			ReadDataMem= DCACHE_rdata;
			DCACHE_wdata = 32'd0;
		end

		else if (MemWrite_MEM)
		begin
			DCACHE_ren = 1'b0;
			DCACHE_wen = 1'b1;
			ReadDataMem= DCACHE_rdata;
			DCACHE_addr= ALU_result_MEM[31:2];
			DCACHE_wdata = ReadData_2_MEM;
		end

		else begin
			
			DCACHE_ren = 1'b0;
			DCACHE_wen = 1'b0;
			ReadDataMem= DCACHE_rdata;
			DCACHE_addr= ALU_result_MEM[31:2];
			DCACHE_wdata = ReadData_2_MEM;
		end
	
	end
	
	always@(*)																			//WB
	begin
		case (MemToReg_MEM)
			2'b00:Writeback_MEM=ALU_result_MEM;
			2'b01:Writeback_MEM=ReadDataMem;
			2'b10:Writeback_MEM=PCin_MEM;
			2'b11:Writeback_MEM=ALU_result_MEM;
		endcase
	end
	
	always@(*)
	begin
		for (i=0;i<32;i=i+1)
		Register_next[i] = Register[i];

		if (RegWrite_WB)
			Register_next [WB_Rd] = Writeback_WB;
		
		
	end
	
//=======================sequential part======================

always @(posedge DCACHE_stall) begin
	miss_time <= miss_time + 1'b1;

end

always @( negedge DCACHE_stall ) begin
	down_time <= down_time + 1'b1;

end

always@(posedge clk or negedge rst_n)
begin
	if (~rst_n)
	begin

		for(i = 0; i<32;i=i+1)
			Register[i] <= 32'b0;

		ID_FLUSH <= 1'b0;
		ICACHE_ren	<= 1'b0;
		ICACHE_wen	<= 1'b0;
		ICACHE_wdata<= 32'd0;
	
		IR_EX_5 <= 6'd0;
		ICACHE_addr	<= 30'd0;
		IR <= 32'd0;

		down_time <= 16'd0;
		
		Jump_EX <= 1'b0;
	
		jalr_EX <= 1'b0;
		jalr_MEM<= 1'b0;
		jalr_WB <= 1'b0;
		
		Sign_extend_EX <= 32'd0;
		Sa_EX <= 5'd0;
		
		EX_Rs <= 5'd0;
		EX_Rt <= 5'd0;
		EX_Rd <= 5'd0;
		ALUOp_EX <= 3'b000;
		ALUSrc_EX <= 2'b00;
		MemWrite_EX <= 1'b0;
		MemWrite_MEM<= 1'b0;
		Branch_EX <= 1'b0;
		Branch_MEM<= 1'b0;
		MemToReg_EX <= 2'b00;
		MemToReg_MEM<= 2'b00;
		ALU_result_MEM <= 32'd0;
		
		RegWrite_EX <= 1'b0;
		RegWrite_MEM<= 1'b0;
		RegWrite_WB <= 1'b0;
		
		ReadData_1_EX <= 32'd0;
		ReadData_2_EX <= 32'd0;
		Sign_extend_0_EX <= 32'd0;
		
		PCin_EX <= 32'd0;
		PCin_MEM<= 32'd0;
		
		Write_register_EX <= 5'd0;
		MEM_Rd<= 5'd0;
		WB_Rd <= 5'd0;
		MemRead_EX <= 1'b0;
		MemRead_MEM<= 1'b0;
		
		ICACHE_addr_EX <= 32'd0;
		ICACHE_addr_MEM<= 32'd0;
		Writeback_WB <= 32'b0;
		Forward_EX <= 2'b0;
		
		all_time <= 16'd0;
		miss_time <= 16'd0;

	end
		
	else
	begin
		Forward_EX <= (stall) ? Forward_EX: Forward_ID;
		ID_FLUSH <= (stall) ? ID_FLUSH : ID_FLUSH_next;
		ICACHE_ren	<= 1'b1;
		ICACHE_wen	<= 1'b0;
		ICACHE_wdata<= 32'b0;

		all_time <= (stall || hazard_lw) ? all_time : (MemRead_MEM || MemWrite_MEM) ? all_time + 1'b1 : all_time;

		Register[0] <= 32'b0;
	
		for (i=1;i<32;i=i+1)
		Register[i] <= Register_next[i];

		ICACHE_addr	<= (stall || hazard_lw) ? ICACHE_addr :  ICACHE_addr_next[31:2] ;
		IR <= (stall || hazard_lw) ? IR :  (ID_FLUSH_next) ? 32'd0 : ICACHE_rdata;
		IR_EX_5 <= (stall) ? IR_EX_5 : IR[5:0];	
		Jump_EX <= (stall) ? Jump_EX :(hazard_lw) ? 1'b0 : Jump_ID;
	
		jalr_EX <= (stall) ? jalr_EX : (hazard_lw) ? 1'b0 : jalr;
		jalr_MEM<= (stall) ? jalr_MEM : jalr_EX;
		jalr_WB <= (stall) ? jalr_WB : jalr_MEM;
		
		Sign_extend_EX <= (stall) ? Sign_extend_EX : (hazard_lw) ? 32'd0 : Sign_extend_ID;
		Sa_EX <= (stall) ? Sa_EX : (hazard_lw) ? 5'd0 : Sa_ID;

		
		EX_Rs <= (stall) ? EX_Rs : IFID_Rs;
		EX_Rt <= (stall) ? EX_Rt : IFID_Rt;

		ALUOp_EX <= (stall) ? ALUOp_EX :(hazard_lw) ? 3'b000 : ALUOp_ID;
		ALUSrc_EX <= (stall) ? ALUSrc_EX : (hazard_lw) ? 2'b00 : ALUSrc_ID;
		MemWrite_EX <= (stall) ? MemWrite_EX : (hazard_lw) ? 1'b0 : MemWrite_ID;
		MemWrite_MEM<= (stall) ? MemWrite_MEM: MemWrite_EX;
		Branch_EX <= (stall) ? Branch_EX : (hazard_lw) ? 1'b0 : Branch_ID;
		Branch_MEM<= (stall) ? Branch_MEM: Branch_EX;
		MemToReg_EX <= (stall) ? MemToReg_EX : (hazard_lw) ? 2'b00 :MemToReg_ID;
		MemToReg_MEM<= (stall) ? MemToReg_MEM : MemToReg_EX;
		ALU_result_MEM <= (stall) ? ALU_result_MEM : ALU_result_EX;
		
		RegWrite_EX <= (stall) ? RegWrite_EX : (hazard_lw) ? 1'b0 : RegWrite_ID;
		RegWrite_MEM<= (stall) ? RegWrite_MEM: RegWrite_EX;
		RegWrite_WB <= (stall) ? RegWrite_WB : RegWrite_MEM;
		
		ReadData_1_EX <= (stall) ? ReadData_1_EX : (hazard_lw) ? 32'd0 : ReadData_1_ID;
		ReadData_2_EX <= (stall) ? ReadData_2_EX : (hazard_lw) ? 32'd0 : ReadData_2_ID;
		ReadData_2_MEM<= (stall) ? ReadData_2_MEM: ALU_in_2_00;
		
		Sign_extend_0_EX <= (stall) ? Sign_extend_0_EX : (hazard_lw) ? 32'd0 : Sign_extend_0_ID;
		
		PCin_EX <= (stall) ? PCin_EX : (hazard_lw) ? 32'b0 : PCin_ID;
		PCin_MEM<= (stall) ? PCin_MEM: PCin_EX;
		
		Write_register_EX <= (stall) ? Write_register_EX : (hazard_lw) ? 5'd0 : Write_register_ID;
		MEM_Rd<= (stall) ? MEM_Rd : Write_register_EX;
		WB_Rd <= (stall) ? WB_Rd : MEM_Rd;
		MemRead_EX <= (stall) ? MemRead_EX : (hazard_lw) ? 1'b0 : MemRead_ID;
		MemRead_MEM<= (stall) ? MemRead_MEM: MemRead_EX;
		
		ICACHE_addr_EX <= (stall) ? ICACHE_addr_EX : ICACHE_addr_ID;
		ICACHE_addr_MEM<= (stall) ? ICACHE_addr_MEM: ICACHE_addr_EX;

		Writeback_WB <= (stall)? Writeback_WB:Writeback_MEM;
	
	end
end


endmodule