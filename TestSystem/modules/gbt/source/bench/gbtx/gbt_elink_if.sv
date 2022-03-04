//-----------------------------------------------------------------------------
// Title      : gbt_elink_if
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : gbt_elink_if.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2017-07-25
// Last update: 2017-07-25
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: GBT Elink Interface
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-07-25  1.0      mbonora        Created
//-----------------------------------------------------------------------------

`ifndef GBT_ELINK_IF_INCLUDED_V
 `define GBT_ELINK_IF_INCLUDED_V

interface gbt_elink_if;
   logic sClk;
   logic [1:0] dclk;
   logic [9:0] din;
   logic [9:0] dout;
   logic       tx_valid;
   logic       rx_valid;
   logic       rxrdy;
   logic       txrdy;


   clocking cb @(posedge sClk);
      output #8ns   dclk;
      input    din, rx_valid;
      output   dout, tx_valid;
      output   rxrdy, txrdy;
   endclocking // cb

   modport gbtx(clocking cb);
   modport fpga(input dclk,dout,tx_valid,
                output din,rx_valid,
                output rxrdy, txrdy);

endinterface // gbt_elink_if

package gbt;

`include "gbt_bfm.sv"
`include "gbt_comm.sv"

endpackage // gbt

`endif // GBT_ELINK_IF_INCLUDED_V
