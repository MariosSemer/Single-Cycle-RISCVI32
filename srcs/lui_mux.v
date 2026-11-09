// ============================================================================
// Module: lui_mux
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit 2-to-1 multiplexer
//
// Selection Logic:
//   - lui = 1'b0 : ImmExt.
//   - lui = 1'b1 : memtoreg_mux_out.
//
// Ports:
//   - ImmExt           : 32-bit
//   - memtoreg_mux_out : 32-bit
//   - lui              : Single-bit control select
//   - mux_out          : 32-bit
// ============================================================================

module lui_mux (
    input  wire [31:0] ImmExt,
    input  wire [31:0] memtoreg_mux_out,
    input  wire        lui,
    output wire [31:0] mux_out
);

    assign mux_out = (lui) ? ImmExt : memtoreg_mux_out;

endmodule
