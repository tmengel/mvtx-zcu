////////////////////////////////////////////////////////////////////////////////
// Title        : wishbone watchdog
// Project      : Probecard
////////////////////////////////////////////////////////////////////////////////
// File         : watchdog.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-07-05
// Last update  : 2016-07-05
// Platform     : Xilinx Vivado 2015.4
// Target       : Kintex-7
// Standard     : S. Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: wishbone watchdog
///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-07-05  1.0      ML            Created
// 2016-07-06  1.1      ML            Added assertions for sim checking
//-----------------------------------------------------------------------------

`timescale 1ns/10ps
module watchdog #(parameter int TIMEOUT_BIT_WIDTH = 16)
  (
    input                              clk_i, // clock input
    input                              rst_i, // synchronous reset input

    input                              stb_i, // strobe input
    input                              cyc_i, // cycle input
    output reg                         err_o, // error output

    input [TIMEOUT_BIT_WIDTH-1:0]      actual_state_i,
    output reg [TIMEOUT_BIT_WIDTH-1:0] actual_state_o,
    // timeout
    input [TIMEOUT_BIT_WIDTH-1:0]      timeout_i // timeout value
  );

  logic                               s_transaction_active;
  logic [TIMEOUT_BIT_WIDTH-1:0]       s_counter;
  logic                               s_rst_cntr; // resets the upcounter

   assign s_transaction_active = cyc_i & stb_i;

  upcounter_core
  #(
    .BIT_WIDTH(TIMEOUT_BIT_WIDTH),
    .VERBOSE(1'b0),
    .IS_SATURATING(1'b0) // default
  )
  INST_TIMEOUT_UPCOUNTER
  (
    .CLK(clk_i),
    .RST(rst_i),
    .RST_CNT(s_rst_cntr),
    .CNT_UP(s_transaction_active),
    .CNT_VALUE(s_counter),
    .ACTUAL_STATE_O(actual_state_o),
    .ACTUAL_STATE_I(actual_state_i)
  );

  logic                      s_is_equal;
  assign s_is_equal = (s_counter == timeout_i);
  assign s_rst_cntr = (!s_transaction_active) ? 1'b1 : ((s_counter == timeout_i) ? 1'b1 : 1'b0);
  assign err_o      = (!s_transaction_active) ? 1'b0 : ((s_counter == timeout_i) ? 1'b1 : 1'b0);

  // synthesis translate_off
  always @(posedge clk_i)
  begin
    assert (err_o == 1'b0) else $warning("Timeout generated by wishbone Watchdog!");
  end
  // synthesis translate_on
endmodule // watchdog
