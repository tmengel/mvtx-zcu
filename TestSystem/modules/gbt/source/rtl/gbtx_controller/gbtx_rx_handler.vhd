-------------------------------------------------------------------------------
-- Title      : GBTX rx_handler
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_rx_handler.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2018-10-04
-- Platform   : Vivado 2016.4
-- Target     : Kintex-US
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Deserialize GBTx DOUT signals and compile into an 80bit GBT
--              frame; add RX_DATAVALID as 81st bit and stuff in FIFO.
--              TX data is either from a testpattern, or from the TX_FIFO;
--              TX data is serizalized, with the 81st bit from the FIFO used
--              to assert the TX_DATAVALID
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

entity gbtx_rx_handler is
  port (
    WB_CLK             : in  std_logic;
    RST                : in  std_logic;
    GBTX_RXDATAVALID_D : out std_logic;
    -- from/to gbtx_hard_mactros
    RX_READY           : in  std_logic;
    CLK_DIV2           : in  std_logic;
    CLK_DIV8           : in  std_logic;

    -- wishbone side
    BITSLIP_RX_VALUE   : in  std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_RX_LOAD    : in  std_logic;
    IDELAY_LOAD        : in  std_logic;
    IDELAY_VALUES      : in  t_idelay_values;
    IDELAY_READ_VALUES : out t_idelay_values;

    -- reclocked values
    BITSLIP_RX_VALUE_CLKDIV8   : out std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_RX_LOAD_CLKDIV8    : out std_logic;
    IDELAY_LOAD_CLKDIV8        : out std_logic;
    IDELAY_VALUES_CLKDIV8      : out t_idelay_values;
    IDELAY_READ_VALUES_CLKDIV8 : in  t_idelay_values;

    -- GBTX interface
    GBTX_RXDATAVALID : in std_logic
    );
end entity gbtx_rx_handler;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_rx_handler is

  signal s_delay_load_from_wishbone, s_delay_load_auto     : std_logic;
  signal s_bitslip_load_from_wishbone, s_bitslip_load_auto : std_logic;

  signal sRxReady_d1        : std_logic;
  signal s_gbtx_rxdatavalid : std_logic_vector(2 downto 0);

  signal sRxDatavalid_iddr : std_logic;
  signal sRxDatavalid_dly  : std_logic;

begin

  INST_delayld_sync : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      INIT_SYNC_FF   => 1,  -- integer; 0=disable simulation init values, 1=enable simulation init values
      REG_OUTPUT     => 0,  -- integer; 0=disable registered output, 1=enable registered output
      RST_USED       => 0,  -- integer; 0=no reset, 1=implement reset
      SIM_ASSERT_CHK => 1  -- integer; 0=disable simulation messages, 1=enable simulation messages
      )
    port map (
      src_clk    => WB_CLK,
      src_rst    => '0',                -- optional; required when RST_USED = 1
      src_pulse  => IDELAY_LOAD,
      dest_clk   => CLK_DIV8,
      dest_rst   => '0',                -- optional; required when RST_USED = 1
      dest_pulse => s_delay_load_from_wishbone
      );

  INST_bitslipld_sync : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      INIT_SYNC_FF   => 1,  -- integer; 0=disable simulation init values, 1=enable simulation init values
      REG_OUTPUT     => 0,  -- integer; 0=disable registered output, 1=enable registered output
      RST_USED       => 0,  -- integer; 0=no reset, 1=implement reset
      SIM_ASSERT_CHK => 1  -- integer; 0=disable simulation messages, 1=enable simulation messages
      )
    port map (
      src_clk    => WB_CLK,
      src_rst    => '0',                -- optional; required when RST_USED = 1
      src_pulse  => BITSLIP_RX_LOAD,
      dest_clk   => CLK_DIV8,
      dest_rst   => '0',                -- optional; required when RST_USED = 1
      dest_pulse => s_bitslip_load_from_wishbone
      );

  INST_bitslip_sync : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      SIM_ASSERT_CHK => 1,  -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 0,  -- integer; 0=do not register input, 1=register input
      WIDTH          => C_BITSLIP_VALUE_bit'length  -- integer; range: 2-1024
      )
    port map (
      src_clk  => '0',      -- optional; required when SRC_INPUT_REG = 1
      src_in   => BITSLIP_RX_VALUE,
      dest_clk => CLK_DIV8,
      dest_out => BITSLIP_RX_VALUE_CLKDIV8
      );

  for_idelay_gen : for i in 0 to C_GBTX_ELINKS_RX-1 generate
    INST_delay_sync : xpm_cdc_array_single
      generic map (
        DEST_SYNC_FF   => 2,            -- integer; range: 2-10
        SIM_ASSERT_CHK => 1,  -- integer; 0=disable simulation messages, 1=enable simulation messages
        SRC_INPUT_REG  => 0,  -- integer; 0=do not register input, 1=register input
        WIDTH          => C_IDELAY_DELAY_WIDTH  -- integer; range: 2-1024
        )
      port map (
        src_clk  => '0',      -- optional; required when SRC_INPUT_REG = 1
        src_in   => IDELAY_VALUES(i),
        dest_clk => CLK_DIV8,
        dest_out => IDELAY_VALUES_CLKDIV8(i)
        );

    INST_delay_read_sync : xpm_cdc_array_single
      generic map (
        DEST_SYNC_FF   => 2,            -- integer; range: 2-10
        SIM_ASSERT_CHK => 1,  -- integer; 0=disable simulation messages, 1=enable simulation messages
        SRC_INPUT_REG  => 0,  -- integer; 0=do not register input, 1=register input
        WIDTH          => C_IDELAY_DELAY_WIDTH  -- integer; range: 2-1024
        )
      port map (
        src_clk  => '0',      -- optional; required when SRC_INPUT_REG = 1
        src_in   => IDELAY_READ_VALUES_CLKDIV8(i),
        dest_clk => WB_CLK,
        dest_out => IDELAY_READ_VALUES(i)
        );
  end generate for_idelay_gen;


  -- purpose: generates the load_en signal for the bitslip logic
  p_rx_ready_d1 : process (CLK_DIV8, RX_READY) is
  begin
    if RX_READY = '0' then
      sRxReady_d1 <= '0';
    else
      if rising_edge(CLK_DIV8) then     -- rising clock edge
        if RST = '1' then               -- synchronous reset (active high)
          sRxReady_d1 <= '0';
        else
          sRxReady_d1 <= RX_READY;
        end if;
      end if;
    end if;
  end process p_rx_ready_d1;

  p_bitslip_load_en : process (CLK_DIV8) is
  begin  -- process p_bitslip_load_en
    if rising_edge(CLK_DIV8) then       -- rising clock edge
      if RST = '1' then                 -- synchronous reset (active high)
        s_bitslip_load_auto     <= '0';
        s_delay_load_auto       <= '0';
        BITSLIP_RX_LOAD_CLKDIV8 <= '0';
        IDELAY_LOAD_CLKDIV8     <= '0';
      else
        s_bitslip_load_auto     <= RX_READY and not(sRxReady_d1);
        BITSLIP_RX_LOAD_CLKDIV8 <= s_bitslip_load_from_wishbone or s_bitslip_load_auto;
        s_delay_load_auto       <= RX_READY and not(sRxReady_d1);
        IDELAY_LOAD_CLKDIV8     <= s_delay_load_from_wishbone or s_delay_load_auto;
      end if;
    end if;
  end process p_bitslip_load_en;

  -- capture GBTX_RXDATAVALID with an IDDR after IDELAY
  INST_idlyi : IDELAYE3
    generic map (
      IS_RST_INVERTED  => '0',
      IS_CLK_INVERTED  => '0',
      DELAY_SRC        => "IDATAIN",
      CASCADE          => "NONE",
      DELAY_TYPE       => "FIXED",
      DELAY_VALUE      => 0,
      REFCLK_FREQUENCY => 300.0,
      DELAY_FORMAT     => "COUNT",
      UPDATE_MODE      => "ASYNC")
    port map (
      IDATAIN     => GBTX_RXDATAVALID,
      DATAOUT     => sRxDatavalid_dly,
      CLK         => CLK_DIV8,
      CE          => '0',
      RST         => '0',
      INC         => '0',
      DATAIN      => '0',
      LOAD        => '0',
      CNTVALUEIN  => "000000000",
      EN_VTC      => '0',
      CASC_IN     => '0',
      CASC_RETURN => '0',
      CASC_OUT    => open,
      CNTVALUEOUT => open
      );

  IDDRE1_inst : IDDRE1
    generic map (
      DDR_CLK_EDGE   => "OPPOSITE_EDGE",  -- IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
      IS_CB_INVERTED => '1',            -- Optional inversion for CB
      IS_C_INVERTED  => '0'             -- Optional inversion for C
      )
    port map (
      Q1 => open,               -- 1-bit output: Registered parallel output 1
      Q2 => sRxDatavalid_iddr,  -- 1-bit output: Registered parallel output 2
      C  => CLK_DIV8,                   -- 1-bit input: High-speed clock
      CB => CLK_DIV8,           -- 1-bit input: Inversion of High-speed clock C
      D  => sRxDatavalid_dly,           -- 1-bit input: Serial Data Input
      R  => '0'                         -- 1-bit input: Active High Async Reset
      );

  -- delay the GBTX_RXDATAVALID to align with RX data
  p_delayRxdatavalid : process (CLK_DIV8, RX_READY) is
  begin
    if RX_READY = '0' then
      s_gbtx_rxdatavalid <= (others => '0');
    elsif rising_edge(CLK_DIV8) then
      -- latch and align GBTX_RXDATAVALID
      s_gbtx_rxdatavalid <= s_gbtx_rxdatavalid(1 downto 0) & sRxDatavalid_iddr;
    end if;
  end process p_delayRxdatavalid;

  GBTX_RXDATAVALID_D <= s_gbtx_rxdatavalid(2);

end architecture Behavior;
