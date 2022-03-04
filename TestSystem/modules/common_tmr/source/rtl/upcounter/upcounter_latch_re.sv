////////////////////////////////////////////////////////////////////////////////
// Title        : upcounter_latch_re
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : upcounter_latch_re.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2017-11-18
// Last update  : 2017-11-18
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-Ultrascale
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: Generic monitor counter embedding the upcounter (eventually
//              triplicated), it allows to monitoring the number or rising edges
//              of the monitored_i input singal. It supposed that the monitored
//              is a clk_i signal
////////////////////////////////////////////////////////////////////////////////

module upcounter_latch_re
  #(parameter int BIT_WIDTH = 5,
    parameter int IS_SATURATING = 0,
    parameter int VERBOSE = 0
    )
   (
    input logic                  clk_i,
    input logic                  rst_i,
    input logic                  monitored_i,
    input logic                  latch_counter_i,
    input logic                  reset_counter_i,
    output logic [BIT_WIDTH-1:0] counter_value_o
    );

   logic [BIT_WIDTH-1:0]        counter_value_s, counter_value_latched_s;
   logic                        monitored_d1, countup_s;

   //synthesis translate_off
   generate
      if (BIT_WIDTH <= 0) begin
         $fatal(1, "Incorrect BIT_WIDTH %d", BIT_WIDTH);
      end
   endgenerate
   //synthesis translate_on

   always_ff @ (posedge clk_i) begin
      monitored_d1 <= monitored_i;
   end

   assign countup_s = (monitored_i == 1'b1 & monitored_d1 == 1'b0)? 1'b1: 1'b0;

   upcounter_tmr_wrapper #(
                           .BIT_WIDTH                 (BIT_WIDTH                 ),
                           .IS_SATURATING             (IS_SATURATING             ),
                           .VERBOSE                   (VERBOSE                   ),
                           .G_SEE_MITIGATION_TECHNIQUE(1'b0),
                           .G_MISMATCH_EN             (1'b0             ),
                           .G_MISMATCH_REGISTERED     (1'b0     ),
                           .G_ADDITIONAL_MISMATCH     (1'b0     )
                           )
   upcounter_INST (
                   .CLK          (clk_i),
                   .RST          (rst_i),
                   .RST_CNT      (reset_counter_i),
                   .CNT_UP       (countup_s),
                   .CNT_VALUE    (counter_value_s),
                   .MISMATCH     (),
                   .MISMATCH_2ND ()
                   );

   always_ff @(posedge clk_i) begin
      if (rst_i == 1'b1 | reset_counter_i == 1'b1)
        counter_value_latched_s <= 'h0;
      else
        if (latch_counter_i)
          counter_value_latched_s <= counter_value_latched_s;
        else
          counter_value_latched_s <= counter_value_s;
   end

   assign counter_value_o = counter_value_latched_s;

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
