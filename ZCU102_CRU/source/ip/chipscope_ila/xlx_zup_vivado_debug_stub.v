// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Fri Sep  3 08:34:00 2021
// Host        : pc0127025.ornl.gov running 64-bit CentOS Linux release 7.9.2009 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /home/yj6/ALICE/gbt-fpga/example_designs/xilinx_zultrascalep/core_sources/chipscope_ila/xlx_zup_vivado_debug_stub.v
// Design      : xlx_zup_vivado_debug
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu9eg-ffvb1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2020.2" *)
module xlx_zup_vivado_debug(clk, probe0, probe1, probe2, probe3)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[83:0],probe1[115:0],probe2[0:0],probe3[0:0]" */;
  input clk;
  input [83:0]probe0;
  input [115:0]probe1;
  input [0:0]probe2;
  input [0:0]probe3;
endmodule
