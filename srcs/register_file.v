// ============================================================================
// Module: reg_file
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   Synchronous write, asynchronous read 32x32-bit General Purpose Register
//   File (GPR) compliant with the RISC-V RV32I base integer specification.
//
// Interface Ports:
//   - clk      : System clock input
//   - rst_n    : Active-low asynchronous reset
//   - RegWrite : Write enable control signal from control_unit
//   - addr1    : 5-bit read address 1 (Instruction rs1 field: Instr[19:15])
//   - addr2    : 5-bit read address 2 (Instruction rs2 field: Instr[24:20])
//   - waddr    : 5-bit write address (Instruction rd field: Instr[11:7])
//   - wd       : 32-bit writeback data input
//   - rs1      : 32-bit asynchronous read data 1 (Operand A to datapath)
//   - rs2      : 32-bit asynchronous read data 2 (Operand B / Store data)
// ============================================================================

module register_file (
    input  wire        clk,
    input  wire        rst_n,      // Active-low asynchronous reset
    input  wire        RegWrite,   // Write enable
    input  wire [4:0]  addr1,      // Read address 1 (rs1)
    input  wire [4:0]  addr2,      // Read address 2 (rs2)
    input  wire [4:0]  waddr,      // Write address (rd)
    input  wire [31:0] wd,         // Write data
    output wire [31:0] rs1,        // Read data 1
    output wire [31:0] rs2         // Read data 2
);

    reg [31:0] registers [31:0];
    integer i;

    assign rs1 = (addr1 == 5'd0) ? 32'd0 : registers[addr1];
    assign rs2 = (addr2 == 5'd0) ? 32'd0 : registers[addr2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (RegWrite && (waddr != 5'd0)) begin
            registers[waddr] <= wd;
        end
    end

endmodule
