-------------------------------------------------------------------------------
-- Title      : ws_usb_if_readout
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : ws_usb_if_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-08-03
-- Last update: 2017-08-04
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2017 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Wishbone mapping:
--
--   0x00 -> GBTX_CONTROLLER_ENABLE : R/W
--                           Bit 0  : 1: Enables the GBTX controller [Default]
--   0x01 -> GBTX_RESET              : R/W
--                           Bit 0  : Resets the GBTX (negative logic)
--   [0x02:0x06]-> SET_IDELAY_VALUE{01:89} : R/W
--                           [4:0]  : Delay value feed to the IDELAYE2
--   [0x07:0x0B]-> GET_IDELAY_VALUE{0:4}   : R/W
--                           [4:0]  : Delay value written into the IDELAYE2
--   0x0C -> IDELAY_LOAD            : W only
--                           Bit 0  : Loads the corresponding IDELAY value (pulse)
--                           Bit 1  : Loads the corresponding IDELAY value (pulse)
--                           Bit 2  : Loads the corresponding IDELAY value (pulse)
--                           Bit 3  : Loads the corresponding IDELAY value (pulse)
--                           Bit 4  : Loads the corresponding IDELAY value (pulse)
--   0x0D -> BITSLIP_RX_CONTROL     : R/W
--                           [2:0]  : BITSLIP on the RX side to be reached
--                           (automatically iterates until condition met)
--   0x0E -> TX_PATTERN_SELECTION   : R/W
--                           [1:0]  : Select the tx pattern to the GBTX (80 bits)
--                                      00: transmit data from FIFO
--                                      01: 4 times repeated pattern
--                                      10: static pattern 1
--                                      11: static pattern 2
--   0x0F -> BITSLIP_TX_CONTROL     : R/W
--                           [2:0]  : BITSLIP on the TX side to be reached
--                           (NOT implemented yet)
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;

package ws_usb_if_pkg is

  -- Mapping of WB Registers
  type t_WB_ADDS is record
    DP23_CMD                     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP2_WRDS_MSB   : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP2_WRDS_LSB   : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP2_RDWRDS_MSB : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP2_RDWRDS_LSB : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP2_OVFL       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP2_FULL       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP3_WRDS_MSB   : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP3_WRDS_LSB   : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP3_RDWRDS_MSB : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP3_RDWRDS_LSB : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP3_OVFL       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_DP23_STS_DP3_FULL       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CFG_DP23_PRODUCER_ADDRESS    : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    NUM_REGS                     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  end record;

  constant WB_ADD : t_WB_ADDS := (
    DP23_CMD                     => x"00",
    READ_DP23_STS_DP2_WRDS_MSB   => x"01",
    READ_DP23_STS_DP2_WRDS_LSB   => x"02",
    READ_DP23_STS_DP2_OVFL       => x"03",
    READ_DP23_STS_DP3_WRDS_MSB   => x"04",
    READ_DP23_STS_DP3_WRDS_LSB   => x"05",
    READ_DP23_STS_DP3_OVFL       => x"06",
    CFG_DP23_PRODUCER_ADDRESS    => x"07",
    READ_DP23_STS_DP2_RDWRDS_MSB => x"08",
    READ_DP23_STS_DP2_RDWRDS_LSB => x"09",
    READ_DP23_STS_DP2_FULL       => x"0A",
    READ_DP23_STS_DP3_RDWRDS_MSB => x"0B",
    READ_DP23_STS_DP3_RDWRDS_LSB => x"0C",
    READ_DP23_STS_DP3_FULL       => x"0D",
    NUM_REGS                     => x"0E");

  -- bit mapping of WS_CMD_dp23_monitor
  constant C_DP23_CMD_bit_dp2_rst_cntr_words     : integer := 0;
  constant C_DP23_CMD_bit_dp2_rst_cntr_ovfl      : integer := 1;
  constant C_DP23_CMD_bit_dp2_latch_cntr_words   : integer := 2;
  constant C_DP23_CMD_bit_dp2_latch_cntr_ovfl    : integer := 3;
  constant C_DP23_CMD_bit_dp2_rst_cntr_rdwords   : integer := 4;
  constant C_DP23_CMD_bit_dp2_rst_cntr_full      : integer := 5;
  constant C_DP23_CMD_bit_dp2_latch_cntr_rdwords : integer := 6;
  constant C_DP23_CMD_bit_dp2_latch_cntr_full    : integer := 7;
  constant C_DP23_CMD_bit_dp3_rst_cntr_words     : integer := 8;
  constant C_DP23_CMD_bit_dp3_rst_cntr_ovfl      : integer := 9;
  constant C_DP23_CMD_bit_dp3_latch_cntr_words   : integer := 10;
  constant C_DP23_CMD_bit_dp3_latch_cntr_ovfl    : integer := 11;
  constant C_DP23_CMD_bit_dp3_rst_cntr_rdwords   : integer := 12;
  constant C_DP23_CMD_bit_dp3_rst_cntr_full      : integer := 13;
  constant C_DP23_CMD_bit_dp3_latch_cntr_rdwords : integer := 14;
  constant C_DP23_CMD_bit_dp3_latch_cntr_full    : integer := 15;

  -- bit mapping of CFG_DP23PRODUCER_ADDRESS
  constant C_CFG_DP23_bit_dp2_producer_address : std_logic_vector(3 downto 0)  := (others => '0');
  constant C_CFG_DP23_bit_dp3_producer_address : std_logic_vector(11 downto 8) := (others => '0');

end package ws_usb_if_pkg;
