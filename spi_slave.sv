`timescale 1ns / 1ps
module slave (
    input logic clk,
    input logic reset,
    input logic [13:0] FDR,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);


    fnd_controller U_FND_CONTROLLER (
        .*,
        .counter(FDR)
    );

endmodule


//
module slave_controller (
    // from slave_module
    input logic [7:0] rx_data,
    input logic done,
    // to fndcontroller
    output logic [13:0] data
    
);

endmodule


module spi_slave (
    // from master
    input logic sclk,
    input logic mosi,
    output logic miso,
    input logic ss,
    // to slave_controller
    output logic [7:0] rx_data,
    output logic done
);

    typedef enum {
        IDLE,
        CP0,
        CP1
    } state_t;

    state_t state, state_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [5:0] sclk_counter_reg, sclk_counter_next;
    logic [2:0] bit_counter_reg, bit_counter_next;

    assign mosi = 
    assign rx_data = rx_data_reg;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            runstop_reg <= 1'b0;
            clear_reg   <= 1'b0;

        end else begin
            state       <= state_next;
            runstop_reg <= runstop_next;
            clear_reg   <= clear_next;

        end
    end

    always_comb begin
        state_next = state;
        rx_data_next = rx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next = bit_counter_reg;
        ss = 1'b0;

        case (state)
            IDLE: begin
                if (ss) begin
                    state_next   = CP0;
                    rx_data_next = rx_data;
                end

            end

            CP0: begin

            end

            CP1: begin
            end

        endcase
    end


endmodule


module edge_detector (
    input  logic clk,
    input  logic reset,
    input  logic i_level,  // Debounced level signal
    output logic o_pulse   // 1-clock pulse signal
);
    logic level_reg;

    always @(posedge clk) begin
        if (reset) level_reg <= 1'b0;
        else level_reg <= i_level;
    end

    // 이전 상태는 0이었고, 현재 상태는 1인 순간을 감지
    assign o_pulse = ~level_reg && i_level;

endmodule



module fnd_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic [13:0] counter,
    output logic [ 3:0] fnd_com,
    output logic [ 7:0] fnd_data
);

    logic tick_1khz;
    logic [1:0] w_sel;
    logic [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    logic [3:0] w_bcd;

    clk_div U_CLK_DIV (
        .clk(clk),
        .reset(reset),
        .tick_1khz(tick_1khz)
    );

    counter_4 U_COUNTER_4 (
        .clk(clk),
        .i_tick(tick_1khz),
        .reset(reset),
        .sel(w_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .sel(w_sel),
        .fnd_com(fnd_com)
    );

    disit_spliter U_DISIT_SPLITER (
        .counter(counter),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4x1 U_MUX_4x1 (
        .sel(w_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .bcd(w_bcd)
    );

    bcd_decoder U_BCD_DECODER (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

endmodule

module clk_div (
    input  logic clk,
    input  logic reset,
    output logic tick_1khz
);

    parameter F_COUNT = 100_000_000 / 1_000;
    logic [$clog2(F_COUNT)-1 : 0] count_reg;
    logic tick_reg;
    assign tick_1khz = tick_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            if (count_reg == F_COUNT - 1) begin
                count_reg <= 0;
                tick_reg  <= 1;
            end else begin
                count_reg <= count_reg + 1;
                tick_reg  <= 0;
            end
        end
    end
endmodule

module counter_4 (
    input  logic       clk,
    input  logic       i_tick,
    input  logic       reset,
    output logic [1:0] sel
);

    logic [1:0] counter;
    assign sel = counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (i_tick) begin
                counter <= counter + 1;
            end
        end
    end

endmodule

module decoder_2x4 (
    input  logic [1:0] sel,
    output logic [3:0] fnd_com
);

    always_comb begin
        case (sel)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule

module disit_spliter (
    input  logic [13:0] counter,
    output logic [ 3:0] digit_1,
    output logic [ 3:0] digit_10,
    output logic [ 3:0] digit_100,
    output logic [ 3:0] digit_1000
);

    assign digit_1    = counter % 10;
    assign digit_10   = (counter / 10) % 10;
    assign digit_100  = (counter / 100) % 10;
    assign digit_1000 = (counter / 1000) % 10;

endmodule

module mux_4x1 (
    input  logic [1:0] sel,
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    output logic [3:0] bcd
);

    always_comb begin
        case (sel)
            2'b00:   bcd = digit_1;
            2'b01:   bcd = digit_10;
            2'b10:   bcd = digit_100;
            2'b11:   bcd = digit_1000;
            default: bcd = digit_1;
        endcase
    end

endmodule

module bcd_decoder (
    input  logic [3:0] bcd,
    output logic [7:0] fnd_data
);

    always_comb begin
        case (bcd)
            4'h0: fnd_data = 8'hc0;  // 0
            4'h1: fnd_data = 8'hF9;
            4'h2: fnd_data = 8'hA4;
            4'h3: fnd_data = 8'hB0;
            4'h4: fnd_data = 8'h99;
            4'h5: fnd_data = 8'h92;
            4'h6: fnd_data = 8'h82;
            4'h7: fnd_data = 8'hF8;
            4'h8: fnd_data = 8'h80;
            4'h9: fnd_data = 8'h90;  // 9
            4'ha: fnd_data = 8'h88;
            4'hb: fnd_data = 8'h83;
            4'hc: fnd_data = 8'hc6;
            4'hd: fnd_data = 8'ha1;
            4'he: fnd_data = 8'h7f;  // dot display
            4'hf: fnd_data = 8'hff;  // all off
            default: fnd_data = 8'hff;
        endcase
    end

endmodule


