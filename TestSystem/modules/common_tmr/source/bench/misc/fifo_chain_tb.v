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

module fifo_chain_tb();

reg         clk100_r, rst100_r;

reg [47:0] injectdbiterr_r;
reg [47:0] injectsbiterr_r;

fifo_lane_chn #(.N(32), .K(48), .M(3)) fifo_lane_chn(
  .clk_i            (clk100_r),
  .rst_i            (rst100_r),
  .injectdbiterr_i  (injectdbiterr_r),
  .injectsbiterr_i  (injectsbiterr_r),
  .sbiterr_o        (),
  .dbiterr_o        (),
  .pg_warn_o        (),
  .err_o            ()
);

initial begin
  clk100_r = 1'b1;
  rst100_r = 1'b1;
  
  repeat(20) #5 clk100_r = ~clk100_r;
  rst100_r = 1'b0;
  
  repeat(4000) #5 clk100_r = ~clk100_r;
  
  $finish;
end

initial begin
  injectdbiterr_r <= 48'd0;
  injectsbiterr_r <= 48'd0;
  
  #6000
  @(posedge clk100_r);
  injectdbiterr_r <= 48'd1;
  
  #10
  @(posedge clk100_r);
  injectdbiterr_r <= 48'd0;

end

endmodule
