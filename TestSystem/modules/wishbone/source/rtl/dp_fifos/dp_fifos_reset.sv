///////////////////////////////////////////////////////////////////////////////
// Title        : dp_fifos_reset module
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
module dp_fifos_reset
  #(
    parameter int FifoSyncStages = 3, // synch stages of the fifo
    parameter int StateBitWidth = 3 // number of state bits for the fifo
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


   (* fsm_encoding = "sequential" *) logic [StateBitWidth-1:0]   state_s, state_voted_s;
   localparam [StateBitWidth:0]  WAIT_FOR_RST_STATE = 'd0, // IDLE
     RST_ONGOING_STATE_0  = 'd1, // RST is ongoing if FifoSyncStages is more than 3, this FSM needs to be modified
     RST_ONGOING_STATE_1  = 'd2, // RST is ongoing if FifoSyncStages is more than 3, this FSM needs to be modified
     RST_ONGOING_STATE_2  = 'd3, // RST is ongoing if FifoSyncStages is more than 3, this FSM needs to be modified
     WAIT_FOR_BUSY_OFF_STATE = 'd4, // waits for fifo to be ready
     DONE_STATE = 'd5, // waits for fifo to be ready
     ERROR_STATE = 'd6; // ERROR due to SEU

   assign actual_state_o = state_s;
   assign state_voted_s = actual_state_i;

  xpm_cdc_async_rst
    #(
      .DEST_SYNC_FF    (2),
      .INIT_SYNC_FF    (0),
      .RST_ACTIVE_HIGH (1)
      )
     sync_rst_dp1_INST
       (
     .src_arst  (arst_i),
     .dest_clk  (slower_clk_i),
     .dest_arst (arst_s)
     );

   // FSM next state
   always @(posedge slower_clk_i) begin
      case(state_voted_s)
        WAIT_FOR_RST_STATE:
          state_s <= (arst_s == 1'b1)? RST_ONGOING_STATE_0:WAIT_FOR_RST_STATE;
        RST_ONGOING_STATE_0:
          state_s <= RST_ONGOING_STATE_1;
        RST_ONGOING_STATE_1:
          state_s <= RST_ONGOING_STATE_2;
        RST_ONGOING_STATE_2: // if reset is still active, stays in reset, else if not busy goes to idle
          state_s <= (arst_s == 1'b1)? RST_ONGOING_STATE_2 : (fifo_rd_reset_is_busy_i == 1'b1 || fifo_wr_reset_is_busy_i == 1'b1)? WAIT_FOR_BUSY_OFF_STATE: DONE_STATE;
        WAIT_FOR_BUSY_OFF_STATE:
          state_s <= (fifo_rd_reset_is_busy_i == 1'b1 || fifo_wr_reset_is_busy_i == 1'b1)? WAIT_FOR_BUSY_OFF_STATE: DONE_STATE;
        DONE_STATE:
          state_s <= (arst_s == 1'b1)? RST_ONGOING_STATE_0:WAIT_FOR_RST_STATE;
        ERROR_STATE:
          state_s <= WAIT_FOR_RST_STATE;
        default:
          state_s <= ERROR_STATE;
      endcase
   end

   // FSM output combinatorial part
   always @(state_voted_s) begin
      case (state_voted_s)
        WAIT_FOR_RST_STATE: begin
           fifo_rst_o      <= 1'b0;
           fifo_rst_done_o <= 1'b0;
           seeerr_sig_o    <= 1'b0;
        end
        RST_ONGOING_STATE_0: begin
           fifo_rst_o      <= 1'b1;
           fifo_rst_done_o <= 1'b0;
           seeerr_sig_o    <= 1'b0;
        end
        RST_ONGOING_STATE_1: begin
           fifo_rst_o      <= 1'b1;
           fifo_rst_done_o <= 1'b0;
           seeerr_sig_o    <= 1'b0;
        end
        RST_ONGOING_STATE_2: begin
           fifo_rst_o      <= 1'b1;
           fifo_rst_done_o <= 1'b0;
           seeerr_sig_o    <= 1'b0;
        end
        WAIT_FOR_BUSY_OFF_STATE: begin
           fifo_rst_o      <= 1'b0;
           fifo_rst_done_o <= 1'b0;
           seeerr_sig_o    <= 1'b0;
        end
        DONE_STATE: begin
           fifo_rst_o      <= 1'b0;
           fifo_rst_done_o <= 1'b1;
           seeerr_sig_o    <= 1'b0;
        end
        ERROR_STATE: begin
           fifo_rst_o      <= 1'b0;
           fifo_rst_done_o <= 1'b0;
           seeerr_sig_o    <= 1'b1;
        end

        default: begin
           fifo_rst_o      <= 1'b0;
           fifo_rst_done_o <= 1'b0;
           seeerr_sig_o    <= 1'b0;
        end
      endcase
   end // always @ (state_voted_s)

   //////////////////////////////////////////////
   // Assertions
   // synthesis translate_off
   //////////////////////////////////////////////

   default clocking cb @(posedge slower_clk_i);
      input arst_s;
      input fifo_wr_reset_is_busy_i;
      input fifo_rd_reset_is_busy_i;
      input fifo_rst_o;
      input fifo_rst_done_o;
      input seeerr_sig_o;
      input actual_state_o;
      input actual_state_i;
   endclocking // cb

   import common_assertions::*;
   // assertions
   rst_out_high_assert:  assert property(check_duration_single_bit_atleast(.line(cb.fifo_rst_o),
								           .duration('d3),
								           .disable_signal(1'b0)))
     else $error("fifo_rst_o is not high long enough");

   rst_out_then_reset_done: assert property(@(posedge slower_clk_i) (cb.fifo_rst_o == 1) ##1 (cb.fifo_rst_o == 0) |-> (cb.fifo_rst_done_o == 1'b0)[*1:$] ##1 (cb.fifo_rst_done_o == 1'b1))
     else $error("reset done is not asserted at the end of reset");

   // to be completed
   //rst_started_no_new_reset_in: assert @(posedge slower_clk_i) (cb.rst_i == 0) ##1 (cb.rst_i == 1) ##1 (cb.fifo_rst_o == 1) |-> (cb.rst_i == 0)
   //  else $error("New reset came before end of current reset");

   // coverage
   rst_in:  cover property($rose(cb.arst_s));
   rst_out:  cover property($rose(cb.fifo_rst_o));
   rst_done:  cover property($rose(cb.fifo_rst_done_o));

   // synthesis translate_on

endmodule // dp_fifos_reset

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "./assertions/" "./../../../../common/source/rtl/common/assertions/")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
