////////////////////////////////////////////////////////////////////////////////
// Title        : Wishbone master fsm tmr wrapper
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : wbmstr_fsm_tmr_wrapper.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-10-12
// Last update  : 2017-08-02
// Platform     : Xilinx Vivado 2015.4
// Target       : Kintex-7
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: tmr wrapper for the wbmstr fsm
//
//              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
//              protected:
//                      0: no mitigation
//                      1: TMR with single voter
///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

(* DONT_TOUCH = "true" *) module wbmstr_fsm_tmr_wrapper
  #(
    parameter int G_SEE_MITIGATION_TECHNIQUE = 0,
    parameter int MISMATCH_EN = 1,
    parameter int G_MISMATCH_REGISTERED = 0,
    parameter int G_ADDITIONAL_MISMATCH = 1,
    parameter int G_K_TMR = 3
    )
   (
    input                    clk_i, // clock input
    input                    rst_i, // synchronous reset input

    // wishbone bus signals
    output reg [G_K_TMR-1:0] we_o, // write enable output
    output reg [G_K_TMR-1:0] stb_o, // strobe output
    input [G_K_TMR-1:0]      ack_i, // acknowledge input
    input [G_K_TMR-1:0]      err_i, // error input
    output reg [G_K_TMR-1:0] cyc_o, // cycle output

    // data port 0 FIFO (wbmstr receives data from that FIFO)
    input                    dp0_epty_i, // data port 0 empty input
    output reg               dp0_rd_o, // data port 0 read output

    // data port 1 FIFO (wbmstr writes data to that FIFO)
    input                    dp1_full_i, // data port 1 full input
    output reg               dp1_wr_o, // data port 1 write output

    // error counters
    output reg               wrerr_sig_o, rderr_sig_o, // error signaling: to be used for upcounter
    output reg               seeerr_sig_o, // error signaling: to be used for upcounter

    // register latch of DP fifo registers
    output reg               ltchDtDP0_o, ltchDtDP1_o,

    // write flag from fifo DP0
    input                    wrFlag_i,

    // MISMATCH
    output logic             mismatch_o,
    output logic             mismatch_2nd_o
    );

   localparam int           StateBitWidth = 4;  // bitwidth of the fsm state

   generate
      if (G_SEE_MITIGATION_TECHNIQUE == 0) begin
         logic [StateBitWidth-1:0] actual_state_voted;
         logic                     we_o_s,stb_o_s,cyc_o_s;


         wbmstr_fsm #(
                      // Parameters
                      .StateBitWidth    (StateBitWidth)
                      /*autoinstparam*/)
         INST_wbmstr_fsm(
                         // Outputs
                         .we_o                  (we_o_s),
                         .stb_o                 (stb_o_s),
                         .cyc_o                 (cyc_o_s),
                         .dp0_rd_o              (dp0_rd_o),
                         .dp1_wr_o              (dp1_wr_o),
                         .wrerr_sig_o           (wrerr_sig_o),
                         .rderr_sig_o           (rderr_sig_o),
                         .seeerr_sig_o          (seeerr_sig_o),
                         .ltchDtDP0_o           (ltchDtDP0_o),
                         .ltchDtDP1_o           (ltchDtDP1_o),
                         .actual_state_o        (actual_state_voted),
                         // Inputs
                         .clk_i                 (clk_i),
                         .rst_i                 (rst_i),
                         .ack_i                 (ack_i[0]),
                         .err_i                 (err_i[0]),
                         .dp0_epty_i            (dp0_epty_i),
                         .dp1_full_i            (dp1_full_i),
                         .wrFlag_i              (wrFlag_i),
                         .actual_state_i        (actual_state_voted)
                         /*autoinst*/);
         assign we_o  = {G_K_TMR{we_o_s}};
         assign stb_o = {G_K_TMR{stb_o_s}};
         assign cyc_o = {G_K_TMR{cyc_o_s}};
         assign mismatch_o     = 1'b0;
         assign mismatch_2nd_o = 1'b0;
      end
      else // if (G_SEE_MITIGATION_TECHNIQUE == 0)
        if (G_SEE_MITIGATION_TECHNIQUE == 1) begin

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

           logic [G_K_TMR-1:0]       seeerr_sig_s;
           localparam  logic [G_K_TMR-1:0] C_SEEERR_SIG_NONE = {G_K_TMR{1'b0}};

           localparam int            C_MISMATCH_SIZE = 10;
           localparam [C_MISMATCH_SIZE-1:0] C_MISMATCH_NONE = 'd0;
           logic [C_MISMATCH_SIZE-1:0] mismatch_s, mismatch_2nd_s;

           for (genvar i = 0; i<G_K_TMR; i++) begin : inst_wbmstr

              (* DONT_TOUCH = "true" *) wbmstr_fsm #(
                           // Parameters
                           .StateBitWidth    (StateBitWidth)
                           /*autoinstparam*/)
              INST_wbmstr_fsm(
                              // Outputs
                              .we_o                  (we_s[i]),
                              .stb_o                 (stb_s[i]),
                              .cyc_o                 (cyc_s[i]),
                              .dp0_rd_o              (dp0_rd_s[i]),
                              .dp1_wr_o              (dp1_wr_s[i]),
                              .wrerr_sig_o           (wrerr_sig_s[i]),
                              .rderr_sig_o           (rderr_sig_s[i]),
                              .seeerr_sig_o          (seeerr_sig_s[i]),
                              .ltchDtDP0_o           (ltchDtDP0_s[i]),
                              .ltchDtDP1_o           (ltchDtDP1_s[i]),
                              .actual_state_o        (actual_state_s[i]),
                              // Inputs
                              .clk_i                 (clk_i),
                              .rst_i                 (rst_i),
                              .ack_i                 (ack_i[i]),
                              .err_i                 (err_i[i]),
                              .dp0_epty_i            (dp0_epty_i),
                              .dp1_full_i            (dp1_full_i),
                              .wrFlag_i              (wrFlag_i),
                              .actual_state_i        (actual_state_voted[i])
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

           // majority_voter_array #(
           //                        // Parameters
           //                        .K_MMR              (G_K_TMR),
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

                                    end // if (G_SEE_MITIGATION_TECHNIQUE == 1)

   endgenerate

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../" "./assertions/" "../../../../common_tmr/source/rtl/mmr_registers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
