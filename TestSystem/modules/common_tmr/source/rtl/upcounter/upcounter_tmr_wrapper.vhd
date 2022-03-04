-------------------------------------------------------------------------------
-- Title      : Upcounter tmr wrapper
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : upcounter_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-27
-- Last update: 2017-11-02
-- Platform   : Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: WRAPPER for upcounter
--
--              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
--              protected:
--                            0: no mitigation
--                            1: TMR with single voter
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tmr_pkg.all;

entity upcounter_tmr_wrapper is
  generic (
    BIT_WIDTH                  : integer := 16;
    IS_SATURATING              : integer := 0;
    VERBOSE                    : integer := 1;
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_MISMATCH_EN              : integer := 1;
    G_MISMATCH_REGISTERED      : integer := 0;
    G_ADDITIONAL_MISMATCH      : integer := 1);
  port (
    CLK          : in  std_logic;
    RST          : in  std_logic;
    RST_CNT      : in  std_logic;
    CNT_UP       : in  std_logic;
    CNT_VALUE    : out std_logic_vector(BIT_WIDTH-1 downto 0);
    MISMATCH     : out std_logic;
    MISMATCH_2ND : out std_logic);
  attribute DONT_TOUCH                          : string;
  attribute DONT_TOUCH of upcounter_tmr_wrapper : entity is "true";
end entity upcounter_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of upcounter_tmr_wrapper is

  signal s_actual_state_nonvoted : std_logic_vector(BIT_WIDTH-1 downto 0);

begin

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    INST_upcounter : entity work.upcounter_core
      generic map (
        BIT_WIDTH     => BIT_WIDTH,
        IS_SATURATING => IS_SATURATING,
        VERBOSE       => VERBOSE)
      port map (
        CLK            => CLK,
        RST            => RST,
        RST_CNT        => RST_CNT,
        CNT_UP         => CNT_UP,
        CNT_VALUE      => CNT_VALUE,
        ACTUAL_STATE_O => s_actual_state_nonvoted,
        ACTUAL_STATE_I => s_actual_state_nonvoted);
    MISMATCH     <= '0';
    MISMATCH_2ND <= '0';
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      type t_cnt_value_tmr is array (0 to C_K_TMR-1) of std_logic_vector(BIT_WIDTH-1 downto 0);

      signal s_cnt_value          : t_cnt_value_tmr;
      signal s_actual_state       : t_cnt_value_tmr;
      signal s_actual_state_voted : std_logic_vector(BIT_WIDTH-1 downto 0);

      attribute DONT_TOUCH                   : string;
      attribute DONT_TOUCH of s_cnt_value    : signal is "TRUE";
      attribute DONT_TOUCH of s_actual_state : signal is "TRUE";

      constant C_MISMATCH_WIDTH                     : integer                                       := 2;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block

      process (CLK) is
      begin  -- process
        if rising_edge(CLK) then        -- rising clock edge
          if RST = '1' then             -- synchronous reset (active high)
            MISMATCH <= '0';
          else
            if s_mismatch_array = C_MISMATCH_NONE then
              MISMATCH <= '0';
            else
              MISMATCH <= '1';
            end if;
          end if;
        end if;
      end process;

      if_additional_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
      process (CLK) is
      begin  -- process
        if rising_edge(CLK) then        -- rising clock edge
          if RST = '1' then             -- synchronous reset (active high)
            MISMATCH_2ND <= '0';
          else
            if s_mismatch_2nd_array = C_MISMATCH_NONE then
              MISMATCH_2ND <= '0';
            else
              MISMATCH_2ND <= '1';
            end if;
          end if;
        end if;
      end process;
      end generate if_additional_mismatch_gen;

      if_not_additional_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
        MISMATCH_2ND <= '0';
      end generate if_not_additional_mismatch_gen;

      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        INST_upcounter : entity work.upcounter_core
          generic map (
            BIT_WIDTH     => BIT_WIDTH,
            IS_SATURATING => IS_SATURATING,
            VERBOSE       => VERBOSE)
          port map (
            CLK            => CLK,
            RST            => RST,
            RST_CNT        => RST_CNT,
            CNT_UP         => CNT_UP,
            CNT_VALUE      => s_cnt_value(i),
            ACTUAL_STATE_O => s_actual_state(i),
            ACTUAL_STATE_I => s_actual_state_voted);
      end generate for_TMR_generate;

      INST_majority_voter_array_wrapper_CNT_VALUE : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => BIT_WIDTH)
        port map (
          ASSERTION_CLK => CLK,
          ASSERTION_RST => RST,
          INPUT_A       => s_cnt_value(0),
          INPUT_B       => s_cnt_value(1),
          INPUT_C       => s_cnt_value(2),
          OUTPUT        => CNT_VALUE,
          MISMATCH      => s_mismatch_array(0),
          MISMATCH_2ND  => s_mismatch_2nd_array(0));

      INST_majority_voter_array_wrapper_ACTUAL_STATE : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => BIT_WIDTH)
        port map (
          ASSERTION_CLK => CLK,
          ASSERTION_RST => RST,
          INPUT_A       => s_actual_state(0),
          INPUT_B       => s_actual_state(1),
          INPUT_C       => s_actual_state(2),
          OUTPUT        => s_actual_state_voted,
          MISMATCH      => s_mismatch_array(1),
          MISMATCH_2ND  => s_mismatch_2nd_array(1));

    end block tmr_block;
  end generate if_TMR_generate;

  if_TMR3v_generate : if G_SEE_MITIGATION_TECHNIQUE = 3 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      type t_cnt_value_tmr is array (0 to C_K_TMR-1) of std_logic_vector(BIT_WIDTH-1 downto 0);

      signal s_cnt_value                          : t_cnt_value_tmr;
      signal s_actual_state, s_actual_state_voted : t_cnt_value_tmr;

      attribute DONT_TOUCH                         : string;
      attribute DONT_TOUCH of s_cnt_value          : signal is "TRUE";
      attribute DONT_TOUCH of s_actual_state       : signal is "TRUE";
      attribute DONT_TOUCH of s_actual_state_voted : signal is "TRUE";

      constant C_MISMATCH_WIDTH                     : integer                                       := 2;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block

      -- purpose: process handling the sampling of the MISMATCH signal to avoid issues with counters
      p_mismatch_sample : process (CLK) is
      begin  -- process p_mismatch_sample
        if rising_edge(CLK) then        -- rising clock edge
          if RST = '1' then             -- synchronous reset (active high)
            MISMATCH <= '0';
          else
            if s_mismatch_array = C_MISMATCH_NONE then
              MISMATCH <= '0';
            else
              MISMATCH <= '1';
            end if;
          end if;
        end if;
      end process p_mismatch_sample;

      if_additional_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
        -- purpose: process handling the sampling of the MISMATCH signal to avoid issues with counters
        p_mismatch2nd_sample : process (CLK) is
        begin  -- process p_mismatch_sample
          if rising_edge(CLK) then      -- rising clock edge
            if RST = '1' then           -- synchronous reset (active high)
              MISMATCH_2ND <= '0';
            else
              if s_mismatch_2nd_array = C_MISMATCH_NONE then
                MISMATCH_2ND <= '0';
              else
                MISMATCH_2ND <= '1';
              end if;
            end if;
          end if;
        end process p_mismatch2nd_sample;
      end generate if_additional_mismatch_gen;

      if_not_additional_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
        MISMATCH_2ND <= '0';
      end generate if_not_additional_mismatch_gen;

      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        INST_upcounter : entity work.upcounter_core
          generic map (
            BIT_WIDTH     => BIT_WIDTH,
            IS_SATURATING => IS_SATURATING,
            VERBOSE       => VERBOSE)
          port map (
            CLK            => CLK,
            RST            => RST,
            RST_CNT        => RST_CNT,
            CNT_UP         => CNT_UP,
            CNT_VALUE      => s_cnt_value(i),
            ACTUAL_STATE_O => s_actual_state(i),
            ACTUAL_STATE_I => s_actual_state_voted(i));
      end generate for_TMR_generate;

      INST_majority_voter_array_wrapper_CNT_VALUE : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => BIT_WIDTH)
        port map (
          ASSERTION_CLK => CLK,
          ASSERTION_RST => RST,
          INPUT_A       => s_cnt_value(0),
          INPUT_B       => s_cnt_value(1),
          INPUT_C       => s_cnt_value(2),
          OUTPUT        => CNT_VALUE,
          MISMATCH      => s_mismatch_array(0),
          MISMATCH_2ND  => s_mismatch_2nd_array(0));

      INST_majority_voter_triplicated_array_ACTUAL_STATE : entity work.majority_voter_triplicated_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_MISMATCH_REGISTERED => 0,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => BIT_WIDTH)
        port map (
          ASSERTION_CLK => CLK,
          ASSERTION_RST => RST,
          INPUT_A       => s_actual_state(0),
          INPUT_B       => s_actual_state(1),
          INPUT_C       => s_actual_state(2),
          OUTPUT_A      => s_actual_state_voted(0),
          OUTPUT_B      => s_actual_state_voted(1),
          OUTPUT_C      => s_actual_state_voted(2),
          MISMATCH      => s_mismatch_array(1),
          MISMATCH_2ND  => s_mismatch_2nd_array(1));

    end block tmr_block;
  end generate if_TMR3v_generate;

end architecture Behavior;
