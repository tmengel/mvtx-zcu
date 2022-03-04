///////////////////////////////////////////////////////////////////////////////
// Title        : FX3 Controller Module
// Project      : Probecard
////////////////////////////////////////////////////////////////////////////////
// File         : usb_if_wrpr.sv
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Author       : Matteo Lupi <matteo.lupi@cern.ch>
// Company      : CERN / Goethe Universitaet Frankfurt am Main
// Created      : 2015-12-02
// Last update  : 2016-03-04
// Platform     : Xilinx Vivado 2015.4
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: The usb interface wrapper file including FIFOs, fx_ctrl
////////////////////////////////////////////////////////////////////////////////

module usb_if_wrpr #(
                     parameter int GpifCtlWidth = 13, // GPIF II CTL bus width
                     parameter int GpifWidth = 32, // GPIF II bus width
                     parameter int WbDataWidth = 16, // data bus width
                     parameter int G_SEE_MITIGATION_TECHNIQUE = 0,
                     parameter int MISMATCH_EN = 1,
                     parameter int MISMATCH_REGISTERED = 1
                     )
   (
                      input                    clk_i, // clock input
                      input                    rst_i, // synchronous reset input

                      // wishbone bus signals
                      input                    wb_clk, // wishbone clock coming from usb_if
                      input                    wb_rst, // wishbone reset to be passed to the master

                      // Wishbone interface
                      input                    WB_LATCH_WORDS_COUNT_DP2, // latch words counter
                      input                    WB_RST_WORDS_COUNT_DP2, // rst words counter
                      output [WbDataWidth-1:0] WB_WORDS_COUNT_LSB_DP2, // counter output
                      output [WbDataWidth-1:0] WB_WORDS_COUNT_MSB_DP2, // counter output

                      input                    WB_LATCH_RDWORDS_COUNT_DP2, // latch rdwords counter
                      input                    WB_RST_RDWORDS_COUNT_DP2, // rst rdwords counter
                      output [WbDataWidth-1:0] WB_RDWORDS_COUNT_LSB_DP2, // counter output
                      output [WbDataWidth-1:0] WB_RDWORDS_COUNT_MSB_DP2, // counter output

                      input                    WB_LATCH_OVFL_COUNT_DP2, // latch overflow counter
                      input                    WB_RST_OVFL_COUNT_DP2, // rst overflow counter
                      output [WbDataWidth-1:0] WB_OVFL_COUNT_DP2, // counter output

                      input                    WB_LATCH_FULL_COUNT_DP2, // latch overflow counter
                      input                    WB_RST_FULL_COUNT_DP2, // rst overflow counter
                      output [WbDataWidth-1:0] WB_FULL_COUNT_DP2, // counter output

                      input                    WB_LATCH_WORDS_COUNT_DP3, // latch words counter
                      input                    WB_RST_WORDS_COUNT_DP3, // rst words counter
                      output [WbDataWidth-1:0] WB_WORDS_COUNT_LSB_DP3, // counter output
                      output [WbDataWidth-1:0] WB_WORDS_COUNT_MSB_DP3, // counter output

                      input                    WB_LATCH_RDWORDS_COUNT_DP3, // latch rdwords counter
                      input                    WB_RST_RDWORDS_COUNT_DP3, // rst rdwords counter
                      output [WbDataWidth-1:0] WB_RDWORDS_COUNT_LSB_DP3, // counter output
                      output [WbDataWidth-1:0] WB_RDWORDS_COUNT_MSB_DP3, // counter output

                      input                    WB_LATCH_OVFL_COUNT_DP3, // latch overflow counter
                      input                    WB_RST_OVFL_COUNT_DP3, // rst overflow counter
                      output [WbDataWidth-1:0] WB_OVFL_COUNT_DP3, // counter output

                      input                    WB_LATCH_FULL_COUNT_DP3, // latch overflow counter
                      input                    WB_RST_FULL_COUNT_DP3, // rst overflow counter
                      output [WbDataWidth-1:0] WB_FULL_COUNT_DP3, // counter output

                      // FX3 GPIFII Slave Fifo signals
                      input                    FLAGA_i, // FLAGAn input
                      input                    FLAGB_i, // FLAGBn input
                      input                    FLAGC_i, // FLAGCn input
                      input                    FLAGD_i, // FLAGDn input
                      output [1:0]             SLADDR_o, // slave endpoint address output
                      output                   SLOEn_o, // slave output enable
                      output                   SLCSn_o, // slave chip select output
                      output                   SLRDn_o, // slave read request output
                      output                   SLWRn_o, // slave write request output
                      output                   PKTENDn_o, // packet end output
                      input [GpifWidth-1:0]    DQ_i, // GPIFII DQ input (from the FX3)
                      output [GpifWidth-1:0]   DQ_o, // GPIFII DQ output (towards the FX3)

                      // data port 0 FIFO (wbmstr receives data from that FIFO)
                      input                    dp0_rdclk_i, // dataport 0 read clock
                      output [GpifWidth-1:0]   dp0_dt_o, // data port 0 data
                      output                   dp0_epty_o, // data port 0 empty
                      input                    dp0_rd_i, // data port 0 read

                      // data port 1 FIFO (wbmstr writes data to that FIFO)
                      input                    dp1_wrclk_i, // dataport 1 write clock
                      input [GpifWidth-1:0]    dp1_dt_i, // data port 1 data
                      output                   dp1_full_o, // data port 1 full
                      input                    dp1_wr_i, // data port 1 write

                      // DP2 interface (fx3_ctrl reades data from the DP2)
                      input                    clk_dp2_wr_i, // clock input for DP2 FIFO
                      input [GpifWidth-1:0]    dpo2_dti_i, // data port 2 data input
                      output                   dpo2_full_o, // data port 2 full output
                      output                   dpo2_almst_full_o, // data port 2 almost full output
                      input                    dpo2_wr_i, // data port 2 write input
                      output                   dpo2_epty_o, // data port 2 empty flag output
                      output                   dpo2_done_o, // data port 2 FSM done output
                      input                    dpo2_rst_wrclk_i, // DP2 rst

                      // DP3 interface (fx3_ctrl reades data from the DP3)
                      input                    clk_dp3_wr_i, // clock input for DP3 FIFO
                      input [GpifWidth-1:0]    dpo3_dti_i, // data port 3 data input
                      output                   dpo3_full_o, // data port 3 full output
                      output                   dpo3_almst_full_o, // data port 3 almost full output
                      input                    dpo3_wr_i, // data port 3 write input
                      output                   dpo3_epty_o, // data port 3 empty flag output
                      output                   dpo3_done_o, // data port 3 FSM done output
                      input                    dpo3_rst_wrclk_i // DP3 rst
                      );

   wire [GpifWidth-1:0]             dpi0_dti_w;
   wire [GpifWidth-1:0]             dpi0_dto_w;
   wire                             dpi0_full_w;
   wire                             dpi0_almst_full_w;
   wire                             dpi0_wr_w;
   wire                             dpi0_epty_w;
   wire                             dpi0_almst_epty_w;
   wire                             dpi0_rd_w;

   wire [GpifWidth-1:0]             dpo1_dti_w;
   wire [GpifWidth-1:0]             dpo1_dto_w;
   wire                             dpo1_full_w;
   wire                             dpo1_almst_full_w;
   wire                             dpo1_wr_w;
   wire                             dpo1_epty_w;
   wire                             dpo1_almst_epty_w;
   wire                             dpo1_rd_w;

   wire [GpifWidth-1:0]             s_dpo2_dto;
   wire                             s_dpo2_epty;
   assign        dpo2_epty_o = s_dpo2_epty;
   wire                             s_dpo2_almst_epty;
   wire                             s_dpo2_rd;

   wire [GpifWidth-1:0]             s_dpo3_dto;
   wire                              s_dpo3_epty;
   assign        dpo3_epty_o = s_dpo3_epty;
   wire                              s_dpo3_almst_epty;
   wire                              s_dpo3_rd;

////////////////////////////////////////////////////////////////////////////////
// FIFO for DP0
fifo32x1024 fifo32x1024_DP0(
  .wr_clk       (clk_i),
  .rd_clk       (dp0_rdclk_i),
  .almost_full  (dpi0_almst_full_w),
  .almost_empty (dpi0_almst_epty_w),
  .rst          (rst_i),
  .wr_en        (dpi0_wr_w),
  .rd_en        (dp0_rd_i),
  .din          (dpi0_dti_w),
  .dout         (dp0_dt_o),
  .full         (dpi0_full_w),
  .empty        (dp0_epty_o)
);

////////////////////////////////////////////////////////////////////////////////
// FIFO for DP1
fifo32x1024 fifo32x1024_DP1(
  .wr_clk       (dp1_wrclk_i),
  .rd_clk       (clk_i),
  .almost_full  (dpo1_almst_full_w),
  .almost_empty (dpo1_almst_epty_w),
  .rst          (rst_i),
  .wr_en        (dp1_wr_i),
  .rd_en        (dpo1_rd_w),
  .din          (dp1_dt_i),
  .dout         (dpo1_dto_w),
  .full         (dp1_full_o),
  .empty        (dpo1_epty_w)
);

////////////////////////////////////////////////////////////////////////////////
// JS: FIFO for DP2 and DP3 not implemented here, use default values
   assign WB_WORDS_COUNT_LSB_DP2 = 16'd0;
   assign WB_WORDS_COUNT_MSB_DP2 = 16'd0;
   assign WB_RDWORDS_COUNT_LSB_DP2 = 16'd0;
   assign WB_RDWORDS_COUNT_MSB_DP2 = 16'd0;
   assign WB_OVFL_COUNT_DP2 = 16'd0;
   assign WB_FULL_COUNT_DP2 = 16'd0;

   assign WB_WORDS_COUNT_LSB_DP3 = 16'd0;
   assign WB_WORDS_COUNT_MSB_DP3 = 16'd0;
   assign WB_RDWORDS_COUNT_LSB_DP3 = 16'd0;
   assign WB_RDWORDS_COUNT_MSB_DP3 = 16'd0;
   assign WB_OVFL_COUNT_DP3 = 16'd0;
   assign WB_FULL_COUNT_DP3 = 16'd0;


////////////////////////////////////////////////////////////////////////////////
// FX3 controller
fx3_ctrl #(.GpifWidth(GpifWidth),
           .GpifCtlWidth(GpifCtlWidth))
   fx3_ctrl (
  .clk_i              (clk_i),
  .rst_i              (rst_i),
  // FX3 GPIF II BUS
  .FLAGA_i            (FLAGA_i),
  .FLAGB_i            (FLAGB_i),
  .FLAGC_i            (FLAGC_i),
  .FLAGD_i            (FLAGD_i),
  .SLADDR_o           (SLADDR_o),
  .SLOEn_o            (SLOEn_o),
  .SLCSn_o            (SLCSn_o),
  .SLRDn_o            (SLRDn_o),
  .SLWRn_o            (SLWRn_o),
  .PKTENDn_o          (PKTENDn_o),
  .DQ_i               (DQ_i),
  .DQ_o               (DQ_o),
  // DP0
  .dp0_dt_o           (dpi0_dti_w),
  .dp0_full_i         (dpi0_full_w),
  .dp0_almst_full_i   (dpi0_almst_full_w),
  .dp0_wr_o           (dpi0_wr_w),
  // DP1
  .dpo1_dt_i          (dpo1_dto_w),
  .dpo1_epty_i        (dpo1_epty_w),
  .dpo1_almst_epty_i  (dpo1_almst_epty_w),
  .dpo1_rd_o          (dpo1_rd_w),
  // DP2 // JS not implemented here
  .dpo2_dt_i          (32'd0),
  .dpo2_epty_i        (1'b1),
  .dpo2_almst_epty_i  (1'b1),
  .dpo2_rd_o          (s_dpo2_rd),
  .dpo2_done_o        (dpo2_done_o),
  // DP3 // JS not implemented here
  .dpo3_dt_i          (32'd0),
  .dpo3_epty_i        (1'b1),
  .dpo3_almst_epty_i  (1'b1),
  .dpo3_rd_o          (s_dpo3_rd),
  .dpo3_done_o        (dpo3_done_o)
);

endmodule
