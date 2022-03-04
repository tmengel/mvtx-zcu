-------------------------------------------------------------------------------
-- Title      : CAN High Level Protocol (HLP)
-- Project    : CAN Bus DCS for ITS Readout Unit
-------------------------------------------------------------------------------
-- File       : can_hlp_glue_pkg.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    :
-- Created    : 2018-04-03
-- Last update: 2018-06-20
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Package with definitions used in can_hlp.vhd
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-04-03  1.0      simon	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package can_hlp_pkg is

  constant C_CAN_BROADCAST_ID : std_logic_vector(7 downto 0) := x"7F";

  -- CAN HLP command types
  constant C_DATA           : std_logic_vector(2 downto 0) := "001";
  constant C_WRITE_COMMAND  : std_logic_vector(2 downto 0) := "010";
  constant C_WRITE_RESPONSE : std_logic_vector(2 downto 0) := "011";
  constant C_READ_COMMAND   : std_logic_vector(2 downto 0) := "100";
  constant C_READ_RESPONSE  : std_logic_vector(2 downto 0) := "101";
  constant C_STATUS_ALERT   : std_logic_vector(2 downto 0) := "111";

  constant C_READ_COMMAND_LEN   : std_logic_vector(3 downto 0) := x"2";
  constant C_WRITE_COMMAND_LEN  : std_logic_vector(3 downto 0) := x"4";
  constant C_READ_RESPONSE_LEN  : std_logic_vector(3 downto 0) := x"4";
  constant C_WRITE_RESPONSE_LEN : std_logic_vector(3 downto 0) := x"4";

end can_hlp_pkg;
