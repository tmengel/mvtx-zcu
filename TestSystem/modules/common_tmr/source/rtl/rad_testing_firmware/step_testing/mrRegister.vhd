-------------------------------------------------------------------------------
-- Title      : mrRegister
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrRegister.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-05-19
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: arbitrary width register rising-edge latched with configurable 
-- modular redundant replication and voting stage.
-- 
--
-- SYNTHESIS GENERICS: 
--   -> 'C_WIDTH' defines the width of the register (can be single bit).
--   -> 'C_MR' enables ('true') or disable ('false') the modular redundancy. When
--      'false' the unit actually becomes a simple register, with no additional
--      logic.    
--   -> 'C_MRL' sets the redundancy level. Usually 3 or 5.
--   -> 'C_MRI' sets multiple parallel input, i.e. the unit 'INPUT' port becomes
--      'C_WIDTH * C_MRL' wide accomodating 'C_MRL' parallel inputs to directly
--      feed the replicated registers. Useful to create last-stage redundant
--      register(s) blocks. 
--   -> 'C_MRO' defines the shape of the output. If 'C_MRO = false' a single 
--      'C_WIDTH' wide output contains the voted result for every bit replica
--      set. If 'C_MRO = true' the outputs is 'C_WIDTH * C_MRL' wide and
--      carries the result of 'C_MRL' voting procedures, arranged by bit:
--      OUTPUT (0)                          => Voter #1 result of voting bit #0 replicae.
--      OUTPUT (1)                          => Voter #1 result of voting bit #1 replicae.
--      OUTPUT (..)                         => Voter #1 result of voting bit #.. replicae.
--      OUTPUT (C_WIDTH - 1)                => Voter #1 result of voting bit #C_WIDTH - 1 replicae.
--      OUTPUT (C_WIDTH)                    => Voter #2 result of voting bit #0 replicae.
--      OUTPUT (C_WIDTH + 1)                => Voter #2 result of voting bit #1 replicae.
--      OUTPUT (C_WIDTH + ...)              => Voter #2 result of voting bit #.. replicae.
--      ...
--      OUTPUT ((C_MRL - 1) * C_WIDTH)      => Voter #C_MRL result of voting bit #0 replicae.
--      OUTPUT ((C_MRL - 1) * C_WIDTH + ..) => Voter #C_MRL result of voting bit #.. replicae.
--      OUTPUT (C_MRL * C_WIDTH - 1)        => Voter #C_MRL result of voting bit #C_WIDTH - 1 replicae.
--
-- I/O PORTS:
--  ->  'CLK' active high, loads the registers on the rising edge.
--  ->  'RST' sinchronous reset, active high, resets to '(others=>'0')'.   
--  ->  'INPUT' is the bus input, 'C_WIDTH' wide.
--  ->  'OUTPUT' is the bus output, 'C_WIDTH' wide if 'C_MRO = false',
--      'C_MRL * C_WIDTH' wide if 'C_MRO = true'.
--  ->  'WARN' is a warning flag which, if high, indicates that within the unit
--      voting system not all the signals agree, i.e. that some upset is affecting
--      the unit. The signal is completely asynchronous.
--
-- Unit example appearance accordingly to various generic setting. 
-- Here 'C_MRL = 3' for simplicity.
--
-- 'C_MR = false', all other generics irrelevant:
--
--      INPUT -> REG -> OUTPUT
--
-- 'C_MR = true', 'C_MRI = false', 'C_MRO = false':
--
--             /->  REG(0) \
--      INPUT --->  REG(1) -> VOTER => OUTPUT
--             \->  REG(2) /
--
-- 'C_MR = true', 'C_MRI = true', 'C_MRO = false':
--
--      INPUT(0)  -->  REG(0) \
--      INPUT(1)  -->  REG(1) -> VOTER => OUTPUT
--      INPUT(2)  -->  REG(2) /
--
-- 'C_MR = true', 'C_MRI = false', 'C_MRO = true':
--
--             /->  REG(0) \// VOTER(0) -> OUTPUT(0)
--      INPUT --->  REG(1) \\/ VOTER(1) -> OUTPUT(1)
--             \->  REG(2) /\\ VOTER(2) -> OUTPUT(2)
--
-- 'C_MR = true', 'C_MRI = true', 'C_MRO = true':
--
--      INPUT(0)  -->  REG(0) \// VOTER(0) -> OUTPUT(0) 
--      INPUT(1)  -->  REG(1) \\/ VOTER(1) -> OUTPUT(1) 
--      INPUT(2)  -->  REG(2) /\\ VOTER(2) -> OUTPUT(2) 


-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Instantiate 'mrTools_pkg' package.
use work.mrTools_pkg.all; 

    
--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity mrRegister is
	generic(
		C_WIDTH:  natural := 1;       -- Register width.
		C_MR:     boolean := true;    -- Modular redundancy enabled.
		C_MRL:    natural := 3;       -- Modularity level.
		C_MRI:    boolean := false;   -- Modular input.
		C_MRO:    boolean := false;   -- Modular output.
		C_MRW:    boolean := false    -- Enable warning flag.
	);
	port(
		CLK:      in std_logic;
		RST:      in std_logic;
		INPUT:    in  std_logic_vector(mrSel(C_WIDTH * C_MRL, C_WIDTH, C_MR and C_MRI) - 1 downto 0);
		OUTPUT:   out  std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MR and C_MRO) - 1 downto 0);
		WARN:     out std_logic
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
	attribute DONT_TOUCH of mrRegister: entity is "true";
	
end mrRegister;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of mrRegister is

    -- Input fan-out signal (in case).
    signal sInput: std_logic_vector(mrSel(C_WIDTH * C_MRL, C_WIDTH, C_MR) - 1 downto 0);

    -- Registers to voters connection.
    signal sReg: std_logic_vector(mrSel(C_WIDTH * C_MRL, C_WIDTH, C_MR) - 1 downto 0);
        
begin
    
    -- MR enabled.
    MR: if (C_MR = true) generate
            
        -- Fan-out input if necessary .
        FANOUT: entity work.mrFanout
            generic map(
                C_WIDTH => mrSel(C_WIDTH * C_MRL, C_WIDTH, C_MRI),
                C_MRL   => mrSel(1, C_MRL, C_MRI)
            )
            port map(
                INPUT   => INPUT,
                OUTPUT  => sInput
            );        
        
        -- Generates the registers.
        Rs: for i in 0 to C_MRL - 1 generate
            R: entity work.muRegister
            generic map(
                C_WIDTH => C_WIDTH
            )
            port map(
                CLK => CLK,
                RST => RST,
                INPUT => sInput( (i + 1) * C_WIDTH - 1 downto i * C_WIDTH ),
                OUTPUT => sReg( (i + 1) * C_WIDTH - 1 downto i * C_WIDTH ) 
            );
        end generate Rs;

        -- Generates the registers voter(s).
        V: entity work.mrVotingStage
            generic map (
                C_WIDTH => C_WIDTH,
                C_MRL   => C_MRL,
                C_MRO   => C_MRO,
                C_MRW   => C_MRW
            )
            port map(
                INPUT   => sReg,
                OUTPUT  => OUTPUT,
                WARN    => WARN
            );
    
    -- MR disable, implement a simp-le register.
    else generate
    
        -- Single register (multibit).
        R: entity work.muRegister
            generic map(
                C_WIDTH => C_WIDTH
            )
            port map(
                CLK => CLK,
                RST => RST,
                INPUT => INPUT,
                OUTPUT => OUTPUT 
            );
        
        -- No warning signal.
        WARN <= '0';
        
    end generate MR;
        	
end Behavioral;
