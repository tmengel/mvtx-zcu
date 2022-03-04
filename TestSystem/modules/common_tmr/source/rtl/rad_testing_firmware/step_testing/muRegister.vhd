-------------------------------------------------------------------------------
-- Title      : muRegister
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : muRegister.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-05-19
-- Last update: 2016-05-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: arbitrary width register, used as basic unit to form modular
-- redundant entities. 
--
-- GENERICS: 
--   -> 'C_WIDTH' defines the width of the register (can be single bit).
--
-- I/O PORTS:
--  ->  'CLK' active high, loads the registers on the rising edge.
--  ->  'RST' sinchronous reset, active high, resets to '(others=>'0')'.   
--  ->  'INPUT' is the bus input, 'C_WIDTH' wide.
--  ->  'OUTPUT' is the bus output, 'C_WIDTH'
--
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author          Description
-- 2016-01-29   1.0         Piero        Created
------------------------------------------------------------------------------- 

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Instantiate 'mrTools_pkg' package.
use work.mrTools_pkg.all; 

    
--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity muRegister is
	generic(
		C_WIDTH:  natural := 1        -- Register width.
	);
	port(
		CLK:      in std_logic;
		RST:      in std_logic;
		INPUT:    in  std_logic_vector(C_WIDTH - 1 downto 0);
		OUTPUT:   out  std_logic_vector(C_WIDTH - 1 downto 0)
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
	attribute DONT_TOUCH of muRegister: entity is "true";
	
end muRegister;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of muRegister is

    -- The storage register.
    signal rStore : std_logic_vector(C_WIDTH - 1 downto 0);
        
begin

	-- SYNC clocked process.
	SYNC: process (RST, CLK)
	begin
	   if (rising_edge(CLK)) then
	       if (RST = '1') then
	           rStore <= (others => '0');
	       else
	           rStore <= INPUT;
	       end if;
	   end if;
	end process;
	
	-- Output assignment.
	OUTPUT <= rStore;
	
end Behavioral;
