-------------------------------------------------------------------------------
-- Title      : mmcm_monitor_dut
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mmcm_monitor_dut.vhd
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

entity mmcm_monitor_dut is
  generic (
    G_USER_CLOCK_NUMBER : integer := 7;
    G_CLKFBOUT_MULT_F   : real    := 6.250  -- 6.250 for 83.33 MHz and 6 for 80.00 MHz
    );
  port (
    CLK_IN       : in  std_logic;
    RESET        : in  std_logic;
    WB_CLK       : in  std_logic;
    LOCKED       : out std_logic;
    USER_CLK_OUT : out std_logic_vector(G_USER_CLOCK_NUMBER-1 downto 0)
    );
end entity mmcm_monitor_dut;
-------------------------------------------------------------------------------
-- Beginning of the Architecture
-------------------------------------------------------------------------------
architecture struct of mmcm_monitor_dut is

  signal s_clkfbout     : std_logic;
  signal s_clkfbout_buf : std_logic;
  signal s_clk_out      : std_logic_vector(G_USER_CLOCK_NUMBER-1 downto 0);

begin

  INST_mmcm_adv1 : MMCME3_ADV
    generic map (
      BANDWIDTH            => "OPTIMIZED",
      CLKOUT4_CASCADE      => "FALSE",
      COMPENSATION         => "AUTO",
      STARTUP_WAIT         => "FALSE",
      DIVCLK_DIVIDE        => 1,
      CLKFBOUT_MULT_F      => G_CLKFBOUT_MULT_F,
      CLKFBOUT_PHASE       => 0.000,
      CLKFBOUT_USE_FINE_PS => "FALSE",
      CLKOUT0_DIVIDE_F     => 12.000,    -- f_{CLK_IN} $\times$ CLKFBOUT_MULT_F
      -- $\times$ DIVCLK_DIVIDE $\times$  CLKOUT0_DIVIDE_F
      -- = 160 * 6.25 / (2*6) = 83.33 MHz
      CLKOUT0_PHASE        => 0.000,
      CLKOUT0_DUTY_CYCLE   => 0.500,
      CLKOUT0_USE_FINE_PS  => "FALSE",
      CLKOUT1_DIVIDE       => 12,
      CLKOUT1_PHASE        => 0.000,
      CLKOUT1_DUTY_CYCLE   => 0.500,
      CLKOUT1_USE_FINE_PS  => "FALSE",
      CLKOUT2_DIVIDE       => 12,
      CLKOUT2_PHASE        => 0.000,
      CLKOUT2_DUTY_CYCLE   => 0.500,
      CLKOUT2_USE_FINE_PS  => "FALSE",
      CLKOUT3_DIVIDE       => 12,
      CLKOUT3_PHASE        => 0.000,
      CLKOUT3_DUTY_CYCLE   => 0.500,
      CLKOUT3_USE_FINE_PS  => "FALSE",
      CLKOUT4_DIVIDE       => 12,
      CLKOUT4_PHASE        => 0.000,
      CLKOUT4_DUTY_CYCLE   => 0.500,
      CLKOUT4_USE_FINE_PS  => "FALSE",
      CLKOUT5_DIVIDE       => 12,
      CLKOUT5_PHASE        => 0.000,
      CLKOUT5_DUTY_CYCLE   => 0.500,
      CLKOUT5_USE_FINE_PS  => "FALSE",
      CLKOUT6_DIVIDE       => 12,
      CLKOUT6_PHASE        => 0.000,
      CLKOUT6_DUTY_CYCLE   => 0.500,
      CLKOUT6_USE_FINE_PS  => "FALSE",
      CLKIN1_PERIOD        => 6.25
      )
    port map (
      CLKFBOUT     => s_clkfbout,
      CLKFBOUTB    => open,
      CLKOUT0      => s_clk_out(0),
      CLKOUT0B     => open,
      CLKOUT1      => s_clk_out(1),
      CLKOUT1B     => open,
      CLKOUT2      => s_clk_out(2),
      CLKOUT2B     => open,
      CLKOUT3      => s_clk_out(3),
      CLKOUT3B     => open,
      CLKOUT4      => s_clk_out(4),
      CLKOUT5      => s_clk_out(5),
      CLKOUT6      => s_clk_out(6),
      --  Input clock control
      CLKFBIN      => s_clkfbout_buf,
      CLKIN1       => CLK_IN,
      CLKIN2       => '0',
      --   Tied to always select the primary input clock
      CLKINSEL     => '1',
      --  Ports for dynamic reconfiguration
      DADDR        => "0000000",
      DCLK         => '0',
      DEN          => '0',
      DI           => x"0000",
      DO           => open,
      DRDY         => open,
      DWE          => '0',
      CDDCDONE     => open,
      CDDCREQ      => '0',
      -- Ports for dynamic phase shift
      PSCLK        => '0',
      PSEN         => '0',
      PSINCDEC     => '0',
      PSDONE       => open,
      --  Other control and status signals
      LOCKED       => LOCKED,
      CLKINSTOPPED => open,
      CLKFBSTOPPED => open,
      PWRDWN       => '0',
      RST          => RESET
      );

  --------------------------------------
  --  Output buffering
  -----------------------------------
  INST_clkf_buf : BUFG
    port map (
      O => s_clkfbout_buf,
      I => s_clkfbout
      );

  BUFG_for_generate : for i in 0 to G_USER_CLOCK_NUMBER-1 generate
    INST_clkout0_buf : BUFG
      port map (
        O => USER_CLK_OUT(i),
        I => s_clk_out(i)
        );
  end generate BUFG_for_generate;

end architecture struct;
