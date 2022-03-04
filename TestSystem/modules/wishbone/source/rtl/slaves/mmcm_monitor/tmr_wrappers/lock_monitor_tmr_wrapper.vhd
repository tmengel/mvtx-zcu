-------------------------------------------------------------------------------
-- Title      : lock_monitor_tmr_wrapper
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : lock_monitor_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-25
-- Last update: 2017-11-20
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the lock_monitor module.
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

entity lock_monitor_tmr_wrapper is
  generic (
    IS_SATURATING              : integer := 0;
    VERBOSE                    : integer := 0;
    G_SEE_MITIGATION_TECHNIQUE : integer := 1;
    G_MISMATCH_EN              : integer := 1;
    G_MISMATCH_REGISTERED      : integer := 0;
    G_ADDITIONAL_MISMATCH      : integer := 1);
  port (
    clk_i           : in  std_logic;
    rst_i           : in  std_logic;
    monitored_i     : in  std_logic;
    latch_counter_i : in  std_logic_vector(C_K_TMR-1 downto 0);
    reset_counter_i : in  std_logic_vector(C_K_TMR-1 downto 0);
    counter_value_o : out std_logic_vector(WB_DATA_WIDTH-1 downto 0));
  attribute DONT_TOUCH                             : string;
  attribute DONT_TOUCH of lock_monitor_tmr_wrapper : entity is "true";
end entity lock_monitor_tmr_wrapper;

architecture structural of lock_monitor_tmr_wrapper is

  constant C_BIT_WIDTH : integer := (WB_DATA_WIDTH-1)/3;
  component upcounter_latch_re
    generic(
      BIT_WIDTH     : integer := C_BIT_WIDTH;
      IS_SATURATING : integer := 0;
      VERBOSE       : integer := 0
      );
    port(
      clk_i           : in  std_logic;
      rst_i           : in  std_logic;
      monitored_i     : in  std_logic;
      latch_counter_i : in  std_logic;
      reset_counter_i : in  std_logic;
      counter_value_o : out std_logic_vector(BIT_WIDTH-1 downto 0)
      );
  end component;

  signal s_counter_value                  : std_logic_vector(C_BIT_WIDTH-1 downto 0);

begin  -- architecture structural

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    upcounter_latch_re_1 : upcounter_latch_re
      generic map (
        BIT_WIDTH     => C_BIT_WIDTH,
        IS_SATURATING => IS_SATURATING,
        VERBOSE       => VERBOSE)
      port map (
        clk_i           => clk_i,
        rst_i           => rst_i,
        monitored_i     => monitored_i,
        latch_counter_i => latch_counter_i(0),
        reset_counter_i => reset_counter_i(0),
        counter_value_o => s_counter_value
        );

    counter_value_o <= '0' & s_counter_value & s_counter_value & s_counter_value;
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte mmcm_monitor_handler, defines the necessary signals locally
    tmr_block : block is

    begin  -- block tmr_block
      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        upcounter_latch_re_INST : upcounter_latch_re
          generic map (
            BIT_WIDTH     => C_BIT_WIDTH,
            IS_SATURATING => IS_SATURATING,
            VERBOSE       => VERBOSE)
          port map (
            clk_i           => clk_i,
            rst_i           => rst_i,
            monitored_i     => monitored_i,
            latch_counter_i => latch_counter_i(i),
            reset_counter_i => reset_counter_i(i),
            counter_value_o => counter_value_o(i*C_BIT_WIDTH + C_BIT_WIDTH -1 downto i*C_BIT_WIDTH));
      end generate for_TMR_generate;
      counter_value_o(WB_DATA_WIDTH-1) <= '0';
    end block tmr_block;
  end generate if_TMR_generate;

end architecture structural;
