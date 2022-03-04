////////////////////////////////////////////////////////////////////////////////
// Title        : Wait Module
// Project      : Probecard
////////////////////////////////////////////////////////////////////////////////
// File         : waitmodule.v
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2016-07-12
// Last update  : 2016-07-12
// Platform     : Xilinx Vivado 2015.4
// Target       : Kintex-7
// Standard     : Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: Wait module
///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-07-12  1.0      ML            Created
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module wtmdl #( parameter WbDataWidth=16 )
   (
    input                   clk_i, // clk input
    input                   rst_i, // rst input

    input                   wait_start_i, // wait start input
    input [WbDataWidth-1:0] wait_value_i, // wait value input
    output logic            wait_done_o // wait done output
    );

   logic [WbDataWidth-1:0]  wait_value_s;
   logic                    rst_upcounter_s;
   logic                    cntup_s;

   //FSM state
   typedef enum { RESET = 0, // RESET STATE
                  IDLE = 1, // IDLE STATE
                  WAIT = 2, // WAIT STATE
                  WAITDONE = 3} state_t; // WAIT DONE
   state_t state_r;

   // FSM state changing part
   always @(posedge clk_i) begin
      if (rst_i) begin
         state_r <= IDLE;
      end else begin
         case(state_r)
           RESET:       // 0
             state_r <= IDLE;
           IDLE:       // 1
             state_r <= (wait_start_i) ? WAIT : IDLE;
           WAIT:    // 2
             state_r <= (wait_value_i == wait_value_s) ? WAITDONE : WAIT;
           WAITDONE: // 3
             state_r <= IDLE;
           default:
             state_r <= IDLE;
         endcase
      end
   end

   // FSM combinatorial part
   always @(state_r) begin
      case (state_r)
        RESET: begin // 0
           wait_done_o <= 1'b0;
           rst_upcounter_s <= 1'b1;
           cntup_s <= 1'b0;
        end

        IDLE: begin // 1
           wait_done_o <= 1'b0;
           rst_upcounter_s <= 1'b0;
           cntup_s <= 1'b0;
        end

        WAIT: begin // 2
           wait_done_o <= 1'b0;
           rst_upcounter_s <= 1'b0;
           cntup_s <= 1'b1;
        end

        WAITDONE: begin // 3
           wait_done_o <= 1'b1;
           rst_upcounter_s <= 1'b1;
           cntup_s <= 1'b0;
        end

        default: begin
           wait_done_o <= 1'b0;
           rst_upcounter_s <= 1'b1;
           cntup_s <= 1'b0;
        end
      endcase
   end // always @ (state_r)

   wire [WbDataWidth-1:0] s_actual_state;
   // error counters
   upcounter_core #(
               .BIT_WIDTH(WbDataWidth),
               .IS_SATURATING(1'b0),
               .VERBOSE(1'b1)
               )
   INST_WAIT_UPCOUNTER(
                        .CLK(clk_i),
                        .RST(rst_i),
                        .RST_CNT(rst_upcounter_s),
                        .CNT_UP(cntup_s),
                        .CNT_VALUE(wait_value_s),
                        .ACTUAL_STATE_O(s_actual_state),
                        .ACTUAL_STATE_I(s_actual_state)
                        );

endmodule // wtmdl
