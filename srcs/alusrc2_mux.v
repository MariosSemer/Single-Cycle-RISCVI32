// ============================================================================
// Module: alusrc2_mux
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit 2-to-1 multiplexer
//
// Selection Logic:
//   - AluSrc2 = 1'b0 : Selects pc.
//   - AluSrc2 = 1'b1 : Selects rs1 (read data 1).
//
// Ports:
//   - pc     : 32-bit
//   - rs1  : 32-bit
//   - AluSrc2 : Single-bit control select
//   - mux_out : 32-bit
// ============================================================================

module alusrc2_mux (
    input  wire [31:0] pc,
    input  wire [31:0] rs1,
    input  wire        AluSrc2,
    output wire [31:0] mux_out
);

    assign mux_out = (AluSrc2) ? pc : rs1;

endmodule
