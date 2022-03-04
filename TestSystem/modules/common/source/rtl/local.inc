/*
  Project local defines
*/

`timescale 1ns/1ps

// propagation delay for simulation
// synopsys translate_off
`define __NO_SYNTESIS__ 
// synopsys translate_on

`ifdef __NO_SYNTESIS__
        `define Tp #0.1
`else
        `define Tp
        `define __IN_SYNTESIS__
`endif

