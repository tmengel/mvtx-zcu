//-----------------------------------------------------------------------------
// Title         : lane_fsm_tmr
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : lane_fsm_tmr.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// Example of 8 state-Moore machine given as example.
// is able to recognize two different sequences (S1, S2)
// FSM starts in IDLE and stays there until one of the two sequences header
// is recognized.
// At this stage the machine expects the sequence in input, else it goes to
// ERROR and then to idle.
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

(* DONT_TOUCH = "true" *) module lane_fsm_tmr
  #(
    parameter int                   IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter int                   STEPS_G = 32, // number of steps in each lane
    parameter logic [IO_SIZE_G-1:0] IDLE = 0,
                                    S1_A = 1,
                                    S1_B = 2,
                                    S1_C = 3,
                                    S2_A = 4,
                                    S2_B = 5,
                                    S2_C = 6,
                                    ERROR = 7,
    parameter logic [IO_SIZE_G-1:0] RESET_STATE_G = IDLE,
    parameter logic [IO_SIZE_G-1:0] DEFAULT_STATE_G = ERROR,
    parameter int                   LANE_MITIGATION_G = 3 // if 3 full TMR (including I/O) is applied, if 5 full TMR (with triple voter) is applied to the lanes.
    )(
      input logic clk_i, rst_i,
      (* DONT_TOUCH = "true" *) input logic [IO_SIZE_G-1:0] data_a_i, data_b_i, data_c_i,
      (* DONT_TOUCH = "true" *) output logic [IO_SIZE_G-1:0] data_o
      );

   localparam TMR_MULTIPLICITY_C = 3;

   // the intenal data in position i is the input of the step i.
   // the one in position STEPS_G is the output
   logic [IO_SIZE_G-1:0] data_internal_a_s [STEPS_G:0];
   logic [IO_SIZE_G-1:0] data_internal_b_s [STEPS_G:0];
   logic [IO_SIZE_G-1:0] data_internal_c_s [STEPS_G:0];

   // output data
   logic [IO_SIZE_G-1:0] data_internal_tmr_s [TMR_MULTIPLICITY_C-1:0];

   assign data_internal_a_s[0] = data_a_i;
   assign data_internal_b_s[0] = data_b_i;
   assign data_internal_c_s[0] = data_c_i;

   generate
      for (genvar i=0; i<STEPS_G; i++) begin
         if (LANE_MITIGATION_G == 3) begin
            step_fsm_tmr #(
                           // Parameters
                           .IO_SIZE_G        (IO_SIZE_G),
                           .IDLE               (IDLE),
                           .S1_A               (S1_A),
                           .S1_B               (S1_B),
                           .S1_C               (S1_C),
                           .S2_A               (S2_A),
                           .S2_B               (S2_B),
                           .S2_C               (S2_C),
                           .ERROR              (ERROR),
                           .RESET_STATE_G      (RESET_STATE_G),
                           .DEFAULT_STATE_G    (DEFAULT_STATE_G)
                           /*autoinstparam*/)
            step_fsm_tmr(
                 // Outputs
                 .data_a_o                   (data_internal_a_s[i+1]),
                 .data_b_o                   (data_internal_b_s[i+1]),
                 .data_c_o                   (data_internal_c_s[i+1]),
                 // Inputs
                 .clk_i                    (clk_i),
                 .rst_i                    (rst_i),
                 .data_a_i                   (data_internal_a_s[i]),
                 .data_b_i                   (data_internal_b_s[i]),
                 .data_c_i                   (data_internal_c_s[i])
                 /*autoinst*/);
         end // if (LANE_MITIGATION_G == 3)
         else if (LANE_MITIGATION_G == 5) begin
            step_fsm_tmr_triplevoter #(
                           // Parameters
                           .IO_SIZE_G        (IO_SIZE_G),
                           .IDLE               (IDLE),
                           .S1_A               (S1_A),
                           .S1_B               (S1_B),
                           .S1_C               (S1_C),
                           .S2_A               (S2_A),
                           .S2_B               (S2_B),
                           .S2_C               (S2_C),
                           .ERROR              (ERROR),
                           .RESET_STATE_G      (RESET_STATE_G),
                           .DEFAULT_STATE_G    (DEFAULT_STATE_G)
                           /*autoinstparam*/)
            step_fsm_tmr_triplevoter(
                 // Outputs
                 .data_a_o                   (data_internal_a_s[i+1]),
                 .data_b_o                   (data_internal_b_s[i+1]),
                 .data_c_o                   (data_internal_c_s[i+1]),
                 // Inputs
                 .clk_i                      (clk_i),
                 .rst_i                      (rst_i),
                 .data_a_i                   (data_internal_a_s[i]),
                 .data_b_i                   (data_internal_b_s[i]),
                 .data_c_i                   (data_internal_c_s[i])
                 /*autoinst*/);
         end // if (LANE_MITIGATION_G == 5)
      end
   endgenerate

   // output stage
   assign data_internal_tmr_s[0] = data_internal_a_s[STEPS_G];
   assign data_internal_tmr_s[1] = data_internal_b_s[STEPS_G];
   assign data_internal_tmr_s[2] = data_internal_c_s[STEPS_G];

   majority_voter_array#(
                         // Parameters
                         .K_MMR                 (TMR_MULTIPLICITY_C),
                         .MISMATCH_EN           (1'b0),
                         .N                     (IO_SIZE_G)
                         /*autoinstparam*/)
   voter_mismatch_array(
                        // Outputs
                        .mismatch_o     (),
                        .output_o       (data_o),
                        // Inputs
                        .assert_clk_i   (clk_i),
                        .assert_rst_i   (rst_i),
                        .input_i        (data_internal_tmr_s)
                        /*autoinst*/);


endmodule // lane_fsm_tmr

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "../mmr_registers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
