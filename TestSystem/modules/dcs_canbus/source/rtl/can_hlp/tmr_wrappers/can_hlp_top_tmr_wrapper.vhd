-------------------------------------------------------------------------------
-- Title      : can_hlp_top_tmr_wrapper
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : can_hlp_top_tmr_wrapper.vhd
-- Author     : Simon Voigt Nesbo <svn@hvl.no>
-- Created    : 2018-05-12
-- Last update: 2018-12-17
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: TMR wrapper for the DCS CANbus HLP
--              It handles the triplication of the wishbone bus
--              Based on usb_if_tmr_wrapper.vhd by ML.
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

entity can_hlp_top_tmr_wrapper is
  generic (
    ENABLE_DEBUG               : string  := "FALSE";
    MISMATCH_EN                : integer := 1;
    MISMATCH_REGISTERED        : integer := 1;
    G_SEE_MITIGATION_TECHNIQUE : integer := 0);
  port (
    -- Wishbone slave interface
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1);

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
    CAN_RX : in  std_logic
    );
end entity can_hlp_top_tmr_wrapper;

architecture str of can_hlp_top_tmr_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i : wbs_i_type;
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture str

  INST_can_hlp_top : entity work.can_hlp_top
    port map (
      WB_CLK      => WB_CLK,
      WB_RST      => WB_RST,
      WB_WBS_I    => s_wb_wbs_i,
      WB_WBS_O    => s_wb_wbs_o,
      DP0_DT_O    => DP0_DT_O,
      DP0_EPTY_O  => DP0_EPTY_O,
      DP0_RD_I    => DP0_RD_I,
      DP1_DT_I    => DP1_DT_I,
      DP1_FULL_O  => DP1_FULL_O,
      DP1_WR_I    => DP1_WR_I,
      CAN_NODE_ID => CAN_NODE_ID,
      CAN_TX      => CAN_TX,
      CAN_RX      => CAN_RX);

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
