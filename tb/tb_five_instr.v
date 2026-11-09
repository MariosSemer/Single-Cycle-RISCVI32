`timescale 1ns/1ps

// ============================================================================
// Testbench: 5-instruction program (addi, addi, bne, addi, sw)
// ----------------------------------------------------------------------------
//   0x00  00500093   addi x1, x0, 5
//   0x04  00700113   addi x2, x0, 7
//   0x08  00209463   bne  x1, x2, +8     5 != 7 -> TAKEN, jumps to 0x10
//   0x0C  06300193   addi x3, x0, 99     SKIPPED (x3 must stay 0)
//   0x10  00102023   sw   x1, 0(x0)      mem[0] = 5
//
// Expected PC sequence: 00 -> 04 -> 08 -> 10 -> 14 -> 18 ...
// (after 0x10 the memory is empty, so PC just keeps counting up by 4)
//
// Expected final state: x1 = 5, x2 = 7, x3 = 0, mem[0] = 5
//
// ============================================================================

`define IMEM       dut.iinst_mem.mem        // word-indexed instruction array
`define REGS       dut.rf.registers         // register array name in register_file
`define DMEM_WORD0 dut.data_mem.mem[0]      // word at address 0

module tb_five_instr;

    reg clk;
    reg rst_n;
    integer errors;

    single_cycle_riscvi32 dut (
        .clk  (clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_five_instr.fst");
        $dumpvars(0, tb_five_instr);
    end

    // Load the program just after time 0
    initial begin
        #1;
        `IMEM[0] = 32'h00500093;   // addi x1, x0, 5
        `IMEM[1] = 32'h00700113;   // addi x2, x0, 7
        `IMEM[2] = 32'h00209463;   // bne  x1, x2, +8
        `IMEM[3] = 32'h06300193;   // addi x3, x0, 99 (skipped)
        `IMEM[4] = 32'h00102023;   // sw   x1, 0(x0)
    end

    // One line per cycle (sampled just before PC updates)
    always @(posedge clk) begin
        if (rst_n)
            $display("t=%0t pc=%08h inst=%08h Branch=%b alu_res=%08h branch_cond=%b jb=%b pc_next=%08h",
                     $time, dut.pc, dut.inst, dut.Branch, dut.ALUResult,
                     dut.branch_cond, dut.jb, dut.pc_next);
    end

    task check(input [8*12-1:0] name, input [31:0] got, input [31:0] expected);
        begin
            if (got === expected)
                $display("PASS  %0s = %0d", name, got);
            else begin
                $display("FAIL  %0s = %0d (0x%08h), expected %0d (0x%08h)",
                         name, got, got, expected, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n  = 1'b0;
        repeat (2) @(posedge clk);
        #1 rst_n = 1'b1;

        // 4 instructions execute (one is skipped)
        repeat (6) @(posedge clk);
        #1;

        $display("---- Results ----");
        check("x1",     `REGS[1],     32'd5);
        check("x2",     `REGS[2],     32'd7);
        check("x3",     `REGS[3],     32'd0);   // must be skipped by the bne
        check("mem[0]", `DMEM_WORD0,  32'd5);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
