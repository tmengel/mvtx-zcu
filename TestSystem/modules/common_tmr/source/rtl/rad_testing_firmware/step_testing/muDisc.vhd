-------------------------------------------------------------------------------
-- Title      : muDisc
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : muDisc.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-04
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: 'muDisc' checks whether the 'INPUT' port is high ('1') at 'CLK'
-- rising edge, between two 'CYCLE' events (supposed to be in synch with 'CLK'), 
-- and outputs a single '1' on 'OUTPUT' in synch with the 'CYCLE' signal and 
-- lasting one clock cycle if 'INPUT' met the condition at least once.
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this 
--      clock, i.e. they change state just after the 'CLK' rising edge.
--  ->  'EN' active high enable, if low forces the output to '0' (no transition
--      signalled whichever the input). This input is asynchronous.
--  ->  'RST' is the active-high synchronous reset. The unit start working after
--      'RST' goes low.
--  ->  'CYCLE' is the input for the pattern cycle, should be in synch with the 
--      clock, and asserted at every pattern cycle end.
--  ->  'READY' is the input for the pattern status, should be in synch with the 
--      clock, and asserted at every pattern cycle end. Transition on the 'INPUT'
--      signal are recorded only when 'READY = 1'.
--  ->  'INPUT' is the input signal where 'rising_edge' transitions are detected.
--  ->  'OUTPUT' is the output, asserted in synch with 'CYCLE' and equal to '1'
--      in case a rising edge has been detected during the interval between the 
--      last and the current 'CYCLE, '0' otherwise. The '1' level remains asserted
--      for one clock cycle only.

-- Libraries.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Packages.
use work.mrTools_pkg.all;

--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity muDisc is
	port(
		CLK    : in  std_logic;
		RST    : in  std_logic;
		EN     : in  std_logic;
		CYCLE  : in  std_logic;
		READY  : in std_logic;
		INPUT  : in  std_logic;
		OUTPUT : out std_logic
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
    attribute DONT_TOUCH of muDisc: entity is "true";
end muDisc;

	
--------------------------------------------------------------------------------
--                     Architecture 'Behavioral' Declaration                  --
--------------------------------------------------------------------------------
architecture Behavioral of muDisc is

    -- The latch register to record events during a cycle.
    signal rEvent : std_logic := '0';

begin
    -- Sync reset clock process.
	SYNC: process (RST, CLK, EN, INPUT, CYCLE, READY)
    begin
        if (rising_edge(CLK)) then
            
            -- Synch reset.
            --if (RST = '0') then
            if (RST = '1') then -- @ksielewi
                OUTPUT <= '0';
                rEvent <= '0';
         
            -- Working.
            else
           
                -- Latch any high level at the clock rising edge.
                if (INPUT = '1' and EN = '1' and READY = '1') then
                    rEvent <= '1';
                end if;
                
                -- Output the latch (and reset it) at every cycle.
                if (CYCLE = '1' and EN = '1') then
                    OUTPUT <= rEvent;
                    rEvent <= '0';
                else
                    OUTPUT <= '0';
                end if;
            end if;   
        end if;
    end process;
    
end Behavioral;
