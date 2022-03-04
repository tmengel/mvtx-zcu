////////////////////////////////////////////////////////////////////////////////
// Title        : frequency_selector
// Project      : RUv1_Test
////////////////////////////////////////////////////////////////////////////////
// File         : frequency_selector.sv
// Author       : Matteo Lupi (matteo.lupi@cern.ch)
// Company      : Goethe Universitaet Frankfurt am Main / CERN
// Created      : 2015-03-21
// Last update  : 2016-03-21
// Platform     : Xilinx Vivado 2017.4
// Target       : Kintex-Ultrascale
// Standard     : S. Verilog
////////////////////////////////////////////////////////////////////////////////
// Description: frequency_selector.
//              Allows force of signal in VHDL (not allowed by cadence ius)
//
//              I2C frequency setting is:
//              (wb-frequency[MHz]/(5 * I2C-frequency[MHz])) - 1
//              wb-frequency = 160MHz
//              GBTx I2C f = 100kHz -> 0x13f
//              sim I2C  f = 8MHz -> 0x003
//
//              wb_frequency = 75MHz
//              GBTx I2C f = 100kHz -> 0x95
// ///////////////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2017-03-21  1.0      ML            Created
//-----------------------------------------------------------------------------

`timescale 1ns/10ps
module i2c_frequency_selector #(parameter int FREQ_SELECTION_BIT_WIDTH = 16)
  (
   output logic [FREQ_SELECTION_BIT_WIDTH-1:0] frequency_setting_o
  );

   assign frequency_setting_o = 'h0095;  // 100kHz

endmodule // frequency_selector

// needed for emacs verilog-auto mode
// Local Variables:
// verilog-library-directories:("." "../")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
