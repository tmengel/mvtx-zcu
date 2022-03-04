// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
// Date        : Tue Apr 18 15:23:40 2017
// Host        : pcphaiddt001 running 64-bit CentOS Linux release 7.3.1611 (Core)
// Command     : write_verilog -force -mode synth_stub
//               /afs/cern.ch/work/m/mlupi/work/git/RUv0_radtest/modules/common_tmr/source/ip/SEM_IP/SEM_IP_stub.v
// Design      : SEM_IP
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "sem_v4_1_7_x7_sem_controller,Vivado 2016.4" *)
module SEM_IP(status_heartbeat, status_initialization, 
  status_observation, status_correction, status_classification, status_injection, 
  status_essential, status_uncorrectable, monitor_txdata, monitor_txwrite, monitor_txfull, 
  monitor_rxdata, monitor_rxread, monitor_rxempty, inject_strobe, inject_address, icap_o, 
  icap_csib, icap_rdwrb, icap_i, icap_clk, icap_request, icap_grant, fecc_crcerr, fecc_eccerr, 
  fecc_eccerrsingle, fecc_syndromevalid, fecc_syndrome, fecc_far, fecc_synbit, fecc_synword)
/* synthesis syn_black_box black_box_pad_pin="status_heartbeat,status_initialization,status_observation,status_correction,status_classification,status_injection,status_essential,status_uncorrectable,monitor_txdata[7:0],monitor_txwrite,monitor_txfull,monitor_rxdata[7:0],monitor_rxread,monitor_rxempty,inject_strobe,inject_address[39:0],icap_o[31:0],icap_csib,icap_rdwrb,icap_i[31:0],icap_clk,icap_request,icap_grant,fecc_crcerr,fecc_eccerr,fecc_eccerrsingle,fecc_syndromevalid,fecc_syndrome[12:0],fecc_far[25:0],fecc_synbit[4:0],fecc_synword[6:0]" */;
  output status_heartbeat;
  output status_initialization;
  output status_observation;
  output status_correction;
  output status_classification;
  output status_injection;
  output status_essential;
  output status_uncorrectable;
  output [7:0]monitor_txdata;
  output monitor_txwrite;
  input monitor_txfull;
  input [7:0]monitor_rxdata;
  output monitor_rxread;
  input monitor_rxempty;
  input inject_strobe;
  input [39:0]inject_address;
  input [31:0]icap_o;
  output icap_csib;
  output icap_rdwrb;
  output [31:0]icap_i;
  input icap_clk;
  output icap_request;
  input icap_grant;
  input fecc_crcerr;
  input fecc_eccerr;
  input fecc_eccerrsingle;
  input fecc_syndromevalid;
  input [12:0]fecc_syndrome;
  input [25:0]fecc_far;
  input [4:0]fecc_synbit;
  input [6:0]fecc_synword;
endmodule
