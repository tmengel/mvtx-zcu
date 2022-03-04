-------------------------------------------------------------------------------
-- Title      : ws_status
-- Project    : RUv0
-------------------------------------------------------------------------------
-- File       : ws_status.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-08-03
-- Last update: 2019-01-29
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave to monitor githash, compilation date,
--              etc (global firmware/fpga related informations)
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.ws_status_pkg.all;

entity ws_status is
  generic (
    HASH_CODE : std_logic_vector(2*WB_DATA_WIDTH -1 downto 0) := (others => '0');
    DATE      : std_logic_vector(3*WB_DATA_WIDTH -1 downto 0) := (others => '0');
    OS        : std_logic_vector(WB_DATA_WIDTH -1 downto 0)   := (others => '0')
    );
  port (
    -- inputs
    DIPSWITCH  : in  std_logic_vector(9 downto 0);
    PUSHBUTTON : in  std_logic_vector(3 downto 0);
    -- Wishbone interface
    WB_CLK     : in  std_logic;         -- Wishbone clock
    WB_RST     : in  std_logic;         -- Wishbone reset
    s_EdgeCntTotal : in std_logic_vector(15 downto 0);
    WB_WBS_I   : in  wbs_i_type;        -- Wishbone slave input signals
    WB_WBS_O   : out wbs_o_type         -- Wishbone slave output signals
    );

end ws_status;

architecture str of ws_status is

  signal s_githash : std_logic_vector(HASH_CODE'range);
  signal s_date    : std_logic_vector(DATE'range);
  signal s_os      : std_logic_vector(OS'range);

  signal s_wbs_reg_i : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Read registers
  signal s_wbs_reg_o : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Write registers

  signal s_dna_do_read : std_logic;
  signal s_dna_value   : std_logic_vector(C_DNA_PORT_SIZE-1 downto 0);

begin


  -- Read and write registers to be passed to the wishbone register module
  p_wishbone_data : process (DIPSWITCH, PUSHBUTTON, s_date, s_dna_value,
                             s_githash, s_EdgeCntTotal, s_wbs_reg_o) is
  begin  -- process p_wishbone_data
    s_wbs_reg_i                             <= (others => (others => '0'));
    -- Read
    s_wbs_reg_i(WB_ADD'pos(GITHASH_LSB))    <= s_githash(C_GITHASH_range_LSB'range);
    s_wbs_reg_i(WB_ADD'pos(GITHASH_MSB))    <= s_githash(C_GITHASH_range_MSB'range);
    s_wbs_reg_i(WB_ADD'pos(DATE_LSB))       <= s_date(C_DATE_range_LSB'range);
    s_wbs_reg_i(WB_ADD'pos(DATE_CSB))       <= s_date(C_DATE_range_CSB'range);
    s_wbs_reg_i(WB_ADD'pos(DATE_MSB))       <= s_date(C_DATE_range_MSB'range);
    s_wbs_reg_i(WB_ADD'pos(OS_LSB))         <= s_EdgeCntTotal;
    s_wbs_reg_i(WB_ADD'pos(DIPSWITCH_VAL))  <= wb_resize(DIPSWITCH);
    s_wbs_reg_i(WB_ADD'pos(DNA_CHUNK_0))    <= s_dna_value(C_DNA_CHUNK_range_0'range);
    s_wbs_reg_i(WB_ADD'pos(DNA_CHUNK_1))    <= s_dna_value(C_DNA_CHUNK_range_1'range);
    s_wbs_reg_i(WB_ADD'pos(DNA_CHUNK_2))    <= s_dna_value(C_DNA_CHUNK_range_2'range);
    s_wbs_reg_i(WB_ADD'pos(DNA_CHUNK_3))    <= s_dna_value(C_DNA_CHUNK_range_3'range);
    s_wbs_reg_i(WB_ADD'pos(DNA_CHUNK_4))    <= s_dna_value(C_DNA_CHUNK_range_4'range);
    s_wbs_reg_i(WB_ADD'pos(DNA_CHUNK_5))    <= s_dna_value(C_DNA_CHUNK_range_5'range);
    s_wbs_reg_i(WB_ADD'pos(PUSHBUTTON_VAL)) <= wb_resize(PUSHBUTTON);
    -- Write
    s_dna_do_read                           <= s_wbs_reg_o(WB_ADD'pos(DNA_DO_READ))(C_DNA_DO_READ_bit);
    -- Write feedback

  end process p_wishbone_data;

  -----------------------------------------------------------------------------
  -- githash and date
  -----------------------------------------------------------------------------
  s_os      <= OS;
  s_date    <= DATE;
  s_githash <= HASH_CODE;

  -----------------------------------------------------------------------------
  -- Wishbone register handling
  -----------------------------------------------------------------------------
  INST_wishbone_slave_register : entity work.ws_reg
    generic map (
      WB_ADD_WE      => C_WB_ADD_WE,
      WB_ILLEGAL_VAL => x"DEAD",
      WB_REG_INIT    => C_WB_REG_DEFAULT
      )
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => WB_WBS_I,
      WB_WBS_O  => WB_WBS_O,
      WBS_REG_I => s_wbs_reg_i,
      WBS_REG_O => s_wbs_reg_o
      );

  INST_dna_read : entity work.dna_read
    generic map(
      G_DNA_SIZE      => C_DNA_PORT_SIZE,
      G_SIM_DNA_VALUE => C_SIM_DNA_VALUE)
    port map(
      clk_i         => WB_CLK,
      rst_i         => WB_RST,
      do_read_dna_i => s_dna_do_read,
      dna_value_o   => s_dna_value);

end architecture str;
