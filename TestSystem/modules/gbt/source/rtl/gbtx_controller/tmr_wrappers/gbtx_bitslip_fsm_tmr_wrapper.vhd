-------------------------------------------------------------------------------
-- Title      : GBTX bitslip sync fsm
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_bitslip_fsm_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-27
-- Last update: 2017-11-03
-- Platform   : Vivado 2016.1
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: WRAPPER for bitslip FSM
--
--              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
--              protected:
--                      0: no mitigation
--                      1: TMR with single voter
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

library work;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;

entity gbtx_bitslip_fsm_tmr_wrapper is
  generic (
    G_SEE_MITIGATION_TECHNIQUE : integer   := 0;
    G_MISMATCH_EN              : std_logic := '1';
    G_ADDITIONAL_MISMATCH      : std_logic := '1'
    );
  port (
    CLK_DIV           : in  std_logic;
    SERDES_RST        : in  std_logic;
    BITSLIP_RX_SYNC   : in  std_logic_vector(C_BITSLIP_RX_CONTROL_bit'range);
    SERDES_BITSLIP_RX : out std_logic;
    MISMATCH          : out std_logic;
    MISMATCH_2ND      : out std_logic);
  attribute DONT_TOUCH                                 : string;
  attribute DONT_TOUCH of gbtx_bitslip_fsm_tmr_wrapper : entity is "true";
end entity gbtx_bitslip_fsm_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_bitslip_fsm_tmr_wrapper is

  constant C_STATE_BITSIZE          : integer := 2;
  signal s_actual_state_voted_notmr : std_logic_vector(C_STATE_BITSIZE-1 downto 0);

begin

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    gbtx_bitslip_fsm_1 : entity work.gbtx_bitslip_fsm
      generic map (
        G_STATE_BITSIZE => C_STATE_BITSIZE)
      port map (
        CLK_DIV           => CLK_DIV,
        SERDES_RST        => SERDES_RST,
        BITSLIP_RX_SYNC   => BITSLIP_RX_SYNC,
        SERDES_BITSLIP_RX => SERDES_BITSLIP_RX,
        ACTUAL_STATE_O    => s_actual_state_voted_notmr,
        ACTUAL_STATE_I    => s_actual_state_voted_notmr);

    MISMATCH     <= '0';
    MISMATCH_2ND <= '0';
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      constant C_K_TMR : natural := 3;  -- TMR

      type t_state_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_STATE_BITSIZE-1 downto 0);

      signal s_serdes_bitslip_rx  : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_actual_state       : t_state_tmr;
      signal s_actual_state_voted : std_logic_vector(C_STATE_BITSIZE-1 downto 0);

      attribute DONT_TOUCH                        : string;
      attribute DONT_TOUCH of s_serdes_bitslip_rx : signal is "TRUE";
      attribute DONT_TOUCH of s_actual_state      : signal is "TRUE";

      constant C_MISMATCH_WIDTH                     : integer                                       := 2;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block
      MISMATCH <= '0' when s_mismatch_array = C_MISMATCH_NONE else
                  '1';

      if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = '1' generate
        MISMATCH_2ND <= '0' when s_mismatch_2nd_array = C_MISMATCH_NONE else
                        '1';
      end generate if_add_mismatch_gen;

      if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = '0' generate
        MISMATCH_2ND <= '0';
      end generate if_not_add_mismatch_gen;

      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        gbtx_bitslip_fsm_2 : entity work.gbtx_bitslip_fsm
          generic map (
            G_STATE_BITSIZE => C_STATE_BITSIZE)
          port map (
            CLK_DIV           => CLK_DIV,
            SERDES_RST        => SERDES_RST,
            BITSLIP_RX_SYNC   => BITSLIP_RX_SYNC,
            SERDES_BITSLIP_RX => s_serdes_bitslip_rx(i),
            ACTUAL_STATE_O    => s_actual_state(i),
            ACTUAL_STATE_I    => s_actual_state_voted);
      end generate for_TMR_generate;

      --INST_majority_voter_wrapper2_<NAME>        : entity work.majority_voter_wrapper2
      --  generic map (
      --    MISMATCH_EN => G_MISMATCH_EN)
      --  port map (
      --    ASSERTION_CLK => WB_CLK,
      --    ASSERTION_RST => WB_RST,
      --    INPUT         => s_<name>,
      --    OUTPUT        => <NAME>,
      --    MISMATCH      => open);

      INST_majority_voter_wrapper2_SERDES_BITSLIP_RX : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => SERDES_RST,
          INPUT         => s_serdes_bitslip_rx,
          OUTPUT        => SERDES_BITSLIP_RX,
          MISMATCH      => s_mismatch_array(0),
          MISMATCH_2ND  => s_mismatch_2nd_array(0));

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
      --    MISMATCH      => open);

      INST_majority_voter_array_wrapper_ACTUAL_STATE : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_STATE_BITSIZE)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => SERDES_RST,
          INPUT_A       => s_actual_state(0),
          INPUT_B       => s_actual_state(1),
          INPUT_C       => s_actual_state(2),
          OUTPUT        => s_actual_state_voted,
          MISMATCH      => s_mismatch_array(1),
          MISMATCH_2ND  => s_mismatch_2nd_array(1));

    end block tmr_block;
  end generate if_TMR_generate;

  if_TMR3V_generate : if G_SEE_MITIGATION_TECHNIQUE = 3 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      constant C_K_TMR : natural := 3;  -- TMR

      type t_state_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_STATE_BITSIZE-1 downto 0);

      signal s_serdes_bitslip_rx                  : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_actual_state, s_actual_state_voted : t_state_tmr;

      attribute DONT_TOUCH                         : string;
      attribute DONT_TOUCH of s_serdes_bitslip_rx  : signal is "TRUE";
      attribute DONT_TOUCH of s_actual_state       : signal is "TRUE";
      attribute DONT_TOUCH of s_actual_state_voted : signal is "TRUE";

      constant C_MISMATCH_WIDTH                     : integer                                       := 2;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);
      signal s_mismatch_state, s_mismatch_2nd_state : std_logic_vector(C_K_TMR-1 downto 0);
ptot
    begin  -- block tmr_block
      MISMATCH <= '0' when s_mismatch_array = C_MISMATCH_NONE else
                  '1';

      if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = '1' generate
        MISMATCH_2ND <= '0' when s_mismatch_2nd_array = C_MISMATCH_NONE else
                        '1';
      end generate if_add_mismatch_gen;

      if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = '0' generate
        MISMATCH_2ND <= '0';
      end generate if_not_add_mismatch_gen;

      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        gbtx_bitslip_fsm_2 : entity work.gbtx_bitslip_fsm
          generic map (
            G_STATE_BITSIZE => C_STATE_BITSIZE)
          port map (
            CLK_DIV           => CLK_DIV,
            SERDES_RST        => SERDES_RST,
            BITSLIP_RX_SYNC   => BITSLIP_RX_SYNC,
            SERDES_BITSLIP_RX => s_serdes_bitslip_rx(i),
            ACTUAL_STATE_O    => s_actual_state(i),
            ACTUAL_STATE_I    => s_actual_state_voted(i));

        INST_majority_voter_array_wrapper_ACTUAL_STATE_i : entity work.majority_voter_array_wrapper
          generic map (
            MISMATCH_EN           => G_MISMATCH_EN,
            G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
            C_WIDTH               => C_STATE_BITSIZE)
          port map (
            ASSERTION_CLK => CLK_DIV,
            ASSERTION_RST => SERDES_RST,
            INPUT_A       => s_actual_state(0),
            INPUT_B       => s_actual_state(1),
            INPUT_C       => s_actual_state(2),
            OUTPUT        => s_actual_state_voted(i),
            MISMATCH      => s_mismatch_state(i),
            MISMATCH_2ND  => s_mismatch_2nd_state(i));
      end generate for_TMR_generate;

      s_mismatch_array(1) <= '0' when s_mismatch_state = "000" else
                             '1';
      s_mismatch_2nd_array(1) <= '0' when s_mismatch_2nd_state = "000" else
                                 '1';

      INST_majority_voter_wrapper2_SERDES_BITSLIP_RX : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => SERDES_RST,
          INPUT         => s_serdes_bitslip_rx,
          OUTPUT        => SERDES_BITSLIP_RX,
          MISMATCH      => s_mismatch_array(0),
          MISMATCH_2ND  => s_mismatch_2nd_array(0));

    end block tmr_block;
  end generate if_TMR3V_generate;

end architecture Behavior;
