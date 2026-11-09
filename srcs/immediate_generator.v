// ============================================================================
// Module: immediate_generator
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   Autonomous Immediate Generator for the RV32I base integer instruction set.
//
// Formats Decoded & Reassembled:
//   - I-type : Sign-extended 12-bit immediate (instr[31:20])
//              Used by: ALU immediates (addi, slti, etc.), loads (lw, lh, etc.), jalr
//   - S-type : Sign-extended split 12-bit store offset ({instr[31:25], instr[11:7]})
//              Used by: stores (sw, sh, sb)
//   - B-type : Sign-extended 13-bit branch displacement ({instr[31], instr[7],
//              instr[30:25], instr[11:8], 1'b0}). Note: LSB is hardwired to 0.
//              Used by: conditional branches (beq, bne, blt, bge, bltu, bgeu)
//   - U-type : 20-bit upper immediate placed at bits [31:12], zero-padded at [11:0]
//              Used by: lui, auipc
//   - J-type : Sign-extended 21-bit jump displacement ({instr[31], instr[19:12],
//              instr[20], instr[30:21], 1'b0}). Note: LSB is hardwired to 0.
//              Used by: jal
//
// Ports:
//   - instr  : 32-bit raw instruction word from instruction_memory
//   - ImmExt : 32-bit assembled, properly sign-extended immediate value
// ============================================================================

module immediate_generator (
    input  wire [31:0] instr,
    output reg  [31:0] ImmExt
);

    wire [6:0] op = instr[6:0];

    always @(*) begin
        case (op)
            // jalr
            // lb, lh, lw, lbu, lhu
            // addi, slli, slti, sltiu, xori, srli, srai, ori, andi
            7'b0010011,
            7'b0000011,
            7'b1100111: begin
                ImmExt = {{20{instr[31]}}, instr[31:20]};
            end

            // sb, sh, sw
            7'b0100011: begin
                ImmExt = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // beq, bne, blt, bge, bltu, bgeu
            7'b1100011: begin
                ImmExt = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            // lui, auipc
            7'b0110111,
            7'b0010111: begin
                ImmExt = {instr[31:12], 12'h000};
            end

            // jal
            7'b1101111: begin
                ImmExt = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            default: begin
                ImmExt = 32'h0000_0000;
            end
        endcase
    end

endmodule
