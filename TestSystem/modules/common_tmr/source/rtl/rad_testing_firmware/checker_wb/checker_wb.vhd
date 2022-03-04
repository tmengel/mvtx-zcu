-- checker_wb.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

-- Wishbone interface package
use work.intercon_package.all;

entity checker_wb is
  generic(
    constant C_TB_ARR : natural := 256;
    CNT_REG_SIZE      : natural := 16
  );
  port(
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    monitor_i : in  std_logic_vector(C_TB_ARR - 1 downto 0);
    -- Wishbone interface signals
    WB_CLK    : in  std_logic;
    WB_RST    : in  std_logic;
    WB_WBS_I  : in  wbs_i_type;
    WB_WBS_O  : out wbs_o_type
  );
end checker_wb;

architecture structural of checker_wb is

  -- warning checker and counter
  component warn_cntr
    generic(
      TB_ARR       : natural := 256;
      CNT_REG_SIZE : natural := 16
    );
    port(
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      warn_i    : in  std_logic_vector(TB_ARR - 1 downto 0);
      warnCnt_o : out std_logic_vector(TB_ARR * 16 - 1 downto 0)
    );
  end component;

  component db_buff_n
    generic(
      WIDTH : natural := 32
    );
    port(
      clk_i : in  std_logic;
      rst_i : in  std_logic;
      sig_i : in  std_logic_vector(WIDTH - 1 downto 0);
      sig_o : out std_logic_vector(WIDTH - 1 downto 0)
    );
  end component;

  signal warnCnt_s      : std_logic_vector(C_TB_ARR * 16 - 1 downto 0);
  signal warnCntSync_s  : std_logic_vector(C_TB_ARR * 16 - 1 downto 0);
  signal sValidAddr     : std_logic;
  signal iWbAddr        : integer range 0 to 255;
  signal sWbAck, sWbErr : std_logic;
  signal sWbWrite       : std_logic;

begin
  INST_WARN_CNTR : warn_cntr
    generic map(
      TB_ARR       => C_TB_ARR,
      CNT_REG_SIZE => CNT_REG_SIZE
    )
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      warn_i    => monitor_i,
      warnCnt_o => warnCnt_s
    );

  INST_DB_BUFF_N : db_buff_n
    generic map(
      WIDTH => (C_TB_ARR * 16)
    )
    port map(
      clk_i => WB_CLK,
      rst_i => WB_RST,
      sig_i => warnCnt_s,
      sig_o => warnCntSync_s
    );

  -- generate acknowledge and error signals
  genAckErr : process(WB_CLK, WB_RST) is
  begin                                 -- process genAckErr
    if rising_edge(WB_CLK) then
      if WB_RST = '1' then              -- synchronous reset (active high)
        sWbAck <= '0';
        sWbErr <= '0';
      else
        sWbAck <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and sValidAddr and (not sWbAck);
        sWbErr <= WB_WBS_I.stb_i and WB_WBS_I.cyc_i and (not sValidAddr) and (not sWbErr);
      end if;
    end if;
  end process genAckErr;

  WB_WBS_O.ack_o <= sWbAck;
  WB_WBS_O.err_o <= sWbErr;

  -- generate wishbone write signal
  sWbWrite <= sWbAck and WB_WBS_I.we_i;

  -- Wishbone Read and Address Decode (asynchronous)
  iWbAddr <= to_integer(unsigned(WB_WBS_I.addr_i));

  procRegRead : process(warnCntSync_s, iWbAddr) is
  begin
    if iWbAddr < C_TB_ARR then
      sValidAddr     <= '1';
      WB_WBS_O.dat_o <= warnCntSync_s(iWbAddr * 16 + 15 downto iWbAddr * 16);
    else
      sValidAddr     <= '0';
      WB_WBS_O.dat_o <= (others => '1');
    end if;
  end process procRegRead;
   
end structural;
