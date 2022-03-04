////////////////////////////////////////////////////////////////////////////////
// Title        : Wishbone master fsm
// Project      : ALICE ITS WP10
////////////////////////////////////////////////////////////////////////////////
// File         : wbmstr_fsm.sv
// Author       : Krzysztof Marek Sielewicz
// Company      : Warsaw University of Technology / CERN
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-10-12
// Last update  : 2017-08-02
// Platform     : Xilinx Vivado 2015.4
// Target       : Kintex-7
// Standard     : SystemVerilog
////////////////////////////////////////////////////////////////////////////////
// Description: Wishbone master fsm
///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-10-12  1.0      KMS           Created
// 2016-07-05  1.3      ML            Added wishbone error signal, with the two
//                                    new states (WRERRSIG and RDERRSIG) the cyc
//                                    and stb are sent to 0 upon error receiving
// 2016-07-11  2.0      ML            Parametrized ports width and switch to sv
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module wbmstr_fsm #(
                    parameter int StateBitWidth = 4 // bitwidth of the fsm state
                    )
   (
    input                      clk_i, // clock input
    input                      rst_i, // synchronous reset input

    // wishbone bus signals
    output reg                 we_o, // write enable output
    output reg                 stb_o, // strobe output
    input                      ack_i, // acknowledge input
    input                      err_i, // error input
    output reg                 cyc_o, // cycle output

    // data port 0 FIFO (wbmstr receives data from that FIFO)
    input                      dp0_epty_i, // data port 0 empty input
    output reg                 dp0_rd_o, // data port 0 read output

    // data port 1 FIFO (wbmstr writes data to that FIFO)
    input                      dp1_full_i, // data port 1 full input
    output reg                 dp1_wr_o, // data port 1 write output

    // error counters
    output reg                 wrerr_sig_o, rderr_sig_o, // error signaling: to be used for upcounter
    output reg                 seeerr_sig_o, // error signaling: to be used for upcounter

    // register latch of DP fifo registers
    output reg                 ltchDtDP0_o, ltchDtDP1_o,

    // write flag from fifo DP0
    input                      wrFlag_i,

    // fsm state
    output [StateBitWidth-1:0] actual_state_o,
    input [StateBitWidth-1:0]  actual_state_i
    );

   (* fsm_encoding = "sequential" *) reg [StateBitWidth-1:0]   state_r, state_voted_r;
   localparam  [StateBitWidth-1:0] IDLE      = 'd0,   // IDLE       - waiting for data in the DP0 FIFO
     RDDTDP0   = 'd1,   // RDDTDP0    - read data from the DP0 FIFO
     WTDTDP0   = 'd2,   // WTDTDP0    - wait for the data from the DP0 FIFO
     LTCHDTDP0 = 'd3,   // LTCHDTDP0  - latch the data from the DP0 FIFO
     PRCSDT    = 'd4,   // PRCSDT     - process the received data, go to read or write operation
     WRDTWB    = 'd5,   // WRDTWB     - write data to the wishbone slave
     WRWTACK   = 'd6,   // WRWTACK    - wait for the acknowledge after write
     RDDTWB    = 'd7,   // RDDTWB     - read data from the wishbone slave
     RDWTACK   = 'd8,   // RDWTACK    - wait for data from the slave
     RDCHKFLL  = 'd9,   // RDCHKFLL   - check whether the DP1 FIFO is ful
     WRDTFIFO  = 'd10,  // WRDTFIFO   - write data to the DP1 FIFO
     WRERRSIG  = 'd11,  // WRERRSIG   - signals an error
     RDERRSIG  = 'd12,  // RDERRSIG   - signals an error
     SEU_ERR   = 'd15;  // FSM ERROR STATE (SEU) - signals an SEU error


   assign actual_state_o = state_r;
   assign state_voted_r = actual_state_i;

   // FSM state changing part
   always @(posedge clk_i) begin
      if (rst_i) begin
         state_r <= IDLE;
      end else begin
         case(state_voted_r)
           IDLE:       // 0
             state_r <= (!dp0_epty_i) ? RDDTDP0 : IDLE;
           RDDTDP0:    // 1
             state_r <= WTDTDP0;
           WTDTDP0:    // 2
             state_r <= LTCHDTDP0;
           LTCHDTDP0:  // 3
             state_r <= PRCSDT;
           PRCSDT:     // 4
             state_r <= (wrFlag_i) ? WRDTWB : RDDTWB;
           WRDTWB:     // 5
             state_r <= WRWTACK;
           WRWTACK:    // 6
             state_r <= (err_i) ? WRERRSIG : ((ack_i) ? IDLE : WRWTACK);
           RDDTWB:     // 7
             state_r <= RDWTACK;
           RDWTACK:    // 8
             state_r <= (err_i) ? RDERRSIG : ((ack_i) ? RDCHKFLL : RDWTACK);
           RDERRSIG:   // 12
             state_r <= RDCHKFLL;
           RDCHKFLL:   // 9
             state_r <= (!dp1_full_i) ? WRDTFIFO : RDCHKFLL;
           WRDTFIFO:   // 10
             state_r <= IDLE;
           WRERRSIG:   // 11
             state_r <= IDLE;
           SEU_ERR:      // 15
             state_r <= IDLE;
           default:
             state_r <= SEU_ERR;
         endcase
      end
   end

   // FSM combinatorial part
   always @(state_voted_r) begin
      case (state_voted_r)
        IDLE: begin // 0
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        RDDTDP0: begin // 1
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b1;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        WTDTDP0: begin // 2
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        LTCHDTDP0: begin // 3
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b1;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        PRCSDT: begin // 4
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        WRDTWB: begin // 5
           we_o        <= 1'b1;
           stb_o       <= 1'b1;
           cyc_o       <= 1'b1;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        WRWTACK: begin // 6
           we_o        <= 1'b1;
           stb_o       <= 1'b1;
           cyc_o       <= 1'b1;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        RDDTWB: begin // 7
           we_o        <= 1'b0;
           stb_o       <= 1'b1;
           cyc_o       <= 1'b1;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        RDWTACK: begin // 8
           we_o        <= 1'b0;
           stb_o       <= 1'b1;
           cyc_o       <= 1'b1;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b1;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        RDCHKFLL: begin // 9
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        WRDTFIFO: begin // 10
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b1;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        WRERRSIG: begin // 11
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b1;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end

        RDERRSIG: begin // 12
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b1;
           seeerr_sig_o  <= 1'b0;
        end

        SEU_ERR: begin // 15
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b1;
        end

        default: begin
           we_o        <= 1'b0;
           stb_o       <= 1'b0;
           cyc_o       <= 1'b0;
           dp0_rd_o    <= 1'b0;
           dp1_wr_o    <= 1'b0;
           ltchDtDP0_o <= 1'b0;
           ltchDtDP1_o <= 1'b0;
           wrerr_sig_o   <= 1'b0;
           rderr_sig_o   <= 1'b0;
           seeerr_sig_o  <= 1'b0;
        end
      endcase
   end // always @ (state_r)

endmodule

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
