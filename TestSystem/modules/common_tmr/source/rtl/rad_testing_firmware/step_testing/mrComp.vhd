-------------------------------------------------------------------------------
-- Title      : mrComp
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : rtComp.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-01-29
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: 'mrComp' compares two input signals at each clock cycle.
-- If the signalss do not match, issues the 'DIFF' flag which will stay high
-- for the clock period. The component is MR protected and the 'DIFF' ouput is
-- a multiple ('C_MRL') redundant signal, while the 'WARN' output is a warning
-- combinatorial flag asserted if there is no full agreement within and/or
-- between the MR voting stages of the entity.
--
-- GENERICS: 
--   -> 'C_WIDTH' defines the width of the input signals.
--   -> 'C_MRL' defines the level of Modulare Redundancy of the hardened components.
--      It should be odd and it is anyway suggested to only use the 3 and 5 values.
--   -> 'C_MRO' defines wheter the modular redundancy stops at the port output
--      ('C_MRO = false'), in which case the output is a single bit port, or when
--      the modular redundancy is carried outside the entity ('C_MRO = true'), in
--      which case the 'DIFF' port is a parallel bus 'C_MRL' wide of fully
--      triplicated circuits. 
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this clock,
--      i.e. they change state just after the 'CLK' rising edge.
--  ->  'RST' is the active-high synchronous reset. The unit start working after
--      'RST' goes low.
--  ->  'PTRN1' is the reference pattern to be compared.
--  ->  'PTRN2' is the second pattern to be compared.
--  ->  'DIFF' is a 'C_MR' width port which outputs in parallel for 'C-MR' times
--      the comparison result, '0' meaning no difference between 'SIG1' and 'SIG2'
--      and '1' meaning at least one bit is different. The signal is synchronous 
--      with 'CLK' and tied to '0' during reset.
--  ->  'WARN' is a warning flag which if '1' indicates that within the comparator
--      voting system not all signals agree, i.e. that some upset is affecting the
--      comparator itself. The signal is synchronous with 'CLK' and tied to '0' 
--      during reset.
--

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Packages.
use work.mrTools_pkg.all;


--------------------------------------------------------------------------------
--                              Entity Declaration                            --
--------------------------------------------------------------------------------
entity mrComp is

    generic (
        C_WIDTH:natural := 6;   -- Width of the data path.
        C_MRL:  natural := 3;   -- Modular Redundancy Level.
        C_MRO:  boolean := true -- Modular Redundancy Output.    
    );
    port (  
        CLK:    in  std_logic;
        RST:    in  std_logic;
        PTRN1:  in  std_logic_vector(C_WIDTH - 1 downto 0);
        PTRN2:  in  std_logic_vector(C_WIDTH - 1 downto 0);
        DIFF:   out std_logic_vector(mrPortWidth(1, C_MRL, C_MRO) - 1 downto 0);
        WARN:   out std_logic
    );
    
    -- Make 'rtDisc' untouchable by the synthesis/placement tools. 
    attribute DONT_TOUCH of mrComp: entity is "TRUE";
        
end mrComp;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of mrComp is
    
    -- Output signals generated by the 'C_MRL' replicated comparators.
    signal sDiff: std_logic_vector(C_MRL - 1 downto 0):= (others => '0');    
    
    -- Warning signals generated by the 'C_MRL' voters.
    signal sWarn: std_logic_vector(mrPortWidth(1, C_MRL, C_MRO) - 1 downto 0):= (others => '0');    
                        
    -- Comparator(s) output signals registers, 'C_MRL' replicated.
    signal rDiff: std_logic_vector(C_MRL - 1 downto 0):= (others => '0');    
    

begin
    
    -- Combinatorial comparators, 'C_MRL' replicated. Each compares the 'SIG1' 
    -- and 'SIG2' inputs and asserts a '1' if they differ. Purely async process.
    MR: for i in 0 to (C_MRL - 1) generate
        COMP: entity work.muComp
        generic map (
            C_WIDTH => C_WIDTH
        )
        port map (
            PTRN1 => PTRN1,
            PTRN2 => PTRN2,
            DIFF  => sDiff(i)
        );
    end generate MR;
    
    -- Sync clock process. Loads the comparator output value 'sDiff' into the 
    -- register rDiff, so the comparison status remains freezed for one clock 
    -- cycle. The process synthetize 'C_MR' registers in parallel.
    CLOCK: process(CLK, RST, sDiff)
    begin
        if (rising_edge(CLK)) then
            --if (RST = '0') then
            if (RST = '1') then --@ksielewi
                rDiff <= (Others => '0');
            else 
                rDiff <= sDiff;
            end if;
        end if;
    end process;

    -- Voting stage. Votes the values of the 'C_MRL' 'rDiff' registers. Directly
    -- drives the output 'DIFF' port. Completely combinatorial.
    MR_VOTE: entity work.mrVotingStage
    generic map (
        C_WIDTH => 1,
        C_MRL => C_MRL,
        C_MRO => C_MRO
    )
    port map (
        INPUT   => rDiff,
        OUTPUT  => DIFF,
        WARN    => WARN
    );
        
end Behavioral;
