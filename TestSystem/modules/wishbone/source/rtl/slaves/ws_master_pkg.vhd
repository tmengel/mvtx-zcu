-------------------------------------------------------------------------------
-- Title      : ws_master_pkg
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : ws_master_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-07-06
-- Last update: 2017-11-03
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Wishbone mapping:
--
--   0x00 -> READ_WBM_WRERRCNTR      : R Only
--                           [15:0]  : Reads the value of the wisbone master
--                                     write error counter
--   0x01 -> READ_WBM_RDERRCNTR      : R Only
--                           [15:0]  : Reads the value of the wisbone master
--                                     read error counter
--   0x02 -> READ_WBM_SEEERRCNTR     : R Only
--                           [15:0]  : Reads the value of the wisbone master
--                                     see error counter
--   0x03 -> RST_WBM_CNTRS           : W only
--                           Bit 0   : Resets the WR counter (pulse)
--                           Bit 1   : Resets the RD counter (pulse)
--                           Bit 2   : Resets the SEE counter (pulse)
--   0x04 -> MISMATCH                : R Only
--                           [5:0]   : Reads the value of the mismatch value
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;

package ws_master_pkg is

  -- wishbone master mismatch width
  constant C_WBMSTR_MISMATCH_WIDTH : integer := 7;

  -- Mapping of WB Registers
  type t_WB_ADDS is record
    READ_WBM_WRERRCNTR  : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_WBM_RDERRCNTR  : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    READ_WBM_SEEERRCNTR : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    RST_WBM_CNTR        : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MISMATCH            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    NUM_REGS            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  end record;

  constant WB_ADD : t_WB_ADDS := (
    READ_WBM_WRERRCNTR           => x"00",
    READ_WBM_RDERRCNTR           => x"01",
    READ_WBM_SEEERRCNTR          => x"02",
    RST_WBM_CNTR                 => x"03",
    MISMATCH                     => x"04",
    NUM_REGS                     => x"05");

  -- counter reset bit mapping
  constant C_WBM_RST_bit_WRERRCNT  : integer := 0;
  constant C_WBM_RST_bit_RDERRCNT  : integer := 1;
  constant C_WBM_RST_bit_SEEERRCNT : integer := 2;

end package ws_master_pkg;
