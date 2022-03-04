-------------------------------------------------------------------------------
-- Title      : mmr_register_mutliclock_wrapper
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : mmr_register_multiclock_wrapper.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-03-09
-- Last update: 2017-09-27
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: mmr_register wrapper for VHDL with TMR.
-- Refer to mmr_register.sv for more information
-- mapping: branch a is LSB, branch c is MSB
-------------------------------------------------------------------------------
-- Copyright (c) 2017 by CERN This model is the confidential and
-- proprietary property of  and the possession or use of this
-- file requires a written license from CERN.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity tmr_register_multiclock_wrapper is

  generic (
    VOTING_SCHEME : integer := -1;
    RESET_VALUE   : integer := 0;
    MISMATCH_EN   : integer := 1);
  port (
    CLK      : in  std_logic_vector(2 downto 0);
    RST      : in  std_logic;
    INPUT_A  : in  std_logic;
    INPUT_B  : in  std_logic;
    INPUT_C  : in  std_logic;
    OUTPUT_A : out std_logic;
    OUTPUT_B : out std_logic;
    OUTPUT_C : out std_logic;
    MISMATCH : out std_logic);

end entity tmr_register_multiclock_wrapper;

architecture rtl of tmr_register_multiclock_wrapper is

  constant C_K_TMR : integer := 3;      -- TMR

  component mmr_register is
    generic (
      K_MMR         : integer;
      K_MMR_CLOCK   : integer;
      VOTING_SCHEME : integer;
      RESET_VALUE   : integer;
      MISMATCH_EN   : integer);
    port (
      clk_i      : in  std_logic_vector(K_MMR_CLOCK-1 downto 0);
      rst_i      : in  std_logic;
      d_i        : in  std_logic_vector(K_MMR-1 downto 0);
      q_o        : out std_logic_vector(K_MMR-1 downto 0);
      mismatch_o : out std_logic);
  end component mmr_register;

  signal s_input, s_output : std_logic_vector(C_K_TMR-1 downto 0);

begin  -- architecture rtl

  -- mapping: a is LSB
  s_input(0) <= INPUT_A;
  s_input(1) <= INPUT_B;
  s_input(2) <= INPUT_C;

  tmr_register_INST : mmr_register
    generic map (
      K_MMR         => C_K_TMR,
      K_MMR_CLOCK   => C_K_TMR,
      VOTING_SCHEME => VOTING_SCHEME,
      RESET_VALUE   => RESET_VALUE,
      MISMATCH_EN   => MISMATCH_EN)
    port map (
      clk_i      => CLK,
      rst_i      => RST,
      d_i        => s_input,
      q_o        => s_output,
      mismatch_o => MISMATCH);

  -- mapping: a is LSB
  OUTPUT_A <= s_output(0);
  OUTPUT_A <= s_output(1);
  OUTPUT_A <= s_output(2);

end architecture rtl;
