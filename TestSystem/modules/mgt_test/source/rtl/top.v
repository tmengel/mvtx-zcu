`timescale 1ps/1ps

module mgt_example_top
  (

   // Differential reference clock inputs
   input wire          mgtrefclk1_x0y4_p,
   input wire          mgtrefclk1_x0y4_n,
   input wire          mgtrefclk1_x1y2_p,
   input wire          mgtrefclk1_x1y2_n,

   // Serial data ports for transceivers
   input wire [27:0]   gthrxn_in,
   input wire [27:0]   gthrxp_in,
   output wire [27:0]  gthtxn_out,
   output wire [27:0]  gthtxp_out,

   // clock inputs
   input wire          clk150,
   input wire          clk600,
   input wire          clk75,

   // GPIO outputs
   output [27:0]       gpout,

   // DRP inputs
   input wire [251:0]  drpaddr_in,
   input wire [27:0]   drpclk_in,
   input wire [447:0]  drpdi_in,
   input wire [27:0]   drpen_in,
   input wire [27:0]   drpwe_in,

   // DRP outputs
   output wire [447:0] drpdo_out,
   output wire [27:0]  drprdy_out,

   // control inputs
   input wire          enable_error_in,
   input wire          force_error,
   input wire          link_down_latched_rst,
   input wire          reset_all,
   input wire          reset_rx_pll_and_datapath,
   input wire          reset_rx_datapath,
   input wire [111:0]  rxprbssel,
   input wire [27:0]   rxprbscntreset,

   // control outputs
   output wire         init_done,
   output wire [3:0]   init_retry_ctr,
   output wire [27:0]  gtpowergood,
   output wire [27:0]  rxpmaresetdone,
   output wire         reset_rx_done,
   output wire [27:0]  rxprbslocked,
   output wire [27:0]  rxprbserr,
   output wire         link_status_out,
   output reg          link_down_latched_out = 1'b1

   );

   wire               hb_gtwiz_reset_rx_datapath_vio_int;
   wire [111:0]       rxprbssel_vio_async;
   wire [27:0]        rxprbscntreset_vio_async;
   wire               init_done_int;
   wire [3:0]         init_retry_ctr_int;
   wire [27:0]        gtpowergood_vio_sync;
   wire [27:0]        rxpmaresetdone_vio_sync;
   wire [0:0]         gtwiz_reset_rx_done_vio_sync;
   wire [27:0]        rxprbslocked_vio_sync;
   wire [27:0]        rxprbserr_vio_sync;
   wire [27:0]        txpmaresetdone_vio_sync;

   // connect outputs:
   assign init_done      = init_done_int;
   assign init_retry_ctr = init_retry_ctr_int;
   assign gtpowergood    = gtpowergood_vio_sync;
   assign rxpmaresetdone = rxpmaresetdone_vio_sync;
   assign reset_rx_done  = gtwiz_reset_rx_done_vio_sync;
   assign rxprbslocked   = rxprbslocked_vio_sync;
   assign rxprbserr      = rxprbserr_vio_sync;

   // connect inputs:
   assign rxprbssel_vio_async                 = rxprbssel;
   assign hb_gtwiz_reset_rx_datapath_vio_int  = reset_rx_datapath;
   assign rxprbscntreset_vio_async            = rxprbscntreset;

   // Globally buffer the free-running input clock
   wire               clkout1;
   wire               clkout2;
   wire               hb_gtwiz_reset_clk_freerun_buf_int;

   assign clkout1 = clk150;
   assign clkout2 = clk600;
   assign hb_gtwiz_reset_clk_freerun_buf_int = clk75;

   reg                force_error_dly;
   wire [7:0]         data_in;

   assign data_in[7:1]=7'b0000000;
   always @ (posedge clkout1) begin
      force_error_dly  <= force_error;
   end

   assign data_in[0]= force_error & ~force_error_dly;

   wire [7:0] prbs_out;
   reg  [7:0] prbsreg [0:27];
   //--------------------------------------------
   // Set the PRBS parameters
   //--------------------------------------------
   parameter POLY_LENGHT = 7;
   parameter POLY_TAP = 6;
   parameter INV_PATTERN = 0;
   //--------------------------------------------
   // Instantiate the PRBS generator
   //--------------------------------------------
   prbs_any
     #(
       .CHK_MODE    (0),
       .INV_PATTERN (INV_PATTERN),
       .POLY_LENGHT (POLY_LENGHT),
       .POLY_TAP    (POLY_TAP),
       .NBITS       (8)
       ) I_PRBS_ANY_GEN
       (
        .RST      (1'b0),
        .CLK      (clkout1),
        .DATA_IN  (data_in),
        .EN       (1'b1),
        .DATA_OUT (prbs_out)
        );

   integer i;
   always@(posedge clkout1) begin
      prbsreg[0]<=prbs_out;
      for(i=27; i>0; i=i-1) prbsreg[i] <= prbsreg[i-1];
   end

   genvar     index;
   generate
//      for (index=0; index < 8; index=index+1)
      for (index=0; index < 28; index=index+1)
        begin: gen_code_label1
           OSERDESE3
                 #(
                   .DATA_WIDTH(8), // Parallel Data Width (8-4)
                   .INIT(0), // Initialization value of the OSERDES flip-flops
                   .IS_CLKDIV_INVERTED(1'b0), // Optional inversion for CLKDIV
                   .IS_CLK_INVERTED(1'b0), // Optional inversion for CLK
                   .IS_RST_INVERTED(1'b0) // Optional inversion for RST
                   )
           OSERDESE3_inst
                 (
                  .OQ(gpout[index]), // 1-bit output: Serial Output Data
                  .T_OUT(), // 1-bit output: 3-state control output to IOB
                  .CLK(clkout2), // 1-bit input: High-speed clock
                  .CLKDIV(clkout1), // 1-bit input: Divided Clock
                  .D(prbsreg[index]), // 8-bit input: Parallel Data Input
                  .RST(1'b0), // 1-bit input: Asynchronous Reset
                  .T(1'b0) // 1-bit input: Tristate input from fabric
                  );
        end
   endgenerate

// these are inverted on the loopback board relative to the first 8
//   generate
//      for (index=8; index < 28; index=index+1)
//        begin: gen_code_label2
//           OSERDESE3
//                 #(
//                   .DATA_WIDTH(8), // Parallel Data Width (8-4)
//                   .INIT(0), // Initialization value of the OSERDES flip-flops
//                   .IS_CLKDIV_INVERTED(1'b0), // Optional inversion for CLKDIV
//                   .IS_CLK_INVERTED(1'b0), // Optional inversion for CLK
//                   .IS_RST_INVERTED(1'b0) // Optional inversion for RST
//                   )
//           OSERDESE3_inst
//                 (
//                  .OQ(gpout[index]), // 1-bit output: Serial Output Data
//                  .T_OUT(), // 1-bit output: 3-state control output to IOB
//                  .CLK(clkout2), // 1-bit input: High-speed clock
//                  .CLKDIV(clkout1), // 1-bit input: Divided Clock
//                  .D(~prbs_out), // 8-bit input: Parallel Data Input
//                  .RST(1'b0), // 1-bit input: Asynchronous Reset
//                  .T(1'b0) // 1-bit input: Tristate input from fabric
//                  );
//
//        end
//   endgenerate

   // ===================================================================================================================
   // PER-CHANNEL SIGNAL ASSIGNMENTS
   // ===================================================================================================================

   // The core and example design wrapper vectorize ports across all enabled transceiver channel and common instances for
   // simplicity and compactness. This example design top module assigns slices of each vector to individual, per-channel
   // signal vectors for use if desired. Signals which connect to helper blocks are prefixed "hb#", signals which connect
   // to transceiver common primitives are prefixed "cm#", and signals which connect to transceiver channel primitives
   // are prefixed "ch#", where "#" is the sequential resource number.

   //--------------------------------------------------------------------------------------------------------------------

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_tx_reset_int;
   wire [0:0]  hb0_gtwiz_userclk_tx_reset_int;
   assign gtwiz_userclk_tx_reset_int[0:0] = hb0_gtwiz_userclk_tx_reset_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_tx_srcclk_int;
   wire [0:0]  hb0_gtwiz_userclk_tx_srcclk_int;
   assign hb0_gtwiz_userclk_tx_srcclk_int = gtwiz_userclk_tx_srcclk_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_tx_usrclk_int;
   wire [0:0]  hb0_gtwiz_userclk_tx_usrclk_int;
   assign hb0_gtwiz_userclk_tx_usrclk_int = gtwiz_userclk_tx_usrclk_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_tx_usrclk2_int;
   wire [0:0]  hb0_gtwiz_userclk_tx_usrclk2_int;
   assign hb0_gtwiz_userclk_tx_usrclk2_int = gtwiz_userclk_tx_usrclk2_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_tx_active_int;
   wire [0:0]  hb0_gtwiz_userclk_tx_active_int;
   assign hb0_gtwiz_userclk_tx_active_int = gtwiz_userclk_tx_active_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_rx_reset_int;
   wire [0:0]  hb0_gtwiz_userclk_rx_reset_int;
   assign gtwiz_userclk_rx_reset_int[0:0] = hb0_gtwiz_userclk_rx_reset_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_rx_srcclk_int;
   wire [0:0]  hb0_gtwiz_userclk_rx_srcclk_int;
   assign hb0_gtwiz_userclk_rx_srcclk_int = gtwiz_userclk_rx_srcclk_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_rx_usrclk_int;
   wire [0:0]  hb0_gtwiz_userclk_rx_usrclk_int;
   assign hb0_gtwiz_userclk_rx_usrclk_int = gtwiz_userclk_rx_usrclk_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_rx_usrclk2_int;
   wire [0:0]  hb0_gtwiz_userclk_rx_usrclk2_int;
   assign hb0_gtwiz_userclk_rx_usrclk2_int = gtwiz_userclk_rx_usrclk2_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_userclk_rx_active_int;
   wire [0:0]  hb0_gtwiz_userclk_rx_active_int;
   assign hb0_gtwiz_userclk_rx_active_int = gtwiz_userclk_rx_active_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_clk_freerun_int;
   wire [0:0]  hb0_gtwiz_reset_clk_freerun_int = 1'b0;
   assign gtwiz_reset_clk_freerun_int[0:0] = hb0_gtwiz_reset_clk_freerun_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_all_int;
   wire [0:0]  hb0_gtwiz_reset_all_int = 1'b0;
   assign gtwiz_reset_all_int[0:0] = hb0_gtwiz_reset_all_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_tx_pll_and_datapath_int;
   wire [0:0]  hb0_gtwiz_reset_tx_pll_and_datapath_int;
   assign gtwiz_reset_tx_pll_and_datapath_int[0:0] = hb0_gtwiz_reset_tx_pll_and_datapath_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_tx_datapath_int;
   wire [0:0]  hb0_gtwiz_reset_tx_datapath_int;
   assign gtwiz_reset_tx_datapath_int[0:0] = hb0_gtwiz_reset_tx_datapath_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_rx_pll_and_datapath_int;
   wire [0:0]  hb0_gtwiz_reset_rx_pll_and_datapath_int = 1'b0;
   assign gtwiz_reset_rx_pll_and_datapath_int[0:0] = hb0_gtwiz_reset_rx_pll_and_datapath_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_rx_datapath_int;
   wire [0:0]  hb0_gtwiz_reset_rx_datapath_int = 1'b0;
   assign gtwiz_reset_rx_datapath_int[0:0] = hb0_gtwiz_reset_rx_datapath_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_rx_cdr_stable_int;
   wire [0:0]  hb0_gtwiz_reset_rx_cdr_stable_int;
   assign hb0_gtwiz_reset_rx_cdr_stable_int = gtwiz_reset_rx_cdr_stable_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_tx_done_int;
   wire [0:0]  hb0_gtwiz_reset_tx_done_int;
   assign hb0_gtwiz_reset_tx_done_int = gtwiz_reset_tx_done_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [0:0]  gtwiz_reset_rx_done_int;
   wire [0:0]  hb0_gtwiz_reset_rx_done_int;
   assign hb0_gtwiz_reset_rx_done_int = gtwiz_reset_rx_done_int[0:0];

   //--------------------------------------------------------------------------------------------------------------------
   wire [447:0] gtwiz_userdata_tx_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [447:0] gtwiz_userdata_rx_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [6:0]   gtrefclk01_int;
   wire [0:0]   cm0_gtrefclk01_int;
   wire [0:0]   cm1_gtrefclk01_int;
   wire [0:0]   cm2_gtrefclk01_int;
   wire [0:0]   cm3_gtrefclk01_int;
   wire [0:0]   cm4_gtrefclk01_int;
   wire [0:0]   cm5_gtrefclk01_int;
   wire [0:0]   cm6_gtrefclk01_int;
   assign gtrefclk01_int[0:0] = cm0_gtrefclk01_int;
   assign gtrefclk01_int[1:1] = cm1_gtrefclk01_int;
   assign gtrefclk01_int[2:2] = cm2_gtrefclk01_int;
   assign gtrefclk01_int[3:3] = cm3_gtrefclk01_int;
   assign gtrefclk01_int[4:4] = cm4_gtrefclk01_int;
   assign gtrefclk01_int[5:5] = cm5_gtrefclk01_int;
   assign gtrefclk01_int[6:6] = cm6_gtrefclk01_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [6:0]   qpll1outclk_int;
   wire [0:0]   cm0_qpll1outclk_int;
   wire [0:0]   cm1_qpll1outclk_int;
   wire [0:0]   cm2_qpll1outclk_int;
   wire [0:0]   cm3_qpll1outclk_int;
   wire [0:0]   cm4_qpll1outclk_int;
   wire [0:0]   cm5_qpll1outclk_int;
   wire [0:0]   cm6_qpll1outclk_int;
   assign cm0_qpll1outclk_int = qpll1outclk_int[0:0];
   assign cm1_qpll1outclk_int = qpll1outclk_int[1:1];
   assign cm2_qpll1outclk_int = qpll1outclk_int[2:2];
   assign cm3_qpll1outclk_int = qpll1outclk_int[3:3];
   assign cm4_qpll1outclk_int = qpll1outclk_int[4:4];
   assign cm5_qpll1outclk_int = qpll1outclk_int[5:5];
   assign cm6_qpll1outclk_int = qpll1outclk_int[6:6];

   //--------------------------------------------------------------------------------------------------------------------
   wire [6:0]   qpll1outrefclk_int;
   wire [0:0]   cm0_qpll1outrefclk_int;
   wire [0:0]   cm1_qpll1outrefclk_int;
   wire [0:0]   cm2_qpll1outrefclk_int;
   wire [0:0]   cm3_qpll1outrefclk_int;
   wire [0:0]   cm4_qpll1outrefclk_int;
   wire [0:0]   cm5_qpll1outrefclk_int;
   wire [0:0]   cm6_qpll1outrefclk_int;
   assign cm0_qpll1outrefclk_int = qpll1outrefclk_int[0:0];
   assign cm1_qpll1outrefclk_int = qpll1outrefclk_int[1:1];
   assign cm2_qpll1outrefclk_int = qpll1outrefclk_int[2:2];
   assign cm3_qpll1outrefclk_int = qpll1outrefclk_int[3:3];
   assign cm4_qpll1outrefclk_int = qpll1outrefclk_int[4:4];
   assign cm5_qpll1outrefclk_int = qpll1outrefclk_int[5:5];
   assign cm6_qpll1outrefclk_int = qpll1outrefclk_int[6:6];

   //--------------------------------------------------------------------------------------------------------------------
   wire [27:0]  rxprbscntreset_int;
   // This vector is not sliced because it is directly assigned in a debug core instance below

   //--------------------------------------------------------------------------------------------------------------------
   wire [111:0] rxprbssel_int;
   // This vector is not sliced because it is directly assigned in a debug core instance below

   //--------------------------------------------------------------------------------------------------------------------
   wire [27:0]  txprbsforceerr_int;
   // This vector is not sliced because it is directly assigned in a debug core instance below

   //--------------------------------------------------------------------------------------------------------------------
   wire [111:0] txprbssel_int;
   // This vector is not sliced because it is directly assigned in a debug core instance below

   //--------------------------------------------------------------------------------------------------------------------
   wire [27:0]  gtpowergood_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [27:0]  rxpmaresetdone_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [27:0]  rxprbserr_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [27:0]  rxprbslocked_int;

   //--------------------------------------------------------------------------------------------------------------------
   wire [27:0]  txpmaresetdone_int;


   // ===================================================================================================================
   // BUFFERS
   // ===================================================================================================================

   // Buffer the hb_gtwiz_reset_all_in input and logically combine it with the internal signal from the example
   // initialization block as well as the VIO-sourced reset
   wire         hb_gtwiz_reset_all_buf_int;
   wire         hb_gtwiz_reset_all_init_int;
   wire         hb_gtwiz_reset_all_int;
   wire         hb_gtwiz_reset_all_vio_int;

   assign hb_gtwiz_reset_all_int = reset_all || hb_gtwiz_reset_all_init_int || hb_gtwiz_reset_all_vio_int;

   // Instantiate a differential reference clock buffer for each reference clock differential pair in this configuration,
   // and assign the single-ended output of each differential reference clock buffer to the appropriate PLL input signal

   // Differential reference clock buffer for MGTREFCLK1_X0Y4
   wire         mgtrefclk1_x0y4_int;

   IBUFDS_GTE3
     #(
       .REFCLK_EN_TX_PATH  (1'b0),
       .REFCLK_HROW_CK_SEL (2'b00),
       .REFCLK_ICNTL_RX    (2'b00)
       )
   IBUFDS_GTE3_MGTREFCLK1_X0Y4_INST
     (
      .I     (mgtrefclk1_x0y4_p),
      .IB    (mgtrefclk1_x0y4_n),
      .CEB   (1'b0),
      .O     (mgtrefclk1_x0y4_int),
      .ODIV2 ()
      );

   // Differential reference clock buffer for MGTREFCLK1_X1Y2
   wire         mgtrefclk1_x1y2_int;

   IBUFDS_GTE3
     #(
       .REFCLK_EN_TX_PATH  (1'b0),
       .REFCLK_HROW_CK_SEL (2'b00),
       .REFCLK_ICNTL_RX    (2'b00)
       )
   IBUFDS_GTE3_MGTREFCLK1_X1Y2_INST
     (
      .I     (mgtrefclk1_x1y2_p),
      .IB    (mgtrefclk1_x1y2_n),
      .CEB   (1'b0),
      .O     (mgtrefclk1_x1y2_int),
      .ODIV2 ()
      );

   assign cm0_gtrefclk01_int = mgtrefclk1_x0y4_int;
   assign cm1_gtrefclk01_int = mgtrefclk1_x0y4_int;
   assign cm2_gtrefclk01_int = mgtrefclk1_x1y2_int;
   assign cm3_gtrefclk01_int = mgtrefclk1_x1y2_int;
   assign cm4_gtrefclk01_int = mgtrefclk1_x1y2_int;
   assign cm5_gtrefclk01_int = mgtrefclk1_x1y2_int;
   assign cm6_gtrefclk01_int = mgtrefclk1_x1y2_int;


   // ===================================================================================================================
   // USER CLOCKING RESETS
   // ===================================================================================================================

   // The TX user clocking helper block should be held in reset until the clock source of that block is known to be
   // stable. The following assignment is an example of how that stability can be determined, based on the selected TX
   // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
   assign hb0_gtwiz_userclk_tx_reset_int = ~(&txpmaresetdone_int);

   // The RX user clocking helper block should be held in reset until the clock source of that block is known to be
   // stable. The following assignment is an example of how that stability can be determined, based on the selected RX
   // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
   assign hb0_gtwiz_userclk_rx_reset_int = ~(&rxpmaresetdone_int);


   // ===================================================================================================================
   // PRBS STIMULUS, CHECKING, AND LINK MANAGEMENT
   // ===================================================================================================================

   // Declare a signal vector of PRBS match indicators, with one indicator bit per transceiver channel
   wire [27:0]  prbs_match_int;

   generate
      for (index=0; index<28; index=index+1)
        begin
           // PRBS stimulus
           // -------------------------------------------------------------------------------------------------------------------
           // PRBS-based data stimulus module for transceiver channel "index"
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_stimulus_raw example_stimulus_inst
                 (
                  .gtwiz_reset_all_in          (hb_gtwiz_reset_all_int),
                  .gtwiz_userclk_tx_usrclk2_in (hb0_gtwiz_userclk_tx_usrclk2_int),
                  .gtwiz_userclk_tx_active_in  (hb0_gtwiz_userclk_tx_active_int),
                  .txdata_out                  (gtwiz_userdata_tx_int[index*16+15:index*16])
                  );

           // PRBS checking
           // -------------------------------------------------------------------------------------------------------------------
           // PRBS-based data checking module for transceiver channel "index"
           gtwizard_ultrascale_0_example_checking_raw example_checking_inst0
             (
              .gtwiz_reset_all_in          (hb_gtwiz_reset_all_int || ~hb0_gtwiz_reset_rx_done_int ),
              .gtwiz_userclk_rx_usrclk2_in (hb0_gtwiz_userclk_rx_usrclk2_int),
              .gtwiz_userclk_rx_active_in  (hb0_gtwiz_userclk_rx_active_int),
              .rxdata_in                   (gtwiz_userdata_rx_int[index*16+15:index*16]),
              .prbs_match_out              (prbs_match_int[index])
              );

        end
   endgenerate

   // PRBS match and related link management
   // -------------------------------------------------------------------------------------------------------------------

   // Perform a bitwise NAND of all PRBS match indicators, creating a combinatorial indication of any PRBS mismatch
   // across all transceiver channels
   wire         prbs_error_any_async = ~(&prbs_match_int);
   wire         prbs_error_any_sync;

   // Synchronize the PRBS mismatch indicator the free-running clock domain, using a reset synchronizer with asynchronous
   // reset and synchronous removal
   (* DONT_TOUCH = "TRUE" *)
   gtwizard_ultrascale_0_example_reset_synchronizer reset_synchronizer_prbs_match_all_inst
     (
      .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
      .rst_in (prbs_error_any_async),
      .rst_out(prbs_error_any_sync)
      );

   // Implement an example link status state machine using a simple leaky bucket mechanism. The link status indicates
   // the continual PRBS match status to both the top-level observer and the initialization state machine, while being
   // tolerant of occasional bit errors. This is an example and can be modified as necessary.
   localparam ST_LINK_DOWN = 1'b0;
   localparam ST_LINK_UP   = 1'b1;
   reg          sm_link      = ST_LINK_DOWN;
   reg [6:0]    link_ctr     = 7'd0;

   always @(posedge hb_gtwiz_reset_clk_freerun_buf_int) begin
      case (sm_link)
        // The link is considered to be down when the link counter initially has a value less than 67. When the link is
        // down, the counter is incremented on each cycle where all PRBS bits match, but reset whenever any PRBS mismatch
        // occurs. When the link counter reaches 67, transition to the link up state.
        ST_LINK_DOWN: begin
           if (prbs_error_any_sync != 1'b0) begin
              link_ctr <= 7'd0;
           end
           else begin
              if (link_ctr < 7'd67)
                link_ctr <= link_ctr + 7'd1;
              else
                sm_link <= ST_LINK_UP;
           end
        end

        // When the link is up, the link counter is decreased by 34 whenever any PRBS mismatch occurs, but is increased by
        // only 1 on each cycle where all PRBS bits match, up to its saturation point of 67. If the link counter reaches
        // 0 (including rollover protection), transition to the link down state.
        ST_LINK_UP: begin
           if (prbs_error_any_sync != 1'b0) begin
              if (link_ctr > 7'd33) begin
                 link_ctr <= link_ctr - 7'd34;
                 if (link_ctr == 7'd34)
                   sm_link  <= ST_LINK_DOWN;
              end
              else begin
                 link_ctr <= 7'd0;
                 sm_link  <= ST_LINK_DOWN;
              end
           end
           else begin
              if (link_ctr < 7'd67)
                link_ctr <= link_ctr + 7'd1;
           end
        end
      endcase
   end

   // Synchronize the latched link down reset input and the VIO-driven signal into the free-running clock domain
   wire link_down_latched_reset_vio_int;
   wire link_down_latched_reset_sync;

   (* DONT_TOUCH = "TRUE" *)
   gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_link_down_latched_reset_inst
     (
      .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
      .i_in   (link_down_latched_rst || link_down_latched_reset_vio_int),
      .o_out  (link_down_latched_reset_sync)
      );

   // Reset the latched link down indicator when the synchronized latched link down reset signal is high. Otherwise, set
   // the latched link down indicator upon losing link. This indicator is available for user reference.
   always @(posedge hb_gtwiz_reset_clk_freerun_buf_int) begin
      if (link_down_latched_reset_sync)
        link_down_latched_out <= 1'b0;
      else if (!sm_link)
        link_down_latched_out <= 1'b1;
   end

   // Assign the link status indicator to the top-level two-state output for user reference
   assign link_status_out = sm_link;


   // ===================================================================================================================
   // INITIALIZATION
   // ===================================================================================================================

   // Declare the receiver reset signals that interface to the reset controller helper block. For this configuration,
   // which uses the same PLL type for transmitter and receiver, the "reset RX PLL and datapath" feature is not used.
   wire hb_gtwiz_reset_rx_pll_and_datapath_int = 1'b0;
   wire hb_gtwiz_reset_rx_datapath_int;

   // Combine the receiver reset signals form the initialization module and the VIO to drive the appropriate reset
   // controller helper block reset input
   wire       hb_gtwiz_reset_rx_pll_and_datapath_vio_int;
   wire       hb_gtwiz_reset_rx_datapath_init_int;

   assign hb_gtwiz_reset_rx_datapath_int = hb_gtwiz_reset_rx_datapath_init_int || hb_gtwiz_reset_rx_datapath_vio_int;

   // The example initialization module interacts with the reset controller helper block and other example design logic
   // to retry failed reset attempts in order to mitigate bring-up issues such as initially-unavilable reference clocks
   // or data connections. It also resets the receiver in the event of link loss in an attempt to regain link, so please
   // note the possibility that this behavior can have the effect of overriding or disturbing user-provided inputs that
   // destabilize the data stream. It is a demonstration only and can be modified to suit your system needs.

   // JS: don't re-initialize  when input "enable_error_in" is high
   gtwizard_ultrascale_0_example_init example_init_inst
     (
      .clk_freerun_in  (hb_gtwiz_reset_clk_freerun_buf_int),
      .reset_all_in    (hb_gtwiz_reset_all_int),
      .tx_init_done_in (gtwiz_reset_tx_done_int),
      .rx_init_done_in (gtwiz_reset_rx_done_int),
      .rx_data_good_in (sm_link || enable_error_in),
      .reset_all_out   (hb_gtwiz_reset_all_init_int),
      .reset_rx_out    (hb_gtwiz_reset_rx_datapath_init_int),
      .init_done_out   (init_done_int),
      .retry_ctr_out   (init_retry_ctr_int)
      );


   // ===================================================================================================================
   // VIO FOR HARDWARE BRING-UP AND DEBUG
   // ===================================================================================================================

   generate
      for (index=0; index < 28; index=index+1)
        begin
           // Synchronize gtpowergood into the free-running clock domain for VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_gtpowergood_inst
                 (
                  .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
                  .i_in   (gtpowergood_int[index]),
                  .o_out  (gtpowergood_vio_sync[index])
                  );

           // Synchronize txpmaresetdone into the free-running clock domain for VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_txpmaresetdone_inst
             (
              .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
              .i_in   (txpmaresetdone_int[index]),
              .o_out  (txpmaresetdone_vio_sync[index])
              );

           // Synchronize rxpmaresetdone into the free-running clock domain for VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_rxpmaresetdone_inst
             (
              .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
              .i_in   (rxpmaresetdone_int[index]),
              .o_out  (rxpmaresetdone_vio_sync[index])
              );

           // Synchronize rxprbserr into the free-running clock domain for VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_rxprbserr_inst
             (
              .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
              .i_in   (rxprbserr_int[index]),
              .o_out  (rxprbserr_vio_sync[index])
              );

           // Synchronize rxprbslocked into the free-running clock domain for VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_rxprbslocked_inst
             (
              .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
              .i_in   (rxprbslocked_int[index]),
              .o_out  (rxprbslocked_vio_sync[index])
              );

        end
   endgenerate

   // Synchronize gtwiz_reset_tx_done into the free-running clock domain for VIO usage
   wire [0:0]  gtwiz_reset_tx_done_vio_sync;

   (* DONT_TOUCH = "TRUE" *)
   gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_gtwiz_reset_tx_done_0_inst
     (
      .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
      .i_in   (gtwiz_reset_tx_done_int[0]),
      .o_out  (gtwiz_reset_tx_done_vio_sync[0])
      );

   // Synchronize gtwiz_reset_rx_done into the free-running clock domain for VIO usage

   (* DONT_TOUCH = "TRUE" *)
   gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_gtwiz_reset_rx_done_0_inst
     (
      .clk_in (hb_gtwiz_reset_clk_freerun_buf_int),
      .i_in   (gtwiz_reset_rx_done_int[0]),
      .o_out  (gtwiz_reset_rx_done_vio_sync[0])
      );


   wire [111:0] txprbssel_vio_async;
   generate
      for (index=0; index<112; index=index+1)
        begin
           // Synchronize txprbssel into the TXUSRCLK2 clock domain from VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_txprbssel_inst
                 (
                  .clk_in (hb0_gtwiz_userclk_tx_usrclk2_int),
                  .i_in   (txprbssel_vio_async[index]),
                  .o_out  (txprbssel_int[index])
                  );

           // Synchronize rxprbssel into the RXUSRCLK2 clock domain from VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_rxprbssel_inst
             (
              .clk_in (hb0_gtwiz_userclk_rx_usrclk2_int),
              .i_in   (rxprbssel_vio_async[index]),
              .o_out  (rxprbssel_int[index])
              );
        end
   endgenerate

   wire [27:0]  txprbsforceerr_vio_async;
   generate
      for (index=0; index<28; index=index+1)
        begin
           // Synchronize txprbsforceerr into the TXUSRCLK2 clock domain from VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_txprbsforceerr_inst
                 (
                  .clk_in (hb0_gtwiz_userclk_tx_usrclk2_int),
                  .i_in   (txprbsforceerr_vio_async[index]),
                  .o_out  (txprbsforceerr_int[index])
                  );

           // Synchronize rxprbscntreset into the RXUSRCLK2 clock domain from VIO usage
           (* DONT_TOUCH = "TRUE" *)
           gtwizard_ultrascale_0_example_bit_synchronizer bit_synchronizer_vio_rxprbscntreset_inst
             (
              .clk_in (hb0_gtwiz_userclk_rx_usrclk2_int),
              .i_in   (rxprbscntreset_vio_async[index]),
              .o_out  (rxprbscntreset_int[index])
              );

        end
   endgenerate

   // Instantiate the VIO IP core for hardware bring-up and debug purposes, connecting relevant debug and analysis
   // signals which have been enabled during Wizard IP customization. This initial set of connected signals is
   // provided as a convenience and example, but more or fewer ports can be used as needed; simply re-customize and
   // re-generate the VIO instance, then connect any exposed signals that are needed. Signals which are synchronous to
   // clocks other than the free-running clock will require synchronization. For usage, refer to Vivado Design Suite
   // User Guide: Programming and Debugging (UG908)
   gtwizard_ultrascale_0_vio_0 gtwizard_ultrascale_0_vio_0_inst
     (
      .clk         (hb_gtwiz_reset_clk_freerun_buf_int)
      ,.probe_in0  (link_status_out)
      ,.probe_in1  (link_down_latched_out)
      ,.probe_in2  (init_done_int)
      ,.probe_in3  (init_retry_ctr_int)
      ,.probe_in4  (gtpowergood_vio_sync)
      ,.probe_in5  (txpmaresetdone_vio_sync)
      ,.probe_in6  (rxpmaresetdone_vio_sync)
      ,.probe_in7  (gtwiz_reset_tx_done_vio_sync)
      ,.probe_in8  (gtwiz_reset_rx_done_vio_sync)
      ,.probe_in9  (rxprbserr_vio_sync)
      ,.probe_in10 (rxprbslocked_vio_sync)
      ,.probe_out0 (hb_gtwiz_reset_all_vio_int)
      ,.probe_out1 (hb0_gtwiz_reset_tx_pll_and_datapath_int)
      ,.probe_out2 (hb0_gtwiz_reset_tx_datapath_int)
      ,.probe_out3 (link_down_latched_reset_vio_int)
      ,.probe_out4 (txprbssel_vio_async)
      ,.probe_out5 (txprbsforceerr_vio_async)
      );


   // ===================================================================================================================
   // EXAMPLE WRAPPER INSTANCE
   // ===================================================================================================================

   // Instantiate the example design wrapper, mapping its enabled ports to per-channel internal signals and example
   // resources as appropriate
   gtwizard_ultrascale_0_example_wrapper example_wrapper_inst
     (
      .gthrxn_in                                (gthrxn_in)
      ,.gthrxp_in                               (gthrxp_in)
      ,.gthtxn_out                              (gthtxn_out)
      ,.gthtxp_out                              (gthtxp_out)
      ,.gtwiz_userclk_tx_reset_in               (gtwiz_userclk_tx_reset_int)
      ,.gtwiz_userclk_tx_srcclk_out             (gtwiz_userclk_tx_srcclk_int)
      ,.gtwiz_userclk_tx_usrclk_out             (gtwiz_userclk_tx_usrclk_int)
      ,.gtwiz_userclk_tx_usrclk2_out            (gtwiz_userclk_tx_usrclk2_int)
      ,.gtwiz_userclk_tx_active_out             (gtwiz_userclk_tx_active_int)
      ,.gtwiz_userclk_rx_reset_in               (gtwiz_userclk_rx_reset_int)
      ,.gtwiz_userclk_rx_srcclk_out             (gtwiz_userclk_rx_srcclk_int)
      ,.gtwiz_userclk_rx_usrclk_out             (gtwiz_userclk_rx_usrclk_int)
      ,.gtwiz_userclk_rx_usrclk2_out            (gtwiz_userclk_rx_usrclk2_int)
      ,.gtwiz_userclk_rx_active_out             (gtwiz_userclk_rx_active_int)
      ,.gtwiz_reset_clk_freerun_in              ({1{hb_gtwiz_reset_clk_freerun_buf_int}})
      ,.gtwiz_reset_all_in                      ({1{hb_gtwiz_reset_all_int}})
      ,.gtwiz_reset_tx_pll_and_datapath_in      (gtwiz_reset_tx_pll_and_datapath_int)
      ,.gtwiz_reset_tx_datapath_in              (gtwiz_reset_tx_datapath_int)
      ,.gtwiz_reset_rx_pll_and_datapath_in      ({1{hb_gtwiz_reset_rx_pll_and_datapath_int}})
      ,.gtwiz_reset_rx_datapath_in              ({1{hb_gtwiz_reset_rx_datapath_int}})
      ,.gtwiz_reset_rx_cdr_stable_out           (gtwiz_reset_rx_cdr_stable_int)
      ,.gtwiz_reset_tx_done_out                 (gtwiz_reset_tx_done_int)
      ,.gtwiz_reset_rx_done_out                 (gtwiz_reset_rx_done_int)
      ,.gtwiz_userdata_tx_in                    (gtwiz_userdata_tx_int)
      ,.gtwiz_userdata_rx_out                   (gtwiz_userdata_rx_int)
      ,.gtrefclk01_in                           (gtrefclk01_int)
      ,.qpll1outclk_out                         (qpll1outclk_int)
      ,.qpll1outrefclk_out                      (qpll1outrefclk_int)
      ,.drpaddr_in                              (drpaddr_in)
      ,.drpclk_in                               (drpclk_in)
      ,.drpdi_in                                (drpdi_in)
      ,.drpen_in                                (drpen_in)
      ,.drpwe_in                                (drpwe_in)
      ,.rxprbscntreset_in                       (rxprbscntreset_int)
      ,.rxprbssel_in                            (rxprbssel_int)
      ,.txprbsforceerr_in                       (txprbsforceerr_int)
      ,.txprbssel_in                            (txprbssel_int)
      ,.drpdo_out                               (drpdo_out)
      ,.drprdy_out                              (drprdy_out)
      ,.gtpowergood_out                         (gtpowergood_int)
      ,.rxpmaresetdone_out                      (rxpmaresetdone_int)
      ,.rxprbserr_out                           (rxprbserr_int)
      ,.rxprbslocked_out                        (rxprbslocked_int)
      ,.txpmaresetdone_out                      (txpmaresetdone_int)
      );

endmodule
