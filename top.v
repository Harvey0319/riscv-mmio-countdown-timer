`timescale 1ns / 1ps

module top(
    input clk,
    input btnC,
    input btnU,
    input  [5:0] sw,
    output [3:0] led,
    output reg [6:0] seg,
    output reg [3:0] an,
    output dp
);

    //  CPU reset 
    reg [15:0] reset_cnt = 16'd0;

    always @(posedge clk) begin
        if (reset_cnt != 16'hFFFF)
            reset_cnt <= reset_cnt + 1'b1;
    end

    wire cpu_reset = (reset_cnt != 16'hFFFF);

    // Button
    reg [19:0] btnc_cnt = 20'd0;
    reg [19:0] btnu_cnt = 20'd0;

    reg btnc_stable = 1'b0;
    reg btnu_stable = 1'b0;

    reg btnc_last = 1'b0;
    reg btnu_last = 1'b0;

    reg btnc_event = 1'b0;
    reg btnu_event = 1'b0;

    wire        mem_valid;
    wire        mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    reg  [31:0] mem_rdata;

    always @(posedge clk) begin
        if (btnC == btnc_stable) begin
            btnc_cnt <= 20'd0;
        end else begin
            btnc_cnt <= btnc_cnt + 1'b1;
            if (btnc_cnt == 20'd999999) begin
                btnc_stable <= btnC;
                btnc_cnt <= 20'd0;
            end
        end

        if (btnU == btnu_stable) begin
            btnu_cnt <= 20'd0;
        end else begin
            btnu_cnt <= btnu_cnt + 1'b1;
            if (btnu_cnt == 20'd999999) begin
                btnu_stable <= btnU;
                btnu_cnt <= 20'd0;
            end
        end

        btnc_last <= btnc_stable;
        btnu_last <= btnu_stable;

        if (btnc_stable && !btnc_last)
            btnc_event <= 1'b1;

        if (btnu_stable && !btnu_last)
            btnu_event <= 1'b1;

        if (mem_valid && mem_we && mem_addr == 32'h4000_001C) begin
            if (mem_wdata[0])
                btnc_event <= 1'b0;

            if (mem_wdata[1])
                btnu_event <= 1'b0;
        end
    end

    reg [26:0] sec_cnt = 27'd0;
    reg timer_flag = 1'b0;

    always @(posedge clk) begin
        if (sec_cnt == 27'd99_999_999) begin
            sec_cnt <= 27'd0;
            timer_flag <= 1'b1;
        end else begin
            sec_cnt <= sec_cnt + 1'b1;
        end

        if (mem_valid && mem_we && mem_addr == 32'h4000_0018) begin
            if (mem_wdata[0])
                timer_flag <= 1'b0;
        end
    end

    reg [3:0] led_reg = 4'b0001;
    reg [6:0] seg7_reg = 7'd0;

    riscv_cpu cpu0(
        .clk(clk),
        .reset(cpu_reset),

        .mem_valid(mem_valid),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );

    always @(posedge clk) begin
        if (mem_valid && mem_we) begin
            case (mem_addr)
                32'h4000_0008: led_reg  <= mem_wdata[3:0]; // LED_REG
                32'h4000_000C: seg7_reg <= mem_wdata[6:0]; // SEG7_REG
                default: begin
                end
            endcase
        end
    end

    always @(*) begin
        case (mem_addr)
            32'h4000_0000: mem_rdata = {26'd0, sw};                    
            32'h4000_0004: mem_rdata = {30'd0, btnu_event, btnc_event}; 
            32'h4000_0008: mem_rdata = {28'd0, led_reg};               
            32'h4000_000C: mem_rdata = {25'd0, seg7_reg};              
            32'h4000_0010: mem_rdata = {31'd0, timer_flag};            
            default:       mem_rdata = 32'd0;
        endcase
    end

    assign led = led_reg;
    assign dp = 1'b1; 

    wire [3:0] ones_digit = seg7_reg % 10;
    wire [3:0] tens_digit = seg7_reg / 10;

    reg [16:0] scan_cnt = 17'd0;

    always @(posedge clk) begin
        scan_cnt <= scan_cnt + 1'b1;
    end

    wire scan_sel = scan_cnt[16];

    reg [3:0] digit;

    always @(*) begin
        if (scan_sel == 1'b0) begin
            digit = ones_digit;
            an = 4'b1110;
        end else begin
            digit = tens_digit;
            an = 4'b1101;
        end

        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
