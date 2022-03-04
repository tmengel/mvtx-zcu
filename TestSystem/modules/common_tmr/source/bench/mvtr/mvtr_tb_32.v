//-----------------------------------------------------------------------------
// Title          : mvtr_tb_32.v
// Project        : RUv0
//-----------------------------------------------------------------------------
// File           : mvtr_tb_32.v
// Author         : Krzysztof Marek Sielewicz <krzysztof.sielewicz@cern.ch>
// Created        : 12.04.2017
// Last modified  : 12.04.2017
//-----------------------------------------------------------------------------
// Description    : mvtr_tb_32.v -  multi voter test bench
//                                  (for 32-bit data vectors)
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
`timescale 1ns/100ps

module mvtr_tb_32();

reg   [31:0]  A, B, C;
wire  [31:0]  D_vtr;
wire          warn_w;

mvtr #(.M(3), .N(32)) mvtr(
  .vtr_i  ({A, B, C}),
  .vtr_o  (D_vtr),
  .warn_o (warn_w)
);

initial begin
  #1000
  $finish;
end

initial begin
  A = 32'h00000000;
  B = 32'h00000000;
  C = 32'h00000000;
  
  #100
  A = 32'h000000FF;
  B = 32'h000000FF;
  C = 32'h000000FF;
  
  #100
  A = 32'h1000;
  B = 32'h1100;
  C = 32'h0100;
end

initial begin
  $display("\t\ttime\tA\tB\tC\tD_vtr\twarn_w");
  $monitor("%d\t%h\t%h\t%h\t%h\t%h", $time, A, B, C, D_vtr, warn_w);
end

endmodule
