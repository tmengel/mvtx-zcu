-- $Id$
-------------------------------------------------------------------------------
-- Title      : I2C Interface - Test Bench
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : i2c_master_top_tb.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2015-12-14
-- Last update: 2017-06-28
-- Platform   : Modelsim SE 10.1c (32bit)
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Test bench for the I2C module from opencores.
--              Uses the Bitvis Utility Library 2.6.0 (from www.bitvis.no)
--              See documentation in the Bitvis distribution
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library STD;
use std.textio.all;

-- libraries that extent the standard IEEE libraries to 2008 standard
-- library ieee_proposed;
-- use ieee_proposed.standard_additions.all;
-- use ieee_proposed.std_logic_1164_additions.all;

-- bitvis utility libraries
library bitvis_util;
use bitvis_util.types_pkg.all;
use bitvis_util.string_methods_pkg.all;
use bitvis_util.adaptations_pkg.all;
use bitvis_util.methods_pkg.all;

-- Wishbone interface package
use work.intercon_pkg.all;


-- Test case entity
entity i2c_master_top_tb is
end entity;

-- Test case architecture
architecture func of i2c_master_top_tb is

  -- Constants
  constant C_CLK_PERIOD : time := 10 ns;

  -- Signals
  signal bClkEna   : boolean   := false;
  signal WB_CLK    : std_logic := '0';
  signal WB_RST    : std_logic := '0';
  signal WB_WBS_I  : wbs_i_type;
  signal WB_WBS_O  : wbs_o_type;
  signal ARST      : std_logic := '0';
  signal WB_INTA_o : std_logic;
  signal SCL_PAD_i : std_logic;
  signal SCL_PAD_o : std_logic;
  signal SCL_PAD_T : std_logic;
  signal SDA_PAD_i : std_logic;
  signal SDA_PAD_o : std_logic;
  signal SDA_PAD_T : std_logic;


begin

  -----------------------------------------------------------------------------
  -- Instantiate DUT
  -----------------------------------------------------------------------------

  INST_i2c_master_top : entity work.i2c_master_top
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => WB_WBS_I,
      WB_WBS_O  => WB_WBS_O,
      ARST      => ARST,
      WB_INTA_o => WB_INTA_o,
      SCL_PAD_i => SCL_PAD_i,
      SCL_PAD_o => SCL_PAD_o,
      SCL_PAD_T => SCL_PAD_T,
      SDA_PAD_i => SDA_PAD_i,
      SDA_PAD_o => SDA_PAD_o,
      SDA_PAD_T => SDA_PAD_T);


  -- Set up clock generator
  clock_generator(WB_CLK, bClkEna, 10 ns, "WB Clock");

  ------------------------------------------------
  -- PROCESS: p_main
  ------------------------------------------------
  p_main : process
    -- various constants:
    constant C_SCOPE           : string  := C_TB_SCOPE_DEFAULT;
    constant wb_write_time_out : integer := 6;  -- number of clocks to wait
                                                -- on wb_write, before an error
    constant wb_read_time_out  : integer := 6;  -- number of clocks to wait

    -- --------------------------------------------------------------------
    -- set all input values to their defaults
    -- --------------------------------------------------------------------
    procedure set_inputs_passive(
      dummy : t_void) is
    begin
      WB_WBS_I.dat_i  <= (others => '0');
      WB_WBS_I.addr_i <= (others => '0');
      WB_WBS_I.we_i   <= '0';
      WB_WBS_I.cyc_i  <= '0';
      WB_WBS_I.stb_i  <= '0';
      SCL_PAD_i       <= '1';
      SDA_PAD_i       <= '1';
      log(ID_SEQUENCER_SUB, "All inputs set passive", C_SCOPE);
    end;


    -- --------------------------------------------------------------------
    -- Log overload for simplification
    -- --------------------------------------------------------------------
    procedure log(
      msg : string) is
    begin
      log(ID_SEQUENCER, msg, C_SCOPE);
    end;

    -- --------------------------------------------------------------------
    -- usage wb_init( bus_record ); -- Initalises the wishbone bus
    -- --------------------------------------------------------------------
    procedure wb_init(
      dummy : t_void) is
    begin
      WB_WBS_I.dat_i  <= (others => '0');
      WB_WBS_I.addr_i <= (others => '0');
      WB_WBS_I.we_i   <= '0';
      WB_WBS_I.cyc_i  <= '0';
      WB_WBS_I.stb_i  <= '0';

      wait until rising_edge(WB_CLK);   -- align to next clock
    end procedure wb_init;

    -- --------------------------------------------------------------------
    -- usage wb_rst( 10); -- reset system for 10 clocks
    -- --------------------------------------------------------------------
    procedure wb_reset (
      constant no_of_clocks : in integer) is
    begin
      WB_WBS_I.cyc_i <= '0';
      WB_WBS_I.stb_i <= '0';

      WB_RST <= '1';
      for n in 1 to no_of_clocks loop
        wait until falling_edge(WB_CLK);
      end loop;
      WB_RST <= '0';
      wait until rising_edge(WB_CLK);
    end procedure wb_reset;

    -- --------------------------------------------------------------------
    -- wishbone write:
    -- --------------------------------------------------------------------
    procedure wb_write (
      constant address_data : in std_logic_vector(7 downto 0);
      constant write_data   : in std_logic_vector(15 downto 0)
      ) is

      constant proc_call : string := "wb_write(A:" & to_string(address_data, HEX, AS_IS, INCL_RADIX) &
                                     ", " & to_string(write_data, HEX, AS_IS, INCL_RADIX) & ")";

      variable bus_write_timer : integer;

    begin

      WB_WBS_I.addr_i <= address_data;
      WB_WBS_I.dat_i  <= write_data;
      WB_WBS_I.we_i   <= '1';           -- write cycle
      WB_WBS_I.cyc_i  <= '1';
      WB_WBS_I.stb_i  <= '1';

      bus_write_timer := 0;

      wait until rising_edge(WB_CLK);

      while WB_WBS_O.ack_o = '0' loop
        bus_write_timer := bus_write_timer + 1;
        wait until rising_edge(WB_CLK);
        check_value(bus_write_timer < wb_write_time_out, failure,
                    ": Timeout while waiting for ack", C_SCOPE, ID_NEVER, shared_msg_id_panel, proc_call);
        exit when bus_write_timer >= wb_write_time_out;
      end loop;

      WB_WBS_I.addr_i <= (others => '0');
      WB_WBS_I.dat_i  <= (others => '0');
      WB_WBS_I.we_i   <= '0';
      WB_WBS_I.cyc_i  <= '0';
      WB_WBS_I.stb_i  <= '0';

    end procedure wb_write;


    -- ----------------------------------------------------------------------
    --  wishbone read
    -- ----------------------------------------------------------------------
    -- usage wb_read ( address, data)-- read 16 bit data from an 8 bit address
    --
    --  Note: need read data to be a variable to be passed back to calling process;
    --   If it's a signal, it's one delta out, and in the calling process
    --    it will have the wrong value, the one after the clock !
    --
    procedure wb_read (
      constant address_data : in  std_logic_vector(7 downto 0);
      variable read_data    : out std_logic_vector(15 downto 0)
      ) is

      constant proc_call : string := "wb_read(A:" & to_string(address_data, HEX, AS_IS, INCL_RADIX) & ")";

      variable bus_read_timer : integer;

    begin

      WB_WBS_I.addr_i <= address_data;
      WB_WBS_I.we_i   <= '0';           -- read cycle
      WB_WBS_I.cyc_i  <= '1';
      WB_WBS_I.stb_i  <= '1';

      bus_read_timer := 0;

      wait until rising_edge(WB_CLK);
      while WB_WBS_O.ack_o = '0' loop
        bus_read_timer := bus_read_timer + 1;
        wait until rising_edge(WB_CLK);
        check_value(bus_read_timer < wb_read_time_out, failure,
                    ": Timeout while waiting for ack", C_SCOPE, ID_NEVER, shared_msg_id_panel, proc_call);
        exit when bus_read_timer >= wb_read_time_out;
      end loop;

      read_data       := WB_WBS_O.dat_o;
      WB_WBS_I.addr_i <= (others => '0');
      WB_WBS_I.dat_i  <= (others => '0');
      WB_WBS_I.we_i   <= '0';
      WB_WBS_I.cyc_i  <= '0';
      WB_WBS_I.stb_i  <= '0';

    end procedure wb_read;

    -- ----------------------------------------------------------------------
    --  wishbone read a register and check against expected value
    -- ----------------------------------------------------------------------
    procedure wb_check(
      constant address_data : in std_logic_vector(7 downto 0);
      constant data_exp     : in std_logic_vector(15 downto 0);
      constant alert_level  : in t_alert_level;
      constant msg          : in string) is

      variable vReadData  : std_logic_vector(15 downto 0) := x"0000";
      variable v_check_ok : boolean;

      constant proc_call : string := "wb_check(A:" & to_string(address_data, HEX, AS_IS, INCL_RADIX) &
                                     ", " & to_string(data_exp, HEX, AS_IS, INCL_RADIX) & ")";

    begin
      wb_read(address_data, vReadData);
      v_check_ok := check_value(vReadData, data_exp,
                                alert_level, msg, C_SCOPE,
                                HEX_BIN_IF_INVALID, SKIP_LEADING_0, ID_NEVER,
                                shared_msg_id_panel, proc_call);
      if v_check_ok then
        log(ID_BFM, proc_call & "=> OK, read data = " & to_string(vReadData, HEX, SKIP_LEADING_0, INCL_RADIX) & ". " & msg,
            C_SCOPE, shared_msg_id_panel);
      end if;
    end procedure wb_check;

    -- ----------------------------------------------------------------------
    -- various helper variables:
    -- ----------------------------------------------------------------------
    variable vReadData    : std_logic_vector(15 downto 0);
    variable i2c_timer : integer;

  begin
    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    enable_log_msg(ALL_MESSAGES);
    --disable_log_msg(ALL_MESSAGES);
    --enable_log_msg(ID_LOG_HDR);

    log(ID_LOG_HDR, "Start Simulation of TB for I2C", C_SCOPE);
    ------------------------------------------------------------

    set_inputs_passive(VOID);
    bClkEna      <= true;               -- to start clock generator
    wait for 5 ns;
    -- pulse ARST high for 10 clock periods
    gen_pulse(ARST, WB_CLK, 10, "async reset-signal ARST");

    -- reset wishbone bus for 2 clock cycles
    log("- Reset Wishbone bus (2T)");
    wb_reset(2);

    wait for C_CLK_PERIOD * 5;


    log(ID_LOG_HDR, "Check some register default values after reset", C_SCOPE);
    ------------------------------------------------------------
    -- test some of the register values after reset
    wb_check(x"00", x"FFFF", error, "Reg 0 default");
    wb_check(x"01", x"0000", error, "Reg 1 default");
    wb_check(x"02", x"0000", error, "Reg 2 default");
    wb_check(x"03", x"0000", error, "Reg 3 default");

    wait for C_CLK_PERIOD * 5;

    log(ID_LOG_HDR, "write one register, then read back 2 registers", C_SCOPE);
    ------------------------------------------------------------
    -- write to one of the registers and read it back, interspersing a read of
    -- another register
    log("- Write register 0 with value 0x1234");
    wb_write(x"00", x"1234");

    wait for C_CLK_PERIOD * 5;

    wb_check(x"01", x"0000", error, "Reg 1 default");
    wb_check(x"00", x"1234", error, "Reg 0 after change");

    log(ID_LOG_HDR, "Do some I2C transactions", C_SCOPE);
    ------------------------------------------------------------
    -- do a I2C write transaction:
    -- write 0x1 to register 28 of I2C address 0x01 on I2C bus 0
    -- should be 3 I2C write transactions:
    --  a) a write with value 0x1 for I2C address and R/W bit turned off: 0x02,
    --     including an I2C Start
    --  b) a write with value 0x1c (register address 28)
    --  c) a write with value 0x1  (register value), including an I2C Stop
    --
    -- See I2C module documentation in the doc directory for details on the registers
    --
    -- 1) write clock scaling factor 0x0 to register 0:
    --    (should result in a SCL frequency of 20MHz (50ns period)
    log("- Write register 0 with value 0x0000");
    wb_write(x"00", x"0000");
    -- 2) enable I2C on bus 0 (reg 1 = 0x80)
    log("- Write register 1 with value 0x0080");
    wb_write(x"01", x"0080");
    -- 3) set TX register to 0x02
    log("- Write register 2 with value 0x0002");
    wb_write(x"02", x"0002");
    -- 4) set STA and WR bits in Command register: starts transaction
    log("- Write register 3 with value 0x0090 (should start I2C transaction)");
    wb_write(x"03", x"0090");

    -- read status register in the middle of the transaction
    wait for C_CLK_PERIOD * 5 * 5;
    log("- Read status register 3 (TIP should be high)");
    wb_read(x"03", vReadData);
    log(ID_SEQUENCER, "- value read = " & to_string(vReadData, HEX, AS_IS, INCL_RADIX), C_SCOPE);

    -- now wait until TIP bit goes low, or timeout
    i2c_timer := 0;
    while vReadData(1) = '1' loop
      i2c_timer := i2c_timer + 1;
      wait for C_CLK_PERIOD * 5; -- one I2C CLK period
      wb_read(x"03", vReadData);
      exit when  i2c_timer >= 15;
    end loop;
    log(ID_SEQUENCER, "- wait cycles = " & to_string(i2c_timer, 2), C_SCOPE);
    check_value(i2c_timer < 6, TB_WARNING, "# of wait cycles < 6", C_SCOPE);
    log(ID_SEQUENCER, "- status register value read = " & to_string(vReadData, HEX, AS_IS, INCL_RADIX), C_SCOPE);

    -- 5) set TX register to 0x1c (register address)
    log("- Write register 2 with value 0x001c");
    wb_write(x"02", x"001c");
    -- 6) set WR bit in Command register: starts transaction
    log("- Write register 3 with value 0x0010 (should start I2C transaction)");
    wb_write(x"03", x"0010");
    -- 7) wait for TIP bit in register 3 to go low
    wait for C_CLK_PERIOD * 5 * 5;
    i2c_timer := 0;
    wb_read(x"03", vReadData);
    while vReadData(1) = '1' loop
      i2c_timer := i2c_timer + 1;
      wait for C_CLK_PERIOD * 5; -- one I2C CLK period
      wb_read(x"03", vReadData);
      exit when  i2c_timer >= 15;
    end loop;
    log(ID_SEQUENCER, "- wait cycles = " & to_string(i2c_timer, 2), C_SCOPE);
    check_value(i2c_timer < 6, TB_WARNING, "# of wait cyles < 6", C_SCOPE);
    log(ID_SEQUENCER, "- status register value read = " & to_string(vReadData, HEX, AS_IS, INCL_RADIX), C_SCOPE);


    -- 8) set TX register to 0x1 (register value to write)
    log("- Write register 2 with value 0x0002");
    wb_write(x"02", x"0001");
    -- 9) set STO and WR bits in Command register: starts transaction
    log("- Write register 3 with value 0x0050 (should start I2C transaction)");
    wb_write(x"03", x"0050");
    -- 10) wait for TIP bit in register 3 to go low
    wait for C_CLK_PERIOD * 5 * 5;
    i2c_timer := 0;
    wb_read(x"03", vReadData);
    while vReadData(1) = '1' loop
      i2c_timer := i2c_timer + 1;
      wait for C_CLK_PERIOD * 5; -- one I2C CLK period
      wb_read(x"03", vReadData);
      exit when  i2c_timer >= 15;
    end loop;
    log(ID_SEQUENCER, "- wait cycles = " & to_string(i2c_timer, 2), C_SCOPE);
    check_value(i2c_timer < 6, TB_WARNING, "# of wait cycles < 6", C_SCOPE);
    log(ID_SEQUENCER, "- status register value read = " & to_string(vReadData, HEX, AS_IS, INCL_RADIX), C_SCOPE);

    --==================================================================================================
    -- Ending the simulation
    --------------------------------------------------------------------------------------
    wait for 300 ns;                    -- to allow some time for completion
    report_alert_counters(FINAL);  -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);
    bClkEna <= false;  -- to gracefully stop the simulation - if possible
    -- Hopefully stops when clock is stopped. Otherwise force a stop.
    wait for 100 ns;
    assert false
      report "End of simulation.  (***Ignore this failure. Was provoked to stop the simulation.)"
      severity failure;
    wait;                               -- to stop completely

  end process p_main;

end func;
