//-----------------------------------------------------------------------------
// Title         : majority_voter_packed
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : majority_voter.sv
// Author        : Matteo Lupi  <matteo.lupi@cern.ch>
// Created       : 27.02.2017
// Last modified : 27.02.2017
//-----------------------------------------------------------------------------
// Description :
// Majority voter with K-modular redundancy (input is packed array for VHDL compatibility)
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of  and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 27.02.2017 : created (ML)
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

(* DONT_TOUCH = "yes" *)
module majority_voter_packed
     #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
       parameter int MISMATCH_EN = 1, // if 1 warnign signal is generated
       parameter int G_ADDITIONAL_MISMATCH = 1, // if 1 generates an additional mismatch signal by using a second LUT
       parameter int G_MISMATCH_REGISTERED = 0 // if 1 the mismatch signal is latched
       )
     (input logic assert_clk_i, assert_rst_i,  // since block is only combinatorial, Those Only used
    // for verification purposes
      (* DONT_TOUCH = "yes" *) input logic [K_MMR-1:0] input_i ,
                               output logic output_o,
                               output logic mismatch_o,
                               output logic mismatch_2nd_o
    );

   logic                                    input_s [K_MMR-1:0];

   for (genvar i=0; i<K_MMR; i++) begin : repack_input
      assign input_s[i] = input_i[i];
   end

   majority_voter #(// Parameters
                    .K_MMR                 (K_MMR),
                    .MISMATCH_EN           (MISMATCH_EN),
                    .G_MISMATCH_REGISTERED (G_MISMATCH_REGISTERED),
                    .G_ADDITIONAL_MISMATCH (G_ADDITIONAL_MISMATCH)
                    /*autoinstparam*/)
   majority_voter (// Outputs
                   .output_o        (output_o),
                   .mismatch_o      (mismatch_o),
                   .mismatch_2nd_o  (mismatch_2nd_o),
                   // Inputs
                   .assert_clk_i    (assert_clk_i),
                   .assert_rst_i    (assert_rst_i),
                   .input_i         (input_s)
                   /*autoinst*/);

endmodule // majority_voter

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/.")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
