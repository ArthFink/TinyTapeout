module ddmtd_core
  (input  clk_sys,
   input  rst_n,
   input  clk_ref,
   input  clk_fb,
   output phase_valid,
   output [17:0] phase_err,
   output dbg_edge_ref,
   output dbg_edge_fb);
  reg [1:0] ref_sync;
  reg [1:0] fb_sync;
  reg ref_sync_d;
  reg fb_sync_d;
  reg edge_ref;
  reg edge_fb;
  reg [23:0] cnt;
  reg [23:0] t_ref;
  reg [17:0] phase_err_r;
  reg phase_valid_r;
  wire n18_o;
  wire [23:0] n20_o;
  wire n21_o;
  wire [1:0] n22_o;
  wire n23_o;
  wire [1:0] n24_o;
  wire n25_o;
  wire n26_o;
  wire n27_o;
  wire n28_o;
  wire n29_o;
  wire n30_o;
  wire n31_o;
  wire n32_o;
  wire [23:0] n33_o;
  wire [23:0] n34_o;
  wire n44_o;
  wire n46_o;
  wire [17:0] n47_o;
  wire [17:0] n49_o;
  wire [17:0] n51_o;
  wire [17:0] n53_o;
  wire n56_o;
  wire [1:0] n60_o;
  wire [1:0] n62_o;
  wire n64_o;
  wire n66_o;
  wire n68_o;
  wire n70_o;
  wire [23:0] n72_o;
  wire [23:0] n74_o;
  wire [17:0] n76_o;
  wire n78_o;
  reg [1:0] n93_q;
  reg [1:0] n94_q;
  reg n95_q;
  reg n96_q;
  reg n97_q;
  reg n98_q;
  reg [23:0] n99_q;
  reg [23:0] n100_q;
  reg [17:0] n101_q;
  reg n102_q;
  assign phase_valid = phase_valid_r; //(module output)
  assign phase_err = phase_err_r; //(module output)
  assign dbg_edge_ref = edge_ref; //(module output)
  assign dbg_edge_fb = edge_fb; //(module output)
  /* src/ddmtd_core.vhd:29:10  */
  always @*
    ref_sync = n93_q; // (isignal)
  initial
    ref_sync = 2'b00;
  /* src/ddmtd_core.vhd:30:10  */
  always @*
    fb_sync = n94_q; // (isignal)
  initial
    fb_sync = 2'b00;
  /* src/ddmtd_core.vhd:32:10  */
  always @*
    ref_sync_d = n95_q; // (isignal)
  initial
    ref_sync_d = 1'b0;
  /* src/ddmtd_core.vhd:33:10  */
  always @*
    fb_sync_d = n96_q; // (isignal)
  initial
    fb_sync_d = 1'b0;
  /* src/ddmtd_core.vhd:34:10  */
  always @*
    edge_ref = n97_q; // (isignal)
  initial
    edge_ref = 1'b0;
  /* src/ddmtd_core.vhd:35:10  */
  always @*
    edge_fb = n98_q; // (isignal)
  initial
    edge_fb = 1'b0;
  /* src/ddmtd_core.vhd:37:10  */
  always @*
    cnt = n99_q; // (isignal)
  initial
    cnt = 24'b000000000000000000000000;
  /* src/ddmtd_core.vhd:38:10  */
  always @*
    t_ref = n100_q; // (isignal)
  initial
    t_ref = 24'b000000000000000000000000;
  /* src/ddmtd_core.vhd:40:10  */
  always @*
    phase_err_r = n101_q; // (isignal)
  initial
    phase_err_r = 18'b000000000000000000;
  /* src/ddmtd_core.vhd:41:10  */
  always @*
    phase_valid_r = n102_q; // (isignal)
  initial
    phase_valid_r = 1'b0;
  /* src/ddmtd_core.vhd:72:16  */
  assign n18_o = ~rst_n;
  /* src/ddmtd_core.vhd:86:20  */
  assign n20_o = cnt + 24'b000000000000000000000001;
  /* src/ddmtd_core.vhd:88:29  */
  assign n21_o = ref_sync[0]; // extract
  /* src/ddmtd_core.vhd:88:56  */
  assign n22_o = {n21_o, clk_ref};
  /* src/ddmtd_core.vhd:89:28  */
  assign n23_o = fb_sync[0]; // extract
  /* src/ddmtd_core.vhd:89:54  */
  assign n24_o = {n23_o, clk_fb};
  /* src/ddmtd_core.vhd:91:31  */
  assign n25_o = ref_sync[1]; // extract
  /* src/ddmtd_core.vhd:92:30  */
  assign n26_o = fb_sync[1]; // extract
  /* src/ddmtd_core.vhd:94:29  */
  assign n27_o = ref_sync[1]; // extract
  /* src/ddmtd_core.vhd:94:50  */
  assign n28_o = ~ref_sync_d;
  /* src/ddmtd_core.vhd:94:45  */
  assign n29_o = n27_o & n28_o;
  /* src/ddmtd_core.vhd:95:28  */
  assign n30_o = fb_sync[1]; // extract
  /* src/ddmtd_core.vhd:95:49  */
  assign n31_o = ~fb_sync_d;
  /* src/ddmtd_core.vhd:95:44  */
  assign n32_o = n30_o & n31_o;
  /* src/ddmtd_core.vhd:99:9  */
  assign n33_o = edge_ref ? cnt : t_ref;
  /* src/ddmtd_core.vhd:104:30  */
  assign n34_o = cnt - t_ref;
  /* src/ddmtd_core.vhd:51:10  */
  assign n44_o = $signed(n34_o) > $signed(24'b000000011111111111111111);
  /* src/ddmtd_core.vhd:53:13  */
  assign n46_o = $signed(n34_o) < $signed(24'b111111100000000000000000);
  /* src/ddmtd_core.vhd:56:12  */
  assign n47_o = n34_o[17:0];  // trunc
  /* src/ddmtd_core.vhd:53:5  */
  assign n49_o = n46_o ? 18'b100000000000000000 : n47_o;
  /* src/ddmtd_core.vhd:51:5  */
  assign n51_o = n44_o ? 18'b011111111111111111 : n49_o;
  /* src/ddmtd_core.vhd:103:9  */
  assign n53_o = edge_fb ? n51_o : phase_err_r;
  /* src/ddmtd_core.vhd:103:9  */
  assign n56_o = edge_fb ? 1'b1 : 1'b0;
  /* src/ddmtd_core.vhd:72:7  */
  assign n60_o = n18_o ? 2'b00 : n22_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n62_o = n18_o ? 2'b00 : n24_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n64_o = n18_o ? 1'b0 : n25_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n66_o = n18_o ? 1'b0 : n26_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n68_o = n18_o ? 1'b0 : n29_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n70_o = n18_o ? 1'b0 : n32_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n72_o = n18_o ? 24'b000000000000000000000000 : n20_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n74_o = n18_o ? 24'b000000000000000000000000 : n33_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n76_o = n18_o ? 18'b000000000000000000 : n53_o;
  /* src/ddmtd_core.vhd:72:7  */
  assign n78_o = n18_o ? 1'b0 : n56_o;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n93_q <= n60_o;
  initial
    n93_q = 2'b00;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n94_q <= n62_o;
  initial
    n94_q = 2'b00;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n95_q <= n64_o;
  initial
    n95_q = 1'b0;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n96_q <= n66_o;
  initial
    n96_q = 1'b0;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n97_q <= n68_o;
  initial
    n97_q = 1'b0;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n98_q <= n70_o;
  initial
    n98_q = 1'b0;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n99_q <= n72_o;
  initial
    n99_q = 24'b000000000000000000000000;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n100_q <= n74_o;
  initial
    n100_q = 24'b000000000000000000000000;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n101_q <= n76_o;
  initial
    n101_q = 18'b000000000000000000;
  /* src/ddmtd_core.vhd:71:5  */
  always @(posedge clk_sys)
    n102_q <= n78_o;
  initial
    n102_q = 1'b0;
endmodule

