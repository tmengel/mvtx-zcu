-------------------------------------------------------------------------------
-- Title      : muPG
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : muPG.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-04
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Pattern generator for radiation testing, modular unit. 'muPG' is
-- a pattern generator (either BCD or gray counter) with an additional 'SET' 
-- input port used to re-synchronize the counter in case of SEU upset.
-- 'C_WIDTH' program the counting width. On negative reset 'RST_N' the pattern
-- generator restarts the sequence from the state zero.
-- For the realignment procedure: if the 'SET' signal is high, the pattern 
-- generator compares the current pattern with the reference one at the 'SETVAL'
-- input and if they differ, re-synchronize the inner one with the reference.
-- The 'SETVAL' port is usually tied to the voted output of three (or more) 
-- parallel 'muPG'.
--
-- SYNTHESIS GENERICS: 
--   -> 'C_WIDTH' defines the width of the output pattern.
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this clock,
--      i.e. they change state just after the 'CLK' rising edge.
--  ->  'RST' is the active-high synchronous reset. The pattern generator restarts
--      the pattern sequence from the first state after 'RST_N' goes low.
--  ->  'SET' is a flag signal that, if '1' athe time of 'CLK' rising edge set the
--      pattern value equal to the pattern at the 'SETVAL' port.
--  ->  'SETVAL' is a 'C_WIDTH' width input port used in conjunction with 'SET' to 
--      force the current pattern state into the one at the input of the port.
--  ->  'OTRN' is the 'C_WIDTH' wide pattern signal. Synchronous with 'CLK' is
--      tied to (Others => '0') while 'RST_N = 0'.
--  ->  'READY' is a flag signals which goes to '1' after the first cycle of the
--      pattern has been generated, i.e. after 2^C_WIDTH 'CLK' cycles. It returns
--      to '0' after a reset is issued.
--  ->  'CYCLE' is a flag signals asserted at the beginning of every pattern cycle,
--      in synch with the clock.



-- Libraries.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- Packages.
use work.mrTools_pkg.all;

---------------------------------------------------------------------------------
--                              Entity Declaration                             --
---------------------------------------------------------------------------------
entity muPG is
    generic(
        C_WIDTH : natural := 6
    );
    port(
        CLK    : in  std_logic;
        RST    : in  std_logic;
        SET    : in  std_logic;
        SETVAL : in  std_logic_vector(C_WIDTH - 1 downto 0) := (Others => '0');
        PTRN   : out std_logic_vector(C_WIDTH - 1 downto 0) := (Others => '0');
        READY  : out std_logic;
        CYCLE  : out std_logic
    );
  
  -- Makes the unit not touchable by synthesis and implementation.
  attribute DONT_TOUCH of muPG: entity is "true";
  
end muPG;

--------------------------------------------------------------------------------
--                    Architecture 'Behavioral' Declaration                   --
--------------------------------------------------------------------------------    
architecture Behavioral of muPG is

    -- Signals declaration.
    signal rBCount    : unsigned(C_WIDTH - 1 downto 0)         := (Others => '0');
    signal rBNxtCount : unsigned(C_WIDTH - 1 downto 0)         := (Others => '0');
    signal rGCount    : std_logic_vector(C_WIDTH - 1 downto 0) := (Others => '0');
    signal rFirstLoop : std_logic                              := '0';

begin

    -- Outputs the binary counter (could be switched to the gray one).
    COUT : process(rBCount)
    begin
        PTRN <= std_logic_vector(rBCount);
    end process;

    -- Combinatorial addition process.      
    SUM : process(rBCount)
    begin
        rBNxtCount <= rBCount + 1;
    end process;

    -- Sync clock process, sync reset bar.
    process(CLK, RST, SET)
    begin
        
        -- On the clock rising edge.
        if (rising_edge(CLK)) then

            -- Reset.
            if (RST = '1') then
                rBCount    <= to_unsigned(0, C_WIDTH);
                rGCount    <= (others => '0');
                rFirstLoop <= '0';
                READY <= '0';
                CYCLE <= '0';
        
            -- Count.
            else

                -- Increase binary counter and derive gray one.
                if (SET = '0') then
                    rBCount <= rBNxtCount;
                    rGCount <= std_logic_vector(rBNxtCount(C_WIDTH - 1 downto C_WIDTH - 1)) &  
                              (std_logic_vector(rBNxtCount(C_WIDTH - 1 downto 1)) xor std_logic_vector(rBNxtCount(C_WIDTH - 2 downto 0)));
                else
                    rBCount <= unsigned(SETVAL) + 1;
                    rGCount <= SETVAL(C_WIDTH - 1 downto C_WIDTH - 1) & 
                              (SETVAL(C_WIDTH - 1 downto 1) xor SETVAL(C_WIDTH - 2 downto 0));
                end if;
                
                -- Check the completion of the first pattern iteration.
                if (rFirstLoop = '0') then
                    if (rBNxtCount = 0) then
                        READY <= '1';
                        rFirstLoop <= '1';
                    else
                        READY <= '0';
                        rFirstLoop <= '0';
                    end if;
                else
                    READY <= '1';
                    rFirstLoop <= '1';
                end if;

                -- Asserts the CYCLE signal at every pattern cycle.
                if (rBNxtCount = 0) then
                    CYCLE <= '1';
                else
                    CYCLE <= '0';          
                end if;
                
            -- End of Reset/Set/Countcount IF.
            end if;

        -- End of CLK rising edge IF.	
        end if;
    
    -- End of master CLK, RST_N process.
    end process;

end Behavioral;
