-------------------------------------------------------------------------------
-- Title      : upcounter_n
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : upcounter_n.vhd
-- Author     : Matthias Bonora <matthias.bonora@cern.ch>
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-04-28
-- Last update: 2017-09-27
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: parametric upounter with enable and counter increase value input
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-30  1.0      MB      Copied implementation from upcounter
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity upcounter_n is
  generic (
    BIT_WIDTH       : natural := 16;
    UPCOUNTER_WIDTH : natural := 16;
    IS_SATURATING   : integer := 0;
    VERBOSE         : integer := 1);
  port (
    -- Frontend Interface
    CLK       : in  std_logic;          -- Clock
    RST       : in  std_logic;          -- global fpga reset
    RST_CNT   : in  std_logic;          -- counter reset signal
    CNT_UP    : in  std_logic_vector(UPCOUNTER_WIDTH - 1 downto 0);  -- count up x
    CNT_VALUE : out std_logic_vector(BIT_WIDTH-1 downto 0));

end entity upcounter_n;


architecture arch of upcounter_n is

  signal i_cntr : natural range 0 to (2**BIT_WIDTH)-1;

  -- purpose: updates the counter
  --          if is saturating is true, the counter saturates, otherwise, it overflows
  function f_update_counter (
    constant is_saturating  : integer;
    constant verbose        : integer;
    constant i_actual_value : natural;
    constant i_increment    : natural;
    constant C_bit_width    : natural)
    return natural is

    variable i_next_value : natural;
  begin  -- function f_update_counter
    i_next_value := i_actual_value + i_increment;
    if i_next_value >= (2**C_bit_width) then
      if is_saturating = 1 then
        i_next_value := (2**C_bit_width - 1);
        -- synthesis translate_off
        if verbose = 1 then
          report "Counter saturation" severity NOTE;
        end if;
      -- synthesis translate_on
      else
        i_next_value := i_next_value mod (2**C_bit_width);
        -- synthesis translate_off
        if verbose = 1 then
          report "Counter overflow" severity NOTE;
        end if;
      -- synthesis translate_on
      end if;
    end if;
    return i_next_value;
  end function f_update_counter;

begin  -- architecture arch

  -- purpose: updates the ovfl counter of the fifo for debug purposes
  p_counter_update : process (CLK) is
    variable i_increment : natural range 0 to (2**UPCOUNTER_WIDTH) - 1;
  begin  -- process p_counter_update
    if rising_edge(CLK) then
      if RST = '1' then
        i_cntr <= 0;
      else
        if RST_CNT = '1' then
          i_cntr <= 0;
          -- synthesis translate_off
          if VERBOSE = 1 then
            report "Counter reset" severity NOTE;
          end if;
        -- synthesis translate_on
        else
          i_increment := to_integer(unsigned(CNT_UP));
          i_cntr      <= f_update_counter(IS_SATURATING, VERBOSE, i_cntr, i_increment, BIT_WIDTH);
        end if;
      end if;
    end if;
  end process p_counter_update;

  -----------------------------------------------------------------------------
  -- OUTPUT conversion
  -----------------------------------------------------------------------------

  CNT_VALUE <= std_logic_vector(to_unsigned(i_cntr, BIT_WIDTH));

end architecture arch;
