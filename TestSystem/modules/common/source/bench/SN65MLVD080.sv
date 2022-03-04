//-----------------------------------------------------------------------------
// Title      : Buffer CMOS2DIFF with programmable delay
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : SN65MLVD080.sv
// Author     : Matteo Lupi (Matteo.Lupi@cern.ch)
// Company    : CERN / Universitaet Frankfurt am Main
// Created    : 2017-07-28
// Last update: 2017-07-28
// Platform   :
// Target     : Kintex US / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Bidirectional level translator CMOS2LVDS and LVDS2CMOS with DIR signal
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------

`timescale 1ps/1fs

module SN65MLVD080
  #(parameter time base_delay = 100ps,
    int G_SIZE = 8)
   (
    inout logic [G_SIZE-1:0]  P,
    inout logic [G_SIZE-1:0]  N,
    input logic [G_SIZE-1:0]  D,
    output logic [G_SIZE-1:0] R,
    input logic [G_SIZE-1:0]  DE,
    input logic               REn,
    input int                 cmos2lvds_delay,
    input int                 lvds2cmos_delay);

   generate
      for (genvar i=0; i<G_SIZE; i++) begin
         SN65MLVD_channel
                    #(
                      // Parameters
                      .base_delay       (base_delay)
                      /*autoinstparam*/)
         SN65MLVD_channel
                    (
                     // Inouts
                     .P       (P[i]),
                     .N       (N[i]),
                     // Outputs
                     .R       (R[i]),
                     // Inputs
                     .DE      (DE[i]),
                     .D       (D[i]),
                     .REn     (REn),
                     .cmos2lvds_delay      (cmos2lvds_delay),
                     .lvds2cmos_delay      (lvds2cmos_delay)
                     /*autoinst*/);
      end
   endgenerate

endmodule // SN65MLVD080

// needed for emacs verilog-auto mod
// Local Variables:
// verilog-library-directories:("." "./assertions")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
