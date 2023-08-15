module singleCycleDataPath #(parameter N = 32)(
	input clk,prog,loadPC,
	input [29:0] initPC,
	input [6:0] blockAddr,
	input [N-1:0] Iword,
	output [N-1:0] out,
	output [1:0] flag
);


// prog bit : 1-> programming mode, 0 -> Running mode

reg [29:0] PC;		// Keeping 30 bit wide since 32 bit memory is used.

/******************************************************************/
/*
|--------------------|-----------------|
| Flag Configuration |    Flag Name    |
|--------------------|-----------------|
|        flag[0]     |    Overflow     |
|        flag[1]     |      Zero       |
|--------------------|-----------------|

|-----------------------------------------------|
|-------------INSTRUCTION FORMAT----------------|
|-----------------------------------------------|
| Bit Range | Field Name | Description     		|
|-----------|------------|----------------------|
| 31:26     | OPCODE     | Operation Code  		|
| 25:21     | RS         | Source Register 		|
| 20:16     | RT         | Target Register 		|
| 15:11     | RD         | Destination Register |
| 10:6      | Not Used   | Not Used        		|
| 5:0       | FNCLASS    | Function Class  		|
|-----------------------------------------------|
*/

/******************************************************************/
wire [16:0] controlSig;
wire [5:0] opcode,fnClass;
wire [N-1:0] instruction;

assign opcode = instruction[31:26];			// MSB 5-bits of Instruction
assign fnClass = instruction[5:0];			// LSB 5-bits of Instruction
/******************************************************************/
// RegFile Outputs
wire [N-1:0] regRsOut, regRtOut;
/******************************************************************/
wire [N-1:0] dataOut;
wire [25:0] jta;
wire [N-3:0] incPC, PCin;

/******************************************************************/
// Regfile Inputs
wire [4:0] rs,rt,rd;
assign rs = instruction[25:21];
assign rt = instruction[20:16];
assign rd = instruction[15:11];
// instruction[10:6] -> Not used
wire [4:0] regDstAddr;

// MUX 1
							// controlSig[15] and controlSig[14] are RegDst mux input control signals
assign regDstAddr = (~controlSig[15] & ~controlSig[14]) ? rt :
						  (~controlSig[15] & controlSig[14]) ? rd :
						  (controlSig[15] & ~controlSig[14]) ? (5'b11111):
						  ({5{1'bz}});


/******************************************************************/
// ALU inputs
wire [N-1:0] ALU_b;
wire [N-1:0] immediate;

assign immediate = {{16{instruction[15]}},instruction[15:0]};
					// controlSig[11] -> ALUSrc
// MUX 2
assign ALU_b = (controlSig[11]) ? immediate : regRtOut;

wire [N-1:0] ALUout;
wire ALUOvfl;
/******************************************************************/
// MUX 3
// wire [N-1:0] muxOut;
wire [N-1:0] writeBack;
assign writeBack = (~controlSig[13] & ~controlSig[12]) ? dataOut :
					 (~controlSig[13] & controlSig[12]) ? ALUout :
					 (controlSig[13] & ~controlSig[12]) ? incPC : {N{1'bz}};
assign out = writeBack;
/******************************************************************/


// Instantiate Control Section
/******************************************************************/
// Instruction Cache
wire [N-1:0] ICacheOut;
wire ICacheClk = (prog == 1'b1) ? clk : 1'b0;
instCache #(N) ICache(.pc(PC), .instruction(ICacheOut), .clk(ICacheClk), .wAddr(blockAddr), .Iword(Iword));
assign instruction = (prog == 1'b0) ? ICacheOut : {32{1'bz}};
/******************************************************************/
// Instantiate Register File
// controlSig[16] -> RegWrite
dualPortRam #(N) registerFile(.clk(clk), .dataIn(writeBack), .wr(controlSig[16]), .addrLine_r1(rs), .addrLine_r2(rt), .addrLine_w1(regDstAddr), .dataOut1(regRsOut), .dataOut2(regRtOut));
/******************************************************************/

// Instantiate ALU
alunbit #(N) ALU(.in1(regRsOut), .in2(ALU_b), .ALUfunc(controlSig[10:6]), .out(ALUout), .ovfl(flag[0]), .zero(flag[1]));

/******************************************************************/
// Instantiate Data Cache
/*
input [N-1:0] dataAddr,dataIn,
input [1:0] opType,
output [N-1:0] dataOut
*/
// controlSig[4] -> Data Write
// controlSig[5] -> Data Read
dataCache #(N) DATA(.clk(clk), .dataAddr(ALUout), .dataIn(regRtOut), .opType(controlSig[5:4]), .dataOut(dataOut));
/******************************************************************/
// Next Address Block
assign jta = instruction[25:0];
/*
	input [N-1:0] rt,rs,
	input [29:0] pc,
	input [25:0] jta,
	input [1:0] PCSrc,BrType,
	output [N-2:0] incPC,nxtPC
*/
nextAddr #(N) Address(.rs(regRsOut), .rt(regRtOut), .jta(jta), .pc(PC), .PCSrc(controlSig[1:0]), .BrType(controlSig[3:2]), .incPC(incPC), .nxtPC(PCin));
/******************************************************************/


/******************************************************************/
// Control Block
ctrlBlock CONTROL(.opcode(opcode), .fn(fnClass), .ctrlSig(controlSig));
/******************************************************************/

always@(posedge clk)begin
	if(loadPC)begin
		PC = initPC;
	end
	else begin
		PC = PCin;
	end
end

endmodule

