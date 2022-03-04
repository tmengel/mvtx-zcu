-------------------------------------------------------------------------------
-- Title      : mrVoter
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrVoter.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-04
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: completely combinatorial single-bit voter for n modular redundancy. 
-- Accepts 'C_MRL' inputs and outputs the majority result. In case of even
-- number of imputs (strongly discouraged) and no majority, outputs a '0'.
-- Also outputs a warning signals which stays '1' as long as any disagreement
-- persist between the input values.
--
--
-- GENERICS: 
--   -> 'C_MRL' defines the number of inputs to be voted, which will correspond to the
--      width of the 'INPUT' port. Should be odd and it is anyway suggested to only use 
--      the 3 and 5 values. 
--   -> 'C_MRW' defines whether to compute the output 'WARN' bit (deafult, 'C_MRW = true')
--      or to tye it to the logical value '0' ('C_MRW = false'). Setting 'C_MRW' to false
--      saves logic resources.
--
-- I/O PORTS:
--  ->  'INPUT' is the multi-bit input, 'C_MRL' wide.
--
--  ->  'OUTPUT' is the single-bit voted output in case. 
--  ->  'WARN' is a warning flag which, if high, indicates that within the unit
--      voting system not all the signals agree. Has to be enabled by setting
--      the the 'C_MRW' generic.

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Packages.
use work.mrTools_pkg.all;

--------------------------------------------------------------------------------
--                              Entity Declaration                            --
--------------------------------------------------------------------------------
entity mrVoter is
	generic(
		C_MRL : natural := 3;     -- Modular Redundancy Level (use 3 or 5).
		C_MRW : boolean := true   -- Output warning signal.
	);
	port(
		INPUT  : in  std_logic_vector(C_MRL - 1 downto 0);
		OUTPUT : out std_logic;
		WARN   : out std_logic
	);
	
    -- Makes the unit not touchable by synthesis and implementation.
    attribute DONT_TOUCH of mrVoter: entity is "true";

end mrVoter;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of mrVoter is

	-- LUT table containing the voting logic.
	signal lutVote: std_logic_vector(2**C_MRL - 1 downto 0);
    
    -- LUT table containing the warning logic.
    signal lutWarn: std_logic_vector(2**C_MRL - 1 downto 0);
    
begin

	-- Compiles the voting LUT with the mrTools_pkg function 'mrVote'.
	CVOTE : for i in 0 to (2 ** C_MRL - 1) generate
		lutVote(i) <= mrVote(C_MRL, i);
	end generate CVOTE;

    -- Compiles the warning LUT with the mrTools_pkg function 'mrWarn'.
	CWARN : for i in 0 to (2 ** C_MRL - 1) generate
	   lutWarn(i) <= mrWarn(C_MRL, i);
	end generate CWARN;

	-- Feeds the LUTs with the input signals and outputs the results 
	COMP : process(INPUT, lutVote, lutWarn)
	begin
		OUTPUT <= lutVote( to_integer( unsigned(INPUT)) );
		if (C_MRW = true) then
            WARN <= lutWarn(to_integer( unsigned(INPUT)) );
		else
            WARN <= '0';  
	   end if;  
    end process;

end Behavioral;
