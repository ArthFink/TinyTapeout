// src/loop_filter.v
module loop_filter #(
    parameter integer ERR_W   = 18,  // phase_err width
    parameter integer CTRL_W  = 24,  // ctrl output width
    parameter integer KP_SH   = 4,   // proportional gain as right shift (divide by 2^KP_SH)
    parameter integer KI_SH   = 10   // integral gain as right shift (divide by 2^KI_SH)
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   ena,

    input  wire                   phase_valid,
    input  wire signed [ERR_W-1:0] phase_err,

    output reg  signed [CTRL_W-1:0] ctrl
);

    // Wider internal accumulator to reduce overflow risk.
    // Keep it modest for TinyTapeout.
    localparam integer ACC_W = CTRL_W + 6;

    reg signed [ACC_W-1:0] i_acc;

    // Saturating resize helper (SystemVerilog would be nicer, but keep plain Verilog)
    function signed [CTRL_W-1:0] sat_to_ctrl;
        input signed [ACC_W-1:0] x;
        reg signed [ACC_W-1:0] maxv;
        reg signed [ACC_W-1:0] minv;
    begin
        maxv =  ( (1'sb1 <<< (CTRL_W-1)) - 1 ); // +2^(CTRL_W-1)-1
        minv =  -( 1'sb1 <<< (CTRL_W-1) );      // -2^(CTRL_W-1)
        if (x > maxv)      sat_to_ctrl = maxv[CTRL_W-1:0];
        else if (x < minv) sat_to_ctrl = minv[CTRL_W-1:0];
        else               sat_to_ctrl = x[CTRL_W-1:0];
    end
    endfunction

    // Extend phase_err to accumulator width
    wire signed [ACC_W-1:0] err_ext = {{(ACC_W-ERR_W){phase_err[ERR_W-1]}}, phase_err};

    // P term: err / 2^KP_SH
    wire signed [ACC_W-1:0] p_term = err_ext >>> KP_SH;

    // I increment: err / 2^KI_SH
    wire signed [ACC_W-1:0] i_inc  = err_ext >>> KI_SH;

    // Combine
    wire signed [ACC_W-1:0] sum_pi = i_acc + p_term;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_acc <= '0;
            ctrl  <= '0;
        end else begin
            if (ena && phase_valid) begin
                // Integrator update
                i_acc <= i_acc + i_inc;

                // Output update (use current i_acc, not the updated one; this is fine)
                ctrl <= sat_to_ctrl(sum_pi);
            end
        end
    end

endmodule
