-------------------------------------------------------------------------------
-- Title      : 'mrVoter' test bench.
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrVoter_tb.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-04
-- Last update: 2016-09-07
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
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
use ieee.math_real.all;


--------------------------------------------------------------------------------
--                             Entity declaration                             --
--------------------------------------------------------------------------------
entity mrVoter_tb is
    generic (
        constant C_PERIOD:  time := 10 ns;
        constant C_WIDTH:   natural := 6;
        constant C_MRL:      natural := 3
    );
end mrVoter_tb;


--------------------------------------------------------------------------------
--                         Architecture Declaration                           --
--------------------------------------------------------------------------------
architecture Behavioral of mrVoter_tb is

    -- Shared to avoid redefinition at each function call..
    shared variable seed1, seed2: positive;
                
    -- Random number generator. Generates a integer in the [0 - Max[ interval.
    impure function fRnd(max, min: real) return integer is
        variable rand: real;
    begin
        UNIFORM(seed1, seed2, rand);
        return integer(TRUNC(min + rand * (max - min)));
    end fRnd;
            
    -- Sim signals declaration.
    signal sClk:    std_logic;
    signal sRst:  std_logic;
    
    -- Voter.
    signal sIn:     std_logic_vector(C_MRL - 1 downto 0):= (others => '0');
    signal sOut:    std_logic;
    signal sWarn:   std_logic;
    
    -- Comparator.
    signal sCmpRef:     std_logic_vector(C_WIDTH - 1 downto 0) := (others => '0');
    signal sCmpSig:     std_logic_vector(C_WIDTH - 1 downto 0) := (others => '0');
    signal sCmpDiff:    std_logic_vector(C_MRL - 1 downto 0) := (others => '0');
    signal sCmpWarn:    std_logic;


--------------------------------------------------------------------------------
--                           Architecture Behavioral                          --
--------------------------------------------------------------------------------
begin

    -- Connect 'mrVoter' under test.
    VOTER: entity work.mrVoter 
    generic map (
        C_MRL => C_MRL 
    )
    port map (
        INPUT   => sIn,
        OUTPUT  => sOut,
        WARN    => sWarn
    );
    
    -- Connect 'rtComp' under test.
    COMP: entity work.mrComp
    generic map (
        C_WIDTH => C_WIDTH,
        C_MRL => C_MRL,
        C_MRO => true     
    )
    port map (
        CLK     => sClk,
        RST     => sRst,
        PTRN1   => sCmpRef,
        PTRN2   => sCmpSig,
        DIFF    => sCmpDiff,
        WARN    => sCmpWarn
    );
        
    -- Start reset period.
    RESET: process
    begin
        sRst <= '1';
        wait for C_PERIOD * 4;
        sRst <= '0';
        wait;
    end process;
    
    -- Base clock generation.
    CLOCK: process
    begin
        sClk <= '0';
        wait for C_PERIOD / 2;
        sClk <= '1';
        wait for C_PERIOD / 2;
    end process;
    
    -- Voter data random toggler.
    FEEDVOTER: process(sClk)
    begin
        if (sClk'event and sClk = '0') then
            for i in 0 to (C_MRL - 1) loop
                if (fRnd(10.0, 0.0) > integer(7)) then 
                    sIn(i) <= not sIn(i); 
                end if;          
            end loop;
        end if;
    end process;
    
    -- Comparator data toggler.
    FEEDCOMP: process(sClk)
    begin
        if (sClk'event and sClk = '0') then
            for i in 0 to (C_WIDTH - 1) loop
                
                -- Assign 'sDataRef' value.
                if (fRnd(10.0, 0.0) > integer(5)) then 
                    sCmpRef(i) <= '1';
                else
                    sCmpRef(i) <= '0';
                end if; 
                
                -- Copy it to 'sDataSig' with 10% mistakes.
                if (fRnd(10.0, 0.0) > integer(8)) then 
                    sCmpSig(i) <= sCmpRef(i);
                else
                    sCmpSig(i) <= not sCmpRef(i);
                end if;         
            end loop;
        end if;
    end process;
            
end Behavioral;
