library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity i2c_slave is
  generic (
    G_SDA_DELAY : integer range 1 to 16 := 5);
  port (
    CLK      : in  std_logic;
    RESET    : in  std_logic;
    SCL      : in  std_logic;
    SDA_i    : in  std_logic;
    SDA_o    : out std_logic;
    SLV_ADR  : in  std_logic_vector(6 downto 0);
    TX_DATA  : in  std_logic_vector(7 downto 0);
    TX_WR    : in  std_logic;
    TX_EMPTY : out std_logic;
    RX_DATA  : out std_logic_vector(7 downto 0);
    RX_VLD   : out std_logic;
    RX_ACK   : in  std_logic;
    BUSY     : out std_logic;
    ERROR_C  : out std_logic_vector(1 downto 0)
    );
end entity i2c_slave;

architecture behavior of i2c_slave is
  signal sRxBufEna   : std_logic;
  signal sRxShiftreg : std_logic_vector(7 downto 0);
  signal sTxShiftreg : std_logic_vector(7 downto 0);
  signal sWrBuf      : std_logic_vector(7 downto 0);
  signal sRxVld      : std_logic;

  signal sSDA_reg : std_logic_vector(1 downto 0);
  signal sSCL_reg : std_logic_vector(1 downto 0);

  signal sSDA_del_i : std_logic;

  type TRANSFER_TYPE is (tREAD, tWRITE);
  signal sTransfer : TRANSFER_TYPE;

  signal bStartCond : boolean;
  signal bStopCond  : boolean;

  signal bSCL_falling : boolean;

  signal bTxEmpty : boolean;
  signal bBusy    : boolean;
  
begin  -- architecture behavior

  DELAY_SDA : block is
    signal sDelayLine : std_logic_vector(G_SDA_DELAY-1 downto 0);
  begin  -- block DELAY_SDA
    process (CLK) is
    begin  -- process
      if rising_edge(CLK) then          -- rising clock edge
        if RESET = '1' then             -- synchronous reset (active high)
          sDelayLine <= (others => '0');
        else
          sDelayLine <= sDelayLine(G_SDA_DELAY-2 downto 0) & sSDA_reg(1);
        end if;
      end if;
    end process;
    sSDA_del_i <= sDelayLine(sDelayLine'high);
  end block DELAY_SDA;


  process (CLK) is
    variable bSDA_rising  : boolean;
    variable bSDA_falling : boolean;
  begin  -- process
    if rising_edge(CLK) then            -- rising clock edge
      if RESET = '1' then               -- synchronous reset (active high)
        sSCL_reg   <= (others => '1');
        sSDA_reg   <= (others => '1');
        bStartCond <= false;
        bStopCond  <= false;
      else
        sSCL_reg <= sSCL_reg(0) & SCL;
        sSDA_reg <= sSDA_reg(0) & SDA_i;

        bSDA_rising  := sSDA_reg = "01";
        bSDA_falling := sSDA_reg = "10";

        bStartCond <= bSDA_falling and (sSCL_reg(0) = '1');
        bStopCond  <= bSDA_rising and (sSCL_reg(0) = '1');

        bSCL_falling <= sSCL_reg = "10";
        
      end if;
    end if;
  end process;

  states : block is
    type STATE_type is (st_IDLE,
                        st_WT_SCL_LO,
                        st_RD_SLV_ADR,
                        st_CHECK_STS_FOR_ACK,
                        st_CHECK_ACK,
                        st_BRANCH,
                        st_MSTR_WR,
                        st_MSTR_RD,
                        st_WR_ACK,
                        st_CHECK_STOP
                        );
    signal state_t       : STATE_type;
    signal iBitCnt       : integer range 0 to 8;
    signal sSlvAck       : std_logic;
    signal bLdTx2        : boolean;
    signal bLdTx3        : boolean;
    signal bLdTxShiftreg : boolean;
    
  begin  -- block states
    process (CLK) is
      variable vLdBitCnt : boolean;
    begin  -- process
      if rising_edge(CLK) then          -- rising clock edge
        if RESET = '1' then             -- synchronous reset (active high)
          state_t       <= st_IDLE;
          ERROR_C       <= "00";
          sTransfer     <= tREAD;
          sRxShiftreg   <= (others => '0');
          sTxShiftreg   <= (others => '0');
          RX_DATA       <= (others => '0');
          sWrBuf        <= (others => '0');
          bLdTxShiftreg <= false;
          bLdTx2        <= false;
          bLdTx3        <= false;
          bBusy         <= false;
          bTxempty      <= true;
          SDA_o         <= '1';
          sSlvAck       <= '1';
          sRxBufEna     <= '0';
          sRxVld        <= '0';
          iBitCnt       <= 0;
        else
          vLdBitCnt := false;

          case state_t is
            when st_IDLE =>
              bBusy   <= false;
              sSlvAck <= '1';           -- default
              if bStopCond then
                state_t <= st_IDLE;
              elsif bStartCond then
                bBusy   <= true;
                state_t <= st_WT_SCL_LO;
              end if;
              
            when st_WT_SCL_LO =>
              if bStopCond then
                state_t <= st_IDLE;
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              elsif bSCL_falling then
                state_t   <= st_RD_SLV_ADR;
                vLdBitCnt := true;
              end if;

            when st_RD_SLV_ADR =>
              if bStopCond then
                state_t <= st_IDLE;
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              elsif iBitCnt = 0 then
                if SLV_ADR = sRxShiftreg(7 downto 1) then
                  state_t <= st_CHECK_STS_FOR_ACK;
                else
                  state_t <= st_IDLE;
                end if;
              end if;

            when st_CHECK_STS_FOR_ACK =>
              if bStopCond then
                state_t <= st_IDLE;
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              elsif ((sRxShiftreg(0) = '1') and bTxEmpty) or  -- Master read
                           ((sRxShiftReg(0) = '0') and (sRxVld = '1')) then  -- Master write
                state_t <= st_IDLE;
              else
                sSlvAck <= '0';
                state_t <= st_BRANCH;
              end if;

            when st_BRANCH =>
              if bStopCond then
                state_t <= st_IDLE;
                sSlvAck <= '1';
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
                sSlvAck <= '1';
              elsif bSCL_falling then
                sSlvAck <= '1';
                if sRxShiftreg(0) = '0' then  -- Master Write
                  sTransfer <= tWRITE;
                  state_t   <= st_MSTR_WR;
                  vLdBitCnt := true;
                else
                  sTransfer     <= tREAD;
                  state_t       <= st_MSTR_RD;
                  vLdBitCnt     := true;
                  bLdTxShiftreg <= true;
                end if;
              end if;

            when st_MSTR_WR =>
              if bStopCond then
                state_t <= st_IDLE;
                ERROR_C <= "00";
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              elsif iBitCnt = 0 then
                if sRxVld = '1' then
                  state_t <= st_IDLE;
                  ERROR_C <= "01";
                else
                  sRxBufEna <= '1';
                  state_t   <= st_WR_ACK;
                  sSlvAck   <= '0';
                end if;
              end if;

            when st_MSTR_RD =>
              bLdTxShiftreg <= false;
              if bTxEmpty then
                ERROR_C <= "10";
              else
                ERROR_C <= "00";
              end if;

              if bStopCond then
                state_t <= st_IDLE;
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              elsif iBitCnt = 0 then
                state_t <= st_CHECK_ACK;
              end if;

            when st_CHECK_ACK =>
              if bStopCond then
                state_t <= st_IDLE;
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              elsif bSCL_falling then
                if sSDA_del_i = '0' then  -- ACK from master
                  state_t       <= st_MSTR_RD;
                  bLdTxShiftreg <= true;
                  vLdBitCnt     := true;
                else
                  -- no master ACK, check if followed by STOP
                  state_t <= st_CHECK_STOP;
                end if;
              end if;

            when st_CHECK_STOP =>
              if bStopCond then
                state_t <= st_IDLE;
                ERROR_C <= "00";
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              end if;

            when st_WR_ACK =>
              sRxBufEna <= '0';
              if bStopCond then
                state_t <= st_IDLE;
              elsif bStartCond then
                state_t <= st_WT_SCL_LO;
              elsif bSCL_falling then
                state_t   <= st_MSTR_WR;
                sSlvAck   <= '1';
                vLdBitCnt := true;
              end if;
              
            when others => null;
          end case;

          -- bit counter
          if vLdBitCnt then
            iBitCnt <= 8;
          elsif (iBitCnt > 0) and bSCL_falling then
            iBitCnt <= iBitCnt - 1;
          end if;

          -- shift register for Rx Data
          if bSCL_falling then
            sRxShiftreg <= sRxShiftreg(6 downto 0) & sSDA_del_i;
          end if;

          -- delay TX shift register load by 2 clocks
          bLdTx2 <= bLdTxShiftreg;
          bLdTx3 <= bLdTx2;

          -- write RX buffer
          if (sRxBufEna = '1') and (sRxVld = '0') then
            RX_DATA <= sRxShiftreg;
            sRxVld  <= '1';
          else
            sRxVld <= '0';
          end if;

          -- TX data is double buffered
          if TX_WR = '1' then
            sWrBuf   <= TX_DATA;
            bTxEmpty <= false;
          elsif bLdTx3 then
            bTxEmpty <= true;
          end if;

          if bLdTx3 then
            sTxShiftreg <= TX_DATA;
          elsif bSCL_falling then
            sTxShiftreg(7 downto 1) <= sTxShiftreg(6 downto 0);
          end if;

          -- MUX for slave ack and slave data
          if state_t = st_MSTR_RD then
            SDA_o <= sTxShiftreg(7);
          else
            SDA_o <= sSlvAck;
          end if;
          
        end if;
      end if;
    end process;
  end block states;

  -- connect internal signals
  TX_EMPTY <= '1' when bTxEmpty else '0';
  BUSY     <= '1' when bBusy    else '0';
  RX_VLD   <= sRxVld;
  
end architecture behavior;
