-------------------------------------------------------------------------------
-- Title      : mrFanout
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrFanout.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-05-19
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: fanout port which replicate the input bus into 'C_MRL' output
-- copyes. Accept a 'C_MRL" value of '1', which actually eliminates the unit
-- itself. If the flah 'C_MRI = true' then keep in input 'C_MRL' buses as at
-- the ouptuy, actually realizing a simp[le connection.
--
-- GENERICS: 
--   -> 'C_WIDTH' defines the width of the bus (can be single bit).
--   -> 'C_MRL' defines how many times the input bus is replicated. If '1' simply
--      copy the input bus (actually eliminates the unit itself). 
--   -> 'C_MRI' set that the input bus already replicated 'C_MRL' times, rendering
--      the unit a simple straighforward connection. 
--
-- I/O PORTS:
--  ->  'INPUT' is the bus input, 'C_WIDTH wide.
--  ->  'OUTPUT' is the bus output, where each replicate of the bus follows in
--      the bit ordering:
--      INPUT (C_WIDTH - 1 downto 0) => OUTPUT (C_WIDTH - 1 downto 0).
--      INPUT (C_WIDTH - 1 downto 0) => OUTPUT (2 * C_WIDTH - 1 downto C_WIDTH). 
--      ...
--      INPUT (C_WIDTH - 1 downto 0) => OUTPUT (C_MRL * C_WIDTH - 1 downto (C_MRL - 1) * C_WIDTH).
--
--      the same fashion as the 'INPUT' port. 



-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Instantiate 'mrTools_pkg' package.
use work.mrTools_pkg.all; 

    
--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity mrFanout is
	generic(
		C_WIDTH:  natural := 1;      -- Bus width.
		C_MRL:    natural := 3;      -- Redundancy level.
		C_MRI:    boolean := false   -- Replicate input as well.
	);
	port(
		INPUT:    in  std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRI) - 1 downto 0);
		OUTPUT:   out  std_logic_vector(C_WIDTH * C_MRL - 1 downto 0)
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
	--attribute DONT_TOUCH of mrVotingStage: entity is "true";
	
end mrFanout;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of mrFanout is
        
begin

    -- MRI not enabled, actually copy the input signals to the different outputs.
    MR: if (C_MRI = false) generate

	   -- Routes the signals.
        ROUTE: for i in 0 to (C_MRL - 1) generate
            OUTPUT((i + 1) * C_WIDTH - 1 downto i * C_WIDTH) <= INPUT;
        end generate ROUTE;
        
    -- MRI enabled, simply pass the signals.    
    else generate
        
        -- Directly connect input and output.
        OUTPUT <= INPUT; 
                
    end generate MR;
	
end Behavioral;
