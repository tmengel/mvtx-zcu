-------------------------------------------------------------------------------
-- Title      : i2c_tmr_wrapper
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : i2c_tmr_wrapper.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2017-09-01
-- Last update: 2017-09-27
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: TMR wrapper for the i2c_wrapper
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
use work.i2c_pkg.all;
use work.tmr_pkg.all;

entity i2c_tmr_wrapper is
  port (
    -- Wishbone interface signals
    WB_CLK   : in  std_logic;           -- master clock input
    WB_RST   : in  std_logic := '0';    -- synchronous active high reset
    WB_WBS_I : in  t_wbs_i_array(0 to C_K_TMR-1);
    WB_WBS_O : out t_wbs_o_array(0 to C_K_TMR-1);

    -- i2c lines
    SCL_PAD_i : in  std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c clock line input
    SCL_PAD_o : out std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c clock line output
    SCL_PAD_T : out std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c clock line output enable, active low
    SDA_PAD_i : in  std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c data line input
    SDA_PAD_o : out std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c data line output
    SDA_PAD_T : out std_logic_vector(C_NUM_I2C-1 downto 0)  -- i2c data line output enable, active low
    );
end entity i2c_tmr_wrapper;

architecture str of i2c_tmr_wrapper is

  -- withbone slave interface
  signal s_wb_wbs_i : wbs_i_type;
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture str

  i2c_wrapper_1 : entity work.i2c_wrapper
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => s_wb_wbs_i,
      WB_WBS_O  => s_wb_wbs_o,
      SCL_PAD_i => SCL_PAD_i,
      SCL_PAD_o => SCL_PAD_o,
      SCL_PAD_T => SCL_PAD_T,
      SDA_PAD_i => SDA_PAD_i,
      SDA_PAD_o => SDA_PAD_o,
      SDA_PAD_T => SDA_PAD_T);

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
