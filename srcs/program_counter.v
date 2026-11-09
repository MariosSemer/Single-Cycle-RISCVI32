// ============================================================================
// Module: program_counter
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   32-bit synchronous register holding the byte memory address of the current
//   instruction being fetched and executed.
//
// Interface Ports:
//   - clk     : System clock input
//   - rst_n   : Active-low asynchronous reset
//   - halt    : Halts the PC when ECALL/EBREAK happens
//   - pc_next : 32-bit next PC target address.
//   - pc      : 32-bit current PC value.
// ============================================================================

module program_counter(
   input wire rst_n, 
   input wire clk,
   input wire halt,
   input wire [31:0] pc_next,
   output reg [31:0] pc);

   always@(posedge clk or negedge rst_n) begin
      // Active-Low reset polarity
      if(!rst_n) begin
         pc <= 32'd0;
      end
      else if (!halt) begin
         pc <= pc_next;
      end
   end

endmodule
