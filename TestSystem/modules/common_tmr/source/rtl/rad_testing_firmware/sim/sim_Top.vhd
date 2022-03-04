-------------------------------------------------------------------------------
-- Title      : Simulation for radiation test structures
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : sim_Top.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-01-29
-- Last update: 2016-02-04
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Test pattern generator for radiation testing.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author          Description
-- 2016-01-29   1.0         Piero        Created
------------------------------------------------------------------------------- 

-- Libraries.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--------------------------------------------------------------------------------
--                             Entity declaration                             --
--------------------------------------------------------------------------------
entity sim_Top is
  generic(
    constant C_PERIOD : time    := 10 ns;
    constant C_WIDTH  : natural := 4;
    constant C_STEPS  : natural := 4;
    constant C_LINES  : natural := 2
  );
end sim_Top;

--------------------------------------------------------------------------------
--                         Architecture Declaration                           --
--------------------------------------------------------------------------------
architecture Behavioral of sim_Top is
  component rtTop
    generic(
      constant C_WIDTH : natural := 6;
      constant C_STEPS : natural := 64;
      constant C_LINES : natural := 128;
      constant C_MR    : natural := 3
    );
    port(
      CLK   : in  std_logic;
      RST_N : in  std_logic;
      WARN  : out std_logic_vector(C_LINES - 1 downto 0);
      DIFF  : out std_logic_vector(C_LINES - 1 downto 0)
    );
  end component;

  -- Sim signals declaration.
  signal sClk   : std_logic;
  signal sRst_n : std_logic := '1';
  signal WARN_s : std_logic_vector(C_LINES - 1 downto 0);
  signal DIFF_s : std_logic_vector(C_LINES - 1 downto 0);

--------------------------------------------------------------------------------
--                           Architecture Behavioral                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
begin

  -- Connect top.
  DUT : rtTop
    generic map(
      C_WIDTH => C_WIDTH,
      C_STEPS => C_STEPS,
      C_LINES => C_LINES
    )
    port map(
      CLK   => sClk,
      RST_N => sRst_n,
      WARN  => WARN_s,
      DIFF  => DIFF_s
    );

  -- Start reset period.
  RESET : process
  begin
    sRst_n <= '0';
    wait for C_PERIOD * 4;
    sRst_n <= '1';
    wait;
  end process;

  -- Base clock generation.
  CLOCK : process
  begin
    sClk <= '0';
    wait for C_PERIOD / 2;
    sClk <= '1';
    wait for C_PERIOD / 2;
  end process;

-- Start reset period.
--DBGSEL: process
--begin
--    sDbgSel <= (0 => '0', others => '0');
--    wait for C_PERIOD * 70;
--    sDbgSel <= (0 => '1', others => '0');
--    wait;
--end process;

end Behavioral;
