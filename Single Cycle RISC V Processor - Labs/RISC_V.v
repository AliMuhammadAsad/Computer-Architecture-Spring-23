`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2023 5:09:04 PM
// Design Name: 
// Module Name: RISC_V
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RISC_V(
    input clk,
    input reset,
    output reg [63:0] PC_Out, ReadData1, ReadData2, WriteData, Result, Read_Data, imm_data,
    output reg [31:0] Instruction,
    output reg [6:0] opcode,
    output reg [4:0] rs1, rs2, rd,
    output reg [1:0] ALUOp,
    output reg Branch, MemRead, MemWrite, MemtoReg, ALUSrc, RegWrite
    );

wire [63:0] PC_In, PC_Out, adder_out1, adder_out2, imm_data, WriteData, ReadData1, ReadData2, Result, Read_Data;
wire [63:0] muxmid_out;
wire [31:0] Instruction;
wire [6:0] opcode, funct7;
wire [4:0] rd, rs1, rs2;
wire [3:0] Funct, Operation;
wire [2:0] funct3;
wire [1:0] ALUOp;
wire Branch, MemRead, MemWrite, MemtoReg, ALUSrc, RegWrite, CarryOut, Zero, branch_sel;


// Instruction Fetch //
Adder a1(.a(PC_Out), .b(64'd4), .out(adder_out1));
assign branch_sel = Branch && Zero;
mux_2x1_64 muxfirst(.A(adder_out1), .B(adder_out2), .S(branch_sel), .Y(PC_In));
Program_Counter pc(.clk(clk), .reset(reset), .PC_In(PC_In), .PC_Out(PC_Out));
Instruction_Memory im(.Inst_Address(PC_Out), .Instruction(Instruction));

// Instruction Decode / Register File Read //
inst_parser_32 ip(.instruction(Instruction), .opcode(opcode), .rd(rd), .funct3(funct3), .rs1(rs1), .rs2(rs2), .funct7(funct7));
im_data_extract immdata(.instruction(Instruction), .imm_data(imm_data));
Control_Unit cu(.Opcode(opcode), .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg), .ALUOp(ALUOp), .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite));
regiserFile rf(.clk(clk), .reset(reset), .WriteData(WriteData), .RS1(rs1), .RS2(rs2), .RD(rd), .RegWrite(RegWrite), .ReadData1(ReadData1), .ReadData2(ReadData2));
assign Funct = {Instruction[30], Instruction[14:12]};

// Execute / Address Calculation // 
Adder a2(.a(PC_Out), .b(imm_data << 1), .out(adder_out2));
mux_2x1_64 muxmid(.A(ReadData2), .B(imm_data), .S(ALUSrc), .Y(muxmid_out));
ALU_Control aluc(.ALUOp(ALUOp), .Funct(Funct), .Operation(Operation));
ALU64bit ALU(.a(ReadData1), .b(muxmid_out), .CarryIn(64'd0), .ALUOp(Operation), .Result(Result), .CarryOut(CarryOut), .Zero(Zero));
  
// MEM: Memory Access //
Data_Memory dm(.Mem_Addr(Result), .Write_Data(ReadData2), .clk(clk), .MemWrite(MemWrite), .MemRead(MemRead), .Read_Data(Read_Data));

// Write Back // 
mux_2x1_64 muxlast(.A(Read_Data), .B(Result), .S(MemtoReg), .Y(WriteData));

endmodule 