//-----------------------------------------------------------------------------
// Title         : fsm_comparator
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : fsm_comparator.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// FSM comparator.
// compares the data from pattern generator and last fsm of the lane.
// It asserts a mismatch error if the two do not match.
// It asserts an error state if the fsm is in error.
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module fsm_comparator
  #(
    parameter int                   IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter int                   STEPS_G = 1, // number of steps in each lane
    parameter int                   TMR_COMPARATOR_G = 0, // if 1 TMR of the comparator is implemented, in this case, the input a, b, and c are used
    parameter logic [IO_SIZE_G-1:0] IDLE = 0,
                                    ERROR = 7,
    parameter logic [IO_SIZE_G-1:0] RESET_STATE_G = IDLE,
    parameter logic [IO_SIZE_G-1:0] DEFAULT_STATE_G = ERROR
    )(
      input logic                 clk_i, rst_i,
      input logic [IO_SIZE_G-1:0] data_pattern_generator_i, data_fsm_i,
      output logic                error_state_o,
      output logic                error_mismatch_o);

   localparam int                 TMR_MULTIPLICITY_C = 3;
   logic                          error_state_s [TMR_MULTIPLICITY_C-1:0];
   logic                          error_mismatch_s [TMR_MULTIPLICITY_C-1:0];

   generate
      genvar                      i;
      if (TMR_COMPARATOR_G == 1'b1) begin
         for (i = 0; i<TMR_MULTIPLICITY_C; i++) begin

            (* DONT_TOUCH = "true" *) fsm_comparator_single #(
                                 // Parameters
                                 .IO_SIZE_G             (IO_SIZE_G),
                                 .STEPS_G               (STEPS_G),
                                 .IDLE                  (IDLE),
                                 .ERROR                 (ERROR),
                                 .RESET_STATE_G         (RESET_STATE_G),
                                 .DEFAULT_STATE_G       (DEFAULT_STATE_G)
                                 /*autoinstparam*/)
            fsm_comparator_single (
                                // Outputs
                                .error_state_o  (error_state_s[i]),
                                .error_mismatch_o(error_mismatch_s[i]),
                                // Inputs
                                .clk_i          (clk_i),
                                .rst_i          (rst_i),
                                .data_pattern_generator_i(data_pattern_generator_i),
                                   .data_fsm_i     (data_fsm_i)
                                /*autoinst*/);
         end // for (i = 0; i<TMR_MULTIPLICITY_C; i++)

         majority_voter#(
                         // Parameters
                         .K_MMR                 (TMR_MULTIPLICITY_C),
                         .MISMATCH_EN           (1'b0)
                         /*autoinstparam*/)
         voter_state(
                     // Outputs
                     .output_o          (error_state_o),
                     .mismatch_o        (),
                     // Inputs
                     .assert_clk_i      (clk_i),
                     .assert_rst_i      (rst_i),
                     .input_i           (error_state_s)
                     /*autoinst*/);

         majority_voter#(
                         // Parameters
                         .K_MMR                 (TMR_MULTIPLICITY_C),
                         .MISMATCH_EN           (1'b0)
                         /*autoinstparam*/)
         voter_mismatch(
                     // Outputs
                     .output_o          (error_mismatch_o),
                     .mismatch_o        (),
                     // Inputs
                     .assert_clk_i      (clk_i),
                     .assert_rst_i      (rst_i),
                     .input_i           (error_mismatch_s)
                        /*autoinst*/);

      end else begin
         fsm_comparator_single #(
                                 // Parameters
                                 .IO_SIZE_G             (IO_SIZE_G),
                                 .STEPS_G               (STEPS_G),
                                 .IDLE                  (IDLE),
                                 .ERROR                 (ERROR),
                                 .RESET_STATE_G         (RESET_STATE_G),
                                 .DEFAULT_STATE_G       (DEFAULT_STATE_G)
                                 /*autoinstparam*/)
         fsm_comparator_single (
                                // Outputs
                                .error_state_o  (error_state_o),
                                .error_mismatch_o(error_mismatch_o),
                                // Inputs
                                .clk_i          (clk_i),
                                .rst_i          (rst_i),
                                .data_pattern_generator_i(data_pattern_generator_i),
                                .data_fsm_i     (data_fsm_i)
                                /*autoinst*/);
      end
   endgenerate


endmodule // fsm_comparator

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "../mmr_registers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
