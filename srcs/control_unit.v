// ============================================================================
// Module: control_unit
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   The Control Unit serves as the primary instruction decoder for the RV32I 
//   core. It samples the 7-bit primary opcode (Instr[6:0]) and orchestrates the
//   entire datapath by asserting control lines.
//
// Signal Descriptions:
//
// [INPUTS]
//   - inst        : 32-bit instruction
//
// [OUTPUTS]
//   - RegWrite    : Write enable to the register file.
//   - MemWrite    : Data memory write enable.
//   - MemRead     : Data memory read enable.
//   - AluSrc2     : ALU operand A source multiplexer select:
//                     0 = read data 1 (rs1)
//                     1 = pc
//   - AluSrc1     : ALU operand B source multiplexer select:
//                     0 = read data 2 (rs2)
//                     1 = Sign-extended immediate (ImmExt)
//   - Branch      : Branch condition enable.
//   - Jump        : Unconditional jump flag (jal, jalr).
//   - PcSrc       : Multiplexer select between pc and rs1.
//   - MemToReg    : Dedicated routing line selecting data memory read data over
//                   ALU computation for destination register writeback.
//   - is_ecall    : Asserted when the instruction is ECALL (opcode 1110011,
//                   funct3 = 000, imm[11:0] = 0x000). Environment call request.
//   - is_ebreak   : Asserted when the instruction is EBREAK (opcode 1110011,
//                   funct3 = 000, imm[11:0] = 0x001). Breakpoint request.
//   - halt        : Asserted for ECALL/EBREAK. Freezes the PC (disables the PC
//                   register update) and signals the testbench that the program
//                   has finished. No register or memory write occurs.
//   - lui         : Upper immediate bypass flag; routes raw shifted ImmExt
//                   directly into writeback logic for LUI instructions.
//   - ALUOp[2:0]  : 3'b000 = Force ADD (address calculation for lw/sw/jalr/auipc)
//                   3'b001 = Force SUB / Compare (branch evaluation)
//                   3'b010 = Decode funct3 / funct7 (R-type & I-type ALU operations)
//
// Supported RV32I Instruction Formats:
//   - R-type      (7'b0110011): add, sub, sll, slt, sltu, xor, srl, sra, or, and
//   - I-type ALU  (7'b0010011): addi, slti, sltiu, xori, ori, andi, slli, srli, srai
//   - I-type Load (7'b0000011): lw, lh, lb, lhu, lbu
//   - S-type      (7'b0100011): sw, sh, sb
//   - B-type      (7'b1100011): beq, bne, blt, bge, bltu, bgeu
//   - U-type      (7'b0110111): lui
//   - U-type      (7'b0010111): auipc
//   - J-type      (7'b1101111): jal
//   - I-type Jump (7'b1100111): jalr
// ============================================================================

module control_unit(
    input [31:0] inst,
    output reg RegWrite,
    output reg MemWrite,
    output reg MemRead,
    output reg AluSrc1,
    output reg AluSrc2,
    output reg Branch,
    output reg Jump,
    output reg PcSrc,
    output reg MemToReg,
    output reg is_ebreak,
    output reg is_ecall,
    output reg halt,
    output reg lui,
    output reg [2:0] ALUOp);

    always @(*) begin
        RegWrite  = 1'b0;
        MemWrite  = 1'b0;
        MemRead   = 1'b0;
        AluSrc1   = 1'b0;
        AluSrc2   = 1'b0;
        Branch    = 1'b0;
        Jump      = 1'b0;
        PcSrc     = 1'b0;
        MemToReg  = 1'b0;
        lui       = 1'b0;
        is_ebreak = 1'b0;
        is_ecall  = 1'b0;
        halt      = 1'b0;
        ALUOp     = 3'b000;

        case (inst[6:0])
            //R-type (op = 7'b0110011)
            7'b0110011: begin
                RegWrite  = 1'b1;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;
                AluSrc1   = 1'b0;
                AluSrc2   = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                lui       = 1'b0;
                ALUOp     = 3'b010;
            end

            //I-type (op = 7'b0010011: addi, slli, slti, sltiu, xori, srli, srai, ori, andi)
            7'b0010011: begin
                RegWrite  = 1'b1;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;
                AluSrc1   = 1'b1;
                AluSrc2   = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                lui       = 1'b0;
                ALUOp     = 3'b010;
            end

            //I-type (op = 7'b0000011: lb, lh, lw, lbu, lhu)
            7'b0000011: begin
                RegWrite  = 1'b1;
                MemWrite  = 1'b0;
                MemRead   = 1'b1;
                MemToReg  = 1'b1;
                AluSrc1   = 1'b1;
                AluSrc2   = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                lui       = 1'b0;
                ALUOp     = 3'b000;
            end

            // S-type (op = 7'b0100011: sw, sh, sb)
            7'b0100011: begin
                RegWrite  = 1'b0;
                MemWrite  = 1'b1;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;
                AluSrc1   = 1'b1;
                AluSrc2   = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                lui       = 1'b0;
                ALUOp     = 3'b000;
            end

            // B-type (op = 7'b1100011: beq, bne, blt, bge, bltu, bgeu)
            7'b1100011: begin
                RegWrite  = 1'b0;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;
                AluSrc1   = 1'b0;
                AluSrc2   = 1'b0;
                Branch    = 1'b1;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                lui       = 1'b0;
                ALUOp     = 3'b001;
            end

            // U-type (op = 7'b0110111: lui)
            7'b0110111: begin
                RegWrite  = 1'b1;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;
                AluSrc1   = 1'b0;
                AluSrc2   = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                lui       = 1'b1;
                ALUOp     = 3'b000;
            end

            // U-type (op = 7'b0010111: auipc)
            7'b0010111: begin
                RegWrite  = 1'b1;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;     
                AluSrc1   = 1'b1;
                AluSrc2   = 1'b1;
                Branch    = 1'b0;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                lui       = 1'b0;
                ALUOp     = 3'b000;
            end

            // J-type(op = 7'b1101111: jal)
            7'b1101111: begin
                RegWrite  = 1'b1;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;     
                AluSrc1   = 1'b0;     
                AluSrc2   = 1'b0;     
                Branch    = 1'b0;
                Jump      = 1'b1;
                PcSrc     = 1'b0;
                lui       = 1'b0;     
                ALUOp     = 3'b000;   
            end

            // I-type (op = 7'b1100111: jalr)
            7'b1100111: begin
                RegWrite  = 1'b1;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                MemToReg  = 1'b0;
                AluSrc1   = 1'b0;
                AluSrc2   = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b1;
                PcSrc     = 1'b1;
                lui       = 1'b0;
                ALUOp     = 3'b000;
            end

            // I-type (op = 7'b0001111: FENCE, FENCE.TSO, PAUSE) --> as a NOP
            7'b0001111: begin
                RegWrite  = 1'b0;
                MemWrite  = 1'b0;
                MemRead   = 1'b0;
                AluSrc1   = 1'b0;
                AluSrc2   = 1'b0;
                Branch    = 1'b0;
                Jump      = 1'b0;
                PcSrc     = 1'b0;
                MemToReg  = 1'b0;
                lui       = 1'b0;
                ALUOp     = 3'b000;
            end

            // I-type (op = 7'b1110011: ECALL, EBREAK) --> as a halt
            7'b1110011: begin
                case (inst[14:12])
                
                3'b000: begin

                    case (inst[31:20])

                        12'b000000000000: begin // ECALL --> as halt signal
                            is_ecall = 1'b1;
                            halt = 1'b1;
                        end
                        12'b000000000001: begin // EBREAK --> as halt signal
                            is_ebreak = 1'b1;
                            halt = 1'b1;
                        end

                        default: ;
                    endcase
                end

                    default: ;
                endcase
            end

            default: ;
        endcase 
    end
endmodule
