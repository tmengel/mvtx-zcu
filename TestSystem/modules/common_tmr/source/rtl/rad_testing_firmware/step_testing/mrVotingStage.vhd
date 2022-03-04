-------------------------------------------------------------------------------
-- Title      : mrVotingStage
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrVotingStage.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-04
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: completely combinatorial voting stage for 'C_MRL' replicated bus
-- of width 'C_WIDTH' (can be a single bit bus, i.e. a signal). The output will
-- be a signle (end of block) or a 'C_MRL' parallell (full MR) bus/signal depending
-- on the 'C_MRO' boolean (set to 'true' for full modular redundancy, to 'false'
-- for end-of-the-line single voter). 
--
-- GENERICS: 
--   -> 'C_WIDTH' defines the width of the bus (can be single bit).
--   -> 'C_MR' enables ('true') or disable ('false') the modular redundancy. When
--      'false' the unit actually becomes a simple connection, with no additional
--      logic. Note that when 'C_MR = false' the unit becomes a parallel bus of
--      'C_MRL' lanes, each 'C_WIDTH' wide (no cross-voting occurs) in case 
--      'C_MRO = true', otherwise a single lane of width 'C_WIDTH'.
--   -> 'C_MRL' defines the level of Modulare Redundancy of the hardened components,
--      should be odd and it is anyway suggested to only use the 3 and 5 values. 
--   -> 'C_MRO' defines whether a single voter output is implemented ('C_MRO = false', 
--      like in an end-of-the-block situation) or 'C_MRL' parallel voters are actually 
--      created ('C_MRO = true') to have 'C_MRL' indipendents outputs.
--   -> 'C_MRW' defines whether to compute the output 'WARN' bit (deafult, 'C_MRW = true')
--      or to tye it to the logical value '0' ('C_MRW = false'). Setting 'C_MRW' to false
--      saves logic resources.
--
--   -> ** IMPORTANT ** : if 'C_MR = false', 'C_MRL > 1' and 'C_MRO = false' the unit CANNOT
--      synthetize, as it is asked to join different inputs without voting them.
--
--
-- I/O PORTS:
--  ->  'INPUT' is the bus input, 'C_WIDTH * C_MRL' wide. Connections are expected as 
--      follow, i.e. every full bus copy in sequence, NOT interleaved:
--      INPUT(0)                    => Bus(0)Bit(0)
--      INPUT(1)                    => Bus(0)Bit(1)
--      ....
--      INPUT(C_WIDTH - 2)          => Bus(0)Bit(C_WIDTH - 2)
--      INPUT(C_WIDTH - 1)          => Bus(0)Bit(C_WIDTH - 1)
--      INPUT(C_WIDTH)              => Bus(1)Bit(0)
--      INPUT(C_WIDTH + 1)          => Bus(1)Bit(1)
--      ....
--      INPUT(C_MR * C_WIDTH - 3)   => Bus(C_MR - 1)Bit(C_WIDTH - 3)
--      INPUT(C_MR * C_WIDTH - 2)   => Bus(C_MR - 1)Bit(C_WIDTH - 2)
--      INPUT(C_MR * C_WIDTH - 1)   => Bus(C_MR - 1)Bit(C_WIDTH - 1)
--
--  ->  'OUTPUT' is the voted bus output in case 'C_MRO = false'. Otherwise, is
--      a 'C_MRL' replica of the parallel voting process, and it is arranged in 
--      the same fashion as the 'INPUT' port. 
--  ->  'WARN' is a warning flag which, if high, indicates that within the unit
--      voting system not all the signals agree.
--
-- Unit example appearance accordingly to various generic setting. 
-- Here 'C_MRL = 3' for simplicity. INPUT/OUTPUT port have size 'C_WIDTH'
--
-- 'C_MR = false', 'C_MRO = false', 'C_MRL = 3':
--
--      INPUT(0) -> OUTPUT(0)
--
-- 'C_MR = false', 'C_MRO = true', 'C_MRL = 3':
--
--      INPUT(0) -> OUTPUT(0)
--      INPUT(1) -> OUTPUT(1)
--      INPUT(2) -> OUTPUT(2)
--
-- 'C_MR = true', 'C_MRO = false', 'C_MRL = 3':
--
--      INPUT(0) \
--      INPUT(1) -> VOTER -> OUTPUT
--      INPUT(2) /
--
-- 'C_MR = true', 'C_MRO = true', 'C_MRL = 3':
--
--      INPUT(0) \// VOTER(0) -> OUTPUT(0)
--      INPUT(1) \\/ VOTER(1) -> OUTPUT(1)
--      INPUT(2) /\\ VOTER(2) -> OUTPUT(2)
--

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Package.
use work.mrTools_pkg.all; 

    
--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity mrVotingStage is
	generic(
		C_WIDTH:  natural := 1;       -- Bus width.
		C_MR:     boolean := true;    -- Modular Redundancy enabled.    
		C_MRL:    natural := 3 ;      -- Modular Redundancy Level.
		C_MRO:    boolean := false;   -- Modular Redundant Output.
		C_MRW:    boolean := true     -- Enable warning flag.
	);
	port(
		--INPUT:    in  std_logic_vector(mrSel(C_WIDTH * C_MRL, C_WIDTH, C_MR) - 1 downto 0);
		--OUTPUT:   out std_logic_vector (mrPortWidth(C_WIDTH, C_MRL, C_MR and C_MRO) - 1 downto 0);
		INPUT:    in  std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRO or C_MR) - 1 downto 0);
        OUTPUT:   out std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRO) - 1 downto 0);
        WARN:     out std_logic
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
	attribute DONT_TOUCH of mrVotingStage: entity is "true";
		
end mrVotingStage;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of mrVotingStage is
    
    -- Routing signals.
    type tInput is array (0 to C_WIDTH - 1) of std_logic_vector(C_MRL - 1 downto 0);
    signal sInput: tInput;
    signal sWarn:  std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRO) - 1 downto 0);
    
begin

    -- MR enable.
    MR: if (C_MR = true) generate

	   -- "Bundles" the input signals by grouping together the bit of the same weight
	   -- (position) from the 'C_MRL' inputs, where each imputs is 'C_WIDTH' wide (see 
	   -- definition of the 'INPUT' port).
	   ROUTE: process(INPUT) 
	   begin
	       for i in 0 to (C_WIDTH - 1) loop
	           for b in 0 to (C_MRL - 1) loop
	               sInput(i)(b) <= INPUT(i + b * C_WIDTH);
	           end loop;
	       end loop;
	   end process;
	
	   -- Instantiate one (if 'C_MRO = false') or 'C_MRL' (if 'C_MRO = true') voter(s) 
	   -- for each of the bus 'C_WIDTH' bits. Each voter gets 'C_MRL' bits and vote the 
	   -- majority among them. The 'WARN' output from each voter is collected in a 
	   -- single 'mrOr' component to generate a single warning.
        BITN: for i in 0 to (C_WIDTH - 1) generate
            OUTN: for b in 0 to (mrVotersCount(C_MRL, C_MRO) - 1) generate
                V: entity work.mrVoter
                generic map (
                    C_MRL => C_MRL,
                    C_MRW => C_MRW
                )
                port map (
                    INPUT   => sInput(i),
                    OUTPUT  => OUTPUT(i + b * C_WIDTH),
                    WARN    => sWarn(i + b * C_WIDTH)
                );
            end generate OUTN;
        end generate BITN;
    
        -- Warning signal. Put in OR the warning signals from all the voters to signal 
        -- any disagreement condition. 
        WRN: if (C_MRW = true) generate
            OR_WARN: entity work.mrOr
            generic map (
                C_WIDTH => mrPortWidth(C_WIDTH, C_MRL, C_MRO)
            )
            port map (
               INPUT   =>  sWarn,
               OUTPUT  =>  WARN
            );
        else generate
            WARN <= '0';
        end generate WRN;    
    
    -- MR disabled, just a transparent connection, no warning whatsoever.    
    else generate
    
        OUTPUT <= INPUT; 
        WARN <= '0';
        
    end generate MR;
        
end Behavioral;
