-------------------------------------------------------------------------------
-- Title      : GBTX fifo_tmr_wrapper firmware
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_fifo_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2017-11-03
-- Platform   : Vivado 2016.1
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the gbtx_fifo module.
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

entity gbtx_fifo_tmr_wrapper is
  generic (
    USE_DEBUG                  : string  := "TRUE";
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_MISMATCH_EN              : integer := 1;
    G_ADDITIONAL_MISMATCH      : integer := 1
    );
  port (
    CLK_DIV : in std_logic;
    RST     : in std_logic;

    RX_DATAVALID_D : in std_logic;
    GBT_DATAFRAME  : in std_logic_vector(C_GBT_PACKET_SIZE-1 downto 0);
    PLL_LOCKED     : in std_logic;

    GBTX_RX_DATA  : out std_logic_vector(C_GBT_DATA_WIDTH-1 downto 0);
    RX_FIFO_EMPTY : out std_logic;
    RX_FIFO_CLK   : in  std_logic;
    MISMATCH      : out std_logic;
    MISMATCH_2ND  : out std_logic
    );
  attribute DONT_TOUCH                          : string;
  attribute DONT_TOUCH of gbtx_fifo_tmr_wrapper : entity is "true";
end entity gbtx_fifo_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_fifo_tmr_wrapper is

  component fifo81x16
    port (
      wr_clk : in  std_logic;
      rd_clk : in  std_logic;
      din    : in  std_logic_vector(C_GBT_DATA_WIDTH-1 downto 0);
      wr_en  : in  std_logic;
      rd_en  : in  std_logic;
      dout   : out std_logic_vector(C_GBT_DATA_WIDTH-1 downto 0);
      full   : out std_logic;
      empty  : out std_logic
      );
  end component;

  signal sGbtRxData                  : std_logic_vector(C_GBT_DATA_WIDTH-1 downto 0) := (others => '0');
  -- debug signals for ILA
  attribute mark_debug               : string;
  attribute mark_debug of sGbtRxData : signal is USE_DEBUG;

begin

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    nomitigation_block : block is
      signal sRxFifoEmpty : std_logic;
      signal sRxFifoRden  : std_logic;

    begin  -- block tmr_block

      sGbtRxData(C_GBT_PACKET_SIZE-1 downto 0) <= GBT_DATAFRAME;
      sGbtRxData(C_GBT_DATA_WIDTH-1)           <= RX_DATAVALID_D;
      -- FIFO to output deserialized GBT RX Data
      INST_fifo81x16 : fifo81x16
        port map (
          wr_clk => CLK_DIV,
          rd_clk => RX_FIFO_CLK,
          din    => sGbtRxData,
          wr_en  => PLL_LOCKED,
          rd_en  => sRxFifoRden,
          dout   => GBTX_RX_DATA,
          full   => open,
          empty  => sRxFifoEmpty
          );
      sRxFifoRden   <= not sRxFifoEmpty;
      RX_FIFO_EMPTY <= sRxFifoEmpty;

      MISMATCH     <= '0';
      MISMATCH_2ND <= '0';
    end block;
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_fifo, defines the necessary signals locally
    tmr_block : block is
      constant C_MMR_SIZE : natural := 3;  -- TMR

      type t_gbtx_rx_data_tmr is array (0 to C_MMR_SIZE-1) of std_logic_vector(C_GBT_DATA_WIDTH-1 downto 0);

      signal sRxFifoEmpty   : std_logic_vector(C_MMR_SIZE-1 downto 0);
      signal sRxFifoRden    : std_logic_vector(C_MMR_SIZE-1 downto 0);
      signal s_gbtx_rx_data : t_gbtx_rx_data_tmr;

      attribute DONT_TOUCH                   : string;
      attribute DONT_TOUCH of sRxFifoEmpty   : signal is "TRUE";
      attribute DONT_TOUCH of sRxFifoRden    : signal is "TRUE";
      attribute DONT_TOUCH of s_gbtx_rx_data : signal is "TRUE";

      signal sRxFifoRden_voted : std_logic;

      constant C_MISMATCH_WIDTH                     : integer                                       := 3;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block
      MISMATCH <= '0' when s_mismatch_array = C_MISMATCH_NONE else
                  '1';

      if_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
        MISMATCH_2ND <= '0' when s_mismatch_2nd_array = C_MISMATCH_NONE else
                        '1';
      end generate if_add_mismatch_gen;

      if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
        MISMATCH_2ND <= '0';
      end generate if_not_add_mismatch_gen;

      -- for generate
      sGbtRxData(C_GBT_PACKET_SIZE-1 downto 0) <= GBT_DATAFRAME;
      sGbtRxData(C_GBT_DATA_WIDTH-1)           <= RX_DATAVALID_D;

      TMR_FOR_generate : for i in 0 to C_MMR_SIZE-1 generate
        INST_fifo81x16 : fifo81x16
          port map (
            wr_clk => CLK_DIV,
            rd_clk => RX_FIFO_CLK,
            din    => sGbtRxData,
            wr_en  => PLL_LOCKED,
            rd_en  => sRxFifoRden_voted,
            dout   => s_gbtx_rx_data(i),
            full   => open,
            empty  => sRxFifoEmpty(i)
            );
        sRxFifoRden(i) <= not sRxFifoEmpty(i);
      end generate TMR_FOR_generate;

      INST_majority_voter_wrapper2_RXFIFORDEN : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT         => sRxFifoRden,
          OUTPUT        => sRxFifoRden_voted,
          MISMATCH      => s_mismatch_array(0),
          MISMATCH_2ND  => s_mismatch_2nd_array(0));

      INST_majority_voter_wrapper2_RXFIFOEMPTY : entity work.majority_voter_wrapper2
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT         => sRxFifoEmpty,
          OUTPUT        => RX_FIFO_EMPTY,
          MISMATCH      => s_mismatch_array(1),
          MISMATCH_2ND  => s_mismatch_2nd_array(1));

      INST_majority_voter_array_wrapper_gbtx_rx_data : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_GBT_DATA_WIDTH)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT_A       => s_gbtx_rx_data(0),
          INPUT_B       => s_gbtx_rx_data(1),
          INPUT_C       => s_gbtx_rx_data(2),
          OUTPUT        => GBTX_RX_DATA,
          MISMATCH      => s_mismatch_array(2),
          MISMATCH_2ND  => s_mismatch_2nd_array(2));

    end block tmr_block;
  end generate if_TMR_generate;

end architecture Behavior;
