-------------------------------------------------------------------------------
-- Title      : fiforst.vhd
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : probecard_top.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-04-21
-- Last update: 2016-04-21
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Block to reset the fifo and 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-04-21  1.0      mlupi   Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library UNISIM;
use UNISIM.VComponents.all;

entity fiforst is
  
  generic (
    CLOCK_CYCLES : integer);

  port (
    CLK     : in  std_logic;
    RST     : in  std_logic;
    OUT_RST : out std_logic);

end entity fiforst;

architecture std of fiforst is

signal s_shift_reg : std_logic_vector(CLOCK_CYCLES-1 downto 0);
  
begin  -- architecture std

-- purpose: generates the RST signal which stays high for CLOCK_CYCLES periods of CLK
p_shift: process (CLK) is
begin  -- process p_shift
  if rising_edge(CLK) then              -- rising clock edge
    if RST = '1' then                   -- synchronous reset (active high)
      s_shift_reg <= (others => '1');
    else
      s_shift_reg <= s_shift_reg(CLOCK_CYCLES-2 downto 0) & '0';
    end if;
  end if;
end process p_shift;

OUT_RST <= s_shift_reg(CLOCK_CYCLES-1);

end architecture std;
