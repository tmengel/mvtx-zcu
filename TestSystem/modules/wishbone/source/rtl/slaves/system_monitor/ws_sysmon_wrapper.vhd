-------------------------------------------------------------------------------
-- Title      : Xilinx System Monitor (SYSMON) Wrapper
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : wishbone_drp_bridge.vhd
-- Author     : Emanuele Canessa <e.canessa@cern.ch>
-- Company    : CERN / Politecnico di Torino
-- Created    : 2017-10-13
-- Last update: 2017-10-23
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Xilinx System Monitor wrapper.
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Rev  Author  Description
-- 2017-10-13  1.0  EC      Initial relase
-- 2017-10-13  1.1  EC      Added DRP package
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library WORK;
use WORK.drp_pkg.all;

entity sysmon_wrapper is
  port (
    SMON_RST  : in    std_logic;
    DRP_DCLK  : in    std_logic;
    DRP_MOSI  : in    drp_mosi_type;
    DRP_MISO  : out   drp_miso_type
  );
end entity; -- sysmon_wrapper

architecture structural of sysmon_wrapper is

  component system_management_wiz_0
    port (
      di_in                  : in    std_logic_vector (15 downto 0);
      daddr_in               : in    std_logic_vector ( 7 downto 0);
      den_in                 : in    std_logic;
      dwe_in                 : in    std_logic;
      drdy_out               : out   std_logic;
      do_out                 : out   std_logic_vector (15 downto 0);
      dclk_in                : in    std_logic;
      reset_in               : in    std_logic;
      user_supply0_alarm_out : out   std_logic;
      user_supply1_alarm_out : out   std_logic;
      ot_out                 : out   std_logic;
      channel_out            : out   std_logic_vector ( 5 downto 0);
      eoc_out                : out   std_logic;
      alarm_out              : out   std_logic;
      eos_out                : out   std_logic;
      busy_out               : out   std_logic
    );
  end component;

begin

  SYSMONE1_inst : system_management_wiz_0
    port map (
      di_in                  => DRP_MOSI.di,
      daddr_in               => DRP_MOSI.addr,
      den_in                 => DRP_MOSI.den,
      dwe_in                 => DRP_MOSI.dwe,
      drdy_out               => DRP_MISO.drdy,
      do_out                 => DRP_MISO.do,
      dclk_in                => DRP_DCLK,
      reset_in               => SMON_RST,
      user_supply0_alarm_out => open,
      user_supply1_alarm_out => open,
      ot_out                 => open,
      channel_out            => open,
      eoc_out                => open,
      alarm_out              => open,
      eos_out                => open,
      busy_out               => open
    );

end architecture; -- structural
