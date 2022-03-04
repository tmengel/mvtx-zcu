//-----------------------------------------------------------------------------
// Title         : mmr_register
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : mmr_register.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 01.03.2017
// Last modified : 01.03.2017
//-----------------------------------------------------------------------------
// Description :
// MMR register with different voting configurations
// reset is sync
// voting scheme:
//                 0: no voting, only valid input is [0], only used clock is [0]
//                 1: 1 single voter, output of voter is triplicated
//                 2: 1 single voter, output 0 is from voter, output 1:2 is from 0:1
//                 3: 3 voters
//
// In case of multiple clocks (i.e. K_MMR_CLOCK /= 1) the clock 0 is used for the assertions
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module mmr_register
    #(parameter int VOTING_SCHEME = -1, // voting scheme used in the register
    parameter int K_MMR = 3, // K value used for K-modular redundancy
    parameter int K_MMR_CLOCK = 1, // size of the clock input: if 1 then a single clock is provided to all the flop, if equal to K_MMR then multiple clocks are provided
    parameter int MISMATCH_EN = 1, // if 1 warnign signal is generated
    parameter int RESET_VALUE = 0 // reset value for the ff
    )
   (input logic [K_MMR_CLOCK-1:0] clk_i,
     input logic  rst_i,
     input logic  D_i [K_MMR-1:0],
     output logic Q_o [K_MMR-1:0],
     output logic mismatch_o
    );

   generate
      case(VOTING_SCHEME)
        0: begin
           reg_novote
             #(/*AUTOINSTParam*/
               // Parameters
               .K_MMR                   (K_MMR),
               .RESET_VALUE             (RESET_VALUE))
           reg_novote_inst
             (/*AUTOINST*/
              // Outputs
              .Q_o                      (Q_o),
              .mismatch_o               (mismatch_o),
              // Inputs
              .clk_i                    (clk_i[0]),
              .rst_i                    (rst_i),
              .D_i                      (D_i));
        end


        1: begin
           reg_mmr1vote
             #(/*AUTOINSTParam*/
               // Parameters
               .K_MMR_CLOCK             (K_MMR_CLOCK),
               .K_MMR                   (K_MMR),
               .MISMATCH_EN             (MISMATCH_EN),
               .RESET_VALUE             (RESET_VALUE))
           reg_mmr1vote_inst
             (/*AUTOINST*/
              // Outputs
              .Q_o                      (Q_o),
              .mismatch_o               (mismatch_o),
              // Inputs
              .clk_i                    (clk_i),
              .rst_i                    (rst_i),
              .D_i                      (D_i));
        end // case: 1


        2: begin
           reg_mmr_cross_vote
             #(/*AUTOINSTParam*/
               // Parameters
               .K_MMR_CLOCK             (K_MMR_CLOCK),
               .K_MMR                   (K_MMR),
               .MISMATCH_EN             (MISMATCH_EN),
               .RESET_VALUE             (RESET_VALUE))
           reg_mmr_cross_vote_inst
             (/*AUTOINST*/
              // Outputs
              .Q_o                      (Q_o),
              .mismatch_o               (mismatch_o),
              // Inputs
              .clk_i                    (clk_i),
              .rst_i                    (rst_i),
              .D_i                      (D_i));
        end // case: 2


        3: begin
           reg_mmr_full_vote
             #(/*AUTOINSTParam*/
               // Parameters
               .K_MMR_CLOCK             (K_MMR_CLOCK),
               .K_MMR                   (K_MMR),
               .MISMATCH_EN             (MISMATCH_EN),
               .RESET_VALUE             (RESET_VALUE))
           reg_mmr_full_vote_inst
             (/*AUTOINST*/
              // Outputs
              .Q_o                      (Q_o),
              .mismatch_o               (mismatch_o),
              // Inputs
              .clk_i                    (clk_i),
              .rst_i                    (rst_i),
              .D_i                      (D_i));
        end
      endcase
   endgenerate

   // assertions
   // synthesis translate off
   mmr_register_assertions
     #(/*AUTOINSTParam*/
       // Parameters
       .K_MMR_CLOCK             (K_MMR_CLOCK),
       .K_MMR                   (K_MMR),
       .MISMATCH_EN             (MISMATCH_EN),
       .VOTING_SCHEME           (VOTING_SCHEME),
       .RESET_VALUE             (RESET_VALUE))
   mmr_register_assertions_inst
     (/*AUTOINST*/
      // Outputs
      .Q_o                      (Q_o),
      .mismatch_o               (mismatch_o),
      // Inputs
      .clk                      (clk_i[0]),
      .rst                      (rst_i),
      .D_i                      (D_i));
   // synthesis translate on


endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "./base_registers/")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
