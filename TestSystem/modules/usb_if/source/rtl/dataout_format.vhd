-------------------------------------------------------------------------------
-- Title      : data out format
-- Project    : Probecard
-------------------------------------------------------------------------------
-- File       : dataout_format.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-- Company    : Goethe Universitaet Frankfurt am Main
-- Created    : 2016-04-29
-- Last update: 2017-03-14
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex 7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: formats the data for the output (32 bit 3x8 bit words +
--              start/stop/timeout flags)
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-04-29  1.0      ML      Created
-- 2016-09-30  1.1      ML      Added flag for data 0-padded
-- 2016-10-04  1.2      ML      Changed data format to support up to 8
--                              different in ports
-- 2017.02.24  1.3      ML      Imported assertions from probecard
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.dataout_format_pkg.all;

entity dataout_format is
  port (
    -- general signals
    CLK : in std_logic;
    RST : in std_logic;

    -- output fifo signals
    FIFOOUT_DATAOUT : out std_logic_vector(31 downto 0);
    FIFOOUT_FULL    : in  std_logic;
    FIFOOUT_AFULL   : in  std_logic;
    FIFOOUT_WREN    : out std_logic;

    -- port 0 interface
    FIFOIN_DATAIN : in  std_logic_vector(c_port0_width-1 downto 0);
    FIFOIN_EMPTY  : in  std_logic;
    FIFOIN_RDEN   : out std_logic;

    -- timeout
    TIMEOUT : in std_logic_vector(WB_DATA_WIDTH-1 downto 0));
end entity dataout_format;


architecture str of dataout_format is

  -- FSM
  type t_state is (RESET, IDLE, D0, D1, D2, WAIT_FOR_NEXT_DATA, TX_AND_CONTINUE, TX_END);
  signal s_actual_state, s_next_state, s_next_RO_state, s_next_RO_state_reg : t_state;
  signal s_actualdata_out, s_nextdata_out                                   : t_dout_unformatted;

  -- timeout upcounter
  signal i_timeout_upcounter : integer;
  signal i_timeout           : integer;

  ---------------
  -- assertions
  ---------------
  -- synthesis translate_off
  constant C_STATE_BITWIDTH : integer := 3;
  signal s_actual_state_assertions : std_logic_vector(C_STATE_BITWIDTH-1 downto 0);
  signal s_next_RO_state_reg_assertions : std_logic_vector(C_STATE_BITWIDTH-1 downto 0);

  function f_map_state (
    constant actual_state : t_state)    -- actual_state
    return std_logic_vector is
    variable v_actual_state : std_logic_vector(C_STATE_BITWIDTH-1 downto 0);
  begin
    case actual_state is
      when RESET =>
        v_actual_state := "000";
      when IDLE =>
        v_actual_state := "001";
      when D0 =>
        v_actual_state := "010";
      when D1 =>
        v_actual_state := "011";
      when D2 =>
        v_actual_state := "100";
      when WAIT_FOR_NEXT_DATA =>
        v_actual_state := "101";
      when TX_AND_CONTINUE =>
        v_actual_state := "110";
      when TX_END =>
        v_actual_state := "111";
      when others =>
        v_actual_state := "000";
        report "Unreachable v_state reached!" severity ERROR;
    end case;

    return v_actual_state;
  end f_map_state;

  -- assertions/coverage
  component dataout_format_assertions
    generic(
      StateBitWidth_c : integer);
    port(
      clk   : in std_logic;
      rst   : in std_logic;
      fsm_stop : in std_logic;
      fifoin_empty : in std_logic;
      next_RO_state : in std_logic_vector(StateBitWidth_c-1 downto 0);
      state : in std_logic_vector(StateBitWidth_c-1 downto 0)
      );
  end component;

  -- synthesis translate_on

begin  -- architecture str

  i_timeout <= to_integer(unsigned(TIMEOUT));

-------------------------------------------------------------------------------
-- FSM
-------------------------------------------------------------------------------

  p_FSM_transition : process (CLK) is
  begin  -- process p_FSM_transition
    if rising_edge(CLK) then
      if RST = '1' then
        s_actual_state      <= RESET;
        FIFOOUT_DATAOUT     <= (others => '0');
        s_actualdata_out    <= f_reset_output('0');
        s_next_RO_state_reg <= RESET;
      else
        s_actual_state      <= s_next_state;
        FIFOOUT_DATAOUT     <= f_assign_output(s_nextdata_out);
        s_actualdata_out    <= s_nextdata_out;
        s_next_RO_state_reg <= s_next_RO_state;
      end if;
    end if;
  end process p_FSM_transition;

  p_FSM_next : process (s_actual_state,
                        FIFOIN_EMPTY,
                        FIFOIN_DATAIN,
                        s_next_RO_state,
                        i_timeout_upcounter,
                        i_timeout,
                        s_next_RO_state_reg,
                        s_actualdata_out,
                        FIFOOUT_FULL) is
  begin
    s_next_state    <= s_actual_state;
    s_nextdata_out  <= s_actualdata_out;
    FIFOOUT_WREN    <= '0';
    s_next_RO_state <= s_next_RO_state_reg;
    FIFOIN_RDEN     <= '0';

    case s_actual_state is

      when RESET =>
        s_next_state    <= IDLE;
        s_next_RO_state <= RESET;
        s_nextdata_out  <= f_reset_output('0');

      when IDLE =>
        s_nextdata_out.stop_bit <= '0';
        --s_nextdata_out.timeout  <= '0';
        if FIFOIN_EMPTY = '0' then
          s_next_state             <= D0;
          s_nextdata_out.start_bit <= '1';
        else
          s_next_state <= IDLE;
        end if;

      when D0 =>
        --s_nextdata_out.inport   <= std_logic_vector(to_unsigned(0, 1));  -- port 0
        s_nextdata_out.stop_bit <= '0';
        --s_nextdata_out.timeout  <= '0';
        s_nextdata_out.D0       <= FIFOIN_DATAIN(7 downto 0);

        if FIFOIN_DATAIN(8) = '1' then
          s_nextdata_out.D0                       <= FIFOIN_DATAIN(7 downto 0);
          s_nextdata_out.stop_bit                 <= '1';
          s_next_state                            <= TX_END;
          FIFOIN_RDEN                             <= '1';
          s_nextdata_out.is_padded(c_D0_position) <= '0';
        elsif FIFOIN_EMPTY = '0' then
          s_nextdata_out.D0                       <= FIFOIN_DATAIN(7 downto 0);
          FIFOIN_RDEN                             <= '1';
          s_next_state                            <= D1;
          s_nextdata_out.is_padded(c_D0_position) <= '0';
        else
          s_next_state    <= WAIT_FOR_NEXT_DATA;
          s_next_RO_state <= D0;
        end if;

      when D1 =>

        if FIFOIN_DATAIN(8) = '1' then
          s_nextdata_out.stop_bit                 <= '1';
          s_next_state                            <= TX_END;
          FIFOIN_RDEN                             <= '1';
          s_nextdata_out.D1                       <= FIFOIN_DATAIN(7 downto 0);
          s_nextdata_out.is_padded(c_D1_position) <= '0';
        elsif FIFOIN_EMPTY = '0' then
          FIFOIN_RDEN                             <= '1';
          s_next_state                            <= D2;
          s_nextdata_out.D1                       <= FIFOIN_DATAIN(7 downto 0);
          s_nextdata_out.is_padded(c_D1_position) <= '0';
        else
          s_next_state    <= WAIT_FOR_NEXT_DATA;
          s_next_RO_state <= D1;
        end if;

      when D2 =>

        if FIFOIN_DATAIN(8) = '1' then
          s_nextdata_out.stop_bit                 <= '1';
          s_next_state                            <= TX_END;
          FIFOIN_RDEN                             <= '1';
          s_nextdata_out.D2                       <= FIFOIN_DATAIN(7 downto 0);
          s_nextdata_out.is_padded(c_D2_position) <= '0';
        elsif FIFOIN_EMPTY = '0' then
          FIFOIN_RDEN                             <= '1';
          s_next_state                            <= TX_AND_CONTINUE;
          s_nextdata_out.D2                       <= FIFOIN_DATAIN(7 downto 0);
          s_nextdata_out.is_padded(c_D2_position) <= '0';
        else
          s_next_state    <= WAIT_FOR_NEXT_DATA;
          s_next_RO_state <= D2;
        end if;

      when TX_AND_CONTINUE =>
        if FIFOOUT_FULL = '0' then
          FIFOOUT_WREN             <= '1';
          s_nextdata_out.start_bit <= '0';
          s_nextdata_out.D0        <= (others => '0');
          s_nextdata_out.D1        <= (others => '0');
          s_nextdata_out.D2        <= (others => '0');
          s_nextdata_out.is_padded <= (others => '1');
          if FIFOIN_EMPTY = '0' then
            s_next_state <= D0;
          else
            s_next_state    <= WAIT_FOR_NEXT_DATA;
            s_next_RO_state <= D0;
          end if;
        else
          s_next_state <= TX_AND_CONTINUE;  -- waits if fifofull
        end if;

      when WAIT_FOR_NEXT_DATA =>
        if FIFOIN_EMPTY = '0' then
          s_next_state <= s_next_RO_state;
        elsif i_timeout_upcounter = i_timeout then
          s_next_state            <= TX_END;
          s_nextdata_out.stop_bit <= '1';
          --s_nextdata_out.timeout  <= '1';
        else
          s_next_state <= WAIT_FOR_NEXT_DATA;
        end if;

      when TX_END =>
        if FIFOOUT_FULL = '0' then
          s_next_state             <= IDLE;
          FIFOOUT_WREN             <= '1';
          s_nextdata_out.D0        <= (others => '0');
          s_nextdata_out.D1        <= (others => '0');
          s_nextdata_out.D2        <= (others => '0');
          s_nextdata_out.is_padded <= (others => '1');
          s_next_RO_state          <= RESET;

        else
          s_next_state <= TX_END;       -- waits if fifofull
        end if;

      when others =>
        s_next_state <= RESET;
        -- synthesis translate_off
        report "Unreachable state reached!" severity ERROR;
        -- synthesis translate_on

    end case;
  end process p_FSM_next;

-- purpose: upcounter for the dataout_format
  p_timeout_counter : process (CLK) is
  begin  -- process p_timeout_counter
    if rising_edge(CLK) then
      if RST = '1' then
        i_timeout_upcounter <= 0;
      else
        case s_actual_state is
          when WAIT_FOR_NEXT_DATA =>
            i_timeout_upcounter <= i_timeout_upcounter + 1;

          when others =>
            i_timeout_upcounter <= 0;
        end case;
      end if;
    end if;
  end process p_timeout_counter;

  -----------------------------------------------------------------------------
  -- assertions
  -----------------------------------------------------------------------------
  -- synthesis translate_off

  s_actual_state_assertions <= f_map_state(s_actual_state);
  s_next_RO_state_reg_assertions <= f_map_state(s_next_RO_state_reg);

  INST_dataout_format_assertions : dataout_format_assertions
    generic map(
      StateBitWidth_c => C_STATE_BITWIDTH
      )
    port map (
      clk   => CLK,
      rst   => RST,
      fsm_stop => s_nextdata_out.stop_bit,
      fifoin_empty => FIFOIN_EMPTY,
      next_RO_state => s_next_RO_state_reg_assertions,
      state => s_actual_state_assertions);
  -- synthesis translate_on

end architecture str;
