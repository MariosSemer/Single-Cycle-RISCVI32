// ============================================================================
// Module: instruction_memory
// Project: RV32I Single-Cycle Processor
// ----------------------------------------------------------------------------
// Description:
//   Read-only memory (ROM) module that stores the assembled machine code of the
//   program.
//
// Interface Ports:
//   - pc      : 32-bit instruction byte address supplied by the Program Counter.
//   - instr   : 32-bit machine instruction word output.
// ============================================================================

module instruction_memory(
   input [31:0] pc,
   output [31:0] inst);

   reg [31:0] mem [1023:0];

   /*initial begin
        $readmemh("instr.hex", mem);
        if (mem[0] === 32'h00000000 || mem[0] === 32'hxxxxxxxx) begin
            $display("[ERROR] instructions.hex FAILED to load or is empty! mem[0] = 0x%08h", mem[0]);
        end else begin
            $display("[INFO] instructions.hex loaded successfully! mem[0] = 0x%08h", mem[0]);
        end
    end*/

   assign inst = mem[pc[11:2]];

endmodule
