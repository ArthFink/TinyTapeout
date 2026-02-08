module tt_um_arthfink_ddmtd (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

    // Simple “alive” behavior for now:
    // drive outputs only when enabled
    assign uo_out  = ena ? ui_in : 8'h00;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

endmodule
