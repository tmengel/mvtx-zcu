-------------------------------------------------------------------------------
-- Title      : DNA read
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : dna_read.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Author     : A. Velure <Arild.Velure@cern.ch>
-- Company    : CERN
-- Created    : 2018-08-13
-- Last update: 2018-08-13
-- Platform   : Xilinx Vivado 2017.4
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Module for reading out unique DNA value of FPGA
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity dna_read is
  generic(
    G_DNA_SIZE      : integer                       := 96;
    G_SIM_DNA_VALUE : std_logic_vector(95 downto 0) := X"76543210FEDCBA9876543210"
  );
  port(
    clk_i         : in  std_logic;
    rst_i         : in  std_logic;
    do_read_dna_i : in  std_logic;      -- Enable readout of DNA value
    dna_value_o   : out std_logic_vector(G_DNA_SIZE - 1 downto 0) -- DNA value, available after 97 clock cycles from do_read_dna is toggled
  );
end entity;

architecture rtl of dna_read is
  type state_t is (C_IDLE, C_READ, C_SCROLL, C_DONE);
  signal state_s     : state_t;
  signal read_s      : std_logic;       -- Read enable for latching DNA value to DNA shift register
  signal shift_s     : std_logic;       -- Shift enable of DNA shift register
  signal writeout_s  : std_logic;       -- Latch shifted out value to output of module
  signal dout_s      : std_logic;       -- Output of DNA shift register
  signal cnt_i       : unsigned(positive(ceil(log2(real(G_DNA_SIZE)))) - 1 downto 0); -- Counter for stopping after DNA value is read out
  signal dna_value_s : std_logic_vector(G_DNA_SIZE - 1 downto 0); -- Local shift register to hold shifted out DNA value
begin

  -- FSM for generating shift signal high for N cycles
  p_statemachine : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state_s    <= C_IDLE;
        read_s     <= '0';
        cnt_i      <= (others => '0');
        shift_s    <= '0';
        writeout_s <= '0';
      else
        case (state_s) is
          when C_IDLE =>
            if (do_read_dna_i = '1') then
              state_s <= C_READ;
            else
              state_s <= C_IDLE;
            end if;
            read_s <= '0';
            cnt_i <= (others => '0');
            shift_s <= '0';
            writeout_s <= '0';
          when C_READ =>
            state_s    <= C_SCROLL;
            read_s     <= '1';
            cnt_i      <= (others => '0');
            shift_s    <= '0';
            writeout_s <= '0';
          when C_SCROLL =>
            if (cnt_i < (G_DNA_SIZE - 1)) then
              state_s <= C_SCROLL;
            else
              state_s <= C_DONE;
            end if;
            read_s <= '0';
            cnt_i <= cnt_i + 1;
            shift_s <= '1';
            writeout_s <= '0';
          when C_DONE =>
            state_s    <= C_IDLE;
            read_s     <= '0';
            cnt_i      <= (others => '0');
            shift_s    <= '0';
            writeout_s <= '1';
          when others =>
            state_s    <= C_IDLE;
            read_s     <= '0';
            cnt_i      <= (others => '0');
            shift_s    <= '0';
            writeout_s <= '0';
        end case;
      end if;
    end if;
  end process p_statemachine;

  INST_DNA_PORT : DNA_PORTE2
    generic map(
      SIM_DNA_VALUE => G_SIM_DNA_VALUE) -- Specifies a 96-bit DNA value for simulation
    port map(
      DOUT  => dout_s,                  -- Output of internal shift register
      CLK   => clk_i,                   -- Shift clock
      DIN   => '0',                     -- User data input pin, will be shifted out after dna value
      READ  => read_s,                  -- Latch DNA value in internal shift register
      SHIFT => shift_s);                -- Shift enable of internal shift register

  p_dna_shiftreg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (shift_s = '1') then
        dna_value_s <= (dout_s & dna_value_s(dna_value_s'high downto 1));
      end if;
    end if;
  end process p_dna_shiftreg;

  p_dna_output_reg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        dna_value_o <= (others => '0');
      else
        if (writeout_s = '1') then
          dna_value_o <= dna_value_s;
        end if;
      end if;
    end if;
  end process p_dna_output_reg;
end;

