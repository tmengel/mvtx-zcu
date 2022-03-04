////////////////////////////////////////////////////////////////////////////////
// Title        :
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         :
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Created      :
// Last update  :
// Platform     :
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description:
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module fifo32x32_ecc_tb();

reg           clk100_r, rst100_r;//, clk40_r, rst40_r;

reg [31:0]  din;
reg         wr_en;
reg         rd_en;
reg         injectsbiterr;

wire [31:0] dout;
wire        full;
wire        almost_full;
wire        empty;
wire        almost_empty;
wire        sbiterr;
wire        dbiterr;

fifo32x32_ecc fifo32x32_ecc(
  .rst            (rst100_r),       // input wire rst
  .wr_clk         (clk100_r),       // input wire wr_clk
  .rd_clk         (clk100_r),       // input wire rd_clk
  .din            (din),            // input wire [31 : 0] din
  .wr_en          (wr_en),          // input wire wr_en
  .rd_en          (rd_en),          // input wire rd_en
  .injectsbiterr  (injectsbiterr),  // input wire injectsbiterr
  .dout           (dout),           // output wire [31 : 0] dout
  .full           (full),           // output wire full
  .almost_full    (almost_full),    // output wire almost_full
  .empty          (empty),          // output wire empty
  .almost_empty   (almost_empty),   // output wire almost_empty
  .sbiterr        (sbiterr),        // output wire sbiterr
  .dbiterr        (dbiterr)         // output wire dbiterr
);

initial begin
  clk100_r = 1'b1;
  rst100_r = 1'b1;
  
  repeat(20) #5 clk100_r = ~clk100_r;
  rst100_r = 1'b0;
  
  repeat(100) #5 clk100_r = ~clk100_r;
  
  $finish;
end

//initial begin
//  clk40_r = 1'b1;
//  rst40_r = 1'b1;
//  
//  repeat(5) #13 clk40_r = ~clk40_r;
//  rst40_r = 1'b0;
//  
//  repeat(100) #13 clk40_r = ~clk40_r;
//end

initial begin
  din           <= 32'd0;
  wr_en         <= 1'b0;
  rd_en         <= 1'b0;
  injectsbiterr <= 1'b0;
  
/*   #200
  @(posedge clk100_r);
  din           <= 32'hFFFFFFFF;
  wr_en         <= 1'b1;
  injectsbiterr <= 1'b1;
  
  #10
  @(posedge clk100_r);
  din           <= 32'hAAAAAAAA;
  wr_en         <= 1'b1;
  injectsbiterr <= 1'b0;
  
  #10
  @(posedge clk100_r);
  din           <= 32'd0;
  wr_en         <= 1'b0;
  injectsbiterr <= 1'b0;
  
  #100
  @(posedge clk100_r);
  rd_en         <= 1'b1;
  
  #20
  @(posedge clk100_r);
  rd_en         <= 1'b0;   */
  
  #200
  @(posedge clk100_r);
  din           <= 32'hFFFFFFFF;
  wr_en         <= 1'b1;
  
  #80
  @(posedge clk100_r);
  rd_en         <= 1'b1;
  
end

endmodule
