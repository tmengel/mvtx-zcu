// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Thu Jan 25 19:19:30 2018
// Host        : PCEPAIDVELURE running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               E:/prog/gitlab-runner/builds/4d6b20e9/0/alice-its-wp10-firmware/RUv1_Test/modules/wishbone/source/ip/system_management_wiz_0/system_management_wiz_0_stub.v
// Design      : system_management_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-1-c
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module system_management_wiz_0(daddr_in, den_in, di_in, dwe_in, do_out, drdy_out, 
  dclk_in, reset_in, busy_out, channel_out, eoc_out, eos_out, ot_out, user_supply1_alarm_out, 
  user_supply0_alarm_out, alarm_out)
/* synthesis syn_black_box black_box_pad_pin="daddr_in[7:0],den_in,di_in[15:0],dwe_in,do_out[15:0],drdy_out,dclk_in,reset_in,busy_out,channel_out[5:0],eoc_out,eos_out,ot_out,user_supply1_alarm_out,user_supply0_alarm_out,alarm_out" */;
  input [7:0]daddr_in;
  input den_in;
  input [15:0]di_in;
  input dwe_in;
  output [15:0]do_out;
  output drdy_out;
  input dclk_in;
  input reset_in;
  output busy_out;
  output [5:0]channel_out;
  output eoc_out;
  output eos_out;
  output ot_out;
  output user_supply1_alarm_out;
  output user_supply0_alarm_out;
  output alarm_out;
endmodule
