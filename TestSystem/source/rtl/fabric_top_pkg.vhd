-------------------------------------------------------------------------------
-- Title      : fabric_top_pkg
-- Project    : RUv1_Test
-------------------------------------------------------------------------------
-- File       : fabric_top_pkg
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-02-07
-- Last update: 2019-01-03
-- Platform   : Xilinx Vivado 2017.4
-- Target     : Kintex-Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author  Description
-- 2017-02-07  1.0      ML      Created
-- 2018-03-23  1.1      ML      Configurable number of masters
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;

package fabric_top_pkg is

  -- SEU mitigation and monitor
  constant C_MISMATCH_EN                  : integer := 1;
  constant C_MISMATCH_REGISTERED          : integer := 0;
  constant C_SEE_MITIGATION_TECHNIQUE     : integer := 1;  -- TMR with signle voter
  constant C_SEE_MITIGATION_TECHNIQUE_DWC : integer := 0;  -- DWC disable
  constant C_SEE_MITIGATION_TECHNIQUE_FSM : integer := 3;  -- TMR with triple voter
  constant C_ADDITIONAL_MISMATCH          : integer := 1;

  -- board parameters
  constant C_TRANSCEIVER_NUMBER   : natural := 9;
  constant C_DISABLE_ILA_CORE_STR : string  := "FALSE";
  constant C_ENABLE_ILA_CORE_STR  : string  := "TRUE";
  constant C_ALPIDE_GPIO_NUMBER   : natural := 0;

  -- DCTRLS/DCLK constants and types: it provide information on the board
  -- layout (differs from the PCv3)
  constant N_DCTRL : natural := 5;

  -----------------------------------------------------------------------------
  -- Board specific wishbone constants
  -----------------------------------------------------------------------------

  constant WB_SLAVE_NUMBER  : natural := 10;
  constant WB_MASTER_NUMBER : natural := 2;

  -------------------------------------------
  -- ADDBs: block address on the wishbone bus
  -------------------------------------------
  type t_WB_ADDB is record
    MASTER     : natural;               -- usb_if/master
    STATUS     : natural;
    I2CGBT     : natural;
    FW_WAIT    : natural;
    USB_IF     : natural;
    MGT_TEST   : natural;
    DRP_CTRL   : natural;
    LOOPBACK   : natural;
    MASTER_CAN : natural;
    SLAVE_CAN  : natural;
  end record;

  constant WB_ADDB : t_WB_ADDB := (
    MASTER     => 00,
    STATUS     => 01,
    I2CGBT     => 02,
    FW_WAIT    => 03,
    USB_IF     => 04,
    MGT_TEST   => 05,
    DRP_CTRL   => 06,
    LOOPBACK   => 07,
    MASTER_CAN => 08,
    SLAVE_CAN  => 09
    );

  -------------------------------------------
  -- ADDMs: master address on the wishbone bus
  -------------------------------------------
  type t_WB_ADDM is record
    MASTER_USB : natural;
    MASTER_CAN : natural;
  end record;

  constant WB_ADDM : t_WB_ADDM := (
    MASTER_USB => 00,
    MASTER_CAN => 01
    );


  -----------------------------------------------------------------------------
  -- SCA GPIO mapping
  -----------------------------------------------------------------------------

  constant C_SCA_GPIO_RESET : integer := 0;

end package fabric_top_pkg;
