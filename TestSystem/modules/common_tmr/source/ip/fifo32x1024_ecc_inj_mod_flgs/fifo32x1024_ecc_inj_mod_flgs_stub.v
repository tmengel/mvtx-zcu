// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4 (win64) Build 1412921 Wed Nov 18 09:43:45 MST 2015
// Date        : Mon Dec 05 22:12:35 2016
// Host        : KSIELEWIPC running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               P:/source/ip/fifo32x1024_ecc_inj_mod_flgs/fifo32x1024_ecc_inj_mod_flgs_stub.v
// Design      : fifo32x1024_ecc_inj_mod_flgs
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_0_1,Vivado 2015.4" *)
module fifo32x1024_ecc_inj_mod_flgs(rst, wr_clk, rd_clk, din, wr_en, rd_en, injectdbiterr, injectsbiterr, dout, full, almost_full, empty, almost_empty, prog_full, sbiterr, dbiterr)
/* synthesis syn_black_box black_box_pad_pin="rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,injectdbiterr,injectsbiterr,dout[31:0],full,almost_full,empty,almost_empty,prog_full,sbiterr,dbiterr" */;
  input rst;
  input wr_clk;
  input rd_clk;
  input [31:0]din;
  input wr_en;
  input rd_en;
  input injectdbiterr;
  input injectsbiterr;
  output [31:0]dout;
  output full;
  output almost_full;
  output empty;
  output almost_empty;
  output prog_full;
  output sbiterr;
  output dbiterr;
endmodule
