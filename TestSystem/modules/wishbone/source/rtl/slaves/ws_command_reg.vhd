-------------------------------------------------------------------------------
-- Title      : wishbone slave example, command registers
-- Project    : Probeacard
-------------------------------------------------------------------------------
-- File       : ws_command_reg.vhd
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
-- 2016-02-25  2.0      ML      Imported from wishbone_slave.vhd from Joe
-- 2016-02-25           ML      Parametrized bus
-- 2016-02-25           ML      created trigger slave which, when a bit is written
--                              [bit (address <= (ws_addr_i)],
--                              then then in two clock cycles the trigger is
--                              sent (1) to the block and then set back to 0
-- 2016-02-26           ML      Address space set to 256 (2**WB_ADDRS_WIDTH),
--                              could be expanded to 2**(WB_ADDRS_WIDTH*WB_DATA_WIDTH)
-- 2016-02-29  2.1      ML      Changed paradima of working, now the trigger
--                              are asserted as a 16 bit wide vector (dat_i)
--                              a dedicated process is then interpreting the
--                              command and sending it to the relative logic.
--                              The last written value is not readable on the
--                              wishbone, since it is reset at the next clk_cycle
-- 2016-03-01           ML      Replaced Trigger with command
-- 2016-03-01   2.2     ML      Following GAR guidelines now last issued
--                              command on each register is readable.
--                              Assignemnt of values to output is done using
--                              procedure defined in wishbone_MM package
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

entity ws_command_reg is
  generic (
    CONFIG_REG_DEFAULT : t_sRegister_ws_cmd --std_logic_vector(WS_CMD_NUM*WB_DATA_WIDTH-1 downto 0) := (others => '0')
    );
  port (
    -- Wishbone interface signals
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  wbs_i_type;
    WB_WBS_O : out wbs_o_type;
    CMD_BUS  : out t_cmd_bus
    );
end ws_command_reg;

--=================================================================================================--
--####################################   Architecture   ###########################################--
--=================================================================================================--

architecture structural of ws_command_reg is

  --================================ Signal Declarations ================================--
  --========================--
  -- Wishbone bus registers --
  --========================--
  signal sRegisters,sRegisters_int,sRegisters_int_d1,sRegisters_pulsed : t_sRegister_ws_cmd; --std_logic_vector(WS_CMD_NUM*WB_DATA_WIDTH -1 downto 0);
  signal sValidAddr, sValidAddr_d1 : std_logic;
  signal iWbAddr, iWbAddr_d1   : integer range 0 to ((WS_CMD_NUM)-1);
  signal sWbAck, sWbErr            : std_logic := '0';
  signal sWbWrite, sWbWrite_d1, sWbWrite_d2     : std_logic;

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
        sWbAck        <= '0';
        sWbErr        <= '0';
        sValidAddr_d1 <= '0';
        sWbWrite_d1   <= '0';
        sWbWrite_d2   <= '0';
        iWbAddr_d1    <= 0;
        sRegisters_int_d1 <= (others => '0');
      else
        sRegisters_int_d1 <= sRegisters_int;
        iWbAddr_d1    <= iWbAddr;
        sValidAddr_d1 <= sValidAddr;
        sWbWrite_d1   <= sWbWrite;
        sWbWrite_d2   <= sWbWrite_d1;
        sWbAck        <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and sValidAddr_d1 and (not sWbAck);
        sWbErr        <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and (not sValidAddr) and (not sWbErr);
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
    if iWbAddr < WS_CMD_NUM then
      sValidAddr     <= '1';
      WB_WBS_O.dat_o <= sRegisters(iWbAddr*WB_DATA_WIDTH+(WB_DATA_WIDTH-1) downto iWbAddr*WB_DATA_WIDTH);
    else
      sValidAddr     <= '0';
      WB_WBS_O.dat_o <= (others => '0');
    end if;
  end process procRegRead;


  -- Wishbone Write
  procRegWrite : process (WB_CLK, WB_RST) is
  begin
    if rising_edge(WB_CLK) then         -- rising clock edge
      if WB_RST = '1' then              -- synchronous reset (active high)
        sRegisters <= CONFIG_REG_DEFAULT;
      else
        if (sValidAddr = '1') and (sWbWrite = '1') then
          sRegisters(iWbAddr*WB_DATA_WIDTH+(WB_DATA_WIDTH-1) downto iWbAddr*WB_DATA_WIDTH) <= WB_WBS_I.dat_i;
          sRegisters_int(iWbAddr*WB_DATA_WIDTH+(WB_DATA_WIDTH-1) downto iWbAddr*WB_DATA_WIDTH) <= WB_WBS_I.dat_i;
        else
          sRegisters_int(iWbAddr*WB_DATA_WIDTH+(WB_DATA_WIDTH-1) downto iWbAddr*WB_DATA_WIDTH) <= C_zeros;
        end if;
      end if;
    end if;
  end process procRegWrite;

  -- purpose: detectes the edge of the sWbWrite signal to pulse the signal in output
  p_edge_detector: process (sWbWrite_d1, sWbWrite_d2,sRegisters_int,sRegisters_int_d1, iWbAddr) is
    variable sRegisters_ed : std_logic_vector(WS_CMD_NUM*WB_DATA_WIDTH -1 downto 0);
  begin  -- process p_edge_detector
    sRegisters_ed := sRegisters_int and not sRegisters_int_d1;
    for addr_i in 0 to WS_CMD_NUM-1 loop
      if addr_i = iWbAddr then
        sRegisters_pulsed(addr_i*WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto addr_i*WB_DATA_WIDTH) <= (sRegisters_ed(addr_i*WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto addr_i*WB_DATA_WIDTH))  and (sWbWrite_d1 and not sWbWrite_d2);
      else
        sRegisters_pulsed(addr_i*WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto addr_i*WB_DATA_WIDTH) <= (others => '0');
      end if;
    end loop;
  end process p_edge_detector;

  -- purpose: assigns the pulsed_registers to the output
  p_assign_bus_out: process (sRegisters_pulsed) is
  begin  -- process p_assign_bus_out
    proc_ws_cmd_wr2bus(sRegisters_pulsed, CMD_BUS);
  end process p_assign_bus_out;

--=====================================================================================--
end structural;
