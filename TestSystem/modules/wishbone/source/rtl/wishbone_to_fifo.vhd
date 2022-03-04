-------------------------------------------------------------------------------
-- Title      : wishbone slave example
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : wishbone_slave.vhd
-- Author     : Matthias Bonora  <matthias.bonora@cern.ch>
-- Company    : CERN
-- Created    : 2017-09-28
-- Last update: 2017-10-13
-- Platform   : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Simple wishbone slave writing to a fifo
-------------------------------------------------------------------------------
-- Copyright (c) 2017 CERN
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-09-22  1.0      mbonora Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;

--=================================================================================================--
--#######################################   Entity   ##############################################--
--=================================================================================================--

entity wishbone_to_fifo is
  port (
    -- Wishbone interface signals
    WB_CLK       : in  std_logic;
    WB_RST       : in  std_logic;
    WB_WBS_I     : in  wbs_i_type;
    WB_WBS_O     : out wbs_o_type;
    -- FIFO interface signals to PA3
    FIFO_DOUT    : out std_logic_vector(7 downto 0);
    FIFO_EMPTY   : out std_logic;
    FIFO_P_EMPTY : out std_logic;
    FIFO_RDEN    : in  std_logic;
    FIFO_RDCLK   : in  std_logic
    );
end wishbone_to_fifo;

--=================================================================================================--
--####################################   Architecture   ###########################################--
--=================================================================================================--
architecture structural of wishbone_to_fifo is

  --================================ Signal Declarations ================================--
  --========================--
  -- Wishbone bus registers --
  --========================--
  signal iWbAddr        : integer range 0 to 255;
  signal sWbAck, sWbErr : std_logic;

  constant REG_WRITE_COUNTER_LSB    : integer := 0;
  constant REG_WRITE_COUNTER_MSB    : integer := 1;
  constant REG_READ_COUNTER_LSB     : integer := 2;
  constant REG_READ_COUNTER_MSB     : integer := 3;
  constant REG_OVERFLOW_COUNTER_LSB : integer := 4;
  constant REG_OVERFLOW_COUNTER_MSB : integer := 5;

  constant REG_VALIDATE_READ_COUNTER_LSB : integer := 6;
  constant REG_VALIDATE_READ_COUNTER_MSB : integer := 7;

  constant REG_FIFO_STATUS : integer := 8;

  constant REG_RESET_COUNTERS : integer := 255;

  signal sError : std_logic;

  -- Fifo signals
  signal sfifo_datain                 : std_logic_vector(15 downto 0);
  signal sfifo_full, sfifo_overflow   : std_logic;
  signal sfifo_read, sfifo_empty      : std_logic;
  signal sfifo_write, sfifo_prog_full : std_logic;

  -- Counters
  signal swrite_counter, sread_counter, soverflow_counter : std_logic_vector(31 downto 0);

  signal svalidate_read_counter : std_logic_vector(31 downto 0);

  signal scounter_reset : std_logic;

--=======================================================================================--
begin  --========####   Architecture Body   ####========--
--=======================================================================================--

  upcounter_overflow : entity work.upcounter
    generic map (
      BIT_WIDTH     => 32,
      IS_SATURATING => '0',
      VERBOSE       => '0')
    port map (
      CLK       => WB_CLK,
      RST       => WB_RST,
      RST_CNT   => scounter_reset,
      CNT_UP    => sfifo_overflow,
      CNT_VALUE => soverflow_counter);

  upcounter_read : entity work.upcounter
    generic map (
      BIT_WIDTH     => 32,
      IS_SATURATING => '0',
      VERBOSE       => '0')
    port map (
      CLK       => WB_CLK,
      RST       => WB_RST,
      RST_CNT   => scounter_reset,
      CNT_UP    => sfifo_read,
      CNT_VALUE => sread_counter);

  upcounter_write : entity work.upcounter
    generic map (
      BIT_WIDTH     => 32,
      IS_SATURATING => '0',
      VERBOSE       => '0')
    port map (
      CLK       => WB_CLK,
      RST       => WB_RST,
      RST_CNT   => scounter_reset,
      CNT_UP    => sfifo_write,
      CNT_VALUE => swrite_counter);

  --==================================== Wishbone bus logic =============================--
  -- generate acknowledge and error signals
  genAckErr : process (WB_CLK) is
  begin  -- process genAckErr
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then              -- synchronous reset (active high)
        sWbAck <= '0';
        sWbErr <= '0';
      else
        sWbAck <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and (not sWbAck);
        sWbErr <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and sError and (not sWbErr);
      end if;
    end if;
  end process genAckErr;

  WB_WBS_O.ack_o <= sWbAck;
  WB_WBS_O.err_o <= sWbErr;
  sError         <= sfifo_full;

  -- generate wishbone write signal
  sfifo_write <= sWbAck and WB_WBS_I.we_i;

  -- Wishbone Read and Address Decode (asynchronous)
  iWbAddr <= to_integer(unsigned(WB_WBS_I.addr_i));
  procRegRead : process (iWbAddr, sfifo_full, sfifo_overflow, sfifo_prog_full,
                         soverflow_counter,
                         sread_counter,
                         svalidate_read_counter,
                         swrite_counter) is
  begin
    case iWbAddr is
      when REG_WRITE_COUNTER_LSB =>
        WB_WBS_O.dat_o <= swrite_counter(15 downto 0);
      when REG_WRITE_COUNTER_MSB =>
        WB_WBS_O.dat_o <= swrite_counter(31 downto 16);
      when REG_READ_COUNTER_LSB =>
        WB_WBS_O.dat_o <= sread_counter(15 downto 0);
      when REG_READ_COUNTER_MSB =>
        WB_WBS_O.dat_o <= sread_counter(31 downto 16);
      when REG_OVERFLOW_COUNTER_LSB =>
        WB_WBS_O.dat_o <= soverflow_counter(15 downto 0);
      when REG_OVERFLOW_COUNTER_MSB =>
        WB_WBS_O.dat_o <= soverflow_counter(31 downto 16);
      when REG_VALIDATE_READ_COUNTER_LSB =>
        WB_WBS_O.dat_o <= svalidate_read_counter(15 downto 0);
      when REG_VALIDATE_READ_COUNTER_MSB =>
        WB_WBS_O.dat_o <= svalidate_read_counter(31 downto 16);
      when REG_RESET_COUNTERS =>
        WB_WBS_O.dat_o <= x"0001";
      when REG_FIFO_STATUS =>
        WB_WBS_O.dat_o <= x"000" & '0' &
                          sfifo_overflow &
                          sfifo_full &
                          sfifo_prog_full;
      when others =>
        WB_WBS_O.dat_o <= x"DEAD";
    end case;
  end process procRegRead;

  scounter_reset <= '1' when (WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not WB_WBS_i.we_i) = '1' and iWbAddr = REG_RESET_COUNTERS
                    else '0';

  sfifo_datain <= WB_WBS_i.dat_i;
  sfifo_read   <= FIFO_RDEN;

  xpm_fifo_async_inst : xpm_fifo_async
    generic map (
      FIFO_MEMORY_TYPE    => "block",  --string; "auto", "block", or "distributed";
      ECC_MODE            => "no_ecc",  --string; "no_ecc" or "en_ecc";
      RELATED_CLOCKS      => 0,         --positive integer; 0 or 1
      FIFO_WRITE_DEPTH    => 32768,     --positive integer
      WRITE_DATA_WIDTH    => 16,        --positive integer
      WR_DATA_COUNT_WIDTH => 15,        --positive integer
      PROG_FULL_THRESH    => 30719,     --positive integer
      FULL_RESET_VALUE    => 0,         --positive integer; 0 or 1;
      READ_MODE           => "std",     --string; "std" or "fwft";
      FIFO_READ_LATENCY   => 1,         --positive integer;
      READ_DATA_WIDTH     => 8,         --positive integer
      RD_DATA_COUNT_WIDTH => 16,        --positive integer
      PROG_EMPTY_THRESH   => 4095,      --positive integer
      DOUT_RESET_VALUE    => "0",       --string
      CDC_SYNC_STAGES     => 2,         --positive integer
      WAKEUP_TIME         => 0          --positive integer; 0 or 2;
      )
    port map (
      sleep         => '0',
      rst           => WB_RST,
      wr_clk        => WB_CLK,
      wr_en         => sfifo_write,
      din           => sfifo_datain,
      full          => sfifo_full,
      overflow      => sfifo_overflow,
      wr_rst_busy   => open,
      rd_clk        => FIFO_RDCLK,
      rd_en         => sfifo_read,
      dout          => FIFO_DOUT,
      empty         => FIFO_EMPTY,
      underflow     => open,
      rd_rst_busy   => open,
      prog_full     => sfifo_prog_full,
      wr_data_count => open,
      prog_empty    => FIFO_P_EMPTY,
      rd_data_count => open,
      injectsbiterr => '0',
      injectdbiterr => '0',
      sbiterr       => open,
      dbiterr       => open
      );


--=====================================================================================--
end structural;
