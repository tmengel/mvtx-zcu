// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
// Date        : Tue Dec 18 11:40:59 2018
// Host        : pisces running 64-bit Ubuntu 18.04.1 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/jschamba/ALICE/TestSystem/modules/mgt_test/source/ip/gtwizard_ultrascale_0_vio_0/gtwizard_ultrascale_0_vio_0_stub.v
// Design      : gtwizard_ultrascale_0_vio_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-1-c
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "vio,Vivado 2018.3" *)
module gtwizard_ultrascale_0_vio_0(clk, probe_in0, probe_in1, probe_in2, probe_in3, 
  probe_in4, probe_in5, probe_in6, probe_in7, probe_in8, probe_in9, probe_in10, probe_out0, 
  probe_out1, probe_out2, probe_out3, probe_out4, probe_out5)
/* synthesis syn_black_box black_box_pad_pin="clk,probe_in0[0:0],probe_in1[0:0],probe_in2[0:0],probe_in3[3:0],probe_in4[27:0],probe_in5[27:0],probe_in6[27:0],probe_in7[0:0],probe_in8[0:0],probe_in9[27:0],probe_in10[27:0],probe_out0[0:0],probe_out1[0:0],probe_out2[0:0],probe_out3[0:0],probe_out4[111:0],probe_out5[27:0]" */;
  input clk;
  input [0:0]probe_in0;
  input [0:0]probe_in1;
  input [0:0]probe_in2;
  input [3:0]probe_in3;
  input [27:0]probe_in4;
  input [27:0]probe_in5;
  input [27:0]probe_in6;
  input [0:0]probe_in7;
  input [0:0]probe_in8;
  input [27:0]probe_in9;
  input [27:0]probe_in10;
  output [0:0]probe_out0;
  output [0:0]probe_out1;
  output [0:0]probe_out2;
  output [0:0]probe_out3;
  output [111:0]probe_out4;
  output [27:0]probe_out5;
endmodule
