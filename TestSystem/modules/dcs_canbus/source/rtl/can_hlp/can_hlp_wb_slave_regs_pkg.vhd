-------------------------------------------------------------------------------
-- Title      : CAN DCS HLP Wishbone Slave Registers
-- Project    : ITS RU FPGA
-------------------------------------------------------------------------------
-- File       : can_hlp_wb_slave_regs_pkg.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    : Western Norway University of Applied Sciences
-- Created    : 2018-04-11
-- Last update: 2018-11-20
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave for CAN bus DCS HLP registers. Based on
--              implementation in ws_usb_if.vhd by Matteo Lupi
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-04-11  1.0      simon	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;

package can_hlp_wb_slave_regs_pkg is

  -- Mapping of WB Registers
  type t_WB_ADDS is record
    CAN_REG_RX_MSG_COUNT       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CAN_REG_TX_MSG_COUNT       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CAN_REG_READ_COUNT         : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CAN_REG_WRITE_COUNT        : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CAN_REG_STATUS_ALERT_COUNT : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CAN_REG_UNKNOWN_COUNT      : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CAN_REG_TEST               : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    CAN_REG_CLK_PRESCALE       : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    NUM_REGS                   : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  end record;

  constant WB_ADD : t_WB_ADDS := (
    CAN_REG_RX_MSG_COUNT       => x"00",
    CAN_REG_TX_MSG_COUNT       => x"01",
    CAN_REG_READ_COUNT         => x"02",
    CAN_REG_WRITE_COUNT        => x"03",
    CAN_REG_STATUS_ALERT_COUNT => x"04",
    CAN_REG_UNKNOWN_COUNT      => x"05",
    CAN_REG_TEST               => x"06",
    CAN_REG_CLK_PRESCALE       => x"07",
    NUM_REGS                   => x"08");

end package can_hlp_wb_slave_regs_pkg;
