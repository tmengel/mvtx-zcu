-------------------------------------------------------------------------------
-- Title      : Mmcm_Monitor wishbone
-- Project    : ITSWP10
-------------------------------------------------------------------------------
-- File       : mmcm_monitor_wishbone_.vhd
-- Author     : M. Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2017-07-25
-- Last update: 2017-11-21
-- Platform   : CERN OS7, Xilinx Vivado 2016.4
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone connection for controlling the mmcm_monitor_wishbone
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;
use work.tmr_pkg.all;
use work.mmcm_monitor_pkg.all;

entity mmcm_monitor_wishbone is
  port (
    WB_CLK             : in  std_logic;
    WB_RST             : in  std_logic;
    WB_WBS_I           : in  wbs_i_type;
    WB_WBS_O           : out wbs_o_type;
    COUNTER_LATCH      : out std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
    COUNTER_RESET      : out std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto 0);
    LOCK_COUNTER_LATCH : out std_logic;
    LOCK_COUNTER_RESET : out std_logic;
    COUNTER_ARRAY      : in  t_clk_counters_array;
    LOCK_COUNTER       : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    MISMATCH_ARRAY     : in  std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0);
    MISMATCH_2ND_ARRAY : in  std_logic_vector(C_USER_CLOCK_NUMBER*C_K_TMR -1 downto 0)
    );
end entity mmcm_monitor_wishbone;

architecture structural of mmcm_monitor_wishbone is

  signal s_wb_wbs_o           : wbs_o_type;
  signal s_wishbone_registers : t_wishbone_registers;

begin  -- architecture structural

  for_counters : for clock_i in 0 to C_USER_CLOCK_NUMBER-1 generate
    for_lock_counter : for i in 0 to C_K_TMR-1 generate
      COUNTER_LATCH(clock_i*C_K_TMR + i) <= s_wishbone_registers.counters_latch(clock_i);
      COUNTER_RESET(clock_i*C_K_TMR + i) <= s_wishbone_registers.counters_reset(clock_i);
    end generate for_lock_counter;
  end generate for_counters;

    LOCK_COUNTER_LATCH <= s_wishbone_registers.lock_counter_latch;
    LOCK_COUNTER_RESET <= s_wishbone_registers.lock_counter_reset;

  -----------------------------------------------------------------------------
  -- wishbone
  -----------------------------------------------------------------------------

  p_wishbone_reg : process (WB_CLK) is
  begin  -- process p_wishbone_reg
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then
        s_wishbone_registers <= C_WISHBONE_DEFAULTS;
      else
        s_wishbone_registers <= s_wishbone_registers;

        if WB_WBS_I.we_i = '1' and WB_WBS_I.stb_i = '1' and WB_WBS_I.cyc_i = '1' then
          case WB_WBS_I.addr_i is

            --when WB_ADD.WRITE_CTRL =>
            --  s_wishbone_registers.alpide_protocol.wr_ctrl    <= WB_WBS_I.dat_i;
            --  s_wishbone_registers.alpide_protocol.wr_ctrl_up <= '1';

            --when WB_ADD.WRITE_DATA =>
            --  s_wishbone_registers.alpide_protocol.wr_data <= WB_WBS_I.dat_i;

            when WB_ADD.LATCH_COUNTERS =>
              s_wishbone_registers.counters_latch     <= WB_WBS_I.dat_i(C_bit_CLK_N downto C_bit_CLK_0);
              s_wishbone_registers.lock_counter_latch <= WB_WBS_I.dat_i(C_bit_lock);

            when WB_ADD.RESET_COUNTERS =>
              s_wishbone_registers.counters_reset     <= WB_WBS_I.dat_i(C_bit_CLK_N downto C_bit_CLK_0);
              s_wishbone_registers.lock_counter_reset <= WB_WBS_I.dat_i(C_bit_lock);

            when others => null;
          end case;
        else
          -- pulse registers
          null;
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

          when to_integer(unsigned(WB_ADD.LATCH_COUNTERS)) =>  -- Write/Read register
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when to_integer(unsigned(WB_ADD.RESET_COUNTERS)) =>  -- Write/Read register
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when to_integer(unsigned(WB_ADD.GET_LOCK_COUNTER)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.GET_COUNTER_CLK_0_FIRST)) to to_integer(unsigned(WB_ADD.GET_COUNTER_CLK_N_LAST)) =>  -- Read only register
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when to_integer(unsigned(WB_ADD.MISMATCH_LSB)) to to_integer(unsigned(WB_ADD.MISMATCH_2ND_COUNTER)) =>  -- Read only register
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
                             s_wishbone_registers,
                             COUNTER_ARRAY,
                             LOCK_COUNTER,
                             MISMATCH_ARRAY,
                             MISMATCH_2ND_ARRAY
                             ) is
  begin  -- process p_wishbone_data
    case to_integer(unsigned(WB_WBS_I.addr_i)) is

      when to_integer(unsigned(WB_ADD.GET_LOCK_COUNTER)) =>  -- Read only register
        s_wb_wbs_o.dat_o <= LOCK_COUNTER;

      when to_integer(unsigned(WB_ADD.LATCH_COUNTERS)) =>  -- Read / Write register
        s_wb_wbs_o.dat_o                                 <= (others => '0');
        s_wb_wbs_o.dat_o(C_bit_CLK_N downto C_bit_CLK_0) <= s_wishbone_registers.counters_latch;

      when to_integer(unsigned(WB_ADD.RESET_COUNTERS)) =>  -- Read / Write register
        s_wb_wbs_o.dat_o                                 <= (others => '0');
        s_wb_wbs_o.dat_o(C_bit_CLK_N downto C_bit_CLK_0) <= s_wishbone_registers.counters_reset;

      when to_integer(unsigned(WB_ADD.GET_COUNTER_CLK_0_FIRST)) to to_integer(unsigned(WB_ADD.GET_COUNTER_CLK_N_LAST)) =>  -- Read only
        --synthesis translate_off
        --report "address " & integer'image(to_integer(unsigned(WB_WBS_I.addr_i))) & " first " & integer'image(to_integer(unsigned(WB_ADD.GET_COUNTER_CLK_0_FIRST))) & " last " & integer'image(to_integer(unsigned(WB_ADD.GET_COUNTER_CLK_N_LAST))) severity note;
        --synthesis translate_on
        s_wb_wbs_o.dat_o <= COUNTER_ARRAY(f_get_address_int(WB_WBS_I.addr_i, WB_ADD.GET_COUNTER_CLK_0_FIRST));

      when to_integer(unsigned(WB_ADD.MISMATCH_LSB)) =>  -- Read only register
        s_wb_wbs_o.dat_o <= MISMATCH_ARRAY(WB_DATA_WIDTH-1 downto 0);

      when to_integer(unsigned(WB_ADD.MISMATCH_MSB)) =>  -- Read only register
        s_wb_wbs_o.dat_o                                                         <= (others => '0');
        s_wb_wbs_o.dat_o(C_USER_CLOCK_NUMBER*C_K_TMR -WB_DATA_WIDTH-1 downto 0)  <= MISMATCH_ARRAY(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto WB_DATA_WIDTH);

      when to_integer(unsigned(WB_ADD.MISMATCH_2ND_LSB)) =>  -- Read only register
        s_wb_wbs_o.dat_o <= MISMATCH_2ND_ARRAY(WB_DATA_WIDTH-1 downto 0);

      when to_integer(unsigned(WB_ADD.MISMATCH_2ND_MSB)) =>  -- Read only register
        s_wb_wbs_o.dat_o                                                         <= (others => '0');
        s_wb_wbs_o.dat_o(C_USER_CLOCK_NUMBER*C_K_TMR -WB_DATA_WIDTH-1 downto 0) <= MISMATCH_2ND_ARRAY(C_USER_CLOCK_NUMBER*C_K_TMR-1 downto WB_DATA_WIDTH);

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
