-------------------------------------------------------------------------------
-- Title      : Readout Unit version 1 Top Level
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : RUv1_top.vhd
-- Author     : M.J. Rossewij
-- Company    : Utrecht University
-- Author     : J. Schambach
-- Company    : University of Texas
-- Created    : 2017-03-17
-- Last update: 2019-01-04
-- Platform   : Xilinx Vivado
-- Target     : Kintex-Utrascale
-------------------------------------------------------------------------------
-- Description: Top Level VHDL entity
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity RUv1_top is
  generic(
    USE_DEBUG : string                        := "FALSE";
    HASH_CODE : std_logic_vector(31 downto 0) := x"0bad6";  -- "git log -1 --pretty=%h"
    DATE      : std_logic_vector(47 downto 0) := x"0bad0badcafe";
    OS        : std_logic_vector(15 downto 0) := x"affe"
    );
  port(
-- Fabric User Clocks
    -- localClock
    -- LOCAL_CLK(0):    RefClk1 for MGT_226 (for ALPIDE_MGT(27:8))
    -- LOCAL_CLK(1):    RefClk1 for MGT_127 (ALPIDE_MGT(7:0)
    -- LOCAL_CLK(2):    to fabric clock switcher
    LOCAL_CLK_dp        : in    std_logic_vector(2 downto 0);
    LOCAL_CLK_dn        : in    std_logic_vector(2 downto 0);
    -- Output to SMA connectors
    CLK_OUT_dp          : out   std_logic;
    CLK_OUT_dn          : in    std_logic;
-- GBTx0 phase adjustable clocks
    -- GBTX_CLOCKDES(0):        RefClk0 for MGT_226 (ALPIDE_MGT(27:8))
    -- GTBX_CLOCKDES(1):        RefClk0 for MGT_127 (ALPIDE_MGT(7:0))
    -- GBTX_CLOCKDES(2):        to Fabric
    -- GBTX_CLOCKDES(3):        to Fabric
    GBTX_CLOCKDES_dp    : in    std_logic_vector(3 downto 0);
    GBTX_CLOCKDES_dn    : in    std_logic_vector(3 downto 0);
    --
    -- reset to GBTx ASICs
    GBT_RESET_n         : out   std_logic;
    --
-- SCA
    -- GPIO(3:0) are triplicated I/Os
    SCA_GPIO            : inout std_logic_vector(11 downto 4);
    SCA_GPIO_A          : inout std_logic_vector(3 downto 0);
    SCA_GPIO_B          : inout std_logic_vector(3 downto 0);
    SCA_GPIO_C          : inout std_logic_vector(3 downto 0);
    -- I2C to GBTx chips
    SCA_SCL             : inout std_logic;  -- I2C master clock (to GBTx0/1/2 control, can also be used by SCA_I2C[7])
    SCA_SDA             : inout std_logic;  -- I2C master data  (to GBTx0/1/2 control, can also be used by SCA_I2C[7])
    -- I2C from SCA chip
    SCA_SCL4            : in    std_logic;  -- I2C slave clock (From SCA_I2C[4])
    SCA_SDA4            : inout std_logic;  -- I2C slave data  (From SCA_I2C[4])
    -- SPI slave
    SCA_SPI_MOSI        : in    std_logic;  -- SPI slave, data in (From SCA)
    SCA_SPI_MISO        : out   std_logic;  -- SPI slave, data out (From SCA)
    SCA_SPI_TCK         : in    std_logic;  -- SPI slave, clock (From SCA)
    SCA_SPI_SS0         : in    std_logic;  -- SPI slave, select (From SCA, select 0)
-- GBTx0
    GBTX0_RXRDY         : in    std_logic;  -- GBTx1 receiver ready
    GBTX0_TXRDY         : in    std_logic;  -- GBTx1 transmitter ready
    -- DataValid signals are triplicated I/Os
    GBTX0_TXDATAVALID_A : out   std_logic;  -- GBTx0 transmit data valid
    GBTX0_TXDATAVALID_B : out   std_logic;  -- GBTx0 transmit data valid
    GBTX0_TXDATAVALID_C : out   std_logic;  -- GBTx0 transmit data valid
    GBTX0_RXDATAVALID_A : in    std_logic;  -- GBTx0 receive data valid
    GBTX0_RXDATAVALID_B : in    std_logic;  -- GBTx0 receive data valid
    GBTX0_RXDATAVALID_C : in    std_logic;  -- GBTx0 receive data valid
    GBTX0_DOUT_dp       : in    std_logic_vector(9 downto 0);  -- GBTX0 elink data input
    GBTX0_DOUT_dn       : in    std_logic_vector(9 downto 0);  -- GBTX0 elink data input
    GBTX0_DCLK_dp       : in    std_logic_vector(1 downto 0);  -- GBTX0 elink clock input
    GBTX0_DCLK_dn       : in    std_logic_vector(1 downto 0);  -- GBTX0 elink clock input
    GBTX0_DIN_dp        : out   std_logic_vector(9 downto 0);  -- GBTX0 elink data output
    GBTX0_DIN_dn        : out   std_logic_vector(9 downto 0);  -- GBTX0 elink data output
    --
-- GBTx1
    GBTX1_TXRDY         : in    std_logic;  -- GBTx1 transmitter ready
    -- DataValid signals are triplicated I/Os
    GBTX1_TXDATAVALID_A : out   std_logic;  -- GBTx1 transmit data valid
    GBTX1_TXDATAVALID_B : out   std_logic;  -- GBTx1 transmit data valid
    GBTX1_TXDATAVALID_C : out   std_logic;  -- GBTx1 transmit data valid
    GBTX1_DIN_dp        : out   std_logic_vector(9 downto 0);  -- GBTX1 elink data output
    GBTX1_DIN_dn        : out   std_logic_vector(9 downto 0);  -- GBTX1 elink data output
    --
-- GBTx2
    GBTX2_RXRDY         : in    std_logic;  -- GBTx1 receiver ready
    GBTX2_TXRDY         : in    std_logic;  -- GBTx1 transmitter ready
    -- DataValid signals are triplicated I/Os
    GBTX2_TXDATAVALID_A : out   std_logic;  -- GBTx2 transmit data valid
    GBTX2_TXDATAVALID_B : out   std_logic;  -- GBTx2 transmit data valid
    GBTX2_TXDATAVALID_C : out   std_logic;  -- GBTx2 transmit data valid
    GBTX2_RXDATAVALID_A : in    std_logic;  -- GBTx2 receive data valid
    GBTX2_RXDATAVALID_B : in    std_logic;  -- GBTx2 receive data valid
    GBTX2_RXDATAVALID_C : in    std_logic;  -- GBTx2 receive data valid
    GBTX2_DOUT_dp       : in    std_logic_vector(9 downto 0);  -- GBTX2 elink data input
    GBTX2_DOUT_dn       : in    std_logic_vector(9 downto 0);  -- GBTX2 elink data input
    GBTX2_DCLK_dp       : in    std_logic_vector(1 downto 0);  -- GBTX2 elink clock input
    GBTX2_DCLK_dn       : in    std_logic_vector(1 downto 0);  -- GBTX2 elink clock input
    GBTX2_DIN_dp        : out   std_logic_vector(9 downto 0);  -- GBTX2 elink data output
    GBTX2_DIN_dn        : out   std_logic_vector(9 downto 0);  -- GBTX2 elink data output
    --
-- PA3
    PA3_IO              : inout std_logic_vector(11 downto 0); -- GPIO to PA3
    PA3_OUT_dp          : out   std_logic_vector(4 downto 0);  -- Diff outputs to PA3
    PA3_OUT_dn          : out   std_logic_vector(4 downto 0);  -- Diff outputs to PA3
    PA3_IN_dp           : in    std_logic_vector(9 downto 5);  -- Diff inputs from PA3
    PA3_IN_dn           : in    std_logic_vector(9 downto 5);  -- Diff inputs from PA3
    --
--USB3/FX3
    FX3_PCLK            : out   std_logic;
    FX3_DQ              : inout std_logic_vector(31 downto 0);
    FX3_CTL             : inout std_logic_vector(12 downto 0);
    FX3_RESET_n         : out   std_logic;
    FX3_INT_n           : out   std_logic;
    FX3_UART_TX         : in    std_logic;
    FX3_UART_RX         : out   std_logic;
    --
-- Alpide interface
    -- DCLK signals triplicated
    ALPIDE_DCLK_A       : out   std_logic_vector(4 downto 0);  -- Alpide DCLK
    ALPIDE_DCLK_B       : in    std_logic_vector(4 downto 0);  -- Alpide DCLK
    ALPIDE_DCLK_C       : in    std_logic_vector(4 downto 0);  -- Alpide DCLK
    ALPIDE_DCLK_EN      : out   std_logic_vector(4 downto 0);  -- Alpide DCLK output enable
    ALPIDE_DCTRL_D      : out   std_logic_vector(4 downto 0);  -- Alpide DCTRL out
    ALPIDE_DCTRL_DE     : out   std_logic_vector(4 downto 0);  -- Alpide DCTRL output enable
    ALPIDE_DCTRL_R      : in    std_logic_vector(4 downto 0);  -- Alpide DCTRL in
    -- inner barrel to MGT
    ALPIDE_DATA_MGT_dp  : in    std_logic_vector(27 downto 0);
    ALPIDE_DATA_MGT_dn  : in    std_logic_vector(27 downto 0);
    -- middle, outer barrel to general purpose IO
    ALPIDE_DATA_GPIO_dp : out   std_logic_vector(27 downto 0);
    ALPIDE_DATA_GPIO_dn : out   std_logic_vector(27 downto 0);
    --
-- Power Board
    PU1_SDA_WRITE       : out   std_logic;
    PU1_SDA_READ        : in    std_logic;
    PU1_SCL_WRITE       : out   std_logic;
    PU1_SCL_READ        : in    std_logic;
    PU1_SDA_AUX_WRITE   : out   std_logic;
    PU1_SDA_AUX_READ    : in    std_logic;
    PU1_SCL_AUX_WRITE   : out   std_logic;
    PU1_SCL_AUX_READ    : in    std_logic;
    --
    PU2_SDA_WRITE       : out   std_logic;
    PU2_SDA_READ        : in    std_logic;
    PU2_SCL_WRITE       : out   std_logic;
    PU2_SCL_READ        : in    std_logic;
    PU2_SDA_AUX_WRITE   : out   std_logic;
    PU2_SDA_AUX_READ    : in    std_logic;
    PU2_SCL_AUX_WRITE   : out   std_logic;
    PU2_SCL_AUX_READ    : in    std_logic;
    --
    -- AUX connector
    AUX_dp              : inout std_logic_vector(3 downto 0);
    AUX_dn              : inout std_logic_vector(3 downto 0);
    -- These driven by a MGT TX (not yet used):
    --BUSY_OUT_dp         : out   std_logic;
    --BUSY_OUT_dn         : out   std_logic;
    -- MISC
    LED                 : out   std_logic_vector(3 downto 0);
    PUSHBUTTON          : in    std_logic_vector(3 downto 0);
    PINHEADER           : inout std_logic_vector(9 downto 0);
    DIPSWITCH           : in    std_logic_vector(9 downto 0)
    );
end entity RUv1_top;

-------------------------------------------------------------------------------
-- Beginning of the Architecture
-------------------------------------------------------------------------------
architecture Behavior of RUv1_top is
  signal sClkRst            : std_logic;  -- MMCM reset
  -- Outputs from clock generator
  signal sClkLocked         : std_logic;
  signal sClk150            : std_logic;
  signal sClk75             : std_logic;
  signal sclk600            : std_logic;
  signal sClk100            : std_logic;
  -- Buffered/unbuffered IO signals
  signal sClkIn_dp          : std_logic_vector(1 downto 0);
  signal sClkIn_dn          : std_logic_vector(1 downto 0);
  signal s_alpide_data_gpio : std_logic_vector(27 downto 0);
  signal s_sca_scl_i        : std_logic;
  signal s_sca_scl_o        : std_logic;
  signal s_sca_scl_T        : std_logic;
  signal s_sca_sda_i        : std_logic;
  signal s_sca_sda_o        : std_logic;
  signal s_sca_sda_T        : std_logic;
  signal s_sca_sda4_i       : std_logic;
  signal s_sca_sda4_o       : std_logic;
  signal s_sca_sda4_T       : std_logic;
  signal s_pa3_io_i         : std_logic_vector(11 downto 0);
  signal s_pa3_io_o         : std_logic_vector(11 downto 0);
  signal s_pa3_io_T         : std_logic_vector(11 downto 0);
  signal s_pa3_out          : std_logic_vector(4 downto 0);
  signal s_pa3_in           : std_logic_vector(9 downto 5);
  signal s_fx3_dq_i         : std_logic_vector(31 downto 0);
  signal s_fx3_dq_o         : std_logic_vector(31 downto 0);
  signal s_fx3_dq_T         : std_logic;
  signal s_fx3_ctl_i        : std_logic_vector(12 downto 0);
  signal s_fx3_ctl_o        : std_logic_vector(12 downto 0);
  signal s_fx3_ctl_T        : std_logic_vector(12 downto 0);
  signal s_gbtx0_dout       : std_logic_vector(9 downto 0);
  signal s_gbtx0_din        : std_logic_vector(9 downto 0);
  signal s_gbtx1_din        : std_logic_vector(9 downto 0);
  signal s_gbtx0_dclk       : std_logic_vector(1 downto 0);
  signal s_gbtx2_dclk       : std_logic_vector(1 downto 0);
  signal s_gbtx2_dout       : std_logic_vector(9 downto 0);
  signal s_gbtx2_din        : std_logic_vector(9 downto 0);

  signal sGbtx0_txdatavalid_A   : std_logic;
  signal sGbtx0_txdatavalid_A_T : std_logic;
  signal sGbtx0_txdatavalid_B   : std_logic;
  signal sGbtx0_txdatavalid_B_T : std_logic;
  signal sGbtx0_txdatavalid_C   : std_logic;
  signal sGbtx0_txdatavalid_C_T : std_logic;
  signal sGbtx1_txdatavalid_A   : std_logic;
  signal sGbtx1_txdatavalid_A_T : std_logic;
  signal sGbtx1_txdatavalid_B   : std_logic;
  signal sGbtx1_txdatavalid_B_T : std_logic;
  signal sGbtx1_txdatavalid_C   : std_logic;
  signal sGbtx1_txdatavalid_C_T : std_logic;
  signal sGbtx2_txdatavalid_A   : std_logic;
  signal sGbtx2_txdatavalid_A_T : std_logic;
  signal sGbtx2_txdatavalid_B   : std_logic;
  signal sGbtx2_txdatavalid_B_T : std_logic;
  signal sGbtx2_txdatavalid_C   : std_logic;
  signal sGbtx2_txdatavalid_C_T : std_logic;

  signal s_alpide_dctrl_t                                      : std_logic;
  signal s_alpide_dctrl_o, s_alpide_dctrl_i, s_alpide_dctrl_de : std_logic_vector(ALPIDE_DCTRL_D'range);

  signal s_alpide_dclk_a                                       : std_logic_vector(ALPIDE_DCLK_EN'range);
  signal s_alpide_dclk_a_t                                     : std_logic_vector(ALPIDE_DCLK_EN'range);
  signal s_alpide_dclk_o, s_alpide_dclk_en                     : std_logic_vector(ALPIDE_DCLK_EN'range);

  signal sClkOut : std_logic;  -- Clock output for debug to SMA (unbuffered CLK_OUT)
  signal sClkIn  : std_logic;  -- Clock input  for debug to SMA (unbuffered CLK_OUT)

  -- SCA GPIO
  signal s_scaGpio_i   : std_logic_vector(11 downto 4);  -- SCA GPIO bidir inputs
  signal s_scaGpio_A_i : std_logic_vector(3 downto 0);  -- SCA GPIO bidir inputs
  signal s_scaGpio_B_i : std_logic_vector(3 downto 0);  -- SCA GPIO bidir inputs
  signal s_scaGpio_C_i : std_logic_vector(3 downto 0);  -- SCA GPIO bidir inputs
  signal s_scaGpio_o   : std_logic_vector(11 downto 0);  -- SCA GPIO bidir outputs
  signal s_scaGpio_T   : std_logic_vector(11 downto 0);  -- SCA GPIO bidir output selection
  signal s_scaGpio_temp: std_logic_vector(3 downto 0);   -- storing calculated SCA GPIO values
  
  -- AUX signals
  signal s_aux_out     : std_logic_vector(3 downto 0);   -- AUX output signals
  signal s_aux_in      : std_logic_vector(3 downto 0);   -- AUX intput signals
 
  -- PIN Header
  signal s_pinheader_o : std_logic_vector(9 downto 0);
  signal s_pinheader_i : std_logic_vector(9 downto 0);
  signal s_pinheader_T : std_logic_vector(9 downto 0);

begin
  --------------------------------------
  --  Clock Input buffering and generation
  --------------------------------------
  sClkRst <= '0';

  INST_clock_generator : entity work.clock_generator
    generic map(
      G_USER_CLOCK_NUMBER  => 4
      )
    port map(
      CLK_IN_dp       => LOCAL_CLK_dp(2),
      CLK_IN_dn       => LOCAL_CLK_dn(2),
      RESET           => sClkRst,
      LOCKED          => sClkLocked,
      USER_CLK_OUT(0) => sclk150,
      USER_CLK_OUT(1) => sClk600,
      USER_CLK_OUT(2) => sClk75,
      USER_CLK_OUT(3) => sClk100
      );

  --------------------------------------
  --  Top fabric
  --------------------------------------

  INST_fabric_top : entity work.fabric_top
    generic map(
      USE_DEBUG => USE_DEBUG,
      HASH_CODE => HASH_CODE,
      DATE      => DATE,
      OS        => OS)
    port map(
      PUSHBUTTON            => PUSHBUTTON,
      HEADER_i              => s_pinheader_i(9 downto 5),
      HEADER_o              => s_pinheader_o(4 downto 0),
      CLKOUT                => sClkOut,
      CLKIn                 => sClkIn,
      CLK150                => sClk150,
      CLK600                => sClk600,
      CLK75                 => sClk75,
      CLK100                => sClk100,
      CLK_LOCKED            => sClkLocked,
      REFCLK1_226_dp        => LOCAL_CLK_dp(0),
      REFCLK1_226_dn        => LOCAL_CLK_dn(0),
      REFCLK1_127_dp        => LOCAL_CLK_dp(1),
      REFCLK1_127_dn        => LOCAL_CLK_dn(1),
      ALPIDE_DCLK_A         => s_alpide_dclk_a,
      ALPIDE_DCLK_B         => ALPIDE_DCLK_B,
      ALPIDE_DCLK_C         => ALPIDE_DCLK_C,
      ALPIDE_DCLK_EN        => s_alpide_dclk_en,
      ALPIDE_DCLK_A_T       => s_alpide_dclk_a_t,
      ALPIDE_DCTRL_O        => s_alpide_dctrl_o,
      ALPIDE_DCTRL_T        => s_alpide_dctrl_t,
      ALPIDE_DCTRL_I        => s_alpide_dctrl_i,
      ALPIDE_DATA_MGT_dp    => ALPIDE_DATA_MGT_dp,
      ALPIDE_DATA_MGT_dn    => ALPIDE_DATA_MGT_dn,
      ALPIDE_DATA_GPIO      => s_alpide_data_gpio,
      GBTX_SCL_i            => s_sca_scl_i,
      GBTX_SCL_o            => s_sca_scl_o,
      GBTX_SCL_T            => s_sca_scl_T,
      GBTX_SDA_i            => s_sca_sda_i,
      GBTX_SDA_o            => s_sca_sda_o,
      GBTX_SDA_T            => s_sca_sda_T,
      SCA_SCL               => SCA_SCL4,
      SCA_SDA_i             => s_sca_sda4_i,
      SCA_SDA_o             => s_sca_sda4_o,
      SCA_SDA_T             => s_sca_sda4_T,
      SCA_SPI_MOSI          => SCA_SPI_MOSI,
      SCA_SPI_MISO          => SCA_SPI_MISO,
      SCA_SPI_TCK           => SCA_SPI_TCK,
      SCA_SPI_SS0           => SCA_SPI_SS0,
      SCA_GPIO_A_i          => s_scaGpio_A_i,
      SCA_GPIO_B_i          => s_scaGpio_B_i,
      SCA_GPIO_C_i          => s_scaGpio_C_i,
      PA3_IO_i              => s_pa3_io_i,
      PA3_IO_o              => s_pa3_io_o,
      PA3_IO_T              => s_pa3_io_T,
      PA3_OUT               => s_pa3_out,
      PA3_IN                => s_pa3_in,
      FX3_PCLK              => FX3_PCLK,
      FX3_RESET_n           => FX3_RESET_n,
      FX3_INT_n             => FX3_INT_n,
      FX3_UART_TX           => FX3_UART_TX,
      FX3_UART_RX           => FX3_UART_RX,
      FX3_DQ_i              => s_fx3_dq_i,
      FX3_DQ_o              => s_fx3_dq_o,
      FX3_DQ_T              => s_fx3_dq_T,
      FX3_CTL_i             => s_fx3_ctl_i,
      FX3_CTL_o             => s_fx3_ctl_o,
      FX3_CTL_T             => s_fx3_ctl_T,
      GBT_RESET_n           => GBT_RESET_n,
      GBTX0_RXRDY           => GBTX0_RXRDY,
      GBTX0_TXRDY           => GBTX0_TXRDY,
      GBTX0_TXDATAVALID_A   => sGbtx0_txdatavalid_A,
      GBTX0_TXDATAVALID_B   => sGbtx0_txdatavalid_B,
      GBTX0_TXDATAVALID_C   => sGbtx0_txdatavalid_C,
      GBTX0_TXDATAVALID_A_T => sGbtx0_txdatavalid_A_T,
      GBTX0_TXDATAVALID_B_T => sGbtx0_txdatavalid_B_T,
      GBTX0_TXDATAVALID_C_T => sGbtx0_txdatavalid_C_T,
      GBTX0_RXDATAVALID_A   => GBTX0_RXDATAVALID_A,
      GBTX0_RXDATAVALID_B   => GBTX0_RXDATAVALID_B,
      GBTX0_RXDATAVALID_C   => GBTX0_RXDATAVALID_C,
      GBTX0_DOUT            => s_gbtx0_dout,
      GBTX0_DIN             => s_gbtx0_din,
      GBTX0_DCLK            => s_gbtx0_dclk,
      GBTX1_TXRDY           => GBTX1_TXRDY,
      GBTX1_TXDATAVALID_A   => sGbtx1_txdatavalid_A,
      GBTX1_TXDATAVALID_B   => sGbtx1_txdatavalid_B,
      GBTX1_TXDATAVALID_C   => sGbtx1_txdatavalid_C,
      GBTX1_TXDATAVALID_A_T => sGbtx1_txdatavalid_A_T,
      GBTX1_TXDATAVALID_B_T => sGbtx1_txdatavalid_B_T,
      GBTX1_TXDATAVALID_C_T => sGbtx1_txdatavalid_C_T,
      GBTX1_DIN             => s_gbtx1_din,
      GBTX2_RXRDY           => GBTX2_RXRDY,
      GBTX2_TXRDY           => GBTX2_TXRDY,
      GBTX2_TXDATAVALID_A   => sGbtx2_txdatavalid_A,
      GBTX2_TXDATAVALID_B   => sGbtx2_txdatavalid_B,
      GBTX2_TXDATAVALID_C   => sGbtx2_txdatavalid_C,
      GBTX2_TXDATAVALID_A_T => sGbtx2_txdatavalid_A_T,
      GBTX2_TXDATAVALID_B_T => sGbtx2_txdatavalid_B_T,
      GBTX2_TXDATAVALID_C_T => sGbtx2_txdatavalid_C_T,
      GBTX2_RXDATAVALID_A   => GBTX2_RXDATAVALID_A,
      GBTX2_RXDATAVALID_B   => GBTX2_RXDATAVALID_B,
      GBTX2_RXDATAVALID_C   => GBTX2_RXDATAVALID_C,
      GBTX2_DOUT            => s_gbtx2_dout,
      GBTX2_DIN             => s_gbtx2_din,
      GBTX2_DCLK            => s_gbtx2_dclk,
      PU1_SDA_WRITE         => PU1_SDA_WRITE,
      PU1_SDA_READ          => PU1_SDA_READ,
      PU1_SCL_WRITE         => PU1_SCL_WRITE,
      PU1_SCL_READ          => PU1_SCL_READ,
      PU1_SDA_AUX_WRITE     => PU1_SDA_AUX_WRITE,
      PU1_SDA_AUX_READ      => PU1_SDA_AUX_READ,
      PU1_SCL_AUX_WRITE     => PU1_SCL_AUX_WRITE,
      PU1_SCL_AUX_READ      => PU1_SCL_AUX_READ,
      PU2_SDA_WRITE         => PU2_SDA_WRITE,
      PU2_SDA_READ          => PU2_SDA_READ,
      PU2_SCL_WRITE         => PU2_SCL_WRITE,
      PU2_SCL_READ          => PU2_SCL_READ,
      PU2_SDA_AUX_WRITE     => PU2_SDA_AUX_WRITE,
      PU2_SDA_AUX_READ      => PU2_SDA_AUX_READ,
      PU2_SCL_AUX_WRITE     => PU2_SCL_AUX_WRITE,
      PU2_SCL_AUX_READ      => PU2_SCL_AUX_READ,
      AUX_OUT               => s_aux_out,
      AUX_IN                => s_aux_in,
      LED                   => LED,
      DIPSWITCH             => DIPSWITCH
      );

  ------------------------------------------------------------------------------
  -- IO IPs to convert external ports to logical signals
  ------------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- AUX outputs & inputs
  -----------------------------------------------------------------------------
  INST_IOBUF_AUX0p : IOBUF
    port map(
      O  => open,                -- Buffer output
      IO => AUX_dp(0),  -- Buffer inout port (connect directly to top-level port)
      I  => s_aux_out(0),                -- Buffer input
      T  => '0'   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_AUX0n : IOBUF
    port map(
      O  => open,                -- Buffer output
      IO => AUX_dn(0),  -- Buffer inout port (connect directly to top-level port)
      I  => s_aux_out(1),                -- Buffer input
      T  => '0'   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_AUX2p : IOBUF
    port map(
      O  => open,                -- Buffer output
      IO => AUX_dp(2),  -- Buffer inout port (connect directly to top-level port)
      I  => s_aux_out(2),                -- Buffer input
      T  => '0'   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_AUX2n : IOBUF
    port map(
      O  => open,                -- Buffer output
      IO => AUX_dn(2),  -- Buffer inout port (connect directly to top-level port)
      I  => s_aux_out(3),                -- Buffer input
      T  => '0'   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_AUX1p : IOBUF
    port map(
      O  => s_aux_in(0),                -- Buffer output
      IO => AUX_dp(1),  -- Buffer inout port (connect directly to top-level port)
      I  => '0',                -- Buffer input
      T  => '1'   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_AUX1n : IOBUF
    port map(
      O  => s_aux_in(1),                -- Buffer output
      IO => AUX_dn(1),  -- Buffer inout port (connect directly to top-level port)
      I  => '0',                -- Buffer input
      T  => '1'   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_AUX3p : IOBUF
    port map(
      O  => s_aux_in(2),                -- Buffer output
      IO => AUX_dp(3),  -- Buffer inout port (connect directly to top-level port)
      I  => '0',                -- Buffer input
      T  => '1'   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_AUX3n : IOBUF
    port map(
      O  => s_aux_in(3),                -- Buffer output
      IO => AUX_dn(3),  -- Buffer inout port (connect directly to top-level port)
      I  => '0',                -- Buffer input
      T  => '1'   -- 3-state enable signal, 1=input, 0=output
      );

  -----------------------------------------------------------------------------
  -- Pin Header
  -----------------------------------------------------------------------------
  s_pinheader_T(4 downto 0) <= (others => '0');  -- output
  s_pinheader_T(9 downto 5) <= (others => '1');  -- input
  s_pinheader_o(9 downto 5) <= (others => '0');
  Gen_Pinheader: for i in 0 to 9 generate
    INST_IOBUF_PINHEADER : IOBUF
      port map(
        O  => s_pinheader_i(i),                -- Buffer output
        IO => PINHEADER(i),  -- Buffer inout port (connect directly to top-level port)
        I  => s_pinheader_o(i),                -- Buffer input
        T  => s_pinheader_T(i)   -- 3-state enable signal, 1=input, 0=output
        );
  end generate Gen_Pinheader;


  -----------------------------------------------------------------------------
  -- Clock output for debug
  -----------------------------------------------------------------------------
   CLK_OUT_dp<=sClkOut;
   sClkIn<=CLK_OUT_dn;

  -----------------------------------------------------------------------------
  -- Alpide
  -----------------------------------------------------------------------------
  ALPIDE_DATAPORT_GEN : for i in ALPIDE_DATA_GPIO_dp'range generate
    INST_ALPIDE_DATAPORTi : OBUFDS
      port map(
        I  => s_alpide_data_gpio(i),
        O  => ALPIDE_DATA_GPIO_dp(i),
        OB => ALPIDE_DATA_GPIO_dn(i)
        );
  end generate ALPIDE_DATAPORT_GEN;

  alpide_dctrl_generate : for i in ALPIDE_DCTRL_D'range generate
    INST_OBUF_DCTRL : OBUFT
      port map(
        O => ALPIDE_DCTRL_D(i),         -- Buffer output
        I => s_alpide_dctrl_o(i),       -- Buffer input
        T => s_alpide_dctrl_t      -- 3-state enable signal, 1=input, 0=output
        );

    INST_IBUF_DCTRL : IBUF
      port map(
        O => s_alpide_dctrl_i(i),       -- Buffer output
        I => ALPIDE_DCTRL_R(i)          -- Buffer input
        );

    INST_OBUF_DCTRL_DEINST : OBUF
      port map(
        O => ALPIDE_DCTRL_DE(i),        -- Buffer output
        I => s_alpide_dctrl_de(i)       -- Buffer input
        );
    s_alpide_dctrl_de <= (others => not s_alpide_dctrl_t);
  end generate alpide_dctrl_generate;

  alpide_dclk_generate : for i in ALPIDE_DCLK_EN'range generate
    -- only clock A is propagated
    INST_OBUF_DCLK_a_i : OBUFT
      port map(
        O => ALPIDE_DCLK_A(i),          -- Buffer output
        I => s_alpide_dclk_a(i),        -- Buffer input
        T => s_alpide_dclk_a_t(i)
        );

    INST_OBUF_DCLK_EN_i : OBUF
      port map(
        O => ALPIDE_DCLK_EN(i),         -- Buffer output
        I => s_alpide_dclk_en(i)        -- Buffer input
        );
  end generate alpide_dclk_generate;

  -------------------------------------------------------------------------------
  -- SCA, SCA4
  -------------------------------------------------------------------------------
  INST_IOBUF_SCA_I2C_SDA : IOBUF
    port map(
      O  => s_sca_sda_i,                -- Buffer output
      IO => SCA_SDA,  -- Buffer inout port (connect directly to top-level port)
      I  => s_sca_sda_o,                -- Buffer input
      T  => s_sca_sda_T   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_SCA_I2C_SCL : IOBUF
    port map(
      O  => s_sca_scl_i,                -- Buffer output
      IO => SCA_SCL,  -- Buffer inout port (connect directly to top-level port)
      I  => s_sca_scl_o,                -- Buffer input
      T  => s_sca_scl_T   -- 3-state enable signal, 1=input, 0=output
      );

  INST_IOBUF_SCA_I2C4 : IOBUF
    port map(
      O  => s_sca_sda4_i,               -- Buffer output
      IO => SCA_SDA4,  -- Buffer inout port (connect directly to top-level port)
      I  => s_sca_sda4_o,               -- Buffer input
      T  => s_sca_sda4_T   -- 3-state enable signal, 1=input, 0=output
      );

  -------------------------------------------------------------------------------
  -- PA3
  -------------------------------------------------------------------------------
  PA3_OUT_GEN : for i in PA3_OUT_dp'range generate
    INST_PA3_OUTi : OBUFDS
      port map(
        O  => PA3_OUT_dp(i),
        OB => PA3_OUT_dn(i),
        I  => s_pa3_out(i)
        );
  end generate PA3_OUT_GEN;

  PA3_IN_GEN : for i in PA3_IN_dp'range generate
    INST_PA3_INi : IBUFDS
      port map(
        O  => s_pa3_in(i),
        I  => PA3_IN_dp(i),
        IB => PA3_IN_dn(i)
        );
  end generate PA3_IN_GEN;

  PA3_IO_GEN : for i in PA3_IO'range generate
    INST_IOBUF_PA3_IO : IOBUF
      port map(
        O  => s_pa3_io_i(i),            -- Buffer output
        IO => PA3_IO(i),  -- Buffer inout port (connect directly to top-level port)
        I  => s_pa3_io_o(i),            -- Buffer input
        T  => s_pa3_io_T(i)   -- 3-state enable signal, 1=input, 0=output
        );
  end generate PA3_IO_GEN;
  -------------------------------------------------------------------------------
  -- FX3
  -------------------------------------------------------------------------------
  FX3DQ_GEN : for i in FX3_DQ'range generate
    INST_IOBUF_FX3DQi : IOBUF
      port map(
        O  => s_fx3_dq_i(i),            -- Buffer output
        IO => FX3_DQ(i),  -- Buffer inout port (connect directly to top-level port)
        I  => s_fx3_dq_o(i),            -- Buffer input
        T  => s_fx3_dq_T  -- 3-state enable signal, 1=input, 0=output
        );
  end generate FX3DQ_GEN;

  FX3CTL_GEN : for i in FX3_CTL'range generate
    INST_IOBUF_FX3CTLi : IOBUF
      port map(
        O  => s_fx3_ctl_i(i),           -- Buffer output
        IO => FX3_CTL(i),  -- Buffer inout port (connect directly to top-level port)
        I  => s_fx3_ctl_o(i),           -- Buffer input
        T  => s_fx3_ctl_T(i)   -- 3-state enable signal, 1=input, 0=output
        );
  end generate FX3CTL_GEN;

  -------------------------------------------------------------------------------
  -- GBTx0
  -------------------------------------------------------------------------------
  GBTX_D_GEN : for i in GBTX0_DIN_dp'range generate
    INST_GBTX_DOUTi : IBUFDS
      port map(
        O  => s_gbtx0_dout(i),
        I  => GBTX0_DOUT_dp(i),
        IB => GBTX0_DOUT_dn(i)
        );

    INST_GBTX_DINi : OBUFDS
      port map(
        O  => GBTX0_DIN_dp(i),
        OB => GBTX0_DIN_dn(i),
        I  => s_gbtx0_din(i)
        );
  end generate GBTX_D_GEN;

  GBTX_DCLK_GEN : for i in GBTX0_DCLK_dp'range generate
    INST_GBTX0_DCLK0 : IBUFDS
      port map(
        O  => s_gbtx0_dclk(i),
        I  => GBTX0_DCLK_dp(i),
        IB => GBTX0_DCLK_dn(i)
        );
  end generate GBTX_DCLK_GEN;

  INST_GBTX0_OBUFA : OBUFT
    port map(
      O => GBTX0_TXDATAVALID_A,
      I => sGbtx0_txdatavalid_A,
      T => sGbtx0_txdatavalid_A_T
      );

  INST_GBTX0_OBUFB : OBUFT
    port map(
      O => GBTX0_TXDATAVALID_B,
      I => sGbtx0_txdatavalid_B,
      T => sGbtx0_txdatavalid_B_T
      );

  INST_GBTX0_OBUFC : OBUFT
    port map(
      O => GBTX0_TXDATAVALID_C,
      I => sGbtx0_txdatavalid_C,
      T => sGbtx0_txdatavalid_C_T
      );

  -------------------------------------------------------------------------------
  -- GBTx1
  -------------------------------------------------------------------------------
  GBTX1_D_GEN : for i in GBTX1_DIN_dp'range generate
    INST_GBTX1_DINi : OBUFDS
      port map(
        O  => GBTX1_DIN_dp(i),
        OB => GBTX1_DIN_dn(i),
        I  => s_gbtx1_din(i)
        );
  end generate GBTX1_D_GEN;

  INST_GBTX1_OBUFA : OBUFT
    port map(
      O => GBTX1_TXDATAVALID_A,
      I => sGbtx1_txdatavalid_A,
      T => sGbtx1_txdatavalid_A_T
      );

  INST_GBTX1_OBUFB : OBUFT
    port map(
      O => GBTX1_TXDATAVALID_B,
      I => sGbtx1_txdatavalid_B,
      T => sGbtx1_txdatavalid_B_T
      );

  INST_GBTX1_OBUFC : OBUFT
    port map(
      O => GBTX1_TXDATAVALID_C,
      I => sGbtx1_txdatavalid_C,
      T => sGbtx1_txdatavalid_C_T
      );

  -------------------------------------------------------------------------------
  -- GBTx2
  -------------------------------------------------------------------------------
  GBTX2_D_GEN : for i in GBTX2_DIN_dp'range generate
    INST_GBTX2_DOUTi : IBUFDS
      port map(
        O  => s_gbtx2_dout(i),
        I  => GBTX2_DOUT_dp(i),
        IB => GBTX2_DOUT_dn(i)
        );

    INST_GBTX2_DINi : OBUFDS
      port map(
        O  => GBTX2_DIN_dp(i),
        OB => GBTX2_DIN_dn(i),
        I  => s_gbtx2_din(i)
        );
  end generate GBTX2_D_GEN;

  GBTX2_DCLK_GEN : for i in GBTX2_DCLK_dp'range generate
    INST_GBTX2_DCLK0 : IBUFDS
      port map(
        O  => s_gbtx2_dclk(i),
        I  => GBTX2_DCLK_dp(i),
        IB => GBTX2_DCLK_dn(i)
        );
  end generate GBTX2_DCLK_GEN;

  INST_GBTX2_OBUFA : OBUFT
    port map(
      O => GBTX2_TXDATAVALID_A,
      I => sGbtx2_txdatavalid_A,
      T => sGbtx2_txdatavalid_A_T
      );

  INST_GBTX2_OBUFB : OBUFT
    port map(
      O => GBTX2_TXDATAVALID_B,
      I => sGbtx2_txdatavalid_B,
      T => sGbtx2_txdatavalid_B_T
      );

  INST_GBTX2_OBUFC : OBUFT
    port map(
      O => GBTX2_TXDATAVALID_C,
      I => sGbtx2_txdatavalid_C,
      T => sGbtx2_txdatavalid_C_T
      );

  -------------------------------------------------------------------------------
  -- SCA GPIO
  -------------------------------------------------------------------------------
  SCA_GPIO_GEN : for i in SCA_GPIO'range generate    -- range 11 downto 4
    INST_IOBUF_SCAGPIOi : IOBUF
      port map(
        O  => s_scaGpio_i(i),           -- Buffer output
        IO => SCA_GPIO(i),  -- Buffer inout port (connect directly to top-level port)
        I  => s_scaGpio_o(i),           -- Buffer input
        T  => s_scaGpio_T(i)   -- 3-state enable signal, 1=input, 0=output
        );
  end generate SCA_GPIO_GEN;

  SCA_GPIO_TMR_GEN : for i in SCA_GPIO_A'range generate   -- range 3 downto 0
    SCA_GPIO_0 : if i = 0 generate

      -- synthesis translate_off
      -- set for simulation in modelsim/questasim (not handled properly => might provoke a 'X')
      SCA_GPIO_A(i) <= 'Z';
      SCA_GPIO_B(i) <= 'Z';
      SCA_GPIO_C(i) <= 'Z';
      -- synthesis translate_on

      INST_IBUF_SCAGPIO_Ai : IBUF
        port map(
          O => s_scaGpio_A_i(i),        -- Buffer output
          I => SCA_GPIO_A(i)  -- Buffer in port (connect directly to top-level port)
          );

      INST_IBUF_SCAGPIO_Bi : IBUF
        port map(
          O => s_scaGpio_B_i(i),        -- Buffer output
          I => SCA_GPIO_B(i)  -- Buffer in port (connect directly to top-level port)
          );

      INST_IBUF_SCAGPIO_Ci : IBUF
        port map(
          O => s_scaGpio_C_i(i),        -- Buffer output
          I => SCA_GPIO_C(i)  -- Buffer in port (connect directly to top-level port)
          );
    end generate SCA_GPIO_0;

    SCA_GPIO_i : if i /= 0 generate
      INST_IOBUF_SCAGPIO_Ai : IOBUF
        port map(
          O  => s_scaGpio_A_i(i),       -- Buffer output
          IO => SCA_GPIO_A(i),  -- Buffer inout port (connect directly to top-level port)
          I  => s_scaGpio_o(i),         -- Buffer input
          T  => s_scaGpio_T(i)  -- 3-state enable signal, 1=input, 0=output
          );

      INST_IOBUF_SCAGPIO_Bi : IOBUF
        port map(
          O  => s_scaGpio_B_i(i),       -- Buffer output
          IO => SCA_GPIO_B(i),  -- Buffer inout port (connect directly to top-level port)
          I  => s_scaGpio_o(i),         -- Buffer input
          T  => s_scaGpio_T(i)  -- 3-state enable signal, 1=input, 0=output
          );

      INST_IOBUF_SCAGPIO_Ci : IOBUF
        port map(
          O  => s_scaGpio_C_i(i),       -- Buffer output
          IO => SCA_GPIO_C(i),  -- Buffer inout port (connect directly to top-level port)
          I  => s_scaGpio_o(i),         -- Buffer input
          T  => s_scaGpio_T(i)  -- 3-state enable signal, 1=input, 0=output
          );

    end generate SCA_GPIO_i;
  end generate SCA_GPIO_TMR_GEN;

-- some fixed pattern for now./tes  
  s_scaGpio_T <= "000000111111";  -- lower 6 are input, upper 6 are output: reset, others: outputs
  with s_scaGpio_i(5 downto 4) select s_scaGpio_temp <=
    s_scaGpio_A_i when "00",      -- forwards the A-inputs
    s_scaGpio_B_i when "01",      -- forwards the B-inputs
    s_scaGpio_C_i when "10",      -- forwards the C-inputs
    ((s_scaGpio_A_i xor s_scaGpio_B_i)xor s_scaGpio_C_i) when "11"; -- Maximize error detect using minority vote on TMR signals
  s_scaGpio_o <= s_scaGpio_i(5 downto 4)&s_scaGpio_temp&"000000"; -- upper 6 equals lower 6.

end architecture Behavior;
