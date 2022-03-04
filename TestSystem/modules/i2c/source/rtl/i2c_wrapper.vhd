-- $Id$
-------------------------------------------------------------------------------
-- Title      : I2C Interface - Wrapper for I2C wishbone master core
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : i2c_wrapper.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2016-03-23
-- Last update: 2017-06-28
-- Platform   : Xilinx Vivado 2015.4
-- Target     : Kintex-7
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrap wishbone slave for I2C to provide full I2C transactions
--              for various devices
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Wishbone interface package
use work.intercon_pkg.all;
-- I2C package
use work.i2c_pkg.all;

entity i2c_wrapper is
  port (
    -- Wishbone interface signals
    WB_CLK    : in  std_logic;          -- master clock input
    WB_RST    : in  std_logic := '0';   -- synchronous active high reset
    WB_WBS_I  : in  wbs_i_type;
    WB_WBS_O  : out wbs_o_type;
    -- i2c lines
    SCL_PAD_i : in  std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c clock line input
    SCL_PAD_o : out std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c clock line output
    SCL_PAD_T : out std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c clock line output enable, active low
    SDA_PAD_i : in  std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c data line input
    SDA_PAD_o : out std_logic_vector(C_NUM_I2C-1 downto 0);  -- i2c data line output
    SDA_PAD_T : out std_logic_vector(C_NUM_I2C-1 downto 0)  -- i2c data line output enable, active low
    );
end entity i2c_wrapper;

architecture structural of i2c_wrapper is
  constant C_GBTX_SLAVE_ADDR    : std_logic_vector(6 downto 0) := "0000001";
  constant C_PU_DAC_SLAVE_ADDR  : std_logic_vector(6 downto 0) := "0010000";
  constant C_PU_IOM_SLAVE_ADDR  : std_logic_vector(6 downto 0) := "0100101";
  constant C_PU_POT_SLAVE_ADDR  : std_logic_vector(6 downto 0) := "0101100";
  constant C_PU_POTB_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0101001";
  constant C_PU_ADC_SLAVE_ADDR  : std_logic_vector(6 downto 0) := "0100010";

  constant C_PRER_ADDR    : std_logic_vector(7 downto 0) := x"00";
  constant C_CTR_ADDR     : std_logic_vector(7 downto 0) := x"01";
  constant C_TXR_RXR_ADDR : std_logic_vector(7 downto 0) := x"02";
  constant C_CR_SR_ADDR   : std_logic_vector(7 downto 0) := x"03";

  signal sGbtI2cWbs_i : wbs_i_type;
  signal sGbtI2cWbs_o : wbs_o_type;

  signal sPuI2cWbs_i : wbs_i_type;
  signal sPuI2cWbs_o : wbs_o_type;

  signal sI2cWbs_i : wbs_i_type;
  signal sI2cWbs_o : wbs_o_type;

  signal wbs_ss_gbt : std_logic;
  signal wbs_ss_pu  : std_logic;

  signal sGbtxRegAddr : unsigned(15 downto 0);

  signal sTXR_RXR : std_logic_vector(7 downto 0);
  signal sCR_SR   : std_logic_vector(7 downto 0);

  signal bInitGbt : boolean := false;
  signal bInitPu  : boolean := false;


begin

  Wishbone_slave : process (WB_CLK) is
    variable vState     : integer range 0 to 31         := 0;
    variable vInit      : integer range 0 to 7          := 0;
    variable bWaitACK   : boolean                       := false;
    variable bWaitSR    : boolean                       := false;
    variable vData      : std_logic_vector(7 downto 0)  := x"00";
    variable vSlaveAddr : std_logic_vector(6 downto 0)  := "0000000";
    variable vTXR1      : std_logic_vector(15 downto 0) := x"0000";
    variable vTXR2      : std_logic_vector(15 downto 0) := x"0000";
    variable vTXR3      : std_logic_vector(15 downto 0) := x"0000";
    variable vCR4       : std_logic_vector(15 downto 0) := x"0000";
  begin
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then              -- synchronous reset (active high)
        sI2cWbs_i.dat_i  <= (others => '0');
        sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
        sI2cWbs_i.stb_i  <= '0';
        sI2cWbs_i.cyc_i  <= '0';
        WB_WBS_O.ack_o   <= '0';
        WB_WBS_O.dat_o   <= (others => '1');
        WB_WBS_O.err_o   <= '0';
        bWaitAck         := false;
        bWaitSR          := false;
        vInit            := 0;
        vState           := 0;
        vTXR1            := (others => '0');
        vTXR2            := (others => '0');
        vTXR3            := (others => '0');
        sGbtxRegAddr     <= (others => '0');
        sTXR_RXR         <= C_TXR_RXR_ADDR;
        sCR_SR           <= C_CR_SR_ADDR;
        bInitGbt         <= false;
        bInitPu          <= false;
        
      else
        WB_WBS_O.ack_o <= '0';
        WB_WBS_O.err_o <= '0';

        if bWaitAck then  -- stay here until ACK is received from I2c core
          if sI2cWbs_o.ack_o = '1' then
            if (sI2cWbs_i.addr_i(1 downto 0) = "11") and (sI2cWbs_i.we_i = '0') then
              -- reading SR register
              if sI2cWbs_o.dat_o(5) = '1' then  -- error bit set?
                WB_WBS_O.err_o <= '1';
              else
                WB_WBS_O.err_o <= '0';
              end if;

              if sI2cWbs_o.dat_o(1) = '0' then  -- transfer finished (tip) set?
                bWaitSR := false;
              end if;
            end if;

            if not bWaitSR then
              bWaitACK        := false;
              vData           := sI2cWbs_o.dat_o(7 downto 0);
              sI2cWbs_i.stb_i <= '0';
              sI2cWbs_i.cyc_i <= '0';
              sI2cWbs_i.we_i  <= '0';
            end if;
          end if;

        else
          -- defaults unless overridden:
          sI2cWbs_i.stb_i <= '1';
          sI2cWbs_i.cyc_i <= '1';
          sI2cWbs_i.we_i  <= '1';
          bWaitACK        := true;
          bWaitSR         := false;

          if vInit /= 4 then                  -- initialize I2C core & enable
            ---------------------------------------------------------------------
            -- I2C frequency setting is:
            -- (wb-frequency/(5 * I2C-frequency)) - 1
            -- wb-frequency = 160MHz
            -- GBTx I2C f = 100kHz -> 0x13f
            -- PU I2C f = 50kHz -> 0x27f
            ---------------------------------------------------------------------
            bInitGBT <= false;
            bInitPu  <= false;
            case vInit is
              when 0 =>
                -- GBTx
                sI2cWbs_i.addr_i <= C_PRER_ADDR;
                sI2cWbs_i.dat_i  <= x"013f";  -- 100kHz
                bInitGbt         <= true;
              when 1 =>
                sI2cWbs_i.addr_i <= C_CTR_ADDR;
                sI2cWbs_i.dat_i  <= x"0080";  -- "enable" bit
                bInitGbt         <= true;
              when 2 =>
                -- PU
                sI2cWbs_i.addr_i <= C_PRER_ADDR;
                sI2cWbs_i.dat_i  <= x"027f";  -- 50kHz
                bInitPu          <= true;
              when others =>
                sI2cWbs_i.addr_i <= C_CTR_ADDR;
                sI2cWbs_i.dat_i  <= x"0080";  -- "enable" bit
                bInitPu          <= true;
            end case;
            vInit := vInit + 1;

          else
            bInitGBT <= false;
            bInitPu  <= false;

            -- I2C read/write
            if (WB_WBS_I.cyc_i = '1') and (WB_WBS_I.stb_i = '1') then
              case vState is
                when 0 =>
                  -- write I2C slave address & Write bit ('0')
                  -- or r/w internal register, depending on WB address
                  case WB_WBS_I.addr_i is
--                  // r/w GBTx Address register
                    when x"00" =>
                      if WB_WBS_I.we_i = '1' then   -- write
                        sGbtxRegAddr <= unsigned(WB_WBS_I.dat_i);
                      else              -- read
                        WB_WBS_O.dat_o <= std_logic_vector(sGbtxRegAddr);
                      end if;
                      WB_WBS_O.ack_o  <= '1';   -- raise ACK
                      bWaitAck        := false;  -- override defaults
                      sI2cWbs_i.stb_i <= '0';
                      sI2cWbs_i.cyc_i <= '0';
                      sI2cWbs_i.we_i  <= '0';
                      vState          := 31;    -- goto IDLE state
--                  // r/w GBTx I2C register
                    when x"01" =>
                      vSlaveAddr       := C_GBTX_SLAVE_ADDR;
                      sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                      sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                      sTXR_RXR         <= C_TXR_RXR_ADDR;
                      sCR_SR           <= C_CR_SR_ADDR;
                      vTXR1            := x"00" & std_logic_vector(sGbtxRegAddr(7 downto 0));
                      vTXR2            := x"00" & std_logic_vector(sGbtxRegAddr(15 downto 8));
                      vTXR3            := WB_WBS_I.dat_i;
                      vCR4             := x"0010";  -- WR bit to CR in State 4
                      sGbtxRegAddr     <= sGbtxRegAddr + 1;  -- increment address
--                  // r/w Power Unit IO module
                    when x"02" =>
                      vSlaveAddr       := C_PU_IOM_SLAVE_ADDR;
                      sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                      sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                      sTXR_RXR         <= C_TXR_RXR_ADDR;
                      sCR_SR           <= C_CR_SR_ADDR;
                      -- write 1 byte in State 9
                      vTXR3            := x"00" & "000" & WB_WBS_I.dat_i(4 downto 0);
                      if WB_WBS_I.we_i = '1' then   -- I2C write?
                        sI2cWbs_i.dat_i <= x"00" & vSlaveAddr & '0';
                      else              -- I2C read?
                        sI2cWbs_i.dat_i <= x"00" & vSlaveAddr & '1';
                      end if;
                      -- start in State 18
                      vState := 17;  -- 1 less, since it will be increased below
--                  // write Power Unit Current DAC
                    when x"03" | x"04" | x"05" | x"06" | x"07" =>  -- PU Current DAC write
                      if WB_WBS_I.we_i = '1' then   -- I2C write?
                        vSlaveAddr       := C_PU_DAC_SLAVE_ADDR;
                        sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                        sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                        sTXR_RXR         <= C_TXR_RXR_ADDR;
                        sCR_SR           <= C_CR_SR_ADDR;
                        -- use WB address as bitmask for channels
                        if WB_WBS_I.addr_i(2) = '1' then
                          vTXR1 := x"00" & "0011" & "00" & WB_WBS_I.addr_i(1 downto 0);
                        else
                          vTXR1 := x"00" & "0011" & "1111";  -- all channels
                        end if;
                        vTXR2 := WB_WBS_I.dat_i;
                        vTXR3 := WB_WBS_I.dat_i;
                      else  -- read transaction not valid, just ACK & finish
                        WB_WBS_O.ack_o  <= '1';  -- raise ACK
                        bWaitAck        := false;   -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;  -- goto IDLE state
                      end if;
--                  // write Power Unit Output voltage Potentiometer
                    when x"08" | x"09" | x"0a" | x"0b" =>
                      if WB_WBS_I.we_i = '1' then   -- I2C write?
                        vSlaveAddr       := C_PU_POT_SLAVE_ADDR;
                        sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                        sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                        sTXR_RXR         <= C_TXR_RXR_ADDR;
                        sCR_SR           <= C_CR_SR_ADDR;
                        -- use WB address as bitmask for channels
                        vTXR2            := x"00" & "000000" & WB_WBS_I.addr_i(1 downto 0);
                        vTXR3            := WB_WBS_I.dat_i;
                        vCR4             := x"0090";  -- WR & STA bits to CR in State 4
                        -- start in State 4
                        vState           := 3;  -- 1 less, since it will be increased below
                      else  -- read transaction not valid, just ACK & finish
                        WB_WBS_O.ack_o  <= '1';  -- raise ACK
                        bWaitAck        := false;   -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;  -- goto IDLE state
                      end if;
--                  // store/recall Power Unit Output voltage Pot values
                    when x"0c" =>
                      if WB_WBS_I.we_i = '1' then   -- I2C write?
                        vSlaveAddr       := C_PU_POT_SLAVE_ADDR;
                        sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                        sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                        sTXR_RXR         <= C_TXR_RXR_ADDR;
                        sCR_SR           <= C_CR_SR_ADDR;
                        -- write 1 byte in State 9
                        vTXR3            := WB_WBS_I.dat_i;
                        -- start in State 18
                        vState           := 17;  -- 1 less, since it will be increased below
                      else  -- read transaction not valid, just ACK & finish
                        WB_WBS_O.ack_o  <= '1';  -- raise ACK
                        bWaitAck        := false;   -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;  -- goto IDLE state
                      end if;
--                  // write Power Unit Bias voltage Potentiometer
                    when x"0d" =>
                      if WB_WBS_I.we_i = '1' then   -- I2C write?
                        vSlaveAddr       := C_PU_POTB_SLAVE_ADDR;
                        sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                        sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                        sTXR_RXR         <= C_TXR_RXR_ADDR;
                        sCR_SR           <= C_CR_SR_ADDR;
                        vTXR2            := x"0011";
                        vTXR3            := WB_WBS_I.dat_i;
                        vCR4             := x"0090";  -- WR & STA bits to CR in State 4
                        -- start in State 4
                        vState           := 3;  -- 1 less, since it will be increased below
                      else  -- read transaction not valid, just ACK & finish
                        WB_WBS_O.ack_o  <= '1';  -- raise ACK
                        bWaitAck        := false;   -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;  -- goto IDLE state
                      end if;
--                  // r/w Power Unit ADC
                    when x"10" | x"11" | x"12" | x"13" | x"14" | x"15" | x"16" | x"17" =>
                      vSlaveAddr       := C_PU_ADC_SLAVE_ADDR;
                      sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                      sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                      sTXR_RXR         <= C_TXR_RXR_ADDR;
                      sCR_SR           <= C_CR_SR_ADDR;
                      if WB_WBS_I.we_i = '1' then
                        vTXR1 := x"0003";
                        vTXR2 := x"00c0";
                      else
                        vTXR1 := x"00" & '1' & WB_WBS_I.addr_i(2 downto 0) & "0000";
                      end if;
                      -- start in State 20
                      vState := 19;  -- 1 less, since it will be increased below

--                  // not a valid address
                    when others =>
                      WB_WBS_O.ack_o  <= '1';    -- raise ACK
                      bWaitAck        := false;  -- override defaults
                      sI2cWbs_i.stb_i <= '0';
                      sI2cWbs_i.cyc_i <= '0';
                      sI2cWbs_i.we_i  <= '0';
                      vState          := 31;     -- goto IDLE state
                  end case;

--              // Common Steps: I2C "write" slave address, 1st and 2nd byte
                when 1 =>               -- write WR and STA bits to CR
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= x"0090";
                when 2 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 3 =>               -- write I2C first byte
                  sI2cWbs_i.addr_i <= sTXR_RXR;
                  sI2cWbs_i.dat_i  <= vTXR1;
                when 4 =>               -- write vCR4 bits to CR
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= vCR4;
                when 5 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 6 =>               -- write I2C second byte
                  sI2cWbs_i.addr_i <= sTXR_RXR;
                  sI2cWbs_i.dat_i  <= vTXR2;
                when 7 =>               -- write WR bit to CR
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= x"0010";
                when 8 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;


--              // Common steps for READ & WRITE, only data different
                when 9 =>
                  sI2cWbs_i.addr_i <= sTXR_RXR;
                  if WB_WBS_I.we_i = '1' then  -- WRITE: send data 3rd byte
                    sI2cWbs_i.dat_i <= vTXR3;
                  else             -- READ: send I2C slave address & RD bit (1)
                    sI2cWbs_i.dat_i <= x"00" & vSlaveAddr & '1';
                  end if;
                when 10 =>
                  sI2cWbs_i.addr_i <= sCR_SR;
                  if WB_WBS_I.we_i = '1' then  -- WRITE: WR & STO bits to CR
                    sI2cWbs_i.dat_i <= x"0050";
                  else                  -- READ: WR & STA bits to CR
                    sI2cWbs_i.dat_i <= x"0090";
                  end if;
                when 11 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                  if WB_WBS_I.we_i = '0' then
                    vState := 12;  -- 1 less, since it will be increased below
                  end if;


--              // Finish WRITE
                when 12 =>                 -- raise ACK & finish
                  WB_WBS_O.ack_o  <= '1';
                  WB_WBS_O.dat_o  <= WB_WBS_I.dat_i;
                  sI2cWbs_i.stb_i <= '0';  -- override defaults
                  sI2cWbs_i.cyc_i <= '0';
                  sI2cWbs_i.we_i  <= '0';
                  bWaitACK        := false;
                  vState          := 31;   -- goto IDLE state


--              // Read 1 byte from I2C
                when 13 =>              -- write RD, STO & ACK bits to CR
                  if sI2cWbs_i.addr_i = sCR_SR then
                    WB_WBS_O.dat_o(15 downto 8) <= x"00";
                  else
                    WB_WBS_O.dat_o(15 downto 8) <= vData;
                  end if;
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= x"0068";
                when 14 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 15 =>              -- read data from RXR
                  sI2cWbs_i.addr_i <= sTXR_RXR;
                  sI2cWbs_i.we_i   <= '0';
                when 16 =>  -- store data and write 0 to CR to clear ACK bit
                  WB_WBS_O.dat_o(7 downto 0) <= vData;
                  sI2cWbs_i.addr_i           <= sCR_SR;
                  sI2cWbs_i.dat_i            <= x"0000";
                when 17 =>              -- raise ACK & finish
                  WB_WBS_O.ack_o  <= '1';
                  sI2cWbs_i.stb_i <= '0';  -- overwrite defaults
                  sI2cWbs_i.cyc_i <= '0';
                  sI2cWbs_i.we_i  <= '0';
                  bWaitACK        := false;
                  vState          := 31;   -- goto IDLE state


--              // IOM r/w
                when 18 =>              -- write WR and STA bits to CR
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= x"0090";
                when 19 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                  if WB_WBS_I.we_i = '0' then  -- Finish reading from State 13
                    vState := 12;  -- 1 less, since it will be increased below
                  else                  -- Finish writing from State 9
                    vState := 8;   -- 1 less, since it will be increased below
                  end if;


                when 20 =>              -- write WR and STA bits to CR
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= x"0090";
                when 21 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 22 =>              -- write I2C first byte
                  sI2cWbs_i.addr_i <= sTXR_RXR;
                  sI2cWbs_i.dat_i  <= vTXR1;
                when 23 =>              -- write WR bit to CR
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= x"0010";
                when 24 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;


--              // Common steps for READ & WRITE, only data different
                when 25 =>
                  sI2cWbs_i.addr_i <= sTXR_RXR;
                  if WB_WBS_I.we_i = '1' then  -- WRITE: send data 2nd byte
                    sI2cWbs_i.dat_i <= vTXR2;
                  else             -- READ: send I2C slave address & RD bit (1)
                    sI2cWbs_i.dat_i <= x"00" & vSlaveAddr & '1';
                  end if;
                when 26 =>
                  sI2cWbs_i.addr_i <= sCR_SR;
                  if WB_WBS_I.we_i = '1' then  -- WRITE: WR & STO bits to CR
                    sI2cWbs_i.dat_i <= x"0050";
                  else                  -- READ: WR & STA bits to CR
                    sI2cWbs_i.dat_i <= x"0090";
                  end if;
                when 27 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                  if WB_WBS_I.we_i = '1' then
                    vState := 11;  -- 1 less, since it will be increased below
                  end if;

--              // Read 1st byte
                when 28 =>              -- write RD bit to CR
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.dat_i  <= x"0020";
                when 29 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= sCR_SR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 30 =>              -- read data from RXR
                  sI2cWbs_i.addr_i <= sTXR_RXR;
                  sI2cWbs_i.we_i   <= '0';
                  -- continue in State 13
                  vState           := 12;  -- 1 less, since it will be increased below


--              // IDLE STATE
                when others =>          -- 31
                  -- stay here until cyc_o and stb_o go down
                  sI2cWbs_i.stb_i <= '0';
                  sI2cWbs_i.cyc_i <= '0';
                  sI2cWbs_i.we_i  <= '0';
                  bWaitACK        := false;
              end case;

              if vState /= 31 then
                vState := vState + 1;
              end if;

            else                        -- No transaction going on
              vState          := 0;
              WB_WBS_O.dat_o  <= (others => '1');
              sI2cWbs_i.stb_i <= '0';   -- override defaults
              sI2cWbs_i.cyc_i <= '0';
              sI2cWbs_i.we_i  <= '0';
              bWaitACK        := false;
            end if;
          end if;
        end if;
      end if;
    end if;

  end process Wishbone_slave;

  -- determine correct wishbone slave
  p_slave_select : process (WB_WBS_I.addr_i, bInitGbt, bInitPu) is
  begin
    if bInitGbt then
      -- initializing GBT I2C, select GBT wishbone
      wbs_ss_gbt <= '1';
    elsif not bInitPu then
      -- address 0x00 and 0x01 go to GBT I2C
      case WB_WBS_I.addr_i is
        when x"00" | x"01" => wbs_ss_gbt <= '1';
        when others        => wbs_ss_gbt <= '0';
      end case;
    else
      wbs_ss_gbt <= '0';
    end if;

    if bInitPu then
      -- initializing PU I2C, select PU wishbone
      wbs_ss_pu <= '1';
    elsif not bInitGbt then
      -- 0x02 to 0x0d and 0x10 to 0x17 go to PU I2C 
      case to_integer(unsigned(WB_WBS_I.addr_i)) is
        when 2 to 13  => wbs_ss_pu <= '1';
        when 16 to 23 => wbs_ss_pu <= '1';
        when others   => wbs_ss_pu <= '0';
      end case;
    else
      wbs_ss_pu <= '0'; 
    end if;
  end process p_slave_select;

  -- wishbone master to slave mapping
  sGbtI2cWbs_i.cyc_i  <= sI2cWbs_i.cyc_i and wbs_ss_gbt;
  sGbtI2cWbs_i.stb_i  <= sI2cWbs_i.stb_i;
  sGbtI2cWbs_i.we_i   <= sI2cWbs_i.we_i;
  sGbtI2cWbs_i.addr_i <= sI2cWbs_i.addr_i;
  sGbtI2cWbs_i.dat_i  <= sI2cWbs_i.dat_i;

  sPuI2cWbs_i.cyc_i  <= sI2cWbs_i.cyc_i and wbs_ss_pu;
  sPuI2cWbs_i.stb_i  <= sI2cWbs_i.stb_i;
  sPuI2cWbs_i.we_i   <= sI2cWbs_i.we_i;
  sPuI2cWbs_i.addr_i <= sI2cWbs_i.addr_i;
  sPuI2cWbs_i.dat_i  <= sI2cWbs_i.dat_i;

  -- wishbone slave to master mapping
  sI2cWbs_o.ack_o <= '0' when ((sGbtI2cWbs_o.ack_o = '0') and
                               (sPuI2cWbs_o.ack_o = '0'))
                     else '1';
  
  sI2cWbs_o.dat_o <= sGbtI2cWbs_o.dat_o when wbs_ss_gbt = '1' else
                     sPuI2cWbs_o.dat_o when wbs_ss_pu = '1' else
                     (others => '0');

  -- attach I2C master core for GBT
  INST_gbt_i2c_master : entity work.i2c_master_top
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => sGbtI2cWbs_i,
      WB_WBS_O  => sGbtI2cWbs_o,
      ARST      => '0',
      WB_INTA_o => open,
      SCL_PAD_i => SCL_PAD_i(0),
      SCL_PAD_o => SCL_PAD_o(0),
      SCL_PAD_T => SCL_PAD_T(0),
      SDA_PAD_i => SDA_PAD_i(0),
      SDA_PAD_o => SDA_PAD_o(0),
      SDA_PAD_T => SDA_PAD_T(0)
      );

  -- attach I2C master core for Power Unit (PU)
  INST_pu_i2c_master : entity work.i2c_master_top
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => sPuI2cWbs_i,
      WB_WBS_O  => sPuI2cWbs_o,
      ARST      => '0',
      WB_INTA_o => open,
      SCL_PAD_i => SCL_PAD_i(1),
      SCL_PAD_o => SCL_PAD_o(1),
      SCL_PAD_T => SCL_PAD_T(1),
      SDA_PAD_i => SDA_PAD_i(1),
      SDA_PAD_o => SDA_PAD_o(1),
      SDA_PAD_T => SDA_PAD_T(1)
      );

end architecture structural;
