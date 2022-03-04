-------------------------------------------------------------------------------
-- Title      : upcounter
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : upcounter.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-04-28
-- Last update: 2017-09-27
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: simple parametric upounter with enable
--
-- NOTE: despite the architecture might look a little bit convoluted, it is
--       required to achieve minimum amount of overhead of renaming all the
--       instances.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-05-11  1.0      ML      Created
-- 2016-07-06  1.1      ML      Modified generic IS_SATURATING and VERBOSE to be
--                              std_logic to have compatibility with v and sv
-- 2017-08-02  1.2      ML      Updated to upcounter/upcounter_core architecture
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity upcounter is
  generic (
    BIT_WIDTH     : integer := 16;
    IS_SATURATING : integer := 0;
    VERBOSE       : integer := 1);
  port (
    -- Frontend Interface
    CLK     : in std_logic;             -- Clock
    RST     : in std_logic;             -- global fpga reset
    RST_CNT : in std_logic;             -- counter reset signal
    CNT_UP  : in std_logic;             -- count up

    CNT_VALUE : out std_logic_vector(BIT_WIDTH-1 downto 0));

end entity upcounter;

architecture arch of upcounter is

  constant C_NO_MITIGATION    : integer   := 0;
  constant C_MISMATCH_DISABLE : integer := 0;

begin  -- architecture arch

  INST_upcounter_tmr_wrapper : entity work.upcounter_tmr_wrapper
    generic map (
      BIT_WIDTH                  => BIT_WIDTH,
      IS_SATURATING              => IS_SATURATING,
      VERBOSE                    => VERBOSE,
      G_SEE_MITIGATION_TECHNIQUE => C_NO_MITIGATION,
      G_MISMATCH_EN              => C_MISMATCH_DISABLE)
    port map (
      CLK       => CLK,
      RST       => RST,
      RST_CNT   => RST_CNT,
      CNT_UP    => CNT_UP,
      CNT_VALUE => CNT_VALUE,
      MISMATCH  => open);

end architecture arch;
