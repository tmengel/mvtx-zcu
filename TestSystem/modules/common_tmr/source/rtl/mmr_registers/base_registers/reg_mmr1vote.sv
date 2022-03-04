//-----------------------------------------------------------------------------
// Title         : reg mmr1vote
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : reg_mmr1vote.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 01.03.2017
// Last modified : 01.03.2017
//-----------------------------------------------------------------------------
// Description :
// mmr register with a single voter and triple output
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module reg_mmr1vote
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter int K_MMR_CLOCK = 1, // size of the clock input: if 1 then a single clock is provided to all the flop, if equal to K_MMR then multiple clocks are provided
    parameter bit MISMATCH_EN = 1'b1, // if 1 warnign signal is generated
    parameter bit RESET_VALUE = 1'b0
    )
     ((* DONT_TOUCH = "yes" *)input logic [K_MMR_CLOCK-1:0] clk_i ,
     input logic  rst_i,
     (* DONT_TOUCH = "yes" *) input logic D_i [K_MMR-1:0],
     output logic Q_o [K_MMR-1:0],
     output logic mismatch_o
    );


   logic                                  q_s [K_MMR-1:0] ;
   logic                                  q_voted_s;

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

   majority_voter
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
      .output_o            (q_voted_s),
      .mismatch_o          (mismatch_o)
      /*AUTOINST*/);

   assign Q_o = {K_MMR{q_voted_s}};
endmodule // reg_mmr1vote

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../assertions/." "../.")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
