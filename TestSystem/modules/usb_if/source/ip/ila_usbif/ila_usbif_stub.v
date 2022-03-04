// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (lin64) Build 1733598 Wed Dec 14 22:35:42 MST 2016
// Date        : Mon Feb  6 17:02:10 2017
// Host        : pcitsupgrade4.cern.ch running 64-bit CentOS Linux release 7.3.1611 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /afs/cern.ch/work/m/mbonora/private/git/test_itswp10/clean_checkout/firmware/RUv0a/source/ip/ila_usbif/ila_usbif_stub.v
// Design      : ila_usbif
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2016.4" *)
module ila_usbif(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13, probe14, probe15, probe16, probe17)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[31:0],probe1[0:0],probe2[0:0],probe3[0:0],probe4[0:0],probe5[0:0],probe6[0:0],probe7[0:0],probe8[0:0],probe9[1:0],probe10[0:0],probe11[0:0],probe12[0:0],probe13[0:0],probe14[0:0],probe15[31:0],probe16[31:0],probe17[0:0]" */;
  input clk;
  input [31:0]probe0;
  input [0:0]probe1;
  input [0:0]probe2;
  input [0:0]probe3;
  input [0:0]probe4;
  input [0:0]probe5;
  input [0:0]probe6;
  input [0:0]probe7;
  input [0:0]probe8;
  input [1:0]probe9;
  input [0:0]probe10;
  input [0:0]probe11;
  input [0:0]probe12;
  input [0:0]probe13;
  input [0:0]probe14;
  input [31:0]probe15;
  input [31:0]probe16;
  input [0:0]probe17;
endmodule
