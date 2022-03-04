-- $Id$
-------------------------------------------------------------------------------
-- Title      : wishbone asynchronous bus translation
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : wb_cdc.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2017-03-01
-- Last update: 2017-03-13
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: connect two wishbone busses together in different clock domains
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;

entity wb_cdc is

  port (
    -- master side
    WB1_CLK   : in  std_logic;
    WB1_RST   : in  std_logic;
    WB1_WBS_I : in  wbs_i_type;
    WB1_WBS_O : out wbs_o_type;
    -- slave side
    WB2_CLK   : in  std_logic;
    WB2_RST   : in  std_logic;
    WB2_ADR_o : out std_logic_vector(7 downto 0);
    WB2_DAT_o : out std_logic_vector(15 downto 0);
    WB2_DAT_i : in  std_logic_vector(15 downto 0);
    WB2_WE_o  : out std_logic;
    WB2_STB_o : out std_logic;
    WB2_ACK_i : in  std_logic;
    WB2_ERR_i : in  std_logic;
    WB2_CYC_o : out std_logic
    );

end entity wb_cdc;


architecture rtl of wb_cdc is
  signal sWb1Adr_i      : std_logic_vector(7 downto 0)  := (others => '0');
  signal sWb1Dat_i      : std_logic_vector(15 downto 0) := (others => '0');
  signal sWb1Dat_o      : std_logic_vector(15 downto 0) := (others => '0');
  signal sWb1We_i       : std_logic                     := '0';
  signal sWb1Stb_i      : std_logic                     := '0';
  signal sWb1Ack_o      : std_logic                     := '0';
  signal sWb1Err_o      : std_logic                     := '0';
  signal sWb1Cyc_i      : std_logic                     := '0';
  --
  signal sWb1Done_sync  : std_logic_vector(2 downto 0)  := (others => '0');
  --
  signal sWb2Adr_o      : std_logic_vector(7 downto 0)  := (others => '0');
  signal sWb2Dat_i      : std_logic_vector(15 downto 0) := (others => '0');
  signal sWb2Dat_o      : std_logic_vector(15 downto 0) := (others => '0');
  signal sWb2We_o       : std_logic                     := '0';
  signal sWb2Stb_o      : std_logic                     := '0';
  signal sWb2Ack_i      : std_logic                     := '0';
  signal sWb2Err_i      : std_logic                     := '0';
  signal sWb2Cyc_o      : std_logic                     := '0';
  --
  signal sWb2Cyc_o_sync : std_logic_vector(2 downto 0)  := (others => '0');
  signal sWb2Stb_o_sync : std_logic_vector(2 downto 0)  := (others => '0');
  signal sWb2Done       : std_logic                     := '0';

  attribute ASYNC_REG                   : string;
  attribute ASYNC_REG of sWb1Done_sync  : signal is "TRUE";
  attribute ASYNC_REG of sWb2Cyc_o_sync : signal is "TRUE";
  attribute ASYNC_REG of sWb2Stb_o_sync : signal is "TRUE";


begin  -- architecture rtl
  WB1_WBS_O.dat_o <= sWb1Dat_o;
  WB1_WBS_O.ack_o <= sWb1Ack_o;
  WB1_WBS_O.err_o <= sWb1Err_o;

  WB2_ADR_o <= sWb2Adr_o;
  WB2_DAT_o <= sWb2Dat_o;
  WB2_WE_o  <= sWb2We_o;
  WB2_STB_o <= sWb2Stb_o;
  WB2_CYC_O <= sWb2Cyc_o;

  -- master side logic
  process (WB1_CLK) is
  begin  -- process
    if rising_edge(WB1_CLK) then
      if WB1_RST = '1' then             -- synchronous reset (active high)
        sWb1Adr_i <= (others => '0');
        sWb1Dat_i <= (others => '0');
        sWb1Dat_o <= (others => '0');
        sWb1We_i  <= '0';
        sWb1Stb_i <= '0';
        sWb1Ack_o <= '0';
        sWb1Err_o <= '0';
        sWb1Cyc_i <= '0';
      else
        if (sWb1Cyc_i = '1') and (sWb1Stb_i = '1') then
          if (sWb1Done_sync(1) = '1') and (sWb1Done_sync(2) = '0') then
            -- end of cycle - store slave
            sWb1Dat_o <= sWb2Dat_i;
            sWb1Ack_o <= sWb2Ack_i;
            sWb1Err_o <= sWb2Err_i;
            sWb1We_i  <= '0';
            sWb1Stb_i <= '0';
          end if;
        else
          -- idle - store master
          sWb1Adr_i <= WB1_WBS_I.addr_i;
          sWb1Dat_i <= WB1_WBS_I.dat_i;
          sWb1Dat_o <= (others => '0');
          sWb1We_i  <= WB1_WBS_I.we_i and (not(sWb1Ack_o or sWb1Err_o));
          sWb1Stb_i <= WB1_WBS_I.stb_i and (not(sWb1Ack_o or sWb1Err_o));
          sWb1Ack_o <= '0';
          sWb1Err_o <= '0';
          sWb1Cyc_i <= WB1_WBS_I.cyc_i;
        end if;
      end if;
      -- synchronizer signals
      sWb1Done_sync <= sWb1Done_sync(1 downto 0) & sWb2Done;
    end if;
  end process;

  -- slave side logic
  process (WB2_CLK) is
  begin  -- process
    if rising_edge(WB2_CLK) then
      if WB2_RST = '1' then             -- synchronous reset (active high)
        sWb2Adr_o <= (others => '0');
        sWb2Dat_i <= (others => '0');
        sWb2Dat_o <= (others => '0');
        sWb2We_o  <= '0';
        sWb2Stb_o <= '0';
        sWb2Ack_i <= '0';
        sWb2Err_i <= '0';
        sWb2Cyc_o <= '0';
        sWb2Done  <= '0';

      else
        if (WB2_ACK_i = '1') or (WB2_ERR_i = '1') then
          -- end of cycle - store slave
          sWb2Dat_i <= WB2_DAT_i;
          sWb2Ack_i <= WB2_ACK_i;
          sWb2Err_i <= WB2_ERR_i;
          sWb2We_o  <= '0';
          sWb2Stb_o <= '0';
          sWb2Done  <= '1';
        elsif sWb2Stb_o_sync(2 downto 1) = "01" then
          -- beginning of cycle - store master
          sWb2Adr_o <= sWb1Adr_i;
          sWb2Dat_i <= (others => '0');
          sWb2Dat_o <= sWb1Dat_i;
          sWb2We_o  <= sWb1We_i;
          sWb2Stb_o <= sWb1Stb_i;
          sWb2Ack_i <= '0';
          sWb2Err_i <= '0';
          sWb2Cyc_o <= sWb1Cyc_i;
          sWb2Done  <= '0';
        elsif sWb2Cyc_o_sync(2 downto 1) = "10" then
          -- cyc deassert
          sWb2Adr_o <= (others => '0');
          sWb2Dat_i <= (others => '0');
          sWb2Dat_o <= (others => '0');
          sWb2We_o  <= '0';
          sWb2Stb_o <= '0';
          sWb2Ack_i <= '0';
          sWb2Err_i <= '0';
          sWb2Cyc_o <= '0';
          sWb2Done  <= '0';
        end if;
      end if;

      -- synchronize signals
      sWb2Cyc_o_sync <= sWb2Cyc_o_sync(1 downto 0) & sWb1Cyc_i;
      sWb2Stb_o_sync <= sWb2Stb_o_sync(1 downto 0) & sWb1Stb_i;

    end if;
  end process;

end architecture rtl;
