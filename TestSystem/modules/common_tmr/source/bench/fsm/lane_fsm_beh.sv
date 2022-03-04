//-----------------------------------------------------------------------------
// Title         : lane_fsm behavioural
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : lane_fsm_beh.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 04.04.2017
// Last modified : 04.04.2017
//-----------------------------------------------------------------------------
// Description :
// behavioural model of the lane_fsm.sv in ../rtl/fsm
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

  module lane_fsm_beh
    #(
      parameter int                     IO_SIZE_G = 3,
      parameter int                     STEPS_G = 1,
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
        input logic                    clk_i, rst_i,
        input logic [IO_SIZE_G-1:0]  data_i,
        output logic [IO_SIZE_G-1:0] data_o,
        input logic                    correct_i
        );

   // Declare state register
   logic [IO_SIZE_G-1:0]             data_internal_s [STEPS_G:0];
   assign data_internal_s[0] = data_i;
   assign data_o = data_internal_s[STEPS_G];

   step_fsm #(
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
   last_step(
             // Outputs
             .data_o                   (data_internal_s[STEPS_G]),
             // Inputs
             .clk_i                    (clk_i),
             .rst_i                    (rst_i),
             .data_i                   (data_internal_s[STEPS_G-1])
             /*autoinst*/);

   generate
      if (STEPS_G != 1) begin
         always @(posedge clk_i) begin
            if (rst_i)
              data_internal_s <= {STEPS_G+1{RESET_STATE_G}};
            else begin
               data_internal_s[STEPS_G-1:1] <= data_internal_s[STEPS_G-2:0];
            end
         end
      end
   endgenerate

endmodule // lane_fsm_beh

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "../../rtl/fsm/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
