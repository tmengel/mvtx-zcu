-------------------------------------------------------------------------------
-- Title      : majority_voter_wbs_i
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : majority_voter_wbs_i.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-28
-- Last update: 2017-11-02
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

entity majority_voter_triplicated_wbs_i is
  generic(
    MISMATCH_EN           : integer := 1;
    G_ADDITIONAL_MISMATCH : integer := 1;
    G_MISMATCH_REGISTERED : integer := 0
  );
  port(
    ASSERTION_CLK : in  std_logic;
    ASSERTION_RST : in  std_logic;
    INPUT         : in  t_wbs_i_array(0 to C_K_TMR - 1);
    OUTPUT        : out t_wbs_i_array(0 to C_K_TMR - 1);
    MISMATCH      : out std_logic;
    MISMATCH_2ND  : out std_logic);

end entity majority_voter_triplicated_wbs_i;

architecture rtl of majority_voter_triplicated_wbs_i is

  component majority_voter_triplicated
    generic(K_MMR                 : integer := 3;
            MISMATCH_EN           : integer := 1;
            G_MISMATCH_REGISTERED : integer := 0;
            G_ADDITIONAL_MISMATCH : integer := 1
           );
    port(
      assert_clk_i   : in  std_logic;
      assert_rst_i   : in  std_logic;
      input_i        : in  std_logic_vector(K_MMR - 1 downto 0);
      mismatch_o     : out std_logic;
      mismatch_2nd_o : out std_logic;
      output_o       : out std_logic_vector(K_MMR - 1 downto 0)
    );
  end component;

  type t_dat_array  is array (C_K_TMR - 1 downto 0) of std_logic_vector(WB_DATA_WIDTH - 1 downto 0);
  type t_addr_array is array (C_K_TMR - 1 downto 0) of std_logic_vector(WB_ADDS_WIDTH - 1 downto 0);
  signal s_we_in, s_cyc_in, s_stb_in    : std_logic_vector(C_K_TMR - 1 downto 0);
  signal s_we_out, s_cyc_out, s_stb_out : std_logic_vector(C_K_TMR - 1 downto 0);
  signal s_dat_in, s_dat_out            : t_dat_array;
  signal s_addr_in, s_addr_out          : t_addr_array;
  signal s_output                       : t_wbs_i_array(0 to C_K_TMR - 1);

  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of s_dat_in    : signal is "TRUE";
  attribute DONT_TOUCH of s_addr_in   : signal is "TRUE";
  attribute DONT_TOUCH of s_stb_in    : signal is "TRUE";
  attribute DONT_TOUCH of s_cyc_in    : signal is "TRUE";
  attribute DONT_TOUCH of s_we_in     : signal is "TRUE";
  attribute DONT_TOUCH of s_dat_out   : signal is "TRUE";
  attribute DONT_TOUCH of s_addr_out  : signal is "TRUE";
  attribute DONT_TOUCH of s_stb_out   : signal is "TRUE";
  attribute DONT_TOUCH of s_cyc_out   : signal is "TRUE";
  attribute DONT_TOUCH of s_we_out    : signal is "TRUE";
  attribute DONT_TOUCH of s_output    : signal is "TRUE";

  constant C_MISMATCH_NONE                                                                                  : std_logic := '0';
  signal s_mismatch_cyc, s_mismatch_we, s_mismatch_stb, s_mismatch_dat, s_mismatch_addr                     : std_logic;
  signal s_mismatch_2nd_cyc, s_mismatch_2nd_we, s_mismatch_2nd_stb, s_mismatch_2nd_dat, s_mismatch_2nd_addr : std_logic;

begin                                   -- architecture rtl

  OUTPUT <= s_output;

  for_assign_generate : for i in 0 to C_K_TMR - 1 generate
    s_we_in(i)         <= INPUT(i).we_i;
    s_cyc_in(i)        <= INPUT(i).cyc_i;
    s_stb_in(i)        <= INPUT(i).stb_i;
    s_dat_in(i)        <= INPUT(i).dat_i;
    s_addr_in(i)       <= INPUT(i).addr_i;
    s_output(i).we_i   <= s_we_out(i);
    s_output(i).dat_i  <= s_dat_out(i);
    s_output(i).cyc_i  <= s_cyc_out(i);
    s_output(i).stb_i  <= s_stb_out(i);
    s_output(i).addr_i <= s_addr_out(i);
  end generate for_assign_generate;

  INST_majority_voter_wrapper_WE : majority_voter_triplicated
    generic map(
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map(
      assert_clk_i   => ASSERTION_CLK,
      assert_rst_i   => ASSERTION_RST,
      input_i        => s_we_in,
      output_o       => s_we_out,
      mismatch_o     => s_mismatch_we,
      mismatch_2nd_o => s_mismatch_2nd_we);

  INST_majority_voter_wrapper_CYC : majority_voter_triplicated
    generic map(
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map(
      assert_clk_i   => ASSERTION_CLK,
      assert_rst_i   => ASSERTION_RST,
      input_i        => s_cyc_in,
      output_o       => s_cyc_out,
      mismatch_o     => s_mismatch_cyc,
      mismatch_2nd_o => s_mismatch_2nd_cyc);

  INST_majority_voter_wrapper_STB : majority_voter_triplicated
    generic map(
      MISMATCH_EN           => MISMATCH_EN,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
    port map(
      assert_clk_i   => ASSERTION_CLK,
      assert_rst_i   => ASSERTION_RST,
      input_i        => s_stb_in,
      output_o       => s_stb_out,
      mismatch_o     => s_mismatch_stb,
      mismatch_2nd_o => s_mismatch_2nd_stb);

  INST_majority_voter_array_wrapper_DAT : entity work.majority_voter_triplicated_array_wrapper
    generic map(
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      C_WIDTH               => WB_DATA_WIDTH)
    port map(
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT_A       => s_dat_in(0),
      INPUT_B       => s_dat_in(1),
      INPUT_C       => s_dat_in(2),
      OUTPUT_A      => s_dat_out(0),
      OUTPUT_B      => s_dat_out(1),
      OUTPUT_C      => s_dat_out(2),
      MISMATCH      => s_mismatch_dat,
      MISMATCH_2ND  => s_mismatch_2nd_dat);

  INST_majority_voter_array_wrapper_ADDR : entity work.majority_voter_triplicated_array_wrapper
    generic map(
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED,
      C_WIDTH               => WB_ADDS_WIDTH)
    port map(
      ASSERTION_CLK => ASSERTION_CLK,
      ASSERTION_RST => ASSERTION_RST,
      INPUT_A       => s_addr_in(0),
      INPUT_B       => s_addr_in(1),
      INPUT_C       => s_addr_in(2),
      OUTPUT_A      => s_addr_out(0),
      OUTPUT_B      => s_addr_out(1),
      OUTPUT_C      => s_addr_out(2),
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
