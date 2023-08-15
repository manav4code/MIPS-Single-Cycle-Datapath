module nextAddr #(parameter N = 32)(
	input [N-1:0] rt,rs,
	input [29:0] pc,
	input [25:0] jta,
	input [1:0] PCSrc,BrType,
	output [29:0] incPC,nxtPC
);

/*
		input [N-1:0]a,b,
		input c_in,
		output  [N-1:0]sum,
		output  c_out
*/

wire [29:0] adder_in_a;
wire BrTrue;

assign BrTrue = (~BrType[1] & ~BrType[0]) ? 1'b0 :								// No branching
					 (~BrType[1] & BrType[0]) ? ((rs == rt) ? 1'b1:1'b0):		// beq
					 (BrType[1] & ~BrType[0]) ? ((rs != rt) ? 1'b1:1'b0):		// bne
					 ((rs < 0) ? 1'b1 : 1'b0);											// bltz
					 
					 
assign adder_in_a = (BrTrue) ? ({{14{jta[15]}},jta[15:0]}) : {30{1'b0}}; // Signed Extension of LSB 16-bits of JTA (Jump Target Address)

adder_nextAddr add0(.in0(adder_in_a), .in1(pc), .carry(1'b1), .sum(incPC));

// NextPC

nextPCMUX nextPcGen(.sel(PCSrc), .in0(incPC), .in1({pc[29:26],jta}), .in2(rs[31:2]), .in3({30{1'bx}}), .out(nxtPC));

endmodule




module nextPCMUX(
	input [29:0] in0,in1,in2,in3,
	input [1:0] sel,
	output [29:0] out
);


assign out = (sel == 0) ? in0 :
             (sel == 1) ? in1 :
             (sel == 2) ? in2 :
                          in3;

endmodule

module adder_nextAddr(
	input [29:0] in0, in1,
	input carry,
	output [29:0] sum
);
lookAheadCarryAdder #(30) adder0(.a(in0), .b(in1), .c_in(carry), .sum(sum));

endmodule
