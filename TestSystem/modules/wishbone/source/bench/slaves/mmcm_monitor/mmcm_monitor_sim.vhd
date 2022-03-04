-------------------------------------------------------------------------------
-- Title      : mmcm_monitor_sim
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mmcm_monitor_sim.vhd
-- Author     : Matteo Lupi (matteo.lupi@cern.ch)
-- Company    : Goethe Universitaet Frankfurt am Main / CERN
-- Created    : 2017-11-16
-- Last update: 2018-03-23
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-Utrascale
-------------------------------------------------------------------------------
-- Description: mmcm_monitor, simulation model
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.xpm_cdc_components_pkg.all;

architecture behav of mmcm_monitor is

  component mmcm_monitor_single_clock is
    generic (
      READ_BIT_WIDTH             : integer;
      BIT_WIDTH                  : integer;
      IS_SATURATING              : integer;
      VERBOSE                    : integer;
      G_SEE_MITIGATION_TECHNIQUE : integer;
      G_MISMATCH_EN              : integer;
      G_MISMATCH_REGISTERED      : integer;
      G_ADDITIONAL_MISMATCH      : integer;
      G_K_TMR                    : integer
      );
    port (
      clkcnt_i                  : in  std_logic;
      rst_clkcnt_i              : in  std_logic;
      clkread_i                 : in  std_logic;
      rst_clkread_i             : in  std_logic;
      latch_counter_clkread_i   : in  std_logic_vector(G_K_TMR-1 downto 0);
      reset_counter_clkread_i   : in  std_logic_vector(G_K_TMR-1 downto 0);
      counter_value_clkread_a_o : out std_logic_vector(READ_BIT_WIDTH-1 downto 0);
      counter_value_clkread_b_o : out std_logic_vector(READ_BIT_WIDTH-1 downto 0);
      counter_value_clkread_c_o : out std_logic_vector(READ_BIT_WIDTH-1 downto 0);
      mismatch_clkread_o        : out std_logic_vector(G_K_TMR-1 downto 0);
      mismatch_2nd_clkread_o    : out std_logic_vector(G_K_TMR-1 downto 0)
      );
  end component;

  signal s_locked         : std_logic;
  signal s_user_clock_out : std_logic_vector(C_USER_CLOCK_NUMBER-1 downto 0);

  signal s_counter_latch : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
  signal s_counter_reset : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
  signal s_counter_array : t_clk_counters_array;
  signal s_startup_reset : std_logic_vector(C_USER_CLOCK_NUMBER-1 downto 0);

  signal s_lock_counter_latch, s_lock_counter_reset : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_lock_counter                             : std_logic_vector(WB_DATA_WIDTH-1 downto 0);

  signal s_mismatch_array     : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0);
  signal s_mismatch_2nd_array : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0);
begin

  s_counter_array <= (others => (others => '0'));
  s_lock_counter <= (others => '0');
  s_mismatch_array <= (others => '0');
  s_mismatch_2nd_array <= (others => '0');

  mmcm_monitor_dut_INST : entity work.mmcm_monitor_dut(behav)
    generic map (
      G_USER_CLOCK_NUMBER => C_USER_CLOCK_NUMBER,
      G_CLKFBOUT_MULT_F   => G_CLKFBOUT_MULT_F)
    port map (
      CLK_IN       => MMCM_CLK_IN,
      RESET        => RESET,
      WB_CLK       => WB_CLK,
      LOCKED       => s_locked,
      USER_CLK_OUT => s_user_clock_out);

  mmcm_monitor_wishbone_tmr_wrapper_INST : entity work.mmcm_monitor_wishbone_tmr_wrapper
    generic map (
      G_SEE_MITIGATION_TECHNIQUE => 1,
      G_MISMATCH_EN              => 0,
      G_ADDITIONAL_MISMATCH      => 0)
    port map (
      WB_CLK             => WB_CLK,
      WB_RST             => WB_RST,
      WB_WBS_I           => WB_WBS_I,
      WB_WBS_O           => WB_WBS_O,
      COUNTER_LATCH      => s_counter_latch,
      COUNTER_RESET      => s_counter_reset,
      LOCK_COUNTER_LATCH => s_lock_counter_latch,
      LOCK_COUNTER_RESET => s_lock_counter_reset,
      COUNTER_ARRAY      => s_counter_array,
      LOCK_COUNTER       => s_lock_counter,
      MISMATCH_ARRAY     => s_mismatch_array,
      MISMATCH_2ND_ARRAY => s_mismatch_2nd_array);

end behav;
