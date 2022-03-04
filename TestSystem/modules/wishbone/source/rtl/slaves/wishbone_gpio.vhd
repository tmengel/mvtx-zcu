-------------------------------------------------------------------------------
-- Title      : Wishbone Slave Gpio
-- Project    :
-------------------------------------------------------------------------------
-- File	      : wishbone_gpio.vhd
-- Author     : Matthias Bonora	 <matthias.bonora@cern.ch>
-- Company    : University of Salzburg / CERN
-- Created    : 2016-01-14
-- Last update: 2017-03-13
-- Platform   : CERN OS7, Xilinx Vivado 2015.3
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: A simple Wishbone slave module which exposes a registers for
-- GPIO purposes
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date	       Version	Author	Description
-- 2016-01-14  1.0	mbonora Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone interface package
use work.intercon_pkg.all;

entity wb_slave_gpio is
  generic (
    CONFIG_REG_DEFAULT : std_logic_vector(15 downto 0) := (others => '0')
    );
  port (
    -- Wishbone interface signals
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  wbs_i_type;
    WB_WBS_O : out wbs_o_type;
    OUTPUTS  : out std_logic_vector(15 downto 0);
    INPUTS   : in  std_logic_vector(15 downto 0)
    );
end wb_slave_gpio;

architecture structural of wb_slave_gpio is

  --========================--
  -- Wishbone bus registers --
  --========================--
  signal sRegistersIn	: std_logic_vector(15 downto 0);
  signal sRegistersOut	: std_logic_vector(15 downto 0);
  signal sValidAddr	: std_logic;
  signal iWbAddr	: integer range 0 to 255;
  signal sWbAck, sWbErr : std_logic;
  signal sWbWrite	: std_logic;

begin  --========####	Architecture Body   ####========--

  OUTPUTS <= sRegistersOut(OUTPUTS'range);
  registersInput : process (WB_CLK) is
  begin	 -- process genAckErr
    if rising_edge(WB_CLK) then
      sRegistersIn <= INPUTS;
    end if;
  end process registersInput;



  --==================================== Wishbone bus logic =============================--
  -- generate acknowledge and error signals
  genAckErr : process (WB_CLK, WB_RST) is
  begin	 -- process genAckErr
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then		-- synchronous reset (active high)
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
  procRegRead : process (sRegistersIn, iWbAddr) is
  begin
    if iWbAddr = 0 then
      sValidAddr     <= '1';
      WB_WBS_O.dat_o <= sRegistersIn;
    else
      sValidAddr     <= '0';
      WB_WBS_O.dat_o <= (others => '1');
    end if;
  end process procRegRead;

  -- Wishbone Write
  procRegWrite : process (WB_CLK, WB_RST) is
  begin
    if rising_edge(WB_CLK) then		-- rising clock edge
      if WB_RST = '1' then		-- synchronous reset (active high)
	sRegistersOut <= CONFIG_REG_DEFAULT;
      else
	if (sValidAddr = '1') and (sWbWrite = '1') then
	  sRegistersOut <= WB_WBS_I.dat_i;
	end if;
      end if;
    end if;
  end process procRegWrite;

end structural;
