//-----------------------------------------------------------------------------
// Title         : majority_voter_triplicated_array
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : majority_voter_triplicated_array.sv
// Author        : Matteo Lupi  <matteo.lupi@cern.ch>
// Created       : 01.03.2017
// Last modified : 01.03.2017
//-----------------------------------------------------------------------------
// Description :
// N-width majority voter triplicated_array with K-modular redundancy
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of  and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 01.03.2017 : created (ML)
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module majority_voter_triplicated_array
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter int MISMATCH_EN = 1, // if 1 warnign signal is generated
    parameter int N = 2, // size of the voted triplicated_array
    parameter int G_MISMATCH_REGISTERED = 0, // mismatch is registered usign the assertion clock
    parameter int G_ADDITIONAL_MISMATCH = 1 // if 1 generates an additional mismatch signal by using a second LUT
    )
   (
    input logic  assert_clk_i, assert_rst_i,
    (* DONT_TOUCH = "yes" *) input logic [K_MMR-1:0][N-1:0] input_i,
    output logic mismatch_o,
    output logic mismatch_2nd_o,
    (* DONT_TOUCH = "yes" *) output logic [K_MMR-1:0][N-1:0] output_o
    );

   logic [N-1:0]         mismatch_s, mismatch_2nd_s;

   // inverts the packed and unpacked dimentions
   logic [N-1:0][K_MMR-1:0] reverse_input_s, reverse_output_s;
   genvar                   tmr_index, size_index;
   generate
      for (tmr_index=0; tmr_index<K_MMR; tmr_index++) begin : reverse_input_tmr_index
         for (size_index=0; size_index<N; size_index++) begin : reverse_input_size_index
            assign reverse_input_s[size_index][tmr_index]  = input_i[tmr_index][size_index];
            assign output_o[tmr_index][size_index]         = reverse_output_s[size_index][tmr_index];
         end
      end
   endgenerate

   // voting
   genvar                       i;
   generate
      for(i=0; i<N; i++) begin : voter
         majority_voter_triplicated
            #(
              // Parameters
              .K_MMR                    (K_MMR),
              .MISMATCH_EN              (MISMATCH_EN),
              .G_MISMATCH_REGISTERED      (G_MISMATCH_REGISTERED),
              .G_ADDITIONAL_MISMATCH    (G_ADDITIONAL_MISMATCH)
              /*AUTOINSTPARAM*/)
         majority_voter_triplicated
            ( // Outputs
              .output_o      (reverse_output_s[i]),
              .mismatch_o    (mismatch_s[i]),
              .mismatch_2nd_o(mismatch_2nd_s[i]),
              // Inputs
              .assert_clk_i  (assert_clk_i),
              .assert_rst_i  (assert_rst_i),
              .input_i       (reverse_input_s[i])
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


endmodule // majority_voter_triplicated_array

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
