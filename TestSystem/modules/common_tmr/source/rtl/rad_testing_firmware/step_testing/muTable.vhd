-------------------------------------------------------------------------------
-- Title      : muTable
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : muTable.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-05-19
-- Last update: 2016-12-12
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: arbitrary width completely combinatorial transfer function (table)
-- with 'C_WIDTH' wide input and 'C_WIDTH' wide output.
--
-- GENERICS: 
--  -> 'C_WIDTH' defines the input and output width of the table.
--
-- I/O PORTS:
--  ->  'INPUT' is the input of the table.
--  ->  'OUTPUT' is the output result.
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
entity muTable is
	generic(
		C_WIDTH:  natural := 1        -- Table input/output width.
	);
	port(
		INPUT:    in  std_logic_vector(C_WIDTH - 1 downto 0);
		OUTPUT:   out  std_logic_vector(C_WIDTH - 1 downto 0)
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
	attribute DONT_TOUCH of muTable: entity is "true";
	
end muTable;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of muTable is

    -- 'fTable' generates a transfer function of 'C_WIDTH' inputs which uses a 
    -- lot (but not the math theoretical maximum yet) of LUT resources. 
    impure function fTable(idx : natural) return std_logic_vector is    
        variable result : std_logic_vector(C_WIDTH - 1 downto 0);       
    begin
        
        -- Simple counter transfer function.
        result := std_logic_vector(to_unsigned(idx + 1, C_WIDTH));
        
        -- Debug output, keep it as it is useful for testing different transfer functions.
        -- SYNTHESIS TRANSLATE_OFF
        -- report "idx = " &  integer'image(to_integer(unsigned(idx))) 
        --      & ", result = " &  integer'image(to_integer(unsigned(result)));
        -- SYNTHESIS TRANSLATE_ON
        
        return result;
    end function fTable;
    
     -- Implement the combinatorial logic block(s), defined by a generic 'C_WIDTH'
     -- inputs virtual LUT table. (The actual implementation will use a combination 
     -- of different hardware LUTs or LUT slices accordingly to the chosen transfer 
     -- function complexity).
     type tTable is array (0 to 2 ** C_WIDTH - 1) of std_logic_vector(C_WIDTH - 1 downto 0);
     signal sTable: tTable;        
        
begin

    -- Synthetize the table into physical LUT(s).
    TABLE: for i in 0 to (2 ** C_WIDTH - 1) generate
	   --sTable(i) <= fTable(std_logic_vector(to_unsigned(i, C_WIDTH)));
        sTable(i) <= fTable(i);
    end generate TABLE;

	-- ASYNC input process which drives the table outputs.
    ASYNC: process(INPUT, sTable)
    begin
        OUTPUT <= sTable(to_integer(unsigned(INPUT)));
    end process;
	
end Behavioral;
