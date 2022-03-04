//------------------------------------------------------------------------------
// Title         : h3_correct_n_k_assertions.sv
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : h3_correct_n_k_assertions.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 28.03.2017
// Last modified : 28.03.2017
//-----------------------------------------------------------------------------
// Description :  assertion module for hamming correction block
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module h3_correct_n_k_assertions
  #(parameter int n = -1,
    parameter int k = -1,
    parameter int r = -1)
  (input bit [n-1:0] hamming_i,
   input bit [n-1:0] hamming_corrected_o,
   input bit         sec_o,
   input bit [r-1:0] syndrome_s
   );

   clocking cb@(posedge hamming_i);
      input          hamming_corrected_o;
      input          sec_o;
      input          syndrome_s;
   endclocking // cb
   default clocking cb;

   property n_k_are_consistent(int n, int k);
      (n == 15 && k == 11) || (n == 7 && k == 4);
   endproperty

   // assertions
   n_k_assert : assert property(n_k_are_consistent(.n(n), .k(k)));

   // coverage
   sec_rose_cov : cover property($rose(cb.sec_o));
   sec_fell_cov : cover property($fell(cb.sec_o));
endmodule // h3_correct_n_k_assertions
