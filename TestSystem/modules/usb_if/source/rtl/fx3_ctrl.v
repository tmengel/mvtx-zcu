////////////////////////////////////////////////////////////////////////////////
// Title        : FX3 Controller Module
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : fx3_ctrl.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-11-20
// Last update  : 2015-11-20
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: The FX3 controller
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps

module fx3_ctrl #(parameter  GpifWidth = 32,
                  parameter  GpifCtlWidth = 13)
(
  input               clk_i,              // clock input
  input               rst_i,              // synchronous reset input

  // FX3 GPIFII Slave Fifo signals
  input               FLAGA_i,            // FLAGAn input
  input               FLAGB_i,            // FLAGBn input
  input               FLAGC_i,            // FLAGCn input
  input               FLAGD_i,            // FLAGDn input
  output      [1:0]   SLADDR_o,           // slave endpoint address output
  output              SLOEn_o,            // slave output enable
  output              SLCSn_o,            // slave chip select output
  output              SLRDn_o,            // slave read request output
  output              SLWRn_o,            // slave write request output
  output              PKTENDn_o,          // packet end output
  input       [GpifWidth-1:0]  DQ_i,               // GPIFII DQ input (from the FX3)
  output  reg [GpifWidth-1:0]  DQ_o,               // GPIFII DQ output (towards the FX3)

  // DP0 interface (fx3_ctrl writes data to the DP0)
  output      [GpifWidth-1:0]  dp0_dt_o,           // data port 0 data output
  input               dp0_full_i,         // data port 0 full input
  input               dp0_almst_full_i,   // data port 0 almost full input
  output              dp0_wr_o,           // data port 0 write output

  // DP1 interface (fx3_ctrl reades data from the DP1)
  input       [GpifWidth-1:0]  dpo1_dt_i,          // data port 1 data input
  input               dpo1_epty_i,        // data port 1 empty input
  input               dpo1_almst_epty_i,  // data port 1 almost empty input
  output              dpo1_rd_o,          // data port 1 read output

  // DP2 interface (fx3_ctrl reades data from the DP2)
  input       [GpifWidth-1:0]  dpo2_dt_i,          // data port 2 data input
  input               dpo2_epty_i,        // data port 2 empty input
  input               dpo2_almst_epty_i,  // data port 2 almost empty input
  output              dpo2_rd_o,          // data port 2 read output
  output              dpo2_done_o,        // data port 2 FSM done output

  // DP3 interface (fx3_ctrl reades data from the DP3)
  input       [GpifWidth-1:0]  dpo3_dt_i,          // data port 3 data input
  input               dpo3_epty_i,        // data port 3 empty input
  input               dpo3_almst_epty_i,  // data port 3 almost empty input
  output              dpo3_rd_o,          // data port 3 read output
  output              dpo3_done_o         // data port 3 FSM done output
);

wire  [1:0]   dpoMuxSel_w;
wire  [GpifWidth-1:0]  dpo1_dto_w, dpo2_dto_w, dpo3_dto_w;
localparam  DP1_MUX_SEL  = 2'd0,
            DP2_MUX_SEL  = 2'd1,
            DP3_MUX_SEL  = 2'd2;

// registered mux that selects a data port to be forwarded to the FX3
always @(posedge clk_i) begin
  if (rst_i) begin
    DQ_o <= 32'd0;
  end else begin
    case (dpoMuxSel_w)
      DP1_MUX_SEL:
        DQ_o <= dpo1_dto_w;
      DP2_MUX_SEL:
        DQ_o <= dpo2_dto_w;
      DP3_MUX_SEL:
        DQ_o <= dpo3_dto_w;
      default:
        DQ_o <= dpo1_dto_w;
    endcase
  end
end

reg FLAGA_r, FLAGB_r, FLAGC_r, FLAGD_r;

/// register the FLAGs and DQ_i
always @(posedge clk_i) begin
  if (rst_i) begin
    FLAGA_r <= 1'b0;
    FLAGB_r <= 1'b0;
    FLAGC_r <= 1'b0;
    FLAGD_r <= 1'b0;
  end else begin
    FLAGA_r <= FLAGA_i;
    FLAGB_r <= FLAGB_i;
    FLAGC_r <= FLAGC_i;
    FLAGD_r <= FLAGD_i;
  end
end

wire  [3:0] strt_w;
wire  [3:0] done_w;
wire  [2:0] SLWRn_w;
wire  [2:0] PKTENDn_w;

assign dpo2_done_o = done_w[2];
assign dpo3_done_o = done_w[3];

// the DP arbiter
dp_arbtr dp_arbtr(
  .clk_i        (clk_i),
  .rst_i        (rst_i),
  .strt_o       (strt_w),
  .done_i       (done_w),
  .SLWRn_i      (SLWRn_w),
  .PKTENDn_i    (PKTENDn_w),
  .SLADDR_o     (SLADDR_o),
  .SLOEn_o      (SLOEn_o),
  .SLCSn_o      (SLCSn_o),
  .SLWRn_o      (SLWRn_o),
  .PKTENDn_o    (PKTENDn_o),
  .dpoMuxSel_o  (dpoMuxSel_w)
);

// DP0
dpi_fsm dpi0(
  .clk_i            (clk_i),
  .rst_i            (rst_i),
  .strt_i           (strt_w[0]),
  .done_o           (done_w[0]),
  .FLAG_i           (FLAGA_r),
  .SLRDn_o          (SLRDn_o),
  .dpi_dt_i         (DQ_i),
  .dpi_dt_o         (dp0_dt_o),
  .dpi_full_i       (dp0_full_i),
  .dpi_almst_full_i (dp0_almst_full_i),
  .dpi_wr_o         (dp0_wr_o)
);

// DP1
dpo_fsm dpo1(
  .clk_i            (clk_i),
  .rst_i            (rst_i),
  .strt_i           (strt_w[1]),
  .done_o           (done_w[1]),
  .FLAG_i           (FLAGB_r),
  .SLWRn_o          (SLWRn_w[0]),
  .PKTENDn_o        (PKTENDn_w[0]),
  .dpo_dt_i         (dpo1_dt_i),
  .dpo_dt_o         (dpo1_dto_w),
  .dpo_epty_i       (dpo1_epty_i),
  .dpo_almst_epty_i (dpo1_almst_epty_i),
  .dpo_rd_o         (dpo1_rd_o)
);

// DP2
dpo_fsm dpo2(
  .clk_i            (clk_i),
  .rst_i            (rst_i),
  .strt_i           (strt_w[2]),
  .done_o           (done_w[2]),
  .FLAG_i           (FLAGC_r),
  .SLWRn_o          (SLWRn_w[1]),
  .PKTENDn_o        (PKTENDn_w[1]),
  .dpo_dt_i         (dpo2_dt_i),
  .dpo_dt_o         (dpo2_dto_w),
  .dpo_epty_i       (dpo2_epty_i),
  .dpo_almst_epty_i (dpo2_almst_epty_i),
  .dpo_rd_o         (dpo2_rd_o)
);

// DP3
dpo_fsm dpo3(
  .clk_i            (clk_i),
  .rst_i            (rst_i),
  .strt_i           (strt_w[3]),
  .done_o           (done_w[3]),
  .FLAG_i           (FLAGD_r),
  .SLWRn_o          (SLWRn_w[2]),
  .PKTENDn_o        (PKTENDn_w[2]),
  .dpo_dt_i         (dpo3_dt_i),
  .dpo_dt_o         (dpo3_dto_w),
  .dpo_epty_i       (dpo3_epty_i),
  .dpo_almst_epty_i (dpo3_almst_epty_i),
  .dpo_rd_o         (dpo3_rd_o)
);

endmodule
