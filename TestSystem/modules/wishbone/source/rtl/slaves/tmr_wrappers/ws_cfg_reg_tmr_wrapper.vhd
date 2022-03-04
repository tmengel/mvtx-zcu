-------------------------------------------------------------------------------
-- Title      : ws_cfg_reg_tmr_wrapper
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : ws_cfg_reg_tmr_wrapper.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2017-09-01
-- Last update: 2017-09-27
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex US
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: TMR wrapper for the ws_cfg_reg_wrapper
--              It handles the triplication of the wishbone bus
-------------------------------------------------------------------------------
-- Copyright (c) 2017 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone interface package
library work;
use work.intercon_pkg.all;
use work.tmr_pkg.all;
use work.wishbone_MM.all;

entity ws_cfg_reg_tmr_wrapper is
  generic (
    CONFIG_REG_DEFAULT : t_sRegister_ws_cfg);
  port (
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1);
    CFG_BUS  : out t_cfg_bus);
end;

architecture str of ws_cfg_reg_tmr_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i : wbs_i_type;
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture str

  INST_ws_cfg_reg: entity work.ws_cfg_reg
  generic map (
    CONFIG_REG_DEFAULT => CONFIG_REG_DEFAULT)
  port map (
    WB_CLK   => WB_CLK,
    WB_RST   => WB_RST,
      WB_WBS_I  => s_wb_wbs_i,
      WB_WBS_O  => s_wb_wbs_o,
    CFG_BUS  => CFG_BUS);

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
