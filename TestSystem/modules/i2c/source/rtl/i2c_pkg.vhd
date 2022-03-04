-- $Id$
-------------------------------------------------------------------------------
-- Title      : I2C Interface - Common definitions
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : i2c_pkg.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2017-03-03
-- Last update: 2017-03-03
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Constants used in I2C module
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package i2c_pkg is

  -- number of I2C busses in project
  constant C_NUM_I2C : natural := 2;

end package i2c_pkg;
