//-----------------------------------------------------------------------------
// Title          : mvtr_tb.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : mvtr_tb.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : mvtr_tb.v - multi voter test bench (for 8-bit data vectors)
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module mvtr_tb();

reg         rst_r;
reg   [3:0] A, B, C;
wire  [3:0] D_vtr;
wire        warn_w;

mvtr mvtr(
  .vtr_i  ({A, B, C}),
  .vtr_o  (D_vtr),
  .warn_o (warn_w)
);

initial begin
  rst_r = 1'b1;
  # 100
  rst_r = 1'b0;
  
  # 1000
  $finish;
end

initial begin
  A = 8'b0000;
  B = 8'b0000;
  C = 8'b0000;
  
  # 200
  A = 8'b1110;
  B = 8'b1110;
  C = 8'b0000;
  
  # 100
  A = 8'b1111;
  B = 8'b1111;
  C = 8'b0000;
  
  # 100
  A = 8'b1111;
  B = 8'b1111;
  C = 8'b1111;
  
  # 100
  A = 8'b0000;
  B = 8'b1111;
  C = 8'b1111;
  
  # 100
  A = 8'b0000;
  B = 8'b0000;
  C = 8'b1111;
  
  # 100
  A = 8'b0000;
  B = 8'b0000;
  C = 8'b0000;
end

initial begin
  $display("\t\ttime\tA\tB\tC\tD_vtr\twarn_w");
  $monitor("%d\t%b\t%b\t%b\t%b\t%b", $time, A, B, C, D_vtr, warn_w);
end

endmodule
