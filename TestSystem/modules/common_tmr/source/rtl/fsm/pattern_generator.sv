//-----------------------------------------------------------------------------
// Title         : pattern_generator
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : pattern_generator.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// pattern generator for the lane_fsm and dut_block. One pattern generator should
// be assigned to many different lanes to allow for recognition of damage on
// pattern generator
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module pattern_generator
  #(
    parameter int                     IO_SIZE_G = 3,
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
      input logic                  clk_i,
      input logic                  rst_i,
      output logic [IO_SIZE_G-1:0] data_o
      );

   localparam int                  SEQ_LEN_C = 2*6;
   localparam logic [IO_SIZE_G-1:0] data_sequence [SEQ_LEN_C-1:0] = {S1_C,S1_B,S1_A,S1_C,S1_B,S1_A,
                                                                     S2_C,S2_B,S2_A,S2_C,S2_B,S2_A};
   int                              position_int;

   always_ff @(posedge clk_i) begin
      if (rst_i) begin
         position_int = 0;
      end else begin
         position_int = (position_int == SEQ_LEN_C-1)? 0: position_int+1;
      end
   end

   always_ff @(posedge clk_i) begin
      if (rst_i) begin
         data_o = IDLE;
      end else begin
         data_o = data_sequence[position_int];
      end
   end

endmodule // pattern_generator

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
