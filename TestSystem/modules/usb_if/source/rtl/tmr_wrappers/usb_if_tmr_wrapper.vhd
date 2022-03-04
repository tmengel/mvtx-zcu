-------------------------------------------------------------------------------
-- Title      : ws_status_tmr_wrapper
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : ws_status_tmr_wrapper.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-08-03
-- Last update: 2017-09-27
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: TMR wrapper for the usb_if.
--              It handles the triplication of the wishbone bus
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone interface package
library work;
use work.intercon_pkg.all;
use work.tmr_pkg.all;

entity usb_if_tmr_wrapper is
  generic (
    ENABLE_DEBUG               : string  := "FALSE";
    DP_SELECT_WIDTH            : integer := 3;
    MISMATCH_EN                : integer := 1;
    MISMATCH_REGISTERED        : integer := 1;
    G_SEE_MITIGATION_TECHNIQUE : integer := 0);
  port (
    -- Wishbone slave interface
    WB_CLK               : in  std_logic;
    WB_RST               : in  std_logic;
    WB_WBS_I             : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O             : out t_wbs_o_array(0 to C_K_TMR-1);
    -- USB interface signals
    CLK                  : in  std_logic;  -- 100 MHz
    RST                  : in  std_logic;
    FX3_UART_RX          : out std_logic;
    FX3_UART_TX          : in  std_logic;
    FX3_GPIF_II_DQ_i     : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    FX3_GPIF_II_DQ_o     : out std_logic_vector(GPIF_WIDTH-1 downto 0);
    FX3_GPIF_II_DQ_T     : out std_logic;
    FX3_GPIF_II_CTL_i    : in  std_logic_vector(GPIF_CTL_WIDTH-1 downto 0);
    FX3_GPIF_II_CTL_o    : out std_logic_vector(GPIF_CTL_WIDTH-1 downto 0);
    FX3_GPIF_II_CTL_T    : out std_logic_vector(GPIF_CTL_WIDTH-1 downto 0);
    FX3_GPIF_II_PCLK     : out std_logic;
    FX3_GPIF_II_INT_n    : out std_logic;
    FX3_GPIF_II_RESET_n  : out std_logic;
    -- DATA PORT 0 INTERFACE
    DP0_RDCLK_I          : in  std_logic;
    DP0_DT_O             : out std_logic_vector(GPIF_WIDTH-1 downto 0);
    DP0_EPTY_O           : out std_logic;
    DP0_RD_I             : in  std_logic;
    -- DATA PORT 1 INTERFACE
    DP1_WRCLK_I          : in  std_logic;
    DP1_DT_I             : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    DP1_WR_I             : in  std_logic;
    DP1_FULL_O           : out std_logic;
    -- DATA PORT 2 INTERFACE
    CLK_DP2_WR_I         : in  std_logic;
    DPO2_DTI_I           : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    DPO2_FULL_O          : out std_logic;
    DPO2_ALMST_FULL_O    : out std_logic;
    DPO2_WR_I            : in  std_logic;
    DPO2_EPTY_O          : out std_logic;
    DPO2_DONE_O          : out std_logic;
    DPO2_RST_WRCLK_I     : in  std_logic;
    DPO2_PRODUCER_SELECT : out std_logic_vector(DP_SELECT_WIDTH-1 downto 0);
    -- DATA PORT 3 INTERFACE
    CLK_DP3_WR_I         : in  std_logic;
    DPO3_DTI_I           : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    DPO3_FULL_O          : out std_logic;
    DPO3_ALMST_FULL_O    : out std_logic;
    DPO3_WR_I            : in  std_logic;
    DPO3_EPTY_O          : out std_logic;
    DPO3_DONE_O          : out std_logic;
    DPO3_RST_WRCLK_I     : in  std_logic;
    DPO3_PRODUCER_SELECT : out std_logic_vector(DP_SELECT_WIDTH-1 downto 0)
    );
end entity usb_if_tmr_wrapper;

architecture str of usb_if_tmr_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i : wbs_i_type;
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture str

  INST_usb_if : entity work.usb_if
    generic map (
      ENABLE_DEBUG               => ENABLE_DEBUG,
      DP_SELECT_WIDTH            => DP_SELECT_WIDTH,
      MISMATCH_EN                => MISMATCH_EN,
      MISMATCH_REGISTERED        => MISMATCH_REGISTERED,
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE)
    port map (
      WB_CLK               => WB_CLK,
      WB_RST               => WB_RST,
      WB_WBS_I             => s_wb_wbs_i,
      WB_WBS_O             => s_wb_wbs_o,
      CLK                  => CLK,
      RST                  => RST,
      FX3_UART_RX          => FX3_UART_RX,
      FX3_UART_TX          => FX3_UART_TX,
      FX3_GPIF_II_DQ_i     => FX3_GPIF_II_DQ_i,
      FX3_GPIF_II_DQ_o     => FX3_GPIF_II_DQ_o,
      FX3_GPIF_II_DQ_T     => FX3_GPIF_II_DQ_T,
      FX3_GPIF_II_CTL_i    => FX3_GPIF_II_CTL_i,
      FX3_GPIF_II_CTL_o    => FX3_GPIF_II_CTL_o,
      FX3_GPIF_II_CTL_T    => FX3_GPIF_II_CTL_T,
      FX3_GPIF_II_PCLK     => FX3_GPIF_II_PCLK,
      FX3_GPIF_II_INT_n    => FX3_GPIF_II_INT_n,
      FX3_GPIF_II_RESET_n  => FX3_GPIF_II_RESET_n,
      DP0_RDCLK_I          => DP0_RDCLK_I,
      DP0_DT_O             => DP0_DT_O,
      DP0_EPTY_O           => DP0_EPTY_O,
      DP0_RD_I             => DP0_RD_I,
      DP1_WRCLK_I          => DP1_WRCLK_I,
      DP1_DT_I             => DP1_DT_I,
      DP1_WR_I             => DP1_WR_I,
      DP1_FULL_O           => DP1_FULL_O,
      CLK_DP2_WR_I         => CLK_DP2_WR_I,
      DPO2_DTI_I           => DPO2_DTI_I,
      DPO2_FULL_O          => DPO2_FULL_O,
      DPO2_ALMST_FULL_O    => DPO2_ALMST_FULL_O,
      DPO2_WR_I            => DPO2_WR_I,
      DPO2_EPTY_O          => DPO2_EPTY_O,
      DPO2_DONE_O          => DPO2_DONE_O,
      DPO2_RST_WRCLK_I     => DPO2_RST_WRCLK_I,
      DPO2_PRODUCER_SELECT => DPO2_PRODUCER_SELECT,
      CLK_DP3_WR_I         => CLK_DP3_WR_I,
      DPO3_DTI_I           => DPO3_DTI_I,
      DPO3_FULL_O          => DPO3_FULL_O,
      DPO3_ALMST_FULL_O    => DPO3_ALMST_FULL_O,
      DPO3_WR_I            => DPO3_WR_I,
      DPO3_EPTY_O          => DPO3_EPTY_O,
      DPO3_DONE_O          => DPO3_DONE_O,
      DPO3_RST_WRCLK_I     => DPO3_RST_WRCLK_I,
      DPO3_PRODUCER_SELECT => DPO3_PRODUCER_SELECT);

  -- implementation with array of WBS inputs
  INST_majority_voter_wbs_i : entity work.majority_voter_wbs_i
    generic map (
      --MISMATCH_EN           => MISMATCH_EN, -- temporary, remove after slave is protected
      MISMATCH_EN           => 0,
      G_ADDITIONAL_MISMATCH => 0)
    port map (
      ASSERTION_CLK => WB_CLK,
      ASSERTION_RST => WB_RST,
      INPUT         => WB_WBS_I,
      OUTPUT        => s_wb_wbs_i,
      MISMATCH      => open,
      MISMATCH_2ND  => open);

  WB_WBS_O(0) <= s_wb_wbs_o;
  WB_WBS_O(1) <= s_wb_wbs_o;
  WB_WBS_O(2) <= s_wb_wbs_o;

end architecture str;
