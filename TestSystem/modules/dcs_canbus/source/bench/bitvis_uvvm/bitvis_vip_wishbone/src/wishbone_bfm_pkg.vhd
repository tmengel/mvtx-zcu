--========================================================================================================================
-- Copyright Bitvis 2016
-- This Wishbone BFM is for Bitvis Internal use only and not yet ready for a public release.
-- At least the following issues need to be handled:
-- - Quality check of the code
-- - Beautification of code
-- - More code commenting
-- - Verification

--========================================================================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

--========================================================================================================================
--========================================================================================================================
package wb_bfm_pkg is

  --========================================================================================================================
  -- Types and constants for WB BFM
  --========================================================================================================================
  constant C_SCOPE : string := "WB BFM";

  type t_wbm_if is record
    -- Common for slave and master interfaces
    dat_o : std_logic_vector; -- to dut
    dat_i : std_logic_vector; -- from dut

    -- Master interface
    addr_o : std_logic_vector; -- to dut, address
    cyc_o : std_logic;        -- to dut, valid bus cycle
    stb_o : std_logic;        -- to dut, chip select
    we_o : std_logic;         -- to dut, write enable
    ack_i : std_logic;        -- from dut
  end record;

  -- Configuration record to be assigned in the test harness.
  type t_wb_bfm_config is
  record
    max_wait_cycles          : integer;
    max_wait_cycles_severity : t_alert_level;
    clock_period             : time;  -- Needed in the VVC
    id_for_bfm               : t_msg_id;
    id_for_bfm_wait          : t_msg_id;
    id_for_bfm_poll          : t_msg_id;
  end record;

  -- Define the default value for the BFM config
  constant C_WB_BFM_CONFIG_DEFAULT : t_wb_bfm_config := (
    max_wait_cycles          => 50,
    max_wait_cycles_severity => failure,
    clock_period             => 10 ns,
    id_for_bfm               => ID_BFM,
    id_for_bfm_wait          => ID_BFM_WAIT,
    id_for_bfm_poll          => ID_BFM_POLL
  );


  --========================================================================================================================
  -- BFM procedures
  --========================================================================================================================

  function init_wbm_if_signals(
    addr_width : natural;
    data_width : natural
    ) return t_wbm_if;

  procedure wb_write (
    constant addr_value       : in  std_logic_vector;
    constant data_value       : in  std_logic_vector;
    constant msg              : in  string;
    signal clk                : in  std_logic;
    signal wb_if        : inout t_wbm_if;
    constant scope            : in  string                    := C_SCOPE;
    constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
    constant config           : in  t_wb_bfm_config     := C_WB_BFM_CONFIG_DEFAULT
    );

  procedure wb_read (
    constant addr_value       : in  std_logic_vector;
    variable data_value       : out std_logic_vector;
    constant msg              : in  string;
    signal clk                : in  std_logic;
    signal wb_if        : inout t_wbm_if;
    constant scope            : in  string                    := C_SCOPE;
    constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
    constant config           : in  t_wb_bfm_config     := C_WB_BFM_CONFIG_DEFAULT;
    constant proc_name        : in  string                    := "wb_read"  -- overwrite if called from other procedure like wb_check
    );

  procedure wb_check (
    constant addr_value       : in  std_logic_vector;
    constant data_exp         : in  std_logic_vector;
    constant alert_level      : in  t_alert_level             := error;
    constant msg              : in  string;
    signal clk                : in  std_logic;
    signal wb_if        : inout t_wbm_if;
    constant scope            : in  string                    := C_SCOPE;
    constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
    constant config           : in  t_wb_bfm_config     := C_WB_BFM_CONFIG_DEFAULT
    );

end package wb_bfm_pkg;


--========================================================================================================================
--========================================================================================================================

package body wb_bfm_pkg is

  function init_wbm_if_signals(
    addr_width : natural;
    data_width : natural
    ) return t_wbm_if is
    variable result : t_wbm_if(dat_o(data_width - 1 downto 0),
                                         dat_i(data_width-1 downto 0),
                                         addr_o(addr_width - 1 downto 0)
                                         );
  begin
    -- BFM to DUT signals
    result.dat_o            := (others => '0');
    result.addr_o            := (others => '0');
    result.cyc_o            := '0';
    result.stb_o            := '0';
    result.we_o             := '0';

    -- DUT to BFM signals
    result.dat_i            := (others => 'Z');
    result.ack_i            := 'Z';
    return result;
  end function;

  procedure wb_write (
    constant addr_value       : in  std_logic_vector;
    constant data_value       : in  std_logic_vector;
    constant msg              : in  string;
    signal clk                : in  std_logic;
    signal wb_if        : inout t_wbm_if;
    constant scope            : in  string                    := C_SCOPE;
    constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
    constant config           : in  t_wb_bfm_config     := C_WB_BFM_CONFIG_DEFAULT
    ) is
    constant proc_name : string := "wb_write";
    constant proc_call : string := "wb_write(A:" & to_string(addr_value, HEX, AS_IS, INCL_RADIX) &
                                   ", " & to_string(data_value, HEX, AS_IS, INCL_RADIX) & ")";
    -- normalize_and_check to the DUT addr/data widths
    variable v_normalized_addr : std_logic_vector(wb_if.addr_o'length-1 downto 0) :=
      normalize_and_check(std_logic_vector(addr_value), wb_if.addr_o, ALLOW_NARROWER, "address", "wb_if.addr_o", msg);
    variable v_normalized_data : std_logic_vector(wb_if.dat_o'length-1 downto 0) :=
      normalize_and_check(data_value, wb_if.dat_o, ALLOW_NARROWER, "data", "wb_if.dat_o", msg);

    variable timeout : boolean := false;
  begin
    wait_until_given_time_after_rising_edge(clk, config.clock_period/4);

    wb_if.dat_o    <= v_normalized_data;
    wb_if.addr_o    <= v_normalized_addr;
    wb_if.cyc_o    <= '1'; -- Valid bus cycle activated
    wb_if.stb_o    <= '1'; -- Chip-select
    wb_if.we_o     <= '1'; -- Write enable

    wait until falling_edge(clk);     -- wait for DUT update of signal
    for cycle in 1 to config.max_wait_cycles loop
      if wb_if.ack_i = '0' then
        wait until falling_edge(clk);
      else
        exit;
      end if;
      if cycle = config.max_wait_cycles then
        timeout := true;
      end if;
    end loop;

    -- did we timeout?
    if timeout then
      alert(config.max_wait_cycles_severity, proc_call & "=> Failed. Timeout waiting for ack_i", scope);
    else
      wait until rising_edge(clk);
      wait_until_given_time_after_rising_edge(clk, config.clock_period/4);
    end if;

    wb_if <= init_wbm_if_signals(wb_if.addr_o'length, wb_if.dat_o'length);
    log(config.id_for_bfm, proc_call & " completed. " & msg, scope, msg_id_panel);
  end procedure wb_write;


  procedure wb_read (
    constant addr_value       : in  std_logic_vector;
    variable data_value       : out std_logic_vector;
    constant msg              : in  string;
    signal clk                : in  std_logic;
    signal wb_if        : inout t_wbm_if;
    constant scope            : in  string                    := C_SCOPE;
    constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
    constant config           : in  t_wb_bfm_config     := C_WB_BFM_CONFIG_DEFAULT;
    constant proc_name        : in  string                    := "wb_read"  -- overwrite if called from other procedure like wb_check
    ) is
    constant proc_call : string := "wb_read(A:" & to_string(addr_value, HEX, AS_IS, INCL_RADIX) & ")";

    -- normalize_and_check to the DUT addr/data widths
    variable v_normalized_addr : std_logic_vector(wb_if.addr_o'length-1 downto 0) :=
      normalize_and_check(std_logic_vector(addr_value), wb_if.addr_o, ALLOW_NARROWER, "addr", "wb_if.addr_o", msg);
    variable v_normalized_data : std_logic_vector(wb_if.dat_i'length-1 downto 0) :=
      normalize_and_check(data_value, wb_if.dat_i, ALLOW_NARROWER, "data", "wb_if.dat_i", msg);

    -- Helper variables
    variable timeout : boolean := false;
  begin
    wait_until_given_time_after_rising_edge(clk, config.clock_period/4);
    wb_if.addr_o    <= v_normalized_addr;
    wb_if.cyc_o    <= '1'; -- Valid bus cycle activated
    wb_if.stb_o    <= '1'; -- Chip-select
    wb_if.we_o     <= '0'; -- Read

    wait until falling_edge(clk);     -- wait for DUT update of signal
    for cycle in 1 to config.max_wait_cycles loop
      if wb_if.ack_i = '0' then
        wait until falling_edge(clk);
      else
        exit;
      end if;
      if cycle = config.max_wait_cycles then
        timeout := true;
      end if;
    end loop;

    -- did we timeout?
    if timeout then
      alert(config.max_wait_cycles_severity, proc_call & "=> Failed. Timeout waiting for ack_i", scope);
    else
      wait until rising_edge(clk);
      wait_until_given_time_after_rising_edge(clk, config.clock_period/4);
    end if;

    v_normalized_data := wb_if.dat_i;
    data_value        := v_normalized_data(data_value'length-1 downto 0);

    wb_if <= init_wbm_if_signals(wb_if.addr_o'length, wb_if.dat_i'length);

    if proc_name = "wb_read" then
      log(config.id_for_bfm, proc_call & "=> " & to_string(data_value, HEX, SKIP_LEADING_0, INCL_RADIX) & ". " & msg, scope, msg_id_panel);
    end if;
  end procedure wb_read;

  procedure wb_check (
    constant addr_value       : in  std_logic_vector;
    constant data_exp         : in  std_logic_vector;
    constant alert_level      : in  t_alert_level             := error;
    constant msg              : in  string;
    signal clk                : in  std_logic;
    signal wb_if        : inout t_wbm_if;
    constant scope            : in  string                    := C_SCOPE;
    constant msg_id_panel     : in  t_msg_id_panel            := shared_msg_id_panel;
    constant config           : in  t_wb_bfm_config     := C_WB_BFM_CONFIG_DEFAULT
    ) is
    constant proc_name : string := "wb_check";
    constant proc_call : string := "wb_check(A:" & to_string(addr_value, HEX, AS_IS, INCL_RADIX) & ", " & to_string(data_exp, HEX, AS_IS, INCL_RADIX) & ")";

    -- normalize_and_check to the DUT addr/data widths
    variable v_normalized_data : std_logic_vector(wb_if.dat_i'length-1 downto 0) :=
      normalize_and_check(data_exp, wb_if.dat_i, ALLOW_NARROWER, "data", "wb_if.dat_i", msg);
    
    -- Helper variables
    variable v_data_value : std_logic_vector(wb_if.dat_i'length-1 downto 0) := (others => '0');
    variable v_check_ok   : boolean;
  begin
    wb_read(addr_value, v_data_value, msg, clk, wb_if, scope, msg_id_panel, config, proc_name);
    v_check_ok := true;
    for i in 0 to (v_normalized_data'length)-1 loop
      if v_normalized_data(i) = '-' or v_normalized_data(i) = v_data_value(i) then
        v_check_ok := true;
      else
        v_check_ok := false;
        exit;
      end if;
    end loop;

    if not v_check_ok then
      alert(alert_level, proc_call & "=> Failed. slv Was " & to_string(v_data_value, HEX, AS_IS, INCL_RADIX) & ". Expected " & to_string(data_exp, HEX, AS_IS, INCL_RADIX) & "." & LF & msg, scope);
    else
      log(config.id_for_bfm, proc_call & "=> OK, received data = " & to_string(v_data_value, HEX, SKIP_LEADING_0, INCL_RADIX) & ". " & msg, scope, msg_id_panel);
    end if;
  end procedure wb_check;

end package body wb_bfm_pkg;


