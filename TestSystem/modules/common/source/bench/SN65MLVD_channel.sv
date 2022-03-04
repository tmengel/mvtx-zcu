//-----------------------------------------------------------------------------
// Title      : Buffer CMOS2DIFF with programmable delay
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : SN65MLVD_channel.sv
// Author     : Matteo Lupi (Matteo.Lupi@cern.ch)
// Company    : CERN / Universitaet Frankfurt am Main
// Created    : 2017-06-28
// Last update: 2017-06-28
// Platform   :
// Target     : Kintex US / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Bidirectional level translator CMOS2LVDS and LVDS2CMOS with DIR signal
//
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------

`timescale 1ps/1fs

module SN65MLVD_channel#(parameter time base_delay = 100ps)
   (
    inout logic  P,
    inout logic  N,
    input logic  D,
    output logic R,
    input logic  DE,
    input logic  REn,
    input int    cmos2lvds_delay,
    input int    lvds2cmos_delay);

   logic         alpideDctrlP;
   logic         alpideDctrlN;
   logic         alpideDctrlD;
   logic         alpideDctrlR;

   always @(D, DE) begin
      fork
         begin
            automatic logic alpideDctrlDir_thread = DE;
            automatic logic alpideDctrlD_thread = D;

            for (int k=0; k < cmos2lvds_delay; k++)
              #base_delay;

            alpideDctrlP <= (alpideDctrlDir_thread) ? alpideDctrlD_thread: 'z;
            alpideDctrlN <= (alpideDctrlDir_thread) ? ~alpideDctrlD_thread : 'z;
         end
      join_none;
   end

   always @(P, N, REn) begin
      fork
         begin
            automatic logic alpideDctrlDir_thread = REn;
            automatic logic alpideDctrlP_thread = P;
            automatic logic alpideDctrlN_thread = N;

            for (int k=0; k < lvds2cmos_delay; k++)
              #base_delay;

            alpideDctrlR <= (alpideDctrlDir_thread) ? 'z : alpideDctrlP_thread;
         end
      join_none;
   end

   assign P = alpideDctrlP;
   assign N = alpideDctrlN;
   assign R = alpideDctrlR;

endmodule // SN65MLVD_channel

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "./assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
