//-----------------------------------------------------------------------------
// Title         : majority_voter_triplicated
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : majority_voter_triplicated.sv
// Author        : Matteo Lupi  <matteo.lupi@cern.ch>
// Created       : 30.08.2017
// Last modified : 30.08.2017
//-----------------------------------------------------------------------------
// Description :
// K_MMR-modular redundant voter with
// std_logic_vector(K_MMR-1 downto 0) as input as and as output
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of  and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 01.03.2017 : created (ML)
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module majority_voter_triplicated
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter int MISMATCH_EN = 1, // if 1 warnign signal is generated
    parameter int G_MISMATCH_REGISTERED = 0, // mismatch is registered usign the assertion clock
    parameter int G_ADDITIONAL_MISMATCH = 1 // if 1 generates an additional mismatch signal by using a second LUT
    )
   (
    input logic  assert_clk_i, assert_rst_i,
    (* DONT_TOUCH = "true" *) input logic [K_MMR-1:0] input_i,
    output logic mismatch_o,
    output logic mismatch_2nd_o,
    (* DONT_TOUCH = "true" *) output logic [K_MMR-1:0] output_o
    );

   logic [K_MMR-1:0]         mismatch_s, mismatch_2nd_s;

   // voting
   genvar                       i;
   generate
      for(i=0; i<K_MMR; i++) begin : majority_voter
         (* DONT_TOUCH = "true" *) majority_voter_packed
            #(
              // Parameters
              .K_MMR                    (K_MMR),
              .MISMATCH_EN              (MISMATCH_EN),
              .G_MISMATCH_REGISTERED      (G_MISMATCH_REGISTERED),
              .G_ADDITIONAL_MISMATCH    (G_ADDITIONAL_MISMATCH)
              /*AUTOINSTPARAM*/)
         majority_voter_packed
            ( // Outputs
              .output_o      (output_o[i]),
              .mismatch_o    (mismatch_s[i]),
              .mismatch_2nd_o(mismatch_2nd_s[i]),
              // Inputs
              .assert_clk_i  (assert_clk_i),
              .assert_rst_i  (assert_rst_i),
              .input_i       (input_i)
              /*AUTOINST*/);
      end // for (i=0; i<N; i++)
   endgenerate

   assign mismatch_o = (mismatch_s == 'd0)? 1'b0: 1'b1;

   generate
      if (G_ADDITIONAL_MISMATCH)
        assign mismatch_2nd_o = (mismatch_2nd_s == 'd0)? 1'b0: 1'b1;
      else
        assign mismatch_2nd_o = 1'b0;
   endgenerate


endmodule // majority_voter_triplicated

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
