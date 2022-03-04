-------------------------------------------------------------------------------
-- Title      : wishbone slave example, status registers
-- Project    : Probeacard
-------------------------------------------------------------------------------
-- File       : ws_status_reg.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-02-25
-- Last update: 2017-09-28
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave used to read values from different blocks.
--              Reset of REG external!
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author  Description
-- 2016-02-25  2.0      ML      Imported from ws_trigger_reg.vhd
-- 2016-02-26           ML      created status slave which receives configuration
--                              values from the blocks and make them available
--                              to the wishbone (and usb)
-- 2016-02-29  2.1      ML      Modified input which is now a record of records,
--                              each one of them coming from a different block
--                              and then mapped to sRegister and eventually mapped.
--                              TODO: move the padding and unwrapping of the
--                              record into the memory package having only one
--                              function assigning sRegister properly using the
--                              info inside the memory mapping (to be discuss
--                              with GAR)
-- 2015-03-01   2.2     ML      Now assignment from extenal bus to internal
--                              sRegister is done using the
--                              proc_ws_sts_wrfrombus defined in the
--                              wishbone_MM package
-------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.wishbone_MM.all;

--=================================================================================================--
--#######################################   Entity   ##############################################--
--=================================================================================================--

entity ws_status_reg is
  port (
    -- Wishbone interface signals
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  wbs_i_type;
    WB_WBS_O : out wbs_o_type;
    STS_BUS  : in  t_sts_bus
    );
end ws_status_reg;

--=================================================================================================--
--####################################   Architecture   ###########################################--
--=================================================================================================--

architecture structural of ws_status_reg is

  --================================ Signal Declarations ================================--
  --========================--
  -- Wishbone bus registers --
  --========================--
  signal sRegisters     : std_logic_vector(((WS_STS_NUM)*WB_DATA_WIDTH)-1 downto 0);
  signal sValidAddr     : std_logic;
  signal iWbAddr        : integer range 0 to 255;
  signal sWbAck, sWbErr : std_logic := '0';
  signal sWbWrite       : std_logic;

  --=====================================================================================--

--=======================================================================================--
begin  --========####   Architecture Body   ####========--
--=======================================================================================--

  p_wr2bus: process (STS_BUS) is
  begin  -- process p_wr2bus
    proc_ws_sts_wrfrombus(sRegisters,STS_BUS);
  end process p_wr2bus;

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
        sWbErr <= (WB_WBS_I.stb_i and WB_WBS_I.cyc_i and (not sValidAddr) and (not sWbErr)) or (WB_WBS_I.stb_i and WB_WBS_I.cyc_i and (sWbWrite) and (not sWbErr));
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
    if iWbAddr < WS_STS_NUM then
      sValidAddr     <= '1';
      WB_WBS_O.dat_o <= sRegisters(iWbAddr*WB_DATA_WIDTH+(WB_DATA_WIDTH-1) downto iWbAddr*WB_DATA_WIDTH);
    else
      sValidAddr     <= '0';
      WB_WBS_O.dat_o <= (others => '0');
    end if;
  end process procRegRead;

--=====================================================================================--
end structural;
