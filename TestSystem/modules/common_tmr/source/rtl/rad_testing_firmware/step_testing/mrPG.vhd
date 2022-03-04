-------------------------------------------------------------------------------
-- Title      : mrPG
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrPG.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-02
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Test pattern generator for radiation testing. Incorporates
-- 'C_MRL' 'mrPG' patter generators and votes their outputs to implement MR
-- protection against SEU. Re-align the wrong counters through the 'SET' port
-- to limit error accumulation. The port 'WARN' raises a '1' in case discrepancy 
-- is detected within the voting procedure.
--
-- GENERICS: 
--   -> 'C_WIDTH' defines the width of the output pattern.
--   -> 'C_MRL' defines the level of Modulare Redundancy of the hardened components
--      should be odd and it is anyway suggested to only use the 3 and 5 values. 
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this clock,
--      i.e. they change state just after the 'CLK' rising edge.
--  ->  'RST' is the active-high synchronous reset. The pattern generator restarts
--      the pattern sequence from the first state after 'RST_N' goes low.
--  ->  'READY' is a flag signals which goes to '1' after the first cycle of the
--      pattern has been generated, i.e. after 2^C_WIDTH 'CLK' cycles. It returns
--      to '0' after a reset is issued.
--  ->  'CYCLE' is a flag signals asserted at the beginning of every pattern cycle,
--      in synch with the clock.
--  ->  'PTRN' is the 'C_WIDTH' wide pattern signal. Synchronous with 'CLK' is
--      tied to (Others => '0') while 'RST_N = 0'.
--  ->  'WARN' is a warning flag which, if high, indicates that within the unit
--      voting system not all the signals agree, i.e. that some upset is affecting
--      the unit. The signal is synchronous with 'CLK' and tied to '0' during reset.



-- Libraries.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- Packages.
use work.mrTools_pkg.all;

---------------------------------------------------------------------------------
--                              Entity Declaration                             --
---------------------------------------------------------------------------------
entity mrPG is
    generic(
        C_WIDTH : natural := 6;        -- Pattern width.
        C_MRL   : natural := 3         -- Modular Redundancy Level.
    );
    port (
        CLK     : in  std_logic;
        RST     : in  std_logic;
        READY   : out std_logic;
        CYCLE   : out std_logic;
        PTRN    : out std_logic_vector(C_WIDTH - 1 downto 0);
        WARN    : out std_logic
    );
    
    -- Makes the unit not touchable by synthesis and implementation.
    attribute DONT_TOUCH of mrPG: entity is "true";
    
end mrPG;

--------------------------------------------------------------------------------
--                  Architecture 'Behavioral' Declaration                     --
--------------------------------------------------------------------------------    
architecture Behavioral of mrPG is

    -- Counters set signals, tied to zero so far.
    signal sSet : std_logic_vector(C_MRL - 1 downto 0) := (others => '0');

    -- Pattern Generator(s) output signal (stacked).
    signal sPtrn : std_logic_vector(C_WIDTH * C_MRL - 1 downto 0);
    
    -- Pattern Generator(s) ready and cycle signals.
    signal sReady : std_logic_vector(C_MRL - 1 downto 0);
    signal sCycle : std_logic_vector(C_MRL - 1 downto 0);
    
    -- Final pattern signal after voting.
    signal sPtrnVoted : std_logic_vector(C_WIDTH - 1 downto 0);

    -- Voters output warning signals: sCount, sReady and sCycle. 
    signal sWarn : std_logic_vector(2 downto 0);
           

--------------------------------------------------------------------------------
--                          Architecture Behavioral                           --
--------------------------------------------------------------------------------    
begin

    -- Feed the voted pattern to the output. There is no signal-less connection 
    -- between the voting stage and the output because the voted pattern is also
    -- used for re-alignment of the pattern generators themselves.
    COUT: process(sPtrnVoted)
    begin
        PTRN <= sPtrnVoted;
    end process;

    -- Generates 'C_MRL' pattern generators.
    MR: for i in 0 to (C_MRL - 1) generate
        PG : entity work.muPG
        generic map(
            C_WIDTH => C_WIDTH
        )
        port map(
            CLK    => CLK,
            RST    => RST,
            SET    => sSet(i),
            SETVAL => sPtrnVoted,
            PTRN   => sPtrn((i + 1) * C_WIDTH - 1 downto i * C_WIDTH),
            READY  => sReady(i),
            CYCLE  => sCycle(i)
        );
    end generate MR;

    -- Single output voter (C_MRO => false) for the 'sPtrn' stacked bus signals.
    VOTE_PTRN : entity work.mrVotingStage
    generic map (
        C_WIDTH => C_WIDTH,
        C_MRL   => C_MRL,
        C_MRO   => false
    )
    port map(
        INPUT   => sPtrn,
        OUTPUT  => sPtrnVoted,
        WARN    => sWarn(0)
    );

    -- Single output voter (C_MRO => false) voter for the 'sReady' signals.
    VOTE_READY : entity work.mrVotingStage
    generic map(
        C_WIDTH => 1,
        C_MRL   => C_MRL,
        C_MRO   => false
    )
    port map(
        INPUT  => sReady,
        OUTPUT(0) => READY,
        WARN   => sWarn(1)
    );

    -- Single output voter (C_MRO => false) voter for the 'sCycle' signals.
    VOTE_CYCLE : entity work.mrVotingStage
    generic map(
        C_WIDTH => 1,
        C_MRL   => C_MRL,
        C_MRO   => false
    )
    port map(
        INPUT  => sCycle,
        OUTPUT(0) => CYCLE,
        WARN   => sWarn(2)
    );

    -- Or for the 'sWarn' signals.
    OR_WARN : entity work.mrOr
    generic map(
        C_WIDTH => 3
    )
    port map(
        INPUT  => sWarn,
        OUTPUT => WARN
    );

end Behavioral;
