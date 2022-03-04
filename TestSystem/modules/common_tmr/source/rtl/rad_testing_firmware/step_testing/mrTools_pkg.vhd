-------------------------------------------------------------------------------
-- Title      : mrTools_pkg
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrTools_pkg.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-03-24
-- Last update: 2016-09-07
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: package containing helpers tools to handle/generate Modular
-- Redundant support units (voters, etc...)
--
--
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author		Description
-- 2016-01-29   1.0         Piero		Created
------------------------------------------------------------------------------- 


-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;


------------------------------------------------------------------------------------------------------------------------
--                                                 Package Declaration                                                --
------------------------------------------------------------------------------------------------------------------------
package mrTools_pkg is
	
	-- Attribute to stop synthesis optimization. In the Xilinx framework, this will both stop synthesys and placement 
	-- optimization of the component.
    attribute DONT_TOUCH: string;
    
    -- General width bus port, useful to define variable redundancy structures.
    type mrPort is array (natural range <>) of std_logic_vector;
        
	-- Converts a boolean to an integer (0 for false, or 1 for true).
	function mrToInt(input: boolean) return integer;                   
    
    -- Returns the port width of a voting system having an 'busWidth' data width, 'mrl' redundancy level 
    -- and 'mrio' boolean of input/output.
    function mrPortWidth(busWidth: natural; mrl: natural; mrio: boolean) return natural;     
    
    -- Returns the bus indexing MSB for a replicated bus of width 'busWidth' replicated 'mrl' times if 'mr=true'. 
    function mrBusMSB(busWidth: natural; mrl: natural; mr: boolean; index : natural) return natural;     
    
    -- Returns the bus indexing LSB for a replicated bus of width 'busWidth' replicated 'mrl' times if 'mr=true'. 
    function mrBusLSB(busWidth: natural; mrl: natural; mr: boolean; index : natural) return natural;     
        
    -- Returns the required number of voters for each bit, depending on the redundancy level and the output type.
    function mrVotersCount(mrl: natural; mro: boolean) return natural;
    
    -- Return 'a' when 'flga = true', 'b' when 'flag = false'.
    function mrSel(a: natural; b: natural; flag: boolean) return natural;
    
    -- Generate truth table for a voting function of 'mrl' bits (votes the majority of 'input').
    function mrVote(mrl: natural; input: natural) return std_logic;
    
    -- Generate truth table for a warning function of 'mrl' bits ('0' if all equal in 'input', '1' otherwise).
    function mrWarn(mrl: natural; input: natural) return std_logic;
        
 end mrTools_pkg;


------------------------------------------------------------------------------------------------------------------------
--                                                    Package Body                                                    --
------------------------------------------------------------------------------------------------------------------------
package body mrTools_pkg is
    
    -- Converts boolean value to integer.
    function mrToInt(input: boolean) return integer is
    begin
        if (input = true) then 
            return 1;
        else 
            return 0;
        end if;    
    end mrToInt;
    
    -- Returns the port width for a voting system; 'busWidth' defines the data bus width (can be 1). 'mrl' sets
    -- the Modular Redundancy level (3, 5,...). 'mrio' sets whether there is a single input or output (false) or 
    -- a fully 'mrl' replicated parallel input or output (true).     
    function mrPortWidth(busWidth : natural; mrl : natural; mrio: boolean) return natural is
    begin
        if (mrio = true) then 
            return busWidth * mrl;
        else 
            return busWidth;
        end if;
    end mrPortWidth;
    
    -- Returns the bus indexing MSB for a replicated bus of width 'busWidth' replicated 'mrl' times if 'mr=true'. 
    -- 'index' MUST range between '0' and 'mrl - 1' included.
    function mrBusMSB(busWidth : natural; mrl : natural; mr : boolean; index : natural) return natural is     
    begin
        if (mr = true) then 
            return busWidth * (index + 1) - 1;
        else 
            return busWidth - 1;
        end if;
    end mrBusMSB;    
    
    -- Returns the bus indexing LSB for a replicated bus of width 'busWidth' replicated 'mrl' times if 'mr=true'.
    -- 'index' MUST range between '0' and 'mrl - 1' included. 
    function mrBusLSB(busWidth : natural; mrl : natural; mr : boolean; index : natural) return natural is     
    begin
        if (mr = true) then 
            return busWidth * index;
        else 
            return 0;
        end if;
    end mrBusLSB;    
             
    -- Returns the required number of voters for each bit, depending on the redundancy level and the output type.
    -- The number of required voters is simply 1 if a single output is requested ('mro = false'), or it is equal
    -- to 'mrl' otherwise ('mro = true').
    function mrVotersCount(mrl: natural; mro: boolean) return natural is
    begin
        if (mro = true) then 
            return mrl;
        else 
            return 1;
        end if;
    end mrVotersCount;
    
    -- Returns 'a' if 'flag = true', returns 'b' if 'flag = false'.
    function mrSel(a: natural; b: natural; flag: boolean) return natural is
    begin
        if (flag = true) then 
            return a;
        else 
            return b;
        end if;
    end mrSel;
    
    -- Vote among n bits, returning the majority value. 
    function mrVote(mrl: natural; input: natural) return std_logic is
        variable count : natural := 0;     
    begin
        -- Loop over all (mrl - 1) inputs and count how many '1'.
        for i in 0 to mrl - 1 loop
            if (to_unsigned(input, mrl)(i) = '1') then
                count := count + 1;
            end if;
        end loop;
    
        -- Returns the majority vote.
        if (2 * count > mrl) then
            return '1';
        else
            return '0';
        end if;
    end function mrVote;
    
    -- Warn among n bits, returning '0' if they are all the same, '1' otherwise. 
    function mrWarn(mrl: natural; input: natural) return std_logic is
    begin
        -- Loop over all (mrl - 1) inputs and check for differencies.
        for i in 1 to mrl - 1 loop
            if ( to_unsigned(input, mrl)(i) /= to_unsigned(input, mrl)(i - 1) ) then
                return '1';
            end if;
        end loop;
        
        -- Full agreement.
        return '0';
    end function mrWarn;
                 
end mrTools_pkg;
