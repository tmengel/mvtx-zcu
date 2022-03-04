-------------------------------------------------------------------------------
-- Title      : GBTx controller package
-- Project    :
-------------------------------------------------------------------------------
-- File       : mmcm_monitor_pkg.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-25
-- Last update: 2017-11-24
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Common declarations for the GBTx controler
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Wishbone mapping:
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.tmr_pkg.all;

package mmcm_monitor_pkg is

  component mmcm_monitor is
    generic (
      G_CLKFBOUT_MULT_F : real);
    port (
      MMCM_CLK_IN : in  std_logic;
      RESET       : in  std_logic;
      WB_CLK      : in  std_logic;
      WB_RST      : in  std_logic;
      WB_WBS_I    : in  t_wbs_i_array(0 to C_K_TMR-1);
      WB_WBS_O    : out t_wbs_o_array(0 to C_K_TMR-1));
  end component mmcm_monitor;

  component mmcm_monitor_dut is
    generic (
      G_USER_CLOCK_NUMBER : integer;
      G_CLKFBOUT_MULT_F   : real);
    port (
      CLK_IN       : in  std_logic;
      RESET        : in  std_logic;
      WB_CLK       : in  std_logic;
      LOCKED       : out std_logic;
      USER_CLK_OUT : out std_logic_vector(G_USER_CLOCK_NUMBER-1 downto 0));
  end component mmcm_monitor_dut;

  constant C_MMCM_MONITORS     : natural := 6;
  constant C_USER_CLOCK_NUMBER : natural := 7;
  constant C_COUNTER_BIT_WIDTH : natural := 35;

  -----------------------------------------------------------------------------
  -- MMCM clock frequencies
  -----------------------------------------------------------------------------
  -- see mmcm_monitor_dut
  -- f_{CLK_IN} $\times$ CLKFBOUT_MULT_F $\times$ DIVCLK_DIVIDE $\times$ CLKOUT0_DIVIDE_F
  -- = 160 * 6.25 / (2*6) = 83.33 MHz
  type t_mmcm_mult_array is array (0 to C_MMCM_MONITORS-1) of real;
  constant C_MMCM_MULT_ARRAY : t_mmcm_mult_array := (6.000,
                                                     6.000,
                                                     6.000,
                                                     --6.000,
                                                     --6.000,
                                                     --6.250,
                                                     6.250,
                                                     6.250,
                                                     6.250
                                                     );

  -----------------------------------------------------------------------------
  -- Wishbone address calculations
  -----------------------------------------------------------------------------

  constant C_RESET_COUNTERS          : integer := 8;
  constant C_GET_COUNTER_CLK_0_FIRST : integer := C_RESET_COUNTERS + 1;
  constant C_GET_COUNTER_CLK_0_LAST  : integer := C_GET_COUNTER_CLK_0_FIRST + C_K_TMR -1;
  constant C_GET_COUNTER_CLK_N_FIRST : integer := C_GET_COUNTER_CLK_0_FIRST + C_K_TMR*(C_USER_CLOCK_NUMBER-1) + 1 -1;
  constant C_GET_COUNTER_CLK_N_LAST  : integer := C_GET_COUNTER_CLK_0_FIRST + C_K_TMR*C_USER_CLOCK_NUMBER -1;

  -----------------------------------------------------------------------------
  -- Wishbone address space
  -----------------------------------------------------------------------------
  type t_WB_ADDS is record
    GET_LOCK_COUNTER        : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    LATCH_COUNTERS          : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    RESET_COUNTERS          : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    GET_COUNTER_CLK_0_FIRST : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    GET_COUNTER_CLK_0_LAST  : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    GET_COUNTER_CLK_N_FIRST : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    GET_COUNTER_CLK_N_LAST  : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    -- SEU MONITOR
    MISMATCH_LSB            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MISMATCH_MSB            : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MISMATCH_COUNTER        : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MISMATCH_2ND_LSB        : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MISMATCH_2ND_MSB        : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MISMATCH_2ND_COUNTER    : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    ---------------------------------------------------------------------------
    NUM_REGS                : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  end record t_WB_ADDS;

  constant WB_ADD : t_WB_ADDS := (GET_LOCK_COUNTER        => x"00",
                                  MISMATCH_LSB            => x"01",
                                  MISMATCH_MSB            => x"02",
                                  MISMATCH_2ND_LSB        => x"03",
                                  MISMATCH_2ND_MSB        => x"04",
                                  MISMATCH_COUNTER        => x"05",
                                  MISMATCH_2ND_COUNTER    => x"06",
                                  LATCH_COUNTERS          => x"07",
                                  RESET_COUNTERS          => std_logic_vector(to_unsigned(C_RESET_COUNTERS, WB_ADDS_WIDTH)),
                                  GET_COUNTER_CLK_0_FIRST => std_logic_vector(to_unsigned(C_GET_COUNTER_CLK_0_FIRST, WB_ADDS_WIDTH)),
                                  GET_COUNTER_CLK_0_LAST  => std_logic_vector(to_unsigned(C_GET_COUNTER_CLK_0_LAST, WB_ADDS_WIDTH)),
                                  GET_COUNTER_CLK_N_FIRST => std_logic_vector(to_unsigned(C_GET_COUNTER_CLK_N_FIRST, WB_ADDS_WIDTH)),
                                  GET_COUNTER_CLK_N_LAST  => std_logic_vector(to_unsigned(C_GET_COUNTER_CLK_N_LAST, WB_ADDS_WIDTH)),
                                  NUM_REGS                => std_logic_vector(to_unsigned(C_GET_COUNTER_CLK_N_LAST + 1, WB_ADDS_WIDTH))
                                  );

  -----------------------------------------------------------------------------
  -- bit mapping
  -----------------------------------------------------------------------------

  -- MISMATCH               bit mapping
  constant C_bit_CLK_0                   : integer := 0;
  constant C_bit_CLK_N                   : integer := C_USER_CLOCK_NUMBER -1;
  constant C_bit_lock                    : integer := C_bit_CLK_N + 1;
  constant C_MMCM_MONITOR_MISMATCH_WIDTH : integer := C_bit_lock + 1;

  -----------------------------------------------------------------------------
  -- type definition
  -----------------------------------------------------------------------------

  type t_clk_counters_array is array (0 to C_K_TMR*C_USER_CLOCK_NUMBER-1) of std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  type t_clk_counters_tmr_array is array (0 to C_K_TMR-1) of t_clk_counters_array;

  -----------------------------------------------------------------------------
  -- wishbone registers
  -----------------------------------------------------------------------------

  type t_wishbone_registers is record
    counters_latch     : std_logic_vector(C_USER_CLOCK_NUMBER-1 downto 0);
    counters_reset     : std_logic_vector(C_USER_CLOCK_NUMBER-1 downto 0);
    lock_counter_latch : std_logic;
    lock_counter_reset : std_logic;
  end record;

  constant C_WISHBONE_DEFAULTS : t_wishbone_registers := (counters_latch     => (others => '0'),
                                                          counters_reset     => (others => '0'),
                                                          lock_counter_latch => '0',
                                                          lock_counter_reset => '0'
                                                          );

  -----------------------------------------------------------------------------
  -- function definitions
  -----------------------------------------------------------------------------

  function f_get_address_int (
    constant wb_address           : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0);  -- actual_address
    constant module_start_address : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0)  -- start address of module
    ) return natural;

end package mmcm_monitor_pkg;

package body mmcm_monitor_pkg is

  function f_get_address_int (
    constant wb_address           : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0);  -- actual_address
    constant module_start_address : in std_logic_vector(WB_ADDS_WIDTH-1 downto 0)  -- start address of module
    ) return natural is
    variable v_result : integer range 0 to 2**wb_address'length-1;
  begin
    if unsigned(wb_address) < unsigned(module_start_address) then
      v_result := 0;
    else
      v_result := to_integer(unsigned(wb_address) - unsigned(module_start_address));
    end if;
    return v_result;
  end function f_get_address_int;

end package body mmcm_monitor_pkg;
