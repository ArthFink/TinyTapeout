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

    // External reference (clock-like) input
    wire clk_ref_ext = ui_in[0];

    // External fb (optional) and selector
    wire clk_fb_ext  = ui_in[1];
    wire sel_close   = ui_in[2]; // 1 = close loop using internal helper

    wire [1:0] kp_sel = ui_in[4:3]; // P gain select (00=weakest, 11=strongest)
    wire [1:0] ki_sel = ui_in[6:5]; // I gain select (00=weakest, 11=strongest)

    wire        phase_valid;
    wire signed [23:0] ctrl;

    // Helper clock from NCO
    wire        clk_helper;
    wire [23:0] nco_phase_acc;

    // Choose feedback clock source
    wire clk_fb = sel_close ? clk_helper : clk_fb_ext;
    wire clk_ref = clk_ref_ext;

    // The core will be a Verilog module generated from ddmtd_core.vhd
    wire ref_samp, fb_samp;
    wire signed [15:0] phase_err_beat;   // choose width

    ddmtd_sampler #(
      .SYNC_STAGES(2),
      .COUNT_W(16)
    ) u_core (
      .clk_sys        (clk),
      .rst_n          (rst_n),
      .ena            (ena),
      .clk_ref_in     (clk_ref),
      .clk_fb_in      (clk_fb),
      .helper_tick    (helper_tick),
      .phase_valid    (phase_valid),
      .phase_err_beat (phase_err_beat),
      .ref_samp       (ref_samp),
      .fb_samp        (fb_samp)
    );

    loop_filter #(
        .ERR_W(16),
        .CTRL_W(24)
    ) u_lf (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .phase_valid(phase_valid),
        .phase_err(phase_err_beat),
        .kp_sel(kp_sel),
        .ki_sel(ki_sel),
        .ctrl(ctrl)
    );


    // NCO: ctrl -> clk_helper
    nco #(
        .ACC_W(24),
        .CTRL_W(24),
        .BASE_INC(1<<16),
        .CTRL_SH(8)
    ) u_nco (
        .clk       (clk),
        .rst_n     (rst_n),
        .ena       (ena),
        .ctrl      (ctrl),
        .clk_out   (clk_helper),
        .phase_acc (nco_phase_acc)
    );

    reg helper_msb_d;
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) helper_msb_d <= 1'b0;
      else        helper_msb_d <= nco_phase_acc[23];
    end

    wire helper_tick = (nco_phase_acc[23] ^ helper_msb_d); // tick on toggle

    // Outputs (beat-domain phase error):
    // uo[0]   = phase_valid (new measurement strobe)
    // uo[1]   = phase_err_sign = phase_err_beat[15]
    // uo[7:2] = phase_err_beat[11:6] (6 bits, mid-bits for stability)
    wire [7:0] uo_dbg = { phase_err_beat[11:6], phase_err_beat[15], phase_valid };

    assign uo_out  = ena ? uo_dbg : 8'h00;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    wire _unused = &{uio_in, ui_in[7:3]};

endmodule
