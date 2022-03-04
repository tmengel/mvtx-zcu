////////////////////////////////////////////////////////////////////////////////
// Title        : DP23 fifos with usb_monitor modules
// Project      : Probecard
////////////////////////////////////////////////////////////////////////////////
// File         : DP23_fifo.sv
// Author       : Matteo Lupi <matteo.lupi@cern.ch>
// Company      : CERN / Goethe Universitaet Frankfurt am Main
// Created      : 2016-07-01
// Last update  : 2016-07-01
// Platform     : Xilinx Vivado 2015.4
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: DP23 fifos to be used for monitoring the fifo write side
//              The counter are realative to the number of words effectively written
//              to the fifo (if overflow, then the counter is not updated)
////////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-07-01  1.0      ML            Created
// 2016-12-01  1.1      ML            Added parametrization of WbDataWidth
//                                    added readcounter and full counter
//-----------------------------------------------------------------------------

`timescale 1ns/10ps

module DP23_fifo #(parameter int WbDataWidth   = 16,// data bus width
                   parameter int GpifWidth = 32 // GPIF II bus width
                   )
   (
    input                          rst_i, // async reset

                 // WB
    input                          WB_CLK,
    input                          WB_RST,

    // Written words counter
    input                          LATCH_WORDS_COUNT_I,
    input                          RST_WORDS_COUNT_I,
    output logic [WbDataWidth-1:0] WORDS_COUNT_MSB_O,
    output logic [WbDataWidth-1:0] WORDS_COUNT_LSB_O,

    // Read words counter
    input                          LATCH_RDWORDS_COUNT_I,
    input                          RST_RDWORDS_COUNT_I,
    output logic [WbDataWidth-1:0] RDWORDS_COUNT_MSB_O,
    output logic [WbDataWidth-1:0] RDWORDS_COUNT_LSB_O,

    // Overflow counter
    input                          LATCH_OVFL_COUNT_I,
    input                          RST_OVFL_COUNT_I,
    output logic [WbDataWidth-1:0] OVFL_COUNT_O,

    // Full counter
    input                          LATCH_FULL_COUNT_I,
    input                          RST_FULL_COUNT_I,
    output logic [WbDataWidth-1:0] FULL_COUNT_O,

                 // WRCLK side
    input                          clk_dp_wr_i,
    input                          dpo_rst_wrclk_i,
    input                          dpo_wr_i,
    output                         dpo_full_o,
    output                         dpo_almst_full_o,
    input [GpifWidth-1:0]          dpo_dti_i,

                 // RDCLK side
    input                          clk_rd_i,
    input                          dpo_rst_rdclk_i,
    input                          dpo_rd_i,
    output                         dpo_epty_o,
    output                         dpo_almst_epty_o,
    output [GpifWidth-1:0]         dpo_dto_o);


  ////////////////////////////////////////////////////////////////////////////////////
  // FIFO
  ////////////////////////////////////////////////////////////////////////////////////
   logic                           overflow;

  fifo_DP23_32bit fifo_DP23_32bit_DP(
                                     .wr_clk       (clk_dp_wr_i),
                                     .rd_clk       (clk_rd_i),
                                     .almost_full  (dpo_almst_full_o),
                                     .almost_empty (dpo_almst_epty_o),
                                     .rst          (rst_i),
                                     .wr_en        (dpo_wr_i),
                                     .rd_en        (dpo_rd_i),
                                     .din          (dpo_dti_i),
                                     .dout         (dpo_dto_o),
                                     .full         (dpo_full_o),
                                     .empty        (dpo_epty_o),
                                     .overflow     (overflow)          // output wire overflow
                                     );
   ////////////////////////////////////////////////////////////////////////////////////
                                          // MONITOR
   ////////////////////////////////////////////////////////////////////////////////////
   localparam int                    WORDS_WIDTH = 30;
   logic [WORDS_WIDTH-1:0]           s_words, s_rdwords;
   logic [WbDataWidth-1:0]           s_ovfl, s_full;
   logic                             s_rst_words_count;
   logic                             s_rst_rdwords_count;
   logic                             s_rst_ovfl_count;
   logic                             s_rst_full_count;

   upcounter #(
               .BIT_WIDTH(WORDS_WIDTH),
               .IS_SATURATING(1'b0), // default
               .VERBOSE(1'b1) // verbose
               )
   INST_WORDS_UPCOUNTER(
                        .CLK(clk_dp_wr_i),
                        .RST(dpo_rst_wrclk_i),
                        .RST_CNT(s_rst_words_count),
                        .CNT_UP(dpo_wr_i & !overflow), // counts only the effective words written to the fifo
                        .CNT_VALUE(s_words)
                        );

   upcounter #(
               .BIT_WIDTH(WORDS_WIDTH),
               .IS_SATURATING(1'b0), // default
               .VERBOSE(1'b1) // verbose
               )
   INST_RDWORDS_UPCOUNTER(
                        .CLK(clk_rd_i),
                        .RST(dpo_rst_rdclk_i),
                        .RST_CNT(s_rst_rdwords_count),
                        .CNT_UP(dpo_rd_i), // counts only the effective words read from the fifo
                        .CNT_VALUE(s_rdwords)
                        );

   upcounter #(
               .BIT_WIDTH(WbDataWidth),
               .IS_SATURATING(1'b0), // default
               .VERBOSE(1'b1) // verbose
               )
   INST_OVFL_UPCOUNTER(
                       .CLK(clk_dp_wr_i),
                       .RST(dpo_rst_wrclk_i),
                       .RST_CNT(s_rst_ovfl_count),
                       .CNT_UP(overflow),
                       .CNT_VALUE(s_ovfl)
                       );

   upcounter #(
               .BIT_WIDTH(WbDataWidth),
               .IS_SATURATING(1'b0), // default
               .VERBOSE(1'b1) // verbose
               )
   INST_FULL_UPCOUNTER(
                       .CLK(clk_dp_wr_i),
                       .RST(dpo_rst_wrclk_i),
                       .RST_CNT(s_rst_full_count),
                       .CNT_UP(dpo_full_o),
                       .CNT_VALUE(s_full)
                       );

   ////////////////////////////////////////////////////////////////////////////////////
   // XCLK_REGS
   ///////////////////////////////////////////////////////////////////////////////////

   //WR2WB
   localparam int                    XCLK_WRCLK2WBCLK_WIDTH = 3*WbDataWidth;
   logic [XCLK_WRCLK2WBCLK_WIDTH-1:0] xclk_wrclk2wbclk_input_array;
   logic [XCLK_WRCLK2WBCLK_WIDTH-1:0] xclk_wrclk2wbclk_output_array;

   assign xclk_wrclk2wbclk_input_array = {2'b0, s_words, s_ovfl}; //<= 2'b0, MSB, LSB, OVFL =====
   xclk_reg #(
              .SIZE(XCLK_WRCLK2WBCLK_WIDTH),
              .RESET_VALUE(0),
              .DOUBLE_BUFFER(1)
              )
   INST_xclk_reg_wrclk2wbclk (
                              .RESET(WB_RST),
                              .INPUT(xclk_wrclk2wbclk_input_array),
                              .CLK(WB_CLK),
                              .OUTPUT(xclk_wrclk2wbclk_output_array)
                              );

   //WB2WR
   localparam int                     XCLK_WBCLK2WRCLK_WIDTH = 3;
   logic [XCLK_WBCLK2WRCLK_WIDTH-1:0] xclk_wbclk2wrclk_input_array;
   logic [XCLK_WBCLK2WRCLK_WIDTH-1:0] xclk_wbclk2wrclk_output_array;

   assign xclk_wbclk2wrclk_input_array = {RST_FULL_COUNT_I, RST_WORDS_COUNT_I, RST_OVFL_COUNT_I}; //<= rst_full, rst words, rst ovfl =====
   xclk_reg #(
              .SIZE(XCLK_WBCLK2WRCLK_WIDTH),
              .RESET_VALUE(0),
              .DOUBLE_BUFFER(1)
              )
   INST_xclk_reg_wbclk2wrclk (
                              .RESET(dpo_rst_wrclk_i),
                              .INPUT(xclk_wbclk2wrclk_input_array),
                              .CLK(clk_dp_wr_i),
                              .OUTPUT(xclk_wbclk2wrclk_output_array)
                              );
   assign s_rst_full_count = xclk_wbclk2wrclk_output_array[2];
   assign s_rst_words_count = xclk_wbclk2wrclk_output_array[1];
   assign s_rst_ovfl_count = xclk_wbclk2wrclk_output_array[0];

   //RD2WB
   localparam int                     XCLK_RDCLK2WBCLK_WIDTH = 2*WbDataWidth;
   logic [XCLK_RDCLK2WBCLK_WIDTH-1:0] xclk_rdclk2wbclk_input_array;
   logic [XCLK_RDCLK2WBCLK_WIDTH-1:0] xclk_rdclk2wbclk_output_array;

   assign xclk_rdclk2wbclk_input_array = {2'b0, s_rdwords}; //<= 2'b0, MSB, LSB =====
   xclk_reg #(
              .SIZE(XCLK_RDCLK2WBCLK_WIDTH),
              .RESET_VALUE(0),
              .DOUBLE_BUFFER(1)
              )
   INST_xclk_reg_rdclk2wbclk (
                              .RESET(WB_RST),
                              .INPUT(xclk_rdclk2wbclk_input_array),
                              .CLK(WB_CLK),
                              .OUTPUT(xclk_rdclk2wbclk_output_array)
                              );

   //WB2RD
   localparam int                     XCLK_WBCLK2RDCLK_WIDTH = 1;
   logic [XCLK_WBCLK2RDCLK_WIDTH-1:0] xclk_wbclk2rdclk_input_array;
   logic [XCLK_WBCLK2RDCLK_WIDTH-1:0] xclk_wbclk2rdclk_output_array;

   assign xclk_wbclk2rdclk_input_array = {RST_RDWORDS_COUNT_I}; //<= rst rdwords =====
   xclk_reg #(
              .SIZE(XCLK_WBCLK2RDCLK_WIDTH),
              .RESET_VALUE(0),
              .DOUBLE_BUFFER(1)
              )
   INST_xclk_reg_wbclk2rdclk (
                              .RESET(dpo_rst_rdclk_i),
                              .INPUT(xclk_wbclk2rdclk_input_array),
                              .CLK(clk_rd_i),
                              .OUTPUT(xclk_wbclk2rdclk_output_array)
                              );

   assign s_rst_rdwords_count = xclk_wbclk2rdclk_output_array[0];

   ////////////////////////////////////////////////////////////////////////////////////
   // WB IF
   ///////////////////////////////////////////////////////////////////////////////////
   always @(posedge WB_CLK)
     begin
        if(WB_RST) begin
           // words counters
           WORDS_COUNT_MSB_O <= 16'b0;
           WORDS_COUNT_LSB_O <= 16'b0;

           // rdwords counters
           RDWORDS_COUNT_MSB_O <= 16'b0;
           RDWORDS_COUNT_LSB_O <= 16'b0;

           // overflow counter
           OVFL_COUNT_O <= 16'b0;

           // full counter
           FULL_COUNT_O <= 16'b0;
        end else begin

           // words counters
           if(RST_WORDS_COUNT_I) begin
              WORDS_COUNT_MSB_O <= 16'b0;
              WORDS_COUNT_LSB_O <= 16'b0;
           end else begin
              if(LATCH_WORDS_COUNT_I) begin
                 WORDS_COUNT_MSB_O <= xclk_wrclk2wbclk_output_array[XCLK_WRCLK2WBCLK_WIDTH-1:XCLK_WRCLK2WBCLK_WIDTH-16];
                 WORDS_COUNT_LSB_O <= xclk_wrclk2wbclk_output_array[XCLK_WRCLK2WBCLK_WIDTH-16-1:XCLK_WRCLK2WBCLK_WIDTH-2*16];
              end;
           end;

           // rdwords counters
           if(RST_RDWORDS_COUNT_I) begin
              RDWORDS_COUNT_MSB_O <= 16'b0;
              RDWORDS_COUNT_LSB_O <= 16'b0;
           end else begin
              if(LATCH_RDWORDS_COUNT_I) begin
                 RDWORDS_COUNT_MSB_O <= xclk_rdclk2wbclk_output_array[XCLK_RDCLK2WBCLK_WIDTH-1:XCLK_RDCLK2WBCLK_WIDTH-16];
                 RDWORDS_COUNT_LSB_O <= xclk_rdclk2wbclk_output_array[XCLK_RDCLK2WBCLK_WIDTH-16-1:XCLK_RDCLK2WBCLK_WIDTH-2*16];
              end;
           end;

           // ovfl counter
           if(RST_OVFL_COUNT_I)
             OVFL_COUNT_O <= 16'b0;
           else
             if(LATCH_OVFL_COUNT_I)
               OVFL_COUNT_O <= xclk_wrclk2wbclk_output_array[XCLK_WRCLK2WBCLK_WIDTH-2*16-1:0];

           // full counter
           if(RST_FULL_COUNT_I)
             FULL_COUNT_O <= 16'b0;
           else
             if(LATCH_FULL_COUNT_I)
               FULL_COUNT_O <= xclk_wrclk2wbclk_output_array[XCLK_WRCLK2WBCLK_WIDTH-2*16-1:0];
        end;
     end

endmodule // DP23_fifo
