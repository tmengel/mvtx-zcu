-------------------------------------------------------------------------------
-- Title      : muComp
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : muComp.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-08
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2016.1
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: completely combinatorial comparator. While this is a simple
-- comparator, it is implemented in its own entity to keep MR enforcements
-- with different synthesys tools. 
-- Generic 'C_WIDTH' states the input signals width, while the output 'DIFF'
-- stays '0' as long as the two input signals 'PTRN1' and 'PTRN2' are identical
-- or moves to '1' if they differ.

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Packages.
use work.mrTools_pkg.all;


--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity muComp is
    generic (
        -- Width of the input signals.
        C_WIDTH: natural:= 6    
    );
    port (  
        PTRN1:  in std_logic_vector(C_WIDTH - 1 downto 0);
        PTRN2:  in std_logic_vector(C_WIDTH - 1 downto 0);
        DIFF:   out std_logic:= '0'
    );
    
    -- Make 'rtDisc' untouchable by the synthesis/placement tools. 
    attribute DONT_TOUCH of muComp: entity is "TRUE";
        
end muComp;


--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of muComp is
        
begin
    
    -- Comparator, outputs '0' if the two input signals match, '1' otherwise.
    process(PTRN1, PTRN2)
    begin
        if (PTRN1 = PTRN2) then
            DIFF <= '0'; 
        else
            DIFF <= '1';
        end if;
    end process;
    
end Behavioral;
