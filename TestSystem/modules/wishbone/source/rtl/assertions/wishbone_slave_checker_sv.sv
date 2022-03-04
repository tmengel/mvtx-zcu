//-----------------------------------------------------------------------------
// Title      : Wishbone Slave Checker Sv
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : wishbone_slave_checker_sv.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2017-02-22
// Last update: 2017-02-22
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Define Coverage bins for the Wishbone Slave module
//-----------------------------------------------------------------------------
// Copyright (c)   2017
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-02-22  1.0      mbonora        Created
//-----------------------------------------------------------------------------

module wishbone_slave_checker_sv #(parameter int NR_ADDRESSES = 0)
   (
    input        wb_clk,
    input        wb_rst,
    input [15:0] dat_i,
    input        we_i,
    input [7:0]  addr_i,
    input        cyc_i,
    input        stb_i,
    input [15:0] dat_o,
    input        err_o,
    input        ack_o
    );

   default clocking cb @(posedge wb_clk);
      input wb_clk;
      input wb_rst;
      input dat_i;
      input we_i;
      input addr_i;
      input cyc_i;
      input stb_i;
      input dat_o;
      input err_o;
      input ack_o;
   endclocking // cb

   // Assertions

//   property reply_on_strobe;
//      disable iff(cb.wb_rst || !cb.cyc_i)
//        (cb.stb_i && cb.cyc_i) |-> s_eventually (cb.err_o || cb.ack_o);
//   endproperty // ack_on_strobe


//   assert property (reply_on_strobe);


   event    slave_active;

   always@(cb)
      if (cb.stb_i && cb.cyc_i)
        -> slave_active;

   covergroup CoverWishboneAccess@(slave_active);
      option.per_instance = 1;
      addr: coverpoint cb.addr_i {
         bins existing[] = {[0:NR_ADDRESSES-1]};
         bins non_existing = {[NR_ADDRESSES:$]};
      }
      write: coverpoint cb.we_i {
         bins write = {1};
         bins read = {0};
      }
      cross addr, write;

   endgroup // CoverWishboneAccess

   CoverWishboneAccess coverwishboneaccess_inst = new();

endmodule // wishbone_slave_checker_coverbins
