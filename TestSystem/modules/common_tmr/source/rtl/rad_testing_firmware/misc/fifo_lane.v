// krzysztof.sielewicz@cern.ch
// fifo_lane.v

(* DONT_TOUCH = "true" *) module fifo_lane #(parameter
  N = 32,
  M = 3)(
  input   clk_i,
  input   rst_i,
  output  fifo_err_o,
  output  pg_warn_o
);

wire          fifo_wr_w;
wire          fifo_full_w;
wire          fifo_almst_full_w;
wire [N-1:0]  fifo_dt_wrtr_w;

wire          fifo_rd_w;
wire          fifo_empty_w;
wire          fifo_almst_empty_w;
wire [N-1:0]  fifo_dt_rdr_w;

wire          sbiterr_w;
wire          dbiterr_w;
//assign fifo_err_o = sbiterr_w | dbiterr_w;
assign fifo_err_o = sbiterr_w;

// fifo_writer
fifo_writer #(.N(N), .M(M)) fifo_writer(
  .clk_i              (clk_i),
  .rst_i              (rst_i),
  .fifo_full_i        (fifo_full_w),
  .fifo_almst_full_i  (fifo_almst_full_w),
  .fifo_wr_o          (fifo_wr_w),
  .fifo_data_o        (fifo_dt_wrtr_w),
  .pg_warn_o          (pg_warn_o)
);

// fifo32x1024_ecc
fifo32x1024_ecc fifo32x1024_ecc(
  .rst          (rst_i),              // input wire rst
  .wr_clk       (clk_i),              // input wire wr_clk
  .rd_clk       (clk_i),              // input wire rd_clk
  .din          (fifo_dt_wrtr_w),     // input wire [31 : 0] din
  .wr_en        (fifo_wr_w),          // input wire wr_en
  .rd_en        (fifo_rd_w),          // input wire rd_en
  .dout         (fifo_dt_rdr_w),      // output wire [31 : 0] dout
  .full         (fifo_full_w),        // output wire full
  .almost_full  (fifo_almst_full_w),  // output wire almost_full
  .empty        (fifo_empty_w),       // output wire empty
  .almost_empty (fifo_almst_empty_w), // output wire almost_empty
  .sbiterr      (sbiterr_w),          // output wire sbiterr
  .dbiterr      (dbiterr_w)           // output wire dbiterr
);

// fifo_reader
fifo_reader #(.N(N)) fifo_reader(
  .clk_i              (clk_i),
  .rst_i              (rst_i),
  .fifo_empty_i       (fifo_empty_w),
  .fifo_almst_empty_i (fifo_almst_empty_w),
  .fifo_rd_o          (fifo_rd_w),
  .fifo_data_i        (fifo_dt_rdr_w)
);

endmodule
