module ddmtd_sampler #(
    parameter integer SYNC_STAGES = 2,
    parameter integer COUNT_W      = 16
)(
    input  wire clk_sys,
    input  wire rst_n,
    input  wire ena,

    // async-ish external clocks (must be synchronized)
    input  wire clk_ref_in,
    input  wire clk_fb_in,

    // helper tick in clk_sys domain (1-cycle pulse)
    input  wire helper_tick,

    output reg                  phase_valid,
    output reg  signed [COUNT_W-1:0] phase_err_beat,

    // debug
    output reg ref_samp,
    output reg fb_samp
);

    // --- Synchronizers into clk_sys ---
    reg [SYNC_STAGES-1:0] ref_sync;
    reg [SYNC_STAGES-1:0] fb_sync;

    wire ref_sys = ref_sync[SYNC_STAGES-1];
    wire fb_sys  = fb_sync[SYNC_STAGES-1];

    // --- Samples taken on helper ticks ---
    reg ref_samp_d, fb_samp_d;
    wire ref_edge_samp = ref_samp & ~ref_samp_d;
    wire fb_edge_samp  = fb_samp  & ~fb_samp_d;

    // --- Beat-domain counters (counts helper samples) ---
    reg [COUNT_W-1:0] beat_cnt;
    reg [COUNT_W-1:0] t_ref;
    reg [COUNT_W-1:0] t_fb;

    reg have_ref, have_fb;

    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            ref_sync <= '0;
            fb_sync  <= '0;

            ref_samp   <= 1'b0;
            fb_samp    <= 1'b0;
            ref_samp_d <= 1'b0;
            fb_samp_d  <= 1'b0;

            beat_cnt <= '0;
            t_ref    <= '0;
            t_fb     <= '0;

            have_ref <= 1'b0;
            have_fb  <= 1'b0;

            phase_valid    <= 1'b0;
            phase_err_beat <= '0;
        end else begin
            phase_valid <= 1'b0;

            // sync external signals
            ref_sync <= {ref_sync[SYNC_STAGES-2:0], clk_ref_in};
            fb_sync  <= {fb_sync [SYNC_STAGES-2:0], clk_fb_in };

            if (ena && helper_tick) begin
                // increment beat counter on each helper tick
                beat_cnt <= beat_cnt + 1'b1;

                // sample synchronized refs on helper ticks
                ref_samp <= ref_sys;
                fb_samp  <= fb_sys;

                // edge detect in sampled domain
                ref_samp_d <= ref_samp;
                fb_samp_d  <= fb_samp;

                if (ref_edge_samp) begin
                    t_ref    <= beat_cnt;
                    have_ref <= 1'b1;
                end

                if (fb_edge_samp) begin
                    t_fb    <= beat_cnt;
                    have_fb <= 1'b1;
                end

                // when both timestamps captured, output signed difference
                if (have_ref && have_fb) begin
                    // signed modular difference (wrap OK if COUNT_W is large enough)
                    phase_err_beat <= $signed({1'b0,t_fb}) - $signed({1'b0,t_ref});
                    phase_valid    <= 1'b1;
                    have_ref <= 1'b0;
                    have_fb  <= 1'b0;
                end
            end
        end
    end

endmodule
