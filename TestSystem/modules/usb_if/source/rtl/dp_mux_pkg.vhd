-------------------------------------------------------------------------------
-- Title      : dp mux package
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : dp_mux_pkg.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-10-04
-- Last update: 2017-03-13
-- Platform   : Vivado 2015.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: datapoint mux
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author     Description
-- 2016-01-28  1.0      mlupi      created
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

use work.intercon_pkg.all;

package dp_mux_pkg is

  constant C_FIFOWIDTH : integer := 32;

  type t_fifo_wrif_tofifo is record  -- data going towards the write interface of the fifo
    DT : std_logic_vector(C_FIFOWIDTH -1 downto 0);
    WR : std_logic;
  end record t_fifo_wrif_tofifo;

  type t_fifo_wrif_fromfifo is record  -- data coming from the wr interface of the fifo
    FULL  : std_logic;
    AFULL : std_logic;
    EPTY  : std_logic;
    AEPTY : std_logic;
    DONE  : std_logic;
    RX_EN : std_logic;
  end record t_fifo_wrif_fromfifo;

  -- defaults

  constant C_FIFO_WRIF_TOFIFO_DEFAULT : t_fifo_wrif_tofifo := (DT => (others => '0'),
                                                               WR => '0'
                                                               );

  constant C_FIFO_WRIF_FROMFIFO_DEFAULT : t_fifo_wrif_fromfifo := (FULL  => '1',
                                                                   AFULL => '1',
                                                                   EPTY  => '0',
                                                                   AEPTY => '0',
                                                                   DONE  => '0',
                                                                   RX_EN => '0');

  -- arrays

  type t_fifo_wrif_tofifo_array is array(integer range <>) of t_fifo_wrif_tofifo;

  type t_fifo_wrif_fromfifo_array is array(integer range <>) of t_fifo_wrif_fromfifo;

end dp_mux_pkg;

package body dp_mux_pkg is

end dp_mux_pkg;
