// src/nco.v
//
// Simple NCO (phase accumulator)
// - Generates a square-wave clk_out = phase_acc[MSB]
// - Frequency controlled by phase_inc
//
// phase_inc = BASE_INC + (ctrl >>> CTRL_SH)
//
// BASE_INC sets nominal frequency.
// ctrl provides +/- trimming around BASE_INC.
//

module nco #(
    parameter integer ACC_W    = 24,   // phase accumulator width
    parameter integer CTRL_W   = 24,   // ctrl width
    parameter [ACC_W-1:0] BASE_INC = 1<<16, // nominal increment (tune this)
    parameter integer CTRL_SH  = 8     // ctrl scaling: smaller => stronger control
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    ena,
    input  wire signed [CTRL_W-1:0] ctrl,
    output wire                    clk_out,
    output reg  [ACC_W-1:0]        phase_acc  // optional debug
);

    // Scale ctrl into accumulator domain
    wire signed [ACC_W-1:0] ctrl_scaled = ({{(ACC_W-CTRL_W){ctrl[CTRL_W-1]}}, ctrl}) >>> CTRL_SH;

    // BASE_INC is positive unsigned; convert to signed for addition
    wire signed [ACC_W-1:0] base_inc_s = $signed(BASE_INC);

    // Compute increment; clamp to at least 1 to avoid “stuck”
    wire signed [ACC_W-1:0] inc_s = base_inc_s + ctrl_scaled;

    // Minimal clamp: ensure inc != 0 (and avoid negative runaway in early tests)
    // For first bring-up we clamp negative to +1.
    wire [ACC_W-1:0] inc_u =
        (inc_s <= 0) ? {{(ACC_W-1){1'b0}},1'b1} : inc_s[ACC_W-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= '0;
        end else if (ena) begin
            phase_acc <= phase_acc + inc_u;
        end
    end

    assign clk_out = phase_acc[ACC_W-1];

endmodule
