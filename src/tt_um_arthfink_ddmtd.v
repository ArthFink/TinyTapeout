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

    // Map TT pins to your core's "clock-like" inputs.
    // You must drive these from outside (e.g. testbench / board).
    wire clk_ref = ui_in[0];
    wire clk_fb  = ui_in[1];

    wire        phase_valid;
    wire signed [17:0] phase_err;
    wire        dbg_edge_ref;
    wire        dbg_edge_fb;
    wire signed [23:0] ctrl;

    // The core will be a Verilog module generated from ddmtd_core.vhd
    ddmtd_core u_core (
        .clk_sys      (clk),
        .rst_n        (rst_n),
        .clk_ref      (clk_ref),
        .clk_fb       (clk_fb),
        .phase_valid  (phase_valid),
        .phase_err    (phase_err),
        .dbg_edge_ref (dbg_edge_ref),
        .dbg_edge_fb  (dbg_edge_fb)
    );

    loop_filter #(
        .ERR_W(18),
        .CTRL_W(24),
        .KP_SH(4),
        .KI_SH(10)
    ) u_lf (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .phase_valid(phase_valid),
        .phase_err(phase_err),
        .ctrl(ctrl)
    );

    // Show ctrl LSBs on outputs for debugging
    // Single output assignment: show CTRL (LSBs) + flags
    assign uo_out  = ena ? { ctrl[4:0], dbg_edge_fb, dbg_edge_ref, phase_valid } : 8'h00;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    wire _unused = &{uio_in};
endmodule
