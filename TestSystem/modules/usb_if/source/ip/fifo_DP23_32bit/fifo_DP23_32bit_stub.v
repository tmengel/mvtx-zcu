// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
// Date        : Sat Mar  3 12:01:42 2018
// Host        : pisces running 64-bit Ubuntu Bionic Beaver (development branch)
// Command     : write_verilog -force -mode synth_stub
//               /home/jschamba/ALICE/RUv1_Test_clean/modules/usb_if/source/ip/fifo_DP23_32bit/fifo_DP23_32bit_stub.v
// Design      : fifo_DP23_32bit
// Purpose     : Stub declaration of top-level module interface
// Device      : xcku060-ffva1156-1-c
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_1,Vivado 2017.4" *)
module fifo_DP23_32bit(rst, wr_clk, rd_clk, din, wr_en, rd_en, dout, full, 
  almost_full, overflow, empty, almost_empty)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,dout[31:0],full,almost_full,overflow,empty,almost_empty" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [31:0]din;
  input wr_en;
  input rd_en;
  output [31:0]dout;
  output full;
  output almost_full;
  output overflow;
  output empty;
  output almost_empty;
endmodule
