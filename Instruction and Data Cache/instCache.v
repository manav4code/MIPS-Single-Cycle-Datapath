module instCache #(parameter N = 32)(
	input clk, prog,
	input [29:0] pc,
	input [6:0] wAddr,
	input [N-1:0] Iword,
	output reg [N-1:0] instruction
);

wire [6:0] rAddr;
assign rAddr = pc[6:0];
generate
	reg [N-1:0]mem[127:0];

	always@(posedge clk)begin
		mem[wAddr] = Iword;
	end

	always@(pc)begin
		instruction = mem[rAddr];
	end
endgenerate
endmodule
