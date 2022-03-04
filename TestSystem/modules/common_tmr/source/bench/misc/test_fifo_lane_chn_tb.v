// krzysztof.sielewicz@cern.ch
// test_fifo_lane_chn_tb.v

`timescale 1 ns / 100 ps

module test_fifo_lane_chn_tb();

reg         clk100_r, rst100_r;

reg [4*48-1:0]  injectdbiterr_r;
reg [4*48-1:0]  injectsbiterr_r;

wire [11:0]     err_w;
wire [191:0]    sbiterr_w;
wire [191:0]    dbiterr_w;

test_fifo_lane_chn #(.N(32), .K(48), .M(3), .L(4)) test_fifo_lane_chn(
  .clk_i            (clk100_r),
  .rst_i            (rst100_r),
  .injectdbiterr_i  (injectdbiterr_r),
  .injectsbiterr_i  (injectsbiterr_r),
  .sbiterr_o        (sbiterr_w),
  .dbiterr_o        (dbiterr_w),
  .pg_warn_o        (),
  .err_o            (err_w)
);

tbRdout #(.N(32), .K(12)) tbRdout_DP2(
  .clk_i              (clk100_r),
  .rst_i              (rst100_r),
  .monitor_i          (err_w),
  .fifo_full_i        (1'b0),
  .fifo_almst_full_i  (1'b0),
  .fifo_wr_o          (),
  .fifo_data_o        ()
);

tbRdout #(.N(32), .K(384)) tbRdout_DP3(
  .clk_i              (clk100_r),
  .rst_i              (rst100_r),
  .monitor_i          ({dbiterr_w, sbiterr_w}),
  .fifo_full_i        (1'b0),
  .fifo_almst_full_i  (1'b0),
  .fifo_wr_o          (),
  .fifo_data_o        ()
);

initial begin
  clk100_r = 1'b1;
  rst100_r = 1'b1;
  
  repeat(20) #5 clk100_r = ~clk100_r;
  rst100_r = 1'b0;
  
  repeat(4000) #5 clk100_r = ~clk100_r;
  
  $finish;
end

initial begin
  injectdbiterr_r <= 384'd0;
  injectsbiterr_r <= 384'd0;
  
  #6000
  @(posedge clk100_r);
  injectsbiterr_r <= 384'd1;
  
  #10
  @(posedge clk100_r);
  injectsbiterr_r <= 384'd0;

end

endmodule
