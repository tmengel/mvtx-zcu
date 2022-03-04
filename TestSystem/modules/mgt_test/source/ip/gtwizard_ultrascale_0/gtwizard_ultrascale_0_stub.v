// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Fri Jul 16 13:50:30 2021
// Host        : pc0127025.ornl.gov running 64-bit CentOS Linux release 7.9.2009 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /home/yj6/ALICE/TestSystem/modules/mgt_test/source/ip/gtwizard_ultrascale_0/gtwizard_ultrascale_0_stub.v
// Design      : gtwizard_ultrascale_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-1-c
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "gtwizard_ultrascale_0_gtwizard_top,Vivado 2020.2" *)
module gtwizard_ultrascale_0(gtwiz_userclk_tx_active_in, 
  gtwiz_userclk_rx_active_in, gtwiz_reset_clk_freerun_in, gtwiz_reset_all_in, 
  gtwiz_reset_tx_pll_and_datapath_in, gtwiz_reset_tx_datapath_in, 
  gtwiz_reset_rx_pll_and_datapath_in, gtwiz_reset_rx_datapath_in, 
  gtwiz_reset_rx_cdr_stable_out, gtwiz_reset_tx_done_out, gtwiz_reset_rx_done_out, 
  gtwiz_userdata_tx_in, gtwiz_userdata_rx_out, gtrefclk01_in, qpll1outclk_out, 
  qpll1outrefclk_out, drpaddr_in, drpclk_in, drpdi_in, drpen_in, drpwe_in, gthrxn_in, gthrxp_in, 
  rxprbscntreset_in, rxprbssel_in, rxusrclk_in, rxusrclk2_in, txprbsforceerr_in, 
  txprbssel_in, txusrclk_in, txusrclk2_in, drpdo_out, drprdy_out, gthtxn_out, gthtxp_out, 
  gtpowergood_out, rxoutclk_out, rxpmaresetdone_out, rxprbserr_out, rxprbslocked_out, 
  txoutclk_out, txpmaresetdone_out)
/* synthesis syn_black_box black_box_pad_pin="gtwiz_userclk_tx_active_in[0:0],gtwiz_userclk_rx_active_in[0:0],gtwiz_reset_clk_freerun_in[0:0],gtwiz_reset_all_in[0:0],gtwiz_reset_tx_pll_and_datapath_in[0:0],gtwiz_reset_tx_datapath_in[0:0],gtwiz_reset_rx_pll_and_datapath_in[0:0],gtwiz_reset_rx_datapath_in[0:0],gtwiz_reset_rx_cdr_stable_out[0:0],gtwiz_reset_tx_done_out[0:0],gtwiz_reset_rx_done_out[0:0],gtwiz_userdata_tx_in[447:0],gtwiz_userdata_rx_out[447:0],gtrefclk01_in[6:0],qpll1outclk_out[6:0],qpll1outrefclk_out[6:0],drpaddr_in[251:0],drpclk_in[27:0],drpdi_in[447:0],drpen_in[27:0],drpwe_in[27:0],gthrxn_in[27:0],gthrxp_in[27:0],rxprbscntreset_in[27:0],rxprbssel_in[111:0],rxusrclk_in[27:0],rxusrclk2_in[27:0],txprbsforceerr_in[27:0],txprbssel_in[111:0],txusrclk_in[27:0],txusrclk2_in[27:0],drpdo_out[447:0],drprdy_out[27:0],gthtxn_out[27:0],gthtxp_out[27:0],gtpowergood_out[27:0],rxoutclk_out[27:0],rxpmaresetdone_out[27:0],rxprbserr_out[27:0],rxprbslocked_out[27:0],txoutclk_out[27:0],txpmaresetdone_out[27:0]" */;
  input [0:0]gtwiz_userclk_tx_active_in;
  input [0:0]gtwiz_userclk_rx_active_in;
  input [0:0]gtwiz_reset_clk_freerun_in;
  input [0:0]gtwiz_reset_all_in;
  input [0:0]gtwiz_reset_tx_pll_and_datapath_in;
  input [0:0]gtwiz_reset_tx_datapath_in;
  input [0:0]gtwiz_reset_rx_pll_and_datapath_in;
  input [0:0]gtwiz_reset_rx_datapath_in;
  output [0:0]gtwiz_reset_rx_cdr_stable_out;
  output [0:0]gtwiz_reset_tx_done_out;
  output [0:0]gtwiz_reset_rx_done_out;
  input [447:0]gtwiz_userdata_tx_in;
  output [447:0]gtwiz_userdata_rx_out;
  input [6:0]gtrefclk01_in;
  output [6:0]qpll1outclk_out;
  output [6:0]qpll1outrefclk_out;
  input [251:0]drpaddr_in;
  input [27:0]drpclk_in;
  input [447:0]drpdi_in;
  input [27:0]drpen_in;
  input [27:0]drpwe_in;
  input [27:0]gthrxn_in;
  input [27:0]gthrxp_in;
  input [27:0]rxprbscntreset_in;
  input [111:0]rxprbssel_in;
  input [27:0]rxusrclk_in;
  input [27:0]rxusrclk2_in;
  input [27:0]txprbsforceerr_in;
  input [111:0]txprbssel_in;
  input [27:0]txusrclk_in;
  input [27:0]txusrclk2_in;
  output [447:0]drpdo_out;
  output [27:0]drprdy_out;
  output [27:0]gthtxn_out;
  output [27:0]gthtxp_out;
  output [27:0]gtpowergood_out;
  output [27:0]rxoutclk_out;
  output [27:0]rxpmaresetdone_out;
  output [27:0]rxprbserr_out;
  output [27:0]rxprbslocked_out;
  output [27:0]txoutclk_out;
  output [27:0]txpmaresetdone_out;
endmodule
