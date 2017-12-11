// Single Cycle MIPS
//=========================================================
// Input/Output Signals:
// positive-edge triggered         clk
// active low asynchronous reset   rst_n
// instruction memory interface    IR_addr, IR
// output for testing purposes     RF_writedata  
//=========================================================
// Wire/Reg Specifications:
// control signals             MemToReg, MemRead, MemWrite, 
//                             RegDST, RegWrite, Branch, 
//                             Jump, ALUSrc, ALUOp
// ALU control signals         ALUctrl
// ALU input signals           ALUin1, ALUin2
// ALU output signals          ALUresult, ALUzero
// instruction specifications  r, j, jal, jr, lw, sw, beq
// sign-extended signal        SignExtend
// MUX output signals          MUX_RegDST, MUX_MemToReg, 
//                             MUX_Src, MUX_Branch, MUX_Jump
// registers input signals     Reg_R1, Reg_R2, Reg_W, WriteData 
// registers                   Register
// registers output signals    ReadData1, ReadData2
// data memory contral signals CEN, OEN, WEN
// data memory output signals  ReadDataMem
// program counter/address     PCin, PCnext, JumpAddr, BranchAddr
//=========================================================

module SingleCycle_MIPS( 
    clk,
    rst_n,
    IR_addr,
    IR,
    RF_writedata,
    ReadDataMem,
    CEN,
    WEN,
    A,
    ReadData2,
    OEN
);

//==== in/out declaration =================================
    //-------- processor ----------------------------------
    input         clk, rst_n;
    input  [31:0] IR;
    output reg [31:0] IR_addr, RF_writedata;
    //-------- data memory --------------------------------
    input  [31:0] ReadDataMem;  // read_data from memory
    output  reg   CEN;  // chip_enable, 0 when you read/write data from/to memory
    output  reg   WEN;  // write_enable, 0 when you write data into SRAM & 1 when you read data from SRAM
    output  reg  [6:0] A;  // address
    output  reg  [31:0] ReadData2;  // write_data to memory
    output  reg   OEN;  // output_enable, 0

//==== reg/wire declaration ===============================
	reg [31:0]	reg_instruction, Sign_extend, ALUin1, ALUin2;
	reg Jump, Branch, MemRead, MemWrite, ALUSrc, RegWrite;		//control signal
	reg [1:0] 	ALUOp, MemToReg, RegDst;
	reg [4:0]	Read_register_1, Read_register_2, Write_register, IN5_0;
	reg [31:0]	ReadData_1, ReadData_2;
	reg [31:0]	Register[31:0];
	reg [3:0]	ALU_ctrl;
	reg [31:0]	ALU_result;
	reg [31:0]	PCin, IR_addr_next, JumpAddr, BranchAddr, Branch_result;
	reg zero;
	reg [31:0]	WriteData;
	reg jr;
	reg [6:0]i;
	reg [6:0] A_next;
//==== combinational part =================================
	always@(IR)																			//Control
	begin
		case (IR[31:26])
		6'b000000:begin					//R-type & jr
			RegDst	=	2'b01;
			ALUSrc	=	0;
			MemToReg=	2'b00;
			MemRead	=	0;
			MemWrite=	0;
			Branch	=	0;
			ALUOp	=	2'b10;
			Jump 	=	0; 
			if (IR[5:0]==5'b001000) begin
				jr=1;
				RegWrite=0;
			end
			else begin
				jr=0;
				RegWrite=1;
			end
			end
		6'b100011:begin					//lw
			RegDst	=	2'b00;
			ALUSrc	=	1;
			MemToReg=	2'b01;
			RegWrite=	1;
			MemRead	=	2'b01;
			MemWrite=	0;
			Branch	=	0;
			ALUOp	=	2'b00;
			Jump	=	0;
			jr		=	0;
			end
		6'b101011:begin					//sw
			RegDst	=	2'b00;
			ALUSrc	=	1;
			MemToReg=	2'b00;
			RegWrite=	0;
			MemRead	=	0;
			MemWrite=	1;
			Branch	=	0;
			ALUOp	=	2'b00;
			Jump	=	0;
			jr		=	0;
			end
		6'b000100:begin					//beq
			RegDst	=	2'b00;
			ALUSrc	=	0;
			MemToReg=	2'b00;
			RegWrite=	0;
			MemRead	=	0;
			MemWrite=	0;
			Branch	=	1;
			ALUOp	=	2'b01;
			Jump	=	0;
			jr		=	0;
			end
			
		6'b000010:begin					//j
			RegDst	=	2'b00;
			ALUSrc	=	0;
			MemToReg=	2'b00;
			RegWrite=	0;
			MemRead	=	0;
			MemWrite=	0;
			Branch	=	0;
			ALUOp	=	2'b01;
			Jump	=	1;
			jr		=	0;
			end
			
		6'b000011:begin					//jal
			RegDst	=	2'b10;
			ALUSrc	=	0;
			MemToReg=	2'b10;
			RegWrite=	1;
			MemRead	=	0;
			MemWrite=	0;
			Branch	=	0;
			ALUOp	=	2'b01;
			Jump	=	1;
			jr		=	0;
			end
		default: begin
			RegDst	=	2'b00;
			ALUSrc	=	0;
			MemToReg=	2'b00;
			RegWrite=	0;
			MemRead	=	0;
			MemWrite=	0;
			Branch	=	0;
			ALUOp	=	2'b00;
			Jump	=	0;
			jr		=	0;
			end
		endcase
	end
	
	always@(*)																			//Register
	begin
		Read_register_1 = IR[25:21];
		Read_register_2 = IR[20:16];
		case (RegDst)
			2'b00: Write_register=IR[20:16];
			2'b01: Write_register=IR[15:11];
			2'b10: Write_register=5'd31;
			2'b11: Write_register=5'd0;
		endcase
		ReadData_1 = Register [Read_register_1];
		ReadData_2 = Register [Read_register_2];
	end
	
	always@(*)																			//sign-extend
	begin
		Sign_extend = {{16{IR[15]}}, IR[15:0]};
	end
	
	always@(*)																			//ALU control
	begin
		case (ALUOp)
		2'b10:begin
			case(IR[5:0])
			6'b100000:ALU_ctrl=4'b0010;						//add
			6'b100010:ALU_ctrl=4'b0110;						//sub
			6'b100100:ALU_ctrl=4'b0000;						//and
			6'b100101:ALU_ctrl=4'b0001;						//or
			6'b101010:ALU_ctrl=4'b0111;						//slt
			default: ALU_ctrl=4'b0010;
			endcase
			end
		2'b00:ALU_ctrl=4'b0010;
		2'b01:ALU_ctrl=4'b0110;
		default:ALU_ctrl=4'b0010;
		endcase
	end
	
	always@(*)																			//ALU
	begin
		ALUin1 = ReadData_1;
		ALUin2 = (ALUSrc)? Sign_extend : ReadData_2;
		case (ALU_ctrl)
			4'b0000: ALU_result = ALUin1 & ALUin2;
			4'b0001: ALU_result = ALUin1 | ALUin2;
			4'b0010: ALU_result = ALUin1 + ALUin2;
			4'b0110: ALU_result = ALUin1 - ALUin2;
			4'b0111: ALU_result = (ALUin1 < ALUin2)? 32'b1 : 32'b0;
			default: ALU_result = 32'b1;
		endcase
		zero = (ALU_result==32'b0)? 1 : 0;
	end
	
	always@(*)																			//address
	begin
		PCin = IR_addr+ 32'd4;
		JumpAddr = { PCin[31:28] , IR[25:0] , 2'b00};
		BranchAddr = PCin + {Sign_extend[29:0] , 2'b00} ;
		Branch_result = (Branch & zero) ? BranchAddr : PCin;
		if (jr) begin
			IR_addr_next = ReadData_1;
		end
		else if (Jump) begin
			IR_addr_next = JumpAddr;
		end
		else begin
			IR_addr_next = Branch_result;
		end
	end
	
	always@(*)																			//memory
	begin
		case (MemToReg)
			2'b00:WriteData=ALU_result;
			2'b01:WriteData=ReadDataMem;
			2'b10:WriteData=PCin;
			2'b11:WriteData=ALU_result;
		endcase
	end
	
	always@(*)
	begin
		RF_writedata=WriteData;
		ReadData2=ReadData_2;
		A=ALU_result[8:2];
	end
	
	always @(*)
	begin
		if(MemWrite) begin
		CEN = 1'b0;
		WEN = 1'b0;
		OEN = 1'b0;
		end
		else if(MemRead) begin
		CEN = 1'b0;
		WEN = 1'b1;
		OEN = 1'b0;
		end
		else begin
		CEN = 1'b1;
		WEN = 1'b0;
		OEN = 1'b0;
		end
	end
	
//==== sequential part ====================================
	always@(posedge clk or negedge rst_n)
	begin 
		if (~rst_n)
			begin
			IR_addr <= 32'b0;

			for(i=0; i<32; i=i+1)
			Register[i] <= 32'b0;

			end
		else
			begin
				reg_instruction <= IR;
				IR_addr <= IR_addr_next;
				Register[0] <= 32'b0;
				if (RegWrite)
				Register[Write_register] <= WriteData;
				else
				Register[Write_register] <= Register[Write_register];
			end
	end
//=========================================================
endmodule
