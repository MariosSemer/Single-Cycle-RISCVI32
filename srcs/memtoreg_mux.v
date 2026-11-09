// ============================================================================
// Module: memtoreg_mux
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit 2-to-1 multiplexer
//
// Selection Logic:
//   - MemToReg = 1'b0 : result.
//   - MemToReg = 1'b1 : rd.
//
// Ports:
//   - result   : 32-bit
//   - rd       : 32-bit
//   - MemToReg : Single-bit control select
//   - mux_out  : 32-bit
// ============================================================================

module memtoreg_mux (
    input  wire [31:0] result,
    input  wire [31:0] rd,
    input  wire        MemToReg,
    output wire [31:0] mux_out
);

    assign mux_out = (MemToReg) ? rd : result;

endmodule
