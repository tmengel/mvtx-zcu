//-----------------------------------------------------------------------------
// Title         : reg no vote
// Project       : RUv0
//-----------------------------------------------------------------------------
// File          : reg_novotes.sv
// Author        : Matteo Lupi  <mlupi@pcphaiddt001.cern.ch>
// Created       : 01.03.2017
// Last modified : 01.03.2017
//-----------------------------------------------------------------------------
// Description :
// register without vote for tmr studies
// the value forwarded to the output is the LSB
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by CERN This model is the confidential and
// proprietary property of CERN and the possession or use of this
// file requires a written license from CERN.
//------------------------------------------------------------------------------

`timescale 1ps/1ps

module reg_novote
  #(parameter int K_MMR = 3,  // K value used for K-modular redundancy
    parameter bit RESET_VALUE = 1'b0
    )
   (input logic clk_i, rst_i,
    input logic  D_i[K_MMR-1:0],
    output logic Q_o [K_MMR-1:0],
    output logic mismatch_o
    );

   logic         q_s;

   always @(posedge clk_i)
        if (rst_i)
          Q_o <= {K_MMR{RESET_VALUE}};
        else
          Q_o <= {K_MMR{D_i[0]}};

   assign mismatch_o = 1'b0;
endmodule // reg_novote

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../assertions/." "../.")
// verilog-library-extensions:(".v" ".h" ".sv" ".svh")
// End:
