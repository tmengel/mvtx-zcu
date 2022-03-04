-------------------------------------------------------------------------------
-- Title      : CAN High Level Protocol (HLP)
-- Project    : CAN Bus DCS for ITS Readout Unit
-------------------------------------------------------------------------------
-- File       : can_hlp.vhd
-- Author     : Simon Voigt Nesbø  <simon@simon-ThinkPad-T450s>
-- Company    :
-- Created    : 2018-03-30
-- Last update: 2018-12-17
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Main logic for the CAN bus DCS High Level Protocol (HLP)
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-03-30  1.0      simon   Created
-------------------------------------------------------------------------------



library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library work;
use work.intercon_pkg.all;
use work.can_register_pkg.all;
use work.can_hlp_glue_pkg.all;
use work.can_hlp_pkg.all;

entity can_hlp is
  port (
    CLK   : in std_logic;
    RESET : in std_logic;

    CAN_MY_ID         : in  std_logic_vector(7 downto 0);
    CAN_RX_MSG_ID     : in  std_logic_vector(10 downto 0);
    CAN_RX_MSG_BUFFER : in  can_buffer_t;
    CAN_RX_MSG_SIZE   : in  std_logic_vector(3 downto 0);
    CAN_TX_MSG_BUFFER : out can_buffer_t;
    CAN_TX_MSG_SIZE   : out std_logic_vector(3 downto 0);
    CAN_TX_CMD_ID     : out std_logic_vector(2 downto 0);
    CAN_MSG_RECEIVED  : in  std_logic;
    CAN_TX_REQUEST    : out std_logic;
    CAN_TX_BUSY       : out std_logic;

    -- Registers for CAN HLP module
    CAN_REG_READ_COUNT         : out std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_WRITE_COUNT        : out std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_STATUS_ALERT_COUNT : out std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_UNKNOWN_COUNT      : out std_logic_vector(WB_DATA_WIDTH-1 downto 0);

    -- Interface to wishbone master via FIFO
    -- CAN HLP initiates WB transactions on DP0
    DP0_DT_O   : out std_logic_vector(31 downto 0);
    DP0_FULL_I : in  std_logic;
    DP0_WR_O   : out std_logic;

    -- Interface to wishbone master via FIFO
    -- CAN HLP receives WB replies on DP1
    DP1_DT_I   : in  std_logic_vector(31 downto 0);
    DP1_EPTY_I : in  std_logic;
    DP1_RD_O   : out std_logic);

end entity can_hlp;


architecture rtl of can_hlp is

  type can_hlp_state_t is (ST_IDLE,
                           ST_MSG_RECVD,
                           ST_WB_READ_SETUP,
                           ST_WB_READ_INITIATE,
                           ST_WB_READ_DATA,
                           ST_WB_READ_DATA_WAIT1,
                           ST_WB_READ_DATA_WAIT2,
                           ST_WB_WRITE_SETUP,
                           ST_WB_WRITE_INITIATE,
                           ST_MSG_RESPONSE,
                           ST_MSG_LENGTH_ERROR,
                           ST_IGNORE,
                           ST_STATUS_ALERT,
                           ST_UNKNOWN);

  constant C_WB_FIFO_RW_BIT_READ_VAL  : std_logic := '0';
  constant C_WB_FIFO_RW_BIT_WRITE_VAL : std_logic := '1';

  signal s_can_rx_msg_avail : std_logic := '0';

  signal s_can_write_msg_counter        : unsigned(WB_DATA_WIDTH-1 downto 0);
  signal s_can_read_msg_counter         : unsigned(WB_DATA_WIDTH-1 downto 0);
  signal s_can_status_alert_msg_counter : unsigned(WB_DATA_WIDTH-1 downto 0);
  signal s_can_unknown_msg_counter      : unsigned(WB_DATA_WIDTH-1 downto 0);

  signal s_can_tx_response_after_wb_transaction : std_logic := '0';

  signal s_fsm_state : can_hlp_state_t := ST_IDLE;

begin  -- architecture rtl

  CAN_REG_READ_COUNT         <= std_logic_vector(s_can_read_msg_counter);
  CAN_REG_WRITE_COUNT        <= std_logic_vector(s_can_write_msg_counter);
  CAN_REG_STATUS_ALERT_COUNT <= std_logic_vector(s_can_status_alert_msg_counter);
  CAN_REG_UNKNOWN_COUNT      <= std_logic_vector(s_can_unknown_msg_counter);


  proc_fsm : process (CLK, RESET) is
  begin  -- process proc_fsm
    if RESET = '1' then
      s_fsm_state                    <= ST_IDLE;
      s_can_rx_msg_avail             <= '0';
      s_can_read_msg_counter         <= (others => '0');
      s_can_write_msg_counter        <= (others => '0');
      s_can_status_alert_msg_counter <= (others => '0');
      s_can_unknown_msg_counter      <= (others => '0');
      CAN_TX_CMD_ID                  <= (others => '0');

    elsif rising_edge(CLK) then
      s_can_status_alert_msg_counter <= (others => '0');
      s_can_unknown_msg_counter      <= (others => '0');

      DP0_WR_O       <= '0';
      DP1_RD_O       <= '0';
      CAN_TX_REQUEST <= '0';

      if CAN_MSG_RECEIVED = '1' then
        s_can_rx_msg_avail <= '1';
      end if;

      case s_fsm_state is
        when ST_IDLE =>
          -- New CAN msg received, addressed to us?
          if s_can_rx_msg_avail = '1' then
            if CAN_RX_MSG_ID(10 downto 3) = CAN_MY_ID or
              CAN_RX_MSG_ID(10 downto 3) = C_CAN_BROADCAST_ID
            then
              s_fsm_state <= ST_MSG_RECVD;
            end if;

            s_can_rx_msg_avail <= '0';

          elsif DP1_EPTY_I = '0' then
            DP1_RD_O    <= '1';
            s_fsm_state <= ST_WB_READ_DATA_WAIT1;
          end if;

        when ST_MSG_RECVD =>
          case CAN_RX_MSG_ID(2 downto 0) is
            when C_READ_COMMAND   => s_fsm_state <= ST_WB_READ_SETUP;
            when C_WRITE_COMMAND  => s_fsm_state <= ST_WB_WRITE_SETUP;
            when C_READ_RESPONSE  => s_fsm_state <= ST_IGNORE;
            when C_WRITE_RESPONSE => s_fsm_state <= ST_IGNORE;
            when C_STATUS_ALERT   => s_fsm_state <= ST_STATUS_ALERT;
            when others           => s_fsm_state <= ST_UNKNOWN;
          end case;

        when ST_WB_READ_SETUP =>
          s_can_read_msg_counter <= s_can_read_msg_counter + 1;

          DP0_DT_O(31)           <= C_WB_FIFO_RW_BIT_READ_VAL;
          DP0_DT_O(30 downto 24) <= CAN_RX_MSG_BUFFER(0)(6 downto 0);
          DP0_DT_O(23 downto 16) <= CAN_RX_MSG_BUFFER(1);
          DP0_DT_O(15 downto 8)  <= (others => '0');
          DP0_DT_O(7 downto 0)   <= (others => '0');

          if CAN_RX_MSG_SIZE /= C_READ_COMMAND_LEN then
            s_fsm_state <= ST_MSG_LENGTH_ERROR;
          else
            s_fsm_state <= ST_WB_READ_INITIATE;
          end if;

        when ST_WB_READ_INITIATE =>
          -- Push read request on to WB DP FIFO
          if DP0_FULL_I = '0' then
            DP0_WR_O    <= '1';
            s_fsm_state <= ST_IDLE;
          end if;

          -- Wait two clock cycles for data to arrive from DP FIFO
        when ST_WB_READ_DATA_WAIT1 =>
          s_fsm_state <= ST_WB_READ_DATA_WAIT2;
        when ST_WB_READ_DATA_WAIT2 =>
          s_fsm_state <= ST_WB_READ_DATA;

        when ST_WB_READ_DATA =>
          -- Note: Assuming here that only wishbone read transactions
          --       generates "replies" on the DP1 FIFO, so that every
          --       CAN message sent from this state should be a READ_RESPONSE
          CAN_TX_CMD_ID   <= C_READ_RESPONSE;
          CAN_TX_MSG_SIZE <= C_READ_RESPONSE_LEN;

          -- 15-bit address, MSB bit is R/W in DP FIFO, but not used on CAN.
          CAN_TX_MSG_BUFFER(0) <= '0' & DP1_DT_I(30 downto 24);
          CAN_TX_MSG_BUFFER(1) <= DP1_DT_I(23 downto 16);
          CAN_TX_MSG_BUFFER(2) <= DP1_DT_I(15 downto 8);
          CAN_TX_MSG_BUFFER(3) <= DP1_DT_I(7 downto 0);

          s_fsm_state <= ST_MSG_RESPONSE;

        when ST_WB_WRITE_SETUP =>
          s_can_write_msg_counter <= s_can_write_msg_counter + 1;

          DP0_DT_O(31)           <= C_WB_FIFO_RW_BIT_WRITE_VAL;
          DP0_DT_O(30 downto 24) <= CAN_RX_MSG_BUFFER(0)(6 downto 0);
          DP0_DT_O(23 downto 16) <= CAN_RX_MSG_BUFFER(1);
          DP0_DT_O(15 downto 8)  <= CAN_RX_MSG_BUFFER(2);
          DP0_DT_O(7 downto 0)   <= CAN_RX_MSG_BUFFER(3);

          -- Repond with the same data
          CAN_TX_CMD_ID   <= C_WRITE_RESPONSE;
          CAN_TX_MSG_SIZE <= C_WRITE_RESPONSE_LEN;

          CAN_TX_MSG_BUFFER(0) <= C_WB_FIFO_RW_BIT_READ_VAL &
                                  CAN_RX_MSG_BUFFER(0)(6 downto 0);
          CAN_TX_MSG_BUFFER(1) <= CAN_RX_MSG_BUFFER(1);
          CAN_TX_MSG_BUFFER(2) <= CAN_RX_MSG_BUFFER(2);
          CAN_TX_MSG_BUFFER(3) <= CAN_RX_MSG_BUFFER(3);

          if CAN_RX_MSG_SIZE /= C_WRITE_COMMAND_LEN then
            s_fsm_state <= ST_MSG_LENGTH_ERROR;
          else
            s_can_tx_response_after_wb_transaction <= '1';
            s_fsm_state                            <= ST_WB_WRITE_INITIATE;
          end if;

        when ST_WB_WRITE_INITIATE =>
          -- Push write request on to WB DP FIFO
          if DP0_FULL_I = '0' then
            DP0_WR_O <= '1';

            -- Send write response
            s_fsm_state <= ST_MSG_RESPONSE;
          end if;

        when ST_MSG_RESPONSE =>
          CAN_TX_REQUEST <= '1';
          s_fsm_state    <= ST_IDLE;

        when ST_MSG_LENGTH_ERROR =>
          -- Do something smart here;
          s_fsm_state <= ST_IDLE;

        when others =>
          s_fsm_state <= ST_IDLE;

      end case;
    end if;
  end process proc_fsm;

end architecture rtl;
