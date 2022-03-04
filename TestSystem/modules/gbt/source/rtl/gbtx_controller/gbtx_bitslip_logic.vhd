-------------------------------------------------------------------------------
-- Title      : GBTX bitsplip_logic firmware
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : gbtx_bitsplip_logic.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-09-26
-- Last update: 2018-03-30
-- Platform   : Vivado 2016.4
-- Target     : Kintex-Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Provides the bitsplip_logic for the gbtx_rx_dataframe
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
use work.xpm_cdc_components_pkg.all;

entity gbtx_bitsplip_logic is
  port (
    CLK_DIV8              : in  std_logic;
    RST                   : in  std_logic;
    RX_READY              : in  std_logic;
    BITSLIP_VALUE_CLKDIV8 : in  std_logic_vector(C_BITSLIP_VALUE_bit'range);
    BITSLIP_LOAD_CLKDIV8  : in  std_logic;
    --
    DATAFRAME_i           : in  std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0);
    DATAFRAME_o           : out std_logic_vector(C_GBTX_DATAFRAME_SIZE-1 downto 0)
    );
end entity gbtx_bitsplip_logic;

architecture Behavior of gbtx_bitsplip_logic is

begin

  GEN_deserializer : for i in 0 to C_GBTX_ELINKS_RX-1 generate
    INST_bitslip : entity work.BitSlipInLogic_8b
      generic map (
        C_Slip_Backward => 1,
        C_InputReg      => 0)
      port map (
        DataIn_pin      => DATAFRAME_i(i*8+7 downto i*8),
        Bitslip_pin     => '0',
        Load_pin        => BITSLIP_LOAD_CLKDIV8,
        Bitslip_num_pin => BITSLIP_VALUE_CLKDIV8,
        Ena_pin         => RX_READY,
        Rst_pin         => RST,
        Clk_pin         => CLK_DIV8,
        DataOut_pin     => DATAFRAME_o(i*8+7 downto i*8));
  end generate GEN_deserializer;

end architecture Behavior;
