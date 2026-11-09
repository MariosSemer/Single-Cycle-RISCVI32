// ============================================================================
// Module: data_memory
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   Synchronous write, asynchronous (or combinational) read Data Memory.
//
// Interface Ports:
//   - clk      : System clock input
//   - MemWrite : Write enable signal driven by control_unit (asserted for S-type)
//   - addr     : 32-bit memory address calculated by the ALU (rs1 + offset)
//   - wr_data  : 32-bit data to write into RAM, sourced from register rs2 (read_data_2)
//   - rd_data  : 32-bit data read out from RAM, routed to the writeback mux (ResultSrc)
// ============================================================================

module data_memory (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [31:0] addr,
    input  wire [31:0] wd,
    output wire [31:0] rd
);

    // 1024 words (4 KB of 32-bit data memory)
    reg [31:0] mem [1023:0];

    always @(posedge clk) begin
        if (MemWrite) begin
            mem[addr[11:2]] <= wd;
        end
    end

    assign rd = (MemRead) ? mem[addr[11:2]] : 32'd0;

endmodule
