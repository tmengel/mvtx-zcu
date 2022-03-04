-------------------------------------------------------------------------------
-- Title      : ws_status_tmr_wrapper
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : ws_status_tmr_wrapper.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-08-03
-- Last update: 2018-04-06
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: TMR wrapper for the ws_status.
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
use work.ws_status_pkg.all;
use work.tmr_pkg.all;

entity ws_status_tmr_wrapper is
  generic (
    HASH_CODE       : std_logic_vector(2*WB_DATA_WIDTH -1 downto 0) := (others => '0');
    DATE            : std_logic_vector(3*WB_DATA_WIDTH -1 downto 0) := (others => '0');
    OS              : std_logic_vector(WB_DATA_WIDTH -1 downto 0) := (others => '0')
    );
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1)
    );

end ws_status_tmr_wrapper;

architecture str of ws_status_tmr_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i : wbs_i_type;
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture str

  INST_ws_status: entity work.ws_status
    generic map (
      HASH_CODE       => HASH_CODE,
      DATE            => DATE,
      OS              => OS)
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => s_wb_wbs_i,
      WB_WBS_O => s_wb_wbs_o);

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
