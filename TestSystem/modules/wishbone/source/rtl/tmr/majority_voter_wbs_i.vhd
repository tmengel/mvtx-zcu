-------------------------------------------------------------------------------
-- Title      : majority_voter_wbs_i
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : majority_voter_wbs_i.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-28
-- Last update: 2017-09-27
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone wbs_i (wbs_i_type) voter
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

entity majority_voter_wbs_i is
  generic (
    MISMATCH_EN           : integer := 1;
    G_ADDITIONAL_MISMATCH : integer := 1
    );
  port (
    ASSERTION_CLK : in  std_logic;
    ASSERTION_RST : in  std_logic;
    INPUT         : in  t_wbs_i_array(0 to C_K_TMR-1);
    OUTPUT        : out wbs_i_type;
    MISMATCH      : out std_logic;
    MISMATCH_2ND  : out std_logic);

end entity majority_voter_wbs_i;

architecture rtl of majority_voter_wbs_i is

  type t_dat_array is array (C_K_TMR-1 downto 0) of std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  type t_addr_array is array (C_K_TMR-1 downto 0) of std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  signal s_we, s_cyc, s_stb : std_logic_vector(C_K_TMR-1 downto 0);
  signal s_dat              : t_dat_array;
  signal s_addr             : t_addr_array;

  constant C_MISMATCH_NONE                                                                                  : std_logic := '0';
  signal s_mismatch_cyc, s_mismatch_we, s_mismatch_stb, s_mismatch_dat, s_mismatch_addr                     : std_logic;
  signal s_mismatch_2nd_cyc, s_mismatch_2nd_we, s_mismatch_2nd_stb, s_mismatch_2nd_dat, s_mismatch_2nd_addr : std_logic;

begin  -- architecture rtl

  for_assign_generate : for i in 0 to C_K_TMR-1 generate
    s_we(i)   <= INPUT(i).we_i;
    s_cyc(i)  <= INPUT(i).cyc_i;
    s_stb(i)  <= INPUT(i).stb_i;
    s_dat(i)  <= INPUT(i).dat_i;
    s_addr(i) <= INPUT(i).addr_i;
  end generate for_assign_generate;

  INST_majority_voter_wrapper_WE : entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT         => s_we,
      OUTPUT        => OUTPUT.we_i,
      MISMATCH      => s_mismatch_we,
      MISMATCH_2ND  => s_mismatch_2nd_we);

  INST_majority_voter_wrapper_CYC : entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT         => s_cyc,
      OUTPUT        => OUTPUT.cyc_i,
      MISMATCH      => s_mismatch_cyc,
      MISMATCH_2ND  => s_mismatch_2nd_cyc);

  INST_majority_voter_wrapper_STB : entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT         => s_stb,
      OUTPUT        => OUTPUT.stb_i,
      MISMATCH      => s_mismatch_stb,
      MISMATCH_2ND  => s_mismatch_2nd_stb);

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
      OUTPUT        => OUTPUT.dat_i,
      MISMATCH      => s_mismatch_dat,
      MISMATCH_2ND  => s_mismatch_2nd_dat);

  INST_majority_voter_array_wrapper_ADDR : entity work.majority_voter_array_wrapper
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      C_WIDTH               => WB_ADDS_WIDTH)
    port map (
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT_A       => s_addr(0),
      INPUT_B       => s_addr(1),
      INPUT_C       => s_addr(2),
      OUTPUT        => OUTPUT.addr_i,
      MISMATCH      => s_mismatch_addr,
      MISMATCH_2ND  => s_mismatch_2nd_addr);

  MISMATCH <= '0' when (s_mismatch_addr = C_MISMATCH_NONE and
                        s_mismatch_dat = C_MISMATCH_NONE and
                        s_mismatch_cyc = C_MISMATCH_NONE and
                        s_mismatch_stb = C_MISMATCH_NONE and
                        s_mismatch_we = C_MISMATCH_NONE) else
              '1';


  if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
    MISMATCH_2ND <= '0' when (s_mismatch_addr = C_MISMATCH_NONE and
                              s_mismatch_dat = C_MISMATCH_NONE and
                              s_mismatch_cyc = C_MISMATCH_NONE and
                              s_mismatch_stb = C_MISMATCH_NONE and
                              s_mismatch_we = C_MISMATCH_NONE) else
                    '1';
  end generate if_add_mismatch_gen;

  if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
    MISMATCH_2ND <= '0';
  end generate if_not_add_mismatch_gen;


end architecture rtl;
