-------------------------------------------------------------------------------
-- Title      : ws_master_readout
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : ws_master_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-06
-- Last update: 2017-09-22
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author  Description
-- 2016-07-06  1.0      ML      Created
-- 2016-11-02  1.1      ML      Added selection for DPmux
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;

package ws_master_pkg is

  -- Mapping of WB Registers
  type t_WB_ADDS is record
    READ_WBM_WRERRCNTR           : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_WBM_RDERRCNTR           : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    RST_WBM_CNTR                 : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
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
    DNA_PORT_DO_READ             : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    DNA_PORT_VALUE_W0            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    DNA_PORT_VALUE_W1            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    DNA_PORT_VALUE_W2            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    DNA_PORT_VALUE_W3            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    DNA_PORT_VALUE_W4            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    DNA_PORT_VALUE_W5            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    NUM_REGS                     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  end record;

  constant WB_ADD : t_WB_ADDS := (
    READ_WBM_WRERRCNTR           => std_logic_vector(to_unsigned(0, WB_ADDS_WIDTH)),
    READ_WBM_RDERRCNTR           => std_logic_vector(to_unsigned(1, WB_ADDS_WIDTH)),
    RST_WBM_CNTR                 => std_logic_vector(to_unsigned(2, WB_ADDS_WIDTH)),
    DP23_CMD                     => std_logic_vector(to_unsigned(3, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP2_WRDS_MSB   => std_logic_vector(to_unsigned(4, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP2_WRDS_LSB   => std_logic_vector(to_unsigned(5, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP2_OVFL       => std_logic_vector(to_unsigned(6, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP3_WRDS_MSB   => std_logic_vector(to_unsigned(7, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP3_WRDS_LSB   => std_logic_vector(to_unsigned(8, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP3_OVFL       => std_logic_vector(to_unsigned(9, WB_ADDS_WIDTH)),
    CFG_DP23_PRODUCER_ADDRESS    => std_logic_vector(to_unsigned(10, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP2_RDWRDS_MSB => std_logic_vector(to_unsigned(11, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP2_RDWRDS_LSB => std_logic_vector(to_unsigned(12, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP2_FULL       => std_logic_vector(to_unsigned(13, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP3_RDWRDS_MSB => std_logic_vector(to_unsigned(14, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP3_RDWRDS_LSB => std_logic_vector(to_unsigned(15, WB_ADDS_WIDTH)),
    READ_DP23_STS_DP3_FULL       => std_logic_vector(to_unsigned(16, WB_ADDS_WIDTH)),
    DNA_PORT_DO_READ             => std_logic_vector(to_unsigned(17, WB_ADDS_WIDTH)),
    DNA_PORT_VALUE_W0            => std_logic_vector(to_unsigned(18, WB_ADDS_WIDTH)),
    DNA_PORT_VALUE_W1            => std_logic_vector(to_unsigned(19, WB_ADDS_WIDTH)),
    DNA_PORT_VALUE_W2            => std_logic_vector(to_unsigned(20, WB_ADDS_WIDTH)),
    DNA_PORT_VALUE_W3            => std_logic_vector(to_unsigned(21, WB_ADDS_WIDTH)),
    DNA_PORT_VALUE_W4            => std_logic_vector(to_unsigned(22, WB_ADDS_WIDTH)),
    DNA_PORT_VALUE_W5            => std_logic_vector(to_unsigned(23, WB_ADDS_WIDTH)),
    NUM_REGS                     => std_logic_vector(to_unsigned(24, WB_ADDS_WIDTH)));

  -- counter reset bit mapping
  constant C_WBM_RST_bit_WRERRCNT : integer := 0;
  constant C_WBM_RST_bit_RDERRCNT : integer := 1;

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

  -- bit mapping of DNA_DO_READ
  constant C_DNA_PORT_DO_READ : integer := 0;

end package ws_master_pkg;
