-------------------------------------------------------------------------------
-- Title      : wishbone slave example, cfg registers
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : ws_cfg_reg.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-02-25
-- Last update: 2017-03-13
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave used to write and read values
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Mach     Author  Description
-- 2016-02-25  2.0      ML      Imported from ws_trigger_reg.vhd
-- 2016-02-26           ML      created cnfg slave which receives configuration
--                              values from wishbone (and usb) and forward them
--                              to the relative registers into the memory
-- 2016-02-29  2.1      ML      Modified REG output replacing it with a record
--                              of records which is mapped in the memory mapping
-- 2016-03-01           ML      Renamed to ws_cfg_reg (CNFG -> CFG)
-- 2016-04-06           ML MB   Imported from Probecard fw and adapted to be
--                              used on RUv0a
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

entity ws_cfg_reg is
  generic (
    CONFIG_REG_DEFAULT : t_sRegister_ws_cfg := (others => '0') --std_logic_vector(((WS_CFG_NUM)*WB_DATA_WIDTH)-1 downto 0) := (others => '0')
    );
  port (
    -- Wishbone interface signals
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  wbs_i_type;
    WB_WBS_O : out wbs_o_type;
    CFG_BUS : out t_cfg_bus
    );
end ws_cfg_reg;

--=================================================================================================--
--####################################   Architecture   ###########################################--
--=================================================================================================--

architecture structural of ws_cfg_reg is

  --================================ Signal Declarations ================================--
  --========================--
  -- Wishbone bus registers --
  --========================--
  signal sRegisters     : t_sRegister_ws_cfg;  --std_logic_vector(((WS_CFG_NUM)*WB_DATA_WIDTH)-1 downto 0);
  signal sValidAddr     : std_logic;
  signal iWbAddr        : integer range 0 to (((WS_CFG_NUM)*WB_DATA_WIDTH)-1);
  signal sWbAck, sWbErr : std_logic := '0';
  signal sWbWrite       : std_logic;

  --=====================================================================================--

--=======================================================================================--
begin  --========####   Architecture Body   ####========--
--=======================================================================================--

  -- purpose: assigns the sRegisters to the output bus. The procedure used in the process is defined in the wishbone_MM.vhd file located in rtl/wishbone/.
  p_assign_output: process (sRegisters) is
  begin  -- process p_assign_output
    proc_ws_cfg_wr2bus(sRegisters, CFG_BUS);
  end process p_assign_output;

  --==================================== Wishbone bus logic =============================--
  -- generate acknowledge and error signals
  genAckErr : process (WB_CLK) is
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
    if iWbAddr < WS_CFG_NUM then
      sValidAddr     <= '1';
      WB_WBS_O.dat_o <= sRegisters(iWbAddr*WB_DATA_WIDTH+(WB_DATA_WIDTH-1) downto iWbAddr*WB_DATA_WIDTH);
    else
      sValidAddr     <= '0';
      WB_WBS_O.dat_o <= (others => '0');
    end if;
  end process procRegRead;


  -- Wishbone Write
  procRegWrite : process (WB_CLK) is
  begin
    if rising_edge(WB_CLK) then         -- rising clock edge
      if WB_RST = '1' then              -- synchronous reset (active high)
        sRegisters <= CONFIG_REG_DEFAULT;
      else
        if (sValidAddr = '1') and (sWbWrite = '1') then
          sRegisters(iWbAddr*WB_DATA_WIDTH+(WB_DATA_WIDTH-1) downto iWbAddr*WB_DATA_WIDTH) <= WB_WBS_I.dat_i;
        end if;

      end if;
    end if;
  end process procRegWrite;

--=====================================================================================--
end structural;
