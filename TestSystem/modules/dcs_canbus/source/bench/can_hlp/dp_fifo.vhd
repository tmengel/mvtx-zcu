-------------------------------------------------------------------------------
-- Title      : FIFO
-- Project    :
-------------------------------------------------------------------------------
-- File       : dp_fifo.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    :
-- Created    : 2018-04-24
-- Last update: 2018-04-24
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Simple entity to imitate DP FIFO in UltraScale.
--              Not for synthesis.
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-04-24  1.0      simon	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity dp_fifo is
  generic (
    FIFO_DEPTH : natural := 64;
    DATA_WIDTH : natural := 32);

  port (
    CLK    : in  std_logic;
    RST    : in  std_logic;
    DT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    DT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    EPTY_O : out std_logic;
    FULL_O : out std_logic;
    RD_I   : in  std_logic;
    WR_I   : in  std_logic);
end entity dp_fifo;


architecture behavioral of dp_fifo is
  type fifo_storage_t is array (0 to FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal fifo_storage : fifo_storage_t;

  signal write_ptr : natural := 0;
  signal read_ptr  : natural := 0;


begin  -- architecture behavioral


  proc_fifo_input: process (CLK, RST) is
    variable fifo_size : natural := 0;
  begin  -- process proc_fifo_input
    if RST = '1' then
      fifo_size := 0;
      read_ptr <= 0;
      write_ptr <= 0;
      EPTY_O <= '1';
      FULL_O <= '0';
    elsif rising_edge(CLK) then
      EPTY_O <= '1';
      FULL_O <= '0';

      if WR_I = '1' and fifo_size < FIFO_DEPTH then
        fifo_storage(write_ptr) <= DT_I;

        if write_ptr+1 = FIFO_DEPTH then
          write_ptr <= 0;
        else
          write_ptr <= write_ptr+1;
        end if;
        fifo_size := fifo_size + 1;

      end if;

      if RD_I = '1' and fifo_size > 0 then
        DT_O <= fifo_storage(read_ptr);

        if read_ptr+1 = FIFO_DEPTH then
          read_ptr <= 0;
        else
          read_ptr <= read_ptr+1;
        end if;

        fifo_size := fifo_size - 1;
      end if;

      if fifo_size /= 0 then
        EPTY_O <= '0';
      end if;

      if fifo_size = FIFO_DEPTH then
        FULL_O <= '1';
      end if;

    end if;
  end process proc_fifo_input;

end architecture behavioral;
