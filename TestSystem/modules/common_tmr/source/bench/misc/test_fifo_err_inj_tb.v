// krzysztof.sielewicz@cern.ch
// test_fifo_err_inj_tb.v

`timescale 1 ns / 100 ps

module test_fifo_err_inj_tb();

reg clk100_r, rst100_r;//, clk40_r, rst40_r;

reg injectsbiterr_r;
reg injectdbiterr_r;

wire [191:0]      fifo_err_w;
wire [191:0]      pg_warn_w;
wire [3*192-1:0]  fifo_cnt_err_w;

test_fifo_err_inj #(.N(32), .M(3), .K(192)) test_fifo_err_inj(
  .clk_i            (clk100_r),
  .rst_i            (rst100_r),
  .injectsbiterr_i  (injectsbiterr_r),
  .injectdbiterr_i  (injectdbiterr_r),
  .fifo_err_o       (fifo_err_w),
  .pg_warn_o        (pg_warn_w),
  .fifo_cnt_err_o   (fifo_cnt_err_w)
);

mtbArrReadout mtbArrReadout_DP2(
  .clk_i              (clk100_r),
  .rst_i              (rst100_r),
  .monitor_i          ({{64{1'b0}}, fifo_err_w}),
  .fifo_full_i        (1'b0),
  .fifo_almst_full_i  (1'b0),
  .fifo_wr_o          (),
  .fifo_data_o        ()
);

tbRdout #(.N(32), .K(576)) tbRdout_DP3(
  .clk_i              (clk100_r),
  .rst_i              (rst100_r),
  .monitor_i          (fifo_cnt_err_w),
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
  
  repeat(5000) #5 clk100_r = ~clk100_r;
  
  $finish;
end

//initial begin
//  clk40_r = 1'b1;
//  rst40_r = 1'b1;
//  
//  repeat(5) #13 clk40_r = ~clk40_r;
//  rst40_r = 1'b0;
//  
//  repeat(100) #13 clk40_r = ~clk40_r;
//end

initial begin
  injectsbiterr_r <= 1'b0;
  injectdbiterr_r <= 1'b0;
  
  #2000
  @(posedge clk100_r);
  injectdbiterr_r <= 1'b1;
  
  #10
  @(posedge clk100_r);
  injectdbiterr_r <= 1'b0;
  
  #1000
  @(posedge clk100_r);
  injectdbiterr_r <= 1'b1;
  
  #10
  @(posedge clk100_r);
  injectdbiterr_r <= 1'b0;

/*  din           <= 32'd0;
  wr_en         <= 1'b0;
  rd_en         <= 1'b0;
  injectsbiterr <= 1'b0;
  
  #200
  @(posedge clk100_r);
  din           <= 32'hFFFFFFFF;
  wr_en         <= 1'b1;
  injectsbiterr <= 1'b1;
  
  #10
  @(posedge clk100_r);
  din           <= 32'hAAAAAAAA;
  wr_en         <= 1'b1;
  injectsbiterr <= 1'b0;
  
  #10
  @(posedge clk100_r);
  din           <= 32'd0;
  wr_en         <= 1'b0;
  injectsbiterr <= 1'b0;
  
  #100
  @(posedge clk100_r);
  rd_en         <= 1'b1;
  
  #20
  @(posedge clk100_r);
  rd_en         <= 1'b0;*/
  
end

endmodule
