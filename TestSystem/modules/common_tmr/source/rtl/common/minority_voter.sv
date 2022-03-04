//-----------------------------------------------------------------------------
// Title         : minority_voter
// Project       : RUv1
//-----------------------------------------------------------------------------
// File          : minority_voter.sv
// Author        : Matteo Lupi <matteo.lupi@cern.ch>
// Created       : 05.04.2017
// Last modified : 05.04.2017
//-----------------------------------------------------------------------------
// Description :
// Minority voter implemented as described in the XAPP197
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module minority_voter
   (
   (* dont_touch = "true" *) input logic       primary_i, // primary input, connect here the signal which will be connected to the I port of the OBUF
   (* dont_touch = "true" *) input logic [1:0] reference_i, // reference inputs, connect here the signals which will not be connected to the I port of the OBUF
   (* dont_touch = "true" *) output logic      driver_tristate_o // tristate, connect this signal to the T port of the OBUF relative to the primary_i
   );

   (* dont_touch = "true" *) assign driver_tristate_o = ((primary_i == 1'b1 && reference_i == 2'b00)||(primary_i == 1'b0 && reference_i == 2'b11)) ? 1'b1 : 1'b0;

endmodule // minority_voter

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
