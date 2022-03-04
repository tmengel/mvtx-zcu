//-----------------------------------------------------------------------------
// Title         : step_fsm_hammingsec
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : step_fsm_hammingsec.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// Hamming encoded version of the step_fsm.sv state machine
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

module step_fsm_hammingsec
  #(parameter int IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter int                   HAMMING_PROTECTED_SIZE_G = 7, // size of the hamming protected vector
    parameter [IO_SIZE_G-1:0] IDLE = 0,
                                    S1_A = 1,
                                    S1_B = 2,
                                    S1_C = 3,
                                    S2_A = 4,
                                    S2_B = 5,
                                    S2_C = 6,
                                    ERROR = 7,
    parameter logic [IO_SIZE_G-1:0] RESET_STATE_G = IDLE,
    parameter logic [IO_SIZE_G-1:0] DEFAULT_STATE_G = ERROR
    )
   (input logic        clk_i, rst_i,
    (* DONT_TOUCH = "true" *) input logic [IO_SIZE_G-1:0]         data_i,
    output logic [IO_SIZE_G-1:0] data_o
    );

   // hamming import
   localparam int                   k = IO_SIZE_G+1;
   localparam int                   n = HAMMING_PROTECTED_SIZE_G;
   // import the encode_f function
   // `include "hamming_definitions.sv"
   `include "../hamming/includes/hamming_definitions.sv"

   // state re-definition
   localparam [HAMMING_PROTECTED_SIZE_G-1:0]     IDLE_H = encode_f({1'b0,IDLE}),
                                                 S1_A_H = encode_f({1'b0,S1_A}),
                                                 S1_B_H = encode_f({1'b0,S1_B}),
                                                 S1_C_H = encode_f({1'b0,S1_C}),
                                                 S2_A_H = encode_f({1'b0,S2_A}),
                                                 S2_B_H = encode_f({1'b0,S2_B}),
                                                 S2_C_H = encode_f({1'b0,S2_C}),
                                                 ERROR_H  = encode_f({1'b0,ERROR});

   // Declare state register
   logic [HAMMING_PROTECTED_SIZE_G-1:0]         next_state_s, actual_state_s, actual_state_corrected_s;

   // Sequential next state process (SRST)
   always_ff @(posedge clk_i) begin : p_update
      if (rst_i)
        actual_state_s <= encode_f({1'b0,RESET_STATE_G});
      else
        actual_state_s <= next_state_s;
   end

   // correction of hamming vector after register and before output
   h3_correct_n_k
     #(
       // Parameters
       .n                               (HAMMING_PROTECTED_SIZE_G),
       .k                               (k)
       /*autoinstparam*/)
   hamming_correct
     (
      // Outputs
      .hamming_corrected_o              (actual_state_corrected_s),
      .sec_o                            (),
      // Inputs
      .hamming_i                        (actual_state_s)
      /*autoinst*/);

   // combinatorial next state process
   always_comb  begin : p_next
      case (actual_state_corrected_s)
        IDLE_H:
          if (data_i == S1_A)
            next_state_s = S1_A_H;
          else if (data_i == S2_A)
            next_state_s = S2_A_H;
          else
            next_state_s = IDLE_H;

        ERROR_H:
          next_state_s = encode_f({1'b0,RESET_STATE_G});

        S1_A_H:
          if (S1_B == data_i)
            next_state_s = S1_B_H;
          else
            next_state_s = ERROR_H;
        S1_B_H:
          if (S1_C == data_i)
            next_state_s = S1_C_H;
          else
            next_state_s = ERROR_H;
        S1_C_H:
          if (IDLE == data_i)
            next_state_s = IDLE_H;
          else if (S1_A == data_i)
            next_state_s = S1_A_H;
          else if (S2_A == data_i)
            next_state_s = S2_A_H;
          else
            next_state_s = ERROR_H;

        S2_A_H:
          if (S2_B == data_i)
            next_state_s = S2_B_H;
          else
            next_state_s = ERROR_H;
        S2_B_H:
          if (S2_C == data_i)
            next_state_s = S2_C_H;
          else
            next_state_s = ERROR_H;
        S2_C_H:
          if (IDLE == data_i)
            next_state_s = IDLE_H;
          else if (S1_A == data_i)
            next_state_s = S1_A_H;
          else if (S2_A == data_i)
            next_state_s = S2_A_H;
          else
            next_state_s = ERROR_H;

        default: // default state for safety
          next_state_s = encode_f({1'b0,DEFAULT_STATE_G});
      endcase
   end

   // Output combinatorial process
   always_comb begin : p_output
      data_o = decode_f(actual_state_corrected_s);
   end

endmodule // step_fsm_hammingsec

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "../hamming/")
// verilog-library-extensions:(".v" ".h" ".sv")
// eval:(verilog-read-includes)
// End:
