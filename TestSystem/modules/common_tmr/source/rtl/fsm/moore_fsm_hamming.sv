//-----------------------------------------------------------------------------
// Title         : moore_fsm
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : moore_fsm.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// Example of 4 state-Moore machine given as example, hamming encoded.
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module moore_fsm
    #(parameter int k = 4,    //localparam STATE_ENCODING_BITS_C = $clog2(STATE_NUMBER_C);
      parameter int n = 7)    //localparam STATE_ENCODING_HAMMING_BITS_C = (STATE_ENCODING_BITS_C <= 4) ? 7 : 15;
  (input logic        clk_i, rst_i,
   input logic        data_i,
   output logic [1:0] data_o
   );

   // import the encode_f function
   `include "../hamming/includes/hamming_definitions.sv"

   // Declare state register
   logic [1:0]        next_state_s, actual_state_s, actual_state_reg_s;

   // Declare states
   localparam
     STATE0 = encode_f(0),
     STATE1 = encode_f(1),
     STATE2 = encode_f(2),
     STATE3 = encode_f(3);

   // Declare reset and default state
   localparam RESET_STATE_C = STATE0;
   localparam DEFAULT_STATE_C = STATE0;

   // Declare default output
   localparam DEFAULT_OUTPUT_C = {2{1'b0}};

   // state encoding
   //localparam STATE_NUMBER_C = 4;
   //localparam STATE_ENCODING_BITS_C = $clog2(STATE_NUMBER_C);
   //localparam STATE_ENCODING_HAMMING_BITS_C = (STATE_ENCODING_BITS_C <= 4) ? 7 : 15;

   // Sequential next state process (SRST)
   always @(posedge clk_i) begin
      if (rst_i)
        actual_state_reg_s <= RESET_STATE_C;
      else
        actual_state_reg_s <= next_state_s;
   end

   // combinatorial next state process
   always @(*) begin
        case (actual_state_s)
          STATE0:
            next_state_s <= STATE1;
          STATE1:
            if (data_i)
              next_state_s <= STATE2;
            else
              next_state_s <= STATE1;
          STATE2:
            if (data_i)
              next_state_s <= STATE3;
            else
              next_state_s <= STATE1;
          STATE3:
            if (data_i)
              next_state_s <= STATE2;
            else
              next_state_s <= STATE3;

          default: // default state for safety
            next_state_s <= DEFAULT_STATE_C;
        endcase
   end

   h3_correct_n_k
     #(
       // Parameters
       .n                               (n),
       .k                               (k)
       /*autoinstparam*/)
   correct_module
     (
      // Outputs
      .hamming_corrected_o            (actual_state_s),
      .sec_o                          (),
      // Inputs
      .hamming_i                      (actual_state_reg_s)
      /*autoinst*/);


   // Output combinatorial process
     always @(actual_state_s) begin
        case (actual_state_s)
          STATE0:
            data_o = 2'b01;
          STATE1:
            data_o = 2'b10;
          STATE2:
            data_o = 2'b11;
          STATE3:
            data_o = 2'b00;

          default: // default state for safety
          data_o = DEFAULT_OUTPUT_C;
        endcase
     end

endmodule // moore_fsm

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "../hamming/")
// verilog-library-extensions:(".v" ".h" ".sv")
// eval:(verilog-read-includes)
// End:
