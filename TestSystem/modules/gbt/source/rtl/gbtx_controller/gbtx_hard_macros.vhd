-------------------------------------------------------------------------------
-- Title      : gbtx hard macros
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_hard_macros.vhd
-- Author     : J. Schambach <Joachim.Schambach@cern.ch>
-- Company    : University of Texas at Austin
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2018-11-07
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Implements the hard macros part of the gtbx_handler. This part
--              of the design cannot be further protected from SEE and is it
--              hence moved to a separate module.
--
-- gbtx_handler description: Deserialize GBTx DOUT signals and compile into an
--                           80bit GBT frame; add RX_DATAVALID as 81st bit and
--                           stuff in FIFO. TX data is either from a testpattern,
--                           or from the TX_FIFO; TX data is serizalized, with
--                           the 81st bit from the FIFO used to assert the
--                           TX_DATAVALID
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

library work;
use work.xpm_cdc_components_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;

entity gbtx_hard_macros is
  generic (
    G_USE_GBTX1 : integer := 1
    );
  port (
    -- from fabric top
    ARST                       : in  std_logic_vector(2 downto 0);
    GBTX_RXRDY                 : in  std_logic;
    --
    -- from/to gbtx_handler
    CLK_DIV2                   : out std_logic;
    CLK_DIV8                   : out std_logic;
    GBTX_RX_DATAFRAME          : out std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    RX_READY                   : out std_logic;  -- Async reset for module (PLL_LOCK resync)
    --
    GBTX_TX_DATAFRAME          : in  std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    GBTX1_TX_DATAFRAME         : in  std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0) := (others => '0');  -- optional is G_USE_GBTX1 = '1'
    IDELAY_VALUES_CLKDIV8      : in  t_idelay_values;
    IDELAY_READ_VALUES_CLKDIV8 : out t_idelay_values;
    IDELAY_LOAD_CLKDIV8        : in  std_logic;  -- load signal for the delay tabs
    --
    -- GBTx signals
    GBTX_DCLK                  : in  std_logic_vector(1 downto 0);  -- GBTx 40/160MHz clock for elinks
    GBTX_DIN                   : out std_logic_vector(C_GBTX_ELINKS_TX-1 downto 0);
    GBTX1_DIN                  : out std_logic_vector(C_GBTX_ELINKS_TX-1 downto 0);
    GBTX_DOUT                  : in  std_logic_vector(C_GBTX_ELINKS_RX-1 downto 0)
    );
end entity gbtx_hard_macros;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_hard_macros is

  -----------------------------------------------------------------------------
  -- Clock signals
  -----------------------------------------------------------------------------
  signal sClk40       : std_logic;
  signal sClk160      : std_logic;
  signal sClk40_mmcm  : std_logic;
  signal sClkDiv2     : std_logic;
  signal sClkDiv8     : std_logic;
  signal sClkFb       : std_logic;
  signal sClkFbBuf    : std_logic;
  signal sPllLocked   : std_logic;
  signal rx_mmcm_div2 : std_logic;

  -----------------------------------------------------------------------------
  -- reset
  -----------------------------------------------------------------------------
  signal sRxReady          : std_logic;
  signal sGbtxRxReady_sync : std_logic;
  signal sRst_n            : std_logic;
  signal sRstPll           : std_logic;
  signal sArst_sync        : std_logic_vector(2 downto 0);
  signal sArst_voted       : std_logic;
  signal sClkDiv8_rst      : std_logic;
  signal sRst_sync         : std_logic;
  signal sRst              : std_logic;

  -----------------------------------------------------------------------------
  -- Rx Process
  -----------------------------------------------------------------------------
  signal s_rx_dataframe_reversed : std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
  signal sGbtxDout_d             : std_logic_vector(C_GBTX_ELINKS_RX-1 downto 0);

  -----------------------------------------------------------------------------
  -- Tx Process
  -----------------------------------------------------------------------------
  signal s_tx_dataframe_reversed, s_tx1_dataframe_reversed : std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);

begin

  -- assign output
  CLK_DIV2 <= sClkDiv2;
  CLK_DIV8 <= sClkDiv8;

  RX_READY <= not sClkDiv8_rst;

  -----------------------------------------------------------------------------
  -- Clock handling
  -----------------------------------------------------------------------------
  sClk160 <= GBTX_DCLK(1);

  INST_bg_clk40 : BUFGCE
    port map (
      I  => GBTX_DCLK(0),
      CE => '1',
      O  => sClk40);


  -----------------------------------------------------------------------------
  -- Synchronize reset/clear to 40MHz clock from elink
  -----------------------------------------------------------------------------
  majority_voter_wrapper2_ARST: entity work.majority_voter_wrapper2
    generic map (
      MISMATCH_EN           => 0,
      G_MISMATCH_REGISTERED => 0,
      G_ADDITIONAL_MISMATCH => 0)
    port map (
      ASSERTION_CLK => '0',
      ASSERTION_RST => '0',
      INPUT         => ARST,
      OUTPUT        => sArst_voted,
      MISMATCH      => open,
      MISMATCH_2ND  => open);

  sRst <= sArst_voted or (not GBTX_RXRDY);

  -- process with async reset, but synchronous release of reset
  p_reset_release: process (sClk40, sRst) is
  begin  -- process p_reset
    if sRst = '1' then                  -- asynchronous reset (active high)
      sClkDiv8_rst <= '1';
      sRst_sync <= '1';
    elsif rising_edge(sClk40) then
        sRst_sync <= '0';
        sClkDiv8_rst <= sRst_sync;
    end if;
  end process p_reset_release;


  -----------------------------------------------------------------------------
  -- Serdes clock generation
  -----------------------------------------------------------------------------
  -- buffer for 160MHz clock as bit clock for serdes
  INST_bg_rxdiv2 : BUFGCE
    port map (
      I  => sClk160,
      CE => '1',
      O  => sClkDiv2);

  -- divide-by-4 clock buffer to generate parallel clock for serdes
  INST_bg_rxdiv8 : BUFGCE_DIV
    generic map (
      BUFGCE_DIVIDE   => 4,
      IS_CLR_INVERTED => '0')
    port map (
      I   => sClk160,
      CLR => sClkDiv8_rst,
      CE  => '1',
      O   => sClkDiv8);


  -----------------------------------------------------------------------------
  -- Rx Process
  -----------------------------------------------------------------------------

  GEN_deserializer : for i in 0 to C_GBTX_ELINKS_RX-1 generate
    INST_idlyi : IDELAYE3
      generic map (
        IS_RST_INVERTED  => '0',
        IS_CLK_INVERTED  => '0',
        DELAY_SRC        => "IDATAIN",
        CASCADE          => "NONE",
        DELAY_TYPE       => "VAR_LOAD",
        DELAY_VALUE      => to_integer(unsigned(C_IDELAY_DEFAULT)),
        REFCLK_FREQUENCY => 300.0,
        DELAY_FORMAT     => "COUNT",
        UPDATE_MODE      => "ASYNC")
      port map (
        IDATAIN     => GBTX_DOUT(i),
        DATAOUT     => sGbtxDout_d(i),
        CLK         => sClkDiv8,
        CE          => '0',
        RST         => sClkDiv8_rst,
        INC         => '0',
        DATAIN      => '0',
        LOAD        => IDELAY_LOAD_CLKDIV8,
        CNTVALUEIN  => IDELAY_VALUES_CLKDIV8(i),
        EN_VTC      => '0',
        CASC_IN     => '0',
        CASC_RETURN => '0',
        CASC_OUT    => open,
        CNTVALUEOUT => IDELAY_READ_VALUES_CLKDIV8(i));


    INST_isrdsi : ISERDESE3
      generic map (
        IS_CLK_B_INVERTED => '1',
        IS_CLK_INVERTED   => '0',
        IS_RST_INVERTED   => '0',
        DATA_WIDTH        => 8,
        FIFO_ENABLE       => "FALSE",
        FIFO_SYNC_MODE    => "FALSE"
        )
      port map (
        D               => sGbtxDout_d(i),
        RST             => sClkDiv8_rst,
        CLK             => sClkDiv2,
        CLK_B           => sClkDiv2,
        CLKDIV          => sClkDiv8,
        Q               => s_rx_dataframe_reversed(i*8+7 downto i*8),
        FIFO_RD_CLK     => '0',
        FIFO_RD_EN      => '0',
        FIFO_EMPTY      => open,
        INTERNAL_DIVCLK => open);

    for_reverse_rx : for j in 0 to 7 generate
      GBTX_RX_DATAFRAME(i*8 +7-j) <= s_rx_dataframe_reversed(i*8 + j);
    end generate for_reverse_rx;

  end generate GEN_deserializer;

  -----------------------------------------------------------------------------
  -- Tx process
  -----------------------------------------------------------------------------

  GEN_SERIALIZER : for i in 0 to C_GBTX_ELINKS_TX-1 generate
    for_reverse_gen : for j in 0 to 7 generate
      s_tx_dataframe_reversed(i*8 +7-j) <= GBTX_TX_DATAFRAME(i*8 + j);
    end generate for_reverse_gen;

    -- serdes out to GBTx0 DIN/GBTX2 DIN
    INST_oserdes3i : OSERDESE3
      generic map (
        DATA_WIDTH         => 8,
        INIT               => '0',
        IS_CLKDIV_INVERTED => '0',
        IS_CLK_INVERTED    => '0',
        IS_RST_INVERTED    => '0',
        SIM_DEVICE         => "ULTRASCALE"
        )
      port map (
        OQ     => GBTX_DIN(i),
        T_OUT  => open,
        CLK    => sClkDiv2,             -- 160MHz
        CLKDIV => sClkDiv8,             -- 40MHz
        D      => s_tx_dataframe_reversed(i*8+7 downto i*8),
        RST    => sClkDiv8_rst,
        T      => '0'
        );

    if_use_gbtx1_gen : if G_USE_GBTX1 = 1 generate
      for_reverse1_gen : for j in 0 to 7 generate
        s_tx1_dataframe_reversed(i*8 +7-j) <= GBTX1_TX_DATAFRAME(i*8 + j);
      end generate for_reverse1_gen;

      -- serdes out to GBTx1 DIN
      INST_oserdes3i1 : OSERDESE3
        generic map (
          DATA_WIDTH         => 8,
          INIT               => '0',
          IS_CLKDIV_INVERTED => '0',
          IS_CLK_INVERTED    => '0',
          IS_RST_INVERTED    => '0',
          SIM_DEVICE         => "ULTRASCALE"
          )
        port map (
          OQ     => GBTX1_DIN(i),
          T_OUT  => open,
          CLK    => sClkDiv2,           -- 160MHz
          CLKDIV => sClkDiv8,           -- 40MHz
          D      => s_tx1_dataframe_reversed(i*8+7 downto i*8),
          RST    => sClkDiv8_rst,
          T      => '0'
          );
    end generate if_use_gbtx1_gen;

    else_use_gbtx1_gen : if G_USE_GBTX1 = 0 generate
      GBTX1_DIN <= (others => '0');
    end generate else_use_gbtx1_gen;

  end generate GEN_SERIALIZER;

end architecture Behavior;
