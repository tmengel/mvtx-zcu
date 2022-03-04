-------------------------------------------------------------------------------
-- Title      : majority_voter_triplicated_wrapper
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : majority_voter_triplicated_wrapper.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-09-04
-- Last update: 2017-11-02
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: VHDL wrapper to ease instantiation into vhdl entities of the sv
--              majority_voter_triplicated
-------------------------------------------------------------------------------
-- Copyright (c) 2017 by CERN This model is the confidential and
-- proprietary property of  and the possession or use of this
-- file requires a written license from CERN.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.tmr_pkg.all;

entity majority_voter_triplicated_wrapper is

  generic (
    MISMATCH_EN           : integer := 1;
    G_MISMATCH_REGISTERED : integer := 0;
    G_ADDITIONAL_MISMATCH : integer := 1
    );
  port (
    ASSERTION_CLK : in  std_logic;
    ASSERTION_RST : in  std_logic;
    INPUT         : in  std_logic_vector(C_K_TMR-1 downto 0);
    OUTPUT        : out std_logic_vector(C_K_TMR-1 downto 0);
    MISMATCH      : out std_logic;
    MISMATCH_2ND  : out std_logic);

end entity majority_voter_triplicated_wrapper;

architecture rtl of majority_voter_triplicated_wrapper is

  component majority_voter_triplicated
    generic(
      K_MMR                 : integer := 3;
      MISMATCH_EN           : integer := 1;
      G_MISMATCH_REGISTERED : integer := 0;
      G_ADDITIONAL_MISMATCH : integer := 1);
    port(
      assert_clk_i   : in  std_logic;
      assert_rst_i   : in  std_logic;
      input_i        : in  std_logic_vector (K_MMR-1 downto 0);
      output_o       : out std_logic_vector (K_MMR-1 downto 0);
      mismatch_o     : out std_logic;
      mismatch_2nd_o : out std_logic
      );
  end component;

begin  -- architecture rtl

  INST_majority_voter_triplicated : majority_voter_triplicated
    generic map (
      K_MMR                 => C_K_TMR,
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map (
      assert_clk_i   => ASSERTION_CLK,
      assert_rst_i   => ASSERTION_RST,
      input_i        => INPUT,
      output_o       => OUTPUT,
      mismatch_o     => MISMATCH,
      mismatch_2nd_o => MISMATCH_2ND);

end architecture rtl;
