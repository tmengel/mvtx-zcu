////////////////////////////////////////////////////////////////////////////////
// Title        : Radiation monitor single channel
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : radiation_monitor_single_channel.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2017-10-21
// Last update  : 2017-10-21
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-7
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: Radiation monitor for a single channel, rising edge detection
// and upcounter
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module radiation_monitor_single_channel
  #(
    parameter int G_COUNTER_WIDTH = 8, // output array size
    parameter int G_COUNTER_IS_SATURATING = 1  // describes if the counter is saturating
    )
   (
    input logic                       clk_i, // clock input
    input logic                       rst_i, // synchronous reset input

    // input from single module bit
    input logic                       mismatch_i,
    output logic [G_COUNTER_WIDTH-1:0] counter_o
    );

   logic                              mismatch_d1_s;
   logic                              cntup_s;
   logic 			      cntup_s_reg;

   always_ff @(posedge clk_i)
      if (rst_i)
         mismatch_d1_s <= 1'b0;
      else
        mismatch_d1_s <= mismatch_i;

   assign cntup_s = (mismatch_i == 1'b1 && mismatch_d1_s == 1'b0)? 1'b1: 1'b0;

   // register before using
   always_ff @(posedge clk_i)
      if (rst_i)
        cntup_s_reg <= 1'b0;
      else
        cntup_s_reg <= cntup_s;

   upcounter_tmr_wrapper #(
                           .BIT_WIDTH                  (G_COUNTER_WIDTH),
                           .IS_SATURATING              (G_COUNTER_IS_SATURATING),
                           .VERBOSE                    (1'b0),
                           .G_SEE_MITIGATION_TECHNIQUE (0),
                           .G_MISMATCH_EN              (1'b0),
                           .G_MISMATCH_REGISTERED      (1'b0),
                           .G_ADDITIONAL_MISMATCH      (1'b0)
                           )
   mismatch_counter_inst (
                          .CLK          (clk_i),
                          .RST          (rst_i),
                          .RST_CNT      (1'b0),
                          .CNT_UP       (cntup_s_reg),
                          .CNT_VALUE    (counter_o),
                          .MISMATCH     (),
                          .MISMATCH_2ND ()
                          );

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../" "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
