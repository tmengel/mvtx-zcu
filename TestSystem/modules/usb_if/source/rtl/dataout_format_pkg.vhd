-------------------------------------------------------------------------------
-- Title      : dataout_format_package
-- Project    : Probeacard
-------------------------------------------------------------------------------
-- File       : dataout_format_pkg.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-04-29
-- Last update: 2017-03-14
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: receives the data from 2 input fifos and delivers them to the DP2|3
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-04-29  1.0      ML      Created
-- 2016-09-30  1.1      ML      Added flag for data 0-padded
-- 2016-10-04  1.2      ML      Changed data format to support up to 8
--                              different in ports
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package dataout_format_pkg is

  -- input fifo width
  constant c_port0_width : integer := 10;

  -- timeout
  constant ci_timeout : integer := 20;

  -- DATA formatting

  constant c_inport                 : integer := 29;
  constant c_padding_start_position : integer := 26;
  constant c_start                  : integer := 25;
  constant c_stop                   : integer := 24;

  constant c_D0_position : integer := 0;
  constant c_D1_position : integer := 1;
  constant c_D2_position : integer := 2;

  constant c_inport_size    : integer                                                        := 3;
  constant c_inport_default : std_logic_vector(c_inport + c_inport_size - 1 downto c_inport) := (others => '1');

  type t_dout_unformatted is record
    inport    : std_logic_vector(c_inport_size-1 downto 0);  -- cast from integer
    start_bit : std_logic;
    stop_bit  : std_logic;
    is_padded : std_logic_vector(2 downto 0);
    reserved  : std_logic_vector(0 downto 0);
    D0        : std_logic_vector(7 downto 0);
    D1        : std_logic_vector(7 downto 0);
    D2        : std_logic_vector(7 downto 0);
  end record t_dout_unformatted;

  function f_assign_output (
    constant r_dout : t_dout_unformatted)
    return std_logic_vector;

  function f_reset_output (
    constant s_default_value : std_logic)
    return t_dout_unformatted;

end package dataout_format_pkg;

package body dataout_format_pkg is

-- purpose: assigns the output from a record to std_logic_vector
  function f_assign_output (
    constant r_dout : t_dout_unformatted)
    return std_logic_vector is

    variable v_dataout : std_logic_vector(31 downto 0);

  begin  -- function f_assign_output
    v_dataout                                                := (others => '0');
    v_dataout(c_padding_start_position + c_D0_position)      := r_dout.is_padded(c_D0_position);
    v_dataout(c_padding_start_position + c_D1_position)      := r_dout.is_padded(c_D1_position);
    v_dataout(c_padding_start_position + c_D2_position)      := r_dout.is_padded(c_D2_position);
    v_dataout(c_start)                                       := r_dout.start_bit;
    v_dataout(c_stop)                                        := r_dout.stop_bit;
    v_dataout(c_D0_position*8 + 8 -1 downto c_D0_position*8) := r_dout.D0;
    v_dataout(c_D1_position*8 + 8 -1 downto c_D1_position*8) := r_dout.D1;
    v_dataout(c_D2_position*8 + 8 -1 downto c_D2_position*8) := r_dout.D2;
    v_dataout(c_inport_default'range)                        := r_dout.inport;
    return v_dataout;
  end function f_assign_output;

  -- purpose: resets the record to a known value by setting all the bits to the input value of the function
  function f_reset_output (
    constant s_default_value : std_logic)
    return t_dout_unformatted is

    variable vr_dout : t_dout_unformatted;

  begin  -- function f_reset_output
    vr_dout.is_padded := (others => not(s_default_value));
    vr_dout.inport    := (others => not(s_default_value));
    vr_dout.start_bit := s_default_value;
    vr_dout.stop_bit  := s_default_value;
    vr_dout.reserved  := (others => s_default_value);
    vr_dout.D0        := (others => s_default_value);
    vr_dout.D1        := (others => s_default_value);
    vr_dout.D2        := (others => s_default_value);
    return vr_dout;
  end function f_reset_output;

end package body dataout_format_pkg;
