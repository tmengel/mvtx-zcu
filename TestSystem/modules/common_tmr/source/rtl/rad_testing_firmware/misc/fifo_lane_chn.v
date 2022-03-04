// krzysztof.sielewicz@cern.ch
// fifo_lane_chn.v

module fifo_lane_chn#(parameter
  N = 32,
  K = 48,
  M = 3)(
  input           clk_i,
  input           rst_i,
  
  input   [K-1:0] injectdbiterr_i,
  input   [K-1:0] injectsbiterr_i,
  
  output  [K-1:0] sbiterr_o,
  output  [K-1:0] dbiterr_o,
  
  output          pg_warn_o,
  output  [M-1:0] err_o
);

wire  [N-1:0] fifo_dt_wrtr_w;
wire          fifo_wr_w;
wire          fifo_full_w;
wire          fifo_almst_full_w;

wire  [N-1:0] fifo_dt_rdr_w;
wire          fifo_rd_w;
wire          fifo_empty_w;
wire          fifo_almst_empty_w;
wire          fifo_almst_full_last_w;

// smart_fifo_writer
smart_fifo_writer3 #(.N(N), .M(M)) smart_fifo_writer(
  .clk_i              (clk_i),
  .rst_i              (rst_i),
  .fifo_full_i        (fifo_full_w),
  .fifo_almst_full_i  (fifo_almst_full_w),
  .fifo_wr_o          (fifo_wr_w),
  .fifo_data_o        (fifo_dt_wrtr_w),
  .pg_warn_o          (pg_warn_o)
);

// fifo_chain
fifo_chain2 #(.N(N), .K(K)) fifo_chain(
  .clk_i                  (clk_i),
  .rst_i                  (rst_i),
  .fifo_data_i            (fifo_dt_wrtr_w),
  .fifo_wr_i              (fifo_wr_w),
  .fifo_full_o            (fifo_full_w),
  .fifo_almst_full_o      (fifo_almst_full_w),
  .fifo_almst_full_last_o (fifo_almst_full_last_w),
  .fifo_data_o            (fifo_dt_rdr_w),
  .fifo_rd_i              (fifo_rd_w),
  .fifo_empty_o           (fifo_empty_w),
  .fifo_almst_empty_o     (fifo_almst_empty_w),
  .injectdbiterr_i        (injectdbiterr_i),
  .injectsbiterr_i        (injectsbiterr_i),
  .sbiterr_o              (sbiterr_o),
  .dbiterr_o              (dbiterr_o)
);

// smart_fifo_reader
smart_fifo_reader2 #(.N(N), .M(M)) smart_fifo_reader(
  .clk_i              (clk_i),
  .rst_i              (rst_i),
  .fifo_almst_full_i  (fifo_almst_full_last_w),
  .fifo_empty_i       (fifo_empty_w),
  .fifo_almst_empty_i (fifo_almst_empty_w),
  .fifo_rd_o          (fifo_rd_w),
  .fifo_data_i        (fifo_dt_rdr_w),
  .err_o              (err_o)
);

endmodule
