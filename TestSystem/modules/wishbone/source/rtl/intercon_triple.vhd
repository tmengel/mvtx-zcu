-------------------------------------------------------------------------------
-- Title      : intercon
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : intercon.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-02-26
-- Last update: 2018-04-13
-- Platform   : Vivado 2015.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Intercon entity (wishbone bus)
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- 2016-02-26  1.0      ML        Created
-- 2018-03-23  1.1      ML        Configurable number of masters
-- 2018-04-09  1.2      ML        Updated TMR for wb_arbiter counter
-------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library work;
use work.tmr_pkg.all;
use work.intercon_pkg.all;

entity intercon_triple is
  generic(
    G_WB_MASTER_NUMBER         : natural := 2;  -- defined to avoid package entanglement
    G_WB_SLAVE_NUMBER          : natural := 8;  -- defined to avoid package entanglement
    G_SEE_MITIGATION_TECHNIQUE : natural := 0);
  port(
    -- wishbone master port(s)
    wbm_wbm_i : out t_wbm_i_matrix(0 to G_WB_MASTER_NUMBER-1);
    wbm_wbm_o : in  t_wbm_o_matrix(0 to G_WB_MASTER_NUMBER-1);
    -- wishbone slave port(s)
    wbs_wbs_i : out t_wbs_i_matrix(0 to G_WB_SLAVE_NUMBER - 1);
    wbs_wbs_o : in  t_wbs_o_matrix(0 to G_WB_SLAVE_NUMBER - 1);
    -- clock and reset
    clk       : in  std_logic;
    reset     : in  std_logic
    );
  attribute DONT_TOUCH                    : string;
  attribute DONT_TOUCH of intercon_triple : entity is "true";
end intercon_triple;

architecture rtl of intercon_triple is

  -- constant for wb arbiter
  constant C_WB_ARBITER_GRANT_WIDTH : natural := integer(ceil(log2(real(G_WB_MASTER_NUMBER))));

  component watchdog is
    generic(
      TIMEOUT_BIT_WIDTH : integer);
    port(
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      stb_i          : in  std_logic;
      cyc_i          : in  std_logic;
      err_o          : out std_logic;
      ACTUAL_STATE_O : out std_logic_vector(TIMEOUT_BIT_WIDTH - 1 downto 0);
      ACTUAL_STATE_I : in  std_logic_vector(TIMEOUT_BIT_WIDTH - 1 downto 0);
      timeout_i      : in  std_logic_vector(TIMEOUT_BIT_WIDTH - 1 downto 0));
  end component watchdog;

  -- types definition
  type t_wbm_i_matrix_inv is array (0 to C_K_TMR - 1) of t_wbm_i_array(0 to G_WB_MASTER_NUMBER - 1);
  type t_wbm_o_matrix_inv is array (0 to C_K_TMR - 1) of t_wbm_o_array(0 to G_WB_MASTER_NUMBER - 1);

  type t_wbs_i_matrix_inv is array (0 to C_K_TMR - 1) of t_wbs_i_array(0 to G_WB_SLAVE_NUMBER - 1);
  type t_wbs_o_matrix_inv is array (0 to C_K_TMR - 1) of t_wbs_o_array(0 to G_WB_SLAVE_NUMBER - 1);

  type t_wb_arbiter_grant_array is array (0 to C_K_TMR - 1) of std_logic_vector(C_WB_ARBITER_GRANT_WIDTH-1 downto 0);

  signal s_wbm_wbm_i : t_wbm_i_matrix_inv;
  signal s_wbm_wbm_o : t_wbm_o_matrix_inv;

  signal s_wbs_wbs_i : t_wbs_i_matrix_inv;
  signal s_wbs_wbs_o : t_wbs_o_matrix_inv;

  -- signals
  signal s_wd_stb, s_wd_cyc, s_wd_err : std_logic_vector(C_K_TMR - 1 downto 0);

  signal s_wb_arbiter_count_o, s_wb_arbiter_count_voted : t_wb_arbiter_grant_array;

  -- watchdog
  type t_state is array (C_K_TMR - 1 downto 0) of std_logic_vector(c_WD_TIMEOUT_WIDTH - 1 downto 0);
  signal s_actual_state, s_actual_state_voted : t_state;

  attribute DONT_TOUCH of s_actual_state           : signal is "TRUE";
  attribute DONT_TOUCH of s_actual_state_voted     : signal is "TRUE";
  attribute DONT_TOUCH of s_wd_cyc                 : signal is "TRUE";
  attribute DONT_TOUCH of s_wd_err                 : signal is "TRUE";
  attribute DONT_TOUCH of s_wd_stb                 : signal is "TRUE";
  attribute DONT_TOUCH of s_wb_arbiter_count_o     : signal is "TRUE";
  attribute DONT_TOUCH of s_wb_arbiter_count_voted : signal is "TRUE";

begin  -- rtl

  gen_invert_wb_matrix : for tmr_index in 0 to C_K_TMR - 1 generate
    gen_invert_wbs_matrix_inner : for slave_index in 0 to G_WB_SLAVE_NUMBER - 1 generate
      wbs_wbs_i(slave_index)(tmr_index)   <= s_wbs_wbs_i(tmr_index)(slave_index);
      s_wbs_wbs_o(tmr_index)(slave_index) <= wbs_wbs_o(slave_index)(tmr_index);
    end generate gen_invert_wbs_matrix_inner;
    gen_invert_wbm_matrix_inner : for master_index in 0 to G_WB_MASTER_NUMBER - 1 generate
      wbm_wbm_i(master_index)(tmr_index)   <= s_wbm_wbm_i(tmr_index)(master_index);
      s_wbm_wbm_o(tmr_index)(master_index) <= wbm_wbm_o(master_index)(tmr_index);
    end generate gen_invert_wbm_matrix_inner;
  end generate gen_invert_wb_matrix;

  gen_intercon_tmr_for : for i in 0 to C_K_TMR - 1 generate
    INST_intercon_core : entity work.intercon_core
      generic map(
        G_WB_MASTER_NUMBER       => G_WB_MASTER_NUMBER,
        G_WB_SLAVE_NUMBER        => G_WB_SLAVE_NUMBER,
        G_WB_ARBITER_GRANT_WIDTH => C_WB_ARBITER_GRANT_WIDTH)
      port map(
        wbm_wbm_i              => s_wbm_wbm_i(i),
        wbm_wbm_o              => s_wbm_wbm_o(i),
        wbs_wbs_i              => s_wbs_wbs_i(i),
        wbs_wbs_o              => s_wbs_wbs_o(i),
        clk                    => clk,
        reset                  => reset,
        wd_stb                 => s_wd_stb(i),
        wd_cyc                 => s_wd_cyc(i),
        wd_err                 => s_wd_err(i),
        wb_arbiter_count_o     => s_wb_arbiter_count_o(i),
        wb_arbiter_count_voted => s_wb_arbiter_count_voted(i));

    INST_watchdog : watchdog
      generic map(
        TIMEOUT_BIT_WIDTH => c_WD_TIMEOUT_WIDTH)
      port map(
        clk_i          => clk,
        rst_i          => reset,
        stb_i          => s_wd_stb(i),
        cyc_i          => s_wd_cyc(i),
        err_o          => s_wd_err(i),
        actual_state_i => s_actual_state_voted(i),
        actual_state_o => s_actual_state(i),
        timeout_i      => c_WD_TIMEOUT);
  end generate gen_intercon_tmr_for;

  INST_majority_voter_triplicated_array_ACTUAL_STATE : entity work.majority_voter_triplicated_array_wrapper
    generic map(
      MISMATCH_EN           => 0,
      G_MISMATCH_REGISTERED => 0,
      G_ADDITIONAL_MISMATCH => 0,
      C_WIDTH               => c_WD_TIMEOUT_WIDTH)
    port map(
      ASSERTION_CLK => clk,
      ASSERTION_RST => reset,
      INPUT_A       => s_actual_state(0),
      INPUT_B       => s_actual_state(1),
      INPUT_C       => s_actual_state(2),
      OUTPUT_A      => s_actual_state_voted(0),
      OUTPUT_B      => s_actual_state_voted(1),
      OUTPUT_C      => s_actual_state_voted(2),
      MISMATCH      => open,
      MISMATCH_2ND  => open);

  INST_majority_voter_triplicated_array_WB_ARBITER_COUNT : entity work.majority_voter_triplicated_array_wrapper
    generic map(
      MISMATCH_EN           => 0,
      G_MISMATCH_REGISTERED => 0,
      G_ADDITIONAL_MISMATCH => 0,
      C_WIDTH               => C_WB_ARBITER_GRANT_WIDTH)
    port map(
      ASSERTION_CLK => clk,
      ASSERTION_RST => reset,
      INPUT_A       => s_wb_arbiter_count_o(0),
      INPUT_B       => s_wb_arbiter_count_o(1),
      INPUT_C       => s_wb_arbiter_count_o(2),
      OUTPUT_A      => s_wb_arbiter_count_voted(0),
      OUTPUT_B      => s_wb_arbiter_count_voted(1),
      OUTPUT_C      => s_wb_arbiter_count_voted(2),
      MISMATCH      => open,
      MISMATCH_2ND  => open);

end rtl;
