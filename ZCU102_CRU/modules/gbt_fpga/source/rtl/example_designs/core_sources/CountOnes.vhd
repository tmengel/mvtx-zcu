----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.02.2016 10:21:35
-- Design Name: 
-- Module Name: CountOnes - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CountOnes is
    Generic (SIZE           : POSITIVE := 32;
             MAXOUTWIDTH    : POSITIVE := 6);
    Port ( Clock    : in  STD_LOGIC;
           I        : in  STD_LOGIC_VECTOR (SIZE-1 downto 0);
           O        : out STD_LOGIC_VECTOR (MAXOUTWIDTH-1 downto 0));
end CountOnes;

architecture RTL of CountOnes is

    component CountOnes is 
        generic (SIZE : POSITIVE;
                 MAXOUTWIDTH : POSITIVE
        );
    port (Clock : in std_logic;
        I : in  std_logic_vector(SIZE-1 downto 0);
        O : out std_logic_vector(MAXOUTWIDTH-1 downto 0));
    end component;
    
    signal UpperOutput : std_logic_vector(O'LENGTH-2 downto 0);
    signal LowerOutput : std_logic_vector(O'LENGTH-2 downto 0);

begin

    GT1: if SIZE > 1 generate
        UpperHalf : CountOnes 
        generic map (SIZE => SIZE-SIZE/2,
                     MAXOUTWIDTH => MAXOUTWIDTH-1)
        port map (
            Clock => Clock,
            I => I(SIZE-1 downto SIZE/2),
            O => UpperOutput);
       
        LowerHalf : CountOnes 
        generic map (SIZE  => SIZE/2,
                     MAXOUTWIDTH => MAXOUTWIDTH-1)
        port map  (
            Clock => Clock,
            I     => I(SIZE/2-1 downto 0),
            O     => LowerOutput);

        clk: process(Clock)
        begin
            if rising_edge(clock) then 
                O <= std_logic_vector(unsigned('0' & UpperOutput) +
                                      unsigned(LowerOutput) );
            end if;
        end process;
    end generate;
     
    EQ1: if SIZE = 1 generate
        process(Clock)
        begin
            if rising_edge(clock) then
                O <= (others => '0');
                if I(0) = '1' then
                    O(0) <= '1';
                end if;
            end if;
        end process;
    end generate;

end RTL;
