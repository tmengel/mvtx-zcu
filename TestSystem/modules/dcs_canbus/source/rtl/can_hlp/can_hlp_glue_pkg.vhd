-------------------------------------------------------------------------------
-- Title      : CAN High Level Protocol (HLP)
-- Project    : CAN Bus DCS for ITS Readout Unit
-------------------------------------------------------------------------------
-- File       : can_hlp_glue_pkg.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    :
-- Created    : 2018-04-03
-- Last update: 2019-01-03
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Package with definitions used in can_hlp_glue.vhd
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-04-03  1.0      simon	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package can_hlp_glue_pkg is

  type can_buffer_t is array (0 to 7) of std_logic_vector(7 downto 0);

  constant C_CAN_CR_RESET_MODE_VAL : std_logic_vector(7 downto 0) := x"01";
  -- Default acceptance code value. Not really used, because the AMR value
  -- accepts all acceptance codes
  constant C_CAN_ACR_RESET_VAL : std_logic_vector(7 downto 0) := x"FF";

  -- Default acceptance mask value. Ignore all bits of ACR (don't filter anything)
  constant C_CAN_AMR_RESET_VAL : std_logic_vector(7 downto 0) := x"FF";

  -- 2x baud rate prescale, gives 80 MHz clock at 160 MHz
  -- This clock is divided into 10 timing segments,
  -- which gives a bit rate of 8 Mbit
  -- constant C_CAN_BTR0_RESET_VAL : std_logic_vector(7 downto 0) := x"00";

  -- 16x baud rate prescale, gives 10 MHz clock at 160 MHz
  -- This clock is divided into 10 timing segments,
  -- which gives a bit rate of 1 Mbit
  -- constant C_CAN_BTR0_RESET_VAL : std_logic_vector(7 downto 0) := x"07";

  -- 32x baud rate prescale, gives 5 MHz clock at 160 MHz
  -- This clock is divided into 10 timing segments,
  -- which gives a bit rate of 500 kbit
  -- constant C_CAN_BTR0_RESET_VAL : std_logic_vector(7 downto 0) := x"0F";

  -- 64x baud rate prescale, gives 2.5 MHz clock at 160 MHz
  -- This clock is divided into 10 timing segments,
  -- which gives a bit rate of 250 kbit
  -- constant C_CAN_BTR0_RESET_VAL : std_logic_vector(7 downto 0) := x"1F";

  -- 30x baud rate prescale, gives 2.5 MHz clock at 75 MHz
  -- This clock is divided into 10 timing segments,
  -- which gives a bit rate of 250 kbit
  constant C_CAN_BTR0_RESET_VAL : std_logic_vector(7 downto 0) := x"0E";

  constant C_CAN_BTR1_RESET_VAL : std_logic_vector(7 downto 0) := x"25";
  constant C_CAN_CR_OPERATION_VAL : std_logic_vector(7 downto 0) := "00111110";
  constant C_CAN_CMR_XMIT_REQUEST_VAL : std_logic_vector(7 downto 0) := x"01";
  constant C_CAN_CMR_RELEASE_RECV_BUFF_VAL : std_logic_vector(7 downto 0) := "00000100";

  constant C_CAN_RX_IRQ_BIT : natural := 0;
  constant C_CAN_TX_IRQ_BIT : natural := 1;
  constant C_CAN_ERROR_IRQ_BIT : natural := 2;
  constant C_CAN_DATA_OVERRUN_IRQ_BIT : natural := 3;
  constant C_CAN_WAKEUP_IRQ_BIT : natural := 4;

end can_hlp_glue_pkg;
