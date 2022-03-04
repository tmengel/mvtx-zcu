-------------------------------------------------------------------------------
-- Title      : Testbench for design "i2c_wrapper"
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : i2c_wrapper_tb.vhd
-- Author     : Joachim Schambach  <jschamba@leo.rhip.utexas.edu>
-- Company    : 
-- Created    : 2017-06-28
-- Last update: 2017-09-05
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Testbench for design "i2c_wrapper"
--              Uses the Bitvis Utility Library 2.6.0 (from www.bitvis.no)
--              See documentation in the Bitvis distribution
-------------------------------------------------------------------------------
-- Copyright (c) 2017 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-06-28  1.0      jschamba        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
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

library work;
-- Wishbone interface package
use work.intercon_pkg.all;

-------------------------------------------------------------------------------

entity i2c_pu_wrapper_tb is
end entity i2c_pu_wrapper_tb;

-------------------------------------------------------------------------------

architecture behavioral of i2c_pu_wrapper_tb is

  -- Constants
  constant C_WB_CLK_PERIOD : time := 5 ns;  -- 160MHz (rounded down)

  -- component ports
  signal WB_CLK        : std_logic;
  signal WB_RST        : std_logic := '0';
  signal WB_WBS_I      : wbs_i_type;
  signal WB_WBS_O      : wbs_o_type;
  signal SCL_PAD_o     : std_logic;
  signal SCL_PAD_T     : std_logic;
  signal SDA_PAD_i     : std_logic;
  signal SDA_PAD_o     : std_logic;
  signal SDA_PAD_T     : std_logic;
  signal AUX_SCL_PAD_o : std_logic;
  signal AUX_SCL_PAD_T : std_logic;
  signal AUX_SDA_PAD_i : std_logic;
  signal AUX_SDA_PAD_o : std_logic;
  signal AUX_SDA_PAD_T : std_logic;

  -- slave signals
  signal  TX_EMPTY : std_logic;
  signal  RX_DATA  : std_logic_vector(7 downto 0);
  signal  RX_VLD   : std_logic;
  signal  BUSY     : std_logic;
  signal  ERROR_C  : std_logic_vector(1 downto 0);

  signal  AUX_TX_EMPTY : std_logic;
  signal  AUX_RX_DATA  : std_logic_vector(7 downto 0);
  signal  AUX_RX_VLD   : std_logic;
  signal  AUX_BUSY     : std_logic;
  signal  AUX_ERROR_C  : std_logic_vector(1 downto 0);
  signal  SLV_ADR      : std_logic_vector(6 downto 0);

   -- Signals for simulation
  signal bClkEna : boolean := false;

  --signal iState    : integer := 0;
  --signal iCountSCL : integer := 0;

begin  -- architecture behavioral

  -- component instantiation

  DUT : entity work.i2c_pu_wrapper
    port map (
      WB_CLK        => WB_CLK,
      WB_RST        => WB_RST,
      WB_WBS_I      => WB_WBS_I,
      WB_WBS_O      => WB_WBS_O,
      SCL_PAD_i     => SCL_PAD_T,       -- use output as input
      SCL_PAD_o     => SCL_PAD_o,
      SCL_PAD_T     => SCL_PAD_T,
      SDA_PAD_i     => SDA_PAD_i,
      SDA_PAD_o     => SDA_PAD_o,
      SDA_PAD_T     => SDA_PAD_T,
      AUX_SCL_PAD_i => AUX_SCL_PAD_T,   -- use output as input
      AUX_SCL_PAD_o => AUX_SCL_PAD_o,
      AUX_SCL_PAD_T => AUX_SCL_PAD_T,
      AUX_SDA_PAD_i => AUX_SDA_PAD_i,
      AUX_SDA_PAD_o => AUX_SDA_PAD_o,
      AUX_SDA_PAD_T => AUX_SDA_PAD_T
      );


  -- Set up clock generator
  clock_generator(WB_CLK, bClkEna, C_WB_CLK_PERIOD, "WB Clock");



  i2c_slave_main: entity work.i2c_slave
    generic map (
      G_SDA_DELAY => 5)
    port map (
      CLK      => WB_CLK,
      RESET    => WB_RST,
      SCL      => SCL_PAD_T,
      SDA_i    => SDA_PAD_T,
      SDA_o    => SDA_PAD_i,
      SLV_ADR  => SLV_ADR, -- "1010010",                   -- 0x52
      TX_DATA  => x"bc",
      TX_WR    => '1',
      TX_EMPTY => TX_EMPTY,
      RX_DATA  => RX_DATA,
      RX_VLD   => RX_VLD,
      RX_ACK   => '1',
      BUSY     => BUSY,
      ERROR_C  => ERROR_C
      );

  i2c_slave_aux: entity work.i2c_slave
    generic map (
      G_SDA_DELAY => 5)
    port map (
      CLK      => WB_CLK,
      RESET    => WB_RST,
      SCL      => AUX_SCL_PAD_T,
      SDA_i    => AUX_SDA_PAD_T,
      SDA_o    => AUX_SDA_PAD_i,
      SLV_ADR  => "0111001",                   -- 0x39
      TX_DATA  => x"78",
      TX_WR    => '1',
      TX_EMPTY => AUX_TX_EMPTY,
      RX_DATA  => AUX_RX_DATA,
      RX_VLD   => AUX_RX_VLD,
      RX_ACK   => '1',
      BUSY     => AUX_BUSY,
      ERROR_C  => AUX_ERROR_C
      );

  
  -- try to emulate slave clock stretching by pulling
  -- SCL low at some arbitary point in the I2C transaction
  -- for a couple of SCL periods
  --p_scl: process (WB_CLK) is
  --begin
  --  if rising_edge(WB_CLK) then
  --    if WB_RST = '1' then
  --      SCL_PAD_i <= '1';
  --      iState    <= 0;
  --      iCountSCL <= 0;
  --    else
  --      SCL_PAD_i <= '1';
  --      case iState is
  --        when 0 =>
  --          if SCL_PAD_T = '0' then
  --            iCountSCL <= iCountSCL + 1;
  --            iState <= 1;
  --          end if;
  --        when 1 =>
  --          if iCountSCL = 17 then
  --            iCountSCL <= 0;
  --            iState <= 2;
  --          elsif SCL_PAD_T = '1' then
  --            iState <= 0;
  --          end if;
  --        when 2 =>
  --          SCL_PAD_i <= '0';
  --          if iCountSCL = 3200 then
  --            iState <= 3;
  --          else
  --            iCountSCL <= iCountSCL + 1;
  --          end if;
  --        when others => null;
  --      end case;
  --    end if;
  --  end if;
  --end process p_scl;

  ------------------------------------------------
  -- PROCESS: p_main
  ------------------------------------------------
  p_main : process
    -- various constants:
    constant C_SCOPE           : string  := C_TB_SCOPE_DEFAULT;
    constant wb_write_time_out : integer := 135167;  -- number of clocks to wait
                                        -- on wb_write, before an error
    constant wb_read_time_out  : integer := 135167;  -- number of clocks to wait

    -- --------------------------------------------------------------------
    -- set all input values to their defaults
    -- --------------------------------------------------------------------
    --procedure set_inputs_passive is
    --begin
    --  SCL_PAD_i     <= '1';
    --  SDA_PAD_i     <= '1';
    --  AUX_SCL_PAD_i <= '1';
    --  AUX_SDA_PAD_i <= '1';
    --  log(ID_SEQUENCER_SUB, "All inputs set passive", C_SCOPE);
    --end;


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
    procedure wb_init is
    begin
      WB_WBS_I.dat_i  <= (others => '0');
      WB_WBS_I.addr_i <= (others => '0');
      WB_WBS_I.we_i   <= '0';
      WB_WBS_I.cyc_i  <= '0';
      WB_WBS_I.stb_i  <= '0';

      wait until rising_edge(WB_CLK);   -- align to next clock
      log(ID_SEQUENCER_SUB, "Wishbone signals initialized", C_SCOPE);
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
      log(ID_BFM, proc_call & "=> ACK after " & to_string(bus_write_timer) & " WB_CLK periods",
            C_SCOPE, shared_msg_id_panel);
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
      WB_WBS_I.we_i   <= '0';  -- read cycle
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
      log(ID_BFM, proc_call & "=> ACK after " & to_string(bus_read_timer) & " WB_CLK periods",
            C_SCOPE, shared_msg_id_panel);

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
-------------------------------------------------------------------------------
-- Begin simulation
-------------------------------------------------------------------------------
  begin
    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    enable_log_msg(ALL_MESSAGES);
    --disable_log_msg(ALL_MESSAGES);
    --enable_log_msg(ID_LOG_HDR);

    log(ID_LOG_HDR, "Start Simulation of TB for I2C", C_SCOPE);
    ------------------------------------------------------------
    SLV_ADR <= "1010010";               -- 0x52

    -- set inputs low, start clock
    --set_inputs_passive;
    bClkEna <= true;                    -- to start clock generator
    wb_init;
    wait for C_WB_CLK_PERIOD;

    -- reset wishbone bus for 10 clock cycles
    log("- Reset Wishbone bus (10T)");
    wb_reset(10);

    -- wait for I2C to be initialized
    --wait for C_WB_CLK_PERIOD * 20;
    wait for 10 us;
    ---------------------------------------------------------------------------
    -- write to register 0 (sets GBTx0 register address, no I2C transaction)
    -- 0x12XX sets byte 2 to write
    -- 0xXX34 sets byte 1 to write
    log("- Write register 0 with value 0x1234");
    wb_write(x"00", x"cd12");

    wait for C_WB_CLK_PERIOD * 5;

    -- write to register 1, starts I2C transaction on main bus
    log("- Write register 0x02 with value 0x5600; starts I2C on PU MAIN");
    wb_write(x"02", x"3456");

    -- slave RX_DATA should now be last value written on I2C:
    check_value(RX_DATA, x"56", TB_WARNING, "last MAIN I2C byte written");
    
    wait for 100 us;

    SLV_ADR <= "0011101";               -- 0x1d
    wait for C_WB_CLK_PERIOD;

    -- write to register b, starts I2C transaction on main bus
    log("- Write register 0x0b with value 0x7800; starts I2C on PU MAIN");
    wb_write(x"0b", x"3478");

    -- slave RX_DATA should now be last value written on I2C:
    check_value(RX_DATA, x"78", TB_WARNING, "last MAIN I2C byte written");

    
    wait for 100 us;

    -- write to register 0x21, starts I2C transaction on aux bus
    log("- Write register 0x21 with value 0x9a; starts I2C on PU AUX");
    wb_write(x"21", x"349a");

    -- slave RX_DATA should now be last value written on I2C:
    check_value(AUX_RX_DATA, x"9A", TB_WARNING, "last AUX I2C byte written");

    wait for 100 us;

    -- now read from AUX bus
    log("- Read register 0x21, expect 0x0078");
    wb_check(x"21", x"0078", error, "Addr 0x21 read");



--==================================================================================================
-- Ending the simulation
--------------------------------------------------------------------------------------
    -- wait a little
    wait for 100 us;

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
end architecture behavioral;
