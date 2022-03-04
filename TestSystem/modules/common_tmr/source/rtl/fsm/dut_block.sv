//-----------------------------------------------------------------------------
// Title         : dut_block
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : dut_block.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// dut block composed of a pattern generator every PATTERN_GENERATOR_FANOUT_G lane_fsm,
// and a comparator for every fsm.
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

(* DONT_TOUCH = "true" *) module dut_block
  #(
    parameter int IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter int STEPS_G = 32, // number of steps in each lane
    parameter int PATTERN_GENERATOR_FANOUT_G = 4, // number of lanes fed by the pattern generator
    parameter int TMR_COMPARATOR_G = 1, // if 1 the comparator is triplicated
    parameter int LANE_MITIGATION_G = 0 // lane mitigation technique used
    )(
      input logic clk_i, rst_i,
      (* DONT_TOUCH = "true" *) output logic [PATTERN_GENERATOR_FANOUT_G-1:0] error_state_o,
      (* DONT_TOUCH = "true" *) output logic [PATTERN_GENERATOR_FANOUT_G-1:0] error_mismatch_o
      );

   logic [IO_SIZE_G-1:0]                            pattern_generator_data_s;
   logic [IO_SIZE_G-1:0]                            data_out_s [PATTERN_GENERATOR_FANOUT_G-1:0];

   localparam logic [IO_SIZE_G-1:0]                 IDLE = 0,
                                                    S1_A = 1,
                                                    S1_B = 2,
                                                    S1_C = 3,
                                                    S2_A = 4,
                                                    S2_B = 5,
                                                    S2_C = 6,
                                                    ERROR = 7;
   localparam logic [IO_SIZE_G-1:0]                 RESET_STATE_G = IDLE;
   localparam logic [IO_SIZE_G-1:0]                 DEFAULT_STATE_G = ERROR;

   pattern_generator #(
                       // Parameters
                       .IO_SIZE_G       (IO_SIZE_G),
                       .IDLE            (IDLE),
                       .S1_A            (S1_A),
                       .S1_B            (S1_B),
                       .S1_C            (S1_C),
                       .S2_A            (S2_A),
                       .S2_B            (S2_B),
                       .S2_C            (S2_C),
                       .ERROR           (ERROR),
                       .RESET_STATE_G   (RESET_STATE_G),
                       .DEFAULT_STATE_G (DEFAULT_STATE_G)
                       /*autoinstparam*/)
   pattern_generator(
                     // Outputs
                     .data_o            (pattern_generator_data_s),
                     // Inputs
                     .clk_i             (clk_i),
                     .rst_i             (rst_i)
                     /*autoinst*/);

   generate
      for (genvar i=0; i<PATTERN_GENERATOR_FANOUT_G; i++) begin
         (* DONT_TOUCH = "true" *) lane_fsm #(
                                              // Parameters
                                              .IO_SIZE_G          (IO_SIZE_G),
                                              .STEPS_G            (STEPS_G),
                                              .IDLE               (IDLE),
                                              .S1_A               (S1_A),
                                              .S1_B               (S1_B),
                                              .S1_C               (S1_C),
                                              .S2_A               (S2_A),
                                              .S2_B               (S2_B),
                                              .S2_C               (S2_C),
                                              .ERROR              (ERROR),
                                              .RESET_STATE_G      (RESET_STATE_G),
                                              .DEFAULT_STATE_G    (DEFAULT_STATE_G),
                                              .LANE_MITIGATION_G(LANE_MITIGATION_G)
                                              /*autoinstparam*/)
         lane_fsm_i(
                    // Outputs
                    .data_o                   (data_out_s[i]),
                    // Inputs
                    .clk_i                    (clk_i),
                    .rst_i                    (rst_i),
                    .data_i                   (pattern_generator_data_s)
                    /*autoinst*/);

         (* DONT_TOUCH = "true" *) fsm_comparator #(
                          // Parameters
                          .IO_SIZE_G            (IO_SIZE_G),
                          .STEPS_G              (STEPS_G),
                          .TMR_COMPARATOR_G     (TMR_COMPARATOR_G),
                          .IDLE                 (IDLE),
                          .ERROR                (ERROR),
                          .RESET_STATE_G        (RESET_STATE_G),
                          .DEFAULT_STATE_G      (DEFAULT_STATE_G)
                          /*autoinstparam*/)
         fsm_comparator (
                         // Outputs
                         .error_state_o           (error_state_o[i]),
                         .error_mismatch_o        (error_mismatch_o[i]),
                         // Inputs
                         .clk_i                   (clk_i),
                         .rst_i                   (rst_i),
                         .data_pattern_generator_i(pattern_generator_data_s),
                         .data_fsm_i              (data_out_s[i])
                         /*autoinst*/);
      end
   endgenerate

endmodule // dut_block

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
