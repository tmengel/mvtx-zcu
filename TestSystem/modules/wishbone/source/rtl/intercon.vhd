-------------------------------------------------------------------------------
-- Title      : intercon
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : intercon.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-02-26
-- Last update: 2017-11-14
-- Platform   : Vivado 2015.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Intercon entity (wishbone bus)
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-02-26  1.0      mlupi   Imported from wishbone_pkg.vhd where is has
--                              been removed
-- 2016-02-29  1.1      ML      Reordering of signals to ease adding wb slaves
-- 2016-02-29           ML      Added 3rd slave
-- 2015-03-02           ML      Added 4th slave for debug purposes
-- 2015-03-08           ML      Slaves starting from 0
-- 2015-07-05  2.0      ML      Parametrization of number of slaves
-- 2016-07-21  2.1      ML      git rebase
-- 2017-03-09  3.0      ML      intercon split into intercon_core and watchdog
--                              to allow triplication
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.intercon_pkg.all;

entity intercon is
  generic (
    G_WB_SLAVE_NUMBER : natural := 8); -- defined to avoid package entanglement
  port (
    -- wishbone master port(s)
    -- wbm1
    wbm1_wbm_i : out wbm_i_type;
    wbm1_wbm_o : in  wbm_o_type;
    -- wbm2
    wbm2_wbm_i : out wbm_i_type;
    wbm2_wbm_o : in  wbm_o_type;
    -- wishbone slave port(s)
    wbs_wbs_i  : out t_wbs_i_array(0 to G_WB_SLAVE_NUMBER-1);
    wbs_wbs_o  : in  t_wbs_o_array(0 to G_WB_SLAVE_NUMBER-1);
    -- clock and reset
    clk        : in  std_logic;
    reset      : in  std_logic
    );
end intercon;

architecture rtl of intercon is

  signal s_wd_stb, s_wd_cyc, s_wd_err : std_logic;

  component watchdog is
    generic (
      TIMEOUT_BIT_WIDTH : integer);
    port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      stb_i     : in  std_logic;
      cyc_i     : in  std_logic;
      err_o     : out std_logic;
      timeout_i : in std_logic_vector(TIMEOUT_BIT_WIDTH-1 downto 0));
  end component watchdog;

begin  -- rtl

  intercon_core_INST: entity work.intercon_core
    generic map (
      G_WB_SLAVE_NUMBER => G_WB_SLAVE_NUMBER)
    port map (
      wbm1_wbm_i => wbm1_wbm_i,
      wbm1_wbm_o => wbm1_wbm_o,
      wbm2_wbm_i => wbm2_wbm_i,
      wbm2_wbm_o => wbm2_wbm_o,
      wbs_wbs_i  => wbs_wbs_i,
      wbs_wbs_o  => wbs_wbs_o,
      clk        => clk,
      reset      => reset,
      wd_stb     => s_wd_stb,
      wd_cyc     => s_wd_cyc,
      wd_err     => s_wd_err);

  INST_watchdog: watchdog
    generic map (
      TIMEOUT_BIT_WIDTH => c_WD_TIMEOUT_WIDTH)
    port map (
      clk_i     => clk,
      rst_i     => reset,
      stb_i     => s_wd_stb,
      cyc_i     => s_wd_cyc,
      err_o     => s_wd_err,
      timeout_i => c_WD_TIMEOUT);

end rtl;
