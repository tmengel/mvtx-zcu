-------------------------------------------------------------------------------
-- Title      : MGT Example Wrapper
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mgt_example_wrapper.vhd
-- Author     : Joachim Schambach  <jschamba@pisces.rhip.utexas.edu>
-- Company    : University of Texas at Austin
-- Created    : 2018-06-06
-- Last update: 2018-06-07
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for mgt_example and wishbone controller
-------------------------------------------------------------------------------
-- Copyright (c) 2018 University of Texas at Austin
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018-06-06  1.0      jschamba  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.mgt_example_pkg.all;
use work.drp_pkg.all;

entity mgt_example_wrapper is
  port (
    -- wishbone
    WB_CLK             : in  std_logic;
    WB_RST             : in  std_logic;
    MGT_WB_WBS_I       : in  wbs_i_type;
    MGT_WB_WBS_O       : out wbs_o_type;
    DRP_WB_WBS_I       : in  wbs_i_type;
    DRP_WB_WBS_O       : out wbs_o_type;
    -- MGT example interfaces
    mgtrefclk1_x0y4_dp : in  std_logic;
    mgtrefclk1_x0y4_dn : in  std_logic;
    mgtrefclk1_x1y2_dp : in  std_logic;
    mgtrefclk1_x1y2_dn : in  std_logic;
    gthrx_dp           : in  std_logic_vector(27 downto 0);
    gthrx_dn           : in  std_logic_vector(27 downto 0);
    clk150             : in  std_logic;
    clk600             : in  std_logic;
    clk75              : in  std_logic;
    gpio               : out std_logic_vector(27 downto 0)
    );

end entity mgt_example_wrapper;

architecture rtl of mgt_example_wrapper is

  constant C_STATE_BITSIZE : integer  := 3;
  constant NR_LANES        : positive := 28;

  component mgt_example_top is
    port (
      mgtrefclk1_x0y4_p         : in  std_logic;
      mgtrefclk1_x0y4_n         : in  std_logic;
      mgtrefclk1_x1y2_p         : in  std_logic;
      mgtrefclk1_x1y2_n         : in  std_logic;
      gthrxn_in                 : in  std_logic_vector(27 downto 0);
      gthrxp_in                 : in  std_logic_vector(27 downto 0);
      gthtxn_out                : out std_logic_vector(27 downto 0);
      gthtxp_out                : out std_logic_vector(27 downto 0);
      clk150                    : in  std_logic;
      clk600                    : in  std_logic;
      clk75                     : in  std_logic;
      gpout                     : out std_logic_vector(27 downto 0);
      drpaddr_in                : in  std_logic_vector(251 downto 0);
      drpclk_in                 : in  std_logic_vector(27 downto 0);
      drpdi_in                  : in  std_logic_vector(447 downto 0);
      drpen_in                  : in  std_logic_vector(27 downto 0);
      drpwe_in                  : in  std_logic_vector(27 downto 0);
      drpdo_out                 : out std_logic_vector(447 downto 0);
      drprdy_out                : out std_logic_vector(27 downto 0);
      enable_error_in           : in  std_logic;
      force_error               : in  std_logic;
      link_down_latched_rst     : in  std_logic;
      reset_all                 : in  std_logic;
      reset_rx_pll_and_datapath : in  std_logic;
      reset_rx_datapath         : in  std_logic;
      rxprbssel                 : in  std_logic_vector(111 downto 0);
      rxprbscntreset            : in  std_logic_vector(27 downto 0);
      init_done                 : out std_logic;
      init_retry_ctr            : out std_logic_vector(3 downto 0);
      gtpowergood               : out std_logic_vector(27 downto 0);
      rxpmaresetdone            : out std_logic_vector(27 downto 0);
      reset_rx_done             : out std_logic;
      rxprbslocked              : out std_logic_vector(27 downto 0);
      rxprbserr                 : out std_logic_vector(27 downto 0);
      link_status_out           : out std_logic;
      link_down_latched_out     : out std_logic
      );
  end component mgt_example_top;

  signal s_wishbone_registers_i : t_wishbone_registers_i;
  signal s_wishbone_registers_o : t_wishbone_registers_o;
  signal s_drpaddr              : std_logic_vector(251 downto 0) := (others => '0');
  signal s_drpclk               : std_logic_vector(27 downto 0)  := (others => '0');
  signal s_drpdi                : std_logic_vector(447 downto 0) := (others => '0');
  signal s_drpen                : std_logic_vector(27 downto 0)  := (others => '0');
  signal s_drpwe                : std_logic_vector(27 downto 0)  := (others => '0');
  signal s_drpdo                : std_logic_vector(447 downto 0) := (others => '0');
  signal s_drprdy               : std_logic_vector(27 downto 0)  := (others => '0');

  signal sStateFb   : std_logic_vector(C_STATE_BITSIZE-1 downto 0);
  signal s_DRP_DCLK : std_logic;
  signal s_DRP_MOSI : drp_mosi_type;
  signal s_DRP_MISO : drp_miso_type;
  signal s_DRP_LANE : std_logic_vector (DRP_LANE_WIDTH-1 downto 0);


begin  -- architecture rtl

  INST_mgt_example_top : mgt_example_top
    port map (
      mgtrefclk1_x0y4_p         => mgtrefclk1_x0y4_dp,
      mgtrefclk1_x0y4_n         => mgtrefclk1_x0y4_dn,
      mgtrefclk1_x1y2_p         => mgtrefclk1_x1y2_dp,
      mgtrefclk1_x1y2_n         => mgtrefclk1_x1y2_dn,
      gthrxn_in                 => gthrx_dn,
      gthrxp_in                 => gthrx_dp,
      gthtxn_out                => open,
      gthtxp_out                => open,
      clk150                    => clk150,
      clk600                    => clk600,
      clk75                     => clk75,
      gpout                     => gpio,
      drpaddr_in                => s_drpaddr,
      drpclk_in                 => s_drpclk,
      drpdi_in                  => s_drpdi,
      drpen_in                  => s_drpen,
      drpwe_in                  => s_drpwe,
      drpdo_out                 => s_drpdo,
      drprdy_out                => s_drprdy,
      enable_error_in           => s_wishbone_registers_o.enable_err,
      force_error               => s_wishbone_registers_o.resets(4),
      link_down_latched_rst     => s_wishbone_registers_o.resets(3),
      reset_all                 => s_wishbone_registers_o.resets(0),
      reset_rx_pll_and_datapath => s_wishbone_registers_o.resets(1),
      reset_rx_datapath         => s_wishbone_registers_o.resets(2),
      rxprbssel                 => s_wishbone_registers_o.prbssel,
      rxprbscntreset            => s_wishbone_registers_o.prbs_ctr_reset,
      init_done                 => s_wishbone_registers_i.status(0),
      init_retry_ctr            => s_wishbone_registers_i.init_retry_ctr,
      gtpowergood               => s_wishbone_registers_i.powergood,
      rxpmaresetdone            => s_wishbone_registers_i.pmareset_done,
      reset_rx_done             => s_wishbone_registers_i.status(1),
      rxprbslocked              => s_wishbone_registers_i.prbs_locked,
      rxprbserr                 => s_wishbone_registers_i.prbs_err,
      link_status_out           => s_wishbone_registers_i.status(2),
      link_down_latched_out     => s_wishbone_registers_i.status(3)
      );

  INST_mgt_example_wishbone : entity work.mgt_example_wishbone
    port map (
      WB_CLK           => WB_CLK,
      WB_RST           => WB_RST,
      WB_WBS_I         => MGT_WB_WBS_I,
      WB_WBS_O         => MGT_WB_WBS_O,
      WB_REGISTERS_in  => s_wishbone_registers_i,
      WB_REGISTERS_out => s_wishbone_registers_o
      );

  INST_wishbone_drp_bridge : entity work.wishbone_drp_bridge
    generic map (
      G_STATE_BITSIZE => C_STATE_BITSIZE)
    port map (
      WB_CLK       => WB_CLK,
      WB_RST       => WB_RST,
      WB_WBS_I     => DRP_WB_WBS_I,
      WB_WBS_O     => DRP_WB_WBS_O,
      DRP_DCLK     => s_DRP_DCLK,
      DRP_MOSI     => s_DRP_MOSI,
      DRP_MISO     => s_DRP_MISO,
      DRP_LANE     => s_DRP_LANE,
      STATE_I      => sStateFb,
      STATE_O      => sStateFb,
      MISMATCH     => '0',
      MISMATCH_2ND => '0'
      );

  -- DRP block
  DRP_signals : block is
  begin  -- block DRP_signals

    connect_drp_sigs : for i in 0 to NR_LANES-1 generate
      s_drpclk(i)                  <= s_DRP_DCLK;
      s_drpaddr(i*9+8 downto i*9)  <= s_DRP_MOSI.addr;
      s_drpdi(i*16+15 downto i*16) <= s_DRP_MOSI.di;
      s_drpwe(i)                   <= s_DRP_MOSI.dwe;
    end generate connect_drp_sigs;

    DRP_enable : process (s_DRP_LANE, s_DRP_MOSI.den) is
    begin  -- process DRP_enable
      s_drpen <= (others => '0');
      if unsigned(s_DRP_LANE) < to_unsigned(NR_LANES, 5) then
        s_drpen(to_integer(unsigned(s_DRP_LANE))) <= s_DRP_MOSI.den;
      end if;
    end process DRP_enable;

    DRP_return : process (s_DRP_LANE, s_drpdo, s_drprdy) is
      variable lane_idx : natural range 0 to 2**s_DRP_LANE'length-1;
    begin  -- process DRP_return
      s_DRP_MISO.drdy <= '0';
      s_DRP_MISO.do   <= (others => '0');

      if unsigned(s_DRP_LANE) < to_unsigned(NR_LANES, 5) then
        lane_idx        := to_integer(unsigned(s_DRP_LANE));
        s_DRP_MISO.do   <= s_drpdo(lane_idx*16+15 downto lane_idx*16);
        s_DRP_MISO.drdy <= s_drprdy(lane_idx);
      end if;
    end process DRP_return;
  end block DRP_signals;

end architecture rtl;
