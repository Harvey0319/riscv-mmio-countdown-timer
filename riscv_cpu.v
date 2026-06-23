`timescale 1ns / 1ps

module riscv_cpu(
    input clk,
    input reset,

    output reg        mem_valid,
    output reg        mem_we,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wdata,
    input      [31:0] mem_rdata
);

    reg [31:0] pc = 32'd0;
    reg [31:0] regs [0:31];

    integer i;

    reg [31:0] instr_mem [0:255];
    integer init_i;

    initial begin
        for (init_i = 0; init_i < 256; init_i = init_i + 1) begin
            instr_mem[init_i] = 32'h00000013; // nop
        end

        `include "program_init.vh"
    end

    wire [31:0] instr = instr_mem[pc[9:2]];


    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];

    wire [31:0] rs1_val = regs[rs1];
    wire [31:0] rs2_val = regs[rs2];

    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_j = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    always @(*) begin
        mem_valid = 1'b0;
        mem_we    = 1'b0;
        mem_addr  = 32'd0;
        mem_wdata = 32'd0;

        if (opcode == 7'b0000011) begin
            mem_valid = 1'b1;
            mem_we    = 1'b0;
            mem_addr  = rs1_val + imm_i;
        end

        if (opcode == 7'b0100011) begin
            mem_valid = 1'b1;
            mem_we    = 1'b1;
            mem_addr  = rs1_val + imm_s;
            mem_wdata = rs2_val;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'd0;

            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
        end else begin
            case (opcode)

                7'b0110111: begin
                    if (rd != 0)
                        regs[rd] <= {instr[31:12], 12'd0};
                    pc <= pc + 4;
                end

                7'b0000011: begin
                    if (rd != 0)
                        regs[rd] <= mem_rdata;
                    pc <= pc + 4;
                end

                7'b0100011: begin
                    pc <= pc + 4;
                end

                7'b0010011: begin
                    if (rd != 0) begin
                        case (funct3)
                            3'b000: regs[rd] <= rs1_val + imm_i;
                            3'b111: regs[rd] <= rs1_val & imm_i;
                            default: regs[rd] <= regs[rd];
                        endcase
                    end
                    pc <= pc + 4;
                end

                7'b1100011: begin
                    case (funct3)
                        3'b000: begin
                            if (rs1_val == rs2_val)
                                pc <= pc + imm_b;
                            else
                                pc <= pc + 4;
                        end

                        3'b001: begin
                            if (rs1_val != rs2_val)
                                pc <= pc + imm_b;
                            else
                                pc <= pc + 4;
                        end

                        default: pc <= pc + 4;
                    endcase
                end

                7'b1101111: begin
                    if (rd != 0)
                        regs[rd] <= pc + 4;
                    pc <= pc + imm_j;
                end

                default: begin
                    pc <= pc + 4;
                end
            endcase

            regs[0] <= 32'd0;
        end
    end

endmodule