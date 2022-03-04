//-----------------------------------------------------------------------------
// Title      : Buffer LVDS2DIFF with programmable delay
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : LVDS2LVDS_delay.sv
// Author     : Matteo Lupi (Matteo.Lupi@cern.ch)
// Company    : CERN / Universitaet Frankfurt am Main
// Created    : 2017-01-25
// Last update: 2017-01-25
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Bidirectional level translator LVDS2LVDS and LVDS2LVDS with DIR signal
//
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-01-25  1.0      mlupi         Created
//-----------------------------------------------------------------------------

`timescale 1ps/1fs

module LVDS2LVDS_delay#(parameter time base_delay = 1ps)
   (
    input logic   IN_P,
    input logic   IN_N,
    output logic  OUT_P,
    output logic  OUT_N,
    input int     lvds2lvds_delay);

   logic        out_p;
   logic        out_n;

   always @(IN_P, IN_N) begin
      fork
         begin
            automatic logic in_P_thread = IN_P;
            automatic logic in_N_thread = IN_N;

            for (int k=0; k < lvds2lvds_delay; k++)
              #base_delay;

            out_p <= in_P_thread;
            out_n <= in_N_thread;
         end
      join_none;
   end

   assign OUT_P = out_p;
   assign OUT_N = out_n;

endmodule // LVDS2LVDS_delay
