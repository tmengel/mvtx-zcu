////////////////////////////////////////////////////////////////////////////////
// Title        : An N-bit register
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : regnbit.v
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-10-12
// Last update  : 2017-08-02
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: An N-bit register
//
//              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
//              protected:
//                      0: no mitigation
//                      1: TMR with single voter
////////////////////////////////////////////////////////////////////////////////

(* DONT_TOUCH = "true" *) module regnbit
  #(parameter int N = 32,
    parameter bit MISMATCH_EN = 1'b1,
    parameter bit MISMATCH_REGISTERED = 1'b1,
    parameter int G_SEE_MITIGATION_TECHNIQUE = 0,
    parameter bit G_ADDITIONAL_MISMATCH = 1'b1)
   (
    input logic          clk_i,
    input logic          rst_i,
    input logic          ce_i,
    input logic [N-1:0]  data_i,
    output logic [N-1:0] data_o,
    output logic         mismatch_o,
    output logic         mismatch_2nd_o
  );

   generate
      if (G_SEE_MITIGATION_TECHNIQUE == 0) begin
         always @(posedge clk_i) begin
            if (rst_i) begin
               data_o <= 0;
            end else if(ce_i) begin
               data_o <= data_i;
            end
         end
         assign mismatch_o = 1'b0;
         assign mismatch_2nd_o = 1'b0;
      end
      else // if (G_SEE_MITIGATION_TECHNIQUE == 0)
        if (G_SEE_MITIGATION_TECHNIQUE == 1) begin
           localparam C_K_TMR = 3;
           (* DONT_TOUCH = "true" *) reg  [C_K_TMR-1:0][N-1:0] data_s;
           genvar      i;

           for (i = 0; i < C_K_TMR; i++) begin
              always @(posedge clk_i) begin
                 if (rst_i) begin
                    data_s[i] <= 0;
                 end else if(ce_i) begin
                    data_s[i] <= data_i;
                 end
              end

           end

           // majority_voter_array #(
           //                        // Parameters
           //                        .K_MMR              (C_K_TMR),
           //                        .MISMATCH_EN        (MISMATCH_EN),
           //                        .MISMATCH_REGISTERED(MISMATCH_REGISTERED),
           //                        .N                    (<name_size>)
           //                        /*autoinstparam*/)
           // INST_majority_voter_array_<NAME> (
           //                                   // Outputs
           //                                   .output_o           (<name>_o),
           //                                   .mismatch_o         (mismatch_s[]),
           //                                   // Inputs
           //                                   .assert_clk_i       (clk_i),
           //                                   .assert_rst_i       (rst_i),
           //                                   .input_i            (<name>_s)
           //                                   /*autoinst*/);

           majority_voter_array #(
                                  // Parameters
                                  .K_MMR              (C_K_TMR),
                                  .MISMATCH_EN        (MISMATCH_EN),
                                  .G_ADDITIONAL_MISMATCH        (G_ADDITIONAL_MISMATCH),
                                  .MISMATCH_REGISTERED(MISMATCH_REGISTERED),
                                  .N                  (N)
                                  /*autoinstparam*/)
           INST_majority_voter_array_ACTUAL_STATE (
                                             // Outputs
                                                   .output_o           (data_o),
                                                   .mismatch_o         (mismatch_o),
                                                   .mismatch_2nd_o     (mismatch_2nd_o),
                                                   // Inputs
                                                   .assert_clk_i       (clk_i),
                                                   .assert_rst_i       (rst_i),
                                                   .input_i            (data_s)
                                                   /*autoinst*/);
        end
   endgenerate


endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../" "./assertions/" "../../../common_tmr/source/rtl/mmr_registers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
