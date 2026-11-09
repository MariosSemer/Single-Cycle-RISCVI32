// ============================================================================
// Module: alusrc1_mux
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit 2-to-1 multiplexer
//
// Selection Logic:
//   - AluSrc1 = 1'b0 : Selects rs2 (read_data_2).
//   - AluSrc1 = 1'b1 : Selects ImmExt from imm_gen.
//
// Ports:
//   - rs2     : 32-bit
//   - ImmExt  : 32-bit
//   - AluSrc1 : Single-bit control select
//   - mux_out : 32-bit
// ============================================================================

module alusrc1_mux (
    input  wire [31:0] ImmExt,
    input  wire [31:0] rs2,
    input  wire        AluSrc1,
    output wire [31:0] mux_out
);

    assign mux_out = (AluSrc1) ? ImmExt : rs2;

endmodule
