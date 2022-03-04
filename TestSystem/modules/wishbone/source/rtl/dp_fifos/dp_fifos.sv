///////////////////////////////////////////////////////////////////////////////
// Title        : Interface between the GBTx controller to the wb master
// Project      : RUv1
////////////////////////////////////////////////////////////////////////////////
// File         : dp_fifos.sv
// Author       : Matteo Lupi <matteo.lupi@cern.ch>
// Company      : CERN / Goethe Universitaet Frankfurt am Main
// Created      : 2017-09-11
// Last update  : 2017-09-11
// Platform     : Xilinx Vivado 2017.4
// Target       : Kintex-Ultrascale
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: Interface between the GBTx controller to the wb master
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/10ps
module dp_fifos
  #(
    parameter int GpifWidth = 32, // GPIF II bus width
    parameter int GBTxIfWidth = 80, // GBTx bus width
    parameter int G_MISMATCH_WIDTH = 4 // width of the mismatch signal
    )
   (
    input                         dp0_wrclk_rst_i, // writeclk reset for dp0 fifo
    input                         dp1_wrclk_rst_i, // writeclk reset for dp1 fifo
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
    output                        dp1_full_o, // data port 1 full
    input                         dp1_wr_i, // data port 1 write
    output                        dp1_overflow_o, // dataport 1 overflow

    output [G_MISMATCH_WIDTH-1:0] mismatch_o,
    output [G_MISMATCH_WIDTH-1:0] mismatch_2nd_o
    );

   localparam [3:0] GBTX_SWT_C     = 4'd3;
   localparam       GBTX_NO_DATA_C = 1'b0;

   logic                          dp0_wr_s;
   logic [3:0]                    gbtx_transaction_s;
   logic                          gbtx_datavalid_s;

   logic [G_MISMATCH_WIDTH-1:0]   mismatch_s;
   logic [G_MISMATCH_WIDTH-1:0]   mismatch_2nd_s;

   logic                          dp0_sbiterr_s;
   logic                          dp0_dbiterr_s;
   logic                          dp1_sbiterr_s;
   logic                          dp1_dbiterr_s;

   logic                          dp0_rst_s;
   logic                          dp1_rst_s;

   logic                          dp0_full_s;
   logic                          dp0_wr_rst_busy_s;
   logic                          dp0_underflow_s;
   logic                          dp0_rd_rst_busy_s;
   logic                          dp1_wr_rst_busy_s;
   logic                          dp1_underflow_s;
   logic                          dp1_rd_rst_busy_s;

   localparam int                 FIFO_ADD_WIDTH_C = 10;
   localparam int                 FIFO_DEPTH_C = 2**FIFO_ADD_WIDTH_C;
   localparam int                 FIFO_WIDTH_C = 64; // ECC
   localparam int                 FIFO_READ_LATENCY_C = 2;

   localparam int                 FIFO_UNUSED_BITS_C = FIFO_WIDTH_C - GpifWidth;
   logic [FIFO_UNUSED_BITS_C-1:0] dp0_dt_unused_s;

   ////////////////////////////////////////////////////////////////////////////////

   xpm_fifo_async #
     (
      .FIFO_MEMORY_TYPE          ("block"),           //string; "auto", "block", or "distributed";
      .ECC_MODE                  ("en_ecc"),         //string; "no_ecc" or "en_ecc";
      .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
      .FIFO_WRITE_DEPTH          (FIFO_DEPTH_C),     //positive integer
      .WRITE_DATA_WIDTH          (FIFO_WIDTH_C),     //positive integer
      .WR_DATA_COUNT_WIDTH       (FIFO_ADD_WIDTH_C), //positive integer
      .PROG_FULL_THRESH          (10),               //positive integer
      .FULL_RESET_VALUE          (1),                //positive integer; 0 or 1
      .READ_MODE                 ("std"),            //string; "std" or "fwft";
      .FIFO_READ_LATENCY         (FIFO_READ_LATENCY_C), //positive integer;
      .READ_DATA_WIDTH           (FIFO_WIDTH_C),     //positive integer
      .RD_DATA_COUNT_WIDTH       (FIFO_ADD_WIDTH_C), //positive integer
      .PROG_EMPTY_THRESH         (10),               //positive integer
      .DOUT_RESET_VALUE          ("0"),              //string
      .CDC_SYNC_STAGES           (3),                //positive integer
      .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;
      )
   xpm_fifo_async_dp0_inst
     (
      .rst              (dp0_wrclk_rst_i), // sync to wr_clk
      .wr_clk           (dp0_wrclk_i),
      .wr_en            (dp0_wr_s),
      .din              ({32'd0, dp0_dt_i[GpifWidth-1:0]}),
      .full             (dp0_full_s),
      .overflow         (dp0_overflow_o),
      .wr_rst_busy      (dp0_wr_rst_busy_s),
      .rd_clk           (dp0_rdclk_i),
      .rd_en            (dp0_rd_i),
      .dout             ({dp0_dt_unused_s, dp0_dt_o}),
      .empty            (dp0_epty_o),
      .underflow        (dp0_underflow_s),
      .rd_rst_busy      (dp0_rd_rst_busy_s),
      .prog_full        (),
      .wr_data_count    (),
      .prog_empty       (),
      .rd_data_count    (),
      .sleep            (1'b0),
      .injectsbiterr    (1'b0),
      .injectdbiterr    (1'b0),
      .sbiterr          (dp0_sbiterr_s),
      .dbiterr          (dp0_dbiterr_s),
      .data_valid       (),
      .almost_empty     (),
      .wr_ack           (),
      .almost_full      ()
      );

   assign mismatch_s[0]     = dp0_sbiterr_s;
   assign mismatch_s[1]     = dp0_dbiterr_s;
   assign mismatch_2nd_s[0] = dp0_sbiterr_s;
   assign mismatch_2nd_s[1] = dp0_dbiterr_s;

   assign gbtx_datavalid_s = dp0_dt_i[GBTxIfWidth];
   assign gbtx_transaction_s = dp0_dt_i[GBTxIfWidth-1:GBTxIfWidth-4];

   assign dp0_wr_s = ((gbtx_datavalid_s==GBTX_NO_DATA_C) && (gbtx_transaction_s==GBTX_SWT_C) && (dp0_dt_vld_i==1'b1) && (dp0_full_s == 1'b0))? 1'b1 : 1'b0;
                      /* SWT (single word transaction)*/
                      /* gbtx_datavalid_s==gbtx_no_data_C */
                      /* data are valid*/
                      /* fifo not full (for reset)*/

   // synthesis translate_off
   ////////////////////
   // logging module //
   ////////////////////
   initial begin
      // get file_handler
      automatic int f0 = $fopen("fifodump_DP0", "w");
      if (!f0)
        $display("Could not open \"fifodump_DP0\"");
      else begin
         for (integer i = 0; i<5000; i++) begin
            @(posedge dp0_wrclk_i);
            if (dp0_wr_s) begin
               // write to file
               $fwrite(f0, "%h\n", dp0_dt_i[GpifWidth-1:0]);
            end
         end
         $fclose(f0);
      end
   end
   // synthesis translate_on

   // synthesis translate_off
   always @(posedge dp0_wrclk_i)
     begin
        assert (dp0_overflow_o != 1'b1) else $warning("DP0 FIFO overflowed");
     end
   always @(posedge dp0_wrclk_i)
     begin
        assert (!((dp0_wr_s == 1'b1) && (dp0_full_s == 1'b1))) else $warning("DP0 FIFO overflowed (read and full fifo)");
     end
   always @(posedge dp0_rdclk_i)
     begin
        assert (!((dp0_rd_i == 1'b1) && (dp0_epty_o == 1'b1))) else $warning("DP0 FIFO underflow (read empty fifo!)");
     end
   always @(posedge dp0_rdclk_i)
     begin
        assert (dp0_underflow_s == 1'b0) else $warning("DP0 FIFO underflow (underflow signal is high!)");
     end
   // synthesis translate_on

   ////////////////////////////////////////////////////////////////////////////////
   // FIFO for DP1
   xpm_fifo_async #
     (
      .FIFO_MEMORY_TYPE          ("block"),           //string; "auto", "block", or "distributed";
      .ECC_MODE                  ("en_ecc"),         //string; "no_ecc" or "en_ecc";
      .RELATED_CLOCKS            (0),                //positive integer; 0 or 1
      .FIFO_WRITE_DEPTH          (FIFO_DEPTH_C),     //positive integer
      .WRITE_DATA_WIDTH          (FIFO_WIDTH_C),     //positive integer
      .WR_DATA_COUNT_WIDTH       (FIFO_ADD_WIDTH_C), //positive integer
      .PROG_FULL_THRESH          (10),               //positive integer
      .FULL_RESET_VALUE          (1),                //positive integer; 0 or 1
      .READ_MODE                 ("std"),            //string; "std" or "fwft";
      .FIFO_READ_LATENCY         (FIFO_READ_LATENCY_C), //positive integer;
      .READ_DATA_WIDTH           (FIFO_WIDTH_C),     //positive integer
      .RD_DATA_COUNT_WIDTH       (FIFO_ADD_WIDTH_C), //positive integer
      .PROG_EMPTY_THRESH         (10),               //positive integer
      .DOUT_RESET_VALUE          ("0"),              //string
      .CDC_SYNC_STAGES           (3),                //positive integer
      .WAKEUP_TIME               (0)                 //positive integer; 0 or 2;
      )
   xpm_fifo_async_dp1_inst
     (
      .rst              (dp1_wrclk_rst_i), // sync to wr_clk
      .wr_clk           (dp1_wrclk_i),
      .wr_en            (dp1_wr_i),
      .din              ({32'd0, dp1_dt_i}),
      .full             (dp1_full_o),
      .overflow         (dp1_overflow_o),
      .wr_rst_busy      (dp1_wr_rst_busy_s),
      .rd_clk           (dp1_rdclk_i),
      .rd_en            (dp1_rd_i),
      .dout             (dp1_dt_o[FIFO_WIDTH_C-1:0]),
      .empty            (dp1_epty_o),
      .underflow        (dp1_underflow_s),
      .rd_rst_busy      (dp1_rd_rst_busy_s),
      .prog_full        (),
      .wr_data_count    (),
      .prog_empty       (),
      .rd_data_count    (),
      .sleep            (1'b0),
      .injectsbiterr    (1'b0),
      .injectdbiterr    (1'b0),
      .sbiterr          (dp1_sbiterr_s),
      .dbiterr          (dp1_dbiterr_s),
      .data_valid       (),
      .almost_empty     (),
      .wr_ack           (),
      .almost_full      ()
      );

   assign mismatch_s[2]     = dp1_sbiterr_s;
   assign mismatch_s[3]     = dp1_dbiterr_s;
   assign mismatch_2nd_s[2] = dp1_sbiterr_s;
   assign mismatch_2nd_s[3] = dp1_dbiterr_s;

   assign dp1_dt_o[GBTxIfWidth] = GBTX_NO_DATA_C;
   assign dp1_dt_o[GBTxIfWidth-1:GBTxIfWidth-4] = GBTX_SWT_C;
   assign dp1_dt_o[GBTxIfWidth-5:FIFO_WIDTH_C] = 'b0; // zero padding

   // synthesis translate_off
   ////////////////////
   // logging module //
   ////////////////////
   initial begin
      // get file_handler
      automatic int f1 = $fopen("fifodump_DP1", "w");
      if (!f1)
        $display("Could not open \"fifodump_DP1\"");
      else begin
         for (integer i = 0; i<5000; i++) begin
            @(posedge dp1_wrclk_i);
            if (dp1_wr_i) begin
               // write to file
               $fwrite(f1, "%h\n", dp1_dt_i);
            end
         end
         $fclose(f1);
      end
   end
   // synthesis translate_on

  // synthesis translate_off
  always @(posedge dp1_wrclk_i)
  begin
    assert (dp1_overflow_o == 1'b0) else $warning("DP1 FIFO overflowed (overflow signal went high)");
  end
   always @(posedge dp1_wrclk_i)
     begin
        assert (!((dp1_wr_i == 1'b1) && (dp1_full_o == 1'b1))) else $warning("DP1 FIFO overflowed (read and full fifo)");
     end
  always @(posedge dp1_rdclk_i)
  begin
    assert (!((dp1_rd_i == 1'b1) && (dp1_epty_o == 1'b1))) else $warning("DP1 FIFO underflow (read an empty fifo!)");
  end
  always @(posedge dp1_rdclk_i)
    begin
       assert (dp1_underflow_s == 1'b0) else $warning("DP1 FIFO underflow (underflow signal high)");
    end
   // synthesis translate_on

   /////////////////////////////////////////////////////////////////////////////////////
   // Mismatch signal
   /////////////////////////////////////////////////////////////////////////////////////

   xpm_cdc_array_single
     #(
       .DEST_SYNC_FF   (2               ),  // integer; range: 2-10
       .SIM_ASSERT_CHK (0               ),  // integer; 0=disable simulation messages, 1=enable simulation messages
       .SRC_INPUT_REG  (0               ),  // integer; 0=do not register input, 1=register input
       .WIDTH          (G_MISMATCH_WIDTH)    // integer; range: 2-1024
       )
   mismatch_sync_INST
     (
      .src_clk  (1'b0       ),      // optional; required when SRC_INPUT_REG = 1
      .src_in   (mismatch_s ),
      .dest_clk (dp0_rdclk_i),
      .dest_out (mismatch_o)
      );

   xpm_cdc_array_single
     #(
       .DEST_SYNC_FF   (2               ),  // integer; range: 2-10
       .SIM_ASSERT_CHK (0               ),  // integer; 0=disable simulation messages, 1=enable simulation messages
       .SRC_INPUT_REG  (0               ),  // integer; 0=do not register input, 1=register input
       .WIDTH          (G_MISMATCH_WIDTH)    // integer; range: 2-1024
       )
   mismatch_2nd_sync_INST
     (
      .src_clk  (1'b0          ),      // optional; required when SRC_INPUT_REG = 1
      .src_in   (mismatch_2nd_s),
      .dest_clk (dp0_rdclk_i   ),
      .dest_out (mismatch_2nd_o)
      );

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
