///////////////////////////////////////////////////////////////////////////////
// Title        : Duplicate with compare wrapper for WMB fifos
// Project      : RUv1
////////////////////////////////////////////////////////////////////////////////
// File         : dp_fifos_dwc_wrapper.sv
// Author       : Matteo Lupi <matteo.lupi@cern.ch>
// Company      : CERN / Goethe Universitaet Frankfurt am Main
// Created      : 2017-11-02
// Last update  : 2017-11-02
// Platform     : Xilinx Vivado 2016.4
// Target       : Kintex-US
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: DWC version
////////////////////////////////////////////////////////////////////////////////


`timescale 1ps/1ps

(* DONT_TOUCH = "yes" *) module dp_fifos_dwc_wrapper
  #(
    parameter int GpifWidth = 32, // GPIF II bus width
    parameter int GBTxIfWidth = 80, // GBTx bus width
    parameter int G_MISMATCH_WIDTH = 14,// width of the mismatch signal
    parameter int G_SEE_MITIGATION_TECHNIQUE = 0 // 0 for stadard, 1 for DWC
    )
   (
    input                         rst_i, // synchronous reset input

    // CTRL IN FROM GBTx
    input                         dp0_wrclk_i, // dataport 0 fifo write clock
    input [GBTxIfWidth:0]         dp0_dt_i, // dataport 0 data
    input                         dp0_dt_vld_i,// dataport 0 data valid
    output                        dp0_overflow_o, // dataport 0 overflow

    // CTRL OUT TO GBTx
    input                         dp1_rdclk_i, // dataport 1 write clock
    output [GBTxIfWidth:0]        dp1_dt_o, // data to gbtx controller
    output                        dp1_epty_o, // data port 1 empty
    input                         dp1_rd_i, // data port 1 read

    // data port 0 FIFO (wbmstr receives data from that FIFO)
    input                         dp0_rdclk_i, // dataport 0 read clock
    output [GpifWidth-1:0]        dp0_dt_o, // data port 0 data
    output                        dp0_epty_o, // data port 0 empty
    input                         dp0_rd_i, // data port 0 read

    // data port 1 FIFO (wbmstr writes data to that FIFO)
    input                         dp1_wrclk_i, // dataport 1 write clock
    input [GpifWidth-1:0]         dp1_dt_i, // data port 1 data
    input [GpifWidth-1:0]         dp1_dt_DWC_i, // data port 1 data used as DWC
    output                        dp1_full_o, // data port 1 full
    input                         dp1_wr_i, // data port 1 write
    output                        dp1_overflow_o, // dataport 1 overflow

    output [G_MISMATCH_WIDTH-1:0] mismatch_o,
    output [G_MISMATCH_WIDTH-1:0] mismatch_2nd_o
    );

   localparam int                 C_DP_FIFO_MISMATCH_WIDTH = 4;

   logic [2*GpifWidth-1:0]        dp1_dt_s;
   assign dp1_dt_s = {dp1_dt_i, dp1_dt_i};

   generate
      if (G_SEE_MITIGATION_TECHNIQUE == 0) begin
         assign mismatch_o[G_MISMATCH_WIDTH-1:C_DP_FIFO_MISMATCH_WIDTH] = 0;
         assign mismatch_2nd_o[G_MISMATCH_WIDTH-1:C_DP_FIFO_MISMATCH_WIDTH] = 0;

         dp_fifos #(
                    // Parameters
                    .GpifWidth          (GpifWidth),
                    .GBTxIfWidth        (GBTxIfWidth),
                    .G_MISMATCH_WIDTH   (C_DP_FIFO_MISMATCH_WIDTH),
                    .G_USE_DP0_FIFO     (1'b1)
                    /*autoinstparam*/)
         dp_fifos_INST (
                        .dp1_dt_i       (dp1_dt_s),
                        .*);

      end else // if (G_SEE_MITIGATION_TECHNIQUE == 0)
        if (G_SEE_MITIGATION_TECHNIQUE == 1) begin
           logic [GpifWidth-1:0]        dp0_dt_only_s,       dp0_dt_only_DWC_s;
           logic [2*GpifWidth-1:0]      dp0_dt_s;

           logic [GBTxIfWidth:0]        dp1_dt_main_s;
           logic [GpifWidth-1:0]        dp1_dt_only_main_s,       dp1_dt_only_secondary_s;
           logic                        dp1_epty_main_s;
           logic                        dp1_full_main_s;
           logic                        dp1_overflow_main_s;
           logic [C_DP_FIFO_MISMATCH_WIDTH-1:0] mismatch_main_s,     mismatch_secondary_s;
           logic [C_DP_FIFO_MISMATCH_WIDTH-1:0] mismatch_2nd_main_s, mismatch_2nd_secondary_s;

           logic                                dwc_mismatch_dp0_dt_gbt_s, dwc_mismatch_dp0_dt_gbt_reg_s, dwc_mismatch_dp0_dt_gbt_reg_2nd_s;
           logic                                dwc_mismatch_dp1_dt_wb_s, dwc_mismatch_dp1_dt_wb_reg_s, dwc_mismatch_dp1_dt_wb_reg_2nd_s;
           logic                                dwc_mismatch_dp1_dt_s, dwc_mismatch_dp1_dt_reg_s, dwc_mismatch_dp1_dt_reg_2nd_s;
           logic                                dwc_mismatch_dp0_dt_wb_s, dwc_mismatch_dp0_dt_wb_reg_s, dwc_mismatch_dp0_dt_wb_reg_2nd_s;
           logic                                dp1_full_reg_s, dp1_full_reg_2nd_s;
           logic                                dp1_overflow_reg_s, dp1_overflow_reg_2nd_s;

           localparam logic [GBTxIfWidth-4-GpifWidth:0] dp0_dt_zeros_c = 0;

           localparam int                               dwc_mismatch_dp0_dt_gbt_c   = 0;
           localparam int                               dwc_mismatch_dp1_dt_wb_c    = 1;
           localparam int                               dwc_mismatch_dp1_dt_c       = 2;
           localparam int                               dwc_mismatch_dp0_dt_wb_c    = 3;
           localparam int                               dp1_full_c                  = 4;
           localparam int                               dp1_overflow_c              = 5;
           localparam int                               mismatch_main_first_c       = dp1_overflow_c + 1;
           localparam int                               mismatch_main_last_c        = mismatch_main_first_c + C_DP_FIFO_MISMATCH_WIDTH -1;
           localparam int                               mismatch_secondary_first_c  = mismatch_main_last_c + 1;
           localparam int                               mismatch_secondary_last_c   = mismatch_secondary_first_c + C_DP_FIFO_MISMATCH_WIDTH -1;

           // synthesis_translate off
           initial begin
             assert (G_MISMATCH_WIDTH == mismatch_secondary_last_c + 1);
           end
           // synthesis_translate on

           assign dp0_dt_only_s           = dp0_dt_s[GpifWidth-1:0];
           assign dp0_dt_only_DWC_s       = dp0_dt_s[2*GpifWidth-1:GpifWidth];
           assign dp0_dt_o                = dp0_dt_only_s;

           assign dp1_dt_only_main_s      = dp1_dt_main_s[GpifWidth-1:0];
           assign dp1_dt_only_secondary_s = dp1_dt_main_s[2*GpifWidth-1:GpifWidth];

           assign dp1_dt_o = {dp1_dt_main_s[GBTxIfWidth-1:2*GpifWidth],
                              dp1_dt_only_main_s,
                              dp1_dt_only_main_s};
           assign dp1_epty_o     = dp1_epty_main_s;
           assign dp1_full_o     = dp1_full_main_s;
           assign dp1_overflow_o = dp1_overflow_main_s;

           //-------------------------------------------------------------------------------------------------
           // Mismatch generation
           //-------------------------------------------------------------------------------------------------
           assign dwc_mismatch_dp0_dt_gbt_s = ( dp0_dt_i[GBTxIfWidth-1:GBTxIfWidth-4-1] == 4'h3 &
                                                dp0_dt_i[GpifWidth-1:0] !=  dp0_dt_i[2*GpifWidth-1:GpifWidth] )? 1'b1 : 1'b0;
           //-------------------------------------------------------------------------------------------------------/\-----/\
           // NOTE:
           //-----------------------------------------------------------------------------------------------\/-----\/
           assign dwc_mismatch_dp0_dt_wb_s    = ( dp0_dt_only_s       == dp0_dt_only_DWC_s        )? 1'b0 : 1'b1;
           assign dwc_mismatch_dp1_dt_wb_s    = ( dp1_dt_i            == dp1_dt_DWC_i             )? 1'b0 : 1'b1;
           assign dwc_mismatch_dp1_dt_s       = ( dp1_dt_only_main_s  == dp1_dt_only_secondary_s  )? 1'b0 : 1'b1;

           //-------------------------------------------------------------------------------------------------
           // Mismatch mismatch register
           //-------------------------------------------------------------------------------------------------

           (* DONT_TOUCH = "yes" *)
           always_ff @(posedge dp1_wrclk_i) begin
              dp1_full_reg_s = dp1_full_main_s;
              dp1_overflow_reg_s = dp1_overflow_main_s;
              dwc_mismatch_dp1_dt_wb_reg_s = dwc_mismatch_dp1_dt_wb_s;
              dwc_mismatch_dp0_dt_wb_reg_s = dwc_mismatch_dp0_dt_wb_s;

              dp1_full_reg_2nd_s = dp1_full_main_s;
              dp1_overflow_reg_2nd_s = dp1_overflow_main_s;
              dwc_mismatch_dp1_dt_wb_reg_2nd_s = dwc_mismatch_dp1_dt_wb_s;
              dwc_mismatch_dp0_dt_wb_reg_2nd_s = dwc_mismatch_dp0_dt_wb_s;
           end

           //-------------------------------------------------------------------------------------------------
           // CDC
           //-------------------------------------------------------------------------------------------------
           (* DONT_TOUCH = "yes" *)
           xpm_cdc_single #(
                            //Common module parameters
                            .DEST_SYNC_FF   (2), // integer; range: 2-10
                            .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                            .SRC_INPUT_REG  (1)  // integer; 0=do not register input, 1=register input
                            )
           xpm_cdc_single_0_inst (
                                  .src_clk  (dp0_wrclk_i),  // optional; required when SRC_INPUT_REG = 1
                                  .src_in   (dwc_mismatch_dp0_dt_gbt_s),
                                  .dest_clk (dp1_wrclk_i),
                                  .dest_out (dwc_mismatch_dp0_dt_gbt_reg_s)
                                );

           //(* DONT_TOUCH = "yes" *)
           // xpm_cdc_single #(
           //                  //Common module parameters
           //                  .DEST_SYNC_FF   (2), // integer; range: 2-10
           //                  .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
           //                  .SRC_INPUT_REG  (1)  // integer; 0=do not register input, 1=register input
           //                  )
           // xpm_cdc_single_1_inst (
           //                        .src_clk  (dp1_rdclk_i),  // optional; required when SRC_INPUT_REG = 1
           //                        .src_in   (dp1_epty_main_s),
           //                        .dest_clk (dp1_wrclk_i),
           //                        .dest_out (dp1_epty_reg_s)
           //                      );

           (* DONT_TOUCH = "yes" *)
           xpm_cdc_single #(
                            //Common module parameters
                            .DEST_SYNC_FF   (2), // integer; range: 2-10
                            .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                            .SRC_INPUT_REG  (1)  // integer; 0=do not register input, 1=register input
                            )
           xpm_cdc_single_2_inst (
                                  .src_clk  (dp1_rdclk_i),  // optional; required when SRC_INPUT_REG = 1
                                  .src_in   (dwc_mismatch_dp1_dt_s),
                                  .dest_clk (dp1_wrclk_i),
                                  .dest_out (dwc_mismatch_dp1_dt_reg_s)
                                  );

           (* DONT_TOUCH = "yes" *)
           xpm_cdc_single #(
                            //Common module parameters
                            .DEST_SYNC_FF   (2), // integer; range: 2-10
                            .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                            .SRC_INPUT_REG  (1)  // integer; 0=do not register input, 1=register input
                            )
           xpm_cdc_single_02_inst (
                                  .src_clk  (dp0_wrclk_i),  // optional; required when SRC_INPUT_REG = 1
                                  .src_in   (dwc_mismatch_dp0_dt_gbt_s),
                                  .dest_clk (dp1_wrclk_i),
                                  .dest_out (dwc_mismatch_dp0_dt_gbt_reg_2nd_s)
                                  );

           //(* DONT_TOUCH = "yes" *)
           // xpm_cdc_single #(
           //                  //Common module parameters
           //                  .DEST_SYNC_FF   (2), // integer; range: 2-10
           //                  .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
           //                  .SRC_INPUT_REG  (1)  // integer; 0=do not register input, 1=register input
           //                  )
           // xpm_cdc_single_12_inst (
           //                        .src_clk  (dp1_rdclk_i),  // optional; required when SRC_INPUT_REG = 1
           //                        .src_in   (dp1_epty_main_s),
           //                        .dest_clk (dp1_wrclk_i),
           //                        .dest_out (dp1_epty_reg_2nd_s)
           //                        );

           (* DONT_TOUCH = "yes" *)
           xpm_cdc_single #(
                            //Common module parameters
                            .DEST_SYNC_FF   (2), // integer; range: 2-10
                            .SIM_ASSERT_CHK (1), // integer; 0=disable simulation messages, 1=enable simulation messages
                            .SRC_INPUT_REG  (1)  // integer; 0=do not register input, 1=register input
                            )
           xpm_cdc_single_22_inst (
                                  .src_clk  (dp1_rdclk_i),  // optional; required when SRC_INPUT_REG = 1
                                  .src_in   (dwc_mismatch_dp1_dt_s),
                                  .dest_clk (dp1_wrclk_i),
                                  .dest_out (dwc_mismatch_dp1_dt_reg_2nd_s)
                                  );

           //-------------------------------------------------------------------------------------------------
           // Mismatch
           //-------------------------------------------------------------------------------------------------
           assign mismatch_o[dwc_mismatch_dp0_dt_gbt_c]                            = dwc_mismatch_dp0_dt_gbt_reg_s;
           assign mismatch_o[dwc_mismatch_dp1_dt_wb_c]                             = dwc_mismatch_dp1_dt_wb_reg_s;
           assign mismatch_o[dwc_mismatch_dp1_dt_c]                                = dwc_mismatch_dp1_dt_reg_s;
           assign mismatch_o[dwc_mismatch_dp0_dt_wb_c]                             = dwc_mismatch_dp0_dt_wb_reg_s;
           assign mismatch_o[dp1_full_c]                                           = dp1_full_reg_s;
           assign mismatch_o[dp1_overflow_c]                                       = dp1_overflow_reg_s;
           assign mismatch_o[mismatch_main_last_c:mismatch_main_first_c]           = mismatch_main_s;
           assign mismatch_o[mismatch_secondary_last_c:mismatch_secondary_first_c] = mismatch_secondary_s;

           assign mismatch_2nd_o[dwc_mismatch_dp0_dt_gbt_c]                            = dwc_mismatch_dp0_dt_gbt_reg_2nd_s;
           assign mismatch_2nd_o[dwc_mismatch_dp1_dt_wb_c]                             = dwc_mismatch_dp1_dt_wb_reg_2nd_s;
           assign mismatch_2nd_o[dwc_mismatch_dp1_dt_c]                                = dwc_mismatch_dp1_dt_reg_2nd_s;
           assign mismatch_2nd_o[dwc_mismatch_dp0_dt_wb_c]                             = dwc_mismatch_dp0_dt_wb_reg_2nd_s;
           assign mismatch_2nd_o[dp1_full_c]                                           = dp1_full_reg_2nd_s;
           assign mismatch_2nd_o[dp1_overflow_c]                                       = dp1_overflow_reg_2nd_s;
           assign mismatch_2nd_o[mismatch_main_last_c:mismatch_main_first_c]           = mismatch_2nd_secondary_s;
           assign mismatch_2nd_o[mismatch_secondary_last_c:mismatch_secondary_first_c] = mismatch_2nd_main_s;

           (* DONT_TOUCH = "true" *) dp_fifos #(
                      // Parameters
                      .GpifWidth          (GpifWidth),
                      .GBTxIfWidth        (GBTxIfWidth),
                      .G_MISMATCH_WIDTH   (C_DP_FIFO_MISMATCH_WIDTH),
                      .G_USE_DP0_FIFO     (1'b1)
                      /*autoinstparam*/)
           dp_fifos_main_INST (
                               // Outputs
                               .dp0_dt_o       (dp0_dt_s),
                               .dp0_epty_o     (dp0_epty_o),
                               .dp0_overflow_o (dp0_overflow_o),
                               .dp1_dt_o       (dp1_dt_main_s),
                               .dp1_epty_o     (dp1_epty_main_s),
                               .dp1_full_o     (dp1_full_main_s),
                               .dp1_overflow_o (dp1_overflow_main_s),
                               .mismatch_o     (mismatch_main_s),
                               .mismatch_2nd_o (mismatch_2nd_main_s),
                               // Inputs
                               .rst_i          (rst_i),
                               .dp0_wrclk_i    (dp0_wrclk_i),
                               .dp0_dt_i       (dp0_dt_i),
                               .dp0_dt_vld_i   (dp0_dt_vld_i),
                               .dp1_rdclk_i    (dp1_rdclk_i),
                               .dp1_rd_i       (dp1_rd_i),
                               .dp0_rdclk_i    (dp0_rdclk_i),
                               .dp0_rd_i       (dp0_rd_i),
                               .dp1_wrclk_i    (dp1_wrclk_i),
                               .dp1_dt_i       (dp1_dt_s),
                               .dp1_wr_i       (dp1_wr_i)
                               /*autoinst*/);

           // (* DONT_TOUCH = "true" *) dp_fifos #(
           //            // Parameters
           //            .GpifWidth          (GpifWidth),
           //            .GBTxIfWidth        (GBTxIfWidth),
           //            .G_MISMATCH_WIDTH   (C_DP_FIFO_MISMATCH_WIDTH),
           //            .G_USE_DP0_FIFO     (1'b0)
           //            /*autoinstparam*/)
           // dp_fifos_secondary_INST (
           //                     // Outputs
           //                     .dp0_dt_o       (),
           //                     .dp0_epty_o     (),
           //                     .dp0_overflow_o (),
           //                     .dp1_dt_o       (dp1_dt_secondary_s  ),
           //                     .dp1_epty_o     (dp1_epty_secondary_s),
           //                     .dp1_full_o     (dp1_full_secondary_s),
           //                     .dp1_overflow_o (dp1_overflow_secondary_s),
           //                     .mismatch_o     (mismatch_secondary_s),
           //                     .mismatch_2nd_o (mismatch_2nd_secondary_s),
           //                     // Inputs
           //                     .rst_i          (rst_i),
           //                     .dp0_wrclk_i    (dp0_wrclk_i),
           //                     .dp0_dt_i       (dp0_dt_i),
           //                     .dp0_dt_vld_i   (dp0_dt_vld_i),
           //                     .dp1_rdclk_i    (dp1_rdclk_i),
           //                     .dp1_rd_i       (dp1_rd_i),
           //                     .dp0_rdclk_i    (dp0_rdclk_i),
           //                     .dp0_rd_i       (dp0_rd_i),
           //                     .dp1_wrclk_i    (dp1_wrclk_i),
           //                     .dp1_dt_i       (dp1_dt_i),
           //                     .dp1_wr_i       (dp1_wr_i)
           //                     /*autoinst*/);


      end else // if (G_SEE_MITIGATION_TECHNIQUE == 1)
        $fatal(1, "G_SEE_MITIGATION_TECHNIQUE is invalid. Given value is %d", G_SEE_MITIGATION_TECHNIQUE);
   endgenerate


endmodule
// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
