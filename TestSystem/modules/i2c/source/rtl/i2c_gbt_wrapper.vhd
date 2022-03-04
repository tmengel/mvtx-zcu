-------------------------------------------------------------------------------
-- Title      : I2C Interface - Wrapper for I2C wishbone master core
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : i2c_gbt_wrapper.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2017-06-16
-- Last update: 2018-03-21
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrap wishbone slave for I2C to provide full I2C transactions
--              for GBTx ASICs
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Wishbone interface package
use work.intercon_pkg.all;

entity i2c_gbt_wrapper is
  port (
    -- Wishbone interface signals
    WB_CLK    : in  std_logic;          -- master clock input
    WB_RST    : in  std_logic := '0';   -- synchronous active high reset
    WB_WBS_I  : in  wbs_i_type;
    WB_WBS_O  : out wbs_o_type;
    -- i2c lines
    SCL_PAD_i : in  std_logic;          -- i2c clock line input
    SCL_PAD_o : out std_logic;          -- i2c clock line output
    SCL_PAD_T : out std_logic;  -- i2c clock line output enable, active low
    SDA_PAD_i : in  std_logic;          -- i2c data line input
    SDA_PAD_o : out std_logic;          -- i2c data line output
    SDA_PAD_T : out std_logic   -- i2c data line output enable, active low
    );
end entity i2c_gbt_wrapper;

architecture structural of i2c_gbt_wrapper is
  constant C_GBTX0_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0000001";
  constant C_GBTX1_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0000011";
  constant C_GBTX2_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0000101";

  constant C_PRER_ADDR    : std_logic_vector(7 downto 0) := x"00";
  constant C_CTR_ADDR     : std_logic_vector(7 downto 0) := x"01";
  constant C_TXR_RXR_ADDR : std_logic_vector(7 downto 0) := x"02";
  constant C_CR_SR_ADDR   : std_logic_vector(7 downto 0) := x"03";

  signal sGbtI2cWbs_i : wbs_i_type;
  signal sGbtI2cWbs_o : wbs_o_type;

  signal sI2cWbs_i : wbs_i_type;
  signal sI2cWbs_o : wbs_o_type;

  signal sGbtxRegAddr : unsigned(15 downto 0);


  constant C_FREQ_SELECTION_BIT_WIDTH : integer := 16;
  component i2c_frequency_selector is
    generic (FREQ_SELECTION_BIT_WIDTH : integer);
    port (frequency_setting_o : out std_logic_vector(FREQ_SELECTION_BIT_WIDTH-1 downto 0));
  end component;
  signal sFreqSetting : std_logic_vector(C_FREQ_SELECTION_BIT_WIDTH-1 downto 0);

begin

  i2c_frequency_selector_INST: i2c_frequency_selector
    generic map (
      FREQ_SELECTION_BIT_WIDTH => C_FREQ_SELECTION_BIT_WIDTH)
    port map (
      frequency_setting_o => sFreqSetting);

  Wishbone_slave : process (WB_CLK) is
    variable vState     : integer range 0 to 31         := 0;
    variable vInit      : integer range 0 to 3          := 0;
    variable bWaitACK   : boolean                       := false;
    variable bWaitSR    : boolean                       := false;
    variable vData      : std_logic_vector(7 downto 0)  := x"00";
    variable vSlaveAddr : std_logic_vector(6 downto 0)  := "0000000";
    variable vTXR1      : std_logic_vector(15 downto 0) := x"0000";
    variable vTXR2      : std_logic_vector(15 downto 0) := x"0000";
    variable vTXR3      : std_logic_vector(15 downto 0) := x"0000";
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
        bWaitACK         := false;
        bWaitSR          := false;
        vInit            := 0;
        vState           := 0;
        vTXR1            := (others => '0');
        vTXR2            := (others => '0');
        vTXR3            := (others => '0');
        sGbtxRegAddr     <= (others => '0');
        -- sFreqSetting     <= x"0003";

      else
        WB_WBS_O.ack_o <= '0';
        WB_WBS_O.err_o <= '0';

        if bWaitACK then  -- stay here until ACK is received from I2c core
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

          if vInit /= 2 then                  -- initialize I2C core & enable
            -- set initial slave address to address of GBTx0
            vSlaveAddr := C_GBTX0_SLAVE_ADDR;
            case vInit is
              when 0 =>
                -- GBTx
                sI2cWbs_i.addr_i <= C_PRER_ADDR;
                sI2cWbs_i.dat_i  <= sFreqSetting;  -- 100kHz
              when others =>
                sI2cWbs_i.addr_i <= C_CTR_ADDR;
                sI2cWbs_i.dat_i  <= x"0080";  -- "enable" bit
            end case;
            vInit := vInit + 1;

          else
            -- I2C read/write
            if (WB_WBS_I.cyc_i = '1') and (WB_WBS_I.stb_i = '1') then
              case vState is
                when 0 =>
                  -- write I2C slave address & Write bit ('0')
                  -- or r/w internal register, depending on WB address
                  case WB_WBS_I.addr_i is
--                  // r/w GBTx0 Address register
                    when x"00" =>
                      if WB_WBS_I.we_i = '1' then            -- write
                        vSlaveAddr   := C_GBTX0_SLAVE_ADDR;
                        sGbtxRegAddr <= unsigned(WB_WBS_I.dat_i);
                      else              -- read
                        WB_WBS_O.dat_o <= std_logic_vector(sGbtxRegAddr);
                      end if;
                      WB_WBS_O.ack_o  <= '1';    -- raise ACK
                      bWaitACK        := false;  -- override defaults
                      sI2cWbs_i.stb_i <= '0';
                      sI2cWbs_i.cyc_i <= '0';
                      sI2cWbs_i.we_i  <= '0';
                      vState          := 31;     -- goto IDLE state
--                  // r/w GBTx1 Address register
                    when x"01" =>
                      if WB_WBS_I.we_i = '1' then            -- write
                        vSlaveAddr   := C_GBTX1_SLAVE_ADDR;
                        sGbtxRegAddr <= unsigned(WB_WBS_I.dat_i);
                      else              -- read
                        WB_WBS_O.dat_o <= std_logic_vector(sGbtxRegAddr);
                      end if;
                      WB_WBS_O.ack_o  <= '1';    -- raise ACK
                      bWaitACK        := false;  -- override defaults
                      sI2cWbs_i.stb_i <= '0';
                      sI2cWbs_i.cyc_i <= '0';
                      sI2cWbs_i.we_i  <= '0';
                      vState          := 31;     -- goto IDLE state
--                  // r/w GBTx2 Address register
                    when x"02" =>
                      if WB_WBS_I.we_i = '1' then            -- write
                        vSlaveAddr   := C_GBTX2_SLAVE_ADDR;
                        sGbtxRegAddr <= unsigned(WB_WBS_I.dat_i);
                      else              -- read
                        WB_WBS_O.dat_o <= std_logic_vector(sGbtxRegAddr);
                      end if;
                      WB_WBS_O.ack_o  <= '1';    -- raise ACK
                      bWaitACK        := false;  -- override defaults
                      sI2cWbs_i.stb_i <= '0';
                      sI2cWbs_i.cyc_i <= '0';
                      sI2cWbs_i.we_i  <= '0';
                      vState          := 31;     -- goto IDLE state
--                  // r/w GBTx I2C register
                    when x"03" =>
                      sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                      sI2cWbs_i.dat_i  <= x"00" & vSlaveAddr & '0';
                      vTXR1            := x"00" & std_logic_vector(sGbtxRegAddr(7 downto 0));
                      vTXR2            := x"00" & std_logic_vector(sGbtxRegAddr(15 downto 8));
                      vTXR3            := WB_WBS_I.dat_i;
                      sGbtxRegAddr     <= sGbtxRegAddr + 1;  -- increment address

--                  // not a valid address
                    when others =>
                      WB_WBS_O.ack_o  <= '1';    -- raise ACK
                      bWaitACK        := false;  -- override defaults
                      sI2cWbs_i.stb_i <= '0';
                      sI2cWbs_i.cyc_i <= '0';
                      sI2cWbs_i.we_i  <= '0';
                      vState          := 31;     -- goto IDLE state
                  end case;

--              // Common Steps: I2C "write" slave address, 1st and 2nd byte

--              // Write Slave Address
                when 1 =>               -- write WR and STA bits to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0090";
                when 2 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;

--              // Write Byte 1
                when 3 =>               -- write I2C first byte
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.dat_i  <= vTXR1;
                when 4 =>               -- write WR bit to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0010";
                when 5 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;

--              // write Byte 2
                when 6 =>               -- write I2C second byte
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.dat_i  <= vTXR2;
                when 7 =>               -- write WR bit to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0010";
                when 8 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;


--              // Common steps for READ & WRITE, only data different

--              // Byte 3 or repeated start
                when 9 =>
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  if WB_WBS_I.we_i = '1' then  -- WRITE: send data 3rd byte
                    sI2cWbs_i.dat_i <= vTXR3;
                  else             -- READ: send I2C slave address & RD bit (1)
                    sI2cWbs_i.dat_i <= x"00" & vSlaveAddr & '1';
                  end if;
                when 10 =>
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  if WB_WBS_I.we_i = '1' then  -- WRITE: WR & STO bits to CR
                    sI2cWbs_i.dat_i <= x"0050";
                  else                  -- READ: WR & STA bits to CR
                    sI2cWbs_i.dat_i <= x"0090";
                  end if;
                when 11 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
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
                  WB_WBS_O.dat_o(15 downto 8) <= x"00";
                  sI2cWbs_i.addr_i            <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i             <= x"0068";
                when 14 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 15 =>              -- read data from RXR
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                when 16 =>  -- store data and write 0 to CR to clear ACK bit
                  WB_WBS_O.dat_o(7 downto 0) <= vData;
                  sI2cWbs_i.addr_i           <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i            <= x"0000";


--              // Finish READ
                when 17 =>                 -- raise ACK & finish
                  WB_WBS_O.ack_o  <= '1';
                  sI2cWbs_i.stb_i <= '0';  -- overwrite defaults
                  sI2cWbs_i.cyc_i <= '0';
                  sI2cWbs_i.we_i  <= '0';
                  bWaitACK        := false;
                  vState          := 31;   -- goto IDLE state

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

  -- wishbone master to slave mapping
  sGbtI2cWbs_i.cyc_i  <= sI2cWbs_i.cyc_i;
  sGbtI2cWbs_i.stb_i  <= sI2cWbs_i.stb_i;
  sGbtI2cWbs_i.we_i   <= sI2cWbs_i.we_i;
  sGbtI2cWbs_i.addr_i <= sI2cWbs_i.addr_i;
  sGbtI2cWbs_i.dat_i  <= sI2cWbs_i.dat_i;

  -- wishbone slave to master mapping
  sI2cWbs_o.ack_o <= sGbtI2cWbs_o.ack_o;
  sI2cWbs_o.dat_o <= sGbtI2cWbs_o.dat_o;

  -- attach I2C master core for GBT
  INST_gbt_i2c_master : entity work.i2c_master_top
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => sGbtI2cWbs_i,
      WB_WBS_O  => sGbtI2cWbs_o,
      ARST      => '0',
      WB_INTA_o => open,
      SCL_PAD_i => SCL_PAD_i,
      SCL_PAD_o => SCL_PAD_o,
      SCL_PAD_T => SCL_PAD_T,
      SDA_PAD_i => SDA_PAD_i,
      SDA_PAD_o => SDA_PAD_o,
      SDA_PAD_T => SDA_PAD_T
      );


end architecture structural;
