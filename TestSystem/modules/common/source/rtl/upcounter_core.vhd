-------------------------------------------------------------------------------
-- Title      : upcounter_core
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : upcounter_core.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-04-28
-- Last update: 2017-09-27
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: simple parametric upounter with enable
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-05-11  1.0      ML      Created
-- 2016-07-06  1.1      ML      Modified generic IS_SATURATING and VERBOSE to be
--                              std_logic to have compatibility with v and sv
-- 2017-08-02  1.2      ML      Updated name to upcounter_core
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity upcounter_core is
  generic(
    BIT_WIDTH     : integer := 16;
    IS_SATURATING : integer := 0;
    VERBOSE       : integer := 1);
  port(
    -- Front-end Interface
    CLK            : in  std_logic;     -- Clock
    RST            : in  std_logic;     -- global fpga reset
    RST_CNT        : in  std_logic;     -- counter reset signal
    CNT_UP         : in  std_logic;     -- count up

    CNT_VALUE      : out std_logic_vector(BIT_WIDTH - 1 downto 0);
    -- TMR related I/O: connect them together externally or use tmr_wrapper
    -- with C_SEE_MITIGATION_TECHNIQUE = 0
    ACTUAL_STATE_O : out std_logic_vector(BIT_WIDTH - 1 downto 0);
    ACTUAL_STATE_I : in  std_logic_vector(BIT_WIDTH - 1 downto 0));
end entity upcounter_core;

architecture arch of upcounter_core is

  subtype t_counter is unsigned(BIT_WIDTH - 1 downto 0);
  signal i_cntr, i_cntr_voted : t_counter;
  constant C_COUNTER_ZERO     : t_counter := (others => '0');
  constant C_COUNTER_MAX      : t_counter := (others => '1');

  -- purpose: updates the counter
  --          if is saturating is true, the counter saturates, otherwise, it overflows
  function f_update_counter(
    constant is_saturating  : integer;
    constant verbose        : integer;
    constant i_actual_value : t_counter) 
  return t_counter is
    variable i_next_value : t_counter;
  begin  -- function f_update_counter
    if i_actual_value = C_COUNTER_MAX then
      if is_saturating = 1 then
        i_next_value := i_actual_value;
        -- synthesis translate_off
        if verbose = 1 then
          report "Counter saturation" severity NOTE;
        end if;
      -- synthesis translate_on
      else
        i_next_value := C_COUNTER_ZERO;
        -- synthesis translate_off
        if verbose = 1 then
          report "Counter overflow" severity NOTE;
        end if;
        -- synthesis translate_on
      end if;
    else
      i_next_value := i_actual_value + 1;
    end if;
    return i_next_value;
  end function f_update_counter;

begin  -- architecture arch

  --input/output mapping
  ACTUAL_STATE_O <= std_logic_vector(i_cntr);
  i_cntr_voted   <= unsigned(ACTUAL_STATE_I);

  -- purpose: updates the ovfl counter of the fifo for debug purposes
  p_counter_update : process(CLK) is
  begin  -- process p_counter_update
    if rising_edge(CLK) then
      if RST = '1' then
        i_cntr <= C_COUNTER_ZERO;
      else
        if RST_CNT = '1' then
          i_cntr <= C_COUNTER_ZERO;
          -- synthesis translate_off
          if VERBOSE = 1 then
            report "Counter reset" severity NOTE;
          end if;
        -- synthesis translate_on
        elsif CNT_UP = '1' then
          i_cntr <= f_update_counter(IS_SATURATING, VERBOSE, i_cntr_voted);
        end if;
      end if;
    end if;
  end process p_counter_update;

  -----------------------------------------------------------------------------
  -- OUTPUT conversion
  -----------------------------------------------------------------------------

  CNT_VALUE <= std_logic_vector(i_cntr);

end architecture arch;
