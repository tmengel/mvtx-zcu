-------------------------------------------------------------------------------
-- Title      : Simulation top for radiation test structures
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : rtTop_tb.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-01-29
-- Last update: 2016-12-12
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
entity rtTop_tb is
    generic (
        -- Simulation only generics.
        CS_MODE: integer := 2;                  -- Simulation mode (0 = default, 1 = error injection). 
        CS_ERR_TARGET: integer := 2;            -- Error injection target.
        CS_ERR_CLKS_INTERVAL: natural := 30;    -- Average clks interval between errors.
        CS_ERR_CLKS_LENGTH: natural := 3;       -- Average clks duration of errors.
        
        -- Synthetisable generics.
        C_PERIOD: time:= 10 ns;                 -- CLock period.
        C_WIDTH: natural:= 3;                   -- Shift register width.
        C_STEPS: natural:= 8;                   -- Shift register steps.
        C_LANES: natural:= 2;                   -- Test lanes replica.
        C_MRL   : natural := 3;                 -- Redundancy level of MR protection.
        C_SR_MRL: natural := 3;                 -- Shift Register Redundancy level of MR protection.
        C_SR_MRC: boolean := true;              -- Shift Register Replicates combinatorial logic.
        C_SR_MRR:  boolean := true;             -- Shift Register Replicates registers.
        C_SR_MRCR: boolean := false;            -- Add redundant voter between logic and registers.
        C_SR_MRB: boolean := false              -- Shift Register Replicates outputs (use with care).
    );
end rtTop_tb;


--------------------------------------------------------------------------------
--                         Architecture Declaration                           --
--------------------------------------------------------------------------------
architecture Behavioral of rtTop_tb is

    -- Sim signals declaration.
    signal sDUT_DiffOut:    std_logic_vector(C_LANES - 1 downto 0);
    signal sDUT_WarnOut:    std_logic_vector(C_LANES - 1 downto 0);
       
	-- Clock and reset.
	signal sSim_Clk:        std_logic;
    signal sSim_Rst:        std_logic := '0';
        
    
--------------------------------------------------------------------------------
--                           Architecture Behavioral                          --
--------------------------------------------------------------------------------
begin

    -- Connect rtTop entity.
    RT: entity work.rtTop 
    generic map (
        -- Simulation only generics.
        CS_MODE => CS_MODE,
        CS_ERR_TARGET => CS_ERR_TARGET,
        CS_ERR_CLKS_INTERVAL => CS_ERR_CLKS_INTERVAL,
        CS_ERR_CLKS_LENGTH => CS_ERR_CLKS_LENGTH,
        -- Synthetisable generics.
        C_WIDTH  => C_WIDTH,
        C_STEPS  => C_STEPS,
        C_LANES  => C_LANES,
        C_MRL    => C_MRL,
        C_SR_MRL => C_SR_MRL,
        C_SR_MRC => C_SR_MRC,
        C_SR_MRR => C_SR_MRR,
        C_SR_MRCR => C_SR_MRCR,
        C_SR_MRB => C_SR_MRB     
    )
    port map (
        CLK     => sSim_Clk,
        RST     => sSim_Rst,
        DIFF    => sDUT_DiffOut,
        WARN    => sDUT_WarnOut     
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
