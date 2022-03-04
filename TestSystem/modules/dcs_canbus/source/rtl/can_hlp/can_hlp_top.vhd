-------------------------------------------------------------------------------
-- Title      : CAN High Level Protocol (HLP)
-- Project    : CAN Bus DCS for ITS Readout Unit
-------------------------------------------------------------------------------
-- File       : can_hlp_top.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    :
-- Created    : 2018-03-30
-- Last update: 2018-12-17
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: CAN High Level Protocol (HLP) for DCS in ITS Readout Unit
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-03-30  1.0      simon   Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.intercon_pkg.all;
use work.can_hlp_wb_slave_regs_pkg.all;
use work.can_hlp_glue_pkg.all;
use work.xpm_cdc_components_pkg.all;


entity can_hlp_top is
  port (
    -- Wishbone slave interface
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  wbs_i_type;          -- Wishbone slave input signals
    WB_WBS_O : out wbs_o_type;          -- Wishbone slave output signals

    -- Interface to wishbone master via FIFO
    -- CAN HLP intiates WB transactions on DP0
    DP0_DT_O   : out std_logic_vector(31 downto 0);
    DP0_EPTY_O : out std_logic;
    DP0_RD_I   : in  std_logic;

    -- Interface to wishbone master via FIFO
    -- CAN HLP receives WB replies on DP1
    DP1_DT_I     : in  std_logic_vector(31 downto 0);
    DP1_FULL_O   : out std_logic;
    DP1_WR_I     : in  std_logic;

    -- CAN node ID
    CAN_NODE_ID : in std_logic_vector(7 downto 0);

    -- CAN bus signals
    CAN_TX : out std_logic;
    CAN_RX : in  std_logic);

end entity can_hlp_top;

architecture structural of can_hlp_top is

  signal s_can_node_and_cmd_id : std_logic_vector(10 downto 0);

  signal s_dp1_dt   : std_logic_vector(31 downto 0);
  signal s_dp1_epty : std_logic;
  signal s_dp1_rd   : std_logic;
  signal s_dp0_dt   : std_logic_vector(31 downto 0);
  signal s_dp0_full : std_logic;
  signal s_dp0_wr   : std_logic;

  signal s_can_wb_data_i : std_logic_vector(7 downto 0);
  signal s_can_wb_data_o : std_logic_vector(7 downto 0);
  signal s_can_wb_addr_i : std_logic_vector(7 downto 0);
  signal s_can_wb_we_i   : std_logic;
  signal s_can_wb_cyc_i  : std_logic;
  signal s_can_wb_stb_i  : std_logic;
  signal s_can_wb_ack_o  : std_logic;

  signal s_can_interrupt_n     : std_logic;
  signal s_can_ctrl_soft_reset : std_logic;

  signal s_can_rx_msg_id    : std_logic_vector(10 downto 0);
  signal s_can_rx_msg_buff  : can_buffer_t;
  signal s_can_tx_msg_buff  : can_buffer_t;
  signal s_can_msg_received : std_logic;
  signal s_can_tx_request   : std_logic;
  signal s_can_rx_msg_size  : std_logic_vector(3 downto 0);
  signal s_can_tx_msg_size  : std_logic_vector(3 downto 0);
  signal s_can_tx_cmd_id    : std_logic_vector(2 downto 0);  -- HLP command ID

  signal s_can_reg_rx_msg_count           : std_logic_vector(15 downto 0);
  signal s_can_reg_tx_msg_count           : std_logic_vector(15 downto 0);
  signal s_can_reg_read_msg_count         : std_logic_vector(15 downto 0);
  signal s_can_reg_write_msg_count        : std_logic_vector(15 downto 0);
  signal s_can_reg_status_alert_msg_count : std_logic_vector(15 downto 0);
  signal s_can_reg_unknown_msg_count      : std_logic_vector(15 downto 0);
  signal s_can_reg_clk_prescale           : std_logic_vector(5 downto 0);

  component can_top is
    port (
      wb_clk_i   : in  std_logic;
      wb_rst_i   : in  std_logic;
      wb_dat_i   : in  std_logic_vector(7 downto 0);
      wb_dat_o   : out std_logic_vector(7 downto 0);
      wb_cyc_i   : in  std_logic;
      wb_stb_i   : in  std_logic;
      wb_we_i    : in  std_logic;
      wb_adr_i   : in  std_logic_vector(7 downto 0);
      wb_ack_o   : out std_logic;
      clk_i      : in  std_logic;
      rx_i       : in  std_logic;
      tx_o       : out std_logic;
      bus_off_on : out std_logic;
      irq_on     : out std_logic;
      clkout_o   : out std_logic);
  end component can_top;

  component fifo32x16 is
    port (
      rst    : in  STD_LOGIC;
      wr_clk : in  STD_LOGIC;
      rd_clk : in  STD_LOGIC;
      din    : in  STD_LOGIC_VECTOR (31 downto 0);
      wr_en  : in  STD_LOGIC;
      rd_en  : in  STD_LOGIC;
      dout   : out STD_LOGIC_VECTOR (31 downto 0);
      full   : out STD_LOGIC;
      empty  : out STD_LOGIC);
  end component fifo32x16;

begin  -- architecture can_hlp_top

  -- TODO: Maybe all of this should be done in the can_hlp module?
  -- Makes sense to not have any logic at the top level
  --
  -- Full CAN ID (when transmitting) consists of:
  -- Bits 10:3 - Node ID
  -- Bits  2:0 - HLP Command type
  s_can_node_and_cmd_id(10 downto 3) <= CAN_NODE_ID;
  s_can_node_and_cmd_id(2 downto 0)  <= s_can_tx_cmd_id;

  -- can controller
  inst_canbus_ctrl : can_top
    port map
    (
      clk_i      => WB_CLK,
      rx_i       => CAN_RX,
      tx_o       => CAN_TX,
      bus_off_on => open,
      irq_on     => s_can_interrupt_n,
      clkout_o   => open,
      wb_clk_i   => WB_CLK,
      wb_rst_i   => WB_RST,
      wb_dat_i   => s_can_wb_data_i,
      wb_dat_o   => s_can_wb_data_o,
      wb_cyc_i   => s_can_wb_cyc_i,
      wb_stb_i   => s_can_wb_stb_i,
      wb_we_i    => s_can_wb_we_i,
      wb_adr_i   => s_can_wb_addr_i,
      wb_ack_o   => s_can_wb_ack_o
      );

  inst_can_hlp_wb_slave_regs : entity work.can_hlp_wb_slave_regs
    port map (
      WB_CLK       => WB_CLK,
      WB_RST       => WB_RST,
      WB_WBS_I     => WB_WBS_I,
      WB_WBS_O     => WB_WBS_O,

      -- Registers
      CAN_REG_RX_MSG_COUNT       => s_can_reg_rx_msg_count,
      CAN_REG_TX_MSG_COUNT       => s_can_reg_tx_msg_count,
      CAN_REG_READ_COUNT         => s_can_reg_read_msg_count,
      CAN_REG_WRITE_COUNT        => s_can_reg_write_msg_count,
      CAN_REG_STATUS_ALERT_COUNT => s_can_reg_status_alert_msg_count,
      CAN_REG_UNKNOWN_COUNT      => s_can_reg_unknown_msg_count,
      CAN_REG_CLK_PRESCALE       => s_can_reg_clk_prescale,

      CAN_CTRL_SOFT_RESET        => s_can_ctrl_soft_reset
      );


  inst_can_hlp_glue : entity work.can_hlp_glue
    port map (
      CLK               => WB_CLK,
      RESET             => WB_RST,
      CAN_MY_ID         => s_can_node_and_cmd_id,
      CAN_RX_MSG_ID     => s_can_rx_msg_id,
      CAN_RX_MSG_BUFFER => s_can_rx_msg_buff,
      CAN_RX_MSG_SIZE   => s_can_rx_msg_size,
      CAN_TX_MSG_BUFFER => s_can_tx_msg_buff,
      CAN_TX_MSG_SIZE   => s_can_tx_msg_size,
      CAN_MSG_RECEIVED  => s_can_msg_received,
      CAN_TX_REQUEST    => s_can_tx_request,

      CAN_INTERRUPT_N     => s_can_interrupt_n,
      CAN_CTRL_SOFT_RESET => s_can_ctrl_soft_reset,

      -- Registers for CAN HLP glue logic module
      CAN_REG_RX_MSG_COUNT => s_can_reg_rx_msg_count,
      CAN_REG_TX_MSG_COUNT => s_can_reg_tx_msg_count,
      CAN_REG_CLK_PRESCALE => s_can_reg_clk_prescale,

      -- Wishbone master interface to CAN bus controller
      WBM_CAN_DAT_O  => s_can_wb_data_i,
      WBM_CAN_DAT_I  => s_can_wb_data_o,
      WBM_CAN_ADDR_O => s_can_wb_addr_i,
      WBM_CAN_WE_O   => s_can_wb_we_i,
      WBM_CAN_CYC_O  => s_can_wb_cyc_i,
      WBM_CAN_STB_O  => s_can_wb_stb_i,
      WBM_CAN_ACK_I  => s_can_wb_ack_o,
      WBM_CAN_ERR_I  => '0');


  inst_can_hlp : entity work.can_hlp
    port map (
      CLK               => WB_CLK,
      RESET             => WB_RST,
      CAN_MY_ID         => CAN_NODE_ID,
      CAN_RX_MSG_ID     => s_can_rx_msg_id,
      CAN_RX_MSG_BUFFER => s_can_rx_msg_buff,
      CAN_RX_MSG_SIZE   => s_can_rx_msg_size,
      CAN_TX_MSG_BUFFER => s_can_tx_msg_buff,
      CAN_TX_MSG_SIZE   => s_can_tx_msg_size,
      CAN_TX_CMD_ID     => s_can_tx_cmd_id,
      CAN_MSG_RECEIVED  => s_can_msg_received,
      CAN_TX_REQUEST    => s_can_tx_request,

      -- Registers for CAN HLP module
      CAN_REG_READ_COUNT         => s_can_reg_read_msg_count,
      CAN_REG_WRITE_COUNT        => s_can_reg_write_msg_count,
      CAN_REG_STATUS_ALERT_COUNT => s_can_reg_status_alert_msg_count,
      CAN_REG_UNKNOWN_COUNT      => s_can_reg_unknown_msg_count,

      -- Interface to wishbone FIFO
      -- CAN_HLP receives WB replies on this interface
      DP0_DT_O   => s_dp0_dt,
      DP0_FULL_I => s_dp0_full,
      DP0_WR_O   => s_dp0_wr,

      -- Interface to Wishbone FIFO
      -- CAN_HLP initiates WB transactions on this interface
      DP1_DT_I   => s_dp1_dt,
      DP1_EPTY_I => s_dp1_epty,
      DP1_RD_O   => s_dp1_rd);



  inst_dp0_wb_request_fifo: xpm_fifo_sync
    generic map (
      FIFO_MEMORY_TYPE    => "DISTRIBUTED",
      ECC_MODE            => "NO_ECC",
      FIFO_WRITE_DEPTH    => 16,
      WRITE_DATA_WIDTH    => 32,
      READ_DATA_WIDTH     => 32,
      WR_DATA_COUNT_WIDTH => 5,
      RD_DATA_COUNT_WIDTH => 5)
    port map (
      sleep         => '0',
      rst           => WB_RST,
      wr_clk        => WB_CLK,
      wr_en         => s_dp0_wr,
      din           => s_dp0_dt,
      full          => s_dp0_full,
      prog_full     => open,
      wr_data_count => open,
      overflow      => open,
      wr_rst_busy   => open,
      almost_full   => open,
      wr_ack        => open,
      rd_en         => DP0_RD_I,
      dout          => DP0_DT_O,
      empty         => DP0_EPTY_O,
      prog_empty    => open,
      rd_data_count => open,
      underflow     => open,
      rd_rst_busy   => open,
      almost_empty  => open,
      data_valid    => open,
      injectsbiterr => '0',
      injectdbiterr => '0',
      sbiterr       => open,
      dbiterr       => open);


  inst_dp1_wb_response_fifo: xpm_fifo_sync
    generic map (
      FIFO_MEMORY_TYPE    => "DISTRIBUTED",
      ECC_MODE            => "NO_ECC",
      FIFO_WRITE_DEPTH    => 16,
      WRITE_DATA_WIDTH    => 32,
      READ_DATA_WIDTH     => 32,
      WR_DATA_COUNT_WIDTH => 5,
      RD_DATA_COUNT_WIDTH => 5)
    port map (
      sleep         => '0',
      rst           => WB_RST,
      wr_clk        => WB_CLK,
      wr_en         => DP1_WR_I,
      din           => DP1_DT_I,
      full          => DP1_FULL_O,
      prog_full     => open,
      wr_data_count => open,
      overflow      => open,
      wr_rst_busy   => open,
      almost_full   => open,
      wr_ack        => open,
      rd_en         => s_dp1_rd,
      dout          => s_dp1_dt,
      empty         => s_dp1_epty,
      prog_empty    => open,
      rd_data_count => open,
      underflow     => open,
      rd_rst_busy   => open,
      almost_empty  => open,
      data_valid    => open,
      injectsbiterr => '0',
      injectdbiterr => '0',
      sbiterr       => open,
      dbiterr       => open);

end architecture structural;
