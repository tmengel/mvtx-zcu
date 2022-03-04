-------------------------------------------------------------------------------
-- Title      : Wishbone Dual Port FIFO test interface
-- Project    :
-------------------------------------------------------------------------------
-- File       : wb_fifo_test_if.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    :
-- Created    : 2018-04-16
-- Last update: 2018-05-12
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-04-16  1.0      simon	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


library work;
use work.intercon_pkg.all;

entity wb_fifo_test_if is
  generic (
    FIFO_DEPTH : natural := 64);
  port (
    WB_CLK : in std_logic;
    WB_RST : in std_logic;

    WB_WBM_O : out wbm_o_type;
    WB_WBM_I : in  wbm_i_type;

    -- Interface to wishbone master via FIFO
    -- CAN HLP initiates WB transactions on DP0
    DP0_DT_I   : in  std_logic_vector(31 downto 0);
    DP0_EPTY_I : in  std_logic;
    DP0_RD_O   : out std_logic;

    -- Interface to wishbone master via FIFO
    -- CAN HLP receives WB replies on DP1
    DP1_DT_O   : out std_logic_vector(31 downto 0);
    DP1_FULL_I : in  std_logic;
    DP1_WR_O   : out std_logic);

end entity wb_fifo_test_if;


architecture behavioral of wb_fifo_test_if is
  constant C_WB_TIMEOUT_COUNT : natural := 100;

begin  -- architecture behavioral

  proc_wb_master: process is
    variable wb_data     : std_logic_vector(15 downto 0);
    variable wb_addr     : std_logic_vector(14 downto 0);
    variable wb_write_op : std_logic := '0';

    procedure wb_write (
      constant addr : in std_logic_vector(14 downto 0);
      constant data : in std_logic_vector(15 downto 0)
      ) is
      variable wb_timeout_counter : natural := 0;
    begin
      WB_WBM_O.addr_o <= addr;
      WB_WBM_O.dat_o <= data;
      WB_WBM_O.we_o <= '1';
      wait until rising_edge(WB_CLK);
      WB_WBM_O.cyc_o <= '1';
      WB_WBM_O.stb_o <= '1';

      while WB_WBM_I.ack_i = '0' and WB_WBM_I.err_i = '0' and wb_timeout_counter < C_WB_TIMEOUT_COUNT loop
        wait until rising_edge(WB_CLK);
        wb_timeout_counter := wb_timeout_counter + 1;
      end loop;

      -- Todo: error handling
      if wb_timeout_counter = C_WB_TIMEOUT_COUNT or WB_WBM_I.err_i = '1' then

      end if;

      WB_WBM_O.cyc_o <= '0';
      WB_WBM_O.stb_o <= '0';
      WB_WBM_O.we_o <= '0';
    end procedure wb_write;

    procedure wb_read (
      constant addr : in  std_logic_vector(14 downto 0);
      variable data : out std_logic_vector(15 downto 0)
      ) is
      variable wb_timeout_counter : natural := 0;
    begin
      WB_WBM_O.addr_o <= addr;
      WB_WBM_O.we_o <= '0';
      wait until rising_edge(WB_CLK);
      WB_WBM_O.cyc_o <= '1';
      WB_WBM_O.stb_o <= '1';

      while WB_WBM_I.ack_i = '0' and WB_WBM_I.err_i = '0' and wb_timeout_counter < C_WB_TIMEOUT_COUNT loop
        wait until rising_edge(WB_CLK);
        wb_timeout_counter := wb_timeout_counter + 1;
      end loop;

      -- Todo: error handling
      if wb_timeout_counter = C_WB_TIMEOUT_COUNT or WB_WBM_I.err_i = '1' then

      end if;

      data := WB_WBM_I.dat_i;
      WB_WBM_O.cyc_o <= '0';
      WB_WBM_O.stb_o <= '0';
    end procedure wb_read;

  begin  -- process proc_wb_master
    loop
      DP0_RD_O <= '0';
      DP1_WR_O <= '0';
      WB_WBM_O.addr_o <= (others => '0');
      WB_WBM_O.dat_o <= (others => '0');
      WB_WBM_O.we_o <= '0';
      WB_WBM_O.cyc_o <= '0';
      WB_WBM_O.stb_o <= '0';

      wait until rising_edge(WB_CLK);

      -- Wait for DP0 FIFO to contain a new wishbone transaction,
      -- and don't start a new wishbone transaction if DP1 is full
      -- to prevent overflowing DP1 in case of wishbone read operation
      if DP0_EPTY_I = '0' and DP1_FULL_I = '0' then
        DP0_RD_O    <= '1';
        wait until rising_edge(WB_CLK);
        DP0_RD_O    <= '0';
        -- Wait two clock cycles for data to arrive on dt_o port
        wait until rising_edge(WB_CLK);
        wait until rising_edge(WB_CLK);
        wb_write_op := DP0_DT_I(31);
        wb_addr     := DP0_DT_I(30 downto 16);


        if wb_write_op = '1' then
          wb_data := DP0_DT_I(15 downto 0);
          wb_write(wb_addr, wb_data);
        else
          wb_read(wb_addr, wb_data);

          -- Should write transactions also put something on DP0?
          DP1_DT_O(31)           <= wb_write_op;
          DP1_DT_O(30 downto 16) <= wb_addr;
          DP1_DT_O(15 downto 0)  <= wb_data;
          DP1_WR_O               <= '1';
        end if;



        wait until rising_edge(WB_CLK);

        DP1_WR_O <= '0';
      end if;
    end loop;
  end process proc_wb_master;


end architecture behavioral;
