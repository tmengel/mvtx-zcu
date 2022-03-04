-------------------------------------------------------------------------------
-- Title      : Radiation monitor_wrapper
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : radiation monitor_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-10-21
-- Last update: 2017-10-21
-- Platform   : Vivado 2016.4
-- Target     : Kintex-Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Radiation monitor_wrapper
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.radiation_monitor_pkg.all;
use work.tmr_pkg.all;

entity radiation_monitor_wrapper is
  generic (
    G_MODULE_0_MISMATCH_WIDTH     : integer := 4;
    G_MODULE_1_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_2_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_3_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_4_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_5_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_DUMMY_MISMATCH_WIDTH : integer := 1
    );
  port (
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1);

    MODULE_0_MISMATCH_I     : in std_logic_vector(G_MODULE_0_MISMATCH_WIDTH-1 downto 0);
    MODULE_0_MISMATCH_2ND_I : in std_logic_vector(G_MODULE_0_MISMATCH_WIDTH-1 downto 0);

    MODULE_1_MISMATCH_I     : in std_logic_vector(G_MODULE_1_MISMATCH_WIDTH-1 downto 0);
    MODULE_1_MISMATCH_2ND_I : in std_logic_vector(G_MODULE_1_MISMATCH_WIDTH-1 downto 0);

    MODULE_2_MISMATCH_I     : in std_logic_vector(G_MODULE_2_MISMATCH_WIDTH-1 downto 0);
    MODULE_2_MISMATCH_2ND_I : in std_logic_vector(G_MODULE_2_MISMATCH_WIDTH-1 downto 0);

    MODULE_3_MISMATCH_I     : in std_logic_vector(G_MODULE_3_MISMATCH_WIDTH-1 downto 0);
    MODULE_3_MISMATCH_2ND_I : in std_logic_vector(G_MODULE_3_MISMATCH_WIDTH-1 downto 0);

    MODULE_4_MISMATCH_I     : in std_logic_vector(G_MODULE_4_MISMATCH_WIDTH-1 downto 0);
    MODULE_4_MISMATCH_2ND_I : in std_logic_vector(G_MODULE_4_MISMATCH_WIDTH-1 downto 0);

    MODULE_5_MISMATCH_I     : in std_logic_vector(G_MODULE_5_MISMATCH_WIDTH-1 downto 0);
    MODULE_5_MISMATCH_2ND_I : in std_logic_vector(G_MODULE_5_MISMATCH_WIDTH-1 downto 0)
    );
end entity radiation_monitor_wrapper;

architecture Behavior of radiation_monitor_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i : wbs_i_type;
  signal s_wb_wbs_o : wbs_o_type;

  -- counters
  signal s_module_0_counter, s_module_0_counter_2nd         : t_radmon_cntr_array(G_MODULE_0_MISMATCH_WIDTH-1 downto 0);
  signal s_module_1_counter, s_module_1_counter_2nd         : t_radmon_cntr_array(G_MODULE_1_MISMATCH_WIDTH-1 downto 0);
  signal s_module_2_counter, s_module_2_counter_2nd         : t_radmon_cntr_array(G_MODULE_2_MISMATCH_WIDTH-1 downto 0);
  signal s_module_3_counter, s_module_3_counter_2nd         : t_radmon_cntr_array(G_MODULE_3_MISMATCH_WIDTH-1 downto 0);
  signal s_module_4_counter, s_module_4_counter_2nd         : t_radmon_cntr_array(G_MODULE_4_MISMATCH_WIDTH-1 downto 0);
  signal s_module_5_counter, s_module_5_counter_2nd         : t_radmon_cntr_array(G_MODULE_5_MISMATCH_WIDTH-1 downto 0);
  signal s_module_DUMMY_counter, s_module_DUMMY_counter_2nd : t_radmon_cntr_array(G_MODULE_DUMMY_MISMATCH_WIDTH-1 downto 0);

begin

  radiation_monitor_wishbone_INST : entity work.radiation_monitor_wishbone
    generic map (
      G_MODULE_0_MISMATCH_WIDTH     => G_MODULE_0_MISMATCH_WIDTH,
      G_MODULE_1_MISMATCH_WIDTH     => G_MODULE_1_MISMATCH_WIDTH,
      G_MODULE_2_MISMATCH_WIDTH     => G_MODULE_2_MISMATCH_WIDTH,
      G_MODULE_3_MISMATCH_WIDTH     => G_MODULE_3_MISMATCH_WIDTH,
      G_MODULE_4_MISMATCH_WIDTH     => G_MODULE_4_MISMATCH_WIDTH,
      G_MODULE_5_MISMATCH_WIDTH     => G_MODULE_5_MISMATCH_WIDTH,
      G_MODULE_DUMMY_MISMATCH_WIDTH => G_MODULE_DUMMY_MISMATCH_WIDTH)
    port map (
      WB_CLK                   => WB_CLK,
      WB_RST                   => WB_RST,
      WB_WBS_I                 => s_wb_wbs_i,
      WB_WBS_O                 => s_wb_wbs_o,
      MODULE_0_COUNTER         => s_module_0_counter,
      MODULE_0_COUNTER_2ND     => s_module_0_counter_2nd,
      MODULE_1_COUNTER         => s_module_1_counter,
      MODULE_1_COUNTER_2ND     => s_module_1_counter_2nd,
      MODULE_2_COUNTER         => s_module_2_counter,
      MODULE_2_COUNTER_2ND     => s_module_2_counter_2nd,
      MODULE_3_COUNTER         => s_module_3_counter,
      MODULE_3_COUNTER_2ND     => s_module_3_counter_2nd,
      MODULE_4_COUNTER         => s_module_4_counter,
      MODULE_4_COUNTER_2ND     => s_module_4_counter_2nd,
      MODULE_5_COUNTER         => s_module_5_counter,
      MODULE_5_COUNTER_2ND     => s_module_5_counter_2nd,
      MODULE_DUMMY_COUNTER     => s_module_DUMMY_counter,
      MODULE_DUMMY_COUNTER_2ND => s_module_DUMMY_counter_2nd
      );

  -- implementation with array of WBS inputs
  majority_voter_wbs_i_INST : entity work.majority_voter_wbs_i
    generic map (
      MISMATCH_EN           => 0,
      G_ADDITIONAL_MISMATCH => 0)
    port map (
      ASSERTION_CLK => WB_CLK,
      ASSERTION_RST => WB_RST,
      INPUT         => WB_WBS_I,
      OUTPUT        => s_wb_wbs_i,
      MISMATCH      => open,
      MISMATCH_2ND  => open);

  WB_WBS_O(0) <= s_wb_wbs_o;
  WB_WBS_O(1) <= s_wb_wbs_o;
  WB_WBS_O(2) <= s_wb_wbs_o;

  radiation_monitor_INST : entity work.radiation_monitor
    generic map (
      G_MODULE_0_MISMATCH_WIDTH     => G_MODULE_0_MISMATCH_WIDTH,
      G_MODULE_1_MISMATCH_WIDTH     => G_MODULE_1_MISMATCH_WIDTH,
      G_MODULE_2_MISMATCH_WIDTH     => G_MODULE_2_MISMATCH_WIDTH,
      G_MODULE_3_MISMATCH_WIDTH     => G_MODULE_3_MISMATCH_WIDTH,
      G_MODULE_4_MISMATCH_WIDTH     => G_MODULE_4_MISMATCH_WIDTH,
      G_MODULE_5_MISMATCH_WIDTH     => G_MODULE_5_MISMATCH_WIDTH,
      G_MODULE_DUMMY_MISMATCH_WIDTH => G_MODULE_DUMMY_MISMATCH_WIDTH)
    port map (
      CLK_I                  => WB_CLK,
      RST_I                  => WB_RST,
      MODULE_0_MISMATCH_I    => MODULE_0_MISMATCH_I,
      MODULE_0_COUNTER_O     => s_module_0_counter,
      MODULE_1_MISMATCH_I    => MODULE_1_MISMATCH_I,
      MODULE_1_COUNTER_O     => s_module_1_counter,
      MODULE_2_MISMATCH_I    => MODULE_2_MISMATCH_I,
      MODULE_2_COUNTER_O     => s_module_2_counter,
      MODULE_3_MISMATCH_I    => MODULE_3_MISMATCH_I,
      MODULE_3_COUNTER_O     => s_module_3_counter,
      MODULE_4_MISMATCH_I    => MODULE_4_MISMATCH_I,
      MODULE_4_COUNTER_O     => s_module_4_counter,
      MODULE_5_MISMATCH_I    => MODULE_5_MISMATCH_I,
      MODULE_5_COUNTER_O     => s_module_5_counter,
      MODULE_DUMMY_COUNTER_O => s_module_DUMMY_counter
      );

  radiation_monitor_2ND_INST : entity work.radiation_monitor
    generic map (
      G_MODULE_0_MISMATCH_WIDTH     => G_MODULE_0_MISMATCH_WIDTH,
      G_MODULE_1_MISMATCH_WIDTH     => G_MODULE_1_MISMATCH_WIDTH,
      G_MODULE_2_MISMATCH_WIDTH     => G_MODULE_2_MISMATCH_WIDTH,
      G_MODULE_3_MISMATCH_WIDTH     => G_MODULE_3_MISMATCH_WIDTH,
      G_MODULE_4_MISMATCH_WIDTH     => G_MODULE_4_MISMATCH_WIDTH,
      G_MODULE_5_MISMATCH_WIDTH     => G_MODULE_5_MISMATCH_WIDTH,
      G_MODULE_DUMMY_MISMATCH_WIDTH => G_MODULE_DUMMY_MISMATCH_WIDTH)
    port map (
      CLK_I                  => WB_CLK,
      RST_I                  => WB_RST,
      MODULE_0_MISMATCH_I    => MODULE_0_MISMATCH_2ND_I,
      MODULE_0_COUNTER_O     => s_module_0_counter_2nd,
      MODULE_1_MISMATCH_I    => MODULE_1_MISMATCH_2ND_I,
      MODULE_1_COUNTER_O     => s_module_1_counter_2nd,
      MODULE_2_MISMATCH_I    => MODULE_2_MISMATCH_2ND_I,
      MODULE_2_COUNTER_O     => s_module_2_counter_2nd,
      MODULE_3_MISMATCH_I    => MODULE_3_MISMATCH_2ND_I,
      MODULE_3_COUNTER_O     => s_module_3_counter_2nd,
      MODULE_4_MISMATCH_I    => MODULE_4_MISMATCH_2ND_I,
      MODULE_4_COUNTER_O     => s_module_4_counter_2nd,
      MODULE_5_MISMATCH_I    => MODULE_5_MISMATCH_2ND_I,
      MODULE_5_COUNTER_O     => s_module_5_counter_2nd,
      MODULE_DUMMY_COUNTER_O => s_module_DUMMY_counter_2nd
      );

end architecture Behavior;
