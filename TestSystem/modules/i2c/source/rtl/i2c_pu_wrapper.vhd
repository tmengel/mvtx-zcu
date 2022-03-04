-------------------------------------------------------------------------------
-- Title      : I2C Interface - Wrapper for I2C wishbone master core
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : i2c_pu_wrapper.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2017-06-16
-- Last update: 2018-03-21
-- Platform   : Xilinx Vivado 2016.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrap wishbone slave for I2C to provide full I2C transactions
--              for controlling the power unit
--
--              I2C bus frequency is set to 100kHz, based on a wishbone
--              speed of 160MHz
--
--              I2C slave addresses are mapped to wishbone register addresses
--
--              I2C write transactions bytes are sent as:
--              SL - sByte1 - sByte2 - sByte3   or
--              SL - sByte2 - sByte3            or
--              SL - sByte3
--
--              I2C read transactions bytes are as follows:
--              SL - read[7:0]                  or
--              SL - read[15:8] - read[7:0]     or
--              SL - sByte1 - read[15:8] - read[7:0]
--
--              sByte1 is sent to wishbone address 0, while sByte2 and sByte3
--              are sent to the appropriate wishbone write address as
--              data[15:8] and data[7:0], respectively.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Wishbone interface package
use work.intercon_pkg.all;

entity i2c_pu_wrapper is
  port (
    -- Wishbone interface signals
    WB_CLK        : in  std_logic;      -- master clock input
    WB_RST        : in  std_logic := '0';  -- synchronous active high reset
    WB_WBS_I      : in  wbs_i_type;
    WB_WBS_O      : out wbs_o_type;
    -- "main" i2c lines
    SCL_PAD_i     : in  std_logic;      -- i2c clock line input
    SCL_PAD_o     : out std_logic;      -- i2c clock line output
    SCL_PAD_T     : out std_logic;  -- i2c clock line output enable, active low
    SDA_PAD_i     : in  std_logic;      -- i2c data line input
    SDA_PAD_o     : out std_logic;      -- i2c data line output
    SDA_PAD_T     : out std_logic;  -- i2c data line output enable, active low
    -- "aux" i2c lines
    AUX_SCL_PAD_i : in  std_logic;      -- i2c clock line input
    AUX_SCL_PAD_o : out std_logic;      -- i2c clock line output
    AUX_SCL_PAD_T : out std_logic;  -- i2c clock line output enable, active low
    AUX_SDA_PAD_i : in  std_logic;      -- i2c data line input
    AUX_SDA_PAD_o : out std_logic;      -- i2c data line output
    AUX_SDA_PAD_T : out std_logic   -- i2c data line output enable, active low
    );
end entity i2c_pu_wrapper;

architecture structural of i2c_pu_wrapper is
  -- Main I2C bus
  constant C_T_THR_SLAVE_ADDR      : std_logic_vector(6 downto 0) := "0101000";
  constant C_A_THR01_04_SLAVE_ADDR : std_logic_vector(6 downto 0) := "1010010";
  constant C_A_THR05_08_SLAVE_ADDR : std_logic_vector(6 downto 0) := "1100000";
  constant C_A_THR09_12_SLAVE_ADDR : std_logic_vector(6 downto 0) := "1110000";
  constant C_A_THR13_16_SLAVE_ADDR : std_logic_vector(6 downto 0) := "1110010";
  constant C_V01_04_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0101100";
  constant C_V05_08_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0101101";
  constant C_V09_12_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0101110";
  constant C_V13_16_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0101111";
  constant C_B_V_SLAVE_ADDR        : std_logic_vector(6 downto 0) := "0101001";
  constant C_ADC1_2_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0011101";
  constant C_ADC3_4_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0011111";
  constant C_ADC5_6_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0110101";
  constant C_ADC7_8_SLAVE_ADDR     : std_logic_vector(6 downto 0) := "0110111";
  constant C_ADC_B_SLAVE_ADDR      : std_logic_vector(6 downto 0) := "0011110";
  constant C_EN_B_SLAVE_ADDR       : std_logic_vector(6 downto 0) := "0111000";
  -- Aux I2C bus
  constant C_EN1_4_SLAVE_ADDR      : std_logic_vector(6 downto 0) := "0111000";
  constant C_EN5_8_SLAVE_ADDR      : std_logic_vector(6 downto 0) := "0111001";

  constant C_PRER_ADDR    : std_logic_vector(7 downto 0) := x"00";
  constant C_CTR_ADDR     : std_logic_vector(7 downto 0) := x"01";
  constant C_TXR_RXR_ADDR : std_logic_vector(7 downto 0) := x"02";
  constant C_CR_SR_ADDR   : std_logic_vector(7 downto 0) := x"03";

  signal sMainI2cWbs_i : wbs_i_type;
  signal sMainI2cWbs_o : wbs_o_type;
  signal sAuxI2cWbs_i  : wbs_i_type;
  signal sAuxI2cWbs_o  : wbs_o_type;

  signal sI2cWbs_i : wbs_i_type;
  signal sI2cWbs_o : wbs_o_type;

  signal wbs_ss_main : std_logic;
  signal wbs_ss_aux  : std_logic;

  -- registers
  signal sByte1 : std_logic_vector(7 downto 0) := x"00";
  signal sByte2 : std_logic_vector(7 downto 0) := x"00";
  signal sByte3 : std_logic_vector(7 downto 0) := x"00";

  signal bInitMain : boolean := false;
  signal bInitAux  : boolean := false;

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
    variable vState     : integer range 0 to 31        := 0;
    variable vInit      : integer range 0 to 7         := 0;
    variable bWaitACK   : boolean                      := false;
    variable bWaitSR    : boolean                      := false;
    variable vData      : std_logic_vector(7 downto 0) := x"00";
    variable vSlaveAddr : std_logic_vector(6 downto 0) := "0000000";
    variable vState1    : integer range 0 to 31        := 0;
    variable vState2    : integer range 0 to 31        := 0;
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
        sByte1           <= (others => '0');
        sByte2           <= (others => '0');
        sByte3           <= (others => '0');
        vState1          := 0;
        vState2          := 0;
        bInitMain        <= false;
        bInitAux         <= false;

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

          if vInit /= 4 then                  -- initialize I2C core & enable
            bInitMain <= false;
            bInitAux  <= false;
            case vInit is
              when 0 =>
                -- main
                sI2cWbs_i.addr_i <= C_PRER_ADDR;
                sI2cWbs_i.dat_i  <= sFreqSetting;
                bInitMain        <= true;
              when 1 =>
                sI2cWbs_i.addr_i <= C_CTR_ADDR;
                sI2cWbs_i.dat_i  <= x"0080";  -- "enable" bit
                bInitMain        <= true;
              when 2 =>
                -- aux
                sI2cWbs_i.addr_i <= C_PRER_ADDR;
                sI2cWbs_i.dat_i  <= sFreqSetting;
                bInitAux         <= true;
              when 3 =>
                -- aux
                sI2cWbs_i.addr_i <= C_CTR_ADDR;
                sI2cWbs_i.dat_i  <= x"0080";  -- "enable" bit
                bInitAux         <= true;
              when others =>
                sI2cWbs_i.addr_i <= (others => '0');
                sI2cWbs_i.dat_i  <= x"0000";
            end case;
            vInit := vInit + 1;

          else
            bInitMain <= false;
            bInitAux  <= false;

            -- I2C read/write
            if (WB_WBS_I.cyc_i = '1') and (WB_WBS_I.stb_i = '1') then
              case vState is
                when 0 =>
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
--                // read transaction
                  if WB_WBS_I.we_i = '0' then
                    -- ****** read transaction: ******
                    case WB_WBS_I.addr_i is
--                    // internal register
                      when x"00" =>
                        WB_WBS_O.dat_o <= x"00" & sByte1;
                        WB_WBS_O.ack_o  <= '1';    -- raise ACK
                        bWaitACK        := false;  -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;     -- goto IDLE state
---                    // read 2 bytes
                      when x"10" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC1_2_SLAVE_ADDR & '1';  -- read
                        vState1         := 12;
--                    // read 2 bytes
                      when x"11" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC3_4_SLAVE_ADDR & '1';  -- read
                        vState1         := 12;
--                    // read 2 bytes
                      when x"12" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC5_6_SLAVE_ADDR & '1';  -- read
                        vState1         := 12;
--                    // read 2 bytes
                      when x"13" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC7_8_SLAVE_ADDR & '1';  -- read
                        vState1         := 12;
--                    // read 2 bytes
                      when x"14" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC_B_SLAVE_ADDR & '1';  -- read
                        vState1         := 12;
--                    // read 2 bytes
                      when x"15" =>
                        sI2cWbs_i.dat_i <= x"00" & C_T_THR_SLAVE_ADDR & '1';  -- read
                        vState1         := 12;
--                    // read 1 byte
                      when x"16" =>
                        sI2cWbs_i.dat_i <= x"00" & C_EN_B_SLAVE_ADDR & '1';  -- read
                        vState1         := 15;
--                    // AUX bus: read 1 byte
                      when x"20" =>
                        sI2cWbs_i.dat_i <= x"00" & C_EN1_4_SLAVE_ADDR & '1';  -- read
                        vState1         := 15;
--                    // AUX bus: read 1 byte
                      when x"21" =>
                        sI2cWbs_i.dat_i <= x"00" & C_EN5_8_SLAVE_ADDR & '1';  -- read
                        vState1         := 15;

--                    // not a valid address
                      when others =>
                        WB_WBS_O.ack_o  <= '1';    -- raise ACK
                        bWaitACK        := false;  -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;     -- goto IDLE state
                    end case;

--                // ****** write transactions: ******
                  else
                    sByte2 <= WB_WBS_I.dat_i(15 downto 8);
                    sByte3 <= WB_WBS_I.dat_i(7 downto 0);
                    case WB_WBS_I.addr_i is
--                    // write internal registers bytes 1 and 2
                      when x"00" =>
                        sByte1          <= WB_WBS_I.dat_i(7 downto 0);
                        WB_WBS_O.ack_o  <= '1';    -- raise ACK
                        bWaitACK        := false;  -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;     -- goto IDLE state
--                    // write 3 bytes
                      when x"01" =>
                        sI2cWbs_i.dat_i <= x"00" & C_T_THR_SLAVE_ADDR & '0';  -- write
                        vState1         := 2;
                        vState2         := 5;
--                    // write 3 bytes
                      when x"02" =>
                        sI2cWbs_i.dat_i <= x"00" & C_A_THR01_04_SLAVE_ADDR & '0';  -- write
                        vState1         := 2;
                        vState2         := 5;
--                    // write 3 bytes
                      when x"03" =>
                        sI2cWbs_i.dat_i <= x"00" & C_A_THR05_08_SLAVE_ADDR & '0';  -- write
                        vState1         := 2;
                        vState2         := 5;
--                    // write 3 bytes
                      when x"04" =>
                        sI2cWbs_i.dat_i <= x"00" & C_A_THR09_12_SLAVE_ADDR & '0';  -- write
                        vState1         := 2;
                        vState2         := 5;
--                    // write 3 bytes
                      when x"05" =>
                        sI2cWbs_i.dat_i <= x"00" & C_A_THR13_16_SLAVE_ADDR & '0';  -- write
                        vState1         := 2;
                        vState2         := 5;
--                    // write 2 bytes
                      when x"06" =>
                        sI2cWbs_i.dat_i <= x"00" & C_V01_04_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"07" =>
                        sI2cWbs_i.dat_i <= x"00" & C_V05_08_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"08" =>
                        sI2cWbs_i.dat_i <= x"00" & C_V09_12_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"09" =>
                        sI2cWbs_i.dat_i <= x"00" & C_V13_16_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"0a" =>
                        sI2cWbs_i.dat_i <= x"00" & C_B_V_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"0b" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC1_2_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"0c" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC3_4_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"0d" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC5_6_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"0e" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC7_8_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"0f" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC_B_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 1 byte
                      when x"10" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC1_2_SLAVE_ADDR & '0';  -- write
                        vState1         := 8;
                        vState2         := 8;
--                    // write 1 byte
                      when x"11" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC3_4_SLAVE_ADDR & '0';  -- write
                        vState1         := 8;
                        vState2         := 8;
--                    // write 1 byte
                      when x"12" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC5_6_SLAVE_ADDR & '0';  -- write
                        vState1         := 2;
                        vState2         := 8;
--                    // write 1 byte
                      when x"13" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC7_8_SLAVE_ADDR & '0';  -- write
                        vState1         := 8;
                        vState2         := 8;
--                    // write 1 byte
                      when x"14" =>
                        sI2cWbs_i.dat_i <= x"00" & C_ADC_B_SLAVE_ADDR & '0';  -- write
                        vState1         := 8;
                        vState2         := 8;
--                    // write 2 bytes
                      when x"15" =>
                        sI2cWbs_i.dat_i <= x"00" & C_T_THR_SLAVE_ADDR & '0';  -- write
                        vState1         := 5;
                        vState2         := 8;
--                    // write 1 byte
                      when x"16" =>
                        sI2cWbs_i.dat_i <= x"00" & C_EN_B_SLAVE_ADDR & '0';  -- write
                        vState1         := 8;
                        vState2         := 8;
--                    // AUX bus, write 1 byte
                      when x"20" =>
                        sI2cWbs_i.dat_i <= x"00" & C_EN1_4_SLAVE_ADDR & '0';  -- write
                        vState1         := 8;
                        vState2         := 8;
--                    // AUX bus, write 1 byte
                      when x"21" =>
                        sI2cWbs_i.dat_i <= x"00" & C_EN5_8_SLAVE_ADDR & '0';  -- write
                        vState1         := 8;
                        vState2         := 8;

--                    // not a valid address
                      when others =>
                        WB_WBS_O.ack_o  <= '1';    -- raise ACK
                        bWaitACK        := false;  -- override defaults
                        sI2cWbs_i.stb_i <= '0';
                        sI2cWbs_i.cyc_i <= '0';
                        sI2cWbs_i.we_i  <= '0';
                        vState          := 31;     -- goto IDLE state
                    end case;
                  end if;

--              // write slave address
                when 1 =>               -- write WR and STA bits to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0090";
                when 2 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                  -- vState1 =  2: 1 byte to write
                  --         = 12: 2 bytes to read
                  --         = 15: 1 byte to read
                  vState           := vState1;

--              // write 1st Byte
                when 3 =>               -- write I2C first byte
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.dat_i  <= x"00" & sByte1;
                when 4 =>               -- write WR bit to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0010";
                when 5 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                  -- vState2 =  5: 3 bytes to write
                  --         =  8: 2 bytes to write
                  --         = 12: 2 bytes to read
                  vState           := vState2;

--              // 2nd Byte
                when 6 =>               -- write I2C second byte
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.dat_i  <= x"00" & sByte2;
                when 7 =>               -- write WR bit to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0010";
                when 8 =>               -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;

--              // 3rd Byte
                when 9 =>               -- write I2C third byte
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.dat_i  <= x"00" & sByte3;
                when 10 =>              -- WRITE: WR & STO bits to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0050";
                when 11 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;


--              // Finish WRITE
                when 12 =>                 -- raise ACK & finish
                  WB_WBS_O.ack_o  <= '1';
                  WB_WBS_O.dat_o  <= WB_WBS_I.dat_i;
                  sI2cWbs_i.stb_i <= '0';  -- override defaults
                  sI2cWbs_i.cyc_i <= '0';
                  sI2cWbs_i.we_i  <= '0';
                  bWaitACK        := false;
                  vState          := 31;   -- goto IDLE state


--              // Read byte 1 from I2C
                when 13 =>              -- write RD bit to CR
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0020";
                when 14 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 15 =>              -- read data from RXR
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.we_i   <= '0';

--              // Read byte 2 from I2C
                when 16 =>              -- write RD, STO & ACK bits to CR
                  if sI2cWbs_i.addr_i = C_CR_SR_ADDR then
                    WB_WBS_O.dat_o(15 downto 8) <= x"00";
                  else
                    WB_WBS_O.dat_o(15 downto 8) <= vData;
                  end if;
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i  <= x"0068";
                when 17 =>              -- wait for SR to negate TIP and RxACK
                  sI2cWbs_i.addr_i <= C_CR_SR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                  bWaitSR          := true;
                when 18 =>              -- read data from RXR
                  sI2cWbs_i.addr_i <= C_TXR_RXR_ADDR;
                  sI2cWbs_i.we_i   <= '0';
                when 19 =>  -- store data and write 0 to CR to clear ACK bit
                  WB_WBS_O.dat_o(7 downto 0) <= vData;
                  sI2cWbs_i.addr_i           <= C_CR_SR_ADDR;
                  sI2cWbs_i.dat_i            <= x"0000";

--              // Finish READ
                when 20 =>                 -- raise ACK & finish
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

  -- determine correct wishbone slave
  p_slave_select : process (WB_WBS_I.addr_i, bInitMain, bInitAux) is
  begin
    if bInitMain then
      -- initializing main I2C, select main wishbone
      wbs_ss_main <= '1';
    elsif not bInitAux then
      -- address 0x00 - 0x1f goes to main I2C
      case WB_WBS_I.addr_i(7 downto 5) is
        when "000"  => wbs_ss_main <= '1';
        when others => wbs_ss_main <= '0';
      end case;
    else
      wbs_ss_main <= '0';
    end if;

    if bInitAux then
      -- initializing aux I2C, select aux wishbone
      wbs_ss_aux <= '1';
    elsif not bInitMain then
      -- 0x20 - 0x2f goes to aux I2C
      case WB_WBS_I.addr_i(7 downto 5) is
        when "001"  => wbs_ss_aux <= '1';
        when others => wbs_ss_aux <= '0';
      end case;
    else
      wbs_ss_aux <= '0';
    end if;
  end process p_slave_select;

  -- wishbone master to slave mapping
  sMainI2cWbs_i.cyc_i  <= sI2cWbs_i.cyc_i and wbs_ss_main;
  sMainI2cWbs_i.stb_i  <= sI2cWbs_i.stb_i;
  sMainI2cWbs_i.we_i   <= sI2cWbs_i.we_i;
  sMainI2cWbs_i.addr_i <= sI2cWbs_i.addr_i;
  sMainI2cWbs_i.dat_i  <= sI2cWbs_i.dat_i;

  sAuxI2cWbs_i.cyc_i  <= sI2cWbs_i.cyc_i and wbs_ss_aux;
  sAuxI2cWbs_i.stb_i  <= sI2cWbs_i.stb_i;
  sAuxI2cWbs_i.we_i   <= sI2cWbs_i.we_i;
  sAuxI2cWbs_i.addr_i <= sI2cWbs_i.addr_i;
  sAuxI2cWbs_i.dat_i  <= sI2cWbs_i.dat_i;

  -- wishbone slave to master mapping
  sI2cWbs_o.ack_o <= '0' when ((sMainI2cWbs_o.ack_o = '0') and
                               (sAuxI2cWbs_o.ack_o = '0'))
                     else '1';

  sI2cWbs_o.dat_o <= sMainI2cWbs_o.dat_o when wbs_ss_main = '1' else
                     sAuxI2cWbs_o.dat_o when wbs_ss_aux = '1' else
                     (others => '0');


  -- attach I2C master core for PU "main" bus
  INST_pu_i2c_master : entity work.i2c_master_top
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => sMainI2cWbs_i,
      WB_WBS_O  => sMainI2cWbs_o,
      ARST      => '0',
      WB_INTA_o => open,
      SCL_PAD_i => SCL_PAD_i,
      SCL_PAD_o => SCL_PAD_o,
      SCL_PAD_T => SCL_PAD_T,
      SDA_PAD_i => SDA_PAD_i,
      SDA_PAD_o => SDA_PAD_o,
      SDA_PAD_T => SDA_PAD_T
      );


  -- attach I2C master core for PU "AUX" bus
  INST_pu_aux_i2c_master : entity work.i2c_master_top
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => sAuxI2cWbs_i,
      WB_WBS_O  => sAuxI2cWbs_o,
      ARST      => '0',
      WB_INTA_o => open,
      SCL_PAD_i => AUX_SCL_PAD_i,
      SCL_PAD_o => AUX_SCL_PAD_o,
      SCL_PAD_T => AUX_SCL_PAD_T,
      SDA_PAD_i => AUX_SDA_PAD_i,
      SDA_PAD_o => AUX_SDA_PAD_o,
      SDA_PAD_T => AUX_SDA_PAD_T
      );


end architecture structural;
