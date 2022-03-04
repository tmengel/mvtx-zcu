-------------------------------------------------------------------------------
-- Title      : Xilinx System Monitor (SYSMON) Top Module
-- Project    : RUv1
-------------------------------------------------------------------------------
-- File       : wishbone_drp_bridge.vhd
-- Author     : Emanuele Canessa <e.canessa@cern.ch>
-- Company    : CERN / Politecnico di Torino
-- Created    : 2017-10-13
-- Last update: 2017-10-22
-- Platform   : Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Xilinx System Monitor Wisbone slave.
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
use WORK.intercon_pkg.all;
use WORK.drp_pkg.all;

entity sysmon_top is
  generic (
    MISMATCH_EN           : integer := 1;
    G_MISMATCH_REGISTERED : integer := 0;
    G_ADDITIONAL_MISMATCH : integer := 1
  );
  port (
    -- SYSMON Ports
    SMON_RST     : in    std_logic;
    -- Wishbone Ports
    WB_CLK       : in    std_logic;
    WB_RST       : in    std_logic;
    WB_WBS_I     : in    t_wbs_i_array;
    WB_WBS_O     : out   t_wbs_o_array;
    -- Mismatch Ports
    MISMATCH     : out   std_logic_vector(C_DRP_MISMATCH_WIDTH-1 downto 0);
    MISMATCH_2ND : out   std_logic_vector(C_DRP_MISMATCH_WIDTH-1 downto 0)
  );
end entity; -- sysmon_top

architecture structural of sysmon_top is

  signal sDrpDclk  : std_logic;
  signal sDrpMosi  : drp_mosi_type;
  signal sDrpMiso  : drp_miso_type;

begin

  WB_BRIDGE_inst : entity work.wishbone_drp_bridge_tmr_wrapper
    generic map (
      MISMATCH_EN           => MISMATCH_EN,
      G_ADDITIONAL_MISMATCH => G_ADDITIONAL_MISMATCH,
      G_MISMATCH_REGISTERED => G_MISMATCH_REGISTERED
    )
    port map (
      WB_CLK                => WB_CLK,
      WB_RST                => WB_RST,
      WB_WBS_I              => WB_WBS_I,
      WB_WBS_O              => WB_WBS_O,
      DRP_DCLK              => sDrpDclk,
      DRP_MOSI              => sDrpMosi,
      DRP_MISO              => sDrpMiso,
      MISMATCH              => MISMATCH(0),
      MISMATCH_2ND          => MISMATCH_2ND(0)
    );

  SYSMON_inst : entity work.sysmon_wrapper
    port map (
      SMON_RST  => SMON_RST,
      DRP_DCLK  => sDrpDclk,
      DRP_MOSI  => sDrpMosi,
      DRP_MISO  => sDrpMiso
    );

end architecture; -- structural

