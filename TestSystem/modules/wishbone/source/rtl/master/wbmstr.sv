////////////////////////////////////////////////////////////////////////////////
// Title        : The wishbone master module
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : wbmstr.sv
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-10-12
// Last update  : 2016-07-05
// Platform     : Xilinx Vivado 2015.4
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: The wishbone master module
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module wbmstr #(
                parameter int GpifWidth = 32, // GPIF II bus width
                parameter int WbDataWidth = 16, // data bus width
                parameter int WbAddWidth = 12, // address bus width
                parameter bit MISMATCH_EN = 1'b1, // if 1 warnign signal is generated
                parameter bit MISMATCH_REGISTERED = 1'b1, // if 1 the mismatch signal is latched
                parameter int G_SEE_MITIGATION_TECHNIQUE = 1'b0,
                parameter int G_WBMSTR_MISMATCH_WIDTH = 6, // size of the mismatch array
                parameter bit G_ADDITIONAL_MISMATCH = 1'b1 // additional mismatch for testbeam
                )
   (
    input                                      clk_i, // clock input
    input                                      rst_i, // synchronous reset input

    // wishbone bus signals
    output [WbAddWidth-1:0]                    adr_o, // wishbone address output [7:0] reg_addr, [WbAddWidth-1:8] mod_addr
    input [WbDataWidth-1:0]                    dt_i, // wishbone data input
    output [WbDataWidth-1:0]                   dt_o, // wishbone data output
    output reg                                 we_o, // write enable output
    output reg                                 stb_o, // strobe output
    input                                      ack_i, // acknowledge input
    input                                      err_i, // error input
    output reg                                 cyc_o, // cycle output

    // error counters
    output [WbDataWidth-1:0]                   rderrcntr_o, // WbDataWidth bit wb register for rd error on wbmstr
    output [WbDataWidth-1:0]                   wrerrcntr_o, // WbDataWidth bit wb register for wr error on wbmstr
    output [WbDataWidth-1:0]                   seeerrcntr_o, // WbDataWidth bit wb register for rd error on wbmstr
    input                                      rst_seeerrcntr_i, //rst counter for wr error on wbmstr
    input                                      rst_rderrcntr_i, //rst counter for rd error on wbmstr
    input                                      rst_wrerrcntr_i, //rst counter for wr error on wbmstr

    //   // data port 0 FIFO (wbmstr receives data from that FIFO)
    input [GpifWidth-1:0]                      dp0_dt_i, // data port 0 data input
    input                                      dp0_epty_i, // data port 0 empty input
    output reg                                 dp0_rd_o, // data port 0 read output

    // data port 1 FIFO (wbmstr writes data to that FIFO)
    output [GpifWidth-1:0]                     dp1_dt_o, // data port 1 data output
    input                                      dp1_full_i, // data port 1 full input
    output reg                                 dp1_wr_o, // data port 1 write output

    // MISMATCH
    output logic [G_WBMSTR_MISMATCH_WIDTH-1:0] mismatch_o, // mismatch signal
    output logic [G_WBMSTR_MISMATCH_WIDTH-1:0] mismatch_2nd_o // mismatch signal (additional)
    );

   reg                                         ltchDtDP0_r, ltchDtDP1_r;
   wire                                        wrFlag_w;

   reg                                         wrerr_sig_r, rderr_sig_r; // error signaling: to be used for upcounter
   wire [WbDataWidth-1:0]                      wrerrcntr_s, rderrcntr_s;

   reg                                         seeerr_sig_r; // error signaling for SEU
   wire [WbDataWidth-1:0]                      seeerrcntr_s;

   // a register to latch the data from the DP0 FIFO
   regnbit #(.N(GpifWidth),
             .MISMATCH_EN               (MISMATCH_EN),
             .MISMATCH_REGISTERED       (MISMATCH_REGISTERED),
             .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE),
             .G_ADDITIONAL_MISMATCH     (G_ADDITIONAL_MISMATCH)
             /*autoinstparam*/)
   DP0_FIFO_REG(
                .clk_i  (clk_i),
                .rst_i  (rst_i),
                .ce_i   (ltchDtDP0_r),
                .data_i (dp0_dt_i),
                .data_o ({wrFlag_w, adr_o, dt_o}),
                .mismatch_o(mismatch_o[0]),
                .mismatch_2nd_o(mismatch_2nd_o[0])
                /*autoinst*/);

   // a register to latch the data from the wishbone slave that will be written to the DP1_FITO
   regnbit #(.N(GpifWidth),
             .MISMATCH_EN               (MISMATCH_EN),
             .MISMATCH_REGISTERED       (MISMATCH_REGISTERED),
             .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE),
             .G_ADDITIONAL_MISMATCH     (G_ADDITIONAL_MISMATCH)
             /*autoinstparam*/)
   DP1_FIFO_REG(
                .clk_i  (clk_i),
                .rst_i  (rst_i),
                .ce_i   (ltchDtDP1_r),
                .data_i ({err_i, adr_o, dt_i}),
                .data_o (dp1_dt_o),
                .mismatch_o(mismatch_o[1]),
                .mismatch_2nd_o(mismatch_2nd_o[1])
                /*autoinst*/);

   wbmstr_fsm_tmr_wrapper #(
                            // Parameters
                            .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE),
                            .MISMATCH_EN        (MISMATCH_EN),
                            .MISMATCH_REGISTERED(MISMATCH_REGISTERED),
                            .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                            /*autoinstparam*/)
   INST_wbmstr_fsm_tmr_wrapper (
                                // Outputs
                                .we_o                (we_o),
                                .stb_o               (stb_o),
                                .cyc_o               (cyc_o),
                                .dp0_rd_o            (dp0_rd_o),
                                .dp1_wr_o            (dp1_wr_o),
                                .wrerr_sig_o         (wrerr_sig_r),
                                .rderr_sig_o         (rderr_sig_r),
                                .seeerr_sig_o        (seeerr_sig_r),
                                .ltchDtDP0_o         (ltchDtDP0_r),
                                .ltchDtDP1_o         (ltchDtDP1_r),
                                .mismatch_o          (mismatch_o[2]),
                                .mismatch_2nd_o      (mismatch_2nd_o[2]),
                                // Inputs
                                .clk_i               (clk_i),
                                .rst_i               (rst_i),
                                .ack_i               (ack_i),
                                .err_i               (err_i),
                                .dp0_epty_i          (dp0_epty_i),
                                .dp1_full_i          (dp1_full_i),
                                .wrFlag_i            (wrFlag_w)
                                /*autoinst*/);

   // error counters
   upcounter_tmr_wrapper #(
                           .BIT_WIDTH(WbDataWidth),
                           .IS_SATURATING(1'b1),
                           .VERBOSE(1'b1), // verbose
                           .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE)
                           )
   INST_RDERR_UPCOUNTER(
                        .CLK(clk_i),
                        .RST(rst_i),
                        .RST_CNT(rst_rderrcntr_i),
                        .CNT_UP(rderr_sig_r),
                        .CNT_VALUE(rderrcntr_s),
                        .MISMATCH(mismatch_o[3]),
                        .MISMATCH_2ND(mismatch_2nd_o[3])
                        );
   assign rderrcntr_o = rderrcntr_s;

   upcounter_tmr_wrapper #(
                           .BIT_WIDTH(WbDataWidth),
                           .IS_SATURATING(1'b1),
                           .VERBOSE(1'b1), // verbose
                           .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           )
   INST_WRERR_UPCOUNTER(
                        .CLK(clk_i),
                        .RST(rst_i),
                        .RST_CNT(rst_wrerrcntr_i),
                        .CNT_UP(wrerr_sig_r),
                        .CNT_VALUE(wrerrcntr_s),
                        .MISMATCH(mismatch_o[4]),
                        .MISMATCH_2ND(mismatch_2nd_o[4])
                        );
   assign wrerrcntr_o = wrerrcntr_s;

   upcounter_tmr_wrapper #(
                           .BIT_WIDTH(WbDataWidth),
                           .IS_SATURATING(1'b1),
                           .VERBOSE(1'b1), // verbose
                           .G_SEE_MITIGATION_TECHNIQUE(G_SEE_MITIGATION_TECHNIQUE),
                           .G_ADDITIONAL_MISMATCH(G_ADDITIONAL_MISMATCH)
                           )
   INST_SEEERR_UPCOUNTER(
                         .CLK(clk_i),
                         .RST(rst_i),
                         .RST_CNT(rst_seeerrcntr_i),
                         .CNT_UP(seeerr_sig_r),
                         .CNT_VALUE(seeerrcntr_s),
                         .MISMATCH(mismatch_o[5]),
                         .MISMATCH_2ND(mismatch_2nd_o[5])
                         );
   assign seeerrcntr_o = seeerrcntr_s;

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "./tmr_wrappers/" "../../../common/source/rtl/tmr_wrappers/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
