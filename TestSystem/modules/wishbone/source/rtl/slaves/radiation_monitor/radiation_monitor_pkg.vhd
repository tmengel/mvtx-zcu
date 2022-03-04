-------------------------------------------------------------------------------
-- Title      : radiation_monitor_pkg
-- Project    : RUv0_RDO
-------------------------------------------------------------------------------
-- File       : radiation_monitor_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-09-01
-- Last update: 2017-10-21
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Description: Package defining constant/signals used for RADIATION_MONITOR purposes
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;

package radiation_monitor_pkg is

  constant C_COUNTER_WIDTH        : integer                                       := WB_DATA_WIDTH/2;
  constant C_WB_COUNTER_RANGE     : std_logic_vector(WB_DATA_WIDTH/2 -1 downto 0) := (others => '0');
  constant C_WB_COUNTER_2ND_RANGE : std_logic_vector(WB_DATA_WIDTH-1 downto WB_DATA_WIDTH/2) := (others => '0');

  type t_radmon_cntr_array is array (natural range <>) of std_logic_vector(C_COUNTER_WIDTH-1 downto 0);

  function f_get_address_int (
    constant wb_address           : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0);  -- actual_address
    constant module_start_address : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0)   -- start address of module
    ) return integer;

end package radiation_monitor_pkg;

package body radiation_monitor_pkg is

  function f_get_address_int (
    constant wb_address           : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0);  -- actual_address
    constant module_start_address : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0)   -- start address of module
    ) return integer is
    variable v_result : integer range 0 to 2**wb_address'length-1;
  begin
    if unsigned(wb_address) < unsigned(module_start_address) then
      v_result := 0;
    else
      v_result := to_integer(unsigned(wb_address) - unsigned(module_start_address));
    end if;
    return v_result;
  end function f_get_address_int;


end package body radiation_monitor_pkg;
