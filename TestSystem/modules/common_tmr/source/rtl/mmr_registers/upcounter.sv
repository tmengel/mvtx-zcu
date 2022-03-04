//-----------------------------------------------------------------------------
// Title         : upcounter
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : upcounter.sv
// Author        : Matteo Lupi  <matte.lupi@cern.ch>
// Created       : 27.02.2017
// Last modified : 27.02.2017
//-----------------------------------------------------------------------------
// Description :
// upcounter
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 03.03.2017 : created (ML)
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module upcounter
  #(parameter int BIT_WIDTH = 16, // counter bit width
    parameter int IS_SATURATING = 0, // 1 if the counter saturates (displays a message if set in verbose mode)
    parameter int VERBOSE = 0,
    parameter int K_MMR = 1, // K value used for K-modular redundancy
    parameter int VOTING_SCHEME = -1, // voting scheme used in the register
    parameter int MISMATCH_EN = 1 // if 1 warnign signal is generated
    )
   (input logic clk_i, rst_i,
    input logic                  reset_counter_i, // single point of failure for the block: to be fixed
    input logic                  countup_i [K_MMR-1:0],
    output logic [BIT_WIDTH-1:0] counter_value_o [K_MMR-1:0],
    output logic                 mismatch_o);

   localparam bit [BIT_WIDTH-1:0]              RESET_VALUE_C = 0;
   (* dont_touch = "yes" *) logic [BIT_WIDTH-1:0] counter_feedback_s [K_MMR-1:0];
   (* dont_touch = "yes" *) logic [BIT_WIDTH-1:0] counter_updated_s [K_MMR-1:0];

   function logic update_counter_f(input logic [BIT_WIDTH-1:0] actual_value,
                                   input logic countup,
                                   input logic reset_counter
                                   );
      begin
         logic [BIT_WIDTH-1:0]                    next_value;
         if (reset_counter)
           next_value = RESET_VALUE_C;
         else begin
            if (countup) begin
               if (actual_value == ((2**BIT_WIDTH)-1)) begin
                  next_value = IS_SATURATING ? actual_value : 0;
                  // synthesis translate_off
                  if (VERBOSE == 1 && IS_SATURATING == 1)
                    $display("counter saturated! (Next time use VERBOSE==1'b0 if you don't want to see this message any longer)");
                  // synthesis translate_on
               end else
                 next_value = actual_value + 1;
            end else
              next_value = actual_value;
         end
         return next_value;
      end
   endfunction // update_counter_f

   // combinatorial logic, not voted
   generate
      for (genvar i=0; i<K_MMR; i++)
        assign counter_updated_s[i] = update_counter_f(counter_feedback_s[i], countup_i[i], (reset_counter_i||rst_i));
   endgenerate

   // sequential logic, can be voted depending on VOTING_SCHEME value
   mmr_register_array
     #(
       // Parameters
       .VOTING_SCHEME                   (VOTING_SCHEME),
       .K_MMR                           (K_MMR),
       .N                               (BIT_WIDTH),
       .MISMATCH_EN                     (MISMATCH_EN),
       .RESET_VALUE                     (RESET_VALUE_C)
       /*autoinstparam*/)
   mmr_register_array_counter
     (
      // Outputs
      .Q_o                              (counter_feedback_s),
      .mismatch_o                       (mismatch_o),
      // Inputs
      .clk_i                            (clk_i),
      .rst_i                            (rst_i),
      .D_i                              (counter_updated_s)
      /*autoinst*/);

   assign counter_value_o = counter_feedback_s;

endmodule // upcounter

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "./assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
