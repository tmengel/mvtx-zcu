-------------------------------------------------------------------------------
-- Title      : wishbone arbiter
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : wb_arbiter.vhd
-- Author     : Joachim Schambach  <jschamba@pisces.rhip.utexas.edu>
-- Company    : University of Texas at Austin
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2018-03-19
-- Last update: 2018-04-13
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Simple round-robin arbiter for multiple wishbone masters
-------------------------------------------------------------------------------
-- Copyright (c) 2018 University of Texas at Austin
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018-03-19  1.0      jschamba  Created
-- 2018-03-23  1.1      ML        Configurable number of masters
-- 2018-04-09  1.2      ML        Updated to tmr the state, removed grant signal
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;

entity wb_arbiter is
  generic (
    G_WB_MASTER_NUMBER : integer := 4;
    G_GRANT_WIDTH      : integer := 2);
  port (
    clk_i   : in  std_logic;
    rst_i   : in  std_logic;
    busy_i  : in  std_logic;
    count_o : out std_logic_vector((G_GRANT_WIDTH - 1) downto 0);
    count_i : in  std_logic_vector((G_GRANT_WIDTH - 1) downto 0)
    );

end entity wb_arbiter;

architecture Behavioral of wb_arbiter is
  signal u_count_out, u_count_in : unsigned((G_GRANT_WIDTH - 1) downto 0);

begin  -- architecture Behavioral

  u_count_in <= unsigned(count_i);

  count_o <= std_logic_vector(u_count_out);

  p_ctr : process (clk_i) is
  begin  -- process p_ctr
    if rising_edge(clk_i) then
      if rst_i = '1' then
        u_count_out <= (others => '0');
      elsif busy_i = '0' then
        if to_integer(u_count_in) = (G_WB_MASTER_NUMBER - 1) then
          u_count_out <= (others => '0');
        else
          u_count_out <= u_count_in + 1;
        end if;
      end if;
    end if;
  end process p_ctr;

end architecture Behavioral;
