// ============================================================================
// Module: alu
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit combinational ALU. Operation is selected by ALUControl, produced by
//   alu_control_unit.
//
// [INPUTS]
//   - a, b[31:0]      : operands (a = rs1 or pc, b = rs2 or ImmExt)
//   - ALUControl[3:0] : 4'b0000 = ADD    4'b0101 = SLT
//                       4'b0001 = SUB    4'b0110 = SLTU
//                       4'b0010 = AND    4'b0111 = SLL
//                       4'b0011 = OR     4'b1000 = SRL
//                       4'b0100 = XOR    4'b1001 = SRA
//
// [OUTPUTS]
//   - result[31:0]    : ALU result
//   - zero            : 1 when result == 0
// ============================================================================

module alu(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] result,
    output wire        zero
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

    wire [4:0] shamt = b[4:0];

    always @(*) begin
        case (ALUControl)
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_AND:  result = a & b;
            ALU_OR:   result = a | b;
            ALU_XOR:  result = a ^ b;
            ALU_SLT:  result = {31'b0, ($signed(a) < $signed(b))};
            ALU_SLTU: result = {31'b0, (a < b)};
            ALU_SLL:  result = a << shamt;
            ALU_SRL:  result = a >> shamt;
            ALU_SRA:  result = $signed(a) >>> shamt;
            default:  result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
