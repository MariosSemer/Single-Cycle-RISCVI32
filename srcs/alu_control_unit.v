// ============================================================================
// Module: alu_control_unit
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   Second-level decoder. Combines the coarse ALUOp from control_unit with
//   funct3 / funct7 to produce the final ALU operation select.
//
// [INPUTS]
//   - ALUOp[2:0]    : from control_unit
//                       000 = force ADD  (loads, stores, lui, auipc, jal, jalr)
//                       001 = force SUB  (branch compare)
//                       010 = decode funct3/funct7 (R-type & I-type ALU)
//   - funct3[2:0]   : Instr[14:12]
//   - funct7b5      : Instr[30]
//   - opb5          : Instr[5]  (1 = R-type, 0 = I-type ALU)
//
// [OUTPUT]
//   - ALUControl[3:0]
//       4'b0000 = ADD     4'b0101 = SLT
//       4'b0001 = SUB     4'b0110 = SLTU
//       4'b0010 = AND     4'b0111 = SLL
//       4'b0011 = OR      4'b1000 = SRL
//       4'b0100 = XOR     4'b1001 = SRA
//
// Notes:
//   - funct7b5 only means "SUB" for R-type (opb5 = 1). For addi, Instr[30] is
//     part of the immediate, so it must be ignored (otherwise addi with a
//     negative immediate would be decoded as SUB).
//   - For shifts (funct3 = 001 / 101), Instr[30] selects SRL vs SRA for both
//     R-type and I-type (srli/srai). slli has funct7b5 = 0 by definition.
// ============================================================================

module alu_control_unit(
    input  wire [2:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire       funct7b5,
    input  wire       opb5,
    output reg  [3:0] ALUControl
);

    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLTU = 4'b0110;
    localparam ALU_SLL  = 4'b0111;
    localparam ALU_SRL  = 4'b1000;
    localparam ALU_SRA  = 4'b1001;

    always @(*) begin
        ALUControl = ALU_ADD;  // default, avoids latches

        case (ALUOp)
            3'b000: ALUControl = ALU_ADD;
            
            3'b001: begin
                case (funct3)
                    3'b000: ALUControl = ALU_SUB;  // beq
                    3'b001: ALUControl = ALU_SUB;  // bne
                    3'b100: ALUControl = ALU_SLT;  // blt
                    3'b101: ALUControl = ALU_SLT;  // bge
                    3'b110: ALUControl = ALU_SLTU; // bltu
                    3'b111: ALUControl = ALU_SLTU; // bgeu
                    default: ALUControl = ALU_SUB;
                endcase
            end

            3'b010: begin
                case (funct3)
                    3'b000: ALUControl = (opb5 & funct7b5) ? ALU_SUB : ALU_ADD;
                    3'b001: ALUControl = ALU_SLL;
                    3'b010: ALUControl = ALU_SLT;
                    3'b011: ALUControl = ALU_SLTU;
                    3'b100: ALUControl = ALU_XOR;
                    3'b101: ALUControl = funct7b5 ? ALU_SRA : ALU_SRL;
                    3'b110: ALUControl = ALU_OR;
                    3'b111: ALUControl = ALU_AND;
                    default: ALUControl = ALU_ADD;
                endcase
            end

            default: ALUControl = ALU_ADD;
        endcase
    end

endmodule
