// krzysztof.sielewicz@cern.ch
// fifo_chain.v

module fifo_chain#(parameter
  N = 32,
  K = 48)(
  input           clk_i,
  input           rst_i,
  
  input   [N-1:0] fifo_data_i,
  input           fifo_wr_i,
  output          fifo_full_o,
  output          fifo_almst_full_o,
  
  output  [N-1:0] fifo_data_o,
  input           fifo_rd_i,
  output          fifo_empty_o,
  output          fifo_almst_empty_o,
  
  input   [K-1:0] injectdbiterr_i,
  input   [K-1:0] injectsbiterr_i,
  
  output  [K-1:0] sbiterr_o,
  output  [K-1:0] dbiterr_o
);

wire [N-1:0] fifo_data_w[K-1:0];
wire [K-1:0] fifo_wr_w;
wire [K-1:0] fifo_rd_w;
wire [K-1:0] full_w;
wire [K-1:0] almost_full_w;
wire [K-1:0] empty_w;
wire [K-1:0] almost_empty_w;

assign fifo_data_w[0]   = fifo_data_i;
assign fifo_wr_w[0]       = fifo_wr_i;
assign fifo_full_o        = full_w[0];
assign fifo_almst_full_o  = almost_full_w[0];
assign fifo_rd_w[47]      = fifo_rd_i;
assign fifo_empty_o       = empty_w[47];
assign fifo_almst_empty_o = almost_empty_w[47];

genvar i;
generate
	for(i=0; i<K-1; i=i+1)
	begin : fifo
    // fifo32x1024_ecc_inj
    fifo32x1024_ecc_inj fifo32x1024_ecc_inj_i(
      .rst            (rst_i),
      .wr_clk         (clk_i),
      .rd_clk         (clk_i),
      .din            (fifo_data_w[i]),
      .wr_en          (fifo_wr_w[i]),
      .rd_en          (fifo_rd_w[i]),
      .injectdbiterr  (injectdbiterr_i[i]),
      .injectsbiterr  (injectsbiterr_i[i]),
      .dout           (fifo_data_w[i+1]),
      .full           (full_w[i]),
      .almost_full    (almost_full_w[i]),
      .empty          (empty_w[i]),
      .almost_empty   (almost_empty_w[i]),
      .sbiterr        (sbiterr_o[i]),
      .dbiterr        (dbiterr_o[i])
    );

    // fifo_glue_logic
    fifo_glue_logic fifo_glue_logic_i(
      .clk_i                (clk_i),
      .rst_i                (rst_i),
      .fifoA_rd_o           (fifo_rd_w[i]),
      .fifoA_almst_empty_i  (almost_empty_w[i]),
      .fifoB_almst_full_i   (almost_full_w[i+1]),
      .fifoB_wr_o           (fifo_wr_w[i+1])
    );
	end
endgenerate

fifo32x1024_ecc_inj fifo32x1024_ecc_inj_47(
  .rst            (rst_i),
  .wr_clk         (clk_i),
  .rd_clk         (clk_i),
  .din            (fifo_data_w[47]),
  .wr_en          (fifo_wr_w[47]),
  .rd_en          (fifo_rd_w[47]),
  .injectdbiterr  (injectdbiterr_i[47]),
  .injectsbiterr  (injectsbiterr_i[47]),
  .dout           (fifo_data_o),
  .full           (full_w[47]),
  .almost_full    (almost_full_w[47]),
  .empty          (empty_w[47]),
  .almost_empty   (almost_empty_w[47]),
  .sbiterr        (sbiterr_o[47]),
  .dbiterr        (dbiterr_o[47])
);

/*wire [N-1:0] fifo_data_w;
wire fifoA_rd_w;
wire fifoA_almst_empty_w;
wire fifoB_almst_full_w;
wire fifoB_wr_w;

fifo32x32_ecc fifo32x32_ecc_A(
  .rst            (rst_i),                // input wire rst
  .wr_clk         (clk_i),                // input wire wr_clk
  .rd_clk         (clk_i),                // input wire rd_clk
  .din            (fifo_data_i),          // input wire [31 : 0] din
  .wr_en          (fifo_wr_i),            // input wire wr_en
  .rd_en          (fifoA_rd_w),           // input wire rd_en
  .injectsbiterr  (1'b0),                 // input wire injectsbiterr
  .dout           (fifo_data_w),          // output wire [31 : 0] dout
  .full           (fifo_full_o),          // output wire full
  .almost_full    (fifo_almst_full_o),    // output wire almost_full
  .empty          (),                     // output wire empty
  .almost_empty   (fifoA_almst_empty_w),  // output wire almost_empty
  .sbiterr        (),                     // output wire sbiterr
  .dbiterr        ()                      // output wire dbiterr
);

fifo_glue_logic fifo_glue_logic(
  .clk_i                (clk_i),
  .rst_i                (rst_i),
  .fifoA_rd_o           (fifoA_rd_w),
  .fifoA_almst_empty_i  (fifoA_almst_empty_w),
  .fifoB_almst_full_i   (fifoB_almst_full_w),
  .fifoB_wr_o           (fifoB_wr_w)
);

fifo32x32_ecc fifo32x32_ecc_B(
  .rst            (rst_i),                // input wire rst
  .wr_clk         (clk_i),                // input wire wr_clk
  .rd_clk         (clk_i),                // input wire rd_clk
  .din            (fifo_data_w),          // input wire [31 : 0] din
  .wr_en          (fifoB_wr_w),           // input wire wr_en
  .rd_en          (fifo_rd_i),            // input wire rd_en
  .injectsbiterr  (1'b0),                 // input wire injectsbiterr
  .dout           (fifo_data_o),          // output wire [31 : 0] dout
  .full           (),                     // output wire full
  .almost_full    (fifoB_almst_full_w),   // output wire almost_full
  .empty          (fifo_empty_o),         // output wire empty
  .almost_empty   (fifo_almst_empty_o),   // output wire almost_empty
  .sbiterr        (),                     // output wire sbiterr
  .dbiterr        ()                      // output wire dbiterr
);*/

endmodule
