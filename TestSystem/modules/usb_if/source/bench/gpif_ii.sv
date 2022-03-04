//-----------------------------------------------------------------------------
// Title      : GPIF II Interface definition
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : gpif_ii.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-11-30
// Last update: 2015-11-30
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description:
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-30  1.0      mbonora        Created
//-----------------------------------------------------------------------------


`ifndef GPIF_II_IF_INCLUDED_V
 `define GPIF_II_IF_INCLUDED_V

interface gpif_ii_if;
   logic [1:0]  address;
   logic [31:0] data_ms;
   logic [31:0] data_sm;
   logic        data_t;
   logic        SLCS_n;
   logic        SLWR_n;
   logic        SLRD_n;
   logic        SLOE_n;
   logic        FLAGA;
   logic        FLAGB;
   logic        FLAGC;
   logic        FLAGD;
   logic        PKTEND_n;
   logic        PCLK;

   clocking cb @(posedge PCLK);
      input               #2ns data_ms;
      output              #2ns data_sm;
      output              #8ns FLAGA,FLAGB,FLAGC,FLAGD;
      input               address, SLCS_n, SLWR_n, SLRD_n, PKTEND_n;
   endclocking // slave_cb

   modport slave (input PCLK, clocking cb, input SLOE_n, output data_t);
   modport master (input data_sm,
		   input data_t,
		   output data_ms,
		   output address, SLCS_n, SLWR_n, SLRD_n, SLOE_n, PKTEND_n, PCLK,
		   input  FLAGA,FLAGB,FLAGC,FLAGD);

   // Assertions
   // SLWR and SLRD can never be 0 at the same time
   assert property (@(cb) SLWR_n || SLRD_n);
   assert property (@(cb) SLOE_n || SLWR_n);


endinterface // gpif_ii_if

`endif //  `ifndef GPIF_II_IF_INCLUDED_V
