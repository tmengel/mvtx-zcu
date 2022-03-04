-------------------------------------------------------------------------------
-- Title      : CANbus UVVM Testbench
-- Project    : ITS RU FPGA
-------------------------------------------------------------------------------
-- File       : can_uvvm_tb.vhd
-- Author     : Simon Voigt Nesbo (svn@hvl.no)
-- Company    : Western Norway University of Applied Sciences
-- Created    : 2018-03-02
-- Last update: 2018-03-20
-- Platform   : Windows 10 64bit, Libero
-- Target     : Microsemi PA3
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Testbench for the OpenCores CAN module that uses UVVM for
--              verification.
--              Parts of Bitvis' irqc_tb.vhd from UVVM 1.4.0 has been reused
--              in this testbench.
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                  Description
-- 2018-03-02  1.0      svn                     Created
-------------------------------------------------------------------------------
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_textio.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_wishbone;
use bitvis_vip_wishbone.wb_bfm_pkg.all;

library work;
use work.can_register_pkg.all;

-- test bench entity
entity can_wb_uvvm_tb is
end can_wb_uvvm_tb;

architecture func of can_wb_uvvm_tb is

  constant C_CLK_PERIOD : time       := 25000 ps; -- 40 Mhz
  constant C_CLK_FREQ   : integer := 1e9 ns / C_CLK_PERIOD;

  constant WB_DATA_WIDTH : natural := 8;
  constant WB_ADDR_WIDTH : natural := 8;

  -- Copied from Bitvis IRQC testbench
  procedure clock_gen(
    signal   clock_signal  : inout std_logic;
    signal   clock_ena     : in    boolean;
    constant clock_period  : in    time
    ) is
    variable v_first_half_clk_period : time := C_CLK_PERIOD / 2;
  begin
    loop
      if not clock_ena then
        wait until clock_ena;
      end if;
      wait for v_first_half_clk_period;
      clock_signal <= not clock_signal;
      wait for (clock_period - v_first_half_clk_period);
      clock_signal <= not clock_signal;
    end loop;
  end;

  signal clock_ena : boolean := false;

  -- Inputs
  signal reset   : std_logic := '0';
  signal clk     : std_logic := '0';

  signal can_bus_signal  : std_logic;

  signal can0_out        : std_logic;
  signal can0_rx         : std_logic := '0';
  signal can0_tx         : std_logic := '0';
  signal can0_bus_off_on : std_logic := '1';
  signal can0_irq_n      : std_logic := '0';

  -- Wishbone interface for CAN controller #0
  signal wbm_can0_if : t_wbm_if (dat_o(WB_DATA_WIDTH-1 downto 0), addr_o(WB_ADDR_WIDTH-1 downto 0),
                                 dat_i(WB_DATA_WIDTH-1 downto 0)) := init_wbm_if_signals(8, 8);

  signal can1_out        : std_logic;
  signal can1_rx         : std_logic := '0';
  signal can1_tx         : std_logic := '0';
  signal can1_bus_off_on : std_logic := '1';
  signal can1_irq_n      : std_logic := '0';

  -- Wishbone interface for CAN controller #0
  signal wbm_can1_if : t_wbm_if (dat_o(WB_DATA_WIDTH-1 downto 0), addr_o(WB_ADDR_WIDTH-1 downto 0),
                                 dat_i(WB_DATA_WIDTH-1 downto 0)) := init_wbm_if_signals(8, 8);

begin

  -- Configuring floating output / pullup in CAN controller didnt seem to work..
  p_can0_out: process(can0_tx)
  begin
    can0_out <= '0' when can0_tx = '0' else 'Z';
  end process;

  p_can1_out: process(can1_tx)
  begin
    can1_out <= '0' when can1_tx = '0' else 'Z';
  end process;

  can_bus_signal <= 'H';
  can_bus_signal <= can0_out;
  can_bus_signal <= can1_out;
  can0_rx <= can_bus_signal;
  can1_rx <= can_bus_signal;


  -- Set upt clock generator
  clock_gen(clk, clock_ena, C_CLK_PERIOD);


  iCAN0 : entity work.can_top
    port map
    (
      clk_i      => clk,
      rx_i       => can0_rx,
      tx_o       => can0_tx,
      bus_off_on => can0_bus_off_on,
      irq_on     => can0_irq_n,
      clkout_o   => open,
      wb_clk_i   => clk,
      wb_rst_i   => reset,
      wb_dat_i   => wbm_can0_if.dat_o,
      wb_dat_o   => wbm_can0_if.dat_i,
      wb_cyc_i   => wbm_can0_if.cyc_o,
      wb_stb_i   => wbm_can0_if.stb_o,
      wb_we_i    => wbm_can0_if.we_o,
      wb_adr_i   => wbm_can0_if.addr_o,
      wb_ack_o   => wbm_can0_if.ack_i
    );

  iCAN1 : entity work.can_top
    port map
    (
      clk_i      => clk,
      rx_i       => can1_rx,
      tx_o       => can1_tx,
      bus_off_on => can1_bus_off_on,
      irq_on     => can1_irq_n,
      clkout_o   => open,
      wb_clk_i   => clk,
      wb_rst_i   => reset,
      wb_dat_i   => wbm_can1_if.dat_o,
      wb_dat_o   => wbm_can1_if.dat_i,
      wb_cyc_i   => wbm_can1_if.cyc_o,
      wb_stb_i   => wbm_can1_if.stb_o,
      wb_we_i    => wbm_can1_if.we_o,
      wb_adr_i   => wbm_can1_if.addr_o,
      wb_ack_o   => wbm_can1_if.ack_i
    );


  p_main: process
    constant C_SCOPE     : string  := C_TB_SCOPE_DEFAULT;

    -- Pulse a signal for a number of clock cycles.
    -- Source: irqc_tb.vhd from Bitvis UVVM 1.4.0
    procedure pulse(
      signal   target          : inout std_logic;
      signal   clock_signal    : in    std_logic;
      constant num_periods     : in    natural;
      constant msg             : in    string
    ) is
    begin
      if num_periods > 0 then
        wait until falling_edge(clock_signal);
        target  <= '1';
        for i in 1 to num_periods loop
          wait until falling_edge(clock_signal);
        end loop;
      else
        target  <= '1';
        wait for 0 ns;  -- Delta cycle only
      end if;
      target  <= '0';
      log(ID_SEQUENCER_SUB, msg, C_SCOPE);
    end;

    -- Pulse a signal for a number of clock cycles.
    -- Source: irqc_tb.vhd from Bitvis UVVM 1.4.0
    procedure pulse(
      signal   target        : inout  std_logic_vector;
      constant pulse_value   : in     std_logic_vector;
      signal   clock_signal  : in     std_logic;
      constant num_periods   : in     natural;
      constant msg           : in     string) is
    begin
      if num_periods > 0 then
        wait until falling_edge(clock_signal);
        target <= pulse_value;
        for i in 1 to num_periods loop
          wait until falling_edge(clock_signal);
        end loop;
      else
        target <= pulse_value;
        wait for 0 ns;  -- Delta cycle only
      end if;
      target(target'range) <= (others => '0');
      log(ID_SEQUENCER_SUB, "Pulsed to " & to_string(pulse_value, HEX, AS_IS, INCL_RADIX) & ". " & msg, C_SCOPE);
    end;


    -- Log overloads for simplification
    procedure log(
      msg   : string) is
    begin
      log(ID_SEQUENCER, msg, C_SCOPE);
    end;

  procedure init_wishbone_signals is
  begin
    wbm_can0_if.dat_o <= (others => '0');
    wbm_can0_if.addr_o <= (others => '0');
    wbm_can0_if.we_o <= '0';
    wbm_can0_if.cyc_o <= '0';
    wbm_can0_if.stb_o <= '0';

    wbm_can1_if.dat_o <= (others => '0');
    wbm_can1_if.addr_o <= (others => '0');
    wbm_can1_if.we_o <= '0';
    wbm_can1_if.cyc_o <= '0';
    wbm_can1_if.stb_o <= '0';

    log(ID_SEQUENCER_SUB, "Wishbone signals initialized", C_SCOPE);
  end;

    ---------------------------------------------------------------------------
    -- Procedures for wb_bfm
    ---------------------------------------------------------------------------
    procedure wb_check (
      constant addr_value       : in  natural;
      constant data_exp         : in  std_logic_vector;
      constant alert_level      : in  t_alert_level             := error;
      constant msg              : in  string;
      signal   wb_if            : inout t_wbm_if;
      constant scope            : in  string                    := C_SCOPE;
      constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
      constant config           : in  t_wb_bfm_config           := C_WB_BFM_CONFIG_DEFAULT
    ) is
    begin
      wb_check(std_logic_vector(to_unsigned(addr_value, WB_ADDR_WIDTH)), data_exp, error, msg, clk, wb_if, scope, msg_id_panel, config);
    end procedure wb_check;

    procedure wb_write (
      constant addr_value       : in  natural;
      constant data_value       : in  std_logic_vector;
      constant msg              : in  string;
      signal   wb_if            : inout t_wbm_if;
      constant scope            : in  string                    := C_SCOPE;
      constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
      constant config           : in  t_wb_bfm_config           := C_WB_BFM_CONFIG_DEFAULT
    ) is
    begin
      wb_write(std_logic_vector(to_unsigned(addr_value, WB_ADDR_WIDTH)), data_value, msg, clk, wb_if, scope, msg_id_panel, config);
    end procedure wb_write;

    procedure wb_read (
      constant addr_value       : in  natural;
      variable data_value       : out std_logic_vector;
      constant msg              : in  string;
      signal   wb_if            : inout t_wbm_if;
      constant scope            : in  string                    := C_SCOPE;
      constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
      constant config           : in  t_wb_bfm_config           := C_WB_BFM_CONFIG_DEFAULT;
      constant proc_name        : in  string                    := "wb_read"  -- overwrite if called from other procedure like wb_check
    ) is
    begin
      wb_read(std_logic_vector(to_unsigned(addr_value, WB_ADDR_WIDTH)), data_value, msg, clk, wb_if, scope, msg_id_panel, config);
    end procedure wb_read;




  begin
    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    enable_log_msg(ALL_MESSAGES);
    --disable_log_msg(ALL_MESSAGES);
    --enable_log_msg(ID_LOG_HDR);

    log(ID_LOG_HDR, "Start simulation of testbench for CAN controller", C_SCOPE);
    ------------------------------------------------------------

    --set_inputs_passive(VOID);
    clock_ena <= true;   -- to start clock generator
    pulse(reset, clk, 10, "Pulsed reset-signal - active for 250 ns");

    wait for 100 ns;

    log(ID_LOG_HDR, "Check that controllers are in RESET mode", C_SCOPE);
    ------------------------------------------------------------
    wb_check(C_CAN_CMR, x"FF", ERROR, "Reading CMR should return FF in basic mode", wbm_can0_if);
    wb_check(C_CAN_CMR, x"FF", ERROR, "Reading CMR should return FF in basic mode", wbm_can1_if);
    wb_check(C_CAN_BM_CR, "001----1", ERROR, "Check that reset request bit is set (reset mode)", wbm_can0_if);
    wb_check(C_CAN_BM_CR, "001----1", ERROR, "Check that reset request bit is set (reset mode)", wbm_can1_if);


    log(ID_LOG_HDR, "Setting up CAN0 and CAN1 acceptance code and mask", C_SCOPE);
    ------------------------------------------------------------
    wb_write(C_CAN_BM_ACR, x"AA", "CAN0 acceptance code", wbm_can0_if);
    wb_write(C_CAN_BM_AMR, x"FF", "CAN0 acceptance mask", wbm_can0_if);
    wb_write(C_CAN_BM_ACR, x"BB", "CAN1 acceptance code", wbm_can1_if);
    wb_write(C_CAN_BM_AMR, x"FF", "CAN1 acceptance mask", wbm_can1_if);

    wb_check(C_CAN_BM_ACR, x"AA", ERROR, "CAN0 acceptance code", wbm_can0_if);
    wb_check(C_CAN_BM_AMR, x"FF", ERROR, "CAN0 acceptance mask", wbm_can0_if);
    wb_check(C_CAN_BM_ACR, x"BB", ERROR, "CAN1 acceptance code", wbm_can1_if);
    wb_check(C_CAN_BM_AMR, x"FF", ERROR, "CAN1 acceptance mask", wbm_can1_if);


    log(ID_LOG_HDR, "Setting up CAN0 and CAN1 bus timing register for 1Mbps", C_SCOPE);
    ------------------------------------------------------------
    wb_write(C_CAN_BTR0, x"01", "4x baud prescale and minimum synch jump width time for CAN0", wbm_can0_if);
    wb_write(C_CAN_BTR0, x"01", "4x baud prescale and minimum synch jump width time for CAN1", wbm_can1_if);
    wb_write(C_CAN_BTR1, x"25", "7 baud clocks before and 3 after sampling point, tSEG1=6 and tSEG2=3, for CAN0", wbm_can0_if);
    wb_write(C_CAN_BTR1, x"25", "7 baud clocks before and 3 after sampling point, tSEG1=6 and tSEG2=3, for CAN1", wbm_can1_if);

    wb_check(C_CAN_BTR0, x"01", ERROR, "4x baud prescale and minimum synch jump width time for CAN0", wbm_can0_if);
    wb_check(C_CAN_BTR0, x"01", ERROR, "4x baud prescale and minimum synch jump width time for CAN1", wbm_can1_if);
    wb_check(C_CAN_BTR1, x"25", ERROR, "7 baud clocks before and 3 after sampling point, tSEG1=6 and tSEG2=3, for CAN0", wbm_can0_if);
    wb_check(C_CAN_BTR1, x"25", ERROR, "7 baud clocks before and 3 after sampling point, tSEG1=6 and tSEG2=3, for CAN1", wbm_can1_if);


    log(ID_LOG_HDR, "Configure CAN0 and CAN1 for Operation Mode", C_SCOPE);
    ------------------------------------------------------------
    wb_write(C_CAN_BM_CR, "00111110", "CAN0 interrupts enabled, operation mode", wbm_can0_if);
    wb_write(C_CAN_BM_CR, "00111110", "CAN1 interrupts enabled, operation mode", wbm_can1_if);

    wb_check(C_CAN_BM_CR, "00111110", ERROR, "CAN0 interrupts enabled, operation mode", wbm_can0_if);
    wb_check(C_CAN_BM_CR, "00111110", ERROR, "CAN1 interrupts enabled, operation mode", wbm_can1_if);


    log(ID_LOG_HDR, "Start a transaction from CAN0 to CAN1", C_SCOPE);
    ------------------------------------------------------------
    wb_write(C_CAN_BM_TXB_ID1, x"BB", "Set TXID1 to xBB", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_ID2, x"08", "Set TXID2 to x08, 8 bytes data", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA1, x"11", "Set data1 to x11", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA2, x"22", "Set data2 to x22", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA3, x"33", "Set data3 to x33", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA4, x"44", "Set data4 to x44", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA5, x"55", "Set data5 to x55", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA6, x"66", "Set data6 to x66", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA7, x"77", "Set data7 to x77", wbm_can0_if);
    wb_write(C_CAN_BM_TXB_DATA8, x"88", "Set data8 to x88", wbm_can0_if);

    wb_write(C_CAN_CMR, x"01", "Request transmission on CAN0", wbm_can0_if);


    log(ID_LOG_HDR, "Wait for CAN1 to receive message", C_SCOPE);
    ------------------------------------------------------------
    wait until can1_irq_n = '0' for 1000 us;

    if can1_irq_n /= '0' then
      log(ID_LOG_HDR, "Reached 100 us timeout while waiting for CAN1 to assert interrupt.", C_SCOPE);
    else
      log(ID_LOG_HDR, "Got interrupt from CAN1.", C_SCOPE);
    end if;

    wb_check(C_CAN_BM_CR, "-----1--", ERROR, "Check that CAN0 transmit interrupt was set", wbm_can0_if);
    wb_check(C_CAN_SR,    "----1---", ERROR, "Check that CAN0 transmit complete status bit is set", wbm_can0_if);
    wb_check(C_CAN_BM_CR, "------1-", ERROR, "Check that CAN1 receive interrupt was set", wbm_can1_if);


    wait for 1000 ns;

    log(ID_LOG_HDR, "Verify message received by CAN1", C_SCOPE);
    ------------------------------------------------------------
    wb_check(C_CAN_BM_RXB_ID1, x"BB", ERROR, "Verify received RXID1", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_ID2, x"08", ERROR, "Verify received RXID2, 8 bytes data", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA1, x"11", ERROR, "Verify received data byte 1", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA2, x"22", ERROR, "Verify received data byte 2", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA3, x"33", ERROR, "Verify received data byte 3", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA4, x"44", ERROR, "Verify received data byte 4", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA5, x"55", ERROR, "Verify received data byte 5", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA6, x"66", ERROR, "Verify received data byte 6", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA7, x"77", ERROR, "Verify received data byte 7", wbm_can1_if);
    wb_check(C_CAN_BM_RXB_DATA8, x"88", ERROR, "Verify received data byte 8", wbm_can1_if);


    wait for 10000 ns;             -- to allow some time for completion
    report_alert_counters(FINAL); -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    -- Finish the simulation
    std.env.stop;
    wait;  -- to stop completely

  end process p_main;

end func;
