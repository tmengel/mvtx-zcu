-------------------------------------------------------------------------------
-- Title      : mmcm_monitor_wishbone_tmr_wrapper
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : mmcm_monitor_wishbone_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-25
-- Last update: 2017-11-20
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the mmcm_monitor_wishbone module.
--
--              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
--              protected:
--                      0: no mitigation
--                      1: TMR with single voter
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.mmcm_monitor_pkg.all;
use work.tmr_pkg.all;

entity mmcm_monitor_wishbone_tmr_wrapper is
  generic (
    G_SEE_MITIGATION_TECHNIQUE : integer := 1;
    G_MISMATCH_EN              : integer := 0;
    G_ADDITIONAL_MISMATCH      : integer := 0);
  port (
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1);

    COUNTER_LATCH      : out std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
    COUNTER_RESET      : out std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
    LOCK_COUNTER_LATCH : out std_logic_vector(C_K_TMR-1 downto 0);
    LOCK_COUNTER_RESET : out std_logic_vector(C_K_TMR-1 downto 0);
    COUNTER_ARRAY      : in  t_clk_counters_array;
    LOCK_COUNTER       : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    MISMATCH_ARRAY     : in  std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0);
    MISMATCH_2ND_ARRAY : in  std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0));
  attribute DONT_TOUCH                                      : string;
  attribute DONT_TOUCH of mmcm_monitor_wishbone_tmr_wrapper : entity is "true";
end entity mmcm_monitor_wishbone_tmr_wrapper;

architecture structural of mmcm_monitor_wishbone_tmr_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i                                 : wbs_i_type;
  signal s_wb_wbs_o                                 : wbs_o_type;
  signal s_lock_counter_latch, s_lock_counter_reset : std_logic;

begin  -- architecture structural

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    mmcm_monitor_wishbone_INST : entity work.mmcm_monitor_wishbone
      port map (
        WB_CLK             => WB_CLK,
        WB_RST             => WB_RST,
        WB_WBS_I           => s_wb_wbs_i,
        WB_WBS_O           => s_wb_wbs_o,
        COUNTER_LATCH      => COUNTER_LATCH,
        COUNTER_RESET      => COUNTER_RESET,
        LOCK_COUNTER_LATCH => s_lock_counter_latch,
        LOCK_COUNTER_RESET => s_lock_counter_reset,
        COUNTER_ARRAY      => COUNTER_ARRAY,
        LOCK_COUNTER       => LOCK_COUNTER,
        MISMATCH_ARRAY     => MISMATCH_ARRAY,
        MISMATCH_2ND_ARRAY => MISMATCH_2ND_ARRAY);

    -- implementation with array of WBS inputs
    INST_majority_voter_wbs_i : entity work.majority_voter_wbs_i
      generic map (
        --MISMATCH_EN           => MISMATCH_EN, -- temporary, remove after slave is protected
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
    for_output_mux : for i in 0 to C_K_TMR-1 generate
      LOCK_COUNTER_RESET(i) <= s_lock_counter_reset;
      LOCK_COUNTER_LATCH(i) <= s_lock_counter_latch;
    end generate for_output_mux;
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte mmcm_monitor_handler, defines the necessary signals locally
    tmr_block : block is
      type t_lr_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);

      signal s_counter_latch, s_counter_reset : t_lr_tmr;
      signal s_wbs_wbs_o                      : t_wbs_o_array(0 to C_K_TMR-1);

      attribute DONT_TOUCH                    : string;
      attribute DONT_TOUCH of s_counter_latch : signal is "TRUE";
      attribute DONT_TOUCH of s_counter_reset : signal is "TRUE";
      attribute DONT_TOUCH of s_wbs_wbs_o     : signal is "TRUE";

    begin  -- block tmr_block

      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        mmcm_monitor_wishbone_INST : entity work.mmcm_monitor_wishbone
          port map (
            WB_CLK             => WB_CLK,
            WB_RST             => WB_RST,
            WB_WBS_I           => WB_WBS_I(i),
            COUNTER_ARRAY      => COUNTER_ARRAY,
            LOCK_COUNTER       => LOCK_COUNTER,
            MISMATCH_ARRAY     => MISMATCH_ARRAY,
            MISMATCH_2ND_ARRAY => MISMATCH_2ND_ARRAY,

            WB_WBS_O           => s_wbs_wbs_o(i),
            COUNTER_LATCH      => s_counter_latch(i),
            COUNTER_RESET      => s_counter_reset(i),
            LOCK_COUNTER_LATCH => LOCK_COUNTER_LATCH(i),
            LOCK_COUNTER_RESET => LOCK_COUNTER_RESET(i)
            );
      end generate for_TMR_generate;

      INST_majority_voter_array_wrapper_COUNTER_LATCH : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => COUNTER_LATCH'length)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT_A       => s_counter_latch(0),
          INPUT_B       => s_counter_latch(1),
          INPUT_C       => s_counter_latch(2),
          OUTPUT        => COUNTER_LATCH,
          MISMATCH      => open,
          MISMATCH_2ND  => open);

      INST_majority_voter_array_wrapper_COUNTER_RESET : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => COUNTER_RESET'length)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT_A       => s_counter_reset(0),
          INPUT_B       => s_counter_reset(1),
          INPUT_C       => s_counter_reset(2),
          OUTPUT        => COUNTER_RESET,
          MISMATCH      => open,
          MISMATCH_2ND  => open);

      INST_majority_voter_triplicated_wbs_o : entity work.majority_voter_triplicated_wbs_o
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT         => s_wbs_wbs_o,
          OUTPUT        => WB_WBS_O,
          MISMATCH      => open,
          MISMATCH_2ND  => open);
    end block tmr_block;
  end generate if_TMR_generate;

end architecture structural;
