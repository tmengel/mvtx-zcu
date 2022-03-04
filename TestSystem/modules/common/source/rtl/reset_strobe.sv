////////////////////////////////////////////////////////////////////////////////
// Title        : reset strobe
// Project      : RUv1_Test
////////////////////////////////////////////////////////////////////////////////
// File         : reset_strobe.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-03-21
// Last update  : 2016-03-21
// Platform     : Xilinx Vivado 2017.4
// Target       : Kintex-Ultrascale
// Standard     : S. Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: module for generating the rst strobe: allows resetting of simulation
//              via systemverilog signal force.
//              in ncsim forcing vhdl signal is not allowed
///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-03-21  1.0      ML            Created
//-----------------------------------------------------------------------------

`timescale 1ns/10ps
module reset_strobe
  (
   input logic  clock_locked_i, // input lock from MMCM
   output logic reset_strobe_o // output reset strobe
   );

   assign reset_strobe_o = !clock_locked_i;

endmodule // watchdog

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
