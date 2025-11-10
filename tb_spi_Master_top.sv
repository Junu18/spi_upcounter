`timescale 1ns / 1ps

module tb_spi_Master_top ();

    logic clk;
    logic reset;
    logic i_runstop;
    logic i_clear;
    logic sclk;
    logic mosi;
    logic miso;
    logic ss;

    master_top_fast dut (.*);
    always #5 clk = ~clk;

    initial begin
        #0 clk = 0;
        reset = 1;
        #10 reset = 0;
        #350 $finish;
    end
endmodule
