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
-- Description: Glue logic between OpenCores CAN controller and
--              DCS CANbus High Level Protocol (HLP)
-------------------------------------------------------------------------------
-- Copyright (c) 2018
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-03-30  1.0      simon	Created
-------------------------------------------------------------------------------



library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library work;
use work.intercon_pkg.all;
use work.can_register_pkg.all;
use work.can_hlp_glue_pkg.all;


entity can_hlp_glue is
  port (
    CLK               : in  std_logic;
    RESET             : in  std_logic;
    CAN_MY_ID         : in  std_logic_vector(10 downto 0);
    CAN_RX_MSG_ID     : out std_logic_vector(10 downto 0);
    CAN_RX_MSG_BUFFER : out can_buffer_t;
    CAN_RX_MSG_SIZE   : out std_logic_vector(3 downto 0);
    CAN_TX_MSG_BUFFER : in  can_buffer_t;
    CAN_TX_MSG_SIZE   : in  std_logic_vector(3 downto 0);
    CAN_MSG_RECEIVED  : out std_logic;
    CAN_TX_REQUEST    : in  std_logic;
    CAN_TX_BUSY       : out std_logic;

    CAN_INTERRUPT_N   : in std_logic;

    CAN_CTRL_SOFT_RESET : in std_logic;

    -- Registers for CAN HLP glue logic module
    CAN_REG_RX_MSG_COUNT : out   std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_TX_MSG_COUNT : out   std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    CAN_REG_CLK_PRESCALE : in    std_logic_vector(5 downto 0);

    -- Wishbone master interface to CAN controller
    WBM_CAN_DAT_O  : out std_logic_vector(7 downto 0);
    WBM_CAN_DAT_I  : in  std_logic_vector(7 downto 0);
    WBM_CAN_ADDR_O : out std_logic_vector(7 downto 0);
    WBM_CAN_ACK_I  : in  std_logic;
    WBM_CAN_ERR_I  : in  std_logic;
    WBM_CAN_WE_O   : out std_logic;
    WBM_CAN_CYC_O  : out std_logic;
    WBM_CAN_STB_O  : out std_logic);

end entity can_hlp_glue;


architecture rtl of can_hlp_glue is

  type can_hlp_glue_state_t is (ST_SETUP,
                                ST_SETUP_ACR,
                                ST_SETUP_AMR,
                                ST_SETUP_BTR0,
                                ST_SETUP_BTR1,
                                ST_SETUP_CR,
                                ST_IDLE,
                                ST_GET_CAN_INTERRUPT,
                                ST_CHECK_CAN_INTERRUPT,
                                ST_CAN_SEND_MESSAGE,
                                ST_CAN_GET_MESSAGE,
                                ST_CAN_RELEASE_RECV_BUFFER,
                                ST_CAN_MESSAGE_SENT,
                                ST_CAN_ERROR,
                                ST_CAN_DATA_OVERRUN,
                                ST_CAN_WAKEUP,
                                ST_READ_RX_ID1,
                                ST_READ_RX_ID2,
                                ST_READ_RX_BUFFER,
                                ST_WRITE_TX_ID1,
                                ST_WRITE_TX_ID2,
                                ST_WRITE_TX_BUFFER,
                                ST_INITIATE_CAN_TX);

  signal s_fsm_state : can_hlp_glue_state_t := ST_SETUP;

  signal s_wb_done       : std_logic := '0';
  signal s_can_isr_value : std_logic_vector(7 downto 0);

  signal s_can_msg_sent_counter : unsigned(WB_DATA_WIDTH-1 downto 0);
  signal s_can_msg_recv_counter : unsigned(WB_DATA_WIDTH-1 downto 0);

  signal s_can_rx_id1 : std_logic_vector(7 downto 0);
  signal s_can_rx_id2 : std_logic_vector(7 downto 0);

  signal s_can_tx_id1 : std_logic_vector(7 downto 0);
  signal s_can_tx_id2 : std_logic_vector(7 downto 0);

  signal s_byte_counter : unsigned(3 downto 0);

  signal s_can_tx_requested              : std_logic := '0';
  signal s_can_ctrl_soft_reset_requested : std_logic := '0';

begin  -- architecture rtl

  CAN_REG_RX_MSG_COUNT <= std_logic_vector(s_can_msg_recv_counter);
  CAN_REG_TX_MSG_COUNT <= std_logic_vector(s_can_msg_sent_counter);

  CAN_RX_MSG_ID(10 downto 3) <= s_can_rx_id1;
  CAN_RX_MSG_ID(2 downto 0)  <= s_can_rx_id2(7 downto 5);


  proc_fsm : process (clk, RESET) is

    variable v_wb_read_data  : std_logic_vector(WBM_CAN_DAT_O'range);
    variable v_wb_write_data : std_logic_vector(WBM_CAN_DAT_O'range);

    procedure wb_write (
      constant addr : in    natural;
      constant data : in    std_logic_vector;
      signal done   : inout std_logic) is
    begin
      done <= '0';

      -- Todo: Make this more advanced? Can I just keep both cycle and strobe
      -- high like this?
      if WBM_CAN_CYC_O = '0' then
        WBM_CAN_CYC_O  <= '1';
        WBM_CAN_STB_O  <= '1';
        WBM_CAN_ADDR_O <= std_logic_vector(to_unsigned(addr, WBM_CAN_ADDR_O'length));
        WBM_CAN_DAT_O  <= data;
        WBM_CAN_WE_O   <= '1';
      elsif WBM_CAN_ACK_I = '0' then
        WBM_CAN_CYC_O <= '1';
        WBM_CAN_STB_O <= '1';
        WBM_CAN_WE_O  <= '1';
      else
        WBM_CAN_CYC_O <= '0';
        WBM_CAN_STB_O <= '0';
        WBM_CAN_WE_O  <= '0';
        done          <= '1';
      end if;
    end procedure wb_write;

    procedure wb_read (
      constant addr : in    natural;
      variable data : out   std_logic_vector;
      signal done   : inout std_logic) is
    begin
      done <= '0';

      -- Todo: Make this more advanced? Can I just keep both cycle and strobe
      -- high like this?
      if WBM_CAN_CYC_O = '0' then
        WBM_CAN_CYC_O  <= '1';
        WBM_CAN_STB_O  <= '1';
        WBM_CAN_ADDR_O <= std_logic_vector(to_unsigned(addr, WBM_CAN_ADDR_O'length));
        WBM_CAN_WE_O   <= '0';
      elsif WBM_CAN_ACK_I = '0' then
        WBM_CAN_CYC_O <= '1';
        WBM_CAN_STB_O <= '1';
        WBM_CAN_WE_O  <= '0';
      else
        WBM_CAN_CYC_O <= '0';
        WBM_CAN_STB_O <= '0';
        WBM_CAN_WE_O  <= '0';
        data          := WBM_CAN_DAT_I;
        done          <= '1';
      end if;
    end procedure wb_read;


  begin  -- process proc_fsm
    if RESET = '1' then
      s_can_msg_sent_counter          <= to_unsigned(0, s_can_msg_sent_counter'length);
      s_can_msg_recv_counter          <= to_unsigned(0, s_can_msg_recv_counter'length);
      s_can_tx_requested              <= '0';
      s_can_ctrl_soft_reset_requested <= '0';
      CAN_TX_BUSY                     <= '0';
      s_fsm_state                     <= ST_SETUP;

    elsif rising_edge(clk) then
      WBM_CAN_CYC_O    <= '0';
      WBM_CAN_STB_O    <= '0';
      WBM_CAN_WE_O     <= '0';
      s_wb_done        <= '0';
      CAN_MSG_RECEIVED <= '0';

      -- Allow CAN_TX_REQUEST to be pulsed a cycle
      -- while we are busy doing something else
      if CAN_TX_REQUEST = '1' then
        s_can_tx_requested <= '1';
      end if;

      if CAN_CTRL_SOFT_RESET = '1' then
        s_can_ctrl_soft_reset_requested <= '1';
      end if;

      case s_fsm_state is
        when ST_SETUP =>
          -- Put CAN controller in reset mode
          if s_wb_done = '0' then
            wb_write(C_CAN_BM_CR, C_CAN_CR_RESET_MODE_VAL, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_SETUP_ACR;
          end if;

        -- Setup Acceptance Code Register
        -- Basically we just accept anything..
        when ST_SETUP_ACR =>
          if s_wb_done = '0' then
            wb_write(C_CAN_BM_ACR, C_CAN_ACR_RESET_VAL, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_SETUP_AMR;
          end if;

        -- Setup Acceptance Mask Register
        -- Basically we just accept anything..
        when ST_SETUP_AMR =>
          if s_wb_done = '0' then
            wb_write(C_CAN_BM_AMR, C_CAN_AMR_RESET_VAL, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_SETUP_BTR0;
          end if;

        -- Set up Bus Timing Register 0
        -- (Synchronization Jump Width and Baud Rate Prescale)
        when ST_SETUP_BTR0 =>
          if s_wb_done = '0' then
            wb_write(C_CAN_BTR0, C_CAN_BTR0_RESET_VAL(7 downto 6) & CAN_REG_CLK_PRESCALE, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_SETUP_BTR1;
          end if;

        -- Set up Bus Timing Register 1
        -- (Samples per bit (1x or 3x) and time segments per bit)
        when ST_SETUP_BTR1 =>
          if s_wb_done = '0' then
            wb_write(C_CAN_BTR1, C_CAN_BTR1_RESET_VAL, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_SETUP_CR;
          end if;

        -- Set up Control Register to put CAN controller in operation mode
        when ST_SETUP_CR =>
          if s_wb_done = '0' then
            wb_write(C_CAN_BM_CR, C_CAN_CR_OPERATION_VAL, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_IDLE;
          end if;

        when ST_IDLE =>
          if CAN_INTERRUPT_N = '0' then
            s_fsm_state <= ST_GET_CAN_INTERRUPT;
          elsif s_can_tx_requested = '1' and CAN_TX_BUSY = '0' then
            CAN_TX_BUSY        <= '1';
            s_can_tx_requested <= '0';
            s_fsm_state        <= ST_CAN_SEND_MESSAGE;
          elsif s_can_ctrl_soft_reset_requested = '1' and CAN_TX_BUSY = '0' then
            -- Reset is requested when bitrate register is written to, etc.,
            -- which can be done via CAN bus.
            -- Prioritize processing existing CAN messages over reset,
            -- so that a HLP write to such a register gets a response before
            -- the reset is performed
            s_can_ctrl_soft_reset_requested <= '0';
            s_fsm_state                     <= ST_SETUP;
          end if;

        when ST_GET_CAN_INTERRUPT =>
          if s_wb_done = '0' then
            wb_read(C_CAN_IR, v_wb_read_data, s_wb_done);
            s_can_isr_value <= v_wb_read_data;
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_CHECK_CAN_INTERRUPT;
          end if;

        when ST_CHECK_CAN_INTERRUPT =>
          -- TODO: More than one IRQ bit can be set at a time,
          --       and this won't work properly if more than one bit is set..
          if s_can_isr_value(C_CAN_RX_IRQ_BIT) = '1' then
            s_fsm_state <= ST_CAN_GET_MESSAGE;
          elsif s_can_isr_value(C_CAN_TX_IRQ_BIT) = '1' then
            s_fsm_state <= ST_CAN_MESSAGE_SENT;
          elsif s_can_isr_value(C_CAN_ERROR_IRQ_BIT) = '1' then
            s_fsm_state <= ST_CAN_ERROR;
          elsif s_can_isr_value(C_CAN_DATA_OVERRUN_IRQ_BIT) = '1' then
            s_fsm_state <= ST_CAN_DATA_OVERRUN;
          elsif s_can_isr_value(C_CAN_WAKEUP_IRQ_BIT) = '1' then
            s_fsm_state <= ST_CAN_WAKEUP;
          else
            s_fsm_state <= ST_IDLE;
          end if;

        when ST_CAN_GET_MESSAGE =>
          s_can_msg_recv_counter <= s_can_msg_recv_counter + 1;
          s_fsm_state            <= ST_READ_RX_ID1;

        when ST_READ_RX_ID1 =>
          if s_wb_done = '0' then
            wb_read(C_CAN_BM_RXB_ID1, v_wb_read_data, s_wb_done);
            s_can_rx_id1 <= v_wb_read_data;
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_READ_RX_ID2;
          end if;

        when ST_READ_RX_ID2 =>
          if s_wb_done = '0' then
            wb_read(C_CAN_BM_RXB_ID2, v_wb_read_data, s_wb_done);
            s_can_rx_id2 <= v_wb_read_data;
          else
            s_wb_done      <= '0';
            s_byte_counter <= to_unsigned(0, s_byte_counter'length);
            s_fsm_state    <= ST_READ_RX_BUFFER;
          end if;

        when ST_READ_RX_BUFFER =>
          CAN_RX_MSG_SIZE <= s_can_rx_id2(3 downto 0);

          if s_byte_counter = CAN_RX_MSG_BUFFER'length then
            CAN_MSG_RECEIVED <= '1';
            s_fsm_state      <= ST_CAN_RELEASE_RECV_BUFFER;
          elsif s_wb_done = '0' then
            -- TODO:
            -- Can't have the argument to wb_read change, which it does when
            -- s_byte_counter increases...
            wb_read(C_CAN_BM_RXB_DATA1+to_integer(s_byte_counter),
                    v_wb_read_data,
                    s_wb_done);
            CAN_RX_MSG_BUFFER(to_integer(s_byte_counter)) <= v_wb_read_data;
          else
            s_wb_done      <= '0';
            s_byte_counter <= s_byte_counter + 1;
            s_fsm_state    <= ST_READ_RX_BUFFER;
          end if;

        when ST_CAN_RELEASE_RECV_BUFFER =>
          if s_wb_done = '0' then
            wb_write(C_CAN_CMR, C_CAN_CMR_RELEASE_RECV_BUFF_VAL, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_IDLE;
          end if;

        when ST_CAN_SEND_MESSAGE =>
          s_can_tx_id1             <= CAN_MY_ID(10 downto 3);
          s_can_tx_id2(7 downto 5) <= CAN_MY_ID(2 downto 0);

          -- Bit 4: Remote Transmission Request (RTR)
          s_can_tx_id2(4) <= '0';

          -- Bit 3 to 0: Data Length Code (DLC)
          s_can_tx_id2(3 downto 0) <= CAN_TX_MSG_SIZE;
          s_fsm_state              <= ST_WRITE_TX_ID1;

        when ST_WRITE_TX_ID1 =>
          if s_wb_done = '0' then
            wb_write(C_CAN_BM_TXB_ID1, s_can_tx_id1, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_WRITE_TX_ID2;
          end if;

        when ST_WRITE_TX_ID2 =>
          if s_wb_done = '0' then
            wb_write(C_CAN_BM_TXB_ID2, s_can_tx_id2, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_WRITE_TX_BUFFER;
          end if;
          s_byte_counter <= to_unsigned(0, s_byte_counter'length);

        -- Here we just copy all the bytes in CAN_TX_MSG_BUFFER, even if the
        -- message transmitted has a shorter data length (DLC).
        -- The unused bytes will simply be ignored by the CAN controller
        when ST_WRITE_TX_BUFFER =>
          if s_byte_counter = CAN_TX_MSG_BUFFER'length then
            s_fsm_state <= ST_INITIATE_CAN_TX;
          elsif s_wb_done = '0' then
            -- TODO:
            -- Can't have the argument to wb_read change, which it does when
            -- s_byte_counter increases...
            v_wb_write_data := CAN_TX_MSG_BUFFER(to_integer(s_byte_counter));
            wb_write(C_CAN_BM_TXB_DATA1+to_integer(s_byte_counter),
                     v_wb_write_data,
                     s_wb_done);
          else
            s_wb_done      <= '0';
            s_byte_counter <= s_byte_counter + 1;
            s_fsm_state    <= ST_WRITE_TX_BUFFER;
          end if;

        when ST_INITIATE_CAN_TX =>
          if s_wb_done = '0' then
            wb_write(C_CAN_CMR, C_CAN_CMR_XMIT_REQUEST_VAL, s_wb_done);
          else
            s_wb_done   <= '0';
            s_fsm_state <= ST_IDLE;
          end if;

        when ST_CAN_MESSAGE_SENT =>
          CAN_TX_BUSY            <= '0';
          s_can_msg_sent_counter <= s_can_msg_sent_counter + 1;
          s_fsm_state            <= ST_IDLE;

        when ST_CAN_ERROR =>
          -- TODO: Error handling..
          CAN_TX_BUSY <= '0';
          s_fsm_state <= ST_IDLE;

        when ST_CAN_DATA_OVERRUN =>
          s_fsm_state <= ST_IDLE;

        when ST_CAN_WAKEUP =>
          s_fsm_state <= ST_IDLE;
        when others => null;
      end case;
    end if;
  end process proc_fsm;

end architecture rtl;
