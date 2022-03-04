-------------------------------------------------------------------------------
-- Title      : DCS CAN-bus High Level Protocol (HLP) UVVM BFM
-- Project    : ITS Readout Unit (WP10)
-------------------------------------------------------------------------------
-- File       : can_hlp_uvvm_bfm_pkg.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    : Western Norway University of Applied Sciences
-- Created    : 2018-06-20
-- Last update: 2018-08-11
-- Platform   : Ubuntu Linux 16.04
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Bus Functional Model (BFM) for the DCS CAN bus
--              High Level Protocol (HLP) for use with Bitvis UVVM test benches
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-06-20  1.0      simon	Created
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use work.intercon_pkg.all;
use work.can_hlp_pkg.all;
use work.can_bfm_pkg.all;
use work.can_uvvm_bfm_pkg.all;


package can_hlp_uvvm_bfm_pkg is
  constant C_SCOPE           : string  := "CAN HLP BFM";

  -- Write data to the CAN HLP module, using the HLP protocol,
  procedure can_hlp_write (
    constant node_id      : in  std_logic_vector(7 downto 0);
    constant addr         : in  std_logic_vector(14 downto 0);
    constant data         : in  std_logic_vector(15 downto 0);
    constant msg          : in  string;
    signal   clk          : in  std_logic;
    signal   can_tx       : out std_logic;
    signal   can_rx       : in  std_logic;
    constant config       : in  t_can_uvvm_bfm_config := C_CAN_UVVM_BFM_CONFIG_DEFAULT;
    constant scope        : in  string          := C_SCOPE;
    constant msg_id_panel : in  t_msg_id_panel  := shared_msg_id_panel;

    -- overwrite if called from other procedure like can_hlp_check
    constant proc_name    : in string := "can_hlp_write"
    );


  -- Read data from the CAN HLP module, using the HLP protocol,
  procedure can_hlp_read (
    constant node_id      : in  std_logic_vector(7 downto 0);
    constant addr         : in  std_logic_vector(14 downto 0);
    variable data         : out std_logic_vector(15 downto 0);
    constant msg          : in  string;
    signal   clk          : in  std_logic;
    signal   can_tx       : out std_logic;
    signal   can_rx       : in  std_logic;
    constant config       : in  t_can_uvvm_bfm_config := C_CAN_UVVM_BFM_CONFIG_DEFAULT;
    constant scope        : in  string          := C_SCOPE;
    constant msg_id_panel : in  t_msg_id_panel  := shared_msg_id_panel;

    -- overwrite if called from other procedure like can_hlp_check
    constant proc_name    : in  string          := "can_hlp_read"
    );

  -- Read data from the CAN HLP module using the HLP protocol,
  -- and check that the returned data matches expected value
  procedure can_hlp_check (
    constant node_id      : in  std_logic_vector(7 downto 0);
    constant addr         : in  std_logic_vector(14 downto 0);
    constant data_exp     : in  std_logic_vector(15 downto 0);
    constant alert_level  : in  t_alert_level        := error;
    constant msg          : in  string;
    signal   clk          : in  std_logic;
    signal   can_tx       : out std_logic;
    signal   can_rx       : in  std_logic;
    constant config       : in  t_can_uvvm_bfm_config := C_CAN_UVVM_BFM_CONFIG_DEFAULT;
    constant scope        : in  string               := C_SCOPE;
    constant msg_id_panel : in  t_msg_id_panel       := shared_msg_id_panel
    );

end package can_hlp_uvvm_bfm_pkg;


package body can_hlp_uvvm_bfm_pkg is

  ---------------------------------------------------------------------------
  -- Procedures for CAN bus HLP read/write
  ---------------------------------------------------------------------------

  -- Write data to the CAN HLP module, using the HLP protocol,
  procedure can_hlp_write (
    constant node_id      : in  std_logic_vector(7 downto 0);
    constant addr         : in  std_logic_vector(14 downto 0);
    constant data         : in  std_logic_vector(15 downto 0);
    constant msg          : in  string;
    signal   clk          : in  std_logic;
    signal   can_tx       : out std_logic;
    signal   can_rx       : in  std_logic;
    constant config       : in  t_can_uvvm_bfm_config := C_CAN_UVVM_BFM_CONFIG_DEFAULT;
    constant scope        : in  string          := C_SCOPE;
    constant msg_id_panel : in  t_msg_id_panel  := shared_msg_id_panel;

    -- overwrite if called from other procedure like can_hlp_check
    constant proc_name    : in  string := "can_hlp_write"
    ) is
    -- Only 15-bit address in RU/CAN-HLP wishbone
    variable addr_msb : std_logic_vector(7 downto 0) := '0' & addr(14 downto 8);
    variable addr_lsb : std_logic_vector(7 downto 0) := addr(7 downto 0);

    constant proc_call : string := "can_hlp_write(NodeID:" & to_string(node_id, HEX, AS_IS, INCL_RADIX) &
                                   ", A:" & to_string(addr, HEX, AS_IS, INCL_RADIX) &
                                   ", D:" & to_string(data, HEX, AS_IS, INCL_RADIX) & ")";

    variable can_xmit_data         : can_payload_t;
    variable can_recv_data         : can_payload_t;
    variable can_recv_data_len     : natural;
    variable can_xmit_arb_id       : std_logic_vector(28 downto 0) := (others => '0');
    variable can_recv_arb_id       : std_logic_vector(28 downto 0) := (others => '0');
    variable can_recv_timeout      : std_logic                     := '0';
    variable can_recv_ext_id       : std_logic                     := '0';
    variable can_recv_remote_frame : std_logic                     := '0';

  begin
    --==========================================================================
    -- Send WRITE_COMMAND
    --==========================================================================
    can_xmit_arb_id(10 downto 3)  := node_id;
    can_xmit_arb_id(2 downto 0)   := C_WRITE_COMMAND;

    can_xmit_data(0) := addr_msb;
    can_xmit_data(1) := addr_lsb;
    can_xmit_data(2) := data(15 downto 8);
    can_xmit_data(3) := data(7 downto 0);

    can_uvvm_write(can_xmit_arb_id,
                   '0', -- No extended id
                   '0', -- No remote frame request
                   can_xmit_data,
                   to_integer(unsigned(C_WRITE_COMMAND_LEN)),
                   msg,
                   clk,
                   can_tx,
                   can_rx,
                   scope,
                   msg_id_panel,
                   config,
                   proc_name);

    --==========================================================================
    -- Receive WRITE_RESPONSE
    --==========================================================================
    can_uvvm_read(can_recv_arb_id,
                  can_recv_ext_id,
                  can_recv_remote_frame,
                  can_recv_data,
                  can_recv_data_len,
                  msg,
                  clk,
                  can_tx,
                  can_rx,
                  can_recv_timeout,
                  scope,
                  msg_id_panel,
                  config,
                  proc_name);

    --==========================================================================
    -- Verify data in WRITE_RESPONSE
    --==========================================================================
    if can_recv_ext_id = '1' then
      alert(error, "can_hlp_read => Failed. Received extended CAN frame.", scope);
      return;
    end if;

    if can_recv_remote_frame = '1' then
      alert(error, "can_hlp_read => Failed. Received remote frame request.", scope);
      return;
    end if;

    if can_recv_timeout = '1' then
      alert(error, "can_hlp_read => Failed. Timeout.", scope);
      return;
    end if;

    -- WRITE_RESPONSE should reply with the same node ID
    if can_recv_arb_id(10 downto 3) /= node_id then
      alert(error, "can_hlp_write => Failed. Wrong node ID in response.", scope);
      return;
    end if;

    if can_recv_arb_id(2 downto 0) /= C_WRITE_RESPONSE then
      alert(error, "can_hlp_write => Failed. WRITE_RESPONSE not received.", scope);
      return;
    end if;

    if can_recv_data_len /= to_integer(unsigned(C_WRITE_RESPONSE_LEN)) then
      alert(error, "can_hlp_write => Failed. Incorrect length of WRITE_RESPONSE data.", scope);
      return;
    end if;

    -- WRITE_RESPONSE should reply with the same address
    if can_recv_data(0) /= addr_msb or can_recv_data(1) /= addr_lsb then
      alert(error, "can_hlp_write => Failed. Different address in WRITE_RESPONSE.", scope);
      return;
    end if;

    -- WRITE_RESPONSE should reply with the same data
    if can_recv_data(2) /= data(15 downto 8) or can_recv_data(3) /= data(7 downto 0) then
      alert(error, "can_hlp_write => Failed. Different data in WRITE_RESPONSE.", scope);
      return;
    end if;

    -- Add log message only if this procedure was called directly
    if proc_name = "can_hlp_write" then
      log(config.id_for_bfm, proc_call & " completed. " & msg, scope, msg_id_panel);
    end if;

  end procedure can_hlp_write;


  -- Read data from the CAN HLP module, using the HLP protocol,
  procedure can_hlp_read (
    constant node_id      : in  std_logic_vector(7 downto 0);
    constant addr         : in  std_logic_vector(14 downto 0);
    variable data         : out std_logic_vector(15 downto 0);
    constant msg          : in  string;
    signal   clk          : in  std_logic;
    signal   can_tx       : out std_logic;
    signal   can_rx       : in  std_logic;
    constant config       : in  t_can_uvvm_bfm_config := C_CAN_UVVM_BFM_CONFIG_DEFAULT;
    constant scope        : in  string               := C_SCOPE;
    constant msg_id_panel : in  t_msg_id_panel       := shared_msg_id_panel;

    -- overwrite if called from other procedure like can_hlp_check
    constant proc_name    : in  string          := "can_hlp_read"
    ) is
    -- Only 15-bit address in RU/CAN-HLP wishbone
    variable addr_msb : std_logic_vector(7 downto 0) := '0' & addr(14 downto 8);
    variable addr_lsb : std_logic_vector(7 downto 0) := addr(7 downto 0);

    constant proc_call   : string := "can_hlp_read(NodeID:" & to_string(node_id, HEX, AS_IS, INCL_RADIX) &
                                     ", A:" & to_string(addr, HEX, AS_IS, INCL_RADIX) & ")";

    variable can_xmit_data     : can_payload_t;
    variable can_recv_data     : can_payload_t;
    variable can_recv_data_len : natural;
    variable can_xmit_arb_id   : std_logic_vector(28 downto 0) := (others => '0');
    variable can_recv_arb_id   : std_logic_vector(28 downto 0) := (others => '0');
    variable can_recv_timeout      : std_logic                     := '0';
    variable can_recv_ext_id       : std_logic                     := '0';
    variable can_recv_remote_frame : std_logic                     := '0';

  begin
    --==========================================================================
    -- Send READ_COMMAND
    --==========================================================================
    can_xmit_arb_id(10 downto 3)  := node_id;
    can_xmit_arb_id(2 downto 0)   := C_READ_COMMAND;

    can_xmit_data(0) := addr_msb;
    can_xmit_data(1) := addr_lsb;

    can_uvvm_write(can_xmit_arb_id,
                   '0', -- No extended id
                   '0', -- No remote frame request
                   can_xmit_data,
                   to_integer(unsigned(C_READ_COMMAND_LEN)),
                   msg,
                   clk,
                   can_tx,
                   can_rx,
                   scope,
                   msg_id_panel,
                   config,
                   proc_name);

    --==========================================================================
    -- Receive READ_RESPONSE
    --==========================================================================
    can_uvvm_read(can_recv_arb_id,
                  can_recv_ext_id,
                  can_recv_remote_frame,
                  can_recv_data,
                  can_recv_data_len,
                  msg,
                  clk,
                  can_tx,
                  can_rx,
                  can_recv_timeout,
                  scope,
                  msg_id_panel,
                  config,
                  proc_name);

    --==========================================================================
    -- Verify data in WRITE_RESPONSE
    --==========================================================================
    if can_recv_ext_id = '1' then
      alert(error, "can_hlp_read => Failed. Received extended CAN frame.", scope);
      return;
    end if;

    if can_recv_remote_frame = '1' then
      alert(error, "can_hlp_read => Failed. Received remote frame request.", scope);
      return;
    end if;

    if can_recv_timeout = '1' then
      alert(error, "can_hlp_read => Failed. Timeout.", scope);
      return;
    end if;

    -- WRITE_RESPONSE should reply with the same node ID
    if can_recv_arb_id(10 downto 3) /= node_id then
      alert(error, "can_hlp_read => Failed. Wrong node ID in response.", scope);
      return;
    end if;

    if can_recv_arb_id(2 downto 0) /= C_READ_RESPONSE then
      alert(error, "can_hlp_read => Failed. READ_RESPONSE not received.", scope);
      return;
    end if;

    if can_recv_data_len /= to_integer(unsigned(C_READ_RESPONSE_LEN)) then
      alert(error, "can_hlp_read => Failed. Incorrect length of READ_RESPONSE data.", scope);
      return;
    end if;

    -- READ_RESPONSE should reply with the same address
    if can_recv_data(0) /= addr_msb or can_recv_data(1) /= addr_lsb then
      alert(error, "can_hlp_write => Failed. Different address in WRITE_RESPONSE.", scope);
      return;
    end if;

    data(15 downto 8) := can_recv_data(2);
    data(7  downto 0) := can_recv_data(3);

    if proc_name = "can_hlp_read" then
      log(config.id_for_bfm, proc_call & "=> " & to_string(data, HEX, SKIP_LEADING_0, INCL_RADIX) &
          ". " & msg, scope, msg_id_panel);
    end if;
  end procedure can_hlp_read;


  -- Read data from the CAN HLP module using the HLP protocol,
  -- and check that the returned data matches expected value
  procedure can_hlp_check (
    constant node_id      : in  std_logic_vector(7 downto 0);
    constant addr         : in  std_logic_vector(14 downto 0);
    constant data_exp     : in  std_logic_vector(15 downto 0);
    constant alert_level  : in  t_alert_level        := error;
    constant msg          : in  string;
    signal   clk          : in  std_logic;
    signal   can_tx       : out std_logic;
    signal   can_rx       : in  std_logic;
    constant config       : in  t_can_uvvm_bfm_config := C_CAN_UVVM_BFM_CONFIG_DEFAULT;
    constant scope        : in  string               := C_SCOPE;
    constant msg_id_panel : in  t_msg_id_panel       := shared_msg_id_panel
    ) is
    constant proc_name   : string := "can_hlp_check";
    constant proc_call   : string := "can_hlp_check(NodeID:" & to_string(node_id, HEX, AS_IS, INCL_RADIX) &
                                     ", A:" & to_string(addr, HEX, AS_IS, INCL_RADIX) &
                                     ", D:" & to_string(data_exp, HEX, AS_IS, INCL_RADIX) & ")";

    variable v_data_value : std_logic_vector(15 downto 0);
  begin
    can_hlp_read(node_id, addr, v_data_value, msg, clk, can_tx, can_rx,
                 config, scope, msg_id_panel, proc_name);

    if v_data_value /= data_exp then
      alert(alert_level, proc_call & "=> Failed. Got " &
            to_string(v_data_value, HEX, AS_IS, INCL_RADIX) & LF & msg, scope);
    else
      log(config.id_for_bfm, proc_call & "=> OK. " & msg, scope, msg_id_panel);
    end if;

  end procedure can_hlp_check;


end package body can_hlp_uvvm_bfm_pkg;
