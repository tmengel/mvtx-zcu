////////////////////////////////////////////////////////////////////////////////
// Title        : mmcm_monitor_single_clock
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : mmcm_monitor_single_clock.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2017-11-18
// Last update  : 2017-11-18
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-Ultrascale
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: mmcm module to monitor a single clock.
//              3 instances of upcounter cdc are instantiated with TMR-ed
////////////////////////////////////////////////////////////////////////////////

module mmcm_monitor_single_clock
  #(parameter int READ_BIT_WIDTH = 16,
    parameter int BIT_WIDTH = 40,
    parameter int IS_SATURATING = 0,
    parameter int VERBOSE = 0,
    parameter int G_SEE_MITIGATION_TECHNIQUE = 1,
    parameter int G_MISMATCH_EN = 1,
    parameter int G_MISMATCH_REGISTERED = 0,
    parameter int G_ADDITIONAL_MISMATCH = 1,
    parameter int G_K_TMR = 3 // generic used for port size definition, DO NOT MODIFY IT
    )
   (
    input logic                  clkcnt_i,
    input logic                  rst_clkcnt_i,
    input logic                  clkread_i,
    input logic                  rst_clkread_i,
    input logic [G_K_TMR-1:0]    latch_counter_clkread_i,
    input logic [G_K_TMR-1:0]    reset_counter_clkread_i,
    output logic [READ_BIT_WIDTH-1:0] counter_value_clkread_a_o,
    output logic [READ_BIT_WIDTH-1:0] counter_value_clkread_b_o,
    output logic [READ_BIT_WIDTH-1:0] counter_value_clkread_c_o,
    output logic [G_K_TMR-1:0]   mismatch_clkread_o,
    output logic [G_K_TMR-1:0]   mismatch_2nd_clkread_o
    );

   logic [G_K_TMR-1:0][READ_BIT_WIDTH-1:0] counter_value_clkread_s;

   assign counter_value_clkread_a_o = counter_value_clkread_s[0];
   assign counter_value_clkread_b_o = counter_value_clkread_s[1];
   assign counter_value_clkread_c_o = counter_value_clkread_s[2];

   generate
      for (genvar i = 0; i<G_K_TMR; i++) begin : upcounter_cdc
         (* DONT_TOUCH = "true" *)
         upcounter_cdc #(
                         // Parameters
                         .READ_BIT_WIDTH        (READ_BIT_WIDTH),
                         .BIT_WIDTH             (BIT_WIDTH),
                         .IS_SATURATING         (IS_SATURATING),
                         .VERBOSE               (VERBOSE),
                         .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE),
                         .G_MISMATCH_EN         (G_MISMATCH_EN),
                         .G_MISMATCH_REGISTERED (G_MISMATCH_REGISTERED),
                         .G_ADDITIONAL_MISMATCH (G_ADDITIONAL_MISMATCH)
                         /*autoinstparam*/)
         upcounter_cdc (
                        // Outputs
                        .counter_value_clkread_o(counter_value_clkread_s[i]),
                        .mismatch_clkread_o     (mismatch_clkread_o[i]),
                        .mismatch_2nd_clkread_o (mismatch_2nd_clkread_o[i]),
                        // Inputs
                        .clkcnt_i               (clkcnt_i),
                        .rst_clkcnt_i           (rst_clkcnt_i),
                        .countup_clkcnt_i       (1'b1),
                        .clkread_i              (clkread_i),
                        .rst_clkread_i          (rst_clkread_i),
                        .latch_counter_clkread_i(latch_counter_clkread_i[i]),
                        .reset_counter_clkread_i(reset_counter_clkread_i[i])
                        /*autoinst*/);
      end
   endgenerate

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../" "../upcounter/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
