////////////////////////////////////////////////////////////////////////////////
// Title        : USB Interface Wrapper Test Bench
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : usb_if_wrpr_tb.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-2
// Last update  : 2015-12-2
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: This is the simple test bench to simulate the usb_if_wrpr module
//              with the smartProducer data generator running at 100MHz
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module usb_if_wrpr_tb2();

reg           clk_r, rst_r;
reg           FLAGA_r, FLAGB_r, FLAGC_r, FLAGD_r;

wire  [1:0]   SLADDR_w;
wire          SLOEn_w;
wire          SLCSn_w;
wire          SLRDn_w;
wire          SLWRn_w;
wire          PKTENDn_w;

reg           en_sP2_r, en_sP3_r;

wire  [31:0]  dpo2_dti_w;
wire          dpo2_full_w;
wire          dpo2_almst_full_w;
wire          dpo2_wr_w;
wire          dpo2_epty_w;
wire          dpo2_done_w;

wire  [31:0]  dpo3_dti_w;
wire          dpo3_full_w;
wire          dpo3_almst_full_w;
wire          dpo3_wr_w;
wire          dpo3_epty_w;
wire          dpo3_done_w;

wire  [31:0]  DQ_o_w;

usb_if_wrpr usb_if_wrpr(
  .clk_i              (clk_r),
  .rst_i              (rst_r),
  .wb_adr_o           (),
  .wb_dt_i            (16'd0),
  .wb_dt_o            (),
  .wb_we_o            (),
  .wb_stb_o           (),
  .wb_ack_i           (1'b0),
  .wb_cyc_o           (),
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
  .DQ_o               (DQ_o_w),
  
  .clk_dp2_wr_i       (clk_r),
  .dpo2_dti_i         (dpo2_dti_w),
  .dpo2_full_o        (dpo2_full_w),
  .dpo2_almst_full_o  (dpo2_almst_full_w),
  .dpo2_wr_i          (dpo2_wr_w),
  .dpo2_epty_o        (dpo2_epty_w),
  .dpo2_done_o        (dpo2_done_w),
  
  .clk_dp3_wr_i       (clk_r),
  .dpo3_dti_i         (dpo3_dti_w),
  .dpo3_full_o        (dpo3_full_w),
  .dpo3_almst_full_o  (dpo3_almst_full_w),
  .dpo3_wr_i          (dpo3_wr_w),
  .dpo3_epty_o        (dpo3_epty_w),
  .dpo3_done_o        (dpo3_done_w)
);

smartProducer sP_dp2(
  .clk_i              (clk_r),
  .rst_i              (rst_r),
  .en_i               (en_sP2_r),
  .done_i             (dpo2_done_w),
  .fifo_epty_i        (dpo2_epty_w),
  .fifo_full_i        (dpo2_full_w),
  .fifo_almst_full_i  (dpo2_almst_full_w),
  .fifo_wr_o          (dpo2_wr_w),
  .dtProd_o           (dpo2_dti_w)
);

smartProducer sP_dp3(
  .clk_i              (clk_r),
  .rst_i              (rst_r),
  .en_i               (en_sP3_r),
  .done_i             (dpo3_done_w),
  .fifo_epty_i        (dpo3_epty_w),
  .fifo_full_i        (dpo3_full_w),
  .fifo_almst_full_i  (dpo3_almst_full_w),
  .fifo_wr_o          (dpo3_wr_w),
  .dtProd_o           (dpo3_dti_w)
);

initial begin
  clk_r = 1'b1;
  rst_r = 1'b1;
  
  repeat(6) #5 clk_r = ~clk_r;
  rst_r = 1'b0;
  
  repeat(4000) #5 clk_r = ~clk_r;
  
  $finish;
end

initial begin
  FLAGA_r     <= 1'b1;
  FLAGB_r     <= 1'b1;
  FLAGC_r     <= 1'b1;
  FLAGD_r     <= 1'b1;
  en_sP2_r    <= 1'b0;
  en_sP3_r    <= 1'b0;
  
  #200
  @(posedge clk_r);
  en_sP2_r    <= 1'b1;
  en_sP3_r    <= 1'b1;
  
end

endmodule
