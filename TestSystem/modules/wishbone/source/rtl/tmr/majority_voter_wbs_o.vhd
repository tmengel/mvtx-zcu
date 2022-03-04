-------------------------------------------------------------------------------
-- Title      : majority_voter_wbs_o
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : majority_voter_wbs_o.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-28
-- Last update: 2017-09-27
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone wbs_o (wbs_o_type) voter
-------------------------------------------------------------------------------
-- Copyright (c) 2017 by CERN This model is the confidential and
-- proprietary property of  and the possession or use of this
-- file requires a written license from CERN.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.intercon_pkg.all;
use work.tmr_pkg.all;

entity majority_voter_wbs_o is
  generic (
    MISMATCH_EN           : integer := 1;
    G_ADDITIONAL_MISMATCH : integer := 1
    );
  port (
    ASSERTION_CLK : in  std_logic;
    ASSERTION_RST : in  std_logic;
    INPUT         : in  t_wbs_o_array(0 to C_K_TMR-1);
    OUTPUT        : out wbs_o_type;
    MISMATCH      : out std_logic;
    MISMATCH_2ND  : out std_logic);

end entity majority_voter_wbs_o;

architecture rtl of majority_voter_wbs_o is

  type t_dat_array is array (C_K_TMR-1 downto 0) of std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_err, s_ack : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_dat        : t_dat_array;
  signal s_output     : wbs_o_type;

  attribute DONT_TOUCH             : string;
  attribute DONT_TOUCH of s_dat    : signal is "TRUE";
  attribute DONT_TOUCH of s_ack    : signal is "TRUE";
  attribute DONT_TOUCH of s_err    : signal is "TRUE";
  attribute DONT_TOUCH of s_output : signal is "TRUE";

  constant C_MISMATCH_NONE                                          : std_logic := '0';
  signal s_mismatch_err, s_mismatch_ack, s_mismatch_dat             : std_logic;
  signal s_mismatch_2nd_err, s_mismatch_2nd_ack, s_mismatch_2nd_dat : std_logic;

begin  -- architecture rtl

  OUTPUT <= s_output;

  for_assign_generate : for i in 0 to C_K_TMR-1 generate
    s_err(i) <= INPUT(i).err_o;
    s_ack(i) <= INPUT(i).ack_o;
    s_dat(i) <= INPUT(i).dat_o;
  end generate for_assign_generate;

  INST_majority_voter_wrapper_ERR : entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT         => s_err,
      OUTPUT        => s_output.err_o,
      MISMATCH      => s_mismatch_err,
      MISMATCH_2ND  => s_mismatch_2nd_err);

  INST_majority_voter_wrapper_ACK : entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT         => s_ack,
      OUTPUT        => s_output.ack_o,
      MISMATCH      => s_mismatch_ack,
      MISMATCH_2ND  => s_mismatch_2nd_ack);

  INST_majority_voter_array_wrapper_DAT : entity work.majority_voter_array_wrapper
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      C_WIDTH               => WB_DATA_WIDTH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT_A       => s_dat(0),
      INPUT_B       => s_dat(1),
      INPUT_C       => s_dat(2),
      OUTPUT        => s_output.dat_o,
      MISMATCH      => s_mismatch_dat,
      MISMATCH_2ND  => s_mismatch_2nd_dat);

  MISMATCH <= '0' when (s_mismatch_dat = C_MISMATCH_NONE and
                        s_mismatch_ack = C_MISMATCH_NONE and
                        s_mismatch_err = C_MISMATCH_NONE) else
              '1';

  if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
    MISMATCH_2ND <= '0' when (s_mismatch_dat = C_MISMATCH_NONE and
                              s_mismatch_ack = C_MISMATCH_NONE and
                              s_mismatch_err = C_MISMATCH_NONE) else
                    '1';
  end generate if_add_mismatch_gen;

  if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
    MISMATCH_2ND <= '0';
  end generate if_not_add_mismatch_gen;


end architecture rtl;
