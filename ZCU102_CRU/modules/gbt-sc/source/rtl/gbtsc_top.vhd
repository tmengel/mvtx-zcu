-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief IC and EC control - TOP level
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;

--! Include the work library
library work;
--! Use SCA Package to define specific types (vector arrays)
use work.SCA_PKG.all;

--! @brief GBTSC_top Entity - TOP Level
--! @details
--! The gbtsc_top module implements the required blocks to carry out Internal (GBTx)
--! and external (SCA) slow control. Its purpose is to handle the communication
--! with up to 41 SCAs and 1 GBTx (max. capability of a GBT link).
entity gbtsc_top is
  generic (
    -- IC configuration
    g_IC_FIFO_DEPTH : integer              := 20;  --! Defines the depth of the FIFO used to handle the Internal control (Max. number of words/bytes can be read/write from/to a GBTx)
    g_ToLpGBT       : integer range 0 to 1 := 0;   --! 1 to use LpGBT. Otherwise, it should be 0
    --
    -- EC configuration
    g_SCA_COUNT     : integer              := 1  --! Defines the maximum number of SCA that can be connected to this module
    );
  port (
    -- Clock & reset
    tx_clk_i            : in  std_logic;  --! Tx clock (Tx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
    tx_clk_en           : in  std_logic := '1';  --! Tx clock enable signal must be used in case of multi-cycle path(tx_clk_i > LHC frequency). By default: always enabled
    --
    rx_clk_i            : in  std_logic;  --! Rx clock (Rx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
    rx_clk_en           : in  std_logic := '1';  --! Rx clock enable signal must be used in case of multi-cycle path(rx_clk_i > LHC frequency). By default: always enabled
    --
    rx_reset_i          : in  std_logic;  --! Reset RX datapath
    tx_reset_i          : in  std_logic;  --! Reset TX datapath
    --
    -- IC control
    tx_start_write_i    : in  std_logic;  --! Request a write config. to the GBTx (IC)
    tx_start_read_i     : in  std_logic;  --! Request a read config. to the GBTx (IC)
    --
    -- IC configuration
    tx_GBTx_address_i   : in  std_logic_vector(7 downto 0);  --! I2C address of the GBTx
    tx_register_addr_i  : in  std_logic_vector(15 downto 0);       --! Address of the first register to be accessed
    tx_nb_to_be_read_i  : in  std_logic_vector(15 downto 0);       --! Number of words/bytes to be read (only for read transactions)
    --
    -- IC FIFO control
    wr_clk_i            : in  std_logic;  --! Fifo's writing clock
    tx_wr_i             : in  std_logic;  --! Request a write operation into the internal FIFO (Data to GBTx)
    tx_data_to_gbtx_i   : in  std_logic_vector(7 downto 0);  --! Data to be written into the internal FIFO
    -- 
    rd_clk_i            : in  std_logic;
    rx_rd_i             : in  std_logic;  --! Request a read operation of the internal FIFO (GBTx reply)
    rx_data_from_gbtx_o : out std_logic_vector(7 downto 0);  --! Data from the FIFO
    --
    -- IC Status
    tx_ready_o          : out std_logic;  --! IC core ready for a transaction
    rx_empty_o          : out std_logic;  --! Rx FIFO is empty (no reply from GBTx)
    --
    -- SCA control
    sca_enable_i        : in  std_logic_vector((g_SCA_COUNT-1) downto 0);  --! Enable flag to select SCAs
    start_reset_cmd_i   : in  std_logic;  --! Send a reset command to the enabled SCAs
    start_connect_cmd_i : in  std_logic;  --! Send a connect command to the enabled SCAs
    start_command_i     : in  std_logic;  --! Send the command set in input to the enabled SCAs
    inject_crc_error    : in  std_logic;  --! Emulate a CRC error
    --
    -- SCA command
    tx_address_i        : in  std_logic_vector(7 downto 0);  --! Command: address field (According to the SCA manual)
    tx_transID_i        : in  std_logic_vector(7 downto 0);  --! Command: transaction ID field (According to the SCA manual)
    tx_channel_i        : in  std_logic_vector(7 downto 0);  --! Command: channel field (According to the SCA manual)
    tx_command_i        : in  std_logic_vector(7 downto 0);  --! Command: command field (According to the SCA manual)
    tx_data_i           : in  std_logic_vector(31 downto 0);       --! Command: data field (According to the SCA manual)
    --
    rx_received_o       : out std_logic_vector((g_SCA_COUNT-1) downto 0);  --! Reply received flag (pulse)
    rx_address_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);  --! Reply: address field (According to the SCA manual)
    rx_control_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);  --! Reply: control field (According to the SCA manual)
    rx_transID_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);  --! Reply: transaction ID field (According to the SCA manual)
    rx_channel_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);  --! Reply: channel field (According to the SCA manual)
    rx_len_o            : out reg8_arr((g_SCA_COUNT-1) downto 0);  --! Reply: len field (According to the SCA manual)
    rx_error_o          : out reg8_arr((g_SCA_COUNT-1) downto 0);  --! Reply: error field (According to the SCA manual)
    rx_data_o           : out reg32_arr((g_SCA_COUNT-1) downto 0);         --! Reply: data field (According to the SCA manual)
    --
    -- EC line
    ec_data_o           : out reg2_arr((g_SCA_COUNT-1) downto 0);  --! (TX) Array of bits to be mapped to the TX GBT-Frame
    ec_data_i           : in  reg2_arr((g_SCA_COUNT-1) downto 0);  --! (RX) Array of bits to be mapped to the RX GBT-Frame
    --
    -- IC lines
    ic_data_o           : out std_logic_vector(1 downto 0);  --! (TX) Array of bits to be mapped to the TX GBT-Frame (bits 83/84)
    ic_data_i           : in  std_logic_vector(1 downto 0)   --! (RX) Array of bits to be mapped to the RX GBT-Frame (bits 83/84)
    );
end gbtsc_top;

--! @brief GBTSC_top architecture - TOP Level
--! @details GBTSC_top architecture instantiates the modules used to handle the IC and EC slow control. It maps all of the signal from
--! its entity to the sca_top and ic_top components. No additional logic is added in this block.
architecture behaviour of gbtsc_top is

  -- Signals
  signal tx_start_write_s : std_logic;  --! Used to simulate a write command request to the GBTx
  signal tx_start_read_s  : std_logic;  --! Used to simulate a read command request to the GBTx

  --! SCA_top component - TOP Level of the SCA-EC module
  component sca_top is
    generic (
      g_SCA_COUNT : integer := 1
      );
    port (
      tx_clk_i            : in  std_logic;
      tx_clk_en           : in  std_logic;
      rx_clk_i            : in  std_logic;
      rx_clk_en           : in  std_logic;
      rx_reset_i          : in  std_logic;
      tx_reset_i          : in  std_logic;
      enable_i            : in  std_logic_vector(g_SCA_COUNT-1 downto 0);
      start_reset_cmd_i   : in  std_logic;
      start_connect_cmd_i : in  std_logic;
      start_command_i     : in  std_logic;
      inject_crc_error    : in  std_logic;
      tx_address_i        : in  std_logic_vector(7 downto 0);
      tx_transID_i        : in  std_logic_vector(7 downto 0);
      tx_channel_i        : in  std_logic_vector(7 downto 0);
      tx_len_i            : in  std_logic_vector(7 downto 0);
      tx_command_i        : in  std_logic_vector(7 downto 0);
      tx_data_i           : in  std_logic_vector(31 downto 0);
      rx_received_o       : out std_logic_vector(g_SCA_COUNT-1 downto 0);
      rx_address_o        : out reg8_arr(g_SCA_COUNT-1 downto 0);
      rx_control_o        : out reg8_arr(g_SCA_COUNT-1 downto 0);
      rx_transID_o        : out reg8_arr(g_SCA_COUNT-1 downto 0);
      rx_channel_o        : out reg8_arr(g_SCA_COUNT-1 downto 0);
      rx_len_o            : out reg8_arr(g_SCA_COUNT-1 downto 0);
      rx_error_o          : out reg8_arr(g_SCA_COUNT-1 downto 0);
      rx_data_o           : out reg32_arr(g_SCA_COUNT-1 downto 0);
      tx_data_o           : out reg2_arr(g_SCA_COUNT-1 downto 0);
      rx_data_i           : in  reg2_arr(g_SCA_COUNT-1 downto 0)

      );
  end component sca_top;

  --! IC_top component - TOP Level of the IC module
  component ic_top is
    generic (
      g_ToLpGBT    : integer range 0 to 1 := 0;
      g_FIFO_DEPTH : integer              := 20  --! Depth of the internal FIFO used to improve the timming performance
      );
    port (
      -- Clock and reset
      tx_clk_i            : in  std_logic;  --! Tx clock (Tx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
      tx_clk_en           : in  std_logic;  --! Tx clock enable signal must be used in case of multi-cycle path(tx_clk_i > LHC frequency). By default: always enabled
      rx_clk_i            : in  std_logic;  --! Rx clock (Rx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
      rx_clk_en           : in  std_logic;  --! Rx clock enable signal must be used in case of multi-cycle path(rx_clk_i > LHC frequency). By default: always enabled
      rx_reset_i          : in  std_logic;  --! Reset RX datapath
      tx_reset_i          : in  std_logic;  --! Reset TX datapath
      -- Configuration
      tx_GBTx_address_i   : in  std_logic_vector(7 downto 0);   --! I2C address of the GBTx
      tx_register_addr_i  : in  std_logic_vector(15 downto 0);  --! Address of the first register to be accessed
      tx_nb_to_be_read_i  : in  std_logic_vector(15 downto 0);  --! Number of words/bytes to be read (only for read transactions)
      parity_err_mask_i   : in  std_logic_vector(7 downto 0);
      -- Internal FIFO
      wr_clk_i            : in  std_logic;  --! Fifo's writing clock
      tx_wr_i             : in  std_logic;  --! Request a write operation into the internal FIFO (Data to GBTx)
      tx_data_to_gbtx_i   : in  std_logic_vector(7 downto 0);   --! Data to be written into the internal FIFO
      rd_clk_i            : in  std_logic;
      rx_rd_i             : in  std_logic;  --! Request a read operation of the internal FIFO (GBTx reply)
      rx_data_from_gbtx_o : out std_logic_vector(7 downto 0);   --! Data from the FIFO
      -- FSM Control
      tx_start_write_i    : in  std_logic;  --! Request a write config. to the GBTx
      tx_start_read_i     : in  std_logic;  --! Request a read config. to the GBTx
      -- Status
      tx_ready_o          : out std_logic;  --! IC core ready for a transaction
      rx_empty_o          : out std_logic;  --! Rx FIFO is empty (no reply from GBTx)
      -- IC lines
      tx_data_o           : out std_logic_vector(1 downto 0);   --! (TX) Array of bits to be mapped to the TX GBT-Frame (bits 83/84)
      rx_data_i           : in  std_logic_vector(1 downto 0)    --! (RX) Array of bits to be mapped to the RX GBT-Frame (bits 83/84)
      );
  end component ic_top;

begin  --========####   Architecture Body   ####========--


  --! Instantiation of the SCA_top component
  sca_inst : sca_top
    generic map(
      g_SCA_COUNT => g_SCA_COUNT
      )
    port map(
      tx_clk_i            => tx_clk_i,
      tx_clk_en           => tx_clk_en,
      rx_clk_i            => rx_clk_i,
      rx_clk_en           => rx_clk_en,
      rx_reset_i          => rx_reset_i,
      tx_reset_i          => tx_reset_i,
      enable_i            => sca_enable_i,
      start_reset_cmd_i   => start_reset_cmd_i,
      start_connect_cmd_i => start_connect_cmd_i,
      start_command_i     => start_command_i,
      inject_crc_error    => inject_crc_error,
      tx_address_i        => tx_address_i,
      tx_transID_i        => tx_transID_i,
      tx_channel_i        => tx_channel_i,
      tx_len_i            => x"04",     -- tx_len_i, -- Fixed (BUG)
      tx_command_i        => tx_command_i,
      tx_data_i           => tx_data_i,
      rx_received_o       => rx_received_o,
      rx_address_o        => rx_address_o,
      rx_control_o        => rx_control_o,
      rx_transID_o        => rx_transID_o,
      rx_channel_o        => rx_channel_o,
      rx_len_o            => rx_len_o,
      rx_error_o          => rx_error_o,
      rx_data_o           => rx_data_o,
      tx_data_o           => ec_data_o,
      rx_data_i           => ec_data_i
      );

  tx_start_write_s <= tx_start_write_i;
  tx_start_read_s  <= tx_start_read_i;

  --! Instantiation of the IC_top component
  ic_inst : ic_top
    generic map(
      g_ToLpGBT    => g_ToLpGBT,
      g_FIFO_DEPTH => g_IC_FIFO_DEPTH
      )
    port map (
      -- Clock and reset
      tx_clk_i            => tx_clk_i,
      tx_clk_en           => tx_clk_en,
      rx_clk_i            => rx_clk_i,
      rx_clk_en           => rx_clk_en,
      rx_reset_i          => rx_reset_i,
      tx_reset_i          => tx_reset_i,
      -- Configuration
      tx_GBTx_address_i   => tx_GBTx_address_i,
      tx_register_addr_i  => tx_register_addr_i,
      tx_nb_to_be_read_i  => tx_nb_to_be_read_i,
      parity_err_mask_i   => (others => '0'),
      -- Internal FIFO
      wr_clk_i            => wr_clk_i,
      tx_wr_i             => tx_wr_i,
      tx_data_to_gbtx_i   => tx_data_to_gbtx_i,
      rd_clk_i            => rd_clk_i,
      rx_rd_i             => rx_rd_i,
      rx_data_from_gbtx_o => rx_data_from_gbtx_o,
      -- FSM Control
      tx_start_write_i    => tx_start_write_s,
      tx_start_read_i     => tx_start_read_s,
      -- Status
      tx_ready_o          => tx_ready_o,
      rx_empty_o          => rx_empty_o,
      -- IC lines
      tx_data_o           => ic_data_o,
      rx_data_i           => ic_data_i
      );

end behaviour;
--============================================================================--
--############################################################################--
--============================================================================--
