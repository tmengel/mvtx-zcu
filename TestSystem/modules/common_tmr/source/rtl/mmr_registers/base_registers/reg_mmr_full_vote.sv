//-----------------------------------------------------------------------------
// Title         : reg mmr full vote
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : reg_mmr_full_vote.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 01.03.2017
// Last modified : 01.03.2017
//-----------------------------------------------------------------------------
// Description :
// fully MMR register with K_MMR voters
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------
// Modification history :
// 01.03.2017 : created (ML)
//-----------------------------------------------------------------------------

`timescale 1ps/1ps

module reg_mmr_full_vote
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter int K_MMR_CLOCK = 1, // size of the clock input: if 1 then a single clock is provided to all the flop, if equal to K_MMR then multiple clocks are provided
    parameter bit MISMATCH_EN = 1'b1, // if 1 warnign signal is generated
    parameter bit RESET_VALUE = 1'b0
    )
   ((* DONT_TOUCH = "yes" *)input logic [K_MMR_CLOCK-1:0]  clk_i,
    input logic  rst_i,
    (* DONT_TOUCH = "yes" *) input logic D_i[K_MMR-1:0],
    output logic Q_o [K_MMR-1:0],
    output logic mismatch_o
    );

   logic                                  q_s       [K_MMR-1:0];
   logic                                  q_voted_s [K_MMR-1:0];
   logic [K_MMR-1:0]                      mismatch_s;

   generate
      genvar                              j;
      if (K_MMR_CLOCK==1) begin
         // generate K_MMR flops with the same clock
         always_ff @(posedge clk_i[0]) begin
            if (rst_i)
              q_s <= {K_MMR{RESET_VALUE}};
            else
              q_s <= D_i;
         end

      end else begin

         // generate K_MMR flops with different clocks
         for (j=0; j<K_MMR_CLOCK; j++) begin
            always_ff @(posedge clk_i[j])
              begin
                 if (rst_i)
                   q_s[j] <= RESET_VALUE;
                 else
                   q_s[j] <= D_i[j];
              end
         end
      end
   endgenerate

   generate
      genvar i;
      for (i=0; i<K_MMR; i++) begin
      (* DONT_TOUCH = "yes" *) majority_voter
        #(
          // Parameters
          .K_MMR              (K_MMR),
          .MISMATCH_EN        (MISMATCH_EN)
          /*AUTOINSTPARAM*/)
      majority_voter_inst
        (
         .assert_clk_i        (clk_i[0]),
         .assert_rst_i        (rst_i),
         // Inputs
         .input_i             (q_s),
         // Outputs
         .output_o            (q_voted_s[i]),
         .mismatch_o          (mismatch_s[i])
         /*AUTOINST*/);
      end
   endgenerate

   assign Q_o = q_voted_s;
   assign mismatch_o = |mismatch_s;
endmodule // reg_mmr_full_vote

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../assertions/." "../.")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
