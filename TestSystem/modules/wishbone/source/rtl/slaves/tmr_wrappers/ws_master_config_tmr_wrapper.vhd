-------------------------------------------------------------------------------
-- Title      : ws_master_config_tmr_wrapper
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : ws_master_config_tmr_wrapper.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-06
-- Last update: 2017-09-27
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: TMR wrapper for the ws_master_config.
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
use work.ws_master_pkg.all;
use work.tmr_pkg.all;

entity ws_master_config_tmr_wrapper is
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1);

    -- WM ERROR COUNTERs
    -- STS registers
    WBM_RDERRCNTR     : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    WBM_WRERRCNTR     : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    WBM_SEEERRCNTR    : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    -- CMD registers
    WBM_RST_WRERRCNT  : out std_logic;
    WBM_RST_RDERRCNT  : out std_logic;
    WBM_RST_SEEERRCNT : out std_logic;
    -- MISMATCH
    MISMATCH_I        : in  std_logic_vector(C_WBMSTR_MISMATCH_WIDTH-1 downto 0)
    );

end ws_master_config_tmr_wrapper;

architecture str of ws_master_config_tmr_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i : wbs_i_type;
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture str

  INST_ws_master_config : entity work.ws_master_config
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => s_wb_wbs_i,
      WB_WBS_O => s_wb_wbs_o,

      WBM_RDERRCNTR     => WBM_RDERRCNTR,
      WBM_WRERRCNTR     => WBM_WRERRCNTR,
      WBM_SEEERRCNTR    => WBM_SEEERRCNTR,
      WBM_RST_WRERRCNT  => WBM_RST_WRERRCNT,
      WBM_RST_RDERRCNT  => WBM_RST_RDERRCNT,
      WBM_RST_SEEERRCNT => WBM_RST_SEEERRCNT,

      MISMATCH_I => MISMATCH_I
      );

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
