`timescale 1ns / 1ps

module SPI_TOP(
    input logic clk,
    input logic reset,


    );
endmodule




module button_debounce (
    input  logic clk,
    input  logic reset,
    input  logic i_btn,
    output logic o_btn
);

    logic [7:0] q_reg, q_next;
    logic edge_reg;
    logic debounce;

    // clock divider
    logic [$clog2(1000)-1:0] counter_reg;
    logic  clk_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            clk_reg <= 0;
        end else begin
            if (counter_reg == 999) begin
                counter_reg <= 0;
                clk_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                clk_reg <= 1'b0;
            end
        end
    end



    // debounce
    always @(posedge clk_reg, posedge reset) begin
        if (reset) begin
            q_reg <= 8'b0;
        end else begin
            q_reg <= q_next;
        end
    end

        // push upper 3 bit to next 3 register => serial input parallel output shift register
        always @(*) begin
            q_next = {i_btn,q_reg[7:1]};
        end
        // 4 input AND
        assign debounce = &q_reg;
        
        // Q5 out 
        always @(posedge clk, posedge reset) begin
            if (reset) begin
                edge_reg <= 1'b0;
            end else begin
                edge_reg <= debounce;
            end
        end

        // edge output
        assign o_btn = ~edge_reg & debounce;

    endmodule

