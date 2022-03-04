-------------------------------------------------------------------------------
-- Title      : Wishbone master mux
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : wb_master_mux.vhd
-- Author     : Joachim Schambach  <jschamba@pisces.rhip.utexas.edu>
-- Company    : University of Texas at Austin
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2018-03-19
-- Last update: 2018-03-23
-- Platform   : Vivado 2016.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone Master multiplexer
-------------------------------------------------------------------------------
-- Copyright (c) 2018 University of Texas at Austin
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018-03-19  1.0      jschamba  Created
-- 2018-03-23  1.1      ML        Updated wb_master_mux to use package defined
--                                constants instead of generics (redundant)
-- 2018-03-23  2.0      ML        Configurable number of masters
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;

entity wb_master_mux is
  generic (
    G_WB_MASTER_NUMBER : natural := 2;  -- defined to avoid package entanglement
    G_GRANT_WIDTH : integer := 2);
  port (
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    -- signals from a master interface
    cyc_i     : in  std_logic_vector(G_WB_MASTER_NUMBER - 1 downto 0);
    stb_i     : in  std_logic_vector(G_WB_MASTER_NUMBER - 1 downto 0);
    we_i      : in  std_logic_vector(G_WB_MASTER_NUMBER - 1 downto 0);
    addr_i    : in  t_wb_add_array(0 to G_WB_MASTER_NUMBER-1);
    dat_m2s_i : in  t_wb_dat_array(0 to G_WB_MASTER_NUMBER-1);
    dat_s2m_o : out std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
    ack_o     : out std_logic_vector(G_WB_MASTER_NUMBER - 1 downto 0);
    err_o     : out std_logic_vector(G_WB_MASTER_NUMBER - 1 downto 0);
    -- signals to a slave interface
    cyc_o     : out std_logic;
    stb_o     : out std_logic;
    addr_o    : out std_logic_vector(WB_ADD_WIDTH - 1 downto 0);
    we_o      : out std_logic;
    dat_m2s_o : out std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
    --
    dat_s2m_i : in  std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
    ack_i     : in  std_logic;
    err_i     : in  std_logic;
    wd_err_i  : in  std_logic;
    -- MUX select
    gnt_i     : in  std_logic_vector(G_GRANT_WIDTH - 1 downto 0);
    busy_o    : out std_logic
    );
end entity wb_master_mux;

architecture Behavioral of wb_master_mux is
  signal i_selected_master    : integer range 0 to G_WB_MASTER_NUMBER-1;
  signal cyc     : std_logic;
  signal stb     : std_logic;
  signal addr    : std_logic_vector(WB_ADD_WIDTH-1 downto 0);
  signal we      : std_logic;
  signal dat_m2s : std_logic_vector(WB_DATA_WIDTH-1 downto 0);

begin  -- architecture Behavioral
  i_selected_master <= to_integer(unsigned(gnt_i));

  p_m2s : process (clk_i) is
  begin  -- process p_m2s
    if rising_edge(clk_i) then
      if rst_i = '1' then
        cyc_o     <= '0';
        stb_o     <= '0';
        we_o      <= '0';
        addr_o    <= (others => '0');
        dat_m2s_o <= (others => '0');
      else
        cyc_o     <= cyc_i(i_selected_master);
        stb_o     <= stb_i(i_selected_master);
        addr_o    <= addr_i(i_selected_master);
        we_o      <= we_i(i_selected_master);
        dat_m2s_o <= dat_m2s_i(i_selected_master);
      end if;
    end if;
  end process p_m2s;

  p_s2m : process (clk_i) is
  begin  -- process p_s2m
    if rising_edge(clk_i) then
      if rst_i = '1' then
        ack_o     <= (others => '0');
        err_o     <= (others => '0');
        dat_s2m_o <= (others => '0');
      else
        ack_o <= (others => '0');
        err_o <= (others => '0');
        ack_o(i_selected_master)     <= ack_i;
        err_o(i_selected_master)     <= err_i or wd_err_i;
        dat_s2m_o <= dat_s2m_i;
      end if;
    end if;
  end process p_s2m;

  busy_o <= cyc_i(i_selected_master) or ack_i or err_i or wd_err_i;
end architecture Behavioral;
