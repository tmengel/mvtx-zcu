-------------------------------------------------------------------------------
-- Title      : GBTX handler_tx_tmr_wrapper
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_handler_tx_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2018-02-14
-- Platform   : Vivado 2016.1
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the gbtx_tx_handler module.
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

entity gbtx_tx_handler_tmr_wrapper is
  generic (
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_MISMATCH_EN              : integer := 1;
    G_ADDITIONAL_MISMATCH      : integer := 1
    );
  port (
    RST                  : in  std_logic;
    -- from/to gbtx_hard_mactros
    GBTX_TX_DATA         : in  std_logic_vector(C_GBTX_DATA_WIDTH-1 downto 0);
    GBTX_TX_STROBE       : in  std_logic;
    RX_READY             : in  std_logic;
    CLK_DIV              : in  std_logic;
    GBTX_TX_DATAFRAME    : out std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    GBTX_RX_DATAFRAME    : in  std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    -- wishbone side
    TX_PATTERN_SELECTION : in  std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    -- GBTX interface
    GBTX_TXDATAVALID_A   : out std_logic;
    GBTX_TXDATAVALID_B   : out std_logic;
    GBTX_TXDATAVALID_C   : out std_logic;
    -- mismatch
    MISMATCH             : out std_logic;
    MISMATCH_2ND         : out std_logic
    );
  attribute DONT_TOUCH                                : string;
  attribute DONT_TOUCH of gbtx_tx_handler_tmr_wrapper : entity is "true";
end entity gbtx_tx_handler_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_tx_handler_tmr_wrapper is
begin

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    no_tmr_block : block is
      signal sTxDatavalid : std_logic;
    begin  -- block no_tmr_block
      INST_gbtx_tx_handler : entity work.gbtx_tx_handler
        port map (
          RST                  => RST,
          GBTX_TX_DATA         => GBTX_TX_DATA,
          GBTX_TX_STROBE       => GBTX_TX_STROBE,
          RX_READY             => RX_READY,
          CLK_DIV              => CLK_DIV,
          TX_PATTERN_SELECTION => TX_PATTERN_SELECTION,
          GBTX_TX_DATAFRAME    => GBTX_TX_DATAFRAME,
          GBTX_RX_DATAFRAME    => GBTX_RX_DATAFRAME,
          -- 
          GBTX_TXDATAVALID     => sTxDatavalid
          );
      GBTX_TXDATAVALID_A <= sTxDatavalid;
      GBTX_TXDATAVALID_B <= sTxDatavalid;
      GBTX_TXDATAVALID_C <= sTxDatavalid;
    end block no_tmr_block;

    MISMATCH     <= '0';
    MISMATCH_2ND <= '0';
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_handler, defines the necessary signals locally
    tmr_block : block is
      type t_gbtx_tx_dataframe_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);

      signal s_gbtx_txdatavalid  : std_logic_vector(C_K_TMR-1 downto 0);
      signal s_gbtx_tx_dataframe : t_gbtx_tx_dataframe_tmr;

      attribute DONT_TOUCH                        : string;
      attribute DONT_TOUCH of s_gbtx_txdatavalid  : signal is "TRUE";
      attribute DONT_TOUCH of s_gbtx_tx_dataframe : signal is "TRUE";

      constant C_MISMATCH_WIDTH                   : integer                                       := 2;
      constant C_MISMATCH_NONE                    : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch, s_mismatch_2nd           : std_logic;

    begin  -- block tmr_block

      process (CLK_DIV, RX_READY) is
      begin  -- process
        if RX_READY = '0' then          -- asynchronous reset (active high)
          MISMATCH <= '0';
        else
          if rising_edge(CLK_DIV) then  -- rising clock edge
            MISMATCH <= s_mismatch;
          -- if s_mismatch = C_MISMATCH_NONE then
          --   MISMATCH <= '0';
          -- else
          --   MISMATCH <= '1';
          -- end if;
          end if;
        end if;
      end process;

      if_additional_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
        process (CLK_DIV, RX_READY) is
        begin  -- process
          if RX_READY = '0' then          -- asynchronous reset (active high)
            MISMATCH_2ND <= '0';
          else
            if rising_edge(CLK_DIV) then  -- rising clock edge
              MISMATCH_2ND <= s_mismatch_2nd;
            -- if s_mismatch_2nd_array = C_MISMATCH_NONE then
            --   MISMATCH_2ND <= '0';
            -- else
            --   MISMATCH_2ND <= '1';
            -- end if;
            end if;
          end if;
        end process;
      end generate if_additional_mismatch_gen;

      if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
        MISMATCH_2ND <= '0';
      end generate if_not_add_mismatch_gen;

      -- for generate
      TMR_FOR_generate : for i in 0 to C_K_TMR-1 generate
        INST_gbtx_tx_handler : entity work.gbtx_tx_handler
          port map (
            RST                  => RST,
            CLK_DIV              => CLK_DIV,
            RX_READY             => RX_READY,
            GBTX_TX_DATA         => GBTX_TX_DATA,
            GBTX_TX_STROBE       => GBTX_TX_STROBE,
            TX_PATTERN_SELECTION => TX_PATTERN_SELECTION,
            GBTX_RX_DATAFRAME    => GBTX_RX_DATAFRAME,
            GBTX_TXDATAVALID     => s_gbtx_txdatavalid(i),
            GBTX_TX_DATAFRAME    => s_gbtx_tx_dataframe(i)
            );
      end generate TMR_FOR_generate;

      GBTX_TXDATAVALID_A <= s_gbtx_txdatavalid(0);
      GBTX_TXDATAVALID_B <= s_gbtx_txdatavalid(1);
      GBTX_TXDATAVALID_C <= s_gbtx_txdatavalid(2);

      INST_majority_voter_array_wrapper_TX_DATAFRAME : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_GBTX_DATAFRAME_SIZE)
        port map (
          ASSERTION_CLK => CLK_DIV,
          ASSERTION_RST => RST,
          INPUT_A       => s_gbtx_tx_dataframe(0),
          INPUT_B       => s_gbtx_tx_dataframe(1),
          INPUT_C       => s_gbtx_tx_dataframe(2),
          OUTPUT        => GBTX_TX_DATAFRAME,
          MISMATCH      => s_mismatch,
          MISMATCH_2ND  => s_mismatch_2nd
          );

    end block tmr_block;
  end generate if_TMR_generate;

end architecture Behavior;
