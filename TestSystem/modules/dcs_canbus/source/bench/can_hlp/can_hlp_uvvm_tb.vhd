-------------------------------------------------------------------------------
-- Title      : DCS CANbus HLP UVVM Testbench
-- Project    : ITS RU FPGA
-------------------------------------------------------------------------------
-- File       : can_hlp_uvvm_tb.vhd
-- Author     : Simon Voigt Nesbo (svn@hvl.no)
-- Company    : Western Norway University of Applied Sciences
-- Created    : 2018-03-02
-- Last update: 2018-11-21
-- Platform   : Windows 10 64bit, Libero
-- Target     : Microsemi PA3
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Testbench for the CAN High Level Protocol (HLP) module.
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

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_wishbone;
use bitvis_vip_wishbone.wb_bfm_pkg.all;

library work;
use work.intercon_pkg.all;
use work.can_uvvm_bfm_pkg.all;
use work.can_hlp_uvvm_bfm_pkg.all;
use work.can_hlp_wb_slave_regs_pkg.all;
use work.can_hlp_pkg.all;
use work.can_register_pkg.all;

-- test bench entity
entity can_hlp_uvvm_tb is
end can_hlp_uvvm_tb;

architecture func of can_hlp_uvvm_tb is

  constant C_CLK_PERIOD : time       := 6250 ps; -- 160 Mhz
  constant C_CLK_FREQ   : integer    := 1e9 ns / C_CLK_PERIOD;

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
  signal reset           : std_logic := '0';
  signal clk             : std_logic := '0';

  signal can_bus_signal  : std_logic;
  signal can0_rx         : std_logic;
  signal can0_tx         : std_logic;
  signal can1_rx         : std_logic;
  signal can1_tx         : std_logic;

  -- Interface to CAN HLP WB slave, using intercon interface
  signal wbs_can_hlp_i : wbs_i_type;
  signal wbs_can_hlp_o : wbs_o_type;

  signal wb_addr_fifo_test_if : std_logic_vector(WB_ADD_WIDTH-1 downto 0);

  signal can_hlp_node_id : std_logic_vector(7 downto 0) := x"AA";

  -- Interface to wishbone master via FIFO
  -- CAN HLP initiates WB transactions on DP0
  signal dp0_dt   : std_logic_vector(31 downto 0);
  signal dp0_epty : std_logic := '0';
  signal dp0_rd   : std_logic := '0';

  -- Interface to wishbone master via FIFO
  -- CAN HLP receives WB replies on DP1
  signal dp1_dt   : std_logic_vector(31 downto 0);
  signal dp1_full : std_logic := '0';
  signal dp1_wr   : std_logic := '0';

begin
  can_bus_signal <= 'H';
  can_bus_signal <= '0' when can0_tx = '0' else 'Z';
  can_bus_signal <= '0' when can1_tx = '0' else 'Z';
  can0_rx        <= '1' ?= can_bus_signal;
  can1_rx        <= '1' ?= can_bus_signal;

  -- Ignore the upper bits of address - we only have one slave (CAN HLP)
  wbs_can_hlp_i.addr_i <= wb_addr_fifo_test_if(WB_ADDS_WIDTH-1 downto 0);

  -- Set upt clock generator
  clock_gen(clk, clock_ena, C_CLK_PERIOD);

  iCAN_HLP_TOP : entity work.can_hlp_top
    port map
    (
      WB_CLK     => clk,
      WB_RST     => reset,

      WB_WBS_I   => wbs_can_hlp_i,
      WB_WBS_O   => wbs_can_hlp_o,

      -- Interface to wishbone FIFO
      -- WB master receives WB replies on this interface
      DP0_DT_O   => dp0_dt,
      DP0_EPTY_O => dp0_epty,
      DP0_RD_I   => dp0_rd,

      -- Interface to Wishbone FIFO
      -- WB master initiates WB transactions on this interface
      DP1_DT_I   => dp1_dt,
      DP1_FULL_O => dp1_full,
      DP1_WR_I   => dp1_wr,

      -- CAN node ID
      CAN_NODE_ID => can_hlp_node_id,

      -- CAN bus signals
      CAN_TX    => can0_tx,
      CAN_RX    => can0_rx
      );

  iWB_FIFO_TEST_IF : entity work.wb_fifo_test_if
    port map
    (
      WB_CLK => clk,
      WB_RST => reset,

      WB_WBM_O.dat_o  => wbs_can_hlp_i.dat_i,
      WB_WBM_O.we_o   => wbs_can_hlp_i.we_i,
      WB_WBM_O.addr_o => wb_addr_fifo_test_if,
      WB_WBM_O.cyc_o  => wbs_can_hlp_i.cyc_i,
      WB_WBM_O.stb_o  => wbs_can_hlp_i.stb_i,

      WB_WBM_I.dat_i => wbs_can_hlp_o.dat_o,
      WB_WBM_I.err_i => wbs_can_hlp_o.err_o,
      WB_WBM_I.ack_i => wbs_can_hlp_o.ack_o,

      -- Interface to wishbone FIFO
      -- WB master receives WB replies on this interface
      DP0_DT_I   => dp0_dt,
      DP0_EPTY_I => dp0_epty,
      DP0_RD_O   => dp0_rd,

      -- Interface to Wishbone FIFO
      -- WB master initiates WB transactions on this interface
      DP1_DT_O   => dp1_dt,
      DP1_FULL_I => dp1_full,
      DP1_WR_O   => dp1_wr
      );


  p_main: process
    constant C_SCOPE     : string := C_TB_SCOPE_DEFAULT;
    variable can_bfm_cfg : t_can_uvvm_bfm_config := C_CAN_UVVM_BFM_CONFIG_DEFAULT;
    variable data_read   : std_logic_vector(15 downto 0);

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

  -- p_main process
  begin
    can_bfm_cfg.clock_period := 6.25 ns; -- 160 MHz
    can_bfm_cfg.bit_rate     := 250000;

    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    enable_log_msg(ALL_MESSAGES);
    --disable_log_msg(ALL_MESSAGES);
    --enable_log_msg(ID_LOG_HDR);

    log(ID_LOG_HDR, "Start CAN controller testbench at 250 kbit (default)", C_SCOPE);
    ------------------------------------------------------------

    --set_inputs_passive(VOID);
    clock_ena <= true;   -- to start clock generator
    pulse(reset, clk, 10, "Pulsed reset-signal - active for 62.5 ns");

    -- The OpenCores CAN controller in the CAN HLP module needs some time
    -- before it is able to receive first frame. With 10 us it would not be
    -- able to receive first package.
    wait for 100 us;

    can_hlp_write(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_TEST, x"ABCD",
                  "Test write to CAN_REG_TEST", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_check(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_TEST, x"ABCD", ERROR,
                  "Test read back from CAN_REG_TEST", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_RX_MSG_COUNT, data_read,
                 "Read CAN_REG_RX_MSG_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_TX_MSG_COUNT, data_read,
                 "Read CAN_REG_TX_MSG_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_READ_COUNT, data_read,
                 "Read CAN_REG_READ_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_WRITE_COUNT, data_read,
                 "Read CAN_REG_WRITE_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_STATUS_ALERT_COUNT, data_read,
                 "Read CAN_REG_STATUS_ALERT_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_UNKNOWN_COUNT, data_read,
                 "Read CAN_REG_UNKNOWN_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    wait for 10 us;
    log(ID_LOG_HDR, "Change bitrate to 1 Mbit", C_SCOPE);
    ------------------------------------------------------------

    can_hlp_write(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_CLK_PRESCALE, x"0007",
                  "Change bitrate to 1 Mbit", clk, can1_tx, can1_rx, can_bfm_cfg);

    wait for 400 us;             -- to allow some time for completion
    can_bfm_cfg.bit_rate     := 1000000;

    wait for 1 us;
    log(ID_LOG_HDR, "Start CAN controller testbench at 1 Mbit", C_SCOPE);
    ------------------------------------------------------------

    can_hlp_write(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_TEST, x"ABCD",
                  "Test write to CAN_REG_TEST", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_check(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_TEST, x"ABCD", ERROR,
                  "Test read back from CAN_REG_TEST", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_RX_MSG_COUNT, data_read,
                 "Read CAN_REG_RX_MSG_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_TX_MSG_COUNT, data_read,
                 "Read CAN_REG_TX_MSG_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_READ_COUNT, data_read,
                 "Read CAN_REG_READ_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_WRITE_COUNT, data_read,
                 "Read CAN_REG_WRITE_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_STATUS_ALERT_COUNT, data_read,
                 "Read CAN_REG_STATUS_ALERT_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    can_hlp_read(can_hlp_node_id, "0000000" & WB_ADD.CAN_REG_UNKNOWN_COUNT, data_read,
                 "Read CAN_REG_UNKNOWN_COUNT", clk, can1_tx, can1_rx, can_bfm_cfg);

    wait for 100 us;             -- to allow some time for completion

    report_alert_counters(FINAL); -- Report final counters and print conclusion for simulation (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    -- Finish the simulation
    std.env.finish;
    wait;  -- to stop completely

  end process p_main;

end func;
