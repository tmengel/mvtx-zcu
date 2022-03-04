-------------------------------------------------------------------------------
-- Title      : dp_mux
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : probecard_top.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-05-30
-- Last update: 2016-12-05
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Mux for the DP2/3 to have multiple data producers on the single
--              data point
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-05-30  1.0      mlupi   Created
-- 2016-10-04  1.1      ML      Added configurable input ports number
-- 2016-10-17  1.2      ML      Fixed bug on enable of single data generator
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

--library work;
use work.dp_mux_pkg.all;
use work.dataout_format_pkg.all;

entity dp_mux is
  generic (
    WBCLK_DPCLK_ARE_DIFFERENT : boolean := FALSE;
    DP_SELECT_WIDTH           : natural := 3);
  port(
    DP_WRCLK  : in std_logic;
    DP_RST    : in std_logic;
    DP_SELECT : in std_logic_vector(DP_SELECT_WIDTH-1 downto 0);

    -- data generator side
    DPO_TOFIFO_I   : in  t_fifo_wrif_tofifo_array(0 to (2**DP_SELECT_WIDTH)-1) := (others => C_FIFO_WRIF_TOFIFO_DEFAULT);
    DPO_FROMFIFO_O : out t_fifo_wrif_fromfifo_array(0 to (2**DP_SELECT_WIDTH)-1);

    -- fifo side
    DPO_FROMFIFO_I : in  t_fifo_wrif_fromfifo;
    DPO_TOFIFO_O   : out t_fifo_wrif_tofifo);
end entity dp_mux;

architecture std of dp_mux is

  component xclk_reg is
    generic (
      SIZE          : integer;
      DOUBLE_BUFFER : boolean);
    port (
      RESET  : in  std_logic;
      INPUT  : in  std_logic_vector(SIZE-1 downto 0);
      CLK    : in  std_logic;
      OUTPUT : out std_logic_vector(SIZE-1 downto 0));
  end component xclk_reg;

  -----------------------------------------------------------------------------
  -- Synchronize Wbclk to RxusrClk
  -----------------------------------------------------------------------------
  constant C_SYNC_WB2DPCLK_SIZE             : natural := DP_SELECT_WIDTH;
  signal sync_wb2dpclk_wb, sync_wb2dpclk_dp : std_logic_vector(C_SYNC_WB2DPCLK_SIZE - 1 downto 0);
  signal s_dp_select_dp                     : std_logic_vector(C_SYNC_WB2DPCLK_SIZE - 1 downto 0);

  signal s_selected_tofifo : t_fifo_wrif_tofifo;
  signal i_dp_select_dp    : natural;

begin

  -----------------------------------------------------------------------------
  -- xclk_reassignment in case of different clock frequencies between DP_select
  -- and wrclk
  -----------------------------------------------------------------------------

  sync_wb2dpclk_wb <= DP_SELECT;
  xclk_reg_wb2dpclk : xclk_reg
    generic map (
      SIZE          => sync_wb2dpclk_wb'length,
      DOUBLE_BUFFER => TRUE)
    port map (
      CLK    => DP_WRCLK,
      RESET  => DP_RST,
      INPUT  => sync_wb2dpclk_wb,
      OUTPUT => sync_wb2dpclk_dp);

  s_dp_select_dp <= sync_wb2dpclk_dp when WBCLK_DPCLK_ARE_DIFFERENT else
                    DP_SELECT;

  -----------------------------------------------------------------------------
  -- to DP
  -----------------------------------------------------------------------------

  i_dp_select_dp    <= to_integer(unsigned(s_dp_select_dp));
  s_selected_tofifo <= DPO_TOFIFO_I(i_dp_select_dp);

  DPO_TOFIFO_O.DT <= s_dp_select_dp(2 downto 0) & s_selected_tofifo.DT(c_inport-1 downto 0);
  DPO_TOFIFO_O.WR <= s_selected_tofifo.WR;

  -----------------------------------------------------------------------------
  -- from DP to DP0
  -----------------------------------------------------------------------------

  forgenerate_FROMFIFO : for i in 0 to (2**DP_SELECT_WIDTH)-1 generate
    DPO_FROMFIFO_O(i).FULL <= DPO_FROMFIFO_I.FULL when i_dp_select_dp = i else
                              C_FIFO_WRIF_FROMFIFO_DEFAULT.FULL;
    DPO_FROMFIFO_O(i).AFULL <= DPO_FROMFIFO_I.AFULL when i_dp_select_dp = i else
                               C_FIFO_WRIF_FROMFIFO_DEFAULT.AFULL;
    DPO_FROMFIFO_O(i).EPTY <= DPO_FROMFIFO_I.EPTY when i_dp_select_dp = i else
                              C_FIFO_WRIF_FROMFIFO_DEFAULT.EPTY;
    DPO_FROMFIFO_O(i).AEPTY <= DPO_FROMFIFO_I.AEPTY when i_dp_select_dp = i else
                               C_FIFO_WRIF_FROMFIFO_DEFAULT.AEPTY;
    DPO_FROMFIFO_O(i).DONE <= DPO_FROMFIFO_I.DONE when i_dp_select_dp = i else
                              C_FIFO_WRIF_FROMFIFO_DEFAULT.DONE;
    DPO_FROMFIFO_O(i).RX_EN <= '1' when i_dp_select_dp = i else
                               C_FIFO_WRIF_FROMFIFO_DEFAULT.RX_EN;
  end generate forgenerate_FROMFIFO;

end architecture std;
