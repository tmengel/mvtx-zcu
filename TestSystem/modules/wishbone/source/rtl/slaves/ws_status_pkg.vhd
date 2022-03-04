-------------------------------------------------------------------------------
-- Title      : ws_status_pkg
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : ws_status_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-08-03
-- Last update: 2019-01-29
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2017 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Description: Package for the wishbone status register
--
-- Wishbone mapping:
--
--   [0x00:0x01]-> GITHASH{LSB:MSB} : R Only
--                           [15:0] : GITHASH relative to the firmware
--   [0x02:0x04]-> DATE{LSB:CSB:MSB} : R Only
--                           [15:0] : DATE relative to the firmware
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;

package ws_status_pkg is

  constant C_DNA_PORT_SIZE : integer := 96;  -- ultrascale
  constant C_SIM_DNA_VALUE : std_logic_vector(95 downto 0) := X"76543210FEDCBA9876543210";

  -- Mapping of WB Registers
  type WB_ADD is (
    GITHASH_LSB,
    GITHASH_MSB,
    DATE_LSB,
    DATE_CSB,
    DATE_MSB,
    OS_LSB,
    DIPSWITCH_VAL,
    DNA_DO_READ,
    DNA_CHUNK_0,
    DNA_CHUNK_1,
    DNA_CHUNK_2,
    DNA_CHUNK_3,
    DNA_CHUNK_4,
    DNA_CHUNK_5,
    PUSHBUTTON_VAL
  );

  -- Register write enable
  constant C_WB_ADD_WE : t_wbs_reg_we_array(WB_ADD'pos(WB_ADD'high) downto 0) := (
    WB_ADD'pos(GITHASH_LSB)       => r,
    WB_ADD'pos(GITHASH_MSB)       => r,
    WB_ADD'pos(DATE_LSB)          => r,
    WB_ADD'pos(DATE_CSB)          => r,
    WB_ADD'pos(DATE_MSB)          => r,
    WB_ADD'pos(OS_LSB)            => r,
    WB_ADD'pos(DIPSWITCH_VAL)     => r,
    WB_ADD'pos(DNA_DO_READ)       => w,
    WB_ADD'pos(DNA_CHUNK_0)       => r,
    WB_ADD'pos(DNA_CHUNK_1)       => r,
    WB_ADD'pos(DNA_CHUNK_2)       => r,
    WB_ADD'pos(DNA_CHUNK_3)       => r,
    WB_ADD'pos(DNA_CHUNK_4)       => r,
    WB_ADD'pos(DNA_CHUNK_5)       => r,
    WB_ADD'pos(PUSHBUTTON_VAL)    => r
    );

  -- Reset value for writable registers
  constant C_WB_REG_DEFAULT : t_wbs_reg_array := (WB_ADD'pos(WB_ADD'high) downto 0 => (others => '0'));

  -----------------------------------------------------------------------------
  -- bit mapping
  -----------------------------------------------------------------------------

  -- bit mapping of DNA_DO_READ
  constant C_DNA_DO_READ_bit : integer := 0;

  -- bit mapping of GITHASH MSB, LSB
  constant C_GITHASH_range_LSB : std_logic_vector(1*WB_DATA_WIDTH-1 downto 0*WB_DATA_WIDTH) := (others => '0');
  constant C_GITHASH_range_MSB : std_logic_vector(2*WB_DATA_WIDTH-1 downto 1*WB_DATA_WIDTH) := (others => '0');

  -- bit mapping of DATE MSB, CSB, LSB
  constant C_DATE_range_LSB : std_logic_vector(1*WB_DATA_WIDTH-1 downto 0*WB_DATA_WIDTH) := (others => '0');
  constant C_DATE_range_CSB : std_logic_vector(2*WB_DATA_WIDTH-1 downto 1*WB_DATA_WIDTH) := (others => '0');
  constant C_DATE_range_MSB : std_logic_vector(3*WB_DATA_WIDTH-1 downto 2*WB_DATA_WIDTH) := (others => '0');

  -- bit mapping of the DNA_CHUNK
  constant C_DNA_CHUNK_range_0 : std_logic_vector(1*WB_DATA_WIDTH-1 downto 0*WB_DATA_WIDTH) := (others => '0');
  constant C_DNA_CHUNK_range_1 : std_logic_vector(2*WB_DATA_WIDTH-1 downto 1*WB_DATA_WIDTH) := (others => '0');
  constant C_DNA_CHUNK_range_2 : std_logic_vector(3*WB_DATA_WIDTH-1 downto 2*WB_DATA_WIDTH) := (others => '0');
  constant C_DNA_CHUNK_range_3 : std_logic_vector(4*WB_DATA_WIDTH-1 downto 3*WB_DATA_WIDTH) := (others => '0');
  constant C_DNA_CHUNK_range_4 : std_logic_vector(5*WB_DATA_WIDTH-1 downto 4*WB_DATA_WIDTH) := (others => '0');
  constant C_DNA_CHUNK_range_5 : std_logic_vector(6*WB_DATA_WIDTH-1 downto 5*WB_DATA_WIDTH) := (others => '0');

end package ws_status_pkg;
