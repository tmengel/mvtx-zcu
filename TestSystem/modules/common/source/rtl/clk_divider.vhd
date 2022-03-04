-------------------------------------------------------------------------------
-- Title      : clk_divider
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : clk_divider.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-05-23
-- Last update: 2017-09-27
-- Platform   : Vivado 2015.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Block which generates a pulse every given number of clock cycles
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-05-23  1.0      mlupi   Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.math_real.all;

entity clk_divider is
  generic(
    DIV_FACTOR : integer := 2
    );
  port(
    CLK       : in  std_logic;
    RST       : in  std_logic;
    PULSE     : out std_logic
    );
end clk_divider;

architecture std of clk_divider is

  constant c_bit_width : integer := integer(ceil(log2(real(DIV_FACTOR))));

  signal s_cntup : std_logic;
  signal s_cnt, s_actual_state : std_logic_vector(c_bit_width -1 downto 0);

begin

  -- purpose: generates an the upcounting signal
  p_pulse_gen: process (CLK) is
  begin  -- process p_pulse_gen
    if rising_edge(CLK) then
      if RST = '1' then
        s_cntup <= '0';
        PULSE <= '0';
      else
        s_cntup <= '1';

        if s_cnt = DIV_FACTOR-1 then
          PULSE <= '1';
        else
          PULSE <= '0';
        end if;
      end if;
    end if;
  end process p_pulse_gen;

  INST_upcounter: entity work.upcounter_core
    generic map (
      BIT_WIDTH     => c_bit_width,
      IS_SATURATING => 0,
      VERBOSE       => 0)
    port map (
      CLK       => CLK,
      RST       => RST,
      RST_CNT   => RST,
      CNT_UP    => s_cntup,
      CNT_VALUE => s_cnt,
      ACTUAL_STATE_O => s_actual_state,
      ACTUAL_STATE_I => s_actual_state);

end architecture std;
