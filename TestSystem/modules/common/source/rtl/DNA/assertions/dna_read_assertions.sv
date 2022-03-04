//-----------------------------------------------------------------------------
// Title         : dna_read
// Project       : PCv3
//-----------------------------------------------------------------------------
// File          : dna_read.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2016-11-29
// Last update  : 2016-11-29
// Platform     : Xilinx Vivado 2016.1
// Target       : Kintex-7
// Standard     : System Verilog
//-----------------------------------------------------------------------------
// Description : assertions for the dna_read block
//-----------------------------------------------------------------------------
// Copyright (c) 2016 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-02-22  1.0      ML            Created
//----------------------------------------------------------------------------

module dna_read_assertions (
                            input clk,
                            input rst,
                            input do_read_dna_i,
                            input do_read_dna_clk_dna_s
                            );

   import common_assertions::*;

   clocking cb@(posedge clk);
      input                                                do_read_dna_i, do_read_dna_clk_dna_s;
   endclocking // cb

   default clocking cb;

   //********************
   // Extra Property Definitions
   // ********************


   //********************
   // Assertions
   //********************
   // assert property(two_signals_if_first_then_second(.first_signal(cb.enable),
   // 						       .second_signal(),
   // 						       .disable_signal()))
   // 	else $error("");
   do_read_dna_clk_dna_s_4_cycle_high_assert:  assert property(check_duration_single_bit_atleast(.line(cb.do_read_dna_clk_dna_s),
								                                 .duration(16'd4),
								                                 .disable_signal(rst)))
     else $error("do_read_dna_clk_dna_s was not high long enough");

   //********************
   // Coverage
   //********************

   read_triggered:  cover property($rose(cb.do_read_dna_i));

endmodule // dna_read_assertions
