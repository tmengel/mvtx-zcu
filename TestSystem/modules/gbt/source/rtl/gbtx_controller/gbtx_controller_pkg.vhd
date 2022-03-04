-------------------------------------------------------------------------------
-- Title      : GBTx controller package
-- Project    :
-------------------------------------------------------------------------------
-- File       : gbtx_controller_pkg.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Author     : J. Schambach <Joachim.Schambach@cern.ch>
-- Company    : University of Texas at Austin
-------------------------------------------------------------------------------
-- Created    : 2017-07-25
-- Last update: 2018-10-11
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Common declarations for the GBTx controler
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Wishbone mapping:
--
--   0x00 -> GBTX_CONTROLLER_ENABLE : R/W
--                           Bit 0  : 1: Enables the GBTX controller [Default]
--   0x01 -> GBTX_RESET              : R/W
--                           Bit 0  : Resets the GBTX (negative logic)
--   [0x02:0x0B]-> SET_IDELAY_VALUE{01:89} : R/W
--                           [4:0]  : Delay value feed to the IDELAYE2
--   [0x0C:0x15]-> GET_IDELAY_VALUE{0:4}   : R/W
--                           [4:0]  : Delay value written into the IDELAYE2
--   0x16 -> IDELAY_LOAD            : W only
--                           Bit 0  : Loads the corresponding IDELAY value (pulse)
--   0x17 -> BITSLIP_RX_CONTROL     : R/W
--                           [2:0]  : BITSLIP on the RX side to be reached
--                           (automatically iterates until condition met)
--   0x18 -> BITSLIP_TX_CONTROL     : R/W
--                           [2:0]  : BITSLIP on the TX side to be reached
--   0x19 -> BITSLIP_LOAD           : W only
--                           Bit 0  : loads bitslip values for both RX and TX
--   0x1A -> TX_PATTERN_SELECTION   : R/W
--                           [1:0]  : Select the tx pattern to the GBTX0 (80 bits)
--                                      00: transmit data from FIFO
--                                      01: 4 times repeated pattern
--                                      10: static pattern 1
--                                      11: loopback
--   0x1B -> TX1_PATTERN_SELECTION  : R/W
--                           [1:0]  : Select the tx pattern to the GBTX1 (80 bits)
--                                      00: transmit data from FIFO
--                                      01: 4 times repeated pattern
--                                      10: static pattern 1
--                                      11: loopback
--   0x1D -> RXRDY_LOST_FLAG        : Latches a '1' when RXRDY goes to '0'
--                           Bit 0  : R - value of the latch
--                           Bit 15 : W only - resets the latch
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.gbtx_pkg.all;
use work.tmr_pkg.all;

package gbtx_controller_pkg is

  -----------------------------------------------------------------------------
  -- Wishbone address space
  -----------------------------------------------------------------------------
  type WB_ADD is (
    -- General purpose registers
    A_GBTX_CONTROLLER_ENABLE,           -- 0
    A_GBTX_RESET,                       -- 1
    -- rx side
    A_SET_IDELAY_VALUE0,                -- 2
    A_SET_IDELAY_VALUE1,                -- 3
    A_SET_IDELAY_VALUE2,                -- 4
    A_SET_IDELAY_VALUE3,                -- 5
    A_SET_IDELAY_VALUE4,                -- 6
    A_SET_IDELAY_VALUE5,                -- 7
    A_SET_IDELAY_VALUE6,                -- 8
    A_SET_IDELAY_VALUE7,                -- 9
    A_SET_IDELAY_VALUE8,                -- 10
    A_SET_IDELAY_VALUE9,                -- 11
    A_GET_IDELAY_VALUE0,                -- 12
    A_GET_IDELAY_VALUE1,                -- 13
    A_GET_IDELAY_VALUE2,                -- 14
    A_GET_IDELAY_VALUE3,                -- 15
    A_GET_IDELAY_VALUE4,                -- 16
    A_GET_IDELAY_VALUE5,                -- 17
    A_GET_IDELAY_VALUE6,                -- 18
    A_GET_IDELAY_VALUE7,                -- 19
    A_GET_IDELAY_VALUE8,                -- 20
    A_GET_IDELAY_VALUE9,                -- 21
    A_IDELAY_LOAD,                      -- 22
    A_BITSLIP_RX_VALUE,                 -- 23
    A_BITSLIP_TX_VALUE,                 -- 24
    A_BITSLIP_LOAD,                     -- 25
    -- tx side
    A_TX_PATTERN_SELECTION,             -- 26
    A_TX1_PATTERN_SELECTION,            -- 27
    -- SEU MONITOR
    A_MISMATCH,                         -- 28
    ---------------------------------------------------------------------------
    -- Latch for GBTX_RXRDY going low
    A_RXRDY_LOST_FLAG                   -- 29
   ---------------------------------------------------------------------------
    );

  -- Read/Write enable array
  constant C_WB_ADD_WE : t_wbs_reg_we_array(WB_ADD'pos(WB_ADD'high) downto 0) := (
    WB_ADD'pos(A_GBTX_CONTROLLER_ENABLE) => rw,
    WB_ADD'pos(A_GBTX_RESET)             => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE0)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE1)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE2)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE3)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE4)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE5)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE6)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE7)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE8)      => rw,
    WB_ADD'pos(A_SET_IDELAY_VALUE9)      => rw,
    WB_ADD'pos(A_GET_IDELAY_VALUE0)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE1)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE2)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE3)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE4)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE5)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE6)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE7)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE8)      => r,
    WB_ADD'pos(A_GET_IDELAY_VALUE9)      => r,
    WB_ADD'pos(A_IDELAY_LOAD)            => w,
    WB_ADD'pos(A_BITSLIP_RX_VALUE)       => rw,
    WB_ADD'pos(A_BITSLIP_TX_VALUE)       => rw,
    WB_ADD'pos(A_BITSLIP_LOAD)           => w,
    WB_ADD'pos(A_TX_PATTERN_SELECTION)   => rw,
    WB_ADD'pos(A_TX1_PATTERN_SELECTION)  => rw,
    WB_ADD'pos(A_MISMATCH)               => r,
    WB_ADD'pos(A_RXRDY_LOST_FLAG)        => rw
    );

  -----------------------------------------------------------------------------
  -- bit mapping
  -----------------------------------------------------------------------------

  -- GBTX_CONTROLLER_ENABLE bit mapping
  constant C_GBTX_CONTROLLER_ENABLE_bit : integer := 0;

  -- GBTX_RESET              bit mapping
  constant C_GBTX_RESET_bit : integer := 0;

  -- IDELAY_VALUE            bit mapping
  constant C_IDELAY_VALUE_bit : std_logic_vector(C_IDELAY_DELAY_WIDTH-1 downto 0) := (others => '0');

  -- IDELAY_LOAD            bit mapping
  constant C_IDELAY_LOAD_bit : integer := 0;

  -- BITSLIP_RX_CONTROL     bit mapping
  constant C_BITSLIP_VALUE_bit : std_logic_vector(2 downto 0) := (others => '0');

  -- IDELAY_LOAD            bit mapping
  constant C_BITSLIP_LOAD_bit : integer := 0;

  -- TX_PATTERN_SELECTION   bit mapping
  constant C_TX_PATTERN_SELECTION_bit : std_logic_vector(1 downto 0) := (others => '0');

  -- MISMATCH               bit mapping
  constant C_MISMATCH_bit_WISHBONE      : integer := 0;
  constant C_MISMATCH_bit_TX_HANDLER    : integer := 1;
  constant C_MISMATCH_bit_TX1_HANDLER   : integer := 2;
  constant C_MISMATCH_bit_RX_HANDLER    : integer := 3;
  constant C_MISMATCH_bit_BITSLIP_LOGIC : integer := 4;
  constant C_GBTX_MISMATCH_WIDTH        : integer := 5;

  -- RXRDY_FLAG             bit mapping
  constant C_RXRDY_LOST_FLAG_bit     : integer := 0;
  constant C_RXRDY_LOST_FLAG_RST_bit : integer := 15;

  -----------------------------------------------------------------------------
  -- TX pattern
  -----------------------------------------------------------------------------

  constant C_GBTX_TX_PATTERN_FIFO    : std_logic_vector(C_TX_PATTERN_SELECTION_bit'range) := "00";
  constant C_GBTX_TX_PATTERN_COUNTER : std_logic_vector(C_TX_PATTERN_SELECTION_bit'range) := "01";
  constant C_GBTX_TX_PATTERN_STATIC  : std_logic_vector(C_TX_PATTERN_SELECTION_bit'range) := "10";
  constant C_GBTX_TX_PATTERN_MIRROR  : std_logic_vector(C_TX_PATTERN_SELECTION_bit'range) := "11";

  ----------------------------------------------------------------------------
  -- IDELAY settings
  -----------------------------------------------------------------------------
  type t_idelay_values is array (0 to (C_GBTX_ELINKS_RX)-1) of std_logic_vector(C_IDELAY_VALUE_bit'range);
  constant C_IDELAY_DEFAULT        : std_logic_vector(C_IDELAY_VALUE_bit'range) := '1' & x"68";  --360
  constant C_IDELAY_VALUES_DEFAULT : t_idelay_values                            := (others => C_IDELAY_DEFAULT);
  type t_idelay_values_array is array (natural range <>) of t_idelay_values;  -- tmr

  constant C_IDELAY_READ_DEFAULT : t_idelay_values := (others => C_IDELAY_VALUE_bit);

  -----------------------------------------------------------------------------
  -- BITSLIP
  -----------------------------------------------------------------------------

  constant C_GBTX_BITSLIP_RX_VALUE_DEFAULT : std_logic_vector(C_BITSLIP_VALUE_bit'range) := std_logic_vector(to_unsigned(6, C_BITSLIP_VALUE_bit'length));
  constant C_GBTX_BITSLIP_TX_VALUE_DEFAULT : std_logic_vector(C_BITSLIP_VALUE_bit'range) := std_logic_vector(to_unsigned(4, C_BITSLIP_VALUE_bit'length));

  -----------------------------------------------------------------------------
  -- wishbone default settings
  -----------------------------------------------------------------------------
  constant C_WB_REG_DEFAULT : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0) := (
    WB_ADD'pos(A_GBTX_CONTROLLER_ENABLE) => wb_resize_bit('1', C_GBTX_RESET_bit),
    WB_ADD'pos(A_GBTX_RESET)             => wb_resize_bit('1', C_GBTX_RESET_bit),
    WB_ADD'pos(A_SET_IDELAY_VALUE0)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE1)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE2)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE3)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE4)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE5)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE6)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE7)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE8)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_SET_IDELAY_VALUE9)      => wb_resize(C_IDELAY_DEFAULT),
    WB_ADD'pos(A_IDELAY_LOAD)            => wb_resize_bit('1', C_IDELAY_LOAD_bit),
    WB_ADD'pos(A_BITSLIP_RX_VALUE)       => wb_resize(C_GBTX_BITSLIP_RX_VALUE_DEFAULT),
    WB_ADD'pos(A_BITSLIP_TX_VALUE)       => wb_resize(C_GBTX_BITSLIP_TX_VALUE_DEFAULT),
    WB_ADD'pos(A_BITSLIP_LOAD)           => wb_resize_bit('1', C_BITSLIP_LOAD_bit),
    WB_ADD'pos(A_TX_PATTERN_SELECTION)   => wb_resize(C_GBTX_TX_PATTERN_MIRROR),
    WB_ADD'pos(A_TX1_PATTERN_SELECTION)  => wb_resize(C_GBTX_TX_PATTERN_MIRROR),
    others                               => x"0000"
    );

  type t_wishbone_registers is record
    gbtx_controller_enable : std_logic;
    gbtx_reset_n           : std_logic;
    idelay_values          : t_idelay_values;
    idelay_load            : std_logic;
    bitslip_rx_value       : std_logic_vector(C_BITSLIP_VALUE_bit'range);
    bitslip_tx_value       : std_logic_vector(C_BITSLIP_VALUE_bit'range);
    bitslip_load           : std_logic;
    tx_pattern_selection   : std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
    tx1_pattern_selection  : std_logic_vector(C_TX_PATTERN_SELECTION_bit'range);
  end record;

  -----------------------------------------------------------------------------
  -- TMR
  -----------------------------------------------------------------------------

  constant C_WISHBONE_REGISTERS_TOT_WIDTH : integer := 4 + 2*C_BITSLIP_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + C_GBTX_ELINKS_RX*C_IDELAY_VALUE_bit'length;
  constant C_WISHBONE_bit_ENABLE          : integer := C_WISHBONE_REGISTERS_TOT_WIDTH-1;
  constant C_WISHBONE_bit_RST             : integer := C_WISHBONE_REGISTERS_TOT_WIDTH-2;
  constant C_WISHBONE_bit_LOAD_IDELAY     : integer := C_WISHBONE_REGISTERS_TOT_WIDTH-3;
  constant C_WISHBONE_bit_LOAD_BITSLIP    : integer := C_WISHBONE_REGISTERS_TOT_WIDTH-4;

  constant C_WISHBONE_IDELAY9_range               : std_logic_vector(10*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 9*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length) := (others => '0');
  constant C_WISHBONE_IDELAY8_range               : std_logic_vector(9*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 8*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY7_range               : std_logic_vector(8*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 7*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY6_range               : std_logic_vector(7*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 6*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY5_range               : std_logic_vector(6*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 5*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY4_range               : std_logic_vector(5*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 4*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY3_range               : std_logic_vector(4*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 3*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY2_range               : std_logic_vector(3*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 2*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY1_range               : std_logic_vector(2*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 1*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_IDELAY0_range               : std_logic_vector(1*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 0*C_IDELAY_VALUE_bit'length + 2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)  := (others => '0');
  constant C_WISHBONE_TX1_PATTERN_SELECTION_range : std_logic_vector(2*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 1*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)                                                              := (others => '0');
  constant C_WISHBONE_TX_PATTERN_SELECTION_range  : std_logic_vector(1*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length -1 downto 0*C_TX_PATTERN_SELECTION_bit'length + 2*C_BITSLIP_VALUE_bit'length)                                                              := (others => '0');
  constant C_WISHBONE_BITSLIP_TX_VALUE_range      : std_logic_vector(2*C_BITSLIP_VALUE_bit'length -1 downto C_BITSLIP_VALUE_bit'length)                                                                                                                                            := (others => '0');
  constant C_WISHBONE_BITSLIP_RX_VALUE_range      : std_logic_vector(C_BITSLIP_VALUE_bit'length -1 downto 0)                                                                                                                                                                       := (others => '0');

  type t_wishbone_registers_tmr is array (0 to C_K_TMR-1) of t_wishbone_registers;
  type t_slv_wishbone_registers_tmr is array (0 to C_K_TMR-1) of std_logic_vector(C_WISHBONE_REGISTERS_TOT_WIDTH-1 downto 0);

  -----------------------------------------------------------------------------
  -- functions definitions
  -----------------------------------------------------------------------------

  function f_to_std_logic_vector (constant wishbone_registers : t_wishbone_registers) return std_logic_vector;

  function f_to_wishbone_register (constant in_data : std_logic_vector(C_WISHBONE_REGISTERS_TOT_WIDTH-1 downto 0)) return t_wishbone_registers;

end package gbtx_controller_pkg;

package body gbtx_controller_pkg is

  function f_to_std_logic_vector (
    constant wishbone_registers : t_wishbone_registers)
    return std_logic_vector is
    variable v_output_data : std_logic_vector(C_WISHBONE_REGISTERS_TOT_WIDTH-1 downto 0);
  begin
    v_output_data(C_WISHBONE_bit_ENABLE)       := wishbone_registers.gbtx_controller_enable;
    v_output_data(C_WISHBONE_bit_RST)          := wishbone_registers.gbtx_reset_n;
    v_output_data(C_WISHBONE_bit_LOAD_IDELAY)  := wishbone_registers.idelay_load;
    v_output_data(C_WISHBONE_bit_LOAD_BITSLIP) := wishbone_registers.bitslip_load;

    v_output_data(C_WISHBONE_BITSLIP_RX_VALUE_range'range)      := wishbone_registers.bitslip_rx_value;
    v_output_data(C_WISHBONE_BITSLIP_TX_VALUE_range'range)      := wishbone_registers.bitslip_tx_value;
    v_output_data(C_WISHBONE_TX_PATTERN_SELECTION_range'range)  := wishbone_registers.tx_pattern_selection;
    v_output_data(C_WISHBONE_TX1_PATTERN_SELECTION_range'range) := wishbone_registers.tx1_pattern_selection;
    v_output_data(C_WISHBONE_IDELAY0_range'range)               := wishbone_registers.idelay_values(0);
    v_output_data(C_WISHBONE_IDELAY1_range'range)               := wishbone_registers.idelay_values(1);
    v_output_data(C_WISHBONE_IDELAY2_range'range)               := wishbone_registers.idelay_values(2);
    v_output_data(C_WISHBONE_IDELAY3_range'range)               := wishbone_registers.idelay_values(3);
    v_output_data(C_WISHBONE_IDELAY4_range'range)               := wishbone_registers.idelay_values(4);
    v_output_data(C_WISHBONE_IDELAY5_range'range)               := wishbone_registers.idelay_values(5);
    v_output_data(C_WISHBONE_IDELAY6_range'range)               := wishbone_registers.idelay_values(6);
    v_output_data(C_WISHBONE_IDELAY7_range'range)               := wishbone_registers.idelay_values(7);
    v_output_data(C_WISHBONE_IDELAY8_range'range)               := wishbone_registers.idelay_values(8);
    v_output_data(C_WISHBONE_IDELAY9_range'range)               := wishbone_registers.idelay_values(9);
    return v_output_data;
  end;

  function f_to_wishbone_register (
    constant in_data : std_logic_vector(C_WISHBONE_REGISTERS_TOT_WIDTH-1 downto 0))
    return t_wishbone_registers is
    variable v_output_data : t_wishbone_registers;
  begin
    v_output_data.gbtx_controller_enable := in_data(C_WISHBONE_bit_ENABLE);
    v_output_data.gbtx_reset_n           := in_data(C_WISHBONE_bit_RST);
    v_output_data.idelay_load            := in_data(C_WISHBONE_bit_LOAD_IDELAY);
    v_output_data.bitslip_load           := in_data(C_WISHBONE_bit_LOAD_BITSLIP);
    v_output_data.bitslip_rx_value       := in_data(C_WISHBONE_BITSLIP_RX_VALUE_range'range);
    v_output_data.bitslip_tx_value       := in_data(C_WISHBONE_BITSLIP_TX_VALUE_range'range);
    v_output_data.tx_pattern_selection   := in_data(C_WISHBONE_TX_PATTERN_SELECTION_range'range);
    v_output_data.tx1_pattern_selection  := in_data(C_WISHBONE_TX1_PATTERN_SELECTION_range'range);
    v_output_data.idelay_values(0)       := in_data(C_WISHBONE_IDELAY0_range'range);
    v_output_data.idelay_values(1)       := in_data(C_WISHBONE_IDELAY1_range'range);
    v_output_data.idelay_values(2)       := in_data(C_WISHBONE_IDELAY2_range'range);
    v_output_data.idelay_values(3)       := in_data(C_WISHBONE_IDELAY3_range'range);
    v_output_data.idelay_values(4)       := in_data(C_WISHBONE_IDELAY4_range'range);
    v_output_data.idelay_values(5)       := in_data(C_WISHBONE_IDELAY5_range'range);
    v_output_data.idelay_values(6)       := in_data(C_WISHBONE_IDELAY6_range'range);
    v_output_data.idelay_values(7)       := in_data(C_WISHBONE_IDELAY7_range'range);
    v_output_data.idelay_values(8)       := in_data(C_WISHBONE_IDELAY8_range'range);
    v_output_data.idelay_values(9)       := in_data(C_WISHBONE_IDELAY9_range'range);
    return v_output_data;
  end;

end package body gbtx_controller_pkg;
