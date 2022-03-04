-------------------------------------------------------------------------------
-- Title      : Radiation_Monitor wishbone
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : radiation_monitor_wishbone_.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-25
-- Last update: 2017-11-17
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone connection for controlling the radiation_monitor_wishbone
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.radiation_monitor_pkg.all;

entity radiation_monitor_wishbone is
  generic (
    G_MODULE_0_MISMATCH_WIDTH     : integer := 4;
    G_MODULE_1_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_2_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_3_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_4_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_5_MISMATCH_WIDTH     : integer := 6;
    G_MODULE_DUMMY_MISMATCH_WIDTH : integer := 1
    );
  port (
    WB_CLK   : in  std_logic;
    WB_RST   : in  std_logic;
    WB_WBS_I : in  wbs_i_type;
    WB_WBS_O : out wbs_o_type;

    MODULE_0_COUNTER     : in t_radmon_cntr_array(G_MODULE_0_MISMATCH_WIDTH-1 downto 0);
    MODULE_0_COUNTER_2ND : in t_radmon_cntr_array(G_MODULE_0_MISMATCH_WIDTH-1 downto 0);

    MODULE_1_COUNTER     : in t_radmon_cntr_array(G_MODULE_1_MISMATCH_WIDTH-1 downto 0);
    MODULE_1_COUNTER_2ND : in t_radmon_cntr_array(G_MODULE_1_MISMATCH_WIDTH-1 downto 0);

    MODULE_2_COUNTER     : in t_radmon_cntr_array(G_MODULE_2_MISMATCH_WIDTH-1 downto 0);
    MODULE_2_COUNTER_2ND : in t_radmon_cntr_array(G_MODULE_2_MISMATCH_WIDTH-1 downto 0);

    MODULE_3_COUNTER     : in t_radmon_cntr_array(G_MODULE_3_MISMATCH_WIDTH-1 downto 0);
    MODULE_3_COUNTER_2ND : in t_radmon_cntr_array(G_MODULE_3_MISMATCH_WIDTH-1 downto 0);

    MODULE_4_COUNTER     : in t_radmon_cntr_array(G_MODULE_4_MISMATCH_WIDTH-1 downto 0);
    MODULE_4_COUNTER_2ND : in t_radmon_cntr_array(G_MODULE_4_MISMATCH_WIDTH-1 downto 0);

    MODULE_5_COUNTER     : in t_radmon_cntr_array(G_MODULE_5_MISMATCH_WIDTH-1 downto 0);
    MODULE_5_COUNTER_2ND : in t_radmon_cntr_array(G_MODULE_5_MISMATCH_WIDTH-1 downto 0);

    MODULE_DUMMY_COUNTER     : in t_radmon_cntr_array(G_MODULE_DUMMY_MISMATCH_WIDTH-1 downto 0);
    MODULE_DUMMY_COUNTER_2ND : in t_radmon_cntr_array(G_MODULE_DUMMY_MISMATCH_WIDTH-1 downto 0)
    );
end entity radiation_monitor_wishbone;

architecture structural of radiation_monitor_wishbone is

  -----------------------------------------------------------------------------
  -- Wishbone address space
  -----------------------------------------------------------------------------

  constant C_MODULE_0_ADDRESS_START     : integer := 0;
  constant C_MODULE_1_ADDRESS_START     : integer := C_MODULE_0_ADDRESS_START + G_MODULE_0_MISMATCH_WIDTH;
  constant C_MODULE_2_ADDRESS_START     : integer := C_MODULE_1_ADDRESS_START + G_MODULE_1_MISMATCH_WIDTH;
  constant C_MODULE_3_ADDRESS_START     : integer := C_MODULE_2_ADDRESS_START + G_MODULE_2_MISMATCH_WIDTH;
  constant C_MODULE_4_ADDRESS_START     : integer := C_MODULE_3_ADDRESS_START + G_MODULE_3_MISMATCH_WIDTH;
  constant C_MODULE_5_ADDRESS_START     : integer := C_MODULE_4_ADDRESS_START + G_MODULE_4_MISMATCH_WIDTH;
  constant C_MODULE_DUMMY_ADDRESS_START : integer := C_MODULE_5_ADDRESS_START + G_MODULE_5_MISMATCH_WIDTH;
  constant C_NUM_REG                    : integer := C_MODULE_DUMMY_ADDRESS_START + G_MODULE_DUMMY_MISMATCH_WIDTH;

  type t_WB_ADDS is record
    -- General purpose registers
    -- tx side
    MODULE_0_FIRST     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_0_LAST      : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_1_FIRST     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_1_LAST      : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_2_FIRST     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_2_LAST      : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_3_FIRST     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_3_LAST      : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_4_FIRST     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_4_LAST      : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_5_FIRST     : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_5_LAST      : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_DUMMY_FIRST : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    MODULE_DUMMY_LAST  : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
    ---------------------------------------------------------------------------
    NUM_REGS           : std_logic_vector(WB_ADDS_WIDTH-1 downto 0);
  end record t_WB_ADDS;

  constant WB_ADD : t_WB_ADDS := (
    MODULE_0_FIRST     => std_logic_vector(to_unsigned(C_MODULE_0_ADDRESS_START, WB_ADDS_WIDTH)),
    MODULE_0_LAST      => std_logic_vector(to_unsigned(C_MODULE_1_ADDRESS_START -1, WB_ADDS_WIDTH)),
    MODULE_1_FIRST     => std_logic_vector(to_unsigned(C_MODULE_1_ADDRESS_START, WB_ADDS_WIDTH)),
    MODULE_1_LAST      => std_logic_vector(to_unsigned(C_MODULE_2_ADDRESS_START -1, WB_ADDS_WIDTH)),
    MODULE_2_FIRST     => std_logic_vector(to_unsigned(C_MODULE_2_ADDRESS_START, WB_ADDS_WIDTH)),
    MODULE_2_LAST      => std_logic_vector(to_unsigned(C_MODULE_3_ADDRESS_START -1, WB_ADDS_WIDTH)),
    MODULE_3_FIRST     => std_logic_vector(to_unsigned(C_MODULE_3_ADDRESS_START, WB_ADDS_WIDTH)),
    MODULE_3_LAST      => std_logic_vector(to_unsigned(C_MODULE_4_ADDRESS_START -1, WB_ADDS_WIDTH)),
    MODULE_4_FIRST     => std_logic_vector(to_unsigned(C_MODULE_4_ADDRESS_START, WB_ADDS_WIDTH)),
    MODULE_4_LAST      => std_logic_vector(to_unsigned(C_MODULE_5_ADDRESS_START -1, WB_ADDS_WIDTH)),
    MODULE_5_FIRST     => std_logic_vector(to_unsigned(C_MODULE_5_ADDRESS_START, WB_ADDS_WIDTH)),
    MODULE_5_LAST      => std_logic_vector(to_unsigned(C_MODULE_DUMMY_ADDRESS_START -1, WB_ADDS_WIDTH)),
    MODULE_DUMMY_FIRST => std_logic_vector(to_unsigned(C_MODULE_DUMMY_ADDRESS_START, WB_ADDS_WIDTH)),
    MODULE_DUMMY_LAST  => std_logic_vector(to_unsigned(C_NUM_REG -1, WB_ADDS_WIDTH)),
    NUM_REGS           => std_logic_vector(to_unsigned(C_NUM_REG, WB_ADDS_WIDTH))
    );
  -- wishbone
--  signal s_wishbone_registers : t_wishbone_registers;
  signal s_wb_wbs_o : wbs_o_type;

begin  -- architecture structural

  -----------------------------------------------------------------------------
  -- Wishone slave WB_WBS_I.ADD
  -----------------------------------------------------------------------------
  --p_wishbone_reg : process (WB_CLK) is
  --begin  -- process p_wishbone_reg
  --  if rising_edge(WB_CLK) then
  --    if WB_RST = '1' then
  --      s_wishbone_registers <= C_WISHBONE_DEFAULTS;
  --    else
  --      if WB_WBS_I.we_i = '1' and WB_WBS_I.stb_i = '1' and WB_WBS_I.cyc_i = '1' then
  --        --case WB_WBS_I.addr_i is

  --          --when WB_ADD.WRITE_CTRL =>
  --          --  s_wb_reg.alpide_protocol.wr_ctrl    <= WB_WBS_I.dat_i;
  --          --  s_wb_reg.alpide_protocol.wr_ctrl_up <= '1';

  --          --when WB_ADD.WRITE_DATA =>
  --          --  s_wb_reg.alpide_protocol.wr_data <= WB_WBS_I.dat_i;

  --          --when WB_ADD.LATCH_CTRL_CNTRS =>
  --          --  s_wb_reg.counters.latch.cmd_broadcast        <= WB_WBS_I.dat_i(C_LATCH_CTRL_CNTRS_bit_broadcast);
  --          --  s_wb_reg.counters.latch.cmd_write            <= WB_WBS_I.dat_i(C_LATCH_CTRL_CNTRS_bit_write);
  --          --  s_wb_reg.counters.latch.cmd_read             <= WB_WBS_I.dat_i(C_LATCH_CTRL_CNTRS_bit_read);
  --          --  s_wb_reg.counters.latch.cmd_opcode           <= WB_WBS_I.dat_i(C_LATCH_CTRL_CNTRS_bit_opcode);
  --          --  s_wb_reg.counters.latch.cmd_trigger_sent     <= WB_WBS_I.dat_i(C_LATCH_CTRL_CNTRS_bit_trigger_sent);
  --          --  s_wb_reg.counters.latch.cmd_trigger_not_sent <= WB_WBS_I.dat_i(C_LATCH_CTRL_CNTRS_bit_trigger_not_sent);
  --          --  s_wb_reg.counters.latch.cmd_wait_exec        <= WB_WBS_I.dat_i(C_LATCH_CTRL_CNTRS_bit_wait_exec);

  --        --when others => null;
  --        --end case;
  --      else
  --        -- pulse registers

  --      end if;
  --    end if;
  --  end if;
  --end process p_wishbone_reg;


  p_wishbone_answer : process (WB_CLK) is
    variable v_ack_o, v_err_o : std_logic;
  begin  -- process p_wishbone_answer
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        v_ack_o          := '0';
        v_err_o          := '0';
        s_wb_wbs_o.ack_o <= '0';
        s_wb_wbs_o.err_o <= '0';
      else

        case to_integer(unsigned(WB_WBS_I.addr_i)) is

          --when WB_ADD.WRITE_CTRL =>     -- Write only register
          --  v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(WB_WBS_I.we_i);
          --  v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and and not(v_err_o);

          --when WB_ADD.GET_IDELAY_VALUE23 =>  -- Read only register
          --  v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
          --  v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          --when WB_ADD.AUTO_PHASE_OFFSET =>  -- Write/Read register
          --  v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
          --  v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when to_integer(unsigned(WB_ADD.MODULE_0_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_0_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.MODULE_1_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_1_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.MODULE_2_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_2_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.MODULE_3_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_3_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.MODULE_4_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_4_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.MODULE_5_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_5_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.MODULE_DUMMY_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_DUMMY_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when others =>
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;  -- read or write to an illegal address
            v_ack_o := '0';

        end case;
        s_wb_wbs_o.ack_o <= v_ack_o;
        s_wb_wbs_o.err_o <= v_err_o;
      end if;
    end if;
  end process p_wishbone_answer;

  -----------------------------------------------------------------------------
  -- Wishbone statemachine
  -----------------------------------------------------------------------------

  p_wishbone_data : process (WB_WBS_I,
                             MODULE_0_COUNTER, MODULE_0_COUNTER_2ND,
                             MODULE_1_COUNTER, MODULE_1_COUNTER_2ND,
                             MODULE_2_COUNTER, MODULE_2_COUNTER_2ND,
                             MODULE_3_COUNTER, MODULE_3_COUNTER_2ND,
                             MODULE_4_COUNTER, MODULE_4_COUNTER_2ND,
                             MODULE_5_COUNTER, MODULE_5_COUNTER_2ND,
                             MODULE_DUMMY_COUNTER, MODULE_DUMMY_COUNTER_2ND) is
  begin  -- process p_wishbone_data
    case to_integer(unsigned(WB_WBS_I.addr_i)) is

      --when WB_ADD.WRITE_DATA =>         -- Read / Write register
      --  s_wb_wbs_o.dat_o <= s_wb_reg.alpide_protocol.wr_data;

      when to_integer(unsigned(WB_ADD.MODULE_0_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_0_LAST)) =>  -- Read only
        s_wb_wbs_o.dat_o                               <= (others => '0');
        s_wb_wbs_o.dat_o(C_WB_COUNTER_RANGE'range)     <= MODULE_0_COUNTER(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_0_FIRST));
        s_wb_wbs_o.dat_o(C_WB_COUNTER_2ND_RANGE'range) <= MODULE_0_COUNTER_2ND(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_0_FIRST));

      when to_integer(unsigned(WB_ADD.MODULE_1_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_1_LAST)) =>  -- Read only
        s_wb_wbs_o.dat_o                               <= (others => '0');
        s_wb_wbs_o.dat_o(C_WB_COUNTER_RANGE'range)     <= MODULE_1_COUNTER(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_1_FIRST));
        s_wb_wbs_o.dat_o(C_WB_COUNTER_2ND_RANGE'range) <= MODULE_1_COUNTER_2ND(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_1_FIRST));

      when to_integer(unsigned(WB_ADD.MODULE_2_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_2_LAST)) =>  -- Read only
        s_wb_wbs_o.dat_o                               <= (others => '0');
        s_wb_wbs_o.dat_o(C_WB_COUNTER_RANGE'range)     <= MODULE_2_COUNTER(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_2_FIRST));
        s_wb_wbs_o.dat_o(C_WB_COUNTER_2ND_RANGE'range) <= MODULE_2_COUNTER_2ND(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_2_FIRST));

      when to_integer(unsigned(WB_ADD.MODULE_3_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_3_LAST)) =>  -- Read only
        s_wb_wbs_o.dat_o                               <= (others => '0');
        s_wb_wbs_o.dat_o(C_WB_COUNTER_RANGE'range)     <= MODULE_3_COUNTER(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_3_FIRST));
        s_wb_wbs_o.dat_o(C_WB_COUNTER_2ND_RANGE'range) <= MODULE_3_COUNTER_2ND(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_3_FIRST));

      when to_integer(unsigned(WB_ADD.MODULE_4_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_4_LAST)) =>  -- Read only
        s_wb_wbs_o.dat_o                               <= (others => '0');
        s_wb_wbs_o.dat_o(C_WB_COUNTER_RANGE'range)     <= MODULE_4_COUNTER(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_4_FIRST));
        s_wb_wbs_o.dat_o(C_WB_COUNTER_2ND_RANGE'range) <= MODULE_4_COUNTER_2ND(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_4_FIRST));

      when to_integer(unsigned(WB_ADD.MODULE_5_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_5_LAST)) =>  -- Read only
        s_wb_wbs_o.dat_o                               <= (others => '0');
        s_wb_wbs_o.dat_o(C_WB_COUNTER_RANGE'range)     <= MODULE_5_COUNTER(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_5_FIRST));
        s_wb_wbs_o.dat_o(C_WB_COUNTER_2ND_RANGE'range) <= MODULE_5_COUNTER_2ND(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_5_FIRST));

      when to_integer(unsigned(WB_ADD.MODULE_DUMMY_FIRST)) to to_integer(unsigned(WB_ADD.MODULE_DUMMY_LAST)) =>  -- Read only
        s_wb_wbs_o.dat_o                               <= (others => '0');
        s_wb_wbs_o.dat_o(C_WB_COUNTER_RANGE'range)     <= MODULE_DUMMY_COUNTER(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_DUMMY_FIRST));
        s_wb_wbs_o.dat_o(C_WB_COUNTER_2ND_RANGE'range) <= MODULE_DUMMY_COUNTER_2ND(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.MODULE_DUMMY_FIRST));

      when others =>
        s_wb_wbs_o.dat_o <= x"DEAD";
    end case;
  end process p_wishbone_data;

  -- purpose: retiming flop for wishbone answer
  -- type   : sequential
  p_retime_wishbone_output : process (WB_CLK) is
  begin  -- process p_retime_wishbone_output
    if rising_edge(WB_CLK) then         -- rising clock edge
      if WB_RST = '1' then              -- synchronous reset (active high)
        WB_WBS_O.ack_o <= '0';
        WB_WBS_O.err_o <= '0';
        WB_WBS_O.dat_o <= x"DEAD";
      else
        WB_WBS_O <= s_wb_wbs_o;
      end if;
    end if;
  end process p_retime_wishbone_output;

  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  -- synthesis translate off
  INST_wishbone_slave_checker : entity work.wishbone_slave_checker
    generic map (
      NR_ADDRESSES => to_integer(unsigned(WB_ADD.NUM_REGS)))
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => WB_WBS_I,
      WB_WBS_O => s_wb_wbs_o);
  -- synthesis translate on

end architecture structural;
