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
// voiting scheme:
//                 0: no voting, only valid input is 0
//                 1: 1 single voter, output of voter is triplicated
//                 2: 1 single voter, output 0 is from voter, output 1:2 is from 0:1
//                 3: 3 voters
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module top #(parameter int K_MMR = 5,
             parameter int K_TMR = 3,
             parameter bit MISMATCH_EN = 1'b1,
             parameter bit RESET_VALUE = 1'b0);

   logic                   clk = 1'b1;
   logic [0:0]             clk_single;
   logic [K_TMR-1:0]       clk_multi3;
   logic [K_MMR-1:0]       clk_multi5;
   logic                   rst_i = 1'b1;
   logic                   Q_0 [K_TMR-1:0];
   logic                   Q_1 [K_TMR-1:0];
   logic                   Q_2 [K_TMR-1:0];
   logic                   Q_3 [K_TMR-1:0];

   logic                   D_i [K_MMR-1:0] = {K_MMR{1'b0}};
   logic                   Q5_0 [K_MMR-1:0];
   logic                   Q5_1 [K_MMR-1:0];
   logic                   Q5_2 [K_MMR-1:0];
   logic                   Q5_3 [K_MMR-1:0];

   logic                   Q_1_multiclock [K_TMR-1:0];
   logic                   Q_2_multiclock [K_TMR-1:0];
   logic                   Q_3_multiclock [K_TMR-1:0];

   logic                   Q5_1_multiclock[K_MMR-1:0];
   logic                   Q5_2_multiclock[K_MMR-1:0];
   logic                   Q5_3_multiclock[K_MMR-1:0];


  clocking cb@(posedge clk);
     output          rst_i;
     output          D_i;
   endclocking // cb


   //////////////////////////////////////////////
   // wrappers
   //////////////////////////////////////////////

   // tmr_register_wrapper
   //   #(
   //     .MISMATCH_EN                     (MISMATCH_EN),
   //     .VOTING_SCHEME                   (3),
   //     .RESET_VALUE                     (RESET_VALUE))
   // tmr_register_wrapper_inst
   //   (
   //    .output_a  (output_a),
   //    .output_b  (output_b),
   //    .output_c  (output_c),
   //    .mismatch                       (mismatch),
   //    Inputs
   //    .clk                            (clk_single),
   //    .rst                            (rst_i),
   //    .input_a                              (D_i[0] ),
   //    .input_b                              (D_i[1] ),
   //    .input_c                              (D_i[2] )
   //    );

   // tmr_register_multiclock_wrapper
   //   #(
   //     .MISMATCH_EN                     (MISMATCH_EN),
   //     .VOTING_SCHEME                   (3),
   //     .RESET_VALUE                     (RESET_VALUE))
   // tmr_register_multiclock_wrapper_inst
   //   (
   //    .output_a                         (output_a),
   //    .output_b                         (output_b),
   //    .output_c                         (output_c),
   //    .mismatch                         (mismatch),
   //    Inputs
   //    .clk                              (clk_multi3),
   //    .rst                              (rst_i),
   //    .input_a                          (D_i[0] ),
   //    .input_b                          (D_i[1] ),
   //    .input_c                          (D_i[2] )
   //    );

   //////////////////////////////////////////////
   // Single Clock
   //////////////////////////////////////////////

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_TMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (0),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_novote3
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q_0),
      .mismatch_o                       (mismatch_0),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i[K_TMR-1:0] ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_TMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (1),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_1vote3
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q_1 ),
      .mismatch_o                       (mismatch_1),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i[K_TMR-1:0]));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_TMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (2),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_xvote3
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q_2 ),
      .mismatch_o                       (mismatch_2),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i[K_TMR-1:0] ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_TMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (3),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_3vote3
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q_3 ),
      .mismatch_o                       (mismatch_3),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i[K_TMR-1:0] ));


   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_MMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (0),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_novote5
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q5_0),
      .mismatch_o                       (mismatch_0),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                          (K_MMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (1),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_1vote5
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q5_1 ),
      .mismatch_o                       (mismatch_1),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_MMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (2),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_xvote5
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q5_2 ),
      .mismatch_o                       (mismatch_2),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_MMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (3),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_5vote5
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q5_3 ),
      .mismatch_o                       (mismatch_3),
      // Inputs
      .clk_i                            (clk_single),
      .rst_i                            (rst_i),
      .D_i                              (D_i ));

   //////////////////////////////////////////////
   // Multi Clock
   //////////////////////////////////////////////

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_TMR),
       .K_MMR_CLOCK                     (K_TMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (1),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_1vote3_multiclock
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q_1_multiclock),
      .mismatch_o                       (mismatch_1),
      // Inputs
      .clk_i                            (clk_multi3),
      .rst_i                            (rst_i),
      .D_i                              (D_i[K_TMR-1:0]));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_TMR),
       .K_MMR_CLOCK                     (K_TMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (2),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_xvote3_multiclock
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q_2_multiclock),
      .mismatch_o                       (mismatch_2),
      // Inputs
      .clk_i                            (clk_multi3),
      .rst_i                            (rst_i),
      .D_i                              (D_i[K_TMR-1:0] ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_TMR),
       .K_MMR_CLOCK                     (K_TMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (3),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_3vote3_multiclock
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q_3_multiclock),
      .mismatch_o                       (mismatch_3),
      // Inputs
      .clk_i                            (clk_multi3),
      .rst_i                            (rst_i),
      .D_i                              (D_i[K_TMR-1:0] ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_MMR),
       .K_MMR_CLOCK                     (K_MMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (1),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_1vote5_multiclock
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q5_1_multiclock),
      .mismatch_o                       (mismatch_1),
      // Inputs
      .clk_i                            (clk_multi5),
      .rst_i                            (rst_i),
      .D_i                              (D_i ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_MMR),
       .K_MMR_CLOCK                     (K_MMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (2),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_xvote5_multiclock
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q5_2_multiclock),
      .mismatch_o                       (mismatch_2),
      // Inputs
      .clk_i                            (clk_multi5),
      .rst_i                            (rst_i),
      .D_i                              (D_i ));

   mmr_register
     #(/*AUTOinstparam*/
       // Parameters
       .K_MMR                           (K_MMR),
       .K_MMR_CLOCK                     (K_MMR),
       .MISMATCH_EN                     (MISMATCH_EN),
       .VOTING_SCHEME                   (3),
       .RESET_VALUE                     (RESET_VALUE))
   mmr_register_tmr_5vote5_multiclock
     (/*autoinst*/
      // Outputs
      .Q_o                              (Q5_3_multiclock),
      .mismatch_o                       (mismatch_3),
      // Inputs
      .clk_i                            (clk_multi5),
      .rst_i                            (rst_i),
      .D_i                              (D_i ));

   ////////////////////////////////////////////////////////

   logic Q_i5 [K_MMR-1:0];
   logic Q_i3 [K_TMR-1:0];


      function bit majority(logic [K_MMR-1:0] data);
         begin
            if (K_MMR==3)
              return ((data[0]==data[1] && data[0]==1'b1) || (data[0]==data[2] && data[0]==1'b1) || (data[1]==data[2] && data[1]==1'b1));
            else if (K_MMR==5)
              return ((data[0]==data[1] && data[0]==data[2] && data[0]==1'b1) || (data[0]==data[1] && data[0]==data[3] && data[0]==1'b1) || (data[0]==data[1] && data[0]==data[4] && data[0]==1'b1) ||
                      (data[0]==data[2] && data[0]==data[3] && data[0]==1'b1) || (data[0]==data[2] && data[0]==data[4] && data[0]==1'b1) ||
                      (data[0]==data[3] && data[0]==data[4] && data[0]==1'b1) ||
                      (data[1]==data[2] && data[1]==data[3] && data[1]==1'b1) || (data[1]==data[2] && data[1]==data[4] && data[1]==1'b1) ||
                      (data[1]==data[3] && data[1]==data[4] && data[1]==1'b1) ||
                      (data[2]==data[3] && data[2]==data[4] && data[2]==1'b1)
                      );
         end
      endfunction // majority

   always @(posedge clk)
     if (rst_i)
       Q_i5 <= {K_MMR{RESET_VALUE}};
     else
       Q_i5 <= D_i;


   always @(posedge clk)
     if (rst_i)
       Q_i3 <= {K_TMR{RESET_VALUE}};
     else
       Q_i3 <= D_i[K_TMR-1:0];

   initial
     begin
        cb.rst_i <= 1'b1;
        clk = 1'b1;
        #1us;
        cb.rst_i <= 1'b0;
     end

   always
     #6ns assign clk = !clk;

   assign clk_single[0] = clk;
   assign clk_multi3 = {K_TMR{clk}};
   assign clk_multi5 = {K_MMR{clk}};

   initial
     begin
        logic [K_MMR-1:0] i;
        i=0;
        @(cb)
          cb.rst_i <= 1'b1;
        @(cb)
          cb.rst_i <= 1'b0;

        #1us;
        @(cb) cb.D_i <= {>> K_MMR{1'b1}};

        #1us;
        @(cb) cb.D_i <= {>> K_MMR{1'b0}};

        #1us;
        for(i=0; i<=2**K_MMR; i++)
          begin
             $display("%d", i);
             #100ns;
             @(cb) cb.D_i <= {>> K_MMR{i}};

             #100ns;
             @(cb) cb.D_i <= {>> K_MMR{{K_MMR{1'b0}}}};
          end

        $display("end of simulation!");
        $finish;
     end

endmodule // top
