-------------------------------------------------------------------------------
-- Title      : wishbone master traffic supervision
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : traffic_supervision.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2017-11-14
-- Last update: 2017-11-15
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex Ultrscale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: track information about usage of latest cycles.
--              Imported from source created by wb_builder
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author  Description
-- 2017-11-14  1.0      JS      Imported
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity traffic_supervision is

  generic (
    priority     : integer := 1;
    tot_priority : integer := 2);

  port (
    bg            : in  std_logic;      -- bus grant
    ce            : in  std_logic;      -- clock enable
    traffic_limit : out std_logic;
    clk           : in  std_logic;
    reset         : in  std_logic);

end traffic_supervision;

architecture rtl of traffic_supervision is

  signal shreg : std_logic_vector(tot_priority-1 downto 0);
  signal cntr  : integer range 0 to tot_priority;

begin  -- rtl

  -- purpose: holds information of usage of latest cycles
  -- type   : sequential
  -- inputs : clk, reset, ce, bg
  -- outputs: shreg('left)
  sh_reg : process (clk)
  begin  -- process shreg
    if rising_edge(clk) then
      if ce = '1' then
        shreg <= shreg(tot_priority-2 downto 0) & bg;
      end if;
    end if;
  end process sh_reg;

  -- purpose: keeps track of used cycles
  -- type   : sequential
  -- inputs : clk, reset, shreg('left), bg, ce
  -- outputs: traffic_limit
  counter : process (clk, reset)
  begin  -- process counter
    if reset = '1' then                 -- asynchronous reset (active hi)
      cntr          <= 0;
      traffic_limit <= '0';
    elsif rising_edge(clk) then         -- rising clock edge
      if ce = '1' then
        if bg = '1' and shreg(tot_priority-1) /= '1' then
          cntr <= cntr + 1;
          if cntr = priority-1 then
            traffic_limit <= '1';
          end if;
        elsif bg = '0' and shreg(tot_priority-1) = '1' then
          cntr <= cntr - 1;
          if cntr = priority then
            traffic_limit <= '0';
          end if;
        end if;
      end if;
    end if;
  end process counter;

end rtl;
