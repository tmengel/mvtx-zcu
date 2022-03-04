-------------------------------------------------------------------------------
-- Title      : mmcm_monitor_dut_sim
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mmcm_monitor_dut.vhd
-- Author     : Matteo Lupi (matteo.lupi@cern.ch)
-- Company    : Goethe Universitaet Frankfurt am Main / CERN
-- Created    : 2017-11-16
-- Last update: 2017-11-21
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-Utrascale
-------------------------------------------------------------------------------
-- Description: DUT for mmcm testing in beam, simulation model
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.xpm_cdc_components_pkg.all;

architecture behav of mmcm_monitor_dut is

  signal s_locked       : std_logic := '0';
  signal s_clk_out      : std_logic_vector(G_USER_CLOCK_NUMBER-1 downto 0) := (others => '0');

begin

  for_outputs_gen: for i  in 0 to G_USER_CLOCK_NUMBER-1 generate
    p_clock: process (CLK_IN, RESET) is
    begin  -- process p_clock
        if RESET = '1' then               -- synchronous reset (active high)
          s_clk_out(i) <= '0';
        else
      if rising_edge(CLK_IN) then       -- rising clock edge
          s_clk_out(i) <= not(s_clk_out(i));
        end if;
      end if;
    end process p_clock;
  end generate for_outputs_gen;

  p_lock_generation: process (CLK_IN, RESET) is
  begin  -- process p_lock_generation
    if RESET = '1' then               -- synchronous reset (active high)
      s_locked <= '0';
    else
      if rising_edge(CLK_IN) then         -- rising clock edge
        s_locked <= '1';
      end if;
    end if;
  end process p_lock_generation;

  --------------------------------------
  --  Output buffering
  -----------------------------------

  BUFG_for_generate : for i in 0 to G_USER_CLOCK_NUMBER-1 generate
    INST_clkout0_buf : BUFG
      port map (
        O => USER_CLK_OUT(i),
        I => s_clk_out(i)
        );
  end generate BUFG_for_generate;

  -----------------------------------------------------------------------------
  -- locked xpm
  -----------------------------------------------------------------------------

  INST_xpm_cmtlocked_sync : xpm_cdc_async_rst
    generic map (
      DEST_SYNC_FF    => 4,
      RST_ACTIVE_HIGH => 0)
    port map (
      src_arst  => s_locked,
      dest_clk  => WB_CLK,
      dest_arst => LOCKED);

end behav;
