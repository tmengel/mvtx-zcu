//-----------------------------------------------------------------------------
// Title         : lane_fsm_hammingsec
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : lane_fsm_hammingsec.sv
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

(* DONT_TOUCH = "true" *) module lane_fsm_hammingsec
  #(
    parameter int                   IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter int                   HAMMING_PROTECTED_SIZE_G = 7, // size of the hamming protected vector
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
    parameter logic [IO_SIZE_G-1:0] DEFAULT_STATE_G = ERROR
    )(
      input logic clk_i, rst_i,
      (* DONT_TOUCH = "true" *) input logic [IO_SIZE_G-1:0] data_i,
      (* DONT_TOUCH = "true" *) output logic [IO_SIZE_G-1:0] data_o
      );

   // the intenal data in position i is the input of the step i.
   // the one in position STEPS_G is the output
   logic [IO_SIZE_G-1:0]           data_internal_s [STEPS_G:0];

   assign data_internal_s[0] = data_i;
   assign data_o = data_internal_s[STEPS_G];

   generate
      for (genvar i=0; i<STEPS_G; i++) begin
         step_fsm_hammingsec
                    #(
                      // Parameters
                      .IO_SIZE_G        (IO_SIZE_G),
                      .HAMMING_PROTECTED_SIZE_G(HAMMING_PROTECTED_SIZE_G),
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
         step(
              // Outputs
              .data_o                   (data_internal_s[i+1]),
              // Inputs
              .clk_i                    (clk_i),
              .rst_i                    (rst_i),
              .data_i                   (data_internal_s[i])
              /*autoinst*/);
      end
   endgenerate

endmodule // lane_fsm_hammingsec

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
