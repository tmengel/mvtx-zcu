////////////////////////////////////////////////////////////////////////////////
// Title        : regnbit_1to3
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : regnbit_1to3.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2017-08-31
// Last update  : 2017-08-31
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: An N-bit connecting a single input (non TMR) to a TMR output
//
//              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the module is
//              protected:
//                      0   : no mitigation
//                      ~0: TMR with triplicated voter
////////////////////////////////////////////////////////////////////////////////

(* DONT_TOUCH = "true" *) module regnbit_1to3
  #(parameter int N = 32,
    parameter int MISMATCH_EN = 1,
    parameter int G_MISMATCH_REGISTERED = 0,
    parameter int G_SEE_MITIGATION_TECHNIQUE = 0,
    parameter int G_ADDITIONAL_MISMATCH = 1,
    parameter int G_K_TMR = 3 // generic used for port size definition, DO NOT MODIFY IT
    )
   (
    input logic         clk_i,
    input logic         rst_i,
    input logic         ce_i,
    input logic [N-1:0] data_i,
    (* DONT_TOUCH = "true" *) output logic [G_K_TMR-1:0][N-1:0] data_o,
    output logic        mismatch_o,
    output logic        mismatch_2nd_o
  );

   (* DONT_TOUCH = "true" *) reg  [G_K_TMR-1:0][N-1:0] data_s;
   generate
      genvar                          i;
      for (i = 0; i < G_K_TMR; i++) begin : register
         always_ff @(posedge clk_i) begin
            if (rst_i) begin
               data_s[i] <= 0;
            end else if(ce_i) begin
               data_s[i] <= data_i;
            end
         end
      end

      if (G_SEE_MITIGATION_TECHNIQUE == 0) begin
         assign data_o = data_s;
         assign mismatch_o = 1'b0;
         assign mismatch_2nd_o = 1'b0;
      end
      else begin // if (G_SEE_MITIGATION_TECHNIQUE == 0)
         majority_voter_triplicated_array
           #(
             // Parameters
             .K_MMR                 (G_K_TMR),
             .MISMATCH_EN           (MISMATCH_EN),
             .G_ADDITIONAL_MISMATCH (G_ADDITIONAL_MISMATCH),
             .G_MISMATCH_REGISTERED   (G_MISMATCH_REGISTERED),
             .N                     (N)
             /*autoinstparam*/)
         INST_majority_voter_triplicated_array_ACTUAL_STATE
           (
            // Outputs
            .output_o           (data_o),
            .mismatch_o         (mismatch_o),
            .mismatch_2nd_o     (mismatch_2nd_o),
            // Inputs
            .assert_clk_i       (clk_i),
            .assert_rst_i       (rst_i),
            .input_i            (data_s)
            /*autoinst*/);
      end // if (G_SEE_MITIGATION_TECHNIQUE == 3)
   endgenerate

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../" "../assertions/" "../../../../common_tmr/source/rtl/mmr_registers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
