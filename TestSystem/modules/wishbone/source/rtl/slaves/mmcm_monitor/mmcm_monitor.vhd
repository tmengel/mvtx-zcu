-------------------------------------------------------------------------------
-- Title      : mmcm_monitor
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mmcm_monitor.vhd
-- Author     : Matteo Lupi (matteo.lupi@cern.ch)
-- Company    : Goethe Universitaet Frankfurt am Main / CERN
-- Created    : 2017-11-16
-- Last update: 2017-11-22
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-Utrascale
-------------------------------------------------------------------------------
-- Description: DUT for mmcm testing in beam
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.intercon_pkg.all;
use work.mmcm_monitor_pkg.all;
use work.tmr_pkg.all;
use work.xpm_cdc_components_pkg.all;

entity mmcm_monitor is
  generic (
    G_CLKFBOUT_MULT_F : real := 6.250  -- 6.250 for 83.33 MHz and 6 for 80.00 MHz
    );
  port (
    MMCM_CLK_IN : in  std_logic;
    RESET       : in  std_logic;
    WB_CLK      : in  std_logic;
    WB_RST      : in  std_logic;
    WB_WBS_I    : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O    : out t_wbs_o_array(0 to C_K_TMR-1)
    );
end entity mmcm_monitor;
-------------------------------------------------------------------------------
-- Beginning of the Architecture
-------------------------------------------------------------------------------
architecture struct of mmcm_monitor is

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

  signal s_locked, s_locked_wb_clk : std_logic;
  signal s_user_clock_out          : std_logic_vector(C_USER_CLOCK_NUMBER-1 downto 0);

  signal s_counter_latch : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
  signal s_counter_reset : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
  signal s_counter_array : t_clk_counters_array;
  signal s_startup_reset : std_logic_vector(C_USER_CLOCK_NUMBER-1 downto 0);

  signal s_lock_counter_latch, s_lock_counter_reset : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_lock_counter                             : std_logic_vector(WB_DATA_WIDTH-1 downto 0);

  signal s_mismatch_array     : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0);
  signal s_mismatch_2nd_array : std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0);
begin

  mmcm_monitor_dut_INST : entity work.mmcm_monitor_dut
    generic map (
      G_USER_CLOCK_NUMBER => C_USER_CLOCK_NUMBER,
      G_CLKFBOUT_MULT_F   => G_CLKFBOUT_MULT_F)
    port map (
      CLK_IN       => MMCM_CLK_IN,
      RESET        => RESET,
      WB_CLK       => WB_CLK,
      LOCKED       => s_locked,
      USER_CLK_OUT => s_user_clock_out);

  for_clock_generate : for clock_i in 0 to C_USER_CLOCK_NUMBER-1 generate
    mmcm_monitor_single_clock_INST : mmcm_monitor_single_clock
      generic map (
        READ_BIT_WIDTH             => WB_DATA_WIDTH,
        BIT_WIDTH                  => C_COUNTER_BIT_WIDTH,
        IS_SATURATING              => 0,
        VERBOSE                    => 0,
        G_SEE_MITIGATION_TECHNIQUE => 1,
        G_MISMATCH_EN              => 1,
        G_MISMATCH_REGISTERED      => 0,
        G_ADDITIONAL_MISMATCH      => 1,
        G_K_TMR                    => C_K_TMR
        )
      port map (
        clkcnt_i                  => s_user_clock_out(clock_i),
        rst_clkcnt_i              => s_startup_reset(clock_i),
        clkread_i                 => WB_CLK,
        rst_clkread_i             => WB_RST,
        latch_counter_clkread_i   => s_counter_latch(clock_i*C_K_TMR + C_K_TMR-1 downto clock_i*C_K_TMR),
        reset_counter_clkread_i   => s_counter_reset(clock_i*C_K_TMR + C_K_TMR-1 downto clock_i*C_K_TMR),
        counter_value_clkread_a_o => s_counter_array(clock_i*C_K_TMR + 0),
        counter_value_clkread_b_o => s_counter_array(clock_i*C_K_TMR + 1),
        counter_value_clkread_c_o => s_counter_array(clock_i*C_K_TMR + 2),
        mismatch_clkread_o        => s_mismatch_array(clock_i*C_K_TMR + C_K_TMR-1 downto clock_i*C_K_TMR),
        mismatch_2nd_clkread_o    => s_mismatch_2nd_array(clock_i*C_K_TMR + C_K_TMR-1 downto clock_i*C_K_TMR)
        );

    -- use a 16bit shift register look-up table to generate a pulse that is
    -- logic-high for 16 clocks and then goes low
    -- the 4 "Ax" inputs determine the size of the shift register (= 16 bits)
    INST_SRL16E_16b : SRL16E
      generic map (
        INIT => X"FFFF"                    -- initialization value
        )
      port map (
        Q   => s_startup_reset(clock_i),   -- SRL data output
        A0  => '1',                        -- Select[0] input
        A1  => '1',                        -- Select[1] input
        A2  => '1',                        -- Select[2] input
        A3  => '1',                        -- Select[3] input
        CE  => s_locked,                   -- Clock enable input
        CLK => s_user_clock_out(clock_i),  -- Clock input
        D   => '0'                         -- SRL data input
        );
  end generate for_clock_generate;

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

  lock_monitor_tmr_wrapper_INST : entity work.lock_monitor_tmr_wrapper
    generic map (
      IS_SATURATING              => 0,
      VERBOSE                    => 0,
      G_SEE_MITIGATION_TECHNIQUE => 1,
      G_MISMATCH_EN              => 0,
      G_MISMATCH_REGISTERED      => 0,
      G_ADDITIONAL_MISMATCH      => 0)
    port map (
      clk_i           => WB_CLK,
      rst_i           => WB_RST,
      monitored_i     => s_locked_wb_clk,
      latch_counter_i => s_lock_counter_latch,
      reset_counter_i => s_lock_counter_reset,
      counter_value_o => s_lock_counter);

  -----------------------------------------------------------------------------
  -- locked xpm
  -----------------------------------------------------------------------------

  xpm_cdc_single_lock_INST : xpm_cdc_single
    generic map (
      DEST_SYNC_FF   => 2,          -- integer; range: 2-10
      SIM_ASSERT_CHK => 0,  -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 0  -- integer; 0=do not register input, 1=register input
      )
    port map (
      src_clk  => '1',   -- optional; required when SRC_INPUT_REG = 1
      src_in   => s_locked,
      dest_clk => WB_CLK,
      dest_out => s_locked_wb_clk
      );

end architecture struct;
