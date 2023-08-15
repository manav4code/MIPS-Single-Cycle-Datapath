module top_tb;

parameter N = 32;

// Inputs
reg clk, prog, loadPC;
reg [6:0] blockAddr;
reg [N-1:0] Iword;
reg [29:0] initPC;

// Outputs
wire [N-1:0] out;
wire [1:0] flag;

// DUT instantiation
singleCycleDataPath #(N) DUT(
    .clk(clk),
    .prog(prog),
    .blockAddr(blockAddr),
    .Iword(Iword),
    .loadPC(loadPC),
    .initPC(initPC),
    .out(out),
    .flag(flag)
);

// Loop iterator
integer i;


//------------------------TESTBENCH-----------------------------//
initial clk = 0;

always #100 clk = ~clk;

reg [31:0] inst_array [5:0]; // Declare an array of 5 32-bit values
  
  initial begin
    // Initialize the array with the provided values
    inst_array[0] = 32'b00100000000000010000000000000010;
    inst_array[1] = 32'b00100000000000100000000000000101;
    inst_array[2] = 32'b00000000001000100001100000100000;
    inst_array[3] = 32'b10101100001000110000000000000000;
    inst_array[4] = 32'b10001100001001000000000000000000;

  end


// Loading Instructions

initial begin
    prog = 1'b1;        // Program Mode -> ON
    initPC = 1'b0;
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
        blockAddr = i;
        Iword = inst_array[i];
        #10;
        $display("Loaded Instruction -> %b @ %b", DUT.ICache.mem[i], i);
    end 

    $display("---------------------------------------------------");

    prog = 1'b0;        // Program Mode -> OFF
    initPC = 0;      
    loadPC = 1'b1;      // EXECUTION Mode -> ON
    i = 0;

    forever begin
        if(i > 5)begin
            $display("Exit Loop");
            $finish(0);
        end

        @(posedge clk);
        #20;

        $display("PC: %d, PCin: %d", DUT.PC, DUT.PCin);
        $display("Instruction: %b", DUT.instruction);
        // $display("Control Signal: %b", DUT.controlSig);
        $display("Control Signal (ALUSrc): %b", DUT.controlSig[11]);
        $display("rs: %b, rt: %b, rd: %b", DUT.rs, DUT.rt, DUT.rd);
        $display("Immediate: %b", DUT.immediate);
        $display("regRsOut: %b, regRtOut: %b", DUT.regRsOut, DUT.regRtOut);
        $display("ALU Input 2: %b", DUT.ALU_b);
        $display("ALU Output: %b", DUT.ALUout);
        $display("WriteBack: %b", DUT.writeBack);
        $display("---------------------------------------------------");
        $display("REGFILE: r1: %b",DUT.registerFile.REGFILE.reg_r1);
        $display("REGFILE: r2: %b",DUT.registerFile.REGFILE.reg_r2);
        $display("REGFILE: r3: %b",DUT.registerFile.REGFILE.reg_r3);
        $display("REGFILE: r4: %b",DUT.registerFile.REGFILE.reg_r4);
        $display("---------------------------------------------------");
        $display("DATA CACHE: @ 2: %b", DUT.DATA.DATACACHE.mem[2]);
        $display("");
        
        loadPC = 1'b0;
       

        i = i + 1;
    end
end
endmodule