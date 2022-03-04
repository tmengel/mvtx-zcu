-------------------------------------------------------------------------------
-- Title      : Clock Generator
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : clock_generator.vhd
-- Author     : J. Schambach
-- Company    : University of Texas
-- Created    : 2018-06-04
-- Last update: 2018-06-04
-- Platform   : Xilinx Vivado
-- Target     : Kintex-Utrascale
-------------------------------------------------------------------------------
-- Description: Generates all of the needed user clocks using the MMCM IP
--              Also switches between the two input clocks
--
-----------------------------------------------------------
--  Output          Output      Phase    Duty Cycle  Source
--   Clock          Freq (MHz)  (degrees)    (%)
----------------------------------------------------------
-- USER_CLK_OUT0___150.000_______0.000______50.0____CLKDIV
-- USER_CLK_OUT1___600.000_______0.000______50.0____MMCM
-- USER_CLK_OUT2____75.000_______0.000______50.0____MMCM
-- USER_CLK_OUT3___100.000_______0.000______50.0____MMCM
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity clock_generator is
  generic (
    G_USER_CLOCK_NUMBER  : integer := 4 -- Number of output clocks
    );
  port (
    CLK_IN_dp    : in  std_logic; -- Input clock (p)
    CLK_IN_dn    : in  std_logic; -- Input clock (n)
    RESET        : in  std_logic;   -- MMCM async reset
    LOCKED       : out std_logic;   -- MMCM locked 
    USER_CLK_OUT : out std_logic_vector(G_USER_CLOCK_NUMBER-1 downto 0) -- Output clocks, see header
    );
end entity clock_generator;
-------------------------------------------------------------------------------
-- Beginning of the Architecture
-------------------------------------------------------------------------------
architecture Behavior of clock_generator is
  --constant C_MMCM_NUMBER              : integer := 1;

  signal sClkIn        : std_logic;
  signal sClkfbout     : std_logic;                                         -- Dedicated MMCM Feedback clock output
  signal sClkfbout_buf : std_logic;                                         -- Buffered sClkfbout
  signal sClk_out      : std_logic_vector(G_USER_CLOCK_NUMBER-1 downto 0);  -- Clock outputs from MMCM


  signal s_bufgce_div_ce, s_bufgce_div_clr : std_logic;

begin

  --------------------------------------
  --  Input buffering (diff to single ended)
  --------------------------------------
  INST_localClock_ibufds : IBUFDS
    port map (
      O  => sClkIn,
      I  => CLK_IN_dp,
      IB => CLK_IN_dn
      );



  --------------------------------------
  --  MMCM
  --------------------------------------
  INST_mmcm_adv1 : MMCME3_ADV
    generic map (
      BANDWIDTH            => "OPTIMIZED",
      CLKOUT4_CASCADE      => "FALSE",
      COMPENSATION         => "AUTO",
      STARTUP_WAIT         => "FALSE",
      DIVCLK_DIVIDE        => 1,
      CLKFBOUT_MULT_F      => 3.750,
      CLKFBOUT_PHASE       => 0.000,
      CLKFBOUT_USE_FINE_PS => "FALSE",
      CLKOUT0_DIVIDE_F     => 1.000,
      CLKOUT0_PHASE        => 0.000,
      CLKOUT0_DUTY_CYCLE   => 0.500,
      CLKOUT0_USE_FINE_PS  => "FALSE",
      CLKOUT1_DIVIDE       => 8,
      CLKOUT1_PHASE        => 0.000,
      CLKOUT1_DUTY_CYCLE   => 0.500,
      CLKOUT1_USE_FINE_PS  => "FALSE",
      CLKOUT2_DIVIDE       => 6,
      CLKOUT2_PHASE        => 0.000,
      CLKOUT2_DUTY_CYCLE   => 0.500,
      CLKOUT2_USE_FINE_PS  => "FALSE",
      CLKIN1_PERIOD        => 6.25
      )
    port map (
      CLKFBOUT     => sClkfbout,
      CLKFBOUTB    => open,
      CLKOUT0      => sClk_out(0),
      CLKOUT0B     => open,
      CLKOUT1      => sClk_out(1),
      CLKOUT1B     => open,
      CLKOUT2      => sClk_out(2),
      CLKOUT2B     => open,
      CLKOUT3      => open,
      CLKOUT3B     => open,
      CLKOUT4      => open,
      CLKOUT5      => open,
      CLKOUT6      => open,
      --  Input clock control
      CLKFBIN      => sClkfbout_buf,
      CLKIN1       => sClkIn,
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
  --------------------------------------
  INST_clkf_buf : BUFG
    port map (
      O => sClkfbout_buf,
      I => sClkfbout
      );


  INST_BUFGCE_DIV_40 : BUFGCE_DIV
    generic map (
      BUFGCE_DIVIDE   => 4,
      IS_CE_INVERTED  => '0',           -- Optional inversion for CE
      IS_CLR_INVERTED => '0',           -- Optional inversion for CLR
      IS_I_INVERTED   => '0'            -- Optional inversion for I
    )
    port map (
      O   => USER_CLK_OUT(0),
      CE  => '1',
      CLR => '0',
      I   => sClk_out(0)
    );


  INST_clkout0_buf : BUFG
    port map (
      O => USER_CLK_OUT(1),
      I => sClk_out(0)
      );
  
  INST_clkout1_buf : BUFG
    port map (
      O => USER_CLK_OUT(2),
      I => sClk_out(1)
      );
  
  INST_clkout2_buf : BUFG
    port map (
      O => USER_CLK_OUT(3),
      I => sClk_out(2)
      );
  

end architecture Behavior;
