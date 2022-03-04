////////////////////////////////////////////////////////////////////////////////
// Title        : Data Port IN FSM Test Bench
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : dpi_fsm_tb.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-2
// Last update  : 2015-12-2
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: This is the simple test bench to simulate the dpi_fsm module
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module dpi_fsm_tb();

reg           clk, rst;
reg           FLAGA;

reg           strt_r;
wire          done_w;
wire          SLRDn_w;
wire          dpi_wr_w;

dpi_fsm dpi_fsm(
  .clk_i            (clk),
  .rst_i            (rst),
  .strt_i           (strt_r),
  .done_o           (done_w),
  .FLAG_i           (FLAGA),
  .SLRDn_o          (SLRDn_w),
  .dpi_dt_i         (32'h8000FFFF),
  .dpi_dt_o         (),
  .dpi_full_i       (1'b0),
  .dpi_almst_full_i (1'b0),
  .dpi_wr_o         (dpi_wr_w)
);

initial begin
  clk           = 1'b1;
  rst           = 1'b1;
  
  repeat(6) #5 clk = ~clk;
  rst     = 1'b0;
  
  repeat(200) #5 clk = ~clk;
  
  $finish;
end

initial begin
  FLAGA         <= 1'b1;
  strt_r        <= 1'b0;
  
  #100
  @(posedge clk);
  FLAGA         <= 1'b0;
  #20
  @(posedge clk);
  strt_r        <= 1'b1;
  #10
  @(posedge clk);
  strt_r        <= 1'b0;
  #50
  @(posedge clk);
  FLAGA         <= 1'b0;
end

endmodule
