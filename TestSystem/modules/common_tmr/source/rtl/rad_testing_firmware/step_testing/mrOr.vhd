-------------------------------------------------------------------------------
-- Title      : mrOr
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : mrOr.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-01-13
-- Last update: 2016-02-13
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: 'mrOr' is a simple multiple input OR port of 'C_MR' width.
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


--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity mrOr is
    generic (
        C_WIDTH:  natural:= 3    -- or port width.
    );
    port (  
        INPUT:  in  std_logic_vector(C_WIDTH - 1 downto 0);
        OUTPUT: out std_logic
    );
end mrOr;


--------------------------------------------------------------------------------
--                          Architecture Declaration                          --
--------------------------------------------------------------------------------
architecture Behavioral of mrOr is

    -- Or cascade signals.
    signal sOr: std_logic_vector(C_WIDTH - 1 downto 0):= (others => '0');        
        
--------------------------------------------------------------------------------
--                          Architecture Behavioral                           --
--------------------------------------------------------------------------------    
begin
    
    -- Creates an arbitrary wide OR port by cascading the 'C_MR' input signals. 
    sOr(0) <= INPUT(0);
    MR_OR:  for i in 1 to (C_WIDTH - 1) generate
        WARN: process (INPUT(i), sOr(i - 1))
        begin
            sOr(i) <= sOr(i - 1) or INPUT(i);
        end process;    
    end generate MR_OR;
    
    -- Set at the output the last stage of the OR cascade.
    OUTOR: process (sOr)
    begin
        OUTPUT <= sOr(C_WIDTH - 1);
    end process;    
            
end Behavioral;
