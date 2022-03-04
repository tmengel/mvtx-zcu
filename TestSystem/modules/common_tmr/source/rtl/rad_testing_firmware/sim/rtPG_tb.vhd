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
entity rtPG_tb is
  generic(
    constant C_PERIOD : time    := 10 ns;
    C_WIDTH           : natural := 4;
    C_MR              : natural := 3
  );
end rtPG_tb;

--------------------------------------------------------------------------------
--                         Architecture Declaration                           --
--------------------------------------------------------------------------------
architecture Behavioral of rtPG_tb is
  component rtPG is
    generic(
      C_WIDTH : natural := 6;           -- Pattern width.
      C_MR    : natural := 3            -- MR level.
    );

    port(
      CLK    : in  std_logic;
      RST_N  : in  std_logic;
      OUTPUT : out std_logic_vector(C_WIDTH - 1 downto 0);
      WARN   : out std_logic;
      RDY    : out std_logic
    );
  end component;

  -- Sim signals declaration.
  signal sClk    : std_logic;
  signal sRst_n  : std_logic := '1';
  signal sOUTPUT : std_logic_vector(C_WIDTH - 1 downto 0);
  signal sWARN   : std_logic;
  signal sRDY    : std_logic;

--------------------------------------------------------------------------------
--                           Architecture Behavioral                          --
--------------------------------------------------------------------------------
begin

  -- Connect top.
  DUT : rtPG
    generic map(
      C_WIDTH => C_WIDTH,
      C_MR    => C_MR
    )
    port map(
      CLK    => sClk,
      RST_N  => sRst_n,
      OUTPUT => sOUTPUT,
      WARN   => sWARN,
      RDY    => sRDY
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
    sClk <= '1';
    wait for C_PERIOD / 2;
    sClk <= '0';
    wait for C_PERIOD / 2;
  end process;

end Behavioral;
