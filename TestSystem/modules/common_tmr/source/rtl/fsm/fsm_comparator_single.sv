//-----------------------------------------------------------------------------
// Title         : fsm_comparator_single
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : fsm_comparator_single.sv
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

module fsm_comparator_single
  #(
    parameter int                   IO_SIZE_G = 3, // number of bits interconnecting the fsms
    parameter int                   STEPS_G = 32, // number of steps in each lane
    parameter logic [IO_SIZE_G-1:0] IDLE = 0,
                                    ERROR = 7,
    parameter logic [IO_SIZE_G-1:0] RESET_STATE_G = IDLE,
    parameter logic [IO_SIZE_G-1:0] DEFAULT_STATE_G = ERROR
    )(
      input logic                 clk_i, rst_i,
      input logic [IO_SIZE_G-1:0] data_pattern_generator_i, data_fsm_i,
      output logic                error_state_o,
      output logic                error_mismatch_o);

   always_ff @(posedge clk_i) begin
      if (rst_i) begin
         error_state_o = 1'b0;
      end else begin
         error_state_o = (data_fsm_i == ERROR)? 1'b1 : 1'b0;
      end
   end

   always_ff @(posedge clk_i) begin
      if (rst_i) begin
         error_mismatch_o = 1'b0;
      end else begin
         error_mismatch_o = (data_pattern_generator_i == data_fsm_i)? 1'b0 : 1'b1;
      end
   end

endmodule // fsm_comparator_single

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
