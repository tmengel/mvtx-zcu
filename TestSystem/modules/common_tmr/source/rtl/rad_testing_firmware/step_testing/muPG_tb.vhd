-------------------------------------------------------------------------------
-- Title      : Simulation top for radiation test structures
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : muPG_tb.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-05-12
-- Last update: 2016-09-07
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Simulation bench for the radiation testing 'rtTop' module.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author          Description
-- 2016-01-29   1.0         Piero        Created
------------------------------------------------------------------------------- 

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--------------------------------------------------------------------------------
--                             Entity declaration                             --
--------------------------------------------------------------------------------
entity muPG_tb is
    generic (
        C_PERIOD: time:= 10 ns;                 -- CLock period.
        C_WIDTH: natural:= 3;                   -- Shift register width.
        C_STEPS: natural:= 8;                   -- Shift register steps.
        C_LANES: natural:= 2;                   -- Test lanes replica.
        C_MRL:   natural:= 3                    -- Modular redundancy level.
    );
end muPG_tb;


--------------------------------------------------------------------------------
--                         Architecture Declaration                           --
--------------------------------------------------------------------------------
architecture Behavioral of muPG_tb is

    -- Sim signals declaration.
    signal sDUT_Ptrn:   std_logic_vector(C_WIDTH - 1 downto 0);
    signal sDUT_Ready:  std_logic;
    signal sDUT_Cycle:  std_logic;
               
	-- Clock and reset.
	signal sSim_Clk:    std_logic;
    signal sSim_Set:    std_logic := '1';
    signal sSim_Rst:   std_logic := '0';
        
    
--------------------------------------------------------------------------------
--                           Architecture Behavioral                          --
--------------------------------------------------------------------------------
begin

    -- Connect rtTop entity.
    PG: entity work.muPG 
    generic map (
        C_WIDTH => C_WIDTH
    )
    port map (
        CLK     => sSim_Clk,
        RST   => sSim_Rst,
        SET     => sSim_Set,
        SETVAL  => sDUT_Ptrn,
        PTRN    => sDUT_Ptrn,
        CYCLE   => sDUT_Cycle,
        READY   => sDUT_Ready
    );
    
    -- Start reset period.
    RESET: process
    begin
        sSim_Rst <= '1';
        wait for C_PERIOD * 4;
        sSim_Rst <= '0';
        wait for C_PERIOD * 81;
        sSim_Rst <= '1';
        wait for C_PERIOD * 4;
        sSim_Rst <= '0';
        wait for C_PERIOD * 137;
        sSim_Rst <= '1';
        wait for C_PERIOD * 4;
        sSim_Rst <= '0';
    end process;
    
    -- Base clock generation.
    CLOCK: process
    begin
        sSim_Clk <= '0';
        wait for C_PERIOD / 2;
        sSim_Clk <= '1';
        wait for C_PERIOD / 2;
    end process;
        
end Behavioral;
