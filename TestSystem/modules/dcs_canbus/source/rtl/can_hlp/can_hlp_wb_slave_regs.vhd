-------------------------------------------------------------------------------
-- Title      : CAN DCS HLP Wishbone Slave Registers
-- Project    : ITS RU FPGA
-------------------------------------------------------------------------------
-- File       : can_hlp_wb_slave_regs.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    : Western Norway University of Applied Sciences
-- Created    : 2018-04-11
-- Last update: 2018-12-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave for CAN bus DCS HLP registers. Based on
--              implementation in ws_usb_if.vhd by Matteo Lupi
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-04-11  1.0      simon   Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.can_hlp_wb_slave_regs_pkg.all;
use work.can_hlp_glue_pkg.all;

entity can_hlp_wb_slave_regs is
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  wbs_i_type;          -- Wishbone slave input signals
    WB_WBS_O : out wbs_o_type;          -- Wishbone slave output signals

    -- Registers
    CAN_REG_RX_MSG_COUNT       : in    std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_TX_MSG_COUNT       : in    std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_READ_COUNT         : in    std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_WRITE_COUNT        : in    std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_STATUS_ALERT_COUNT : in    std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_UNKNOWN_COUNT      : in    std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_CLK_PRESCALE       : out   std_logic_vector(5 downto 0);

    CAN_CTRL_SOFT_RESET        : out   std_logic);

end can_hlp_wb_slave_regs;

architecture rtl of can_hlp_wb_slave_regs is

  -- wishbone signal for reading
  signal s_wb_wbs_o : wbs_o_type;

  signal s_reg_test : std_logic_vector(WB_DATA_WIDTH-1 downto 0) := x"0000";
  signal s_reg_clk_prescale : std_logic_vector(5 downto 0) := C_CAN_BTR0_RESET_VAL(5 downto 0);

begin

  CAN_REG_CLK_PRESCALE <= s_reg_clk_prescale;

  -----------------------------------------------------------------------------
  -- Wishbone interface
  -----------------------------------------------------------------------------

  -- purpose: writes the wishbone register from the WB side
  p_wishbone_reg : process (WB_CLK) is
  begin  -- process p_wishbone_reg
    if rising_edge(WB_CLK) then
      CAN_CTRL_SOFT_RESET <= '0';

      if WB_RST = '1' then
        -- Reset registers that aren't reset in other modules here
        s_reg_clk_prescale(5 downto 0) <= C_CAN_BTR0_RESET_VAL(5 downto 0);
      else
        if WB_WBS_I.we_i = '1' and WB_WBS_I.stb_i = '1' and WB_WBS_I.cyc_i = '1' then
          case WB_WBS_I.addr_i is

            -- Add registers with write permission here
            when WB_ADD.CAN_REG_TEST =>
              s_reg_test <= WB_WBS_I.dat_i;

            --when WB_ADD.SOME_REGISTER =>
            --  SOME_REGISTER <= WB_WBS_I.dat_i;

            when WB_ADD.CAN_REG_CLK_PRESCALE =>
              s_reg_clk_prescale(5 downto 0) <= WB_WBS_I.dat_i(5 downto 0);
              CAN_CTRL_SOFT_RESET <= '1';

            when others =>
              null;

          end case;

        else                            -- pulse signals
        -- Add pulsed registers here
        -- SOME_PULSED_REGISTER                <= others => '0';
        end if;
      end if;
    end if;
  end process p_wishbone_reg;

  -- purpose: generates the Ack and Err signals for the wishbone
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

          --when WB_ADD.SOME_WO_REGISTER =>       -- Write only
          --  v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(WB_WBS_I.we_i);
          --  v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CAN_REG_RX_MSG_COUNT =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CAN_REG_TX_MSG_COUNT =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CAN_REG_READ_COUNT =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CAN_REG_WRITE_COUNT =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CAN_REG_STATUS_ALERT_COUNT =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CAN_REG_UNKNOWN_COUNT =>  -- Read only
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and WB_WBS_I.we_i;
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_err_o);

          when WB_ADD.CAN_REG_TEST =>   -- Read / Write registers
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when WB_ADD.CAN_REG_CLK_PRESCALE =>   -- Read / Write registers
            v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

            --when WB_ADD.SOME_RW_REGISTER =>  -- Read / Write registers
            --  v_ack_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;
            --  v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i and not(v_ack_o);

          when others =>
            v_err_o := WB_WBS_I.stb_i and WB_WBS_I.cyc_i;  -- read or write to an illegal address
            v_ack_o := '0';

        end case;
        s_wb_wbs_o.ack_o <= v_ack_o;
        s_wb_wbs_o.err_o <= v_err_o;
      end if;
    end if;
  end process p_wishbone_answer;

  -- purpose: generates the data answer to the wishbone request
  p_wishbone_data : process (WB_WBS_I,
                             CAN_REG_RX_MSG_COUNT,
                             CAN_REG_TX_MSG_COUNT,
                             CAN_REG_READ_COUNT,
                             CAN_REG_WRITE_COUNT,
                             CAN_REG_STATUS_ALERT_COUNT,
                             CAN_REG_UNKNOWN_COUNT,
                             s_reg_test,
                             s_reg_clk_prescale) is
  begin  -- process p_wishbone_data
    case WB_WBS_I.addr_i is
      when WB_ADD.CAN_REG_RX_MSG_COUNT =>
        s_wb_wbs_o.dat_o <= CAN_REG_RX_MSG_COUNT;
      when WB_ADD.CAN_REG_TX_MSG_COUNT =>
        s_wb_wbs_o.dat_o <= CAN_REG_TX_MSG_COUNT;
      when WB_ADD.CAN_REG_READ_COUNT =>
        s_wb_wbs_o.dat_o <= CAN_REG_READ_COUNT;
      when WB_ADD.CAN_REG_WRITE_COUNT =>
        s_wb_wbs_o.dat_o <= CAN_REG_WRITE_COUNT;
      when WB_ADD.CAN_REG_STATUS_ALERT_COUNT =>
        s_wb_wbs_o.dat_o <= CAN_REG_STATUS_ALERT_COUNT;
      when WB_ADD.CAN_REG_UNKNOWN_COUNT =>
        s_wb_wbs_o.dat_o <= CAN_REG_UNKNOWN_COUNT;
      when WB_ADD.CAN_REG_TEST =>
        s_wb_wbs_o.dat_o <= s_reg_test;
      when WB_ADD.CAN_REG_CLK_PRESCALE =>
        s_wb_wbs_o.dat_o(WB_DATA_WIDTH-1 downto 6) <= (others => '0');
        s_wb_wbs_o.dat_o(5 downto 0) <= s_reg_clk_prescale;
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

end architecture rtl;
