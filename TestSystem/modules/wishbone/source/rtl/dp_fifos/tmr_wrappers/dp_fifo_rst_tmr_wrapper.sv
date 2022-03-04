///////////////////////////////////////////////////////////////////////////////
// Title        : dp_fifos_reset_tmr_wrapper module
// Project      : RUv1
////////////////////////////////////////////////////////////////////////////////
// File         : dp_fifos_reset.sv
// Author       : Matteo Lupi <matteo.lupi@cern.ch>
// Company      : CERN / Goethe Universitaet Frankfurt am Main
// Created      : 2018-05-03
// Last update  : 2018-05-03
// Platform     : Xilinx Vivado 2017.4
// Target       : Kintex-Ultrascale
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: Module handling the reset of the wishbone fifos (as from fifo
// generator manual v13.2 p128)
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps
(* DONT_TOUCH = "true" *) module dp_fifos_reset_tmr_wrapper
  #(
    parameter int FifoSyncStages = 3, // synch stages of the fifo
    parameter int StateBitWidth = 3, // number of state bits for the fifo
    parameter int G_K_TMR = 3
    )(
      input logic                      arst_i, // asynchronous reset input
      input logic                      slower_clk_i, // slower of the two clocks of the dp fifo

      input logic                      fifo_wr_reset_is_busy_i, // input from fifo
      input logic                      fifo_rd_reset_is_busy_i, // input from fifo

      output logic                     fifo_rst_o, // reset for the fifo with correct length (synch to clock)
      output logic                     fifo_rst_done_o, // when 1 fifo can be read/written

      output logic                     seeerr_sig_o, // SEE error
      output logic [StateBitWidth-1:0] actual_state_o,
      input logic [StateBitWidth-1:0]  actual_state_i
      );


   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0][StateBitWidth-1:0] actual_state_voted;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0][StateBitWidth-1:0] actual_state_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    we_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    stb_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    cyc_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    dp0_rd_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    dp1_wr_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    wrerr_sig_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    rderr_sig_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    ltchDtDP0_s;
   (* DONT_TOUCH = "true" *) logic  [G_K_TMR-1:0]                    ltchDtDP1_s;

   logic [G_K_TMR-1:0]                 seeerr_sig_s;
   localparam  logic [G_K_TMR-1:0]     C_SEEERR_SIG_NONE = {G_K_TMR{1'b0}};

   localparam int                      C_MISMATCH_SIZE = 10;
   localparam [C_MISMATCH_SIZE-1:0] C_MISMATCH_NONE = 'd0;
   logic [C_MISMATCH_SIZE-1:0]         mismatch_s, mismatch_2nd_s;

   for (genvar i = 0; i<G_K_TMR; i++) begin : inst_wbmstr

      (* DONT_TOUCH = "true" *) dp_fifos_reset #(
                                                 // Parameters
                                                 .FifoSyncStages        (FifoSyncStages),
                                                 .StateBitWidth         (StateBitWidth)
                                                 /*autoinstparam*/)
      dp_fifos_reset(
                     // Outputs
                     .fifo_rst_o        (fifo_rst_o),
                     .fifo_rst_done_o   (fifo_rst_done_o),
                     .seeerr_sig_o      (seeerr_sig_o),
                     .actual_state_o    (actual_state_o),
                     // Inputs
                     .arst_i            (arst_i),
                     .slower_clk_i      (slower_clk_i),
                     .fifo_wr_reset_is_busy_i(fifo_wr_reset_is_busy_i),
                     .fifo_rd_reset_is_busy_i(fifo_rd_reset_is_busy_i),
                     .actual_state_i    (actual_state_i)
                     /*autoinst*/);

   end

   // majority_voter_packed #(
   //                  // Parameters
   //                  .K_MMR              (G_K_TMR),
   //                  .MISMATCH_EN        (MISMATCH_EN),
   //                  .MISMATCH_REGISTERED(MISMATCH_REGISTERED)
   //                  /*autoinstparam*/)
   // INST_majority_voter_<NAME> (
   //                             // Outputs
   //                             .output_o           (<name>_o),
   //                             .mismatch_o         (mismatch_s[]),
   //                             // Inputs
   //                             .assert_clk_i       (clk_i),
   //                             .assert_rst_i       (rst_i),
   //                             .input_i            (<name>_s)
   //                             /*autoinst*/);

   majority_voter_triplicated #(
                                // Parameters
                                .K_MMR              (G_K_TMR),
                                .MISMATCH_EN        (MISMATCH_EN),
                                .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                                .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                                /*autoinstparam*/)
   INST_majority_voter_WE (
                           // Outputs
                           .output_o           (we_o),
                           .mismatch_o         (mismatch_s[0]),
                           .mismatch_2nd_o     (mismatch_2nd_s[0]),
                           // Inputs
                           .assert_clk_i       (clk_i),
                           .assert_rst_i       (rst_i),
                           .input_i            (we_s)
                           /*autoinst*/);

   majority_voter_triplicated #(
                                // Parameters
                                .K_MMR              (G_K_TMR),
                                .MISMATCH_EN        (MISMATCH_EN),
                                .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                                .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                                /*autoinstparam*/)
   INST_majority_voter_STB (
                            // Outputs
                            .output_o           (stb_o),
                            .mismatch_o         (mismatch_s[1]),
                            .mismatch_2nd_o     (mismatch_2nd_s[1]),
                            // Inputs
                            .assert_clk_i       (clk_i),
                            .assert_rst_i       (rst_i),
                            .input_i            (stb_s)
                            /*autoinst*/);

   majority_voter_triplicated #(
                                // Parameters
                                .K_MMR              (G_K_TMR),
                                .MISMATCH_EN        (MISMATCH_EN),
                                .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                                .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                                /*autoinstparam*/)
   INST_majority_voter_CYC (
                            // Outputs
                            .output_o           (cyc_o),
                            .mismatch_o         (mismatch_s[2]),
                            .mismatch_2nd_o     (mismatch_2nd_s[2]),
                            // Inputs
                            .assert_clk_i       (clk_i),
                            .assert_rst_i       (rst_i),
                            .input_i            (cyc_s)
                            /*autoinst*/);

   majority_voter_packed #(
                           // Parameters
                           .K_MMR              (G_K_TMR),
                           .MISMATCH_EN        (MISMATCH_EN),
                           .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           /*autoinstparam*/)
   INST_majority_voter_DP0_RD (
                               // Outputs
                               .output_o           (dp0_rd_o),
                               .mismatch_o         (mismatch_s[3]),
                               .mismatch_2nd_o     (mismatch_2nd_s[3]),
                               // Inputs
                               .assert_clk_i       (clk_i),
                               .assert_rst_i       (rst_i),
                               .input_i            (dp0_rd_s)
                               /*autoinst*/);

   majority_voter_packed #(
                           // Parameters
                           .K_MMR              (G_K_TMR),
                           .MISMATCH_EN        (MISMATCH_EN),
                           .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           /*autoinstparam*/)
   INST_majority_voter_DP1_WR (
                               // Outputs
                               .output_o           (dp1_wr_o),
                               .mismatch_o         (mismatch_s[4]),
                               .mismatch_2nd_o     (mismatch_2nd_s[4]),
                               // Inputs
                               .assert_clk_i       (clk_i),
                               .assert_rst_i       (rst_i),
                               .input_i            (dp1_wr_s)
                               /*autoinst*/);

   majority_voter_packed #(
                           // Parameters
                           .K_MMR              (G_K_TMR),
                           .MISMATCH_EN        (MISMATCH_EN),
                           .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           /*autoinstparam*/)
   INST_majority_voter_WRERR_SIG (
                                  // Outputs
                                  .output_o           (wrerr_sig_o),
                                  .mismatch_o         (mismatch_s[5]),
                                  .mismatch_2nd_o     (mismatch_2nd_s[5]),
                                  // Inputs
                                  .assert_clk_i       (clk_i),
                                  .assert_rst_i       (rst_i),
                                  .input_i            (wrerr_sig_s)
                                  /*autoinst*/);

   majority_voter_packed #(
                           // Parameters
                           .K_MMR              (G_K_TMR),
                           .MISMATCH_EN        (MISMATCH_EN),
                           .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           /*autoinstparam*/)
   INST_majority_voter_RDERR_SIG (
                                  // Outputs
                                  .output_o           (rderr_sig_o),
                                  .mismatch_o         (mismatch_s[6]),
                                  .mismatch_2nd_o     (mismatch_2nd_s[6]),
                                  // Inputs
                                  .assert_clk_i       (clk_i),
                                  .assert_rst_i       (rst_i),
                                  .input_i            (rderr_sig_s)
                                  /*autoinst*/);

   majority_voter_packed #(
                           // Parameters
                           .K_MMR              (G_K_TMR),
                           .MISMATCH_EN        (MISMATCH_EN),
                           .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           /*autoinstparam*/)
   INST_majority_voter_LTCHDTDP0 (
                                  // Outputs
                                  .output_o           (ltchDtDP0_o),
                                  .mismatch_o         (mismatch_s[7]),
                                  .mismatch_2nd_o     (mismatch_2nd_s[7]),
                                  // Inputs
                                  .assert_clk_i       (clk_i),
                                  .assert_rst_i       (rst_i),
                                  .input_i            (ltchDtDP0_s)
                                  /*autoinst*/);

   majority_voter_packed #(
                           // Parameters
                           .K_MMR              (G_K_TMR),
                           .MISMATCH_EN        (MISMATCH_EN),
                           .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           /*autoinstparam*/)
   INST_majority_voter_LTCHDTDP1 (
                                  // Outputs
                                  .output_o           (ltchDtDP1_o),
                                  .mismatch_o         (mismatch_s[8]),
                                  .mismatch_2nd_o     (mismatch_2nd_s[8]),
                                  // Inputs
                                  .assert_clk_i       (clk_i),
                                  .assert_rst_i       (rst_i),
                                  .input_i            (ltchDtDP1_s)
                                  /*autoinst*/);

   majority_voter_triplicated_array #(
                                      // Parameters
                                      .K_MMR              (G_K_TMR),
                                      .MISMATCH_EN        (MISMATCH_EN),
                                      .G_MISMATCH_REGISTERED(G_MISMATCH_REGISTERED),
                                      .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH),
                                      .N                    (StateBitWidth)
                                      /*autoinstparam*/)
   INST_majority_voter_triplicated_array_ACTUAL_STATE (
                                                       // Outputs
                                                       .output_o           (actual_state_voted),
                                                       .mismatch_o         (mismatch_s[9]),
                                                       .mismatch_2nd_o     (mismatch_2nd_s[9]),
                                                       // Inputs
                                                       .assert_clk_i       (clk_i),
                                                       .assert_rst_i       (rst_i),
                                                       .input_i            (actual_state_s)
                                                       /*autoinst*/);

   // counter increases at every mismatch
   // on the state machines
   assign seeerr_sig_o = (seeerr_sig_s == C_SEEERR_SIG_NONE)? 1'b0: 1'b1;

   assign mismatch_o = (mismatch_s == C_MISMATCH_NONE)? 1'b0: 1'b1;

   if (G_ADDITIONAL_MISMATCH == 1)
     assign mismatch_2nd_o = (mismatch_2nd_s == C_MISMATCH_NONE)? 1'b0: 1'b1;
   else
     assign mismatch_2nd_o = 1'b0;




endmodule // dp_fifos_reset_tmr_wrapper

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./../" "./../../../../../common_tmr/source/rtl/mmr_registers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
