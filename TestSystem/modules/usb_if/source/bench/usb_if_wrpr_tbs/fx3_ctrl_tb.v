////////////////////////////////////////////////////////////////////////////////
// Title        : FX3 Controller Test Bench
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : fx3_ctrl_tb.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-2
// Last update  : 2015-12-2
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: This is the simple test bench to simulate the fx3_ctrl module
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module fx3_ctrl_tb();

reg           clk_r, rst_r;
reg           FLAGA_r, FLAGB_r, FLAGC_r, FLAGD_r;

wire  [1:0]   SLADDR_w;
wire          SLOEn_w;
wire          SLCSn_w;
wire          SLRDn_w;
wire          SLWRn_w;
wire          PKTENDn_w;

wire [31:0]   dp0_dti_w;
wire          dp0_full_w;
wire          dp0_almst_full_w;
wire          dp0_wr_w;

wire  [31:0]  dpo1_dti_w;
reg           inc_r;
reg           dpo1_wr_r;
wire  [31:0]  dpo1_dto_w;
wire          dpo1_epty_w;
wire          dpo1_almst_epty_w;
wire          dpo1_rd_w;

wire  [31:0]  dpo2_dto_w;
wire          dpo2_epty_w;
wire          dpo2_almst_epty_w;
wire          dpo2_rd_w;

wire  [31:0]  dpo3_dto_w;
wire          dpo3_epty_w;
wire          dpo3_almst_epty_w;
wire          dpo3_rd_w;

fx3_ctrl fx3_ctrl(
  .clk_i              (clk_r),
  .rst_i              (rst_r),
  .FLAGA_i            (FLAGA_r),
  .FLAGB_i            (FLAGB_r),
  .FLAGC_i            (FLAGC_r),
  .FLAGD_i            (FLAGD_r),
  .SLADDR_o           (SLADDR_w),
  .SLOEn_o            (SLOEn_w),
  .SLCSn_o            (SLCSn_w),
  .SLRDn_o            (SLRDn_w),
  .SLWRn_o            (SLWRn_w),
  .PKTENDn_o          (PKTENDn_w),
  .DQ_i               (32'd0),
  .DQ_o               (),
  // DP0
  .dp0_dt_o           (dp0_dti_w),
  .dp0_full_i         (dp0_full_w),
  .dp0_almst_full_i   (dp0_almst_full_w),
  .dp0_wr_o           (dp0_wr_w),
  // DP1
  .dpo1_dt_i          (dpo1_dto_w),
  .dpo1_epty_i        (dpo1_epty_w),
  .dpo1_almst_epty_i  (dpo1_almst_epty_w),
  .dpo1_rd_o          (dpo1_rd_w),
  // DP2
  .dpo2_dt_i          (dpo2_dto_w),
  .dpo2_epty_i        (dpo2_epty_w),
  .dpo2_almst_epty_i  (dpo2_almst_epty_w),
  .dpo2_rd_o          (dpo2_rd_w),
  // DP3
  .dpo3_dt_i          (dpo3_dto_w),
  .dpo3_epty_i        (dpo3_epty_w),
  .dpo3_almst_epty_i  (dpo3_almst_epty_w),
  .dpo3_rd_o          (dpo3_rd_w)
);

// FIFO for DP0
fifo32x1024 fifo32x1024_DP0(
  .wr_clk       (clk_r),
  .rd_clk       (clk_r),
  .almost_full  (dp0_almst_full_w),
  .almost_empty (),
  .rst          (rst_r),
  .wr_en        (dp0_wr_w),
  .rd_en        (1'b0),
  .din          (dp0_dti_w),
  .dout         (),
  .full         (dp0_full_w),
  .empty        ()
);

// FIFO for DP1
fifo32x1024 fifo32x1024_DP1(
  .wr_clk       (clk_r),
  .rd_clk       (clk_r),
  .almost_full  (),
  .almost_empty (dpo1_almst_epty_w),
  .rst          (rst_r),
  .wr_en        (dpo1_wr_r),
  .rd_en        (dpo1_rd_w),
  .din          (dpo1_dti_w),
  .dout         (dpo1_dto_w),
  .full         (),
  .empty        (dpo1_epty_w)
);

// FIFO for DP2
fifo32x1024 fifo32x1024_DP2(
  .wr_clk       (clk_r),
  .rd_clk       (clk_r),
  .almost_full  (),
  .almost_empty (dpo2_almst_epty_w),
  .rst          (rst_r),
  .wr_en        (1'b0),
  .rd_en        (dpo2_rd_w),
  .din          (32'd0),
  .dout         (dpo2_dto_w),
  .full         (),
  .empty        (dpo2_epty_w)
);

// FIFO for DP3
fifo32x1024 fifo32x1024_DP3(
  .wr_clk       (clk_r),
  .rd_clk       (clk_r),
  .almost_full  (),
  .almost_empty (dpo3_almst_epty_w),
  .rst          (rst_r),
  .wr_en        (1'b0),
  .rd_en        (dpo3_rd_w),
  .din          (32'd0),
  .dout         (dpo3_dto_w),
  .full         (),
  .empty        (dpo3_epty_w)
);

datagen datagen (
  .clk_i  (clk_r),
  .rst_i  (rst_r),
  .inc_i  (inc_r),
  .cnt_o  (dpo1_dti_w)
);

initial begin
  clk_r = 1'b1;
  rst_r = 1'b1;
  
  repeat(6) #5 clk_r = ~clk_r;
  rst_r = 1'b0;
  
  repeat(10000) #5 clk_r = ~clk_r;
  
  $finish;
end

initial begin
  FLAGA_r     <= 1'b1;
  FLAGB_r     <= 1'b1;
  FLAGC_r     <= 1'b1;
  FLAGD_r     <= 1'b1;
  inc_r       <= 1'b0;
  dpo1_wr_r   <= 1'b0;
  
  #200
  @(posedge clk_r);
  inc_r       <= 1'b1;
  dpo1_wr_r   <= 1'b1;
end

endmodule
