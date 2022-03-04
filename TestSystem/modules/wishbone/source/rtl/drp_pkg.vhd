-------------------------------------------------------------------------------
-- Title      : Wishbone to TMR DRP Bridge
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : drp_pkg.vhd
-- Author     : Emanuele Canessa <e.canessa@cern.ch>
-- Company    : CERN / Politecnico di Torino
-- Created    : 2017-10-12
-- Last update: 2018-06-07
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Dynamic Reconfiguration Port package
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Rev  Author  Description
-- 2017-10-13  1.0  EC      Initial relase
-------------Q------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

package drp_pkg is

  constant DRP_ADDR_WIDTH       : integer := 9;
  constant DRP_DATA_WIDTH       : integer := 16;
  constant DRP_LANE_WIDTH       : integer := 5;
  constant C_DRP_MISMATCH_WIDTH : integer := 1;
  
  type drp_mosi_type is record
    den  : std_logic;
    dwe  : std_logic;
    addr : std_logic_vector (DRP_ADDR_WIDTH-1 downto 0);
    di   : std_logic_vector (DRP_DATA_WIDTH-1 downto 0);
  end record; -- drp_mosi_type

  type drp_miso_type is record
    do   : std_logic_vector (DRP_DATA_WIDTH-1 downto 0);
    drdy : std_logic;
  end record; -- drp_miso_type

  type drp_addr_array_type is array (natural range <>) of std_logic_vector (DRP_ADDR_WIDTH-1 downto 0);
  type drp_di_array_type   is array (natural range <>) of std_logic_vector (DRP_DATA_WIDTH-1 downto 0);
  type drp_do_array_type   is array (natural range <>) of std_logic_vector (DRP_DATA_WIDTH-1 downto 0);

  type drp_mosi_array_type is array (natural range <>) of drp_mosi_type;
  type drp_miso_array_type is array (natural range <>) of drp_miso_type;

end package; -- drp_pkg
