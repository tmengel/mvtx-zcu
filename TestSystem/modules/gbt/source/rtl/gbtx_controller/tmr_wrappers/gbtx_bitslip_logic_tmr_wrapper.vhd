-------------------------------------------------------------------------------
-- Title      : GBTX bitslip_logic_tmr_wrapper firmware
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_bitslip_logic_tmr_wrapper.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-19
-- Last update: 2018-03-30
-- Platform   : Vivado 2016.1
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for the gbtx_bitslip_logic module.
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
use work.xpm_cdc_components_pkg.all;
use work.gbtx_pkg.all;
use work.gbtx_controller_pkg.all;
use work.tmr_pkg.all;

entity gbtx_bitslip_logic_tmr_wrapper is
  generic (
    G_SEE_MITIGATION_TECHNIQUE : integer := 0;
    G_MISMATCH_EN              : integer := 1;
    G_ADDITIONAL_MISMATCH      : integer := 1
    );
  port (
    CLK_DIV8              : in  std_logic;
    RST                   : in  std_logic;
    RX_READY              : in  std_logic;
    BITSLIP_VALUE_CLKDIV8 : in  std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_LOAD_CLKDIV8  : in  std_logic;
    DATAFRAME_i           : in  std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    -- out
    DATAFRAME_o           : out std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    -- mismatch
    MISMATCH              : out std_logic;
    MISMATCH_2ND          : out std_logic);
  attribute DONT_TOUCH                                   : string;
  attribute DONT_TOUCH of gbtx_bitslip_logic_tmr_wrapper : entity is "true";
end entity gbtx_bitslip_logic_tmr_wrapper;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture Behavior of gbtx_bitslip_logic_tmr_wrapper is

begin

  if_NOMITIGATION_generate : if G_SEE_MITIGATION_TECHNIQUE = 0 generate
    INST_gbtx_bitsplip_logic : entity work.gbtx_bitsplip_logic
      port map (
        CLK_DIV8              => CLK_DIV8,
        RST                   => RST,
        RX_READY              => RX_READY,
        BITSLIP_VALUE_CLKDIV8 => BITSLIP_VALUE_CLKDIV8,
        BITSLIP_LOAD_CLKDIV8  => BITSLIP_LOAD_CLKDIV8,
        DATAFRAME_i           => DATAFRAME_i,
        DATAFRAME_o           => DATAFRAME_o
        );
    MISMATCH     <= '0';
    MISMATCH_2ND <= '0';
  end generate if_NOMITIGATION_generate;

  if_TMR_generate : if G_SEE_MITIGATION_TECHNIQUE = 1 generate
    -- purpose: implements the tmr for hte gbtx_bitslip_logic, defines the necessary signals locally
    tmr_block : block is
      type t_gbtx_dataframe_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);

      signal s_gbtx_dataframe : t_gbtx_dataframe_tmr;

      attribute DONT_TOUCH                     : string;
      attribute DONT_TOUCH of s_gbtx_dataframe : signal is "TRUE";

      constant C_MISMATCH_WIDTH                     : integer                                       := 1;
      constant C_MISMATCH_NONE                      : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0) := (others => '0');
      signal s_mismatch_array, s_mismatch_2nd_array : std_logic_vector(C_MISMATCH_WIDTH-1 downto 0);

    begin  -- block tmr_block

      process (CLK_DIV8, RX_READY) is
      begin  -- process
        if RX_READY = '0' then           -- asynchronous reset (active high)
          MISMATCH <= '0';
        else
          if rising_edge(CLK_DIV8) then  -- rising clock edge
            if s_mismatch_array = C_MISMATCH_NONE then
              MISMATCH <= '0';
            else
              MISMATCH <= '1';
            end if;
          end if;
        end if;
      end process;

      if_additional_mismatch_gen : if G_ADDITIONAL_MISMATCH = 1 generate
        process (CLK_DIV8, RX_READY) is
        begin  -- process
          if RX_READY = '0' then           -- asynchronous reset (active high)
            MISMATCH_2ND <= '0';
          else
            if rising_edge(CLK_DIV8) then  -- rising clock edge
              if s_mismatch_2nd_array = C_MISMATCH_NONE then
                MISMATCH_2ND <= '0';
              else
                MISMATCH_2ND <= '1';
              end if;
            end if;
          end if;
        end process;
      end generate if_additional_mismatch_gen;

      if_not_add_mismatch_gen : if G_ADDITIONAL_MISMATCH = 0 generate
        MISMATCH_2ND <= '0';
      end generate if_not_add_mismatch_gen;

      -- for generate
      TMR_FOR_generate : for i in 0 to C_K_TMR-1 generate
        INST_gbtx_bitsplip_logic : entity work.gbtx_bitsplip_logic
          port map (
            CLK_DIV8              => CLK_DIV8,
            RST                   => RST,
            RX_READY              => RX_READY,
            BITSLIP_VALUE_CLKDIV8 => BITSLIP_VALUE_CLKDIV8,
            BITSLIP_LOAD_CLKDIV8  => BITSLIP_LOAD_CLKDIV8,
            DATAFRAME_i           => DATAFRAME_i,
            DATAFRAME_o           => s_gbtx_dataframe(i));
      end generate TMR_FOR_generate;

      INST_majority_voter_array_wrapper_DATAFRAME_o : entity work.majority_voter_array_wrapper
        generic map (
          MISMATCH_EN           => G_MISMATCH_EN,
          G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
          C_WIDTH               => C_GBTX_DATAFRAME_SIZE)
        port map (
          ASSERTION_CLK => CLK_DIV8,
          ASSERTION_RST => RST,
          INPUT_A       => s_gbtx_dataframe(0),
          INPUT_B       => s_gbtx_dataframe(1),
          INPUT_C       => s_gbtx_dataframe(2),
          OUTPUT        => DATAFRAME_o,
          MISMATCH      => s_mismatch_array(0),
          MISMATCH_2ND  => s_mismatch_2nd_array(0));

    end block tmr_block;
  end generate if_TMR_generate;

end architecture Behavior;
