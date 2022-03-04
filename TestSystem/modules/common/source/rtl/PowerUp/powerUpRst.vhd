-- $Id$
-------------------------------------------------------------------------------
-- Title      : Power Up Reset Generator
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : powerUpRst.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2015-08-24
-- Last update: 2017-02-24
-- Platform   : Xilinx Vivado 2015.2
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Generates an active high signal 16 clocks long which can be
--              used as a global power up reset
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2015-05-12           ML      added 40 MHz reset
-- 2015-05-20           ML      added 120 MHz reset
-- 2016-11-03           MB      imported from probecard, Tag Release_230816_1156_f71ea04
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity powerUpRst is
  port (
    -- User Clock inputs
    CLK        : in  std_logic;         -- clock input
    CLK_LOCKED : in  std_logic;         -- clock is stable
    RST160     : out std_logic;         -- active high reset
    CLK40      : in  std_logic;         -- clock 40 MHz input
    RST40      : out std_logic;         -- 40 MHz synchronous reset
    CLK120     : in  std_logic;         -- clock 120 MHz input
    RST120     : out std_logic;         -- 120 MHz synchronous reset
    CLK80      : in  std_logic;         -- clock 80 MHz input
    RST80      : out std_logic          -- 80 MHz synchronous reset
    );
end entity powerUpRst;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture RTL of powerUpRst is
begin

  -- use a 16bit shift register look-up table to generate a pulse that is
  -- logic-high for 16 clocks and then goes low
  -- the 4 "Ax" inputs determine the size of the shift register (= 16 bits)
  INST_SRL16E_16b : SRL16E
    generic map (
      INIT => X"FFFF"                   -- initialization value
      )
    port map (
      Q   => RST160,                       -- SRL data output
      A0  => '1',                       -- Select[0] input
      A1  => '1',                       -- Select[1] input
      A2  => '1',                       -- Select[2] input
      A3  => '1',                       -- Select[3] input
      CE  => CLK_LOCKED,                -- Clock enable input
      CLK => CLK,                       -- Clock input
      D   => '0'                        -- SRL data input
      );

  -- use a 16bit shift register look-up table to generate a pulse that is
  -- logic-high for 4 clocks and then goes low
  -- the 4 "Ax" inputs determine the size of the shift register (= 4 bits)
  -- Note: if A3:A0 is x then the high time is x+1 [x"0" -> 1 clock cycle, x"F"
  -- -> 16 clock cycles]
  INST_SRL16E_4b : SRL16E
    generic map (
      INIT => X"FFFF"                   -- initialization value
      )
    port map (
      Q   => RST40,                     -- SRL data output
      A0  => '1',                       -- Select[0] input
      A1  => '1',                       -- Select[1] input
      A2  => '0',                       -- Select[2] input
      A3  => '0',                       -- Select[3] input
      CE  => CLK_LOCKED,                -- Clock enable input
      CLK => CLK40,                     -- Clock input
      D   => '0'                        -- SRL data input
      );

  -- use a 16bit shift register look-up table to generate a pulse that is
  -- logic-high for 12 clocks and then goes low
  -- the 4 "Ax" inputs determine the size of the shift register (= 16 bits)
  INST_SRL16E_12b : SRL16E
    generic map (
      INIT => X"FFFF"                   -- initialization value
      )
    port map (
      Q   => RST120,                    -- SRL data output
      A0  => '1',                       -- Select[0] input
      A1  => '1',                       -- Select[1] input
      A2  => '0',                       -- Select[2] input
      A3  => '1',                       -- Select[3] input
      CE  => CLK_LOCKED,                -- Clock enable input
      CLK => CLK120,                    -- Clock input
      D   => '0'                        -- SRL data input
      );

  -- use a 16bit shift register look-up table to generate a pulse that is
  -- logic-high for 8 clocks and then goes low
  -- the 4 "Ax" inputs determine the size of the shift register (= 16 bits)
  INST_SRL16E_8b : SRL16E
    generic map (
      INIT => X"FFFF"                   -- initialization value
      )
    port map (
      Q   => RST80,                     -- SRL data output
      A0  => '1',                       -- Select[0] input
      A1  => '1',                       -- Select[1] input
      A2  => '1',                       -- Select[2] input
      A3  => '0',                       -- Select[3] input
      CE  => CLK_LOCKED,                -- Clock enable input
      CLK => CLK80,                     -- Clock input
      D   => '0'                        -- SRL data input
      );

end architecture RTL;
