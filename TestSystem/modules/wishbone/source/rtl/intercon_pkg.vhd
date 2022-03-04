------------------------------------------------------------------------------
-- Title      : intercon_package
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : intercon_package.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-02-25
-- Last update: 2018-06-04
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: intercon_package to define constants used in wishbone
--              implementation
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author     Description
-- 2016-01-28  1.0      mlupi      Imported from Joe
-- 2016-02-25  2.0      ML         Added parametrization of wishbone bus
-- 2016-02-26  2.1      ML         Moved intercon to intercon.vhd
-- 2016-07-05  3.0      ML         Parametrized wishbone with number of slaves
-- 2016-07-21  3.1      ML         Adapted to alpide_control_dev
-- 2018-03-23  4.0      ML         Configurable number of masters
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package intercon_pkg is

  constant WB_DATA_WIDTH : natural := 16;
  constant WB_ADD_WIDTH  : natural := 15;
  constant WB_ADDS_WIDTH : natural := 8; --slave internal address
  constant WB_ADDB_WIDTH : natural := (WB_ADD_WIDTH - WB_ADDS_WIDTH); --width of slave internal addressing bus

  constant GPIF_WIDTH     : natural := 32;
  constant GPIF_CTL_WIDTH : natural := 13;

  -----------------------------------------------------------------------------
  -- Watchdog constants definition
  -----------------------------------------------------------------------------

  constant c_WD_TIMEOUT_WIDTH : positive                                          := 32;
  constant c_WD_TIMEOUT       : std_logic_vector(c_WD_TIMEOUT_WIDTH - 1 downto 0) := x"000FFFFF";

  -- Record definition
  -----------------------------------------------------------------------------
  type wbm_i_type is record
    dat_i : std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
    err_i : std_logic;
    ack_i : std_logic;
  end record;

  type wbm_o_type is record
    dat_o  : std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
    we_o   : std_logic;
    addr_o : std_logic_vector(WB_ADD_WIDTH - 1 downto 0);
    cyc_o  : std_logic;
    stb_o  : std_logic;
  end record;

  type wbs_i_type is record
    dat_i  : std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
    we_i   : std_logic;
    addr_i : std_logic_vector(WB_ADDS_WIDTH - 1 downto 0);
    cyc_i  : std_logic;
    stb_i  : std_logic;
  end record;

  type wbs_o_type is record
    dat_o : std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
    err_o : std_ulogic;                 -- changed to ulogic to check for address clash
    ack_o : std_ulogic;                 -- changed to ulogic to check for address clash
  end record;

  -----------------------------------------------------------------------------
  -- array
  -----------------------------------------------------------------------------

  type t_wbm_i_array is array (natural range <>) of wbm_i_type;
  type t_wbm_o_array is array (natural range <>) of wbm_o_type;

  type t_wbs_i_array is array (natural range <>) of wbs_i_type;
  type t_wbs_o_array is array (natural range <>) of wbs_o_type;

  type t_wb_add_array is array (natural range <>) of std_logic_vector(WB_ADD_WIDTH - 1 downto 0);
  type t_wb_addr_array is array (natural range <>) of std_logic_vector(WB_ADDS_WIDTH - 1 downto 0);
  type t_wb_dat_array  is array (natural range <>) of std_logic_vector(WB_DATA_WIDTH - 1 downto 0);

  type t_wb_addb_array is array (natural range <>) of std_logic_vector(WB_ADDB_WIDTH - 1 downto 0);

  type t_wbs_reg_array is array (natural range <>) of std_logic_vector(WB_DATA_WIDTH - 1 downto 0);

  type t_wbs_reg_we is (r, w, rw);

  type t_wbs_reg_we_array is array (natural range <>) of t_wbs_reg_we;

  -----------------------------------------------------------------------------
  -- functions definition
  -----------------------------------------------------------------------------

  function f_fetch_slice(
    constant input_array : t_wb_dat_array;
    constant position    : integer)
    return std_logic_vector;

  function f_bitwise_array_or(
    constant input_array : t_wb_dat_array)
    return std_logic_vector;

  function wb_resize(
    constant input_array : std_logic_vector) 
    return std_logic_vector;

  function wb_resize_bit(
    constant input_bit : std_logic;
    constant position  : integer) 
    return std_logic_vector;

end intercon_pkg;

package body intercon_pkg is

  -- purpose: return a std_logic_vector with full wishbone data width from
  -- reduced width input array
  function wb_resize(
    constant input_array : std_logic_vector) 
    return std_logic_vector is
    variable result : std_logic_vector(WB_DATA_WIDTH-1 downto 0) := (others => '0');
  begin
    result(input_array'range) := input_array;
    return result;
  end function wb_resize;

  function wb_resize_bit(
    constant input_bit : std_logic;
    constant position  : integer) 
    return std_logic_vector is
    variable result : std_logic_vector(WB_DATA_WIDTH-1 downto 0) := (others => '0');
  begin
    result(position) := input_bit;
    return result;
  end function wb_resize_bit;


  -- purpose: fetches the vertical slice of the array to easily calculate bitwise_array_or
  function f_fetch_slice(
    constant input_array : t_wb_dat_array;
    constant position    : integer)
  return std_logic_vector is
    variable result : std_logic_vector(input_array'range);
  begin
    for j in input_array'range loop
      result(j) := input_array(j)(position);
    end loop;
    return result;
  end function f_fetch_slice;

  -- purpose: bitwise or (among different values) of the various elements of the array
  --          used for selecting the data from wishbone slaves to the master
  function f_bitwise_array_or(
    constant input_array : t_wb_dat_array)
  return std_logic_vector is
    variable result : std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
  begin
    for i in 0 to WB_DATA_WIDTH - 1 loop
      if (unsigned(f_fetch_slice(input_array, i)) = 0) then
        result(i) := '0';
      else
        result(i) := '1';
      end if;
    end loop;
    return result;
  end function f_bitwise_array_or;

end intercon_pkg;
