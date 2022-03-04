-------------------------------------------------------------------------------
-- Title      : majority_voter_wrapper2
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : majority_voter_wrapper2.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-03-09
-- Last update: 2017-10-17
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: majority_voter wrapper for VHDL with TMR.
-- Refer to majority_voter.sv for more information
-------------------------------------------------------------------------------
-- Copyright (c) 2017 by CERN This model is the confidential and
-- proprietary property of  and the possession or use of this
-- file requires a written license from CERN.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-03-09  1.0      mlupi   created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.tmr_pkg.all;

entity majority_voter_wrapper2 is

  generic (
    MISMATCH_EN           : integer := 1;
    G_MISMATCH_REGISTERED : integer := 0;
    G_ADDITIONAL_MISMATCH : integer := 1
    );
  port (
    ASSERTION_CLK : in  std_logic;
    ASSERTION_RST : in  std_logic;
    INPUT         : in  std_logic_vector(C_K_TMR-1 downto 0);
    OUTPUT        : out std_logic;
    MISMATCH      : out std_logic;
    MISMATCH_2ND  : out std_logic);

end entity majority_voter_wrapper2;

architecture rtl of majority_voter_wrapper2 is

  component majority_voter_packed is
    generic (
      K_MMR                 : integer;
      MISMATCH_EN           : integer;
      G_ADDITIONAL_MISMATCH : integer;
      G_MISMATCH_REGISTERED : integer);
    port (
      assert_clk_i   : in  std_logic;
      assert_rst_i   : in  std_logic;
      input_i        : in  std_logic_vector(K_MMR-1 downto 0);
      output_o       : out std_logic;
      mismatch_o     : out std_logic;
      mismatch_2nd_o : out std_logic);
  end component majority_voter_packed;

  signal s_input : std_logic_vector(C_K_TMR-1 downto 0);

begin  -- architecture rtl

  -- mapping A is LSB
  for_assign_generate : for i in 0 to C_K_TMR-1 generate
    s_input(i) <= INPUT(i);
  end generate for_assign_generate;

  majority_voter_INST : majority_voter_packed
    generic map (
      K_MMR                 => C_K_TMR,
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED)
    port map (
      assert_clk_i   => ASSERTION_CLK,
      assert_rst_i   => ASSERTION_RST,
      input_i        => s_input,
      output_o       => OUTPUT,
      mismatch_o     => MISMATCH,
      mismatch_2nd_o => MISMATCH_2ND);

end architecture rtl;
