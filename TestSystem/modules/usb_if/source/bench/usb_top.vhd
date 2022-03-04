-------------------------------------------------------------------------------
-- Title      : Usb Top Level Wrapper
-- Project    :
-------------------------------------------------------------------------------
-- File       : usb_top.vhd
-- Author     : Matthias Bonora  <matthias.bonora@cern.ch>
-- Company    : University of Salzburg / CERN
-- Created    : 2015-11-17
-- Last update: 2017-03-13
-- Platform   : CERN OS7, Xilinx Vivado 2015.3
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for usb_if toplevel entity
--              - Records to logic vectors
--              - I/O/T signals to inout buffers
-------------------------------------------------------------------------------
-- Copyright (c) 2015
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-11-17  1.0      mbonora	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone interface package
use work.intercon_pkg.all;

entity usb_top is

  port (
    WB_CLK : in std_logic;
    WB_RST : in std_logic;
    WB_ADDR_O : out std_logic_vector(11 downto 0);
    WB_DAT_I : in std_logic_vector(15 downto 0);
    WB_DAT_O  : out std_logic_vector(15 downto 0);
    WB_ERR_I : in std_logic;
    WB_ACK_I : in std_logic;
    WB_WE_O   : out std_logic;
    WB_CYC_O  : out std_logic;
    WB_STB_O  : out std_logic;

    -- USB signals
    CLK                 : in  std_logic;  -- 100 MHz
    RST                 : in  std_logic;
    FX3_I2C_SCL         : in  std_logic;
    FX3_I2C_SDA_i       : in  std_logic;
    FX3_I2C_SDA_o       : out std_logic;
    FX3_I2C_SDA_T       : out std_logic;
    FX3_UART_RX         : out std_logic;
    FX3_UART_TX         : in  std_logic;
    FX3_GPIF_II_DQ_i    : in  std_logic_vector(31 downto 0);
    FX3_GPIF_II_DQ_o    : out std_logic_vector(31 downto 0);
    FX3_GPIF_II_DQ_T    : out std_logic;
    FX3_GPIF_II_CTL_i   : in  std_logic_vector(12 downto 0);
    FX3_GPIF_II_CTL_o   : out std_logic_vector(12 downto 0);
    FX3_GPIF_II_CTL_T   : out std_logic_vector(12 downto 0);
    FX3_GPIF_II_PCLK    : out std_logic;
    FX3_GPIF_II_INT_n   : out std_logic;
    FX3_GPIF_II_RESET_n : out std_logic;
    -- DATA PORT 2 INTERFACE
    CLK_DP2_WR_I        : in  std_logic;
    DPO2_DTI_I          : in  std_logic_vector(31 downto 0);
    DPO2_FULL_O         : out std_logic;
    DPO2_ALMST_FULL_O   : out std_logic;
    DPO2_WR_I           : in  std_logic;
    -- DATA PORT 3 INTERFACE
    CLK_DP3_WR_I        : in  std_logic;
    DPO3_DTI_I          : in  std_logic_vector(31 downto 0);
    DPO3_FULL_O         : out std_logic;
    DPO3_ALMST_FULL_O   : out std_logic;
    DPO3_WR_I           : in  std_logic
    );

end entity usb_top;

architecture bhv of usb_top is
  signal WB_WBM_I            : wbm_i_type;
  signal WB_WBM_O            : wbm_o_type;
begin  -- architecture bhv

  WB_WBM_I.dat_i <= WB_dat_i;
  WB_WBM_I.err_i <= WB_err_i;
  WB_WBM_I.ack_i <= WB_ack_i;

  WB_addr_o <= WB_WBM_O.addr_o;
  WB_dat_o <= WB_WBM_O.dat_o;
  WB_we_o  <= WB_WBM_O.we_o;
  WB_cyc_o <= WB_WBM_O.cyc_o;
  WB_stb_o <= WB_WBM_O.stb_o;

  usb_if_1: entity work.usb_if
    port map (
      WB_CLK              => WB_CLK,
      WB_RST              => WB_RST,
      WB_WBM_I            => WB_WBM_I,
      WB_WBM_O            => WB_WBM_O,
      CLK                 => CLK,
      RST                 => RST,
      FX3_I2C_SCL         => FX3_I2C_SCL,
      FX3_I2C_SDA_i       => FX3_I2C_SDA_i,
      FX3_I2C_SDA_o       => FX3_I2C_SDA_o,
      FX3_I2C_SDA_T       => FX3_I2C_SDA_T,
      FX3_UART_RX         => FX3_UART_RX,
      FX3_UART_TX         => FX3_UART_TX,
      FX3_GPIF_II_DQ_i    => FX3_GPIF_II_DQ_i,
      FX3_GPIF_II_DQ_o    => FX3_GPIF_II_DQ_o,
      FX3_GPIF_II_DQ_T    => FX3_GPIF_II_DQ_T,
      FX3_GPIF_II_CTL_i   => FX3_GPIF_II_CTL_i,
      FX3_GPIF_II_CTL_o   => FX3_GPIF_II_CTL_o,
      FX3_GPIF_II_CTL_T   => FX3_GPIF_II_CTL_T,
      FX3_GPIF_II_PCLK    => FX3_GPIF_II_PCLK,
      FX3_GPIF_II_INT_n   => FX3_GPIF_II_INT_n,
      FX3_GPIF_II_RESET_n => FX3_GPIF_II_RESET_n,
      CLK_DP2_WR_I        => CLK_DP2_WR_I,
      DPO2_DTI_I          => DPO2_DTI_I,
      DPO2_FULL_O         => DPO2_FULL_O,
      DPO2_ALMST_FULL_O   => DPO2_ALMST_FULL_O,
      DPO2_WR_I           => DPO2_WR_I,
      CLK_DP3_WR_I        => CLK_DP3_WR_I,
      DPO3_DTI_I          => DPO3_DTI_I,
      DPO3_FULL_O         => DPO3_FULL_O,
      DPO3_ALMST_FULL_O   => DPO3_ALMST_FULL_O,
      DPO3_WR_I           => DPO3_WR_I);

end architecture bhv;
