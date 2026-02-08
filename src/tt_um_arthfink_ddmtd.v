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

    // Output mapping (debug-friendly)
    // [0]=valid, [1]=edge_ref, [2]=edge_fb, [7:3]=phase_err LSBs
    wire [7:0] uo_raw = {
        phase_err[4:0],
        dbg_edge_fb,
        dbg_edge_ref,
        phase_valid
    };

    assign uo_out  = ena ? uo_raw : 8'h00;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    // Optional: silence unused warnings
    wire _unused = &{uio_in};

endmodule
