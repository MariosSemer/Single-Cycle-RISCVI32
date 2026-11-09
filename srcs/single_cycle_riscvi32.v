/* verilator tracing_on */
module single_cycle_riscvi32(
    input clk,
    input rst_n
);

    // ------------------------------------------------------------------------
    // Internal Wires and Busses
    // ------------------------------------------------------------------------
    // MUX Signals
    wire [31:0] mux1_out, mux2_out, mux3_out, mux4_out, mux5_out, mux6_out;

    //Other Signals
    wire branch_cond;
    wire [31:0] pc_sum;

    // PC
    wire [31:0] pc, pc_next, pc_plus_4;

    // Instruction
    wire [31:0] inst;

    // Control Signals
    wire RegWrite, MemWrite, MemRead, AluSrc1, AluSrc2, Branch, Jump, PcSrc, MemToReg, is_ebreak, is_ecall, halt, lui, jb;
    wire [2:0] ALUOp;

    // ALU Control Signals
    wire [3:0] ALUControl;

    // Register File Signals
    wire [31:0] rs1, rs2, wd;

    // Immediate Generator Signals
    wire [31:0] ImmExt;

    // ALU Signals
    wire [31:0] ALUResult;
    wire zero;

    // Data Memory Signals
    wire [31:0] rd;

    // ------------------------------------------------------------------------
    // Program Counter
    // ------------------------------------------------------------------------
    program_counter pc_reg (
        .rst_n(rst_n),
        .clk(clk),
        .halt(halt),
        .pc_next(pc_next),
        .pc(pc)
    );

    // ------------------------------------------------------------------------
    // Instruction Memory
    // ------------------------------------------------------------------------
    instruction_memory iinst_mem (
        .pc(pc),
        .inst(inst)
    );

    // ------------------------------------------------------------------------
    // Control Unit
    // ------------------------------------------------------------------------
    control_unit ctrl (
        .inst(inst),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .AluSrc1(AluSrc1),
        .AluSrc2(AluSrc2),
        .Branch(Branch),
        .Jump(Jump),
        .PcSrc(PcSrc),
        .MemToReg(MemToReg),
        .is_ebreak(is_ebreak),
        .is_ecall(is_ecall),
        .halt(halt),
        .lui(lui),
        .ALUOp(ALUOp)
    );

    // ------------------------------------------------------------------------
    // Control Unit
    // ------------------------------------------------------------------------
    alu_control_unit alu_ctrl (
        .ALUOp(ALUOp),
        .funct3(inst[14:12]),
        .funct7b5(inst[30]),
        .opb5(inst[5]),
        .ALUControl(ALUControl)
    );

    // ------------------------------------------------------------------------
    // Register File
    // ------------------------------------------------------------------------

    lui_mux mux4 (
        .ImmExt(ImmExt),
        .memtoreg_mux_out(mux3_out),
        .lui(lui),
        .mux_out(mux4_out)
    );

    assign wd = (Jump) ? pc_plus_4 : mux4_out;

    register_file rf (
        .clk(clk),
        .rst_n(rst_n),
        .RegWrite(RegWrite),
        .addr1(inst[19:15]),
        .addr2(inst[24:20]),
        .waddr(inst[11:7]),
        .wd(wd),
        .rs1(rs1),
        .rs2(rs2)
    );

    immediate_generator imm_gen (
        .instr(inst),
        .ImmExt(ImmExt)
    );

    // ------------------------------------------------------------------------
    // ALU
    // ------------------------------------------------------------------------

    alusrc2_mux mux1 (
        .pc(pc),
        .rs1(rs1),
        .AluSrc2(AluSrc2),
        .mux_out(mux1_out)
    );

    alusrc1_mux mux2 (
        .ImmExt(ImmExt),
        .rs2(rs2),
        .AluSrc1(AluSrc1),
        .mux_out(mux2_out)
    );

    alu core_alu (
        .a(mux1_out),
        .b(mux2_out),
        .ALUControl(ALUControl),
        .result(ALUResult),
        .zero(zero)
    );

    // ------------------------------------------------------------------------
    // Offset Calculatios
    // ------------------------------------------------------------------------
    assign branch_cond = (inst[14] ? ALUResult[0] : zero) ^ inst[12];
    assign jb = (Branch & branch_cond) | Jump;

    jb_mux mux5 (
        .ImmExt(ImmExt),
        .jb(jb),
        .mux_out(mux5_out)
    );

    pcsrc_mux mux6 (
        .pc(pc),
        .rs1(rs1),
        .PcSrc(PcSrc),
        .mux_out(mux6_out)
    );

    assign pc_sum = mux5_out + mux6_out;
    assign pc_next = {pc_sum[31:1], 1'b0};
    assign pc_plus_4 = pc + 32'd4;

    // ------------------------------------------------------------------------
    // Data Memory
    // ------------------------------------------------------------------------
    data_memory data_mem (
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .addr(ALUResult),
        .wd(rs2),
        .rd(rd)
    );

    memtoreg_mux mux3 (
        .result(ALUResult),
        .rd(rd),
        .MemToReg(MemToReg),
        .mux_out(mux3_out)
    );

endmodule
