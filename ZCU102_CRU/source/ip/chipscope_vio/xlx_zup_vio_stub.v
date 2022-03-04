// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Fri Sep 10 14:48:43 2021
// Host        : pc0127025.ornl.gov running 64-bit CentOS Linux release 7.9.2009 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /home/yj6/ALICE/ZCU102_CRU/source/rtl/example_designs/xilinx_zultrascalep/core_sources/chipscope_vio/xlx_zup_vio_stub.v
// Design      : xlx_zup_vio
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu9eg-ffvb1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2020.2" *)
module xlx_zup_vio(clk, probe_in0, probe_in1, probe_in2, probe_in3, 
  probe_in4, probe_in5, probe_in6, probe_in7, probe_in8, probe_in9, probe_in10, probe_in11, 
  probe_in12, probe_in13, probe_in14, probe_in15, probe_in16, probe_in17, probe_out0, probe_out1, 
  probe_out2, probe_out3, probe_out4, probe_out5, probe_out6, probe_out7, probe_out8, probe_out9, 
  probe_out10, probe_out11, probe_out12, probe_out13, probe_out14, probe_out15)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[0:0],probe_in1[0:0],probe_in2[0:0],probe_in3[0:0],probe_in4[0:0],probe_in5[5:0],probe_in6[0:0],probe_in7[0:0],probe_in8[0:0],probe_in9[0:0],probe_in10[0:0],probe_in11[0:0],probe_in12[0:0],probe_in13[31:0],probe_in14[31:0],probe_in15[0:0],probe_in16[0:0],probe_in17[7:0],probe_out0[0:0],probe_out1[0:0],probe_out2[2:0],probe_out3[2:0],probe_out4[0:0],probe_out5[0:0],probe_out6[0:0],probe_out7[0:0],probe_out8[0:0],probe_out9[2:0],probe_out10[0:0],probe_out11[7:0],probe_out12[0:0],probe_out13[0:0],probe_out14[0:0],probe_out15[0:0]" */;
  input clk;
  input [0:0]probe_in0;
  input [0:0]probe_in1;
  input [0:0]probe_in2;
  input [0:0]probe_in3;
  input [0:0]probe_in4;
  input [5:0]probe_in5;
  input [0:0]probe_in6;
  input [0:0]probe_in7;
  input [0:0]probe_in8;
  input [0:0]probe_in9;
  input [0:0]probe_in10;
  input [0:0]probe_in11;
  input [0:0]probe_in12;
  input [31:0]probe_in13;
  input [31:0]probe_in14;
  input [0:0]probe_in15;
  input [0:0]probe_in16;
  input [7:0]probe_in17;
  output [0:0]probe_out0;
  output [0:0]probe_out1;
  output [2:0]probe_out2;
  output [2:0]probe_out3;
  output [0:0]probe_out4;
  output [0:0]probe_out5;
  output [0:0]probe_out6;
  output [0:0]probe_out7;
  output [0:0]probe_out8;
  output [2:0]probe_out9;
  output [0:0]probe_out10;
  output [7:0]probe_out11;
  output [0:0]probe_out12;
  output [0:0]probe_out13;
  output [0:0]probe_out14;
  output [0:0]probe_out15;
endmodule
