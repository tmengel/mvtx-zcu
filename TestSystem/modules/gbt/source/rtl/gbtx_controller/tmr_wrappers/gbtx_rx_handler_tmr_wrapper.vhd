-------------------------------------------------------------------------------
-- Title      : GBTX handler_rx_tmr_wrapper
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_handler_rx_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2018-10-12
-- Platform   : Vivado 2016.1
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the gbtx_handler module.
--
--              The generic G_SEE_MITIGATION_TECHNIQUE indicates how the FSM is
--              protected:
--                      0: no mitigation
--                      1: TMR with single voter
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.xpm_cdc_components_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;
use work.tmr_pkg.all;

entity gbtx_rx_handler_tmr_wrapper is
  generic (
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_MISMATCH_EN              : integer := 1;
    G_ADDITIONAL_MISMATCH      : integer := 1
    );
  port (
    WB_CLK                     : in  std_logic;
    WB_RST                     : in  std_logic;
    RST                        : in  std_logic;
    GBTX_RXDATAVALID_D         : out std_logic;
    -- from/to gbtx_hard_mactros
    RX_READY                   : in  std_logic;
    CLK_DIV2                   : in  std_logic;
    CLK_DIV8                   : in  std_logic;
    -- wishbone side
    BITSLIP_RX_VALUE           : in  std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_RX_LOAD            : in  std_logic;
    IDELAY_LOAD                : in  std_logic;
    IDELAY_VALUES              : in  t_idelay_values;
    IDELAY_READ_VALUES         : out t_idelay_values;
    -- reclocked values
    BITSLIP_RX_VALUE_CLKDIV8   : out std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_RX_LOAD_CLKDIV8    : out std_logic;
    IDELAY_LOAD_CLKDIV8        : out std_logic;
    IDELAY_VALUES_CLKDIV8      : out t_idelay_values;
    IDELAY_READ_VALUES_CLKDIV8 : in  t_idelay_values;
    -- GBTX interface
    GBTX_RXDATAVALID           : in  std_logic_vector(C_K_TMR-1 downto 0);
    -- mismatch
    MISMATCH                   : out std_logic;
    MISMATCH_2ND               : out std_logic);

  attribute DONT_TOUCH                                : string;
  attribute DONT_TOUCH of gbtx_rx_handler_tmr_wrapper : entity is "true";
end entity gbtx_rx_handler_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_rx_handler_tmr_wrapper is

    signal s_rxdatavalid_notmr : std_logic;

begin

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    INST_gbtx_rx_handler : entity work.gbtx_rx_handler
      port map (
        RST                        => RST,
        RX_READY                   => RX_READY,
        CLK_DIV2                   => CLK_DIV2,
        CLK_DIV8                   => CLK_DIV8,
        WB_CLK                     => WB_CLK,
        BITSLIP_RX_VALUE           => BITSLIP_RX_VALUE,
        BITSLIP_RX_LOAD            => BITSLIP_RX_LOAD,
        IDELAY_LOAD                => IDELAY_LOAD,
        IDELAY_VALUES              => IDELAY_VALUES,
        IDELAY_READ_VALUES         => IDELAY_READ_VALUES,
        BITSLIP_RX_VALUE_CLKDIV8   => BITSLIP_RX_VALUE_CLKDIV8,
        BITSLIP_RX_LOAD_CLKDIV8    => BITSLIP_RX_LOAD_CLKDIV8,
        IDELAY_LOAD_CLKDIV8        => IDELAY_LOAD_CLKDIV8,
        IDELAY_VALUES_CLKDIV8      => IDELAY_VALUES_CLKDIV8,
        IDELAY_READ_VALUES_CLKDIV8 => IDELAY_READ_VALUES_CLKDIV8,
        GBTX_RXDATAVALID           => s_rxdatavalid_notmr,
        GBTX_RXDATAVALID_D         => GBTX_RXDATAVALID_D);
    MISMATCH     <= '0';
    MISMATCH_2ND <= '0';

    -- need to choose one of them only, since this goes to the IDDR
    s_rxdatavalid_notmr <= GBTX_RXDATAVALID(0);

  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for the gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      type t_bitslip_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_BITSLIP_VALUE_bit'range);

      signal s_bitslip_rx_load_clkdiv8  : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_idelay_load_clkdiv8      : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_gbtx_rxdatavalid_d       : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_bitslip_rx_value_clkdiv8 : t_bitslip_tmr;
      signal s_idelay_values_clkdiv8    : t_idelay_values_array(C_K_TMR-1 downto 0);
      signal s_idelay_read_values       : t_idelay_values_array(C_K_TMR-1 downto 0);


      attribute DONT_TOUCH                               : string;
      attribute DONT_TOUCH of s_bitslip_rx_load_clkdiv8  : signal is "TRUE";
      attribute DONT_TOUCH of s_idelay_load_clkdiv8      : signal is "TRUE";
      attribute DONT_TOUCH of s_gbtx_rxdatavalid_d       : signal is "TRUE";
      attribute DONT_TOUCH of s_bitslip_rx_value_clkdiv8 : signal is "TRUE";
      attribute DONT_TOUCH of s_idelay_values_clkdiv8    : signal is "TRUE";
      attribute DONT_TOUCH of s_idelay_read_values       : signal is "TRUE";


      constant C_mismatch_voter_bitslip_rx_values_clkdiv8  : integer                                            := 0;
      constant C_mismatch_voter_bitslip_rx_load_clkdiv8    : integer                                            := 1;
      constant C_mismatch_voter_idelay_load_clkdiv8        : integer                                            := 2;
      constant C_mismatch_voter_idelay_values_clkdiv8_0    : integer                                            := 3;
      constant C_mismatch_voter_idelay_values_clkdiv8_last : integer                                            := C_mismatch_voter_idelay_values_clkdiv8_0 + C_GBTX_ELINKS_RX-1;
      constant C_MISMATCH_WIDTH_div8                       : integer                                            := C_mismatch_voter_idelay_values_clkdiv8_last + 1;
      constant C_MISMATCH_NONE_div8                        : std_logic_vector(C_MISMATCH_WIDTH_div8-1 downto 0) := (others => '0');

      constant C_mismatch_voter_from_clkdiv8               : integer                                       := 0;
      constant C_mismatch_voter_idelay_read_values_wb_0    : integer                                       := 1;
      constant C_mismatch_voter_idelay_read_values_wb_last : integer                                       := C_mismatch_voter_idelay_read_values_wb_0 + C_GBTX_ELINKS_RX-1;
      constant C_MISMATCH_WIDTH                            : integer                                       := C_mismatch_voter_idelay_read_values_wb_last + 1;
      constant C_MISMATCH_NONE                             : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');

      signal s_mismatch_array_div8, s_mismatch_2nd_array_div8 : std_logic_vector(C_MISMATCH_WIDTH_div8-1 downto 0);

      signal s_mismatch_array_wb, s_mismatch_2nd_array_wb : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

      signal s_mismatch_div8, s_mismatch_2nd_div8 : std_logic;

    begin  -- block tmr_block

      MISMATCH <= '0' when s_mismatch_array_wb = C_MISMATCH_NONE else
                  '1';

      INST_mismatch_div8_2_wb_sync : xpm_cdc_single
        generic map (
          DEST_SYNC_FF   => 2,          -- integer; range: 2-10
          SIM_ASSERT_CHK => 0,  -- integer; 0=disable simulation messages, 1=enable simulation messages
          SRC_INPUT_REG  => 0  -- integer; 0=do not register input, 1=register input
          )
        port map (
          src_clk  => '0',     -- optional; required when SRC_INPUT_REG = 1
          src_in   => s_mismatch_div8,
          dest_clk => WB_CLK,
          dest_out => s_mismatch_array_wb(C_mismatch_voter_from_clkdiv8)
          );

      if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
        MISMATCH_2ND <= '0' when s_mismatch_2nd_array_wb = C_MISMATCH_NONE else
                        '1';


        INST_mismatch_2nd_div8_2_wb_sync : xpm_cdc_single
          generic map (
            DEST_SYNC_FF   => 2,        -- integer; range: 2-10
            SIM_ASSERT_CHK => 0,  -- integer; 0=disable simulation messages, 1=enable simulation messages
            SRC_INPUT_REG  => 0  -- integer; 0=do not register input, 1=register input
            )
          port map (
            src_clk  => '0',     -- optional; required when SRC_INPUT_REG = 1
            src_in   => s_mismatch_2nd_div8,
            dest_clk => WB_CLK,
            dest_out => s_mismatch_2nd_array_wb(C_mismatch_voter_from_clkdiv8)
            );

      end generate if_add_mismatch_gen;

      if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
        MISMATCH_2ND <= '0';
      end generate if_not_add_mismatch_gen;
      -- for generate
      TMR_FOR_generate : for i in 0 to C_K_TMR-1 generate
        INST_gbtx_rx_handler : entity work.gbtx_rx_handler
          port map (
            RST      => RST,
            RX_READY => RX_READY,
            CLK_DIV2 => CLK_DIV2,
            CLK_DIV8 => CLK_DIV8,
            WB_CLK   => WB_CLK,

            BITSLIP_RX_VALUE           => BITSLIP_RX_VALUE,
            BITSLIP_RX_LOAD            => BITSLIP_RX_LOAD,
            IDELAY_LOAD                => IDELAY_LOAD,
            IDELAY_VALUES              => IDELAY_VALUES,
            GBTX_RXDATAVALID           => GBTX_RXDATAVALID(i),
            IDELAY_READ_VALUES_CLKDIV8 => IDELAY_READ_VALUES_CLKDIV8,

            BITSLIP_RX_VALUE_CLKDIV8 => s_bitslip_rx_value_clkdiv8(i),
            BITSLIP_RX_LOAD_CLKDIV8  => s_bitslip_rx_load_clkdiv8(i),
            IDELAY_LOAD_CLKDIV8      => s_idelay_load_clkdiv8(i),
            IDELAY_VALUES_CLKDIV8    => s_idelay_values_clkdiv8(i),
            IDELAY_READ_VALUES       => s_idelay_read_values(i),
            GBTX_RXDATAVALID_D       => s_gbtx_rxdatavalid_d(i));
      end generate TMR_FOR_generate;

      INST_majority_voter_wrapper2_BITSLIP_RX_LOAD : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV8,
          ASSERTION_RST => RST,
          INPUT         => s_bitslip_rx_load_clkdiv8,
          OUTPUT        => BITSLIP_RX_LOAD_CLKDIV8,
          MISMATCH      => s_mismatch_array_div8(C_mismatch_voter_bitslip_rx_load_clkdiv8),
          MISMATCH_2ND  => s_mismatch_2nd_array_div8(C_mismatch_voter_bitslip_rx_load_clkdiv8));

      INST_majority_voter_wrapper2_IDELAY_LOAD : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV8,
          ASSERTION_RST => RST,
          INPUT         => s_idelay_load_clkdiv8,
          OUTPUT        => IDELAY_LOAD_CLKDIV8,
          MISMATCH      => s_mismatch_array_div8(C_mismatch_voter_idelay_load_clkdiv8),
          MISMATCH_2ND  => s_mismatch_2nd_array_div8(C_mismatch_voter_idelay_load_clkdiv8));

      INST_majority_voter_wrapper2_GBTX_RXDATAVALID_D : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV8,
          ASSERTION_RST => RST,
          INPUT         => s_gbtx_rxdatavalid_d,
          OUTPUT        => GBTX_RXDATAVALID_D,
          MISMATCH      => s_mismatch_div8,
          MISMATCH_2ND  => s_mismatch_2nd_div8);

      INST_majority_voter_array_wrapper_BITSLIP_RX_VALUE : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_BITSLIP_VALUE_bit'length)
        port map (
          ASSERTION_CLK => CLK_DIV8,
          ASSERTION_RST => RST,
          INPUT_A       => s_bitslip_rx_value_clkdiv8(0),
          INPUT_B       => s_bitslip_rx_value_clkdiv8(1),
          INPUT_C       => s_bitslip_rx_value_clkdiv8(2),
          OUTPUT        => BITSLIP_RX_VALUE_CLKDIV8,
          MISMATCH      => s_mismatch_array_div8(C_mismatch_voter_bitslip_rx_values_clkdiv8),
          MISMATCH_2ND  => s_mismatch_2nd_array_div8(C_mismatch_voter_bitslip_rx_values_clkdiv8));

      for_idelay_value_gen : for i in 0 to C_GBTX_ELINKS_RX-1 generate
        INST_majority_voter_array_wrapper_IDELAY_VALUES : entity work.majority_voter_array_wrapper
          generic map (
            MISMATCH_EN           => G_MISMATCH_EN,
            G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
            C_WIDTH               => C_IDELAY_DELAY_WIDTH)
          port map (
            ASSERTION_CLK => CLK_DIV8,
            ASSERTION_RST => RST,
            INPUT_A       => s_idelay_values_clkdiv8(0)(i),
            INPUT_B       => s_idelay_values_clkdiv8(1)(i),
            INPUT_C       => s_idelay_values_clkdiv8(2)(i),
            OUTPUT        => IDELAY_VALUES_CLKDIV8(i),
            MISMATCH      => s_mismatch_array_div8(C_mismatch_voter_idelay_values_clkdiv8_0 + i),
            MISMATCH_2ND  => s_mismatch_2nd_array_div8(C_mismatch_voter_idelay_values_clkdiv8_0 + i));

        INST_majority_voter_array_wrapper_IDELAY_READ_VALUES : entity work.majority_voter_array_wrapper
          generic map (
            MISMATCH_EN           => G_MISMATCH_EN,
            G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
            C_WIDTH               => C_IDELAY_DELAY_WIDTH)
          port map (
            ASSERTION_CLK => WB_CLK,
            ASSERTION_RST => WB_RST,
            INPUT_A       => s_idelay_read_values(0)(i),
            INPUT_B       => s_idelay_read_values(1)(i),
            INPUT_C       => s_idelay_read_values(2)(i),
            OUTPUT        => IDELAY_READ_VALUES(i),
            MISMATCH      => s_mismatch_array_wb(C_mismatch_voter_idelay_read_values_wb_0 + i),
            MISMATCH_2ND  => s_mismatch_2nd_array_wb(C_mismatch_voter_idelay_read_values_wb_0 + i));
      end generate for_idelay_value_gen;
    end block tmr_block;
  end generate if_TMR_generate;

end architecture Behavior;
