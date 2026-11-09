// ============================================================================
// Module: branch_unit
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   Decides whether the next PC is the sequential PC+4 or a branch / jump
//   target. Compares rs1 and rs2 directly, so the main ALU is not involved
//   in branch decisions.
//
// [INPUTS]
//   - rs1, rs2[31:0] : register file read data
//   - funct3[2:0]    : Instr[14:12] (selects the comparison)
//   - Branch         : from control_unit (instruction is a conditional branch)
//   - Jump           : from control_unit (jal / jalr)
//
// [OUTPUTS]
//   - branch_cond    : result of the funct3 comparison (only meaningful when
//                      Branch = 1)
//   - jb             : 1 = next PC is the jump/branch target (pc/rs1 + ImmExt),
//                      0 = next PC is PC + 4


module branch_unit(
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,
    input  wire [2:0]  funct3,
    input  wire        Branch,
    input  wire        Jump,
    output reg         branch_cond,
    output wire        jb
);

    wire eq  = (rs1 == rs2);
    wire lt  = ($signed(rs1) < $signed(rs2));
    wire ltu = (rs1 < rs2);

    always @(*) begin
        case (funct3)
            3'b000:  branch_cond = eq;     // beq
            3'b001:  branch_cond = ~eq;    // bne
            3'b100:  branch_cond = lt;     // blt
            3'b101:  branch_cond = ~lt;    // bge
            3'b110:  branch_cond = ltu;    // bltu
            3'b111:  branch_cond = ~ltu;   // bgeu
            default: branch_cond = 1'b0;
        endcase
    end

    assign jb = (Branch & branch_cond) | Jump;

endmodule