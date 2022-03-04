-------------------------------------------------------------------------------
-- Title      : 'mrVotingStage' test bench.
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrVotingStage_tb.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-04
-- Last update: 2016-09-08
-- Platform   : Windows 10 64bit, Xilinx Vivado 2016.1
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: simple test bench to veify 'mrVoter' behavior.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author          Description
-- 2016-01-29   1.0         Piero        Created
------------------------------------------------------------------------------- 

-- Libraries.
library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

-- Package.
use work.mrTools_pkg.all; 


--------------------------------------------------------------------------------
--                             Entity declaration                             --
--------------------------------------------------------------------------------
entity mrVotingStage_tb is
    generic (
        -- Simulation only generics.
        CS_MODE: integer := 2;                  -- Simulation mode (0 = default, 1 = error injection). 
        CS_ERR_TARGET: integer := 2;            -- Error injection target.
        CS_ERR_CLKS_INTERVAL: natural := 30;    -- Average clks interval between errors.
        CS_ERR_CLKS_LENGTH: natural := 3;       -- Average clks duration of errors.
        
        -- Synthetisable generics.
        constant C_PERIOD:  time := 10 ns;
        constant C_WIDTH:   natural := 6;
        constant C_MR:      boolean := true;
        constant C_MRL:     natural := 3;
        constant C_MRO:     boolean := false
    );
    
    -- SYNTHESIS TRANSLATE_OFF
    package rtTools is new work.rtTools_pkg generic map ( 
        CS_MODE => CS_MODE,
        CS_ERR_TARGET => CS_ERR_TARGET,
        CS_ERR_CLKS_INTERVAL => CS_ERR_CLKS_INTERVAL,
        CS_ERR_CLKS_LENGTH => CS_ERR_CLKS_LENGTH,
        C_WIDTH => C_WIDTH 
    );
    -- SYNTHESIS TRANSLATE_ON
    
end mrVotingStage_tb;


--------------------------------------------------------------------------------
--                         Architecture Declaration                           --
--------------------------------------------------------------------------------
architecture Behavioral of mrVotingStage_tb is

    -- SYNTHESIS TRANSLATE_OFF
    -- Use the 'rtTools' 'tErr' protected structure to manage 
    -- the error injection during SIMULATION ONLY .    
    shared variable cErr : rtTools.tErr;    
    -- SYNTHESIS TRANSLATE_ON
    
    -- Generic signals.
    signal simClk:    std_logic;
    signal simRst:    std_logic;
    
    -- Input(s) to the voting stage.
    type tBus is array (0 to C_MRL - 1) of std_logic_vector(C_WIDTH - 1 downto 0);    
    signal simInput: tBus;
        
    -- Voting stage I/Os.
    signal dutIn:    std_logic_vector(C_WIDTH * C_MRL - 1 downto 0);
    signal dutOut:   std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRO) - 1 downto 0);
    signal dutWarn:  std_logic;
      

--------------------------------------------------------------------------------
--                           Architecture Behavioral                          --
--------------------------------------------------------------------------------
begin

    -- Connect 'mrVoter' under test.
    VOTE: entity work.mrVotingStage 
    generic map (
        C_WIDTH => C_WIDTH,
        C_MR => C_MR,
        C_MRL => C_MRL,
        C_MRO => C_MRO
    )
    port map (
        INPUT   => dutIn,
        OUTPUT  => dutOut,
        WARN    => dutWarn
    );
    
    -- Connect sim signals to DUT input.
    ROUTE: process(simInput) 
    begin
        for i in 0 to (C_WIDTH - 1) loop
            for b in 0 to (C_MRL - 1) loop
                dutIn(i + b * C_WIDTH) <= simInput(b)(i);
            end loop;
        end loop;
    end process;
            
    -- Start reset period.
    RESET: process
    begin
        simRst <= '1';
        wait for C_PERIOD * 4;
        simRst <= '0';
        wait;
    end process;
    
    -- Base clock generation.
    CLOCK: process
    begin
        simClk <= '0';
        wait for C_PERIOD / 2;
        simClk <= '1';
        wait for C_PERIOD / 2;
    end process;
    
    -- Voter data input generator.
    FEEDVOTER: process(simClk)
            variable currVec: std_logic_vector(C_WIDTH -1 downto 0);
    begin
        if (simClk'event and simClk = '1') then
            
            -- Generate a random vector.
            currVec := cErr.rndVector;
            
            -- Copy the vector into the inputs and introduce errors.
            for i in 0 to (C_MRL - 1) loop
                if (cErr.rndUniform(0, 100) < 95 ) then
                    simInput(i) <= currVec;
                else
                    simInput(i) <= cErr.rndError(currVec);
                end if;    
            end loop;
        end if;
    end process;
    
            
end Behavioral;
