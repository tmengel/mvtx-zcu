////////////////////////////////////////////////////////////////////////////////
// Title        : Radiation monitor
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : radiation_monitor.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-08-17
// Last update  : 2017-08-17
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-7
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: Wrapper for the DMR radiation monitor
///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

(* DONT_TOUCH = "true" *) module radiation_monitor_wrapper
  #(
    parameter int G_SINGLE_ARRAY_INPUT_SIZE = 16, // max size of the single mismatch array from a module
    parameter int G_MODULES_CONNECTED = 5, // number of modules connected
    parameter int G_OUTPUT_ARRAY_SIZE = 8,  // output array size (of the radiation monitor, double for wrapper)
    parameter int G_ADDITIONAL_MISMATCH = 1 //
    )
   (
    input logic                                                          clk_i, // clock input
    input logic                                                          rst_i, // synchronous reset input

    // inputs from different modules
    input logic [G_MODULES_CONNECTED-1:0][G_SINGLE_ARRAY_INPUT_SIZE-1:0] mismatch_i,
    input logic [G_MODULES_CONNECTED-1:0][G_SINGLE_ARRAY_INPUT_SIZE-1:0] mismatch_2nd_i,

    // fifo interface
    output logic                                                         fifo_writeclock_o,
    output logic                                                         fifo_write_o,
    output logic [2*G_OUTPUT_ARRAY_SIZE-1:0]                             fifo_data_o,
    input logic                                                          fifo_full_i
    );

   logic [1:0]                                                           fifo_write_s, fifo_writeclock_s;
   logic [G_MODULES_CONNECTED-1:0][G_SINGLE_ARRAY_INPUT_SIZE-1:0]        mismatch_2nd_s;

   assign fifo_write_o = (fifo_write_s == 2'b11) ? 1'b1 : 1'b0;
   assign fifo_writeclock_o = fifo_writeclock_s[0]; // clock from main

   generate

      if (G_ADDITIONAL_MISMATCH == 1)
        assign mismatch_2nd_s = mismatch_2nd_i;
      else
        assign mismatch_2nd_s = 'b0;

      for (genvar i=0; i<2; i++) begin
         (* DONT_TOUCH = "true" *) radiation_monitor
                    #(
                      // Parameters
                      .G_SINGLE_ARRAY_INPUT_SIZE(G_SINGLE_ARRAY_INPUT_SIZE),
                      .G_MODULES_CONNECTED(G_MODULES_CONNECTED),
                      .G_OUTPUT_ARRAY_SIZE(G_OUTPUT_ARRAY_SIZE),
                      .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                      /*autoinstparam*/)
         radiation_monitor_inst
                    (
                     // Outputs
                     .fifo_writeclock_o  (fifo_writeclock_s[i]),
                     .fifo_write_o       (fifo_write_s[i]),
                     .fifo_data_o        (fifo_data_o[i*G_OUTPUT_ARRAY_SIZE + G_OUTPUT_ARRAY_SIZE-1:i*G_OUTPUT_ARRAY_SIZE + 0]),
                     // Inputs
                     .clk_i              (clk_i),
                     .rst_i              (rst_i),
                     .mismatch_i         (mismatch_i),
                     .mismatch_2nd_i     (mismatch_2nd_s),
                     .fifo_full_i        (fifo_full_i)
                     /*autoinst*/);
      end
   endgenerate

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../" "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
