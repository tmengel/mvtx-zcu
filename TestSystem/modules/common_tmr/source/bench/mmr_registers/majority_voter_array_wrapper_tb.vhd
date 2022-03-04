-------------------------------------------------------------------------------
-- Title      : Testbench for design "majority_voter_array_wrapper"
-- Project    :
-------------------------------------------------------------------------------
-- File       : majority_voter_array_wrapper_tb.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Compan--------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-07-27  1.0      ML	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity top is

end entity top;

-------------------------------------------------------------------------------

architecture sim of top is

  -- component generics
  constant MISMATCH_EN : std_logic := '1';
  constant C_WIDTH     : integer   := 16;

  -- component ports
  signal ASSERTION_CLK : std_logic;
  signal ASSERTION_RST : std_logic;
  signal INPUT_A       : std_logic_vector(C_WIDTH-1 downto 0);
  signal INPUT_B       : std_logic_vector(C_WIDTH-1 downto 0);
  signal INPUT_C       : std_logic_vector(C_WIDTH-1 downto 0);
  signal OUTPUT        : std_logic_vector(C_WIDTH-1 downto 0);
  signal MISMATCH      : std_logic;

  -- clock
  signal Clk : std_logic := '1';

begin  -- architecture

  -- component
  DUT: entity work.majority_voter_array_wrapper2
    generic map (
      MISMATCH_EN => MISMATCH_EN,
      C_WIDTH     => C_WIDTH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT_A       => INPUT_A,
      INPUT_B       => INPUT_B,
      INPUT_C       => INPUT_C,
      OUTPUT        => OUTPUT,
      MISMATCH      => MISMATCH);

  -- clock generation
  Clk <= not Clk after 10 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    -- insert signal assignments here
    wait until Clk = '1';
    INPUT_A <= (others => '1');
    INPUT_B <= (others => '1');
    INPUT_C <= (others => '1');
    wait until Clk = '1';
    INPUT_A <= x"F10A";
    wait until Clk = '1';
    INPUT_B <= x"F10A";
    wait until Clk = '1';
    INPUT_C <= x"F10A";
  end process WaveGen_Proc;

end architecture ;
