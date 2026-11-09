// ============================================================================
// Module: pcsrc_mux
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit 2-to-1 multiplexer
//
// Selection Logic:
//   - PcSrc = 1'b0 : rs1 (read data 1).
//   - PcSrc = 1'b1 : pc.
//
// Ports:
//   - rs1     : 32-bit
//   - pc      : 32-bit
//   - PcSrc   : Single-bit control select
//   - mux_out : 32-bit
// ============================================================================

module pcsrc_mux (
    input  wire [31:0] pc,
    input  wire [31:0] rs1,
    input  wire        PcSrc,
    output wire [31:0] mux_out
);

    assign mux_out = (PcSrc) ? rs1 : pc;

endmodule
