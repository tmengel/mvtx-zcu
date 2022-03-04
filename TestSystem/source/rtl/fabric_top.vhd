-------------------------------------------------------------------------------
-- Title      : Fabric Top Level
-- Project    : ALICE ITS RUv1
-------------------------------------------------------------------------------
-- File       : fabric_top.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-03-27
-- Last update: 2019-10-15
-- Platform   : Xilinx Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: IPs to convert the various I/O ports to fabric logic signals
-------------------------------------------------------------------------------
-- 2017-03-27  1.0      jschamba  Created
-- 2018-03-23  1.1      ML        Configurable number of masters
-- 2018-04-06  1.2      ML        Added OS code
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.intercon_pkg.all;
use work.fabric_top_pkg.all;
use work.ws_master_pkg.all;
use work.i2c_pkg.all;
use work.xpm_cdc_components_pkg.all;

entity fabric_top is
  generic(
    USE_DEBUG : string                        := "FALSE";
    HASH_CODE : std_logic_vector(31 downto 0) := (others => '0');
    DATE      : std_logic_vector(47 downto 0) := (others => '0');
    OS        : std_logic_vector(15 downto 0) := (others => '0')
    );
  port(
    PUSHBUTTON            : in  std_logic_vector(3 downto 0);
    HEADER_i              : in  std_logic_vector(4 downto 0);
    HEADER_o              : out std_logic_vector(4 downto 0);
    CLKOUT                : out std_logic;
    CLKIN                 : in  std_logic;
    -- Clocks
    CLK150                : in  std_logic;
    CLK600                : in  std_logic;
    CLK75                 : in  std_logic;
    CLK100                : in  std_logic;
    CLK_LOCKED            : in  std_logic;
    REFCLK1_226_dp        : in  std_logic;
    REFCLK1_226_dn        : in  std_logic;
    REFCLK1_127_dp        : in  std_logic;
    REFCLK1_127_dn        : in  std_logic;
    --
    -- Alpide signals
    ALPIDE_DCLK_A         : out std_logic_vector(4 downto 0);
    ALPIDE_DCLK_B         : in  std_logic_vector(4 downto 0);
    ALPIDE_DCLK_C         : in  std_logic_vector(4 downto 0);
    ALPIDE_DCLK_EN        : out std_logic_vector(4 downto 0);
    ALPIDE_DCLK_A_T       : out std_logic_vector(4 downto 0);
    ALPIDE_DCTRL_O        : out std_logic_vector(4 downto 0);
    ALPIDE_DCTRL_T        : out std_logic;
    ALPIDE_DCTRL_I        : in  std_logic_vector(4 downto 0);
    ALPIDE_DATA_MGT_dp    : in  std_logic_vector(27 downto 0);
    ALPIDE_DATA_MGT_dn    : in  std_logic_vector(27 downto 0);
    ALPIDE_DATA_GPIO      : out std_logic_vector(27 downto 0);
    --
    -- I2C to GBTx
    GBTX_SCL_i            : in  std_logic;
    GBTX_SCL_o            : out std_logic;
    GBTX_SCL_T            : out std_logic;
    GBTX_SDA_i            : in  std_logic;
    GBTX_SDA_o            : out std_logic;
    GBTX_SDA_T            : out std_logic;
    --
    -- I2C from SCA
    SCA_SCL               : in  std_logic;
    SCA_SDA_i             : in  std_logic;
    SCA_SDA_o             : out std_logic;
    SCA_SDA_T             : out std_logic;
    --
    -- SPI slave
    SCA_SPI_MOSI          : in  std_logic;
    SCA_SPI_MISO          : out std_logic;
    SCA_SPI_TCK           : in  std_logic;
    SCA_SPI_SS0           : in  std_logic;
    --
    -- GPIO from SCA
    SCA_GPIO_A_i          : in  std_logic_vector(3 downto 0);
    SCA_GPIO_B_i          : in  std_logic_vector(3 downto 0);
    SCA_GPIO_C_i          : in  std_logic_vector(3 downto 0);
    --
    -- PA3 interface
    PA3_IO_i              : in  std_logic_vector(11 downto 0);
    PA3_IO_o              : out std_logic_vector(11 downto 0);
    PA3_IO_T              : out std_logic_vector(11 downto 0);
    PA3_OUT               : out std_logic_vector(4 downto 0);
    PA3_IN                : in  std_logic_vector(9 downto 5);
    --
    -- FX3
    FX3_PCLK              : out std_logic;
    FX3_RESET_n           : out std_logic;
    FX3_INT_n             : out std_logic;
    FX3_UART_TX           : in  std_logic;
    FX3_UART_RX           : out std_logic;
    FX3_DQ_i              : in  std_logic_vector(31 downto 0);
    FX3_DQ_o              : out std_logic_vector(31 downto 0);
    FX3_DQ_T              : out std_logic;
    FX3_CTL_i             : in  std_logic_vector(12 downto 0);
    FX3_CTL_o             : out std_logic_vector(12 downto 0);
    FX3_CTL_T             : out std_logic_vector(12 downto 0);
    --
    -- main GBTx
    GBT_RESET_n           : out std_logic;
    GBTX0_RXRDY           : in  std_logic;
    GBTX0_TXRDY           : in  std_logic;
    GBTX0_TXDATAVALID_A   : out std_logic;
    GBTX0_TXDATAVALID_B   : out std_logic;
    GBTX0_TXDATAVALID_C   : out std_logic;
    GBTX0_TXDATAVALID_A_T : out std_logic;
    GBTX0_TXDATAVALID_B_T : out std_logic;
    GBTX0_TXDATAVALID_C_T : out std_logic;
    GBTX0_RXDATAVALID_A   : in  std_logic;
    GBTX0_RXDATAVALID_B   : in  std_logic;
    GBTX0_RXDATAVALID_C   : in  std_logic;
    GBTX0_DOUT            : in  std_logic_vector(9 downto 0);
    GBTX0_DIN             : out std_logic_vector(9 downto 0);
    GBTX0_DCLK            : in  std_logic_vector(1 downto 0);
    --
    -- secondary GBTx
    GBTX1_TXRDY           : in  std_logic;
    GBTX1_TXDATAVALID_A   : out std_logic;
    GBTX1_TXDATAVALID_B   : out std_logic;
    GBTX1_TXDATAVALID_C   : out std_logic;
    GBTX1_TXDATAVALID_A_T : out std_logic;
    GBTX1_TXDATAVALID_B_T : out std_logic;
    GBTX1_TXDATAVALID_C_T : out std_logic;
    GBTX1_DIN             : out std_logic_vector(9 downto 0);
    --
    -- trigger GBTx
    GBTX2_RXRDY           : in  std_logic;
    GBTX2_TXRDY           : in  std_logic;
    GBTX2_TXDATAVALID_A   : out std_logic;
    GBTX2_TXDATAVALID_B   : out std_logic;
    GBTX2_TXDATAVALID_C   : out std_logic;
    GBTX2_TXDATAVALID_A_T : out std_logic;
    GBTX2_TXDATAVALID_B_T : out std_logic;
    GBTX2_TXDATAVALID_C_T : out std_logic;
    GBTX2_RXDATAVALID_A   : in  std_logic;
    GBTX2_RXDATAVALID_B   : in  std_logic;
    GBTX2_RXDATAVALID_C   : in  std_logic;
    GBTX2_DOUT            : in  std_logic_vector(9 downto 0);
    GBTX2_DIN             : out std_logic_vector(9 downto 0);
    GBTX2_DCLK            : in  std_logic_vector(1 downto 0);
    --
    -- Power Board
    PU1_SDA_WRITE         : out std_logic;
    PU1_SDA_READ          : in  std_logic;
    PU1_SCL_WRITE         : out std_logic;
    PU1_SCL_READ          : in  std_logic;
    PU1_SDA_AUX_WRITE     : out std_logic;
    PU1_SDA_AUX_READ      : in  std_logic;
    PU1_SCL_AUX_WRITE     : out std_logic;
    PU1_SCL_AUX_READ      : in  std_logic;
    --
    PU2_SDA_WRITE         : out std_logic;
    PU2_SDA_READ          : in  std_logic;
    PU2_SCL_WRITE         : out std_logic;
    PU2_SCL_READ          : in  std_logic;
    PU2_SDA_AUX_WRITE     : out std_logic;
    PU2_SDA_AUX_READ      : in  std_logic;
    PU2_SCL_AUX_WRITE     : out std_logic;
    PU2_SCL_AUX_READ      : in  std_logic;
    --
    -- MISC
    AUX_OUT               : out std_logic_vector(3 downto 0);
    AUX_IN                : in  std_logic_vector(3 downto 0);
    LED                   : out std_logic_vector(3 downto 0);
    DIPSWITCH             : in  std_logic_vector(9 downto 0)
    );

end entity fabric_top;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture RTL of fabric_top is

  component watchdog is
    generic(
      TIMEOUT_BIT_WIDTH : integer);
    port(
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      stb_i          : in  std_logic;
      cyc_i          : in  std_logic;
      err_o          : out std_logic;
      ACTUAL_STATE_O : out std_logic_vector(TIMEOUT_BIT_WIDTH - 1 downto 0);
      ACTUAL_STATE_I : in  std_logic_vector(TIMEOUT_BIT_WIDTH - 1 downto 0);
      timeout_i      : in  std_logic_vector(TIMEOUT_BIT_WIDTH - 1 downto 0));
  end component watchdog;

  signal s_gbtx1_txdatavalid_A : std_logic;
  signal s_gbtx1_txdatavalid_B : std_logic;
  signal s_gbtx1_txdatavalid_C : std_logic;
  signal s_gbtx2_txdatavalid_A : std_logic;
  signal s_gbtx2_txdatavalid_B : std_logic;
  signal s_gbtx2_txdatavalid_C : std_logic;

  -----------------------------------------------------------------------------
  -- ALPIDE DCLK
  -----------------------------------------------------------------------------

  signal s_alpide_dclk_t, s_alpide_dclk_t_out : std_logic_vector(14 downto 0);
  signal s_alpide_dclk_t_from_control         : std_logic_vector(4 downto 0);
  constant C_ALPIDE_DCLK_TRISTATE             : std_logic                    := '1';
  constant C_ALPIDE_DCLK_EN                   : std_logic_vector(4 downto 0) := (others => '1');

  signal sCtr   : unsigned(27 downto 0) := x"0000000";
  signal LEDcnt : std_logic_vector(3 downto 0);

  signal sFifoGbtx2dout        : std_logic_vector(80 downto 0);
  signal s_gbtx0_tx_fifo_rdclk : std_logic;
  signal px_clk2               : std_logic;

  -- signals for GBTx handler
  signal s_gbtx_tx_datapath_data                         : std_logic_vector(80 downto 0);
  signal s_gbtx_tx_datapath_strobe                       : std_logic;
  signal s_gbtx_tx_datapath_rd, s_gbtx_tx_datapath_empty : std_logic;

  signal s_gbtx_tx_wishbone_data                                     : std_logic_vector(80 downto 0);
  signal s_gbtx0_txdatavalid_A                                       : std_logic;
  signal s_gbtx0_txdatavalid_B                                       : std_logic;
  signal s_gbtx0_txdatavalid_C                                       : std_logic;
  signal s_gbtx_tx_wishbone_fifo_empty, s_gbtx_tx_wishbone_fifo_rd   : std_logic;
  signal s_gbtx_tx_wishbone_fifo_empty_d1, s_gbtx_tx_wishbone_strobe : std_logic;

  signal s_gbtx0_tx_data   : std_logic_vector(80 downto 0);
  signal s_gbtx0_tx_strobe : std_logic;

  signal s_gbtx0_rx_clk  : std_logic;
  signal s_gbtx0_rx_data : std_logic_vector(80 downto 0);
  signal s_gbtx0_strobe  : std_logic;
  signal s_gbtx0_ready   : std_logic;

  signal sGbtx0RxRdy_n : std_logic;
  signal sGbtx2RxRdy_n : std_logic;

  -- Wishbone bus signals
  signal sWB_Clk             : std_logic;
  signal sWB_Rst             : std_logic;
  signal s_wbm_wbm_i         : wbm_i_type;
  signal s_wbm_wbm_o         : wbm_o_type;
  signal s_wbm_wbm_o_unused1 : wbm_o_type;
  signal s_wbm_wbm_o_unused2 : wbm_o_type;
  signal s_can_wbm_wbm_i     : wbm_i_type;
  signal s_can_wbm_wbm_o     : wbm_o_type;
  signal s_can_wbm_o_unused1 : wbm_o_type;
  signal s_can_wbm_o_unused2 : wbm_o_type;
  signal s_wbs_wbs_i         : t_wbs_i_array(0 to WB_SLAVE_NUMBER -1);
  signal s_wbs_wbs_o         : t_wbs_o_array(0 to WB_SLAVE_NUMBER -1);
  signal s_wbs_wbs_o_unused1 : wbs_o_type;
  signal s_wbs_wbs_o_unused2 : wbs_o_type;
  signal s_can_wbs_o_unused1 : wbs_o_type;
  signal s_can_wbs_o_unused2 : wbs_o_type;
  signal s_can_wbs_o_unused3 : wbs_o_type;
  signal s_can_wbs_o_unused4 : wbs_o_type;

  -- constant for wb arbiter
  constant C_WB_ARBITER_GRANT_WIDTH : natural := integer(ceil(log2(real(WB_MASTER_NUMBER))));
  signal s_wb_arbiter_count         : std_logic_vector(C_WB_ARBITER_GRANT_WIDTH-1 downto 0);
  signal s_wd_stb                   : std_logic;
  signal s_wd_cyc                   : std_logic;
  signal s_wd_err                   : std_logic;
  signal s_actual_state             : std_logic_vector(c_WD_TIMEOUT_WIDTH-1 downto 0);

  -- signals for USB data port 0 and 1
  signal s_dp0_dt             : std_logic_vector(GPIF_WIDTH - 1 downto 0);
  signal s_dp0_epty, s_dp0_rd : std_logic;
  signal s_dp0_overflow       : std_logic;

  signal s_dp1_dt             : std_logic_vector(GPIF_WIDTH - 1 downto 0);
  signal s_dp1_wr, s_dp1_full : std_logic;
  signal s_dp1_overflow       : std_logic;

  signal s_USB_dp0_dt                 : std_logic_vector(GPIF_WIDTH-1 downto 0);
  signal s_USB_dp0_epty, s_USB_dp0_rd : std_logic;
  signal s_USB_dp0_overflow           : std_logic;

  signal s_USB_dp1_dt                 : std_logic_vector(GPIF_WIDTH-1 downto 0);
  signal s_USB_dp1_wr, s_USB_dp1_full : std_logic;
  signal s_USB_dp1_overflow           : std_logic;

  signal s_dpo2_producer_select : std_logic_vector(3 downto 0) := (others => '0');
  signal s_dpo3_producer_select : std_logic_vector(3 downto 0) := (others => '0');


  -- Signals between CAN HLP and wishbone master
  signal s_CAN_dp0_dt   : std_logic_vector(31 downto 0);
  signal s_CAN_dp0_epty : std_logic;
  signal s_CAN_dp0_rd   : std_logic;
  signal s_CAN_dp1_dt   : std_logic_vector(31 downto 0);
  signal s_CAN_dp1_full : std_logic;
  signal s_CAN_dp1_wr   : std_logic;

  signal s_sca_reset                                   : std_logic_vector(2 downto 0);
  signal RST100, RST40                                 : std_logic;
  signal RST75                                         : std_logic;
  signal RST40_CLKDIV, RST40_CLKDIV_2ND, RST160_CLKDIV : std_logic;
  signal RST_GBTX0RXCLK                                : std_logic;

  -- Alpide control signals

  signal sRstStrobe : std_logic;

  signal sPa3FifoClk : std_logic;

  -- mgt_test signals
  signal sLinkDwnLatch_rst : std_logic;
  signal sLinkStatus       : std_logic;
  signal sLinkDwnLatch     : std_logic;
  signal sRstAll           : std_logic;
  signal s_PA3_IO_i        : std_logic_vector(9 downto 0);
  signal s_dipswitch       : std_logic_vector(9 downto 0);
  signal s_pushbutton      : std_logic_vector(3 downto 0);
  signal s_PA3pushbutton   : std_logic_vector(3 downto 0);
  signal s_error_detect    : std_logic;

  -- I2C test slave
  signal sI2C_val              : std_logic_vector(7 downto 0);
  signal sI2C_data_valid       : std_logic;
  signal sI2C_data_from_master : std_logic_vector(7 downto 0);

  signal s_PA3clk       : std_logic;
  signal s_PA3clk_old   : std_logic;
  signal s_PA3clkEdge   : std_logic;
  signal s_CLK100cnt    : unsigned(15 downto 0);
  signal s_EdgeCnt      : unsigned(15 downto 0);
  signal s_EdgeCntTotal : std_logic_vector(15 downto 0);

begin  -- architecture RTL

  -----------------------------------------------------------------------------
  -- Reset synchronization
  -----------------------------------------------------------------------------
  sRstStrobe <= not CLK_LOCKED;
  xpm_cdc_sync_rst_RST75 : xpm_cdc_sync_rst
    generic map(
      DEST_SYNC_FF   => 4,              -- Number of synchronizing FFs
      INIT           => 0,  -- Initialization value for synchronizing FFs
      SIM_ASSERT_CHK => 0)              -- Enable simulation messages
    port map(
      src_rst  => sRstStrobe,
      dest_clk => CLK75,
      dest_rst => RST75
      );

  xpm_cdc_sync_rst_RST100 : xpm_cdc_sync_rst
    generic map(
      DEST_SYNC_FF   => 4,              -- Number of synchronizing FFs
      INIT           => 0,  -- Initialization value for synchronizing FFs
      SIM_ASSERT_CHK => 0)              -- Enable simulation messages
    port map(
      src_rst  => sRstStrobe,
      dest_clk => CLK100,
      dest_rst => RST100
      );


  -------------------------------------------------------------------------------
  -- DEBUG outputs
  -------------------------------------------------------------------------------

  -- generate counter to drive some output pins
  p_counter : process(CLK75) is
  begin
    if rising_edge(CLK75) then
      sCtr <= sCtr + 1;
    end if;
  end process p_counter;

  with sCtr(26 downto 25) select LEDcnt <=
    "0001" when "00",
    "0010" when "01",
    "0100" when "10",
    "1000" when "11";

  LED <= LEDcnt when DIPSWITCH = "0000000000" else PUSHBUTTON;

  -----------------------------------------------------------------------------
  -- Test Interfaces
  -----------------------------------------------------------------------------
  -- MGT loopbacks
  INST_mgt_example : entity work.mgt_example_wrapper
    port map (
      WB_CLK             => sWB_Clk,
      WB_RST             => sWB_Rst,
      MGT_WB_WBS_I       => s_wbs_wbs_i(WB_ADDB.MGT_TEST),
      MGT_WB_WBS_O       => s_wbs_wbs_o(WB_ADDB.MGT_TEST),
      DRP_WB_WBS_I       => s_wbs_wbs_i(WB_ADDB.DRP_CTRL),
      DRP_WB_WBS_O       => s_wbs_wbs_o(WB_ADDB.DRP_CTRL),
      mgtrefclk1_x0y4_dp => REFCLK1_127_dp,
      mgtrefclk1_x0y4_dn => REFCLK1_127_dn,
      mgtrefclk1_x1y2_dp => REFCLK1_226_dp,
      mgtrefclk1_x1y2_dn => REFCLK1_226_dn,
      gthrx_dp           => ALPIDE_DATA_MGT_dp,
      gthrx_dn           => ALPIDE_DATA_MGT_dn,
      clk150             => CLK150,
      clk600             => CLK600,
      clk75              => CLK75,
      gpio               => ALPIDE_DATA_GPIO
      );

  -- GPIO Loopbacks
  INST_gpio_loopback : entity work.gpio_loopback
    port map(
      WB_CLK              => sWB_Clk,
      WB_RST              => sWB_Rst,
      WB_WBS_I            => s_wbs_wbs_i(WB_ADDB.LOOPBACK),
      WB_WBS_O            => s_wbs_wbs_o(WB_ADDB.LOOPBACK),
      SMA_OUT             => CLKOUT,
      SMA_IN              => CLKIN,
      HEADER_OUT          => HEADER_o,
      HEADER_IN           => HEADER_i,
      PA3_OUT             => PA3_OUT,
      PA3_IN              => PA3_IN,
      PA3_IO_i            => s_PA3_IO_i,
      ALPIDE_DCLK_A       => ALPIDE_DCLK_A,
      ALPIDE_DCLK_B       => ALPIDE_DCLK_B,
      ALPIDE_DCLK_C       => ALPIDE_DCLK_C,
      ALPIDE_DCLK_EN      => ALPIDE_DCLK_EN,
      ALPIDE_DCLK_A_T     => ALPIDE_DCLK_A_T,
      ALPIDE_DCTRL_O      => ALPIDE_DCTRL_O,
      ALPIDE_DCTRL_T      => ALPIDE_DCTRL_T,
      ALPIDE_DCTRL_I      => ALPIDE_DCTRL_I,
      AUX_OUT             => AUX_OUT,
      AUX_IN              => AUX_IN,
      PU1_SDA_WRITE       => PU1_SDA_WRITE,
      PU1_SDA_READ        => PU1_SDA_READ,
      PU1_SCL_WRITE       => PU1_SCL_WRITE,
      PU1_SCL_READ        => PU1_SCL_READ,
      PU1_SDA_AUX_WRITE   => PU1_SDA_AUX_WRITE,
      PU1_SDA_AUX_READ    => PU1_SDA_AUX_READ,
      PU1_SCL_AUX_WRITE   => PU1_SCL_AUX_WRITE,
      PU1_SCL_AUX_READ    => PU1_SCL_AUX_READ,
      PU2_SDA_WRITE       => PU2_SDA_WRITE,
      PU2_SDA_READ        => PU2_SDA_READ,
      PU2_SCL_WRITE       => PU2_SCL_WRITE,
      PU2_SCL_READ        => PU2_SCL_READ,
      PU2_SDA_AUX_WRITE   => PU2_SDA_AUX_WRITE,
      PU2_SDA_AUX_READ    => PU2_SDA_AUX_READ,
      PU2_SCL_AUX_WRITE   => PU2_SCL_AUX_WRITE,
      PU2_SCL_AUX_READ    => PU2_SCL_AUX_READ,
      INJECT_GLOBAL_ERROR => PUSHBUTTON(0),
      CLEAR_GLOBAL_ERROR  => PUSHBUTTON(1),
      ERROR_DETECT        => s_error_detect
      );

  -----------------------------------------------------------------------------
  -- Wishbone Interface
  -----------------------------------------------------------------------------
  -- Wishbone syscon
  INST_syscon : entity work.syscon
    port map(
      CLK_o  => sWB_Clk,
      RST_o  => sWB_Rst,
      EXTCLK => CLK75,
      EXTTST => RST75
      );

  -- Wishbone intercon
  INST_intercon_core : entity work.intercon_core
    generic map(
      G_WB_MASTER_NUMBER       => WB_MASTER_NUMBER,
      G_WB_SLAVE_NUMBER        => WB_SLAVE_NUMBER,
      G_WB_ARBITER_GRANT_WIDTH => C_WB_ARBITER_GRANT_WIDTH)
    port map(
      wbm_wbm_i(0)           => s_wbm_wbm_i,
      wbm_wbm_i(1)           => s_can_wbm_wbm_i,
      wbm_wbm_o(0)           => s_wbm_wbm_o,
      wbm_wbm_o(1)           => s_can_wbm_wbm_o,
      wbs_wbs_i              => s_wbs_wbs_i,
      wbs_wbs_o              => s_wbs_wbs_o,
      clk                    => sWB_Clk,
      reset                  => sWB_Rst,
      wd_stb                 => s_wd_stb,
      wd_cyc                 => s_wd_cyc,
      wd_err                 => s_wd_err,
      wb_arbiter_count_o     => s_wb_arbiter_count,
      wb_arbiter_count_voted => s_wb_arbiter_count
      );

  -- watchdog for the wishbone intercon
  INST_watchdog : watchdog
    generic map(
      TIMEOUT_BIT_WIDTH => c_WD_TIMEOUT_WIDTH)
    port map(
      clk_i          => sWB_Clk,
      rst_i          => sWB_Rst,
      stb_i          => s_wd_stb,
      cyc_i          => s_wd_cyc,
      err_o          => s_wd_err,
      actual_state_i => s_actual_state,
      actual_state_o => s_actual_state,
      timeout_i      => c_WD_TIMEOUT
      );
  s_PA3pushbutton <= PA3_IN(9 downto 7) & PA3_IN(5);
  s_pushbutton    <= PUSHBUTTON when PUSHBUTTON = s_PA3pushbutton else PUSHBUTTON xnor s_PA3pushbutton;
  s_dipswitch     <= DIPSWITCH  when DIPSWITCH = s_PA3_IO_i       else "0000000000";
  -- Wishbone Slave: Status
  INST_ws_status : entity work.ws_status
    generic map(
      HASH_CODE => HASH_CODE,
      DATE      => DATE,
      OS        => OS)
    port map(
      DIPSWITCH      => s_dipswitch,
      PUSHBUTTON     => s_pushbutton,
      WB_CLK         => sWB_Clk,
      WB_RST         => sWB_Rst,
      s_EdgeCntTotal => s_EdgeCntTotal,
      WB_WBS_I       => s_wbs_wbs_i(WB_ADDB.STATUS),
      WB_WBS_O       => s_wbs_wbs_o(WB_ADDB.STATUS)
      );



  -- Wishbone slave: i2c_gbt
  INST_i2c_gbt : entity work.i2c_gbt_wrapper
    port map (
      WB_CLK    => sWB_Clk,
      WB_RST    => sWB_Rst,
      WB_WBS_I  => s_wbs_wbs_i(WB_ADDB.I2CGBT),
      WB_WBS_O  => s_wbs_wbs_o(WB_ADDB.I2CGBT),
      SCL_PAD_i => GBTX_SCL_i,
      SCL_PAD_o => GBTX_SCL_o,
      SCL_PAD_T => GBTX_SCL_T,
      SDA_PAD_i => GBTX_SDA_i,
      SDA_PAD_o => GBTX_SDA_o,
      SDA_PAD_T => GBTX_SDA_T
      );

  -- Wishbone slave: wait (pseudo slave to hold wishbone active)
  INST_wishbone_wait : entity work.wishbone_wait
    port map(
      WB_CLK   => sWB_Clk,
      WB_RST   => sWB_Rst,
      WB_WBS_I => s_wbs_wbs_i(WB_ADDB.FW_WAIT),
      WB_WBS_O => s_wbs_wbs_o(WB_ADDB.FW_WAIT)
      );

  -- Wishbone Master: USB (also has a slave for status)
  INST_USB_wishbone_master : entity work.wishbone_master_tripleoutput
    generic map(
      ENABLE_DEBUG               => "False",
      MISMATCH_EN                => 0,
      G_MISMATCH_REGISTERED      => 0,
      G_SEE_MITIGATION_TECHNIQUE => 0,
      G_WBMSTR_MISMATCH_WIDTH    => 7,
      G_ADDITIONAL_MISMATCH      => 0
      )
    port map(
      WB_CLK         => sWB_Clk,
      WB_RST         => sWB_Rst,
      WB_WBM_I(0)    => s_wbm_wbm_i,
      WB_WBM_I(1)    => s_wbm_wbm_i,
      WB_WBM_I(2)    => s_wbm_wbm_i,
      WB_WBM_O(0)    => s_wbm_wbm_o,
      WB_WBM_O(1)    => s_wbm_wbm_o_unused1,
      WB_WBM_O(2)    => s_wbm_wbm_o_unused2,
      WB_WBS_I(0)    => s_wbs_wbs_i(WB_ADDB.MASTER),
      WB_WBS_I(1)    => s_wbs_wbs_i(WB_ADDB.MASTER),
      WB_WBS_I(2)    => s_wbs_wbs_i(WB_ADDB.MASTER),
      WB_WBS_O(0)    => s_wbs_wbs_o(WB_ADDB.MASTER),
      WB_WBS_O(1)    => s_wbs_wbs_o_unused1,
      WB_WBS_O(2)    => s_wbs_wbs_o_unused2,
      DP0_DT_I       => s_USB_dp0_dt,
      DP0_EPTY_I     => s_USB_dp0_epty,
      DP0_RD_O       => s_USB_dp0_rd,
      DP1_DT_O       => s_USB_dp1_dt,
      DP1_WR_O       => s_USB_dp1_wr,
      DP1_FULL_I     => s_USB_dp1_full,
      MISMATCH_O     => open,
      MISMATCH_2ND_O => open
      );

  INST_CAN_HLP_wishbone_master : entity work.wishbone_master_tripleoutput
    generic map(
      ENABLE_DEBUG               => "False",
      MISMATCH_EN                => 0,
      G_MISMATCH_REGISTERED      => 0,
      G_SEE_MITIGATION_TECHNIQUE => 0,
      G_WBMSTR_MISMATCH_WIDTH    => 7,
      G_ADDITIONAL_MISMATCH      => 0
      )
    port map(
      WB_CLK         => sWB_Clk,
      WB_RST         => sWB_Rst,
      WB_WBM_I(0)    => s_can_wbm_wbm_i,
      WB_WBM_I(1)    => s_can_wbm_wbm_i,
      WB_WBM_I(2)    => s_can_wbm_wbm_i,
      WB_WBM_O(0)    => s_can_wbm_wbm_o,
      WB_WBM_O(1)    => s_can_wbm_o_unused1,
      WB_WBM_O(2)    => s_can_wbm_o_unused2,
      WB_WBS_I(0)    => s_wbs_wbs_i(WB_ADDB.MASTER_CAN),
      WB_WBS_I(1)    => s_wbs_wbs_i(WB_ADDB.MASTER_CAN),
      WB_WBS_I(2)    => s_wbs_wbs_i(WB_ADDB.MASTER_CAN),
      WB_WBS_O(0)    => s_wbs_wbs_o(WB_ADDB.MASTER_CAN),
      WB_WBS_O(1)    => s_can_wbs_o_unused1,
      WB_WBS_O(2)    => s_can_wbs_o_unused2,
      DP0_DT_I       => s_CAN_dp0_dt,
      DP0_EPTY_I     => s_CAN_dp0_epty,
      DP0_RD_O       => s_CAN_dp0_rd,
      DP1_DT_O       => s_CAN_dp1_dt,
      DP1_FULL_I     => s_CAN_dp1_full,
      DP1_WR_O       => s_CAN_dp1_wr,
      MISMATCH_O     => open,
      MISMATCH_2ND_O => open
      );



  -------------------------------------------------------------------------------
  -- USB (FX3) Interface (DP2 and DP3 disabled for now)
  -------------------------------------------------------------------------------
  INST_usb_if : entity work.usb_if
    generic map(
      ENABLE_DEBUG               => "FALSE",
      DP_SELECT_WIDTH            => 4,
      MISMATCH_EN                => 0,
      MISMATCH_REGISTERED        => 0,
      G_SEE_MITIGATION_TECHNIQUE => 0
      )
    port map(
      WB_CLK               => sWB_Clk,
      WB_RST               => sWB_Rst,
      WB_WBS_I             => s_wbs_wbs_i(WB_ADDB.USB_IF),
      WB_WBS_O             => s_wbs_wbs_o(WB_ADDB.USB_IF),
      CLK                  => CLK100,
      RST                  => RST100,
      FX3_UART_RX          => FX3_UART_RX,
      FX3_UART_TX          => FX3_UART_TX,
      FX3_GPIF_II_DQ_i     => FX3_DQ_i,
      FX3_GPIF_II_DQ_o     => FX3_DQ_o,
      FX3_GPIF_II_DQ_T     => FX3_DQ_T,
      FX3_GPIF_II_CTL_i    => FX3_CTL_i,
      FX3_GPIF_II_CTL_o    => FX3_CTL_o,
      FX3_GPIF_II_CTL_T    => FX3_CTL_T,
      FX3_GPIF_II_PCLK     => FX3_PCLK,
      FX3_GPIF_II_INT_n    => FX3_INT_n,
      FX3_GPIF_II_RESET_n  => FX3_RESET_n,
      DP0_RDCLK_I          => sWB_Clk,
      DP0_DT_O             => s_USB_dp0_dt,
      DP0_EPTY_O           => s_USB_dp0_epty,
      DP0_RD_I             => s_USB_dp0_rd,
      DP1_WRCLK_I          => sWb_Clk,
      DP1_DT_I             => s_USB_dp1_dt,
      DP1_WR_I             => s_USB_dp1_wr,
      DP1_FULL_O           => s_USB_dp1_full,
      CLK_DP2_WR_I         => CLK75,
      DPO2_RST_WRCLK_I     => RST75,
      DPO2_DTI_I           => x"0000_0000",
      DPO2_FULL_O          => open,
      DPO2_ALMST_FULL_O    => open,
      DPO2_WR_I            => '0',
      DPO2_EPTY_O          => open,
      DPO2_DONE_O          => open,
      DPO2_PRODUCER_SELECT => s_dpo2_producer_select,
      CLK_DP3_WR_I         => CLK75,
      DPO3_RST_WRCLK_I     => RST75,
      DPO3_DTI_I           => x"0000_0000",
      DPO3_FULL_O          => open,
      DPO3_ALMST_FULL_O    => open,
      DPO3_WR_I            => '0',
      DPO3_EPTY_O          => open,
      DPO3_DONE_O          => open,
      DPO3_PRODUCER_SELECT => s_dpo3_producer_select
      );


  -------------------------------------------------------------------------------
  -- DCS CANbus HLP
  -------------------------------------------------------------------------------
  INST_CAN_HLP : entity work.can_hlp_top_tmr_wrapper
    port map(
      WB_CLK      => sWB_Clk,
      WB_RST      => sWB_Rst,
      WB_WBS_I(0) => s_wbs_wbs_i(WB_ADDB.SLAVE_CAN),
      WB_WBS_I(1) => s_wbs_wbs_i(WB_ADDB.SLAVE_CAN),
      WB_WBS_I(2) => s_wbs_wbs_i(WB_ADDB.SLAVE_CAN),
      WB_WBS_O(0) => s_wbs_wbs_o(WB_ADDB.SLAVE_CAN),
      WB_WBS_O(1) => s_can_wbs_o_unused3,
      WB_WBS_O(2) => s_can_wbs_o_unused4,
      DP0_DT_O    => s_CAN_dp0_dt,
      DP0_EPTY_O  => s_CAN_dp0_epty,
      DP0_RD_I    => s_CAN_dp0_rd,
      DP1_DT_I    => s_CAN_dp1_dt,
      DP1_FULL_O  => s_CAN_dp1_full,
      DP1_WR_I    => s_CAN_dp1_wr,
      CAN_NODE_ID => DIPSWITCH(9 downto 2),
      CAN_TX      => PA3_IO_o(9),
      CAN_RX      => PA3_IO_i(10)
      );

  -------------------------------------------------------------------------------
  -- GBT Interfaces
  -------------------------------------------------------------------------------
  INST_gbtx_controller_01 : entity work.gbtx_controller
    generic map(
      G_SEE_MITIGATION_TECHNIQUE     => 0,
      G_SEE_MITIGATION_TECHNIQUE_FSM => 0,
      USE_DEBUG                      => "FALSE",  -- "TRUE"
      G_MISMATCH_EN                  => 0,
      G_ADDITIONAL_MISMATCH          => 0,
      G_USE_GBTX1                    => 1)
    port map(
      WB_CLK              => sWB_CLK,
      WB_RST              => sWB_RST,
      --
      RST                 => '0',
      ARST                => (others => '0'),
      RST_GBTX_n          => open,
      --
      GBTX_RXRDY          => GBTX0_RXRDY,
      GBTX_DIN            => GBTX0_DIN,
      GBTX_DOUT           => GBTX0_DOUT,
      GBTX_DCLK           => GBTX0_DCLK,
      RX_DATAVALID_A      => GBTX0_RXDATAVALID_A,
      RX_DATAVALID_B      => GBTX0_RXDATAVALID_B,
      RX_DATAVALID_C      => GBTX0_RXDATAVALID_C,
      TX_DATAVALID_A      => s_gbtx0_txdatavalid_A,
      TX_DATAVALID_B      => s_gbtx0_txdatavalid_B,
      TX_DATAVALID_C      => s_gbtx0_txdatavalid_C,
      --
      GBTX1_DIN           => GBTX1_DIN,
      TX1_DATAVALID_A     => s_gbtx1_txdatavalid_A,
      TX1_DATAVALID_B     => s_gbtx1_txdatavalid_B,
      TX1_DATAVALID_C     => s_gbtx1_txdatavalid_C,
      --
      GBTX_RX_DATA        => open,
      GBTX_RX_STROBE      => open,
      GBTX_RX_CLK         => open,
      --
      GBTX_TX_DATA        => (others => '0'),
      GBTX_TX_STROBE      => '0',
      GBTX_TX_FIFO_RDCLK  => open,
      --
      GBTX1_TX_DATA       => (others => '0'),
      GBTX1_TX_STROBE     => '0',
      GBTX1_TX_FIFO_RDCLK => open
      );

  INST_gbtx_controller_2 : entity work.gbtx_controller
    generic map(
      G_SEE_MITIGATION_TECHNIQUE     => 0,
      G_SEE_MITIGATION_TECHNIQUE_FSM => 0,
      USE_DEBUG                      => "FALSE",
      G_MISMATCH_EN                  => 0,
      G_ADDITIONAL_MISMATCH          => 0,
      G_USE_GBTX1                    => 0)
    port map(
      WB_CLK              => sWB_CLK,
      WB_RST              => sWB_RST,
      --
      RST                 => '0',
      ARST                => (others => '0'),
      RST_GBTX_n          => open,
      --
      GBTX_RXRDY          => GBTX2_RXRDY,
      GBTX_DIN            => GBTX2_DIN,
      GBTX_DOUT           => GBTX2_DOUT,
      GBTX_DCLK           => GBTX2_DCLK,
      RX_DATAVALID_A      => GBTX2_RXDATAVALID_A,
      RX_DATAVALID_B      => GBTX2_RXDATAVALID_B,
      RX_DATAVALID_C      => GBTX2_RXDATAVALID_C,
      TX_DATAVALID_A      => s_gbtx2_txdatavalid_A,
      TX_DATAVALID_B      => s_gbtx2_txdatavalid_B,
      TX_DATAVALID_C      => s_gbtx2_txdatavalid_C,
      --
      GBTX1_DIN           => open,
      TX1_DATAVALID_A     => open,
      TX1_DATAVALID_B     => open,
      TX1_DATAVALID_C     => open,
      --
      GBTX_RX_DATA        => open,
      GBTX_RX_STROBE      => open,
      GBTX_RX_CLK         => open,
      --
      GBTX_TX_DATA        => (others => '0'),
      GBTX_TX_STROBE      => '0',
      GBTX_TX_FIFO_RDCLK  => open,
      --
      GBTX1_TX_DATA       => (others => '0'),
      GBTX1_TX_STROBE     => '0',
      GBTX1_TX_FIFO_RDCLK => open
      );
  -----------------------------------------------------------------------------
  -- minority voted tmr outputs for GBTx DATAVALID
  -----------------------------------------------------------------------------
  INST_mvtmr_output0 : entity work.mvtmr_output
    port map(
      TR0_i => s_gbtx0_txdatavalid_A,
      TR1_i => s_gbtx0_txdatavalid_B,
      TR2_i => s_gbtx0_txdatavalid_C,
      TR0_o => GBTX0_TXDATAVALID_A,
      TR0_T => GBTX0_TXDATAVALID_A_T,
      TR1_o => GBTX0_TXDATAVALID_B,
      TR1_T => GBTX0_TXDATAVALID_B_T,
      TR2_o => GBTX0_TXDATAVALID_C,
      TR2_T => GBTX0_TXDATAVALID_C_T
      );

  INST_mvtmr_output1 : entity work.mvtmr_output
    port map(
      TR0_i => s_gbtx1_txdatavalid_A,
      TR1_i => s_gbtx1_txdatavalid_B,
      TR2_i => s_gbtx1_txdatavalid_C,
      TR0_o => GBTX1_TXDATAVALID_A,
      TR0_T => GBTX1_TXDATAVALID_A_T,
      TR1_o => GBTX1_TXDATAVALID_B,
      TR1_T => GBTX1_TXDATAVALID_B_T,
      TR2_o => GBTX1_TXDATAVALID_C,
      TR2_T => GBTX1_TXDATAVALID_C_T
      );

  INST_mvtmr_output2 : entity work.mvtmr_output
    port map(
      TR0_i => s_gbtx2_txdatavalid_A,
      TR1_i => s_gbtx2_txdatavalid_B,
      TR2_i => s_gbtx2_txdatavalid_C,
      TR0_o => GBTX2_TXDATAVALID_A,
      TR0_T => GBTX2_TXDATAVALID_A_T,
      TR1_o => GBTX2_TXDATAVALID_B,
      TR1_T => GBTX2_TXDATAVALID_B_T,
      TR2_o => GBTX2_TXDATAVALID_C,
      TR2_T => GBTX2_TXDATAVALID_C_T
      );

  -- simple I2C slave for testing
  INST_I2C_slave : entity work.I2C_slave
    generic map (
      SLAVE_ADDR => "0101000"
      )
    port map (
      scl_i            => SCA_SCL,
      sda_i            => SCA_SDA_i,
      sda_o            => SCA_SDA_o,
      sda_T            => SCA_SDA_T,
      clk              => sWB_Clk,
      rst              => sWB_Rst,
      read_req         => open,
      data_to_master   => sI2C_val,
      data_valid       => sI2C_data_valid,
      data_from_master => sI2C_data_from_master
      );

  -- capture the output data from the simple I2C slave
  p_capture_i2c : process (sWB_Clk) is
  begin
    if rising_edge(sWB_Clk) then
      if sWB_Rst = '1' then
        sI2C_val <= x"de";
      else
        if sI2C_data_valid = '1' then
          sI2C_val <= sI2C_data_from_master;
        else
          sI2C_val <= sI2C_val;
        end if;
      end if;
    end if;
  end process p_capture_i2c;

  -----------------------------------------------------------------------------
  -- Unused ports
  -----------------------------------------------------------------------------

  p_PA3CLK : process (CLK100) is
  begin
    if rising_edge(CLK100) then
      s_CLK100cnt  <= s_CLK100cnt+1;
      s_PA3clk     <= PA3_IN(6);
      s_PA3clk_old <= s_PA3clk;
      s_PA3clkEdge <= (not s_PA3clk_old) and s_PA3clk;
      if s_CLK100cnt = 0 then
        s_EdgeCntTotal <= std_logic_vector(s_EdgeCnt);
        s_EdgeCnt      <= X"0000";
      elsif s_PA3clkEdge = '1' then s_EdgeCnt <= s_EdgeCnt + 1;
      end if;
    end if;
  end process p_PA3CLK;

  SCA_SPI_MISO <= '0';

  s_PA3_IO_i(8 downto 0) <= PA3_IO_i(8 downto 0);
  s_PA3_IO_i(9)          <= PA3_IO_i(11);
  PA3_IO_o(8 downto 0)   <= (others => '0');
  PA3_IO_o(11 downto 10) <= (others => '0');
  PA3_IO_T               <= (9      => '0', others => '1');  -- input except 9

  GBT_RESET_n <= '1';

end architecture RTL;
