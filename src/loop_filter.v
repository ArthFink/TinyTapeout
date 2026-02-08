// src/loop_filter.v
//
// Simple PI-like digital loop filter with selectable gains via kp_sel/ki_sel.
// - Updates only when (ena && phase_valid) is true
// - I-path accumulator with saturation on output
// - Gains implemented as arithmetic right shifts (power-of-two scaling)
//
// Robustness:
// - kp_sel/ki_sel are latched on reset release to avoid floating/glitchy pins.
// - Defaults are kp_sel=2'b10 (kp_sh=4) and ki_sel=2'b10 (ki_sh=10).

module loop_filter #(
    parameter integer ERR_W   = 16,  // phase_err width (signed)
    parameter integer CTRL_W  = 24   // ctrl output width (signed)
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    ena,

    input  wire [1:0]              kp_sel,
    input  wire [1:0]              ki_sel,

    input  wire                    phase_valid,
    input  wire signed [ERR_W-1:0] phase_err,

    output reg  signed [CTRL_W-1:0] ctrl
);

    // Wider internal accumulator to reduce overflow risk.
    localparam integer ACC_W = CTRL_W + 6;

    reg signed [ACC_W-1:0] i_acc;

    // Latch gain selects to avoid unstable/floating pins changing loop dynamics
    reg [1:0] kp_sel_latched;
    reg [1:0] ki_sel_latched;

    // Build shift amounts from latched selects (power-of-two gains)
    reg [4:0] kp_sh, ki_sh;
    always @* begin
        case (kp_sel_latched)
            2'b00: kp_sh = 6; // weakest P
            2'b01: kp_sh = 5;
            2'b10: kp_sh = 4; // default
            2'b11: kp_sh = 3; // strongest P
        endcase

        case (ki_sel_latched)
            2'b00: ki_sh = 12; // weakest I
            2'b01: ki_sh = 11;
            2'b10: ki_sh = 10; // default
            2'b11: ki_sh = 9;  // strongest I
        endcase
    end

    // Sign-extend phase_err to accumulator width
    wire signed [ACC_W-1:0] err_ext =
        $signed({{(ACC_W-ERR_W){phase_err[ERR_W-1]}}, phase_err});

    // Proportional and integral terms
    wire signed [ACC_W-1:0] p_term = err_ext >>> kp_sh;
    wire signed [ACC_W-1:0] i_inc  = err_ext >>> ki_sh;

    // Combine PI (use current i_acc; i_acc updates at clock edge)
    wire signed [ACC_W-1:0] sum_pi = i_acc + p_term;

    // Saturate ACC_W -> CTRL_W
    function signed [CTRL_W-1:0] sat_to_ctrl;
        input signed [ACC_W-1:0] x;
        reg signed [ACC_W-1:0] maxv;
        reg signed [ACC_W-1:0] minv;
    begin
        // max = 0 followed by all 1s in CTRL_W bits (sign-extended to ACC_W)
        maxv = {{(ACC_W-CTRL_W){1'b0}}, 1'b0, {(CTRL_W-1){1'b1}}};
        // min = 1 followed by all 0s in CTRL_W bits (sign-extended to ACC_W)
        minv = {{(ACC_W-CTRL_W){1'b1}}, 1'b1, {(CTRL_W-1){1'b0}}};

        if (x > maxv)       sat_to_ctrl = maxv[CTRL_W-1:0];
        else if (x < minv)  sat_to_ctrl = minv[CTRL_W-1:0];
        else                sat_to_ctrl = x[CTRL_W-1:0];
    end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Defaults (safe bring-up)
            kp_sel_latched <= 2'b10; // kp_sh = 4
            ki_sel_latched <= 2'b10; // ki_sh = 10

            i_acc <= '0;
            ctrl  <= '0;
        end else begin
            // Latch external gain selects once after reset is released.
            // If you prefer to only latch when ena=1, change this logic accordingly.
            kp_sel_latched <= kp_sel_latched; // hold by default
            ki_sel_latched <= ki_sel_latched;

            // If you want to allow changing gains only when disabled:
            if (!ena) begin
                kp_sel_latched <= kp_sel;
                ki_sel_latched <= ki_sel;
            end

            if (ena && phase_valid) begin
                i_acc <= i_acc + i_inc;
                ctrl  <= sat_to_ctrl(sum_pi);
            end
        end
    end

endmodule
