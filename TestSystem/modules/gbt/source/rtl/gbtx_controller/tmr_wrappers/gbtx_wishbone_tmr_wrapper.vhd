-------------------------------------------------------------------------------
-- Title      : GBTx wishbone_tmr_wrapper
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : gbtx_wishbone_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-25
-- Last update: 2018-10-12
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the gbtx_wishbone module.
--
--              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
--              protected:
--                      0: no mitigation
--                      1: TMR with single voter
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library work;
use work.intercon_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;
use work.tmr_pkg.all;
use work.xpm_cdc_components_pkg.all;

entity gbtx_wishbone_tmr_wrapper is
  generic (
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_MISMATCH_EN              : integer := 0;
    G_ADDITIONAL_MISMATCH      : integer := 0
    );
  port (
    WB_CLK                 : in  std_logic;
    WB_RST                 : in  std_logic;
    --GBTx handler interface (WB CLK)
    GBTX_CONTROLLER_ENABLE : out std_logic;
    RST_GBTX_n             : out std_logic;
    IDELAY_VALUES          : out t_idelay_values;
    IDELAY_READ_VALUES     : in  t_idelay_values;
    IDELAY_LOAD            : out std_logic;
    BITSLIP_RX_VALUE       : out std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_TX_VALUE       : out std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_LOAD           : out std_logic;
    TX_PATTERN_SELECTION   : out std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    TX1_PATTERN_SELECTION  : out std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    GBTX_RXRDY             : in  std_logic;
    WISHBONE_REGISTERS_O   : out t_wishbone_registers_tmr
    );
  attribute DONT_TOUCH                              : string;
  attribute DONT_TOUCH of gbtx_wishbone_tmr_wrapper : entity is "true";
end entity gbtx_wishbone_tmr_wrapper;


architecture structural of gbtx_wishbone_tmr_wrapper is

  signal s_wishbone_registers_notmr : t_wishbone_registers;

begin  -- architecture structural

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    INST_gbtx_wishbone : entity work.gbtx_wishbone
      port map (
        WB_CLK                 => WB_CLK,
        WB_RST                 => WB_RST,
        GBTX_CONTROLLER_ENABLE => GBTX_CONTROLLER_ENABLE,
        RST_GBTX_n             => RST_GBTX_n,
        IDELAY_VALUES          => IDELAY_VALUES,
        IDELAY_READ_VALUES     => IDELAY_READ_VALUES,
        IDELAY_LOAD            => IDELAY_LOAD,
        BITSLIP_RX_VALUE       => BITSLIP_RX_VALUE,
        BITSLIP_TX_VALUE       => BITSLIP_TX_VALUE,
        BITSLIP_LOAD           => BITSLIP_LOAD,
        TX_PATTERN_SELECTION   => TX_PATTERN_SELECTION,
        TX1_PATTERN_SELECTION  => TX1_PATTERN_SELECTION,
        GBTX_RXRDY             => GBTX_RXRDY,
        WISHBONE_REGISTERS_I   => s_wishbone_registers_notmr,
        WISHBONE_REGISTERS_O   => s_wishbone_registers_notmr
        );


  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      type t_bitslip_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_BITSLIP_VALUE_bit'range);
      type t_txpatternselection_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);

      signal s_wishbone_registers           : t_wishbone_registers_tmr;
      signal s_wishbone_registers_voted     : t_wishbone_registers_tmr;
      signal s_slv_wishbone_registers_voted : t_slv_wishbone_registers_tmr;
      signal s_gbtx_controller_enable       : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_rst_gbtx_n                   : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_idelay_load                  : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_bitslip_rx_value             : t_bitslip_tmr;
      signal s_bitslip_tx_value             : t_bitslip_tmr;
      signal s_bitslip_load                 : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_tx_pattern_selection         : t_txpatternselection_tmr;
      signal s_tx1_pattern_selection        : t_txpatternselection_tmr;
      signal s_idelay_values                : t_idelay_values_array(0 to C_K_TMR-1);

      attribute DONT_TOUCH                                   : string;
      attribute DONT_TOUCH of s_wishbone_registers           : signal is "TRUE";
      attribute DONT_TOUCH of s_wishbone_registers_voted     : signal is "TRUE";
      attribute DONT_TOUCH of s_slv_wishbone_registers_voted : signal is "TRUE";
      attribute DONT_TOUCH of s_gbtx_controller_enable       : signal is "TRUE";
      attribute DONT_TOUCH of s_rst_gbtx_n                   : signal is "TRUE";
      attribute DONT_TOUCH of s_idelay_load                  : signal is "TRUE";
      attribute DONT_TOUCH of s_bitslip_rx_value             : signal is "TRUE";
      attribute DONT_TOUCH of s_bitslip_tx_value             : signal is "TRUE";
      attribute DONT_TOUCH of s_bitslip_load                 : signal is "TRUE";
      attribute DONT_TOUCH of s_tx_pattern_selection         : signal is "TRUE";
      attribute DONT_TOUCH of s_tx1_pattern_selection        : signal is "TRUE";
      attribute DONT_TOUCH of s_idelay_values                : signal is "TRUE";

      constant C_MISMATCH_WIDTH                     : integer                                       := C_GBTX_ELINKS_RX + 8;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block


      -- for generate
      for_TMR_generate : for i in 0 to C_K_TMR-1 generate
        INST_gbtx_wishbone : entity work.gbtx_wishbone
          port map (
            WB_CLK                 => WB_CLK,
            WB_RST                 => WB_RST,
            IDELAY_READ_VALUES     => IDELAY_READ_VALUES,
            IDELAY_VALUES          => s_idelay_values(i),
            GBTX_CONTROLLER_ENABLE => s_gbtx_controller_enable(i),
            RST_GBTX_n             => s_rst_gbtx_n(i),
            IDELAY_LOAD            => s_idelay_load(i),
            BITSLIP_RX_VALUE       => s_bitslip_rx_value(i),
            BITSLIP_TX_VALUE       => s_bitslip_tx_value(i),
            BITSLIP_LOAD           => s_bitslip_load(i),
            TX_PATTERN_SELECTION   => s_tx_pattern_selection(i),
            TX1_PATTERN_SELECTION  => s_tx1_pattern_selection(i),
            GBTX_RXRDY             => GBTX_RXRDY,
            WISHBONE_REGISTERS_I   => s_wishbone_registers_voted(i),
            WISHBONE_REGISTERS_O   => s_wishbone_registers(i)
            );

        s_wishbone_registers_voted(i) <= f_to_wishbone_register(s_slv_wishbone_registers_voted(i));
        WISHBONE_REGISTERS_O(i)       <= s_wishbone_registers(i);
      end generate for_TMR_generate;

      INST_majority_voter_wrapper2_GBTX_CONTROLLER_ENABLE : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT         => s_gbtx_controller_enable,
          OUTPUT        => GBTX_CONTROLLER_ENABLE,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );

      INST_majority_voter_wrapper2_RST_GBTX_N : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT         => s_rst_gbtx_n,
          OUTPUT        => RST_GBTX_N,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );

      INST_majority_voter_wrapper2_IDELAY_LOAD : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT         => s_idelay_load,
          OUTPUT        => IDELAY_LOAD,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );

      INST_majority_voter_wrapper2_BITSLIP_LOAD : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT         => s_bitslip_load,
          OUTPUT        => BITSLIP_LOAD,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );

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

      INST_majority_voter_array_wrapper_BITSLIP_RX_VALUE : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_BITSLIP_VALUE_bit'length)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT_A       => s_bitslip_rx_value(0),
          INPUT_B       => s_bitslip_rx_value(1),
          INPUT_C       => s_bitslip_rx_value(2),
          OUTPUT        => BITSLIP_RX_VALUE,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );

      INST_majority_voter_array_wrapper_BITSLIP_TX_VALUE : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_BITSLIP_VALUE_bit'length)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT_A       => s_bitslip_tx_value(0),
          INPUT_B       => s_bitslip_tx_value(1),
          INPUT_C       => s_bitslip_tx_value(2),
          OUTPUT        => BITSLIP_TX_VALUE,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );

      INST_majority_voter_array_wrapper_TX_PATTERN_SELECTION : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_TX_PATTERN_SELECTION_bit'length)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT_A       => s_tx_pattern_selection(0),
          INPUT_B       => s_tx_pattern_selection(1),
          INPUT_C       => s_tx_pattern_selection(2),
          OUTPUT        => TX_PATTERN_SELECTION,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );

      INST_majority_voter_array_wrapper_TX1_PATTERN_SELECTION : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_TX_PATTERN_SELECTION_bit'length)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT_A       => s_tx1_pattern_selection(0),
          INPUT_B       => s_tx1_pattern_selection(1),
          INPUT_C       => s_tx1_pattern_selection(2),
          OUTPUT        => TX1_PATTERN_SELECTION,
          MISMATCH      => open,
          MISMATCH_2ND  => open
          );


      majority_voter_triplicated_array_wrapper_wishbone_registers : entity work.majority_voter_triplicated_array_wrapper
        generic map (
          MISMATCH_EN           => 0,
          G_ADDITIONAL_MISMATCH => 0,
          C_WIDTH               => C_WISHBONE_REGISTERS_TOT_WIDTH)
        port map (
          ASSERTION_CLK => WB_CLK,
          ASSERTION_RST => WB_RST,
          INPUT_A       => f_to_std_logic_vector(s_wishbone_registers(0)),
          INPUT_B       => f_to_std_logic_vector(s_wishbone_registers(1)),
          INPUT_C       => f_to_std_logic_vector(s_wishbone_registers(2)),
          OUTPUT_A      => s_slv_wishbone_registers_voted(0),
          OUTPUT_B      => s_slv_wishbone_registers_voted(1),
          OUTPUT_C      => s_slv_wishbone_registers_voted(2),
          MISMATCH      => open,
          MISMATCH_2ND  => open);

      -- IDELAY_VALUES is array of std_logic_vector.
      -- majority_voter_array can be used.
      -- There is one instance for each of the elements of the array.
      -- The increased dimention (TMR) is handled by defining an array of t_idelay_values
      for_delay_values_generate : for j in 0 to C_GBTX_ELINKS_RX-1 generate
        INST_majority_voter_array_wrapper_IDELAY_VALUES : entity work.majority_voter_array_wrapper
          generic map (
            MISMATCH_EN           => G_MISMATCH_EN,
            G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
            C_WIDTH               => C_IDELAY_DELAY_WIDTH)
          port map (
            ASSERTION_CLK => WB_CLK,
            ASSERTION_RST => WB_RST,
            INPUT_A       => s_idelay_values(0)(j),
            INPUT_B       => s_idelay_values(1)(j),
            INPUT_C       => s_idelay_values(2)(j),
            OUTPUT        => IDELAY_VALUES(j),
            MISMATCH      => open,
            MISMATCH_2ND  => open
            );
      end generate for_delay_values_generate;
    end block tmr_block;
  end generate if_TMR_generate;

end architecture structural;
