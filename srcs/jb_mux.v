// ============================================================================
// Module: jb_mux
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit 2-to-1 multiplexer
//
// Selection Logic:
//   - jb = 1'b0 : ImmExt.
//   - jb = 1'b1 : 32'd4.
//
// Ports:
//   - ImmExt  : 32-bit
//   - jb      : Single-bit control select
//   - mux_out : 32-bit
// ============================================================================

module jb_mux (
    input  wire [31:0] ImmExt,
    input  wire        jb,
    output wire [31:0] mux_out
);

    assign mux_out = (jb) ? ImmExt : 32'd4;

endmodule
