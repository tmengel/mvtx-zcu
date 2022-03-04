////////////////////////////////////////////////////////////////////////////////
// Title        : Wishbone master (wbmstr.v) test bench
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : wbmstr_tb.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      : 2015-12-2
// Last update  : 2015-12-2
// Platform     : Xilinx Vivado 2015.3
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: This is the simple test bench to simulate the wbmstr module
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module wbmstr_tb();

reg           clk_r, rst_r;
wire  [11:0]  adr_w;
reg   [15:0]  dat_wb_in_r;
wire  [15:0]  dat_wb_out_w;
wire          we_w;
wire          stb_w;
reg           ack_r;
wire          cyc_w;
reg   [31:0]  dp0_dt_r;
reg           dp0_epty_r;
wire          dp0_rd_w;
wire  [31:0]  dp1_dt_w;
wire          dp1_full_w;
wire          dp1_wr_w;

wbmstr wbmstr(
  .clk_i      (clk_r),
  .rst_i      (rst_r),
  
  .adr_o      (adr_w),
  .dat_i      (dat_wb_in_r),
  .dat_o      (dat_wb_out_w),
  .we_o       (we_w),
  .stb_o      (stb_w),
  .ack_i      (ack_r),
  .cyc_o      (cyc_w),
  
  .dp0_dt_i   (dp0_dt_r),
  .dp0_epty_i (dp0_epty_r),
  .dp0_rd_o   (dp0_rd_w),
  
  .dp1_dt_o   (dp1_dt_w),
  .dp1_full_i (dp1_full_w),
  .dp1_wr_o   (dp1_wr_w)
);

fifo32x1024 fifo32x1024_DP1(
  .wr_clk       (clk_r),
  .rd_clk       (clk_r),
  .almost_full  (),
  .almost_empty (),
  .rst          (rst_r),
  .wr_en        (dp1_wr_w),
  .rd_en        (1'b0),
  .din          (dp1_dt_w),
  .dout         (),
  .full         (dp1_full_w),
  .empty        ()
);

// Only clock and reset in that process
initial begin
  clk_r = 1'b1;
  rst_r = 1'b1;
  
  repeat(4) #5 clk_r = ~clk_r;
  rst_r = 1'b0;
  
  repeat(100) #5 clk_r = ~clk_r;
  
  $finish;
end

// all others signals here
initial begin
  dat_wb_in_r <= 16'd0;
  ack_r       <= 1'b0;
  dp0_dt_r    <= 32'd0;
  dp0_epty_r  <= 1'b1;
  
  // write to the wishbone slave
  #50
  @(posedge clk_r);
  dp0_epty_r  <= 1'b0;
  
  #30
  @(posedge clk_r);
  dp0_dt_r    <= 32'h8000FFFF; // data=0xFFFF, addr=0x00, mod=0x00, write
  
  #10
  @(posedge clk_r);
  dp0_epty_r  <= 1'b1;
  
  #20
  @(posedge clk_r);
  ack_r       <= 1'b1;
  
  #10
  @(posedge clk_r);
  ack_r       <= 1'b0;
  
  // read from the wishbone slave
  #50
  @(posedge clk_r);
  dp0_epty_r  <= 1'b0;
  
  #30
  @(posedge clk_r);
  dp0_dt_r    <= 32'h010EAFAF; // data=0xAFAF, addr=0x0E, mod=0x01, read
  
  #10
  @(posedge clk_r);
  dp0_epty_r  <= 1'b1;
  
  #20
  @(posedge clk_r);
  ack_r       <= 1'b1;
  dat_wb_in_r <= 16'hABCD;
  
  #10
  @(posedge clk_r);
  ack_r       <= 1'b0;
  
end

endmodule
