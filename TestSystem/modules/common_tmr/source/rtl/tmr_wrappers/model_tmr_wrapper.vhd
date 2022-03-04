-------------------------------------------------------------------------------
-- Title      : <NAME>
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : <NAME>_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-27
-- Last update: 2017-09-27
-- Platform   : Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: WRAPPER for <NAME>
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.<name>_pkg.all;

entity <name>_tmr_wrapper is
  generic (
    G_SEE_HARDENING_TECHNIQUE : integer := 0;
    G_MISMATCH_EN             : integer := 1
    );
  <paste entity here>
  attribute DONT_TOUCH                                 : string;
  attribute DONT_TOUCH of <name>_tmr_wrapper : entity is "true";
end entity <name>_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of <name>_tmr_wrapper is

  constant C_STATE_BITSIZE    : integer := 2;
  signal s_actual_state_voted : std_logic_vector(C_STATE_BITSIZE-1 downto 0);

begin

  if_NOMITIGATION_generate : if G_SEE_HARDENING_TECHNIQUE = 0 generate
    <instance>

    MISMATCH <= '0';
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_HARDENING_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      constant C_K_TMR : natural := 3;  -- TMR

      --type t_state_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_STATE_BITSIZE-1 downto 0);

      --signal s_serdes_bitslip_rx : std_logic_vector(C_K_TMR-1 downto 0);
      --signal s_actual_state      : t_state_tmr;

      --attribute DONT_TOUCH                        : string;
      --attribute DONT_TOUCH of s_serdes_bitslip_rx : signal is "TRUE";
      --attribute DONT_TOUCH of s_actual_state      : signal is "TRUE";

      --constant C_MISMATCH_WIDTH : integer                                       := 2;
      --constant C_MISMATCH_NONE  : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      --signal s_mismatch_array   : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block
      MISMATCH <= '0' when s_mismatch_array = C_MISMATCH_NONE else
                  '1';

      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        <instance>
      end generate for_TMR_generate;

      --INST_majority_voter_wrapper2_<NAME>        : entity work.majority_voter_wrapper2
      --  generic map (
      --    MISMATCH_EN => G_MISMATCH_EN)
      --  port map (
      --    ASSERTION_CLK => WB_CLK,
      --    ASSERTION_RST => WB_RST,
      --    INPUT         => s_<name>,
      --    OUTPUT        => <NAME>,
      --    MISMATCH      => s_mismatch_array(0));

      --INST_majority_voter_array_wrapper_<NAME>: entity work.majority_voter_array_wrapper
      --  generic map (
      --    MISMATCH_EN => G_MISMATCH_EN,
      --    C_WIDTH     => <NAME>'length)
      --  port map (
      --    ASSERTION_CLK => WB_CLK,
      --    ASSERTION_RST => WB_RST,
      --    INPUT_A       => s_<name>(0),
      --    INPUT_B       => s_<name>(1),
      --    INPUT_C       => s_<name>(2),
      --    OUTPUT        => <NAME>,
      --    MISMATCH      => s_mismatch_array(1));

    end block tmr_block;
  end generate if_TMR_generate;

end architecture Behavior;
