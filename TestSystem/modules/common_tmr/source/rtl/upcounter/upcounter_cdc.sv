////////////////////////////////////////////////////////////////////////////////
// Title        : upcounter_cdc
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : upcounter_cdc.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2017-11-18
// Last update  : 2017-11-18
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-Ultrascale
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: Generic monitor counter embedding the upcounter (eventually
//              triplicated) with the latch and rst signal generally used for
//              monitoring via a wishbone slave.
//
//              Two clocks (and rst) have to be provided:
//                  clkcnt (clock counter): relative to the event to be monitored
//                  clkread (clock read): relative to the wishbone monitoring it
//
//              The counter can be eventually triplicated, mismatch signal is
//              referred to it.
////////////////////////////////////////////////////////////////////////////////

module upcounter_cdc
  #(parameter int READ_BIT_WIDTH = 16,
    parameter int BIT_WIDTH = 40,
    parameter int IS_SATURATING = 0,
    parameter int VERBOSE = 0,
    parameter int G_SEE_MITIGATION_TECHNIQUE = 1,
    parameter int G_MISMATCH_EN = 1,
    parameter int G_MISMATCH_REGISTERED = 0,
    parameter int G_ADDITIONAL_MISMATCH = 1
    )
   (
    input logic                       clkcnt_i,
    input logic                       rst_clkcnt_i,
    input logic                       countup_clkcnt_i,
    input logic                       clkread_i,
    input logic                       rst_clkread_i,
    input logic                       latch_counter_clkread_i,
    input logic                       reset_counter_clkread_i,
    output logic [READ_BIT_WIDTH-1:0] counter_value_clkread_o,
    output logic                      mismatch_clkread_o,
    output logic                      mismatch_2nd_clkread_o
    );

   logic                        latch_counter_clkcnt_s, reset_counter_clkcnt_s;
   logic [BIT_WIDTH-1:0]        counter_value_clkcnt_s;
   logic [READ_BIT_WIDTH-1:0]   counter_value_latched_clkcnt_s;
   logic                        mismatch_clkcnt_s, mismatch_2nd_clkcnt_s;

   //synthesis translate_off
   generate
      if (READ_BIT_WIDTH <= 0) begin
         $fatal(1, "Incorrect READ_BIT_WIDTH %d", READ_BIT_WIDTH);
      end
      if (BIT_WIDTH <= 0) begin
         $fatal(1, "Incorrect BIT_WIDTH %d", BIT_WIDTH);
      end
      if (READ_BIT_WIDTH > BIT_WIDTH) begin
         $fatal(1, "Incorrect BIT_WIDTH %d and READ_BIT_WIDTH %d", BIT_WIDTH, READ_BIT_WIDTH);
      end
   endgenerate

   //synthesis translate_on

   xpm_cdc_single #(//Common module parameters
                    .DEST_SYNC_FF   (2), // integer; range: 2-10
                    .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                    .SRC_INPUT_REG  (0)  // integer; 0=do not register input, 1=register input
                    )
   xpm_cdc_single_latch_inst (
                              .src_clk  (),  // optional; required when SRC_INPUT_REG = 1
                              .src_in   (latch_counter_clkread_i),
                              .dest_clk (clkcnt_i),
                              .dest_out (latch_counter_clkcnt_s)
                              );

   xpm_cdc_single #(//Common module parameters
                    .DEST_SYNC_FF   (2), // integer; range: 2-10
                    .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                    .SRC_INPUT_REG  (0)  // integer; 0=do not register input, 1=register input
                    )
   xpm_cdc_single_reset_inst (
                              .src_clk  (),  // optional; required when SRC_INPUT_REG = 1
                              .src_in   (reset_counter_clkread_i),
                              .dest_clk (clkcnt_i),
                              .dest_out (reset_counter_clkcnt_s)
                              );

   upcounter_tmr_wrapper #(
                           .BIT_WIDTH                 (BIT_WIDTH                 ),
                           .IS_SATURATING             (IS_SATURATING             ),
                           .VERBOSE                   (VERBOSE                   ),
                           .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE),
                           .G_MISMATCH_EN             (G_MISMATCH_EN             ),
                           .G_MISMATCH_REGISTERED     (G_MISMATCH_REGISTERED     ),
                           .G_ADDITIONAL_MISMATCH     (G_ADDITIONAL_MISMATCH     )
                           )
   upcounter_INST (
                   .CLK          (clkcnt_i),
                   .RST          (rst_clkcnt_i),
                   .RST_CNT      (reset_counter_clkcnt_s),
                   .CNT_UP       (countup_clkcnt_i),
                   .CNT_VALUE    (counter_value_clkcnt_s),
                   .MISMATCH     (mismatch_clkcnt_s),
                   .MISMATCH_2ND (mismatch_2nd_clkcnt_s)
                   );

   always_ff @(posedge clkcnt_i) begin
      if ((reset_counter_clkcnt_s == 1'b1) || (rst_clkcnt_i == 1'b1))
        counter_value_latched_clkcnt_s <= 'h0;
      else
        if (latch_counter_clkcnt_s)
          counter_value_latched_clkcnt_s <= counter_value_clkcnt_s[BIT_WIDTH-1:BIT_WIDTH-READ_BIT_WIDTH]; // Read only MSB
        else
          counter_value_latched_clkcnt_s <= counter_value_latched_clkcnt_s;
   end

   xpm_cdc_array_single #(
                          //Common module parameters
                          .DEST_SYNC_FF   (2), // integer; range: 2-10
                          .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                          .SRC_INPUT_REG  (0), // integer; 0=do not register input, 1=register input
                          .WIDTH          (READ_BIT_WIDTH)  // integer; range: 1-1024
                          )
   xpm_cdc_array_single_inst (
                              .src_clk  (),  // optional; required when SRC_INPUT_REG = 1
                              .src_in   (counter_value_latched_clkcnt_s),
                              .dest_clk (clkread_i),
                              .dest_out (counter_value_clkread_o)
                              );

   xpm_cdc_single #(//Common module parameters
                    .DEST_SYNC_FF   (2), // integer; range: 2-10
                    .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                    .SRC_INPUT_REG  (0)  // integer; 0=do not register input, 1=register input
                    )
   xpm_cdc_single_mismatch_inst (
                              .src_clk  (),  // optional; required when SRC_INPUT_REG = 1
                              .src_in   (mismatch_clkcnt_s),
                              .dest_clk (clkread_i),
                              .dest_out (mismatch_clkread_o)
                              );

   xpm_cdc_single #(//Common module parameters
                    .DEST_SYNC_FF   (2), // integer; range: 2-10
                    .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                    .SRC_INPUT_REG  (0)  // integer; 0=do not register input, 1=register input
                    )
   xpm_cdc_single_mismatch_2nd_inst (
                              .src_clk  (),  // optional; required when SRC_INPUT_REG = 1
                              .src_in   (mismatch_2nd_clkcnt_s),
                              .dest_clk (clkread_i),
                              .dest_out (mismatch_2nd_clkread_o)
                              );

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
