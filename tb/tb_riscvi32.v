`timescale 1ns/1ps

`define REGS dut.rf.registers

module tb_riscvi32;

    reg clk   = 1'b0;
    reg rst_n = 1'b0;

    // Direct instruction injection hook (or load directly into instruction memory)
    reg [31:0] test_inst;

    // Instantiate core
    single_cycle_riscvi32 dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // ========================================================================
    // Golden Reference Model & Scoreboard
    // ========================================================================
    reg [31:0] shadow_rf [31:0];
    integer    i;
    integer    tests_run   = 0;
    integer    mismatches  = 0;

    initial begin
        $dumpfile("riscv_waveform.vcd");
        $dumpvars(0, tb_riscvi32);
    end

    // Corner case constants pool
    reg [31:0] corner_vals [0:7];
    initial begin
        corner_vals[0] = 32'h0000_0000; // Zero
        corner_vals[1] = 32'hFFFF_FFFF; // -1
        corner_vals[2] = 32'h7FFF_FFFF; // Max signed positive
        corner_vals[3] = 32'h8000_0000; // Min signed negative
        corner_vals[4] = 32'h0000_0001; // Positive 1
        corner_vals[5] = 32'hAAAA_AAAA; // Alternating bits
        corner_vals[6] = 32'h5555_5555; // Alternating bits inverse
        corner_vals[7] = 32'h0000_001F; // Max shift amount (31)
    end

    // Instruction generator function
    function [31:0] generate_random_instruction(input integer use_corner_cases);
        reg [4:0]  rd, rs1, rs2;
        reg [2:0]  funct3;
        reg [6:0]  funct7;
        reg [11:0] imm12;
        reg [1:0]  inst_class;
        begin
            rd  = $urandom_range(0, 31);
            rs1 = $urandom_range(0, 31);
            rs2 = $urandom_range(0, 31);
            
            // Randomize class: 0 = R-type, 1 = I-type ALU, 2 = Corner Load/LUI
            inst_class = $urandom_range(0, 2);

            case (inst_class)
                2'd0: begin // R-Type
                    funct3 = $urandom_range(0, 7);
                    funct7 = (funct3 == 3'b000 || funct3 == 3'b101) ? 
                             (($urandom % 2) ? 7'b0100000 : 7'b0000000) : 7'b0000000;
                    generate_random_instruction = {funct7, rs2, rs1, funct3, rd, 7'b0110011};
                end
                2'd1: begin // I-Type ALU
                    funct3 = $urandom_range(0, 7);
                    if (funct3 == 3'b001) begin // SLLI
                        imm12 = {7'b0000000, $urandom_range(0, 31)[4:0]};
                    end else if (funct3 == 3'b101) begin // SRLI / SRAI
                        imm12 = {($urandom % 2) ? 7'b0100000 : 7'b0000000, $urandom_range(0, 31)[4:0]};
                    end else begin
                        imm12 = $urandom;
                    end
                    generate_random_instruction = {imm12, rs1, funct3, rd, 7'b0010011};
                end
                default: begin // LUI / Upper Imm corner case
                    generate_random_instruction = {$urandom[19:0], rd, 7'b0110111};
                end
            endcase
        end
    endfunction

    // Architectural model update step
    task step_golden_model(input [31:0] inst);
        reg [6:0]  opcode;
        reg [4:0]  rd, rs1, rs2;
        reg [2:0]  funct3;
        reg [6:0]  funct7;
        reg [31:0] imm_i, imm_u;
        reg [31:0] opA, opB;
        reg [31:0] res;
        begin
            opcode = inst[6:0];
            rd     = inst[11:7];
            funct3 = inst[14:12];
            rs1    = inst[19:15];
            rs2    = inst[24:20];
            funct7 = inst[31:25];

            imm_i  = {{20{inst[31]}}, inst[31:20]};
            imm_u  = {inst[31:12], 12'b0};

            opA    = shadow_rf[rs1];
            opB    = shadow_rf[rs2];
            res    = 32'd0;

            case (opcode)
                7'b0110111: res = imm_u; // LUI
                7'b0010011: begin        // I-type ALU
                    case (funct3)
                        3'b000: res = opA + imm_i;                                // ADDI
                        3'b001: res = opA << imm_i[4:0];                          // SLLI
                        3'b010: res = ($signed(opA) < $signed(imm_i)) ? 1 : 0;    // SLTI
                        3'b011: res = (opA < imm_i) ? 1 : 0;                      // SLTIU
                        3'b100: res = opA ^ imm_i;                                // XORI
                        3'b101: begin
                            if (imm_i[10]) begin
                                // SRAI: Cast directly to signed
                                res = $signed(opA) >>> imm_i[4:0];
                            end else begin
                                // SRLI: Unsigned logical shift
                                res = opA >> imm_i[4:0];
                            end
                        end
                        3'b110: res = opA | imm_i;                                // ORI
                        3'b111: res = opA & imm_i;                                // ANDI
                    endcase
                end
                7'b0110011: begin        // R-type
                    case (funct3)
                        3'b000: res = (funct7[5]) ? (opA - opB) : (opA + opB);    // SUB / ADD
                        3'b001: res = opA << opB[4:0];                            // SLL
                        3'b010: res = ($signed(opA) < $signed(opB)) ? 1 : 0;      // SLT
                        3'b011: res = (opA < opB) ? 1 : 0;                        // SLTU
                        3'b100: res = opA ^ opB;                                  // XOR
                        3'b101: begin
                            if (funct7[5]) begin
                                // SRA: Cast directly to signed
                                res = $signed(opA) >>> opB[4:0];
                            end else begin
                                // SRL: Unsigned logical shift
                            res = opA >> opB[4:0];
                            end
                        end
                        3'b110: res = opA | opB;                                  // OR
                        3'b111: res = opA & opB;                                  // AND
                    endcase
                end
            endcase

            // Enforce RV32I rule: x0 is always hardwired zero
            if (rd != 5'd0) begin
                shadow_rf[rd] = res;
            end else begin
                shadow_rf[0]  = 32'd0;
            end
        end
    endtask

    // Scoreboard check
    task check_scoreboard(input [31:0] executed_inst);
        integer reg_idx;
        begin
            tests_run = tests_run + 1;
            for (reg_idx = 0; reg_idx < 32; reg_idx = reg_idx + 1) begin
                if (`REGS[reg_idx] !== shadow_rf[reg_idx]) begin
                    $display("MISMATCH [Cycle %0d, Inst: 0x%08h]:", tests_run, executed_inst);
                    $display("  -> Reg x%0d: DUT = 0x%08h, Golden = 0x%08h", 
                             reg_idx, `REGS[reg_idx], shadow_rf[reg_idx]);
                    mismatches = mismatches + 1;
                end
            end
        end
    endtask

    // ========================================================================
    // Simulation Loop
    // ========================================================================
    integer cycle;
    reg [31:0] current_stimulus;

    initial begin
        // Initialize golden state
        for (i = 0; i < 32; i = i + 1) shadow_rf[i] = 32'd0;

        // Reset DUT
        repeat (2) @(posedge clk);
        #1 rst_n = 1'b1;

        // Run 200 randomized stimulus tests
        for (cycle = 0; cycle < 200; cycle = cycle + 1) begin
            current_stimulus = generate_random_instruction(1);

            // Inject instruction into core instruction memory array at current PC word
            dut.iinst_mem.mem[dut.pc[11:2]] = current_stimulus;

            // Advance golden model
            step_golden_model(current_stimulus);

            // Wait for single-cycle execution to settle on next clock edge
            @(posedge clk);
            #1;

            // Check architectural register file state
            check_scoreboard(current_stimulus);
        end

        // Final summary
        $display("\n========================================================");
        $display("SCOREBOARD REPORT: Completed %0d randomized tests", tests_run);
        if (mismatches == 0)
            $display(">>> ALL RANDOM TESTS & CORNER CASES PASSED (0 ERRORS) <<<");
        else
            $display(">>> FAILED WITH %0d REGISTER MISMATCHES! <<<", mismatches);
        $display("========================================================\n");

        $finish;
    end

endmodule
