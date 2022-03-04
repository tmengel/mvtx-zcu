-------------------------------------------------------------------------------
-- Title      : GBTX tx_handler
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_tx_handler.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2018-06-08
-- Platform   : Vivado 2016.4
-- Target     : Kintex-US
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Generates the datavalid and the GBTX_TX_DATAFRAME FOR THE OSERDES
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.xpm_cdc_components_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;

entity gbtx_tx_handler is
  port (
    RST                  : in  std_logic;
    GBTX_TX_DATA         : in  std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0);
    GBTX_TX_STROBE       : in  std_logic;
    --
    -- from/to gbtx_hard_mactros
    RX_READY             : in  std_logic;
    CLK_DIV              : in  std_logic;
    GBTX_TX_DATAFRAME    : out std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    GBTX_RX_DATAFRAME    : in  std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    --
    -- wishbone side
    TX_PATTERN_SELECTION : in  std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    --
    -- GBTX interface
    GBTX_TXDATAVALID     : out std_logic
    );
end entity gbtx_tx_handler;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_tx_handler is

  signal s_tx_datavalid                : std_logic_vector(4 downto 0) := (others => '0');
  signal s_tx_pattern_selection_clkdiv : std_logic_vector(1 downto 0) := (others => '0');

  signal sGbtCounter : unsigned(19 downto 0) := (others => '0');

begin

  -- syncrhonize TEST_PATTERN_SEL with an XPM to CLK_DIV clock domain
  INST_cdc_testpattern_sel : xpm_cdc_array_single
    generic map (
      DEST_SYNC_FF   => 2,              -- integer; range: 2-10
      SIM_ASSERT_CHK => 0,  -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 0,  -- integer; 0=do not register input, 1=register input
      WIDTH          => C_TX_PATTERN_SELECTION_bit'length  -- integer; range: 2-1024
      )
    port map (
      src_clk  => '0',      -- optional; required when SRC_INPUT_REG = 1
      src_in   => TX_PATTERN_SELECTION,
      dest_clk => CLK_DIV,
      dest_out => s_tx_pattern_selection_clkdiv
      );

  -- TX process: determine what data to serialize
  p_serialData : process (CLK_DIV, RX_READY) is
  begin
    if RX_READY = '0' then
      GBTX_TXDATAVALID  <= '0';         -- default
      GBTX_TX_DATAFRAME <= (others => '0');
      s_tx_datavalid    <= (others => '0');
      sGbtCounter       <= (others => '0');

    elsif rising_edge(CLK_DIV) then
      GBTX_TXDATAVALID <= '0';          -- default

      case s_tx_pattern_selection_clkdiv is
        when C_GBTX_TX_PATTERN_FIFO =>
          -- send triggered data
          if GBTX_TX_STROBE = '1' then
            GBTX_TX_DATAFRAME <= GBTX_TX_DATA(79 downto 0);
            -- align GBTX_TXDATAVALID with data
            s_tx_datavalid    <= s_tx_datavalid(s_tx_datavalid'high-1 downto 0) & GBTX_TX_DATA(80);
          else
            GBTX_TX_DATAFRAME <= C_GBTX_IDLE_PACKET;
            s_tx_datavalid    <= s_tx_datavalid(s_tx_datavalid'high-1 downto 0) & '0';
          end if;
          GBTX_TXDATAVALID <= s_tx_datavalid(s_tx_datavalid'high);

        when C_GBTX_TX_PATTERN_COUNTER =>
          -- send counter pattern repeated 4 times over 80 bits
          sGbtCounter <= sGbtCounter + 1;
          for i in 0 to 3 loop
            GBTX_TX_DATAFRAME((20*i)+19 downto 20*i) <= std_logic_vector(sGbtCounter);
          end loop;  -- i

        when C_GBTX_TX_PATTERN_STATIC =>
          -- load GBT_FPGA fixed pattern
          GBTX_TX_DATAFRAME <= x"000b_abea_c1da_cdcf_ffff";
        when C_GBTX_TX_PATTERN_MIRROR =>
          -- mirror received data
          GBTX_TX_DATAFRAME <= GBTX_RX_DATAFRAME;

        when others =>                  -- default is fifo
          -- synthesis translate_off
          report "ILLEGAL VALUE" severity WARNING;
          -- synthesis translate_on
      end case;
    end if;
  end process p_serialData;

end architecture Behavior;
