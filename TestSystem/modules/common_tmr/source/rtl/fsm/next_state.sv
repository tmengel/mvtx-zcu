//-----------------------------------------------------------------------------
// Title         : next_state
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : next_state.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// next_state process in module to allow for keep
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
module next_state
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
   (
    (* DONT_TOUCH = "true" *) input logic [IO_SIZE_G-1:0]                 actual_state_i,
    (* DONT_TOUCH = "true" *) input logic [IO_SIZE_G-1:0]                 data_i,
    (* DONT_TOUCH = "true" *) output logic [IO_SIZE_G-1:0]                next_state_o
    );

   always_comb  begin : p_next
      case (actual_state_i)
        IDLE:
          if (data_i == S1_A)
            next_state_o = S1_A;
          else if (data_i == S2_A)
            next_state_o = S2_A;
          else
            next_state_o = IDLE;

        ERROR:
          next_state_o = RESET_STATE_G;

        S1_A:
          if (S1_B == data_i)
            next_state_o = S1_B;
          else
            next_state_o = ERROR;
        S1_B:
          if (S1_C == data_i)
            next_state_o = S1_C;
          else
            next_state_o = ERROR;
        S1_C:
          if (IDLE == data_i)
            next_state_o = IDLE;
          else if (S1_A == data_i)
            next_state_o = S1_A;
          else if (S2_A == data_i)
            next_state_o = S2_A;
          else
            next_state_o = ERROR;

        S2_A:
          if (S2_B == data_i)
            next_state_o = S2_B;
          else
            next_state_o = ERROR;
        S2_B:
          if (S2_C == data_i)
            next_state_o = S2_C;
          else
            next_state_o = ERROR;
        S2_C:
          if (IDLE == data_i)
            next_state_o = IDLE;
          else if (S1_A == data_i)
            next_state_o = S1_A;
          else if (S2_A == data_i)
            next_state_o = S2_A;
          else
            next_state_o = ERROR;

        default: // default state for safety
          next_state_o = DEFAULT_STATE_G;
      endcase
   end

endmodule // next_state


// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
