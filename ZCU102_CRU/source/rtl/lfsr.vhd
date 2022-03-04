-- $Id$
-------------------------------------------------------------------------------
-- Title      : Linear Feedback Shift Register
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : lfsr.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2016-05-10
-- Last update: 2016-05-10
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Implementation of a Linear Feedback Shift Register according to
--              GBTx manual V0.11 page 44
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;

entity LFSR is
  port (
    CLK          : in  std_logic;
    RST          : in  std_logic;                     -- active hi reset
    SEED         : in  std_logic_vector(6 downto 0);  -- parallel seed input
    PARALLEL_OUT : out std_logic_vector(6 downto 0)   -- parallel data out
    );
end entity LFSR;

architecture RTL of LFSR is
begin
  pLFSR : process (CLK)
    variable vLFSR_reg : std_logic_vector(6 downto 0) := (others => '0');
  begin
    if rising_edge(CLK) then
      if RST = '1' then
        vLFSR_reg := SEED;
      else
        vLFSR_reg := vLFSR_reg(5 downto 0) & (vLFSR_reg(6) xor vLFSR_reg(5));
      end if;
    end if;
    PARALLEL_OUT <= vLFSR_reg;
  end process;
end RTL;
