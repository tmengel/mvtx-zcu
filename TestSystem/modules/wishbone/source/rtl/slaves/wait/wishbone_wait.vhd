-------------------------------------------------------------------------------
-- Title      : wishbone_wait
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : wishbone_wait.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-10-08
-- Last update: 2018-06-05
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex-Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Copyright 2016 CERN European Organization for Nuclear Research
--
-- This file is part of Control Management Unit RTL.
-- Control Management Unit RTL is free software: you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, version 3 of the License.
-- Control Management Unit RTL is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU Lesser General Public License for more details.
-- You should have received a copy of the GNU Lesser General Public License
-- along with Control Management Unit RTL.
-- If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------c
-- Description:
-- Wishbone slave for wait
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.wishbone_wait_pkg.all;

entity wishbone_wait is
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  wbs_i_type;          -- Wishbone slave input signals
    WB_WBS_O : out wbs_o_type           -- Wishbone slave output signals
    );
end wishbone_wait;

architecture str of wishbone_wait is

  component wtmdl is
    generic (
      WbDataWidth : integer);
    port (
      clk_i : in std_logic;
      rst_i : in std_logic;

      wait_start_i : in  std_logic;
      wait_value_i : in  std_logic_vector(WbDataWidth-1 downto 0);
      wait_done_o  : out std_logic);
  end component wtmdl;

  --wishbone slave
  signal s_wb_wbs_o                   : wbs_o_type;
  signal s_wishbone_registers         : t_wait_ws_reg;

  -- WAIT
  signal s_wait_ongoing_d1, s_wait_start, s_wait_done : std_logic;
  signal s_cntr_wait_exec : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_actual_state : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
begin  -- architecture strcutural

  -----------------------------------------------------------------------------
  -- Wishone slave WB_WBS_I.ADD
  -----------------------------------------------------------------------------
  p_wishbone_reg : process (WB_CLK) is
  begin  -- process p_wishbone_reg
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        s_wishbone_registers  <= C_WB_ASSIGN_DEFAULT;
      else
        s_wishbone_registers.wait_mod.ongoing               <= '0';

        if WB_WBS_I.we_i = '1' and WB_WBS_I.stb_i = '1' and WB_WBS_I.cyc_i = '1' then
          case WB_WBS_I.addr_i is

            when WB_ADD.RST_CTRL_CNTRS =>
              s_wishbone_registers.counters.rst        <= WB_WBS_I.dat_i(C_RST_CTRL_CNTRS_bit_wait_exec);

            when WB_ADD.WAIT_VALUE =>
              s_wishbone_registers.wait_mod.value   <= WB_WBS_I.dat_i;
              s_wishbone_registers.wait_mod.ongoing <= '1';

            when others => null;
          end case;
        else

          s_wishbone_registers.wait_mod.ongoing         <= '0';

        end if;
      end if;
    end if;
  end process p_wishbone_reg;


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

        case WB_WBS_I.addr_i is

          when WB_ADD.RST_CTRL_CNTRS =>  -- Write only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(WB_WBS_I.we_i);
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.READ_WAIT_EXEC_CNTR =>  --  Read only error
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.WAIT_VALUE =>     -- Write only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(WB_WBS_I.we_i);
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o) and s_wait_done;

          when others =>
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;  -- read or write to an illegal address
            v_ack_o := '0';

        end case;
        s_wb_wbs_o.ack_o <= v_ack_o;
        s_wb_wbs_o.err_o <= v_err_o;
      end if;
    end if;
  end process p_wishbone_answer;

  p_wishbone_data : process (WB_WBS_I, s_wishbone_registers,
                             s_cntr_wait_exec
                             ) is
  begin  -- process p_wishbone_data
    case WB_WBS_I.addr_i is

      when WB_ADD.RST_CTRL_CNTRS =>     -- Read/Write register
        s_wb_wbs_o.dat_o                                        <= (others => '0');
        s_wb_wbs_o.dat_o(C_RST_CTRL_CNTRS_bit_wait_exec)        <= s_wishbone_registers.counters.rst;

      when WB_ADD.READ_WAIT_EXEC_CNTR =>         --  Read only error
        s_wb_wbs_o.dat_o <= s_cntr_wait_exec;

      when WB_ADD.WAIT_VALUE =>         -- Write only register
        s_wb_wbs_o.dat_o <= s_wishbone_registers.wait_mod.value;

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
  -- WAIT MODULE
  -- the wtmdl is handling the wait state in response to the write to the
  -- relative wishbone register, the counter tracks the amount of wait commands
  -- issued
  -----------------------------------------------------------------------------

  -- note: WBCLK counter != CLK40 !
  INST_upcounter_wait_exec : entity work.upcounter_core
    generic map (
      BIT_WIDTH     => WB_DATA_WIDTH,
      IS_SATURATING => 0,
      VERBOSE       => 0)
    port map (
      CLK            => WB_CLK,
      RST            => WB_RST,
      RST_CNT        => s_wishbone_registers.counters.rst,
      CNT_UP         => s_wait_done,
      CNT_VALUE      => s_cntr_wait_exec,
      ACTUAL_STATE_O => s_actual_state,
      ACTUAL_STATE_I => s_actual_state
      );

  INST_wtmdl : wtmdl
    generic map (
      WbDataWidth => WB_DATA_WIDTH)
    port map (
      clk_i        => WB_CLK,
      rst_i        => WB_RST,
      wait_start_i => s_wait_start,
      wait_value_i => s_wishbone_registers.wait_mod.value,
      wait_done_o  => s_wait_done);

  -- purpose: creates a pulsed signal out of the s_wait_ongoing signal
  p_re_wait_start : process (WB_CLK) is
  begin  -- process p_re_wait_start
    if rising_edge(WB_CLK) then         -- rising clock edge
      if WB_RST = '1' then              -- synchronous reset (active high)
        s_wait_ongoing_d1 <= '0';
      else
        s_wait_ongoing_d1 <= s_wishbone_registers.wait_mod.ongoing;
      end if;
    end if;
  end process p_re_wait_start;
  s_wait_start <= s_wishbone_registers.wait_mod.ongoing and not s_wait_ongoing_d1;

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

end architecture str;
