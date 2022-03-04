-------------------------------------------------------------------------------
-- Title      : GBTX handler_tmr_wrapper firmware
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_handler_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2017-11-03
-- Platform   : Vivado 2016.1
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the gbtx_handler module.
--
--              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
--              protected:
--                      0: no mitigation
--                      1: TMR with single voter
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

library work;
use work.xpm_cdc_components_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;

entity gbtx_handler_tmr_wrapper is
  generic (
    USE_DEBUG                  : string    := "TRUE";
    G_SEE_MITIGATION_TECHNIQUE : integer   := 0;
    G_MISMATCH_EN              : std_logic := '1';
    G_ADDITIONAL_MISMATCH      : std_logic := '1'
    );
  port (
    RST              : in  std_logic;
    -- from/to gbtx_hard_mactros
    PLL_RST          : out std_logic;
    CLK_DIV          : in  std_logic;
    CLK_SERIAL       : in  std_logic;
    SERDES_RST       : out std_logic;
    BITSLIP_RX_SYNC  : out std_logic_vector(C_BITSLIP_RX_CONTROL_bit'range);
    GBT_SENDDATA     : out std_logic_vector(C_GBT_PACKET_SIZE-1 downto 0);
    --interface to the wishbone
    GBT_ENABLE       : in  std_logic;   -- enable the core
    TEST_PATTERN_SEL : in  std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    BITSLIP_RX       : in  std_logic_vector(C_BITSLIP_RX_CONTROL_bit'range);
    IDELAY_LOAD      : in  std_logic;   -- load signal for the delay tabs
    -- GBTx signals
    RX_DATAVALID     : in  std_logic;
    RX_DATAVALID_D   : out std_logic;
    TX_DATAVALID     : out std_logic;
    -- input fifo (read) interface
    GBTX_TX_DATA     : in  std_logic_vector(C_GBT_DATA_WIDTH-1 downto 0);
    TX_FIFO_EMPTY    : in  std_logic;
    -- mismatch
    MISMATCH         : out std_logic;
    MISMATCH_2ND     : out std_logic);
  attribute DONT_TOUCH                             : string;
  attribute DONT_TOUCH of gbtx_handler_tmr_wrapper : entity is "true";
end entity gbtx_handler_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_handler_tmr_wrapper is

begin

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    INST_gbtx_handler : entity work.gbtx_handler
      generic map (
        USE_DEBUG => USE_DEBUG)
      port map (
        RST              => RST,
        PLL_RST          => PLL_RST,
        CLK_DIV          => CLK_DIV,
        CLK_SERIAL       => CLK_SERIAL,
        SERDES_RST       => SERDES_RST,
        BITSLIP_RX_SYNC  => BITSLIP_RX_SYNC,
        GBT_SENDDATA     => GBT_SENDDATA,
        GBT_ENABLE       => GBT_ENABLE,
        TEST_PATTERN_SEL => TEST_PATTERN_SEL,
        BITSLIP_RX       => BITSLIP_RX,
        IDELAY_LOAD      => IDELAY_LOAD,
        RX_DATAVALID     => RX_DATAVALID,
        RX_DATAVALID_D   => RX_DATAVALID_D,
        TX_DATAVALID     => TX_DATAVALID,
        GBTX_TX_DATA     => GBTX_TX_DATA,
        TX_FIFO_EMPTY    => TX_FIFO_EMPTY);

    MISMATCH     <= '0';
    MISMATCH_2ND <= '0';
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      constant C_MMR_SIZE : natural := 3;  -- TMR
      type t_bitslip_tmr is array (0 to C_MMR_SIZE-1) of std_logic_vector(C_BITSLIP_RX_CONTROL_bit'range);
      type t_gbtsenddata_tmr is array (0 to C_MMR_SIZE-1) of std_logic_vector(C_GBT_PACKET_SIZE-1 downto 0);

      signal s_pll_rst         : std_logic_vector(C_MMR_SIZE-1 downto 0);
      signal s_serdes_rst      : std_logic_vector(C_MMR_SIZE-1 downto 0);
      signal s_rx_datavalid_d  : std_logic_vector(C_MMR_SIZE-1 downto 0);
      signal s_tx_datavalid    : std_logic_vector(C_MMR_SIZE-1 downto 0);
      signal s_tx_fifo_clk     : std_logic_vector(C_MMR_SIZE-1 downto 0);
      signal s_bitslip_rx_sync : t_bitslip_tmr;
      signal s_gbt_senddata    : t_gbtsenddata_tmr;

      attribute DONT_TOUCH                      : string;
      attribute DONT_TOUCH of s_pll_rst         : signal is "TRUE";
      attribute DONT_TOUCH of s_serdes_rst      : signal is "TRUE";
      attribute DONT_TOUCH of s_rx_datavalid_d  : signal is "TRUE";
      attribute DONT_TOUCH of s_tx_datavalid    : signal is "TRUE";
      attribute DONT_TOUCH of s_tx_fifo_clk     : signal is "TRUE";
      attribute DONT_TOUCH of s_bitslip_rx_sync : signal is "TRUE";
      attribute DONT_TOUCH of s_gbt_senddata    : signal is "TRUE";

      constant C_MISMATCH_WIDTH                     : integer                                       := 6;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block
      MISMATCH <= '0' when s_mismatch_array = C_MISMATCH_NONE else
                  '1';

      if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = '1' generate
        MISMATCH_2ND <= '0' when s_mismatch_2nd_array = C_MISMATCH_NONE else
                        '1';
      end generate if_add_mismatch_gen;

      if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = '0' generate
        MISMATCH_2ND <= '0';
      end generate if_not_add_mismatch_gen;

      -- for generate
      TMR_FOR_generate : for i in 0 to C_MMR_SIZE-1 generate
        INST_gbtx_handler : entity work.gbtx_handler
          generic map (
            USE_DEBUG => USE_DEBUG)
          port map (
            RST              => RST,
            CLK_DIV          => CLK_DIV,
            CLK_SERIAL       => CLK_SERIAL,
            GBT_ENABLE       => GBT_ENABLE,
            TEST_PATTERN_SEL => TEST_PATTERN_SEL,
            BITSLIP_RX       => BITSLIP_RX,
            IDELAY_LOAD      => IDELAY_LOAD,
            RX_DATAVALID     => RX_DATAVALID,
            GBTX_TX_DATA     => GBTX_TX_DATA,
            TX_FIFO_EMPTY    => TX_FIFO_EMPTY,

            PLL_RST         => s_pll_rst(i),
            SERDES_RST      => s_serdes_rst(i),
            BITSLIP_RX_SYNC => s_bitslip_rx_sync(i),
            GBT_SENDDATA    => s_gbt_senddata(i),
            RX_DATAVALID_D  => s_rx_datavalid_d(i),
            TX_DATAVALID    => s_tx_datavalid(i)
            );
      end generate TMR_FOR_generate;

      INST_majority_voter_wrapper2_PLL_RST : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT         => s_pll_rst,
          OUTPUT        => PLL_RST,
          MISMATCH      => s_mismatch_array(0),
          MISMATCH_2ND  => s_mismatch_2nd_array(0));

      INST_majority_voter_wrapper2_SERDES_RST : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT         => s_serdes_rst,
          OUTPUT        => SERDES_RST,
          MISMATCH      => s_mismatch_array(1),
          MISMATCH_2ND  => s_mismatch_2nd_array(1));

      INST_majority_voter_wrapper2_RX_DATAVALID_D : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT         => s_rx_datavalid_d,
          OUTPUT        => RX_DATAVALID_D,
          MISMATCH      => s_mismatch_array(2),
          MISMATCH_2ND  => s_mismatch_2nd_array(2));

      INST_majority_voter_wrapper2_TX_DATAVALID : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT         => s_tx_datavalid,
          OUTPUT        => TX_DATAVALID,
          MISMATCH      => s_mismatch_array(3),
          MISMATCH_2ND  => s_mismatch_2nd_array(3));

      INST_majority_voter_array_wrapper_BITSLIP_RX_SYNC : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_BITSLIP_RX_CONTROL_bit'length)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT_A       => s_bitslip_rx_sync(0),
          INPUT_B       => s_bitslip_rx_sync(1),
          INPUT_C       => s_bitslip_rx_sync(2),
          OUTPUT        => BITSLIP_RX_SYNC,
          MISMATCH      => s_mismatch_array(4),
          MISMATCH_2ND  => s_mismatch_2nd_array(4));

      INST_majority_voter_array_wrapper_GBT_SENDDATA : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_GBT_PACKET_SIZE)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT_A       => s_gbt_senddata(0),
          INPUT_B       => s_gbt_senddata(1),
          INPUT_C       => s_gbt_senddata(2),
          OUTPUT        => GBT_SENDDATA,
          MISMATCH      => s_mismatch_array(5),
          MISMATCH_2ND  => s_mismatch_2nd_array(5));

    end block tmr_block;
  end generate if_TMR_generate;

end architecture Behavior;
