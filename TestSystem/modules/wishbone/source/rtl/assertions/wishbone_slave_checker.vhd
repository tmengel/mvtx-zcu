-------------------------------------------------------------------------------
-- Title      : Wishbone Slave checker module
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : wishbone_slave_checker.vhd
-- Author     : Matthias Bonora  <matthias.bonora@cern.ch>
-- Company    : CERN / University of Salzburg
-- Created    : 2017-02-22
-- Last update: 2017-07-26
-- Platform   : CERN OS7, Xilinx Vivado 2015.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-02-22  1.0      mbonora	Created
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.intercon_pkg.all;

entity wishbone_slave_checker is
  generic(
    NR_ADDRESSES : integer := 0);
  port(
    WB_CLK   : in std_logic;
    WB_RST   : in std_logic;
    WB_WBS_I : in wbs_i_type;
    WB_WBS_O : in wbs_o_type);
end entity wishbone_slave_checker;

architecture bhv of wishbone_slave_checker is
  component wishbone_slave_checker_sv is
    generic(
      NR_ADDRESSES : integer);
    port(
      wb_clk : in std_logic;
      wb_rst : in std_logic;
      dat_i  : in std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
      we_i   : in std_logic;
      addr_i : in std_logic_vector(WB_ADDS_WIDTH - 1 downto 0);
      cyc_i  : in std_logic;
      stb_i  : in std_logic;
      dat_o  : in std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
      err_o  : in std_logic;
      ack_o  : in std_logic);
  end component wishbone_slave_checker_sv;
begin                                   -- architecture bhv

  wishbone_slave_checker_sv_INST : wishbone_slave_checker_sv
    generic map(
      NR_ADDRESSES => NR_ADDRESSES)
    port map(
      wb_clk => WB_CLK,
      wb_rst => WB_RST,
      dat_i  => WB_WBS_I.dat_i,
      we_i   => WB_WBS_I.we_i,
      addr_i => WB_WBS_I.addr_i,
      cyc_i  => WB_WBS_I.cyc_i,
      stb_i  => WB_WBS_I.stb_i,
      dat_o  => WB_WBS_O.dat_o,
      err_o  => WB_WBS_O.err_o,
      ack_o  => WB_WBS_O.ack_o
    );

end architecture bhv;
