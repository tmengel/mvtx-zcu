-------------------------------------------------------------------------------
-- Title      : tmr_pkg
-- Project    : RUv0_RDO
-------------------------------------------------------------------------------
-- File       : tmr_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-09-01
-- Last update: 2017-09-04
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Description: Package defining constant/signals used for TMR purposes
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tmr_pkg is

  -- Multiple Modular redundancy factor (only 3 implemented)
  constant C_K_TMR                  : integer := 3;

end package tmr_pkg;
