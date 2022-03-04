//-----------------------------------------------------------------------------
// Title      : Main package for Fx3 components
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : fx3.sv
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-11-30
// Last update: 2015-11-30
// Platform   :
// Target     : Kintex 7 / Simulation
// Standard   : System Verilog
//-----------------------------------------------------------------------------
// Description: Groups all classes for the Fx3 device in a package
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-30  1.0      mbonora        Created
//-----------------------------------------------------------------------------

`include "gpif_ii.sv"
`timescale 1ps/1fs

`timescale 1ps/1fs

package Fx3Pkg;
`include "usb_fx3_buffer.sv"
`include "usb_fx3.sv"
`include "usb_comm.sv"
`include "communication.sv"
`include "chip.sv"
endpackage // Fx3Pkg
