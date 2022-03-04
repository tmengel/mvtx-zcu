//-----------------------------------------------------------------------------
// Title         : majority_voter
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : majority_voter.sv
// Author        : Matteo Lupi  <matteo.lupi@cern.ch>
// Created       : 27.02.2017
// Last modified : 27.02.2017
//-----------------------------------------------------------------------------
// Description :
// Majority voter with K-modular redundancy
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
module majority_voter
  #(parameter int K_MMR                 = 3, // K value used for K-modular redundancy
    parameter int MISMATCH_EN           = 1, // if 1 warnign signal is generated
    parameter int G_ADDITIONAL_MISMATCH = 1, // if 1 generates an additional mismatch signal by using a second LUT
    parameter int G_MISMATCH_REGISTERED = 0 // if 1 the mismatch signal is latched
  )
  (input logic assert_clk_i, assert_rst_i, // since block is only combinatorial, Those Only used
  // for verification purposes
    (* DONT_TOUCH = "yes" *) input logic  input_i [K_MMR-1:0],
    output logic output_o,
    output logic mismatch_o,
    output logic mismatch_2nd_o
  );

   //functions ///////////////////////////////////////////////////////////////////
  function logic voter3(input logic  data_in [K_MMR-1:0]);
    return ((data_in[0] && data_in[1]) || (data_in[0] && data_in[2]) ||
            (data_in[1] && data_in[2]));
  endfunction // voter3

  function logic voter5(input logic  data_in [K_MMR-1:0]);
    return ((data_in[0] && data_in[1] && data_in[2]) || (data_in[0] && data_in[1] && data_in[3]) || (data_in[0] && data_in[1] && data_in[4]) ||
            (data_in[0] && data_in[2] && data_in[3]) || (data_in[0] && data_in[2] && data_in[4]) ||
            (data_in[0] && data_in[3] && data_in[4]) ||
            (data_in[1] && data_in[2] && data_in[3]) || (data_in[1] && data_in[2] && data_in[4]) ||
            (data_in[1] && data_in[3] && data_in[4]) ||
            (data_in[2] && data_in[3] && data_in[4]));
  endfunction // voter3

  function logic mismatch(input logic  data_in [K_MMR-1:0]);
    logic                 out, out_s;
    logic [K_MMR-1:0]     mismatch_array;

    out = (K_MMR==3) ? voter3(data_in) : voter5(data_in);

    for (int i = 0; i<K_MMR ;i++) begin
      if (data_in[i] != out)
        mismatch_array[i] = 1'b1;
      else
        mismatch_array[i] = 1'b0;
    end
    return |mismatch_array;
  endfunction // mismatch

  // voted value ///////////////////////////////////////////////////////////////////
  generate
    if (K_MMR == 3)
      assign output_o = voter3(input_i);
    else if (K_MMR == 5)
      assign output_o = voter5(input_i);
  endgenerate

  // mismatch warning //////////////////////////////////////////////////////////////
  logic mismatch_s, mismatch_2nd_s;

  generate
    if (K_MMR == 3)
      if (MISMATCH_EN)
        if (G_MISMATCH_REGISTERED) begin
          assign mismatch_s = mismatch(input_i);
          always_ff @(posedge assert_clk_i)
          if (assert_rst_i)
            mismatch_o <= 1'b0;
          else
            mismatch_o <= mismatch_s;
        end else
          assign mismatch_o = mismatch(input_i);
      else
        assign mismatch_o = 1'b0;
    else if (K_MMR == 5)
      if (MISMATCH_EN)
        if (G_MISMATCH_REGISTERED) begin
          assign mismatch_s = mismatch(input_i);
          always_ff @(posedge assert_clk_i)
          if (assert_rst_i)
            mismatch_o <= 1'b0;
          else
            mismatch_o <= mismatch_s;
        end else
          assign mismatch_o = mismatch(input_i);
      else
        assign mismatch_o = 1'b0;
  endgenerate

  generate
    if (K_MMR == 3)
      if (G_ADDITIONAL_MISMATCH)
        if (G_MISMATCH_REGISTERED) begin
          assign mismatch_2nd_s = mismatch(input_i);
          always_ff @(posedge assert_clk_i)
          if (assert_rst_i)
            mismatch_2nd_o <= 1'b0;
          else
            mismatch_2nd_o <= mismatch_2nd_s;
        end else
          assign mismatch_2nd_o = mismatch(input_i);
      else
        assign mismatch_2nd_o = 1'b0;
    else if (K_MMR == 5)
      if (G_ADDITIONAL_MISMATCH)
        if (G_MISMATCH_REGISTERED) begin
          assign mismatch_2nd_s = mismatch(input_i);
          always_ff @(posedge assert_clk_i)
          if (assert_rst_i)
            mismatch_2nd_o <= 1'b0;
          else
            mismatch_2nd_o <= mismatch_2nd_s;
        end else
          assign mismatch_2nd_o = mismatch(input_i);
      else
        assign mismatch_2nd_o = 1'b0;
  endgenerate

  // assertions ///////////////////////////////////////////////////////////////////
  // synthesis translate off
  majority_voter_assertions
     #(/*AUTOINSTPARAM*/
       // Parameters
    .K_MMR                 (K_MMR),
    .MISMATCH_EN           (MISMATCH_EN),
    .G_MISMATCH_REGISTERED (G_MISMATCH_REGISTERED))
  majority_voter_assertion_inst
  (.clk(assert_clk_i),
    .rst(assert_rst_i),
      .*
      /*AUTOINST*/);
  // synthesis translate on
endmodule // majority_voter

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/.")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
