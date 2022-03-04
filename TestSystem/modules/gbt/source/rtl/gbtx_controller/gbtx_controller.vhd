-------------------------------------------------------------------------------
-- Title      : GBTX controller
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_controller.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-25
-- Last update: 2018-10-11
-- Platform   : Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the GBTx handler and the relative wishbone slave
--              used to set the parameters for the data rx
--
--              The generic G_SEE_HARDENING_TECHNIQUE indicates how the FSM is
--              protected:
--                      0: no mitigation
--                      1: TMR with single voter (not implemented)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library work;
use work.intercon_pkg.all;
use work.tmr_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;
use work.xpm_cdc_components_pkg.all;

entity gbtx_controller is
  generic (
    G_SEE_MITIGATION_TECHNIQUE     : integer := 0;
    G_SEE_MITIGATION_TECHNIQUE_FSM : integer := 0;
    USE_DEBUG                      : string  := "TRUE";
    G_MISMATCH_EN                  : integer := 0;
    G_ADDITIONAL_MISMATCH          : integer := 0;
    G_USE_GBTX1                    : integer := 0
    );
  port (
    WB_CLK              : in  std_logic;
    WB_RST              : in  std_logic;
    --
    ---- general purpose signals
    RST                 : in  std_logic;
    ARST                : in  std_logic_vector(2 downto 0);
    RST_GBTX_n          : out std_logic;
    --
    -- GBTx signals
    GBTX_RXRDY          : in  std_logic;
    GBTX_DIN            : out std_logic_vector(C_GBTX_ELINKS_TX-1 downto 0);
    GBTX_DOUT           : in  std_logic_vector(C_GBTX_ELINKS_RX-1 downto 0);
    GBTX_DCLK           : in  std_logic_vector(1 downto 0);  -- GBTx 40/160MHz clock for elinks
    RX_DATAVALID_A      : in  std_logic;
    RX_DATAVALID_B      : in  std_logic;
    RX_DATAVALID_C      : in  std_logic;
    TX_DATAVALID_A      : out std_logic;
    TX_DATAVALID_B      : out std_logic;
    TX_DATAVALID_C      : out std_logic;
    --
    GBTX1_DIN           : out std_logic_vector(C_GBTX_ELINKS_TX-1 downto 0);
    TX1_DATAVALID_A     : out std_logic;
    TX1_DATAVALID_B     : out std_logic;
    TX1_DATAVALID_C     : out std_logic;
    --
    ---- fifo out data
    GBTX_RX_DATA        : out std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0);
    GBTX_RX_STROBE      : out std_logic;
    GBTX_RX_CLK         : out std_logic;
    --
    ---- fifo in data
    GBTX_TX_DATA        : in  std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0);
    GBTX_TX_STROBE      : in  std_logic;
    GBTX_TX_FIFO_RDCLK  : out std_logic;
    --
    ---- fifo in data (GBTx1)
    GBTX1_TX_DATA       : in  std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0);
    GBTX1_TX_STROBE     : in  std_logic;
    GBTX1_TX_FIFO_RDCLK : out std_logic
    );
  attribute mark_debug                    : string;
  attribute mark_debug of GBTX_TX_DATA    : signal is USE_DEBUG;
  attribute mark_debug of GBTX_TX_STROBE  : signal is USE_DEBUG;
  attribute mark_debug of GBTX1_TX_DATA   : signal is USE_DEBUG;
  attribute mark_debug of GBTX1_TX_STROBE : signal is USE_DEBUG;
end entity gbtx_controller;

architecture structural of gbtx_controller is

  --interface from wishbone slave
  signal s_gbtx_controller_enable                           : std_logic;
  signal s_idelay_values, s_idelay_values_clkdiv8           : t_idelay_values;
  signal s_idelay_read_values, s_idelay_read_values_clkdiv8 : t_idelay_values;
  signal s_idelay_load, s_idelay_load_clkdiv8               : std_logic;
  signal s_tx_pattern_selection, s_tx1_pattern_selection    : std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
  signal s_bitslip_rx_value, s_bitslip_rx_value_clkdiv8     : std_logic_vector(C_BITSLIP_VALUE_bit'range);
  signal s_bitslip_tx_value, s_bitslip_tx_value_clkdiv8     : std_logic_vector(C_BITSLIP_VALUE_bit'range);
  signal s_bitslip_load, s_bitslip_load_clkdiv8             : std_logic;

  -- rx handler
  signal s_gbtx_rxdatavalid_d : std_logic;
  signal s_gbtx_rxdatavalid  : std_logic_vector(C_K_TMR-1 downto 0);

  -- tx handler
  signal s_gbtx_tx_dataframe, s_gbtx1_tx_dataframe : std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
  signal s_gbtx_tx_dataframe_bitslipped            : std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
  signal s_gbtx1_tx_dataframe_bitslipped           : std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);

  -- hard macros
  signal s_clk_div2, s_clk_div8                         : std_logic;
  signal s_rx_ready                                     : std_logic;
  signal s_gbtx_rx_dataframe_macro, s_gbtx_rx_dataframe : std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
  signal s_rx_strobe                                    : std_logic;

  -- SEU monitor
  signal s_mismatch, s_mismatch_2nd       : std_logic_vector(C_GBTX_MISMATCH_WIDTH-1 downto 0);
  signal s_mismatch_wb, s_mismatch_2nd_wb : std_logic_vector(C_GBTX_MISMATCH_WIDTH-1 downto 0);

  signal s_wishbone_registers : t_wishbone_registers_tmr;

  -- debug signals for ILA
  attribute mark_debug of s_gbtx_rx_dataframe  : signal is USE_DEBUG;
  attribute mark_debug of s_gbtx_rxdatavalid_d : signal is USE_DEBUG;
  attribute mark_debug of s_gbtx_tx_dataframe  : signal is USE_DEBUG;
  attribute mark_debug of s_rx_ready           : signal is USE_DEBUG;

  constant C_GBTX_RX_DATA_DISABLED : std_logic_vector(GBTX_RX_DATA'range) := (others => '0');
  constant C_GBTX_RX_STROBE_DISABLED : std_logic := '0';

begin  -- architecture structural

  -- assign output ports
  GBTX_RX_CLK    <= s_clk_div8;
  GBTX_RX_DATA   <= C_GBTX_RX_DATA_DISABLED when s_gbtx_controller_enable = '0' else
                    s_gbtx_rxdatavalid_d & s_gbtx_rx_dataframe;
  GBTX_RX_STROBE <= C_GBTX_RX_STROBE_DISABLED when s_gbtx_controller_enable = '0' else
                    s_rx_strobe;
  s_rx_strobe    <= s_rx_ready when s_tx_pattern_selection = "00" else
                    '0';

  -- RXDATAVALID is a triplicated input
  s_gbtx_rxdatavalid(0) <= RX_DATAVALID_A;
  s_gbtx_rxdatavalid(1) <= RX_DATAVALID_B;
  s_gbtx_rxdatavalid(2) <= RX_DATAVALID_C;

  -----------------------------------------------------------------------------
  -- Wishbone
  -----------------------------------------------------------------------------

  INST_gbtx_wishbone_tmr_wrapper : entity work.gbtx_wishbone_tmr_wrapper
    generic map (
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_MISMATCH_EN              => G_MISMATCH_EN,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
    port map (
      WB_CLK                 => WB_CLK,
      WB_RST                 => WB_RST,
      GBTX_CONTROLLER_ENABLE => s_gbtx_controller_enable,
      RST_GBTX_n             => RST_GBTX_n,
      IDELAY_VALUES          => s_idelay_values,
      IDELAY_READ_VALUES     => s_idelay_read_values,
      IDELAY_LOAD            => s_idelay_load,
      BITSLIP_RX_VALUE       => s_bitslip_rx_value,
      BITSLIP_TX_VALUE       => s_bitslip_tx_value,
      BITSLIP_LOAD           => s_bitslip_load,
      TX_PATTERN_SELECTION   => s_tx_pattern_selection,
      TX1_PATTERN_SELECTION  => s_tx1_pattern_selection,
      GBTX_RXRDY             => GBTX_RXRDY,
      WISHBONE_REGISTERS_O   => s_wishbone_registers
      );

  -----------------------------------------------------------------------------
  -- RX handler
  -----------------------------------------------------------------------------

  INST_gbtx_rx_handler_tmr_wrapper : entity work.gbtx_rx_handler_tmr_wrapper
    generic map (
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_MISMATCH_EN              => G_MISMATCH_EN,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
    port map (
      WB_CLK                     => WB_CLK,
      WB_RST                     => WB_RST,
      RST                        => RST,
      GBTX_RXDATAVALID_D         => s_gbtx_rxdatavalid_d,
      RX_READY                   => s_rx_ready,
      CLK_DIV2                   => s_clk_div2,
      CLK_DIV8                   => s_clk_div8,
      BITSLIP_RX_VALUE           => s_bitslip_rx_value,
      BITSLIP_RX_LOAD            => s_bitslip_load,
      IDELAY_LOAD                => s_idelay_load,
      IDELAY_VALUES              => s_idelay_values,
      IDELAY_READ_VALUES         => s_idelay_read_values,
      BITSLIP_RX_VALUE_CLKDIV8   => s_bitslip_rx_value_clkdiv8,
      BITSLIP_RX_LOAD_CLKDIV8    => s_bitslip_load_clkdiv8,
      IDELAY_LOAD_CLKDIV8        => s_idelay_load_clkdiv8,
      IDELAY_VALUES_CLKDIV8      => s_idelay_values_clkdiv8,
      IDELAY_READ_VALUES_CLKDIV8 => s_idelay_read_values_clkdiv8,
      GBTX_RXDATAVALID           => s_gbtx_rxdatavalid,
      MISMATCH                   => s_mismatch(C_MISMATCH_bit_RX_HANDLER),
      MISMATCH_2ND               => s_mismatch_2nd(C_MISMATCH_bit_RX_HANDLER));

  -----------------------------------------------------------------------------
  -- TX handlers
  -----------------------------------------------------------------------------

  INST_gbtx_tx_handler_tmr_wrapper : entity work.gbtx_tx_handler_tmr_wrapper
    generic map (
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_MISMATCH_EN              => G_MISMATCH_EN,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
    port map (
      RST                  => RST,
      GBTX_TX_DATA         => GBTX_TX_DATA,
      GBTX_TX_STROBE       => GBTX_TX_STROBE,
      RX_READY             => s_rx_ready,
      CLK_DIV              => s_clk_div8,
      GBTX_TX_DATAFRAME    => s_gbtx_tx_dataframe,
      GBTX_RX_DATAFRAME    => s_gbtx_rx_dataframe,
      TX_PATTERN_SELECTION => s_tx_pattern_selection,
      GBTX_TXDATAVALID_A   => TX_DATAVALID_A,
      GBTX_TXDATAVALID_B   => TX_DATAVALID_B,
      GBTX_TXDATAVALID_C   => TX_DATAVALID_C,
      MISMATCH             => s_mismatch(C_MISMATCH_bit_TX_HANDLER),
      MISMATCH_2ND         => s_mismatch_2nd(C_MISMATCH_bit_TX_HANDLER));
  GBTX_TX_FIFO_RDCLK <= s_clk_div8;

  if_use_gbtx1_gen : if G_USE_GBTX1 = 1 generate
    INST_gbtx1_tx_handler_tmr_wrapper : entity work.gbtx_tx_handler_tmr_wrapper
      generic map (
        G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
        G_MISMATCH_EN              => G_MISMATCH_EN,
        G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
      port map (
        RST                  => RST,
        GBTX_TX_DATA         => GBTX1_TX_DATA,
        GBTX_TX_STROBE       => GBTX1_TX_STROBE,
        RX_READY             => s_rx_ready,
        CLK_DIV              => s_clk_div8,
        GBTX_TX_DATAFRAME    => s_gbtx1_tx_dataframe,
        GBTX_RX_DATAFRAME    => s_gbtx_rx_dataframe,
        TX_PATTERN_SELECTION => s_tx1_pattern_selection,
        GBTX_TXDATAVALID_A   => TX1_DATAVALID_A,
        GBTX_TXDATAVALID_B   => TX1_DATAVALID_B,
        GBTX_TXDATAVALID_C   => TX1_DATAVALID_C,
        MISMATCH             => s_mismatch(C_MISMATCH_bit_TX1_HANDLER),
        MISMATCH_2ND         => s_mismatch_2nd(C_MISMATCH_bit_TX1_HANDLER));
    GBTX1_TX_FIFO_RDCLK <= s_clk_div8;
  end generate if_use_gbtx1_gen;

  else_use_gbtx1_gen : if G_USE_GBTX1 = 0 generate
    TX1_DATAVALID_A                            <= '0';
    TX1_DATAVALID_B                            <= '0';
    TX1_DATAVALID_C                            <= '0';
    s_gbtx1_tx_dataframe                       <= (others => '0');
    GBTX1_TX_FIFO_RDCLK                        <= '0';
    s_mismatch(C_MISMATCH_bit_TX1_HANDLER)     <= '0';
    s_mismatch_2nd(C_MISMATCH_bit_TX1_HANDLER) <= '0';
  end generate else_use_gbtx1_gen;

  -----------------------------------------------------------------------------
  -- Macros
  -----------------------------------------------------------------------------
  INST_gbtx_hard_macros : entity work.gbtx_hard_macros
    generic map (
      G_USE_GBTX1 => G_USE_GBTX1)
    port map (
      ARST                       => ARST,
      GBTX_RXRDY                 => GBTX_RXRDY,
      CLK_DIV2                   => s_clk_div2,
      CLK_DIV8                   => s_clk_div8,
      GBTX_RX_DATAFRAME          => s_gbtx_rx_dataframe_macro,
      RX_READY                   => s_rx_ready,
      GBTX_TX_DATAFRAME          => s_gbtx_tx_dataframe_bitslipped,
      GBTX1_TX_DATAFRAME         => s_gbtx1_tx_dataframe_bitslipped,
      IDELAY_VALUES_CLKDIV8      => s_idelay_values_clkdiv8,
      IDELAY_READ_VALUES_CLKDIV8 => s_idelay_read_values_clkdiv8,
      IDELAY_LOAD_CLKDIV8        => s_idelay_load_clkdiv8,
      GBTX_DCLK                  => GBTX_DCLK,
      GBTX_DIN                   => GBTX_DIN,
      GBTX1_DIN                  => GBTX1_DIN,
      GBTX_DOUT                  => GBTX_DOUT);

  -------------------------------------------------------------------------
  -- Bitsplip logic RX
  -------------------------------------------------------------------------

  INST_gbtx_bitsliprx_logic_tmr_wrapper : entity work.gbtx_bitslip_logic_tmr_wrapper
    generic map (
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_MISMATCH_EN              => G_MISMATCH_EN,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
    port map (
      CLK_DIV8              => s_clk_div8,
      RST                   => RST,
      RX_READY              => s_rx_ready,
      BITSLIP_VALUE_CLKDIV8 => s_bitslip_rx_value_clkdiv8,
      BITSLIP_LOAD_CLKDIV8  => s_bitslip_load_clkdiv8,
      DATAFRAME_i           => s_gbtx_rx_dataframe_macro,
      DATAFRAME_o           => s_gbtx_rx_dataframe,
      MISMATCH              => s_mismatch(C_MISMATCH_bit_BITSLIP_LOGIC),
      MISMATCH_2ND          => s_mismatch_2nd(C_MISMATCH_bit_BITSLIP_LOGIC));

  -------------------------------------------------------------------------
  -- Bitsplip logic TX
  -------------------------------------------------------------------------

  INST_bitslip_sync : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      SIM_ASSERT_CHK => 1,  -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 0,  -- integer; 0=do not register input, 1=register input
      WIDTH          => C_BITSLIP_VALUE_bit'length  -- integer; range: 2-1024
      )
    port map (
      src_clk  => '0',      -- optional; required when SRC_INPUT_REG = 1
      src_in   => s_bitslip_tx_value,
      dest_clk => s_clk_div8,
      dest_out => s_bitslip_tx_value_clkdiv8
      );

  INST_gbtx_bitsliptx_logic_tmr_wrapper : entity work.gbtx_bitslip_logic_tmr_wrapper
    generic map (
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      G_MISMATCH_EN              => G_MISMATCH_EN,
      G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
    port map (
      CLK_DIV8              => s_clk_div8,
      RST                   => RST,
      RX_READY              => s_rx_ready,
      BITSLIP_VALUE_CLKDIV8 => s_bitslip_tx_value_clkdiv8,
      BITSLIP_LOAD_CLKDIV8  => s_bitslip_load_clkdiv8,
      DATAFRAME_i           => s_gbtx_tx_dataframe,
      DATAFRAME_o           => s_gbtx_tx_dataframe_bitslipped,
      MISMATCH              => open,
      MISMATCH_2ND          => open);

  if_use_gbtx1_gen2 : if G_USE_GBTX1 = 1 generate
    INST_gbtx_bitsliptx_logic_tmr_wrapper : entity work.gbtx_bitslip_logic_tmr_wrapper
      generic map (
        G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
        G_MISMATCH_EN              => G_MISMATCH_EN,
        G_ADDITIONAL_MISMATCH      => G_ADDITIONAL_MISMATCH)
      port map (
        CLK_DIV8              => s_clk_div8,
        RST                   => RST,
        RX_READY              => s_rx_ready,
        BITSLIP_VALUE_CLKDIV8 => s_bitslip_tx_value_clkdiv8,
        BITSLIP_LOAD_CLKDIV8  => s_bitslip_load_clkdiv8,
        DATAFRAME_i           => s_gbtx1_tx_dataframe,
        DATAFRAME_o           => s_gbtx1_tx_dataframe_bitslipped,
        MISMATCH              => open,
        MISMATCH_2ND          => open);
  end generate if_use_gbtx1_gen2;
  ifn_use_gbtx1_gen2 : if not (G_USE_GBTX1 = 1) generate
    s_gbtx1_tx_dataframe_bitslipped <= (others => '0'); -- not used in this case, but avoids warnings
  end generate ifn_use_gbtx1_gen2;


end architecture structural;
