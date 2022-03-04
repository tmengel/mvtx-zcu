-- $Id$
-------------------------------------------------------------------------------
-- Title      : wishbone slave example
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : wishbone_slave.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2015-10-09
-- Last update: 2017-03-13
-- Platform   : Xilinx Vivado 2015.2
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave used to write and read values
--###############################################################################
--
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author  Description
-- 2016-01-28  1.0      ML      Imported
-- 2016-01-28                   removed gbt libraries
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;

--=================================================================================================--
--#######################################   Entity   ##############################################--
--=================================================================================================--

entity wb_slave_test is
  generic (
    CONFIG_REG_DEFAULT : std_logic_vector(10*16-1 downto 0) := (others => '0')
    );
  port (
    -- Wishbone interface signals
    WB_CLK         : in  std_logic;
    WB_RST         : in  std_logic;
    WB_WBS_I       : in  wbs_i_type;
    WB_WBS_O       : out wbs_o_type
    );
end wb_slave_test;

--=================================================================================================--
--####################################   Architecture   ###########################################--
--=================================================================================================--

architecture structural of wb_slave_test is

  --================================ Signal Declarations ================================--
  --========================--
  -- Wishbone bus registers --
  --========================--
  signal sRegisters : std_logic_vector(10*16-1 downto 0);
  signal sValidAddr : std_logic;
  signal iWbAddr    : integer range 0 to 255;
  signal sWbAck, sWbErr           : std_logic;
  signal sWbWrite                 : std_logic;


  --=====================================================================================--

--=======================================================================================--
begin  --========####   Architecture Body   ####========--
--=======================================================================================--

  --==================================== Wishbone bus logic =============================--
  -- generate acknowledge and error signals
  genAckErr : process (WB_CLK, WB_RST) is
  begin  -- process genAckErr
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then              -- synchronous reset (active high)
        sWbAck <= '0';
        sWbErr <= '0';
      else
        sWbAck <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and sValidAddr and (not sWbAck);
        sWbErr <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and (not sValidAddr) and (not sWbErr);
      end if;
    end if;
  end process genAckErr;

  WB_WBS_O.ack_o <= sWbAck;
  WB_WBS_O.err_o <= sWbErr;

  -- generate wishbone write signal
  sWbWrite <= sWbAck and WB_WBS_I.we_i;

  -- Wishbone Read and Address Decode (asynchronous)
  iWbAddr <= to_integer(unsigned(WB_WBS_I.addr_i));
  procRegRead : process (sRegisters, iWbAddr) is
  begin
    if iWbAddr < 10 then
      sValidAddr     <= '1';
      WB_WBS_O.dat_o <= sRegisters(iWbAddr*16+15 downto iWbAddr*16);
    else
      sValidAddr     <= '0';
      WB_WBS_O.dat_o <= x"DEAD";
    end if;
  end process procRegRead;

  -- Wishbone Write
  procRegWrite : process (WB_CLK, WB_RST) is
  begin
    if rising_edge(WB_CLK) then         -- rising clock edge
      if WB_RST = '1' then              -- synchronous reset (active high)
        sRegisters <= CONFIG_REG_DEFAULT;
      else
         if (sValidAddr = '1' ) and (sWbWrite = '1') then
          sRegisters(iWbAddr*16+15 downto iWbAddr*16) <= WB_WBS_I.dat_i;
          end if;
      end if;
    end if;
  end process procRegWrite;


--=====================================================================================--
end structural;
