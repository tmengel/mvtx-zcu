//-----------------------------------------------------------------------------
// Title         : step_fsm
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : step_fsm.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
//
//
// 8 state-Moore machine given as example.
// It is able to recognize two different sequences (S1, S2)
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

module step_fsm
  #(parameter int IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter [IO_SIZE_G-1:0]      IDLE = 0,
    S1_A = 1,
    S1_B = 2,
    S1_C = 3,
    S2_A = 4,
    S2_B = 5,
    S2_C = 6,
    ERROR  = 7,
    parameter logic [IO_SIZE_G-1:0] RESET_STATE_G = IDLE,
    parameter logic [IO_SIZE_G-1:0] DEFAULT_STATE_G = ERROR
    )
   (input logic        clk_i, rst_i,
    (* DONT_TOUCH = "true" *) input logic [IO_SIZE_G-1:0]         data_i,
    output logic [IO_SIZE_G-1:0] data_o
    );

   // Declare state register
   (* DONT_TOUCH = "true" *) logic [IO_SIZE_G-1:0]         next_state_s, actual_state_s;

   // Sequential next state process (SRST)
   always_ff @(posedge clk_i) begin : p_update
      if (rst_i)
        actual_state_s <= RESET_STATE_G;
      else
        actual_state_s <= next_state_s;
   end

   next_state #(
                // Parameters
                .IO_SIZE_G              (IO_SIZE_G),
                .IDLE                   (IDLE),
                .S1_A                   (S1_A),
                .S1_B                   (S1_B),
                .S1_C                   (S1_C),
                .S2_A                   (S2_A),
                .S2_B                   (S2_B),
                .S2_C                   (S2_C),
                .ERROR                  (ERROR),
                .RESET_STATE_G          (RESET_STATE_G),
                .DEFAULT_STATE_G        (DEFAULT_STATE_G)
                /*autoinstparam*/)
   p_next(
          // Outputs
          .next_state_o                 (next_state_s),
          // Inputs
          .actual_state_i               (actual_state_s),
          .data_i                       (data_i)
          /*autoinst*/);

   // Output combinatorial process
   always_comb begin : p_output
      data_o = actual_state_s;
   end

endmodule // step_fsm

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
