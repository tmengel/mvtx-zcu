-------------------------------------------------------------------------------
-- Title      : Radiation monitor
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : radiation monitor.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-10-21
-- Last update: 2017-11-02
-- Platform   : Vivado 2016.4
-- Target     : Kintex-Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Radiation monitor
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.radiation_monitor_pkg.all;

entity radiation_monitor is
  generic (
    G_MODULE_0_MISMATCH_WIDTH     : integer := 4;
    G_MODULE_1_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_2_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_3_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_4_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_5_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_DUMMY_MISMATCH_WIDTH : integer := 6
    );
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    MODULE_0_MISMATCH_I : in  std_logic_vector(G_MODULE_0_MISMATCH_WIDTH-1 downto 0);
    MODULE_0_COUNTER_O  : out t_radmon_cntr_array(G_MODULE_0_MISMATCH_WIDTH-1 downto 0);

    MODULE_1_MISMATCH_I : in  std_logic_vector(G_MODULE_1_MISMATCH_WIDTH-1 downto 0);
    MODULE_1_COUNTER_O  : out t_radmon_cntr_array(G_MODULE_1_MISMATCH_WIDTH-1 downto 0);

    MODULE_2_MISMATCH_I : in  std_logic_vector(G_MODULE_2_MISMATCH_WIDTH-1 downto 0);
    MODULE_2_COUNTER_O  : out t_radmon_cntr_array(G_MODULE_2_MISMATCH_WIDTH-1 downto 0);

    MODULE_3_MISMATCH_I : in  std_logic_vector(G_MODULE_3_MISMATCH_WIDTH-1 downto 0);
    MODULE_3_COUNTER_O  : out t_radmon_cntr_array(G_MODULE_3_MISMATCH_WIDTH-1 downto 0);

    MODULE_4_MISMATCH_I : in  std_logic_vector(G_MODULE_4_MISMATCH_WIDTH-1 downto 0);
    MODULE_4_COUNTER_O  : out t_radmon_cntr_array(G_MODULE_4_MISMATCH_WIDTH-1 downto 0);

    MODULE_5_MISMATCH_I : in  std_logic_vector(G_MODULE_5_MISMATCH_WIDTH-1 downto 0);
    MODULE_5_COUNTER_O  : out t_radmon_cntr_array(G_MODULE_5_MISMATCH_WIDTH-1 downto 0);

    MODULE_DUMMY_COUNTER_O : out t_radmon_cntr_array(G_MODULE_DUMMY_MISMATCH_WIDTH-1 downto 0)
    );
end entity radiation_monitor;

architecture Behavior of radiation_monitor is

  signal s_dummy_mismatch : std_logic;

begin

  radiation_monitor_single_module_0_INST : entity work.radiation_monitor_single_module
    generic map (
      G_MODULE_MISMATCH_WIDTH => G_MODULE_0_MISMATCH_WIDTH,
      G_COUNTER_IS_SATURATING => 0)
    port map (
      CLK_I      => CLK_I,
      RST_I      => RST_I,
      MISMATCH_I => MODULE_0_MISMATCH_I,
      COUNTER_O  => MODULE_0_COUNTER_O);

  radiation_monitor_single_module_1_INST : entity work.radiation_monitor_single_module
    generic map (
      G_MODULE_MISMATCH_WIDTH => G_MODULE_1_MISMATCH_WIDTH,
      G_COUNTER_IS_SATURATING => 0)
    port map (
      CLK_I      => CLK_I,
      RST_I      => RST_I,
      MISMATCH_I => MODULE_1_MISMATCH_I,
      COUNTER_O  => MODULE_1_COUNTER_O);

  radiation_monitor_single_module_2_INST : entity work.radiation_monitor_single_module
    generic map (
      G_MODULE_MISMATCH_WIDTH => G_MODULE_2_MISMATCH_WIDTH,
      G_COUNTER_IS_SATURATING => 0)
    port map (
      CLK_I      => CLK_I,
      RST_I      => RST_I,
      MISMATCH_I => MODULE_2_MISMATCH_I,
      COUNTER_O  => MODULE_2_COUNTER_O);

  radiation_monitor_single_module_3_INST : entity work.radiation_monitor_single_module
    generic map (
      G_MODULE_MISMATCH_WIDTH => G_MODULE_3_MISMATCH_WIDTH,
      G_COUNTER_IS_SATURATING => 0)
    port map (
      CLK_I      => CLK_I,
      RST_I      => RST_I,
      MISMATCH_I => MODULE_3_MISMATCH_I,
      COUNTER_O  => MODULE_3_COUNTER_O);

  radiation_monitor_single_module_4_INST : entity work.radiation_monitor_single_module
    generic map (
      G_MODULE_MISMATCH_WIDTH => G_MODULE_4_MISMATCH_WIDTH,
      G_COUNTER_IS_SATURATING => 0)
    port map (
      CLK_I      => CLK_I,
      RST_I      => RST_I,
      MISMATCH_I => MODULE_4_MISMATCH_I,
      COUNTER_O  => MODULE_4_COUNTER_O);

  radiation_monitor_single_module_5_INST : entity work.radiation_monitor_single_module
    generic map (
      G_MODULE_MISMATCH_WIDTH => G_MODULE_5_MISMATCH_WIDTH,
      G_COUNTER_IS_SATURATING => 0)
    port map (
      CLK_I      => CLK_I,
      RST_I      => RST_I,
      MISMATCH_I => MODULE_5_MISMATCH_I,
      COUNTER_O  => MODULE_5_COUNTER_O);

  radiation_monitor_single_module_DUMMY_INST : entity work.radiation_monitor_single_module
    generic map (
      G_MODULE_MISMATCH_WIDTH => G_MODULE_DUMMY_MISMATCH_WIDTH,
      G_COUNTER_IS_SATURATING => 0)
    port map (
      CLK_I         => CLK_I,
      RST_I         => RST_I,
      MISMATCH_I(0) => s_dummy_mismatch,
      COUNTER_O     => MODULE_DUMMY_COUNTER_O);

  -- purpose: <[description]>
  p_dummy_mismatch : process (CLK_I) is
    variable v_dummy_mismatch : unsigned(7 downto 0);
  begin  -- process p_dummy_mismatch
    if rising_edge(CLK_I) then          -- rising clock edge
      if RST_I = '1' then               -- synchronous reset (active high)
        v_dummy_mismatch := (others => '0');
        s_dummy_mismatch <= '0';
      else
        v_dummy_mismatch := v_dummy_mismatch + 1;
        s_dummy_mismatch <= v_dummy_mismatch(v_dummy_mismatch'length - 1) and v_dummy_mismatch(v_dummy_mismatch'length - 2);
      end if;
    end if;
  end process p_dummy_mismatch;

end architecture Behavior;
