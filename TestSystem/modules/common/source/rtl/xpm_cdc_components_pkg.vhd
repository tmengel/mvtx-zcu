-------------------------------------------------------------------------------
-- Title      : XPM CDC Components
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : xpm_cdc_components_pkg.vhd
-- Author     : Matthias Bonora  <matthias.bonora@cern.ch>
-- Company    : CERN / University of Salzburg
-- Created    : 2017-03-09
-- Last update: 2018-03-21
-- Platform   : CERN OS7, Xilinx Vivado 2015.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Components declaration for XPM CDC blocks. Use this instead of
-- xpm.vcomponents.
-- Add XPM_CDC components manually due to binding error
-- with Cadence Incisive version 14.1.s025
-- Manually added Generic VERSION
-- TODO: Test if necessary after upgrade to 15.2
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-09  1.0      MB      Created
-- 2018-02-02  1.1      AV      Updated for 2017.4
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package xpm_cdc_components_pkg is

  component xpm_cdc_single
    generic (
      DEST_SYNC_FF   : integer range 2 to 10 := 4; -- Number of register stages used to synchronize signal in the destination clock domain.
      INIT_SYNC_FF   : integer range 0 to 1  := 0; -- Enable behavioral simulation initialization values on synchronization registers.
      SIM_ASSERT_CHK : integer range 0 to 1  := 0; -- Enable simulation message reporting, messages related to potential misuse will be reported.
      SRC_INPUT_REG  : integer range 0 to 1  := 1; -- Register input (src_in) once using src_clk.
      VERSION        : integer := 0
      );
    port (
      src_clk  : in  std_logic; -- Input clock signal for src_in if SRC_INPUT_REG = 1. Unused when SRC_INPUT_REG = 0. Tie 0 when unused.
      src_in   : in  std_logic; -- Input signal to be synchronized to dest_clk domain.
      dest_clk : in  std_logic; -- Clock signal for the destination clock domain.
      dest_out : out std_logic  -- src_in synchronized to the destination clock domain. This output is registered.
      );
  end component;
  component xpm_cdc_array_single
    generic (
      DEST_SYNC_FF   : integer range 2 to 10 := 4; -- Number of register stages used to synchronize signal in the destination clock domain.
      INIT_SYNC_FF   : integer range 0 to 1  := 0; -- Enable behavioral simulation initialization values on synchronization registers.
      SIM_ASSERT_CHK : integer range 0 to 1  := 0; -- Enable simulation message reporting, messages related to potential misuse will be reported.
      SRC_INPUT_REG  : integer range 0 to 1  := 1; -- Register input (src_in) once using src_clk.
      VERSION        : integer := 0;
      WIDTH          : integer range 1 to 1024 := 2 -- Width of single-bit array (src_in) that will be synchronized to destination clock domain.
      );
    port (
      src_clk  : in  std_logic;                          -- Input clock signal for src_in if SRC_INPUT_REG = 1. Unused when SRC_INPUT_REG = 0. Tie 0 when unused.
      src_in   : in  std_logic_vector(WIDTH-1 downto 0); -- Input single-bit array to be synchronized to destination clock domain. It is assumed that each
                                                         -- bit of the array is unrelated to the others. This is reflected in the constraints applied to this macro.
                                                         -- To transfer a binary value losslessly across the two clock domains, use the XPM_CDC_GRAY macro instead
      dest_clk : in  std_logic;                          -- Clock signal for the destination clock domain.
      dest_out : out std_logic_vector(WIDTH-1 downto 0)  -- src_in synchronized to the destination clock domain. This output is registered.
      );
  end component;

  component xpm_cdc_async_rst
    generic (
      DEST_SYNC_FF    : integer range 2 to 10 := 4; -- Number of register stages used to synchronize signal in the destination clock domain. This parameter also
                                                    -- determines the minimum width of the asserted reset signal.
      INIT_SYNC_FF    : integer range 0 to 1  := 0; -- Enable behavioral simulation initialization values on synchronization registers
      RST_ACTIVE_HIGH : integer range 0 to 1  := 0; -- Defines the polarity of the asynchronous reset signal.
      VERSION         : integer := 0
      );
    port (
      src_arst  : in  std_logic; -- Source asynchronous reset signal.
      dest_clk  : in  std_logic; -- Clock signal for the destination clock domain.
      dest_arst : out std_logic  -- The src_arst asynchronous reset signal synchronized to destination clock domain. This output is registered.
                                 -- NOTE: The signal asserts asynchronously but deasserts synchronously to dest_clk. The width of the reset signal is at least
                                 -- (DEST_SYNC_FF*dest_clk) period.
      );
  end component;

  component xpm_cdc_sync_rst
    generic (
      DEST_SYNC_FF   : integer range 2 to 10 := 4; -- Number of register stages used to synchronize the signal in the destination clock domain.
      INIT           : integer range 0 to 1  := 1; -- Initializes synchronization registers to value.
      INIT_SYNC_FF   : integer range 0 to 1  := 0; -- Enable behavioral simulation initialization values on synchronization registers.
      SIM_ASSERT_CHK : integer range 0 to 1  := 0; -- Enable simulation message reporting, messages related to potential misuse will be reported.
      VERSION        : integer := 0
      );
    port (
      src_rst  : in  std_logic; -- Source reset signal.
      dest_clk : in  std_logic; -- Clock signal for the destination clock domain.
      dest_rst : out std_logic  -- src_rst synchronized to the destination clock domain. This output is registered.
      );
  end component;

  component xpm_cdc_pulse
    generic (
      DEST_SYNC_FF   : integer range 2 to 10 := 4; -- Number of register stages used to synchronize signal in the destination clock domain.
      INIT_SYNC_FF   : integer range 0 to 1  := 0; -- Enable behavioral simulation initialization values on synchronization registers.
      REG_OUTPUT     : integer range 0 to 1  := 0; -- Enable registered output.
      RST_USED       : integer range 0 to 1  := 1; -- Resets implemented. When RST_USED = 0, src_pulse input must always be defined during
                                                   -- simulation since there is no reset logic to recover from an x-propagating through the module.
      SIM_ASSERT_CHK : integer range 0 to 1  := 0; -- Enable simulation message reporting, messages related to potential misuse will be reported.
      VERSION        : integer := 0
      );
    port (
      src_clk    : in  std_logic; -- Source clock.
      src_pulse  : in  std_logic; -- The rising edge of this signal initiates a pulse transfer to the destination clock domain. The minimum gap between each
                                  -- pulse transfer must be at least 2*(larger(src_clk period, dest_clk period)). This is measured between the falling edge of a src_pulse to the
                                  -- rising edge of the next src_pulse. This minimum gap will guarantee that each rising edge of src_pulse will generate a pulse the size of one
                                  -- dest_clk period in the destination clock domain. When RST_USED = 1, pulse transfers will not be guaranteed while src_rst and/or dest_rst are asserted.
      dest_clk   : in  std_logic; -- Destination clock.
      src_rst    : in  std_logic; -- Resets all logic in the source clock domain. Unused when RST_USED = 0 To fully reset the macro, src_rst and dest_rst must be asserted
                                  -- simultaneously for at least (DEST_SYNC_FF+2)*dest_clk_period) + (2*src_clk_period)
      dest_rst   : in  std_logic; -- Resets all logic in destination clock domain. Unused when RST_USED = 0
      dest_pulse : out std_logic  -- Outputs a pulse the size of one dest_clk period when a pulse transfer is correctly initiated on src_pulse input. This output is combinatorial.
      );
  end component;

----- component  xpm_fifo_async -----

component xpm_fifo_async
  generic (
    FIFO_MEMORY_TYPE         : string   := "BRAM"; -- Designates the fifo memory primitive (resource type) to use.
    ECC_MODE                 : string   := "NO_ECC"; -- "no_ecc": Disables ECC. "en_ecc": Enables both ECC Encoder and Decoder.
    RELATED_CLOCKS           : integer range 0 to 1  := 0; -- Specifies if the wr_clk and rd_clk are related, having the same source but different clock ratios.

    FIFO_WRITE_DEPTH         : integer range 16 to 4*1024*1024  := 2048; -- Defines the FIFO write depth. Must be a power of two.
    WRITE_DATA_WIDTH         : integer range 1 to 4096 := 32; -- Specifies the width of the port [A] output data port, dout[a].
    WR_DATA_COUNT_WIDTH      : integer  := 12; -- Specifies the width of wr_data_count. The default value of this parameter may not work if the FIFO_WRITE_DEPTH values is non-default. Range 1 to log2(FIFO_WRITE_DEPTH)+1
    PROG_FULL_THRESH         : integer  := 10; -- Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.
    FULL_RESET_VALUE         : integer range 0 to 1 := 0; -- Sets full and prog_full to FULL_RESET_VALUE during reset.
    USE_ADV_FEATURES         : string   := "0707"; -- Enables [12:8] = data_valid, almost_empty, rd_data_count, prog_empty, underflow, [4:0] = wr_ack, almost_full, wr_data_count, prog_full, overflow features

    READ_MODE                : string   := "STD"; -- "std": standard read mode "fwft": First-Word-Fall-Through read mode
    FIFO_READ_LATENCY        : integer  := 1;  -- Number of output register stages in the read data path. If READ_MODE = "fwft", then the only applicable value is 0. Since the default
                                               -- is 1, then you must include this attribute if READ_MODE = "fwft".
    READ_DATA_WIDTH          : integer  := 32; -- Specifies the width of the read data port, dout.
    RD_DATA_COUNT_WIDTH      : integer  := 12; -- Specifies the width of rd_data_count. The default value of this parameter may not work if the FIFO_READ_DEPTH values is non-default.
    PROG_EMPTY_THRESH        : integer  := 10; -- Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.
    DOUT_RESET_VALUE         : string   := "0"; -- Reset value of read data path. Valid hexadecimal value
    CDC_SYNC_STAGES          : integer range 2 to 8 := 2; -- Specifies the number of synchronization stages on the CDC path. CDC_SYNC_STAGES must be <= 4 if FIFO_WRITE_DEPTH is 16.

    WAKEUP_TIME              : integer  := 0; -- 0: Disable sleep. 2: Use Sleep Pin.
    VERSION                  : integer  := 0
  );
  port (

    -- Common module ports
    sleep          : in std_logic;  -- Dynamic power gating. If sleep is active, the FIFO is in power saving mode.
    rst            : in std_logic;  -- Reset: A (synchronous to wr_clk) signal that initializes all internal pointers and output registers. The outputs may have 'X' for 3
                                    -- (CDC_SYNC_STAGES+2) slowest clock cycles at the beginning of the simulation if the reset is not applied to FIFO. Reset must be applied only
                                    -- when both wr_clk and rd_clk are stable and free-running. Violating this could cause unexpected behavior.

    -- Write Domain ports
    wr_clk         : in std_logic; -- Write Clock: All signals on the write domain are synchronous to this clock. Write Clock must be a free-running clock.
    wr_en          : in std_logic; -- Write Enable: If the FIFO is not full, asserting wr_en causes data (on din) to be written to the FIFO. wr_en must be active-Low when
                                   -- rst or wr_rst_busy or wr_rst_busy is active-High.
    din            : in std_logic_vector(WRITE_DATA_WIDTH-1 downto 0); -- Data Input: The input data bus used when writing to the FIFO.
    full           : out std_logic; -- Full Flag: When asserted, indicates that the FIFO is full. Write requests are ignored when the FIFO is full,
                                    -- initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
    prog_full      : out std_logic; -- Programmable Full: Asserted when the number of words in the FIFO (wr_data_count) is greater than or equal to the PROG_FULL_THRESH. It
                                    -- is de-asserted when the number of words in the FIFO (wr_data_count) is less than the PROG_FULL_THRESH.
    wr_data_count  : out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0); -- Write Data Count: Indicates the number of words written into the FIFO. The count is guaranteed to
                                    -- never under-report the number of words in the FIFO, to ensure you never overflow the FIFO.
    overflow       : out std_logic; -- Overflow: Indicates that a write request (wr_en) during the prior clock cycle was rejected, because the FIFO is full. Overflowing the FIFO is
                                    -- not destructive to the contents of the FIFO.
    wr_rst_busy    : out std_logic; -- Write Reset Busy: When asserted, indicates that the write domain is in reset state.
    almost_full    : out std_logic; -- Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
    wr_ack         : out std_logic; -- Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.

    -- Read Domain ports
    rd_clk         : in std_logic;  -- Read Clock: All signals on the read domain are synchronous to this clock. Read clock must be a free-running clock.
    rd_en          : in std_logic;  -- Read Enable: If the FIFO is not empty, asserting rd_en causes data to be read from the FIFO (output on dout). rd_en must be active-Low when
                                    -- rst or wr_rst_busy or rd_rst_busy is active high
    dout           : out std_logic_vector(READ_DATA_WIDTH-1 downto 0); -- Data Output: The output data bus is driven when reading the FIFO.
    empty          : out std_logic; -- Empty Flag: When asserted, empty indicates that the FIFO is empty. Read requests are ignored when the FIFO is empty, so initiating a read
                                    -- while empty is not destructive to the FIFO.
    prog_empty     : out std_logic; -- Programmable Empty: Asserted when the number of words in the FIFO (rd_data_count) is less than or equal to the PROG_EMPTY_THRESH.
                                    -- prog_empty is de-asserted when the number of words in the FIFO (rd_data_count) exceeds the PROG_EMPTY_THRESH.
    rd_data_count  : out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0); -- Read Data Count: Indicates the number of words available in the FIFO for reading. The count is
                                    -- guaranteed to never over-report the number of words available for reading, to ensure that you do not underflow the FIFO.
    underflow      : out std_logic; -- Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Underflowing the
                                    -- FIFO is not destructive to the FIFO
    rd_rst_busy    : out std_logic; -- Read Reset Busy: When asserted, rd_ret_busy indicates that the read domain is in reset state.
    almost_empty   : out std_logic; -- Almost Empty: When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
    data_valid     : out std_logic; -- Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).

    -- ECC Related ports
    injectsbiterr  : in std_logic;  -- Asserting this signal along with wr_en injects a single bit error if the ECC feature is used.
    injectdbiterr  : in std_logic;  -- Asserting this signal along with wr_en injects a double bit error if the ECC feature is used.
    sbiterr        : out std_logic; -- Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
    dbiterr        : out std_logic  -- Double Bit Error: Indicates that the ECC decoder detected a double-bit error and the data from the FIFO core is corrupted.
  );
end component;

----- component  xpm_fifo_sync -----

component xpm_fifo_sync
  generic (
    FIFO_MEMORY_TYPE         : string   := "BRAM"; -- Designates the fifo memory primitive (resource type) to use.
    ECC_MODE                 : string   := "NO_ECC"; -- "no_ecc": Disables ECC. "en_ecc": Enables both ECC Encoder and Decoder.

    FIFO_WRITE_DEPTH         : integer range 16 to 4*1024*1024  := 2048; -- Defines the FIFO write depth. Must be a power of two.
    WRITE_DATA_WIDTH         : integer range 1 to 4096 := 32; -- Specifies the width of the port [A] output data port, dout[a].
    WR_DATA_COUNT_WIDTH      : integer  := 12; -- Specifies the width of wr_data_count. The default value of this parameter may not work if the FIFO_WRITE_DEPTH values is non-default. Range 1 to log2(FIFO_WRITE_DEPTH)+1
    PROG_FULL_THRESH         : integer  := 10; -- Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.
    FULL_RESET_VALUE         : integer range 0 to 1 := 0; -- Sets full and prog_full to FULL_RESET_VALUE during reset.
    USE_ADV_FEATURES         : string   := "0707"; -- Enables [12:8] = data_valid, almost_empty, rd_data_count, prog_empty, underflow, [4:0] = wr_ack, almost_full, wr_data_count, prog_full, overflow features

    READ_MODE                : string   := "STD"; -- "std": standard read mode "fwft": First-Word-Fall-Through read mode
    FIFO_READ_LATENCY        : integer  := 1;  -- Number of output register stages in the read data path. If READ_MODE = "fwft", then the only applicable value is 0. Since the default
                                               -- is 1, then you must include this attribute if READ_MODE = "fwft".
    READ_DATA_WIDTH          : integer  := 32; -- Specifies the width of the read data port, dout.
    RD_DATA_COUNT_WIDTH      : integer  := 12; -- Specifies the width of rd_data_count. The default value of this parameter may not work if the FIFO_READ_DEPTH values is non-default.
    PROG_EMPTY_THRESH        : integer  := 10; -- Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.
    DOUT_RESET_VALUE         : string   := "0"; -- Reset value of read data path. Valid hexadecimal value

    WAKEUP_TIME              : integer  := 0; -- 0: Disable sleep. 2: Use Sleep Pin.
    VERSION                  : integer  := 0
  );
  port (

    -- Common module ports
    sleep          : in std_logic;  -- Dynamic power gating. If sleep is active, the FIFO is in power saving mode.
    rst            : in std_logic;  -- Reset: A synchronous reset (synchronous to wr_clk) signal that initializes all internal pointers and output registers. The outputs may
                                    -- have 'X' for (CDC_SYNC_STAGES+2) slowest clock cycles at the beginning of the simulation.

    -- Write Domain ports
    wr_clk         : in std_logic; -- Write Clock: All signals on the write domain are synchronous to this clock. Write Clock must be a free-running clock.
    wr_en          : in std_logic; -- Write Enable: If the FIFO is not full, asserting wr_en causes data (on din) to be written to the FIFO. wr_en must be active-Low when
                                   -- rst or wr_rst_busy or wr_rst_busy is active-High.
    din            : in std_logic_vector(WRITE_DATA_WIDTH-1 downto 0); -- Data Input: The input data bus used when writing to the FIFO.
    full           : out std_logic; -- Full Flag: When asserted, indicates that the FIFO is full. Write requests are ignored when the FIFO is full,
                                    -- initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
    prog_full      : out std_logic; -- Programmable Full: Asserted when the number of words in the FIFO (wr_data_count) is greater than or equal to the PROG_FULL_THRESH. It
                                    -- is de-asserted when the number of words in the FIFO (wr_data_count) is less than the PROG_FULL_THRESH.
    wr_data_count  : out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0); -- Write Data Count: Indicates the number of words written into the FIFO. The count is guaranteed to
                                    -- never under-report the number of words in the FIFO, to ensure you never overflow the FIFO.
    overflow       : out std_logic; -- Overflow: Indicates that a write request (wr_en) during the prior clock cycle was rejected, because the FIFO is full. Overflowing the FIFO is
                                    -- not destructive to the contents of the FIFO.
    wr_rst_busy    : out std_logic; -- Write Reset Busy: When asserted, indicates that the write domain is in reset state.
    almost_full    : out std_logic; -- Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
    wr_ack         : out std_logic; -- Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.

    -- Read Domain ports
    rd_en          : in std_logic;  -- Read Enable: If the FIFO is not empty, asserting rd_en causes data to be read from the FIFO (output on dout). rd_en must be active-Low when
                                    -- rst or wr_rst_busy or rd_rst_busy is active high
    dout           : out std_logic_vector(READ_DATA_WIDTH-1 downto 0); -- Data Output: The output data bus is driven when reading the FIFO.
    empty          : out std_logic; -- Empty Flag: When asserted, empty indicates that the FIFO is empty. Read requests are ignored when the FIFO is empty, so initiating a read
                                    -- while empty is not destructive to the FIFO.
    prog_empty     : out std_logic; -- Programmable Empty: Asserted when the number of words in the FIFO (rd_data_count) is less than or equal to the PROG_EMPTY_THRESH.
                                    -- prog_empty is de-asserted when the number of words in the FIFO (rd_data_count) exceeds the PROG_EMPTY_THRESH.
    rd_data_count  : out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0); -- Read Data Count: Indicates the number of words available in the FIFO for reading. The count is
                                    -- guaranteed to never over-report the number of words available for reading, to ensure that you do not underflow the FIFO.
    underflow      : out std_logic; -- Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Underflowing the
                                    -- FIFO is not destructive to the FIFO
    rd_rst_busy    : out std_logic; -- Read Reset Busy: When asserted, rd_ret_busy indicates that the read domain is in reset state.
    almost_empty   : out std_logic; -- Almost Empty: When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
    data_valid     : out std_logic; -- Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).

    -- ECC Related ports
    injectsbiterr  : in std_logic;  -- Asserting this signal along with wr_en injects a single bit error if the ECC feature is used.
    injectdbiterr  : in std_logic;  -- Asserting this signal along with wr_en injects a double bit error if the ECC feature is used.
    sbiterr        : out std_logic; -- Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
    dbiterr        : out std_logic  -- Double Bit Error: Indicates that the ECC decoder detected a double-bit error and the data from the FIFO core is corrupted.
  );
end component;


end package xpm_cdc_components_pkg;
