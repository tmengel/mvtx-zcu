-------------------------------------------------------------------------------
-- Title      : majority_voter_array_wrapper
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : majority_voter_array_wrapper2.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-03-09
-- Last update: 2017-11-02
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

entity majority_voter_array_wrapper is
  generic (
    MISMATCH_EN           : integer := 1;
    G_MISMATCH_REGISTERED : integer := 0;
    G_ADDITIONAL_MISMATCH : integer := 1;
    C_WIDTH               : integer := 16
    );
  port (
    ASSERTION_CLK : in  std_logic;
    ASSERTION_RST : in  std_logic;
    INPUT_A       : in  std_logic_vector(C_WIDTH-1 downto 0);
    INPUT_B       : in  std_logic_vector(C_WIDTH-1 downto 0);
    INPUT_C       : in  std_logic_vector(C_WIDTH-1 downto 0);
    OUTPUT        : out std_logic_vector(C_WIDTH-1 downto 0);
    MISMATCH      : out std_logic;
    MISMATCH_2ND  : out std_logic);

end entity majority_voter_array_wrapper;

architecture rtl of majority_voter_array_wrapper is

  constant C_MISMATCH_NONE          : std_logic_vector(C_WIDTH-1 downto 0) := (others => '0');
  type t_input_array is array (0 to C_WIDTH-1) of std_logic_vector(C_K_TMR-1 downto 0);
  signal s_input                    : t_input_array;
  signal s_mismatch, s_mismatch_2nd : std_logic_vector(C_WIDTH-1 downto 0);

begin  -- architecture rtl

  -- mapping A is LSB
  for_assign_generate : for i in 0 to C_WIDTH-1 generate
    s_input(i)(0) <= INPUT_A(i);
    s_input(i)(1) <= INPUT_B(i);
    s_input(i)(2) <= INPUT_C(i);

    INST_majority_voter_wrapper : entity work.majority_voter_wrapper2
      generic map (
        MISMATCH_EN           => MISMATCH_EN,
        G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
        G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
      port map (
        ASSERTION_CLK => ASSERTION_CLK,
        ASSERTION_RST => ASSERTION_RST,
        INPUT         => s_input(i),
        OUTPUT        => OUTPUT(i),
        MISMATCH      => s_mismatch(i),
        MISMATCH_2ND  => s_mismatch_2nd(i));
  end generate for_assign_generate;

  if_mismatch_gen : if MISMATCH_EN = 1 generate
    MISMATCH <= '0' when s_mismatch = C_MISMATCH_NONE else
                '1';
  end generate if_mismatch_gen;

  if_not_mismatch_gen : if MISMATCH_EN = 0 generate
    MISMATCH <= '0';
  end generate if_not_mismatch_gen;

  if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
    MISMATCH_2ND <= '0' when s_mismatch_2nd = C_MISMATCH_NONE else
                    '1';
  end generate if_add_mismatch_gen;

  if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
    MISMATCH_2ND <= '0';
  end generate if_not_add_mismatch_gen;

end architecture rtl;
