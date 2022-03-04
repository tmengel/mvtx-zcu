-------------------------------------------------------------------------------
-- Title      : Cypress FX-3 Logic
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : usb_if.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Author     : Krzysztof Marek Sielewicz
-- Company    : Warsaw University of Technology / CERN
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2015-09-02
-- Last update: 2018-12-18
-- Platform   : Vivado 2016.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Top level entity of the FX3 controller
--
-- 2016-03-04   ML MB           Passed WB_rst to usb_if_wrpr
-- 2016-06-09   ML MB           Changed Flag D from clt8 to clt9! (clkt8 used
--                              as gpio(0))
-- 2015-07-04  ML               Added fifo monitoring signals
-- 2016-07-05  ML               Added forward of wishbone error signal
-- 2016-07-11  ML               Parametrized usb_if_wrapper to use generic
-- 2016-07-21  ML               git rebase
-- 2016-08-02  ML MB            Merge with alpide_dev last version
-- 2016-10-17  ML               Added generic for deciding if to instatiate the
--                              ILAs
-- 2016-11-02  ML               Added selection for DPmux
-- 2016-11-30  ML               Added empty counters to DP23 fifos
-- 2016-12-02  ML               Switched from ILA core to debug nets
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;

entity usb_if is
  generic (
    INITIAL_RESET_DELAY        : natural := 10 * 100e3;  -- 10ms @ 100MHz
    ENABLE_DEBUG               : string  := "FALSE";
    DP_SELECT_WIDTH            : integer := 3;
    MISMATCH_EN                : integer := 1;
    MISMATCH_REGISTERED        : integer := 1;
    G_SEE_MITIGATION_TECHNIQUE : integer := 0);
  port (
    -- Wishbone slave interface
    WB_CLK               : in  std_logic;
    WB_RST               : in  std_logic;
    WB_WBS_I             : in  wbs_i_type;
    WB_WBS_O             : out wbs_o_type;
    -- USB interface signals
    CLK                  : in  std_logic;  -- 100 MHz
    RST                  : in  std_logic;
    FX3_UART_RX          : out std_logic;
    FX3_UART_TX          : in  std_logic;
    FX3_GPIF_II_DQ_i     : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    FX3_GPIF_II_DQ_o     : out std_logic_vector(GPIF_WIDTH-1 downto 0);
    FX3_GPIF_II_DQ_T     : out std_logic;
    FX3_GPIF_II_CTL_i    : in  std_logic_vector(GPIF_CTL_WIDTH-1 downto 0);
    FX3_GPIF_II_CTL_o    : out std_logic_vector(GPIF_CTL_WIDTH-1 downto 0);
    FX3_GPIF_II_CTL_T    : out std_logic_vector(GPIF_CTL_WIDTH-1 downto 0);
    FX3_GPIF_II_PCLK     : out std_logic;
    FX3_GPIF_II_INT_n    : out std_logic;
    FX3_GPIF_II_RESET_n  : out std_logic;
    -- DATA PORT 0 INTERFACE
    DP0_RDCLK_I          : in  std_logic;
    DP0_DT_O             : out std_logic_vector(GPIF_WIDTH-1 downto 0);
    DP0_EPTY_O           : out std_logic;
    DP0_RD_I             : in  std_logic;
    -- DATA PORT 1 INTERFACE
    DP1_WRCLK_I          : in  std_logic;
    DP1_DT_I             : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    DP1_WR_I             : in  std_logic;
    DP1_FULL_O           : out std_logic;
    -- DATA PORT 2 INTERFACE
    CLK_DP2_WR_I         : in  std_logic;
    DPO2_DTI_I           : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    DPO2_FULL_O          : out std_logic;
    DPO2_ALMST_FULL_O    : out std_logic;
    DPO2_WR_I            : in  std_logic;
    DPO2_EPTY_O          : out std_logic;
    DPO2_DONE_O          : out std_logic;
    DPO2_RST_WRCLK_I     : in  std_logic;
    DPO2_PRODUCER_SELECT : out std_logic_vector(DP_SELECT_WIDTH-1 downto 0);
    -- DATA PORT 3 INTERFACE
    CLK_DP3_WR_I         : in  std_logic;
    DPO3_DTI_I           : in  std_logic_vector(GPIF_WIDTH-1 downto 0);
    DPO3_FULL_O          : out std_logic;
    DPO3_ALMST_FULL_O    : out std_logic;
    DPO3_WR_I            : in  std_logic;
    DPO3_EPTY_O          : out std_logic;
    DPO3_DONE_O          : out std_logic;
    DPO3_RST_WRCLK_I     : in  std_logic;
    DPO3_PRODUCER_SELECT : out std_logic_vector(DP_SELECT_WIDTH-1 downto 0)
    );
  attribute mark_debug                     : string;
  attribute mark_debug of FX3_GPIF_II_DQ_i : signal is ENABLE_DEBUG;
end entity usb_if;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture usb_if_arch of usb_if is

  -- usb_if_wrpr component declaration
  component usb_if_wrpr
    generic(
      GpifCtlWidth               : integer;
      GpifWidth                  : integer;
      WbDataWidth                : integer;
      G_SEE_MITIGATION_TECHNIQUE : integer;
      MISMATCH_EN                : integer;
      MISMATCH_REGISTERED        : integer
      );
    port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      wb_clk    : in  std_logic;
      wb_rst    : in  std_logic;
      FLAGA_i   : in  std_logic;
      FLAGB_i   : in  std_logic;
      FLAGC_i   : in  std_logic;
      FLAGD_i   : in  std_logic;
      SLADDR_o  : out std_logic_vector(1 downto 0);
      SLOEn_o   : out std_logic;
      SLCSn_o   : out std_logic;
      SLRDn_o   : out std_logic;
      SLWRn_o   : out std_logic;
      PKTENDn_o : out std_logic;
      DQ_i      : in  std_logic_vector(GpifWidth-1 downto 0);
      DQ_o      : out std_logic_vector(GpifWidth-1 downto 0);

      WB_LATCH_WORDS_COUNT_DP2   : in  std_logic;
      WB_LATCH_RDWORDS_COUNT_DP2 : in  std_logic;
      WB_LATCH_OVFL_COUNT_DP2    : in  std_logic;
      WB_LATCH_FULL_COUNT_DP2    : in  std_logic;
      WB_RST_WORDS_COUNT_DP2     : in  std_logic;
      WB_RST_RDWORDS_COUNT_DP2   : in  std_logic;
      WB_RST_OVFL_COUNT_DP2      : in  std_logic;
      WB_RST_FULL_COUNT_DP2      : in  std_logic;
      WB_WORDS_COUNT_LSB_DP2     : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_WORDS_COUNT_MSB_DP2     : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_RDWORDS_COUNT_LSB_DP2   : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_RDWORDS_COUNT_MSB_DP2   : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_OVFL_COUNT_DP2          : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_FULL_COUNT_DP2          : out std_logic_vector(WbDataWidth-1 downto 0);

      WB_LATCH_WORDS_COUNT_DP3   : in  std_logic;
      WB_LATCH_RDWORDS_COUNT_DP3 : in  std_logic;
      WB_LATCH_OVFL_COUNT_DP3    : in  std_logic;
      WB_LATCH_FULL_COUNT_DP3    : in  std_logic;
      WB_RST_WORDS_COUNT_DP3     : in  std_logic;
      WB_RST_RDWORDS_COUNT_DP3   : in  std_logic;
      WB_RST_OVFL_COUNT_DP3      : in  std_logic;
      WB_RST_FULL_COUNT_DP3      : in  std_logic;
      WB_WORDS_COUNT_LSB_DP3     : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_WORDS_COUNT_MSB_DP3     : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_RDWORDS_COUNT_LSB_DP3   : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_RDWORDS_COUNT_MSB_DP3   : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_OVFL_COUNT_DP3          : out std_logic_vector(WbDataWidth-1 downto 0);
      WB_FULL_COUNT_DP3          : out std_logic_vector(WbDataWidth-1 downto 0);

      dp0_rdclk_i : in  std_logic;
      dp0_dt_o    : out std_logic_vector(GpifWidth-1 downto 0);
      dp0_epty_o  : out std_logic;
      dp0_rd_i    : in  std_logic;

      dp1_wrclk_i : in  std_logic;
      dp1_dt_i    : in  std_logic_vector(GpifWidth-1 downto 0);
      dp1_wr_i    : in  std_logic;
      dp1_full_o  : out std_logic;

      clk_dp2_wr_i      : in  std_logic;
      dpo2_dti_i        : in  std_logic_vector(GpifWidth-1 downto 0);
      dpo2_full_o       : out std_logic;
      dpo2_almst_full_o : out std_logic;
      dpo2_wr_i         : in  std_logic;
      dpo2_epty_o       : out std_logic;
      dpo2_done_o       : out std_logic;
      dpo2_rst_wrclk_i  : in  std_logic;

      clk_dp3_wr_i      : in  std_logic;
      dpo3_dti_i        : in  std_logic_vector(GpifWidth-1 downto 0);
      dpo3_full_o       : out std_logic;
      dpo3_almst_full_o : out std_logic;
      dpo3_wr_i         : in  std_logic;
      dpo3_epty_o       : out std_logic;
      dpo3_done_o       : out std_logic;
      dpo3_rst_wrclk_i  : in  std_logic
      );
  end component;

  signal slcs_n   : std_logic;          -- output chip select
  signal faddr    : std_logic_vector(1 downto 0);  -- output endpoint address
  signal slrd_n   : std_logic;          -- output read select
  signal sloe_n   : std_logic;          -- output output enable select
  signal slwr_n   : std_logic;          -- output write select
  signal flaga    : std_logic;          -- in
  signal flagb    : std_logic;          -- in
  signal flagc    : std_logic;          -- in
  signal flagd    : std_logic;          -- in
  signal pktend_n : std_logic;          -- output packet end
  signal gpio     : std_logic_vector(1 downto 0);

  -- WS related signals
  signal s_dp23_cmd_bit_dp2_rst_cntr_words     : std_logic;
  signal s_dp23_cmd_bit_dp2_rst_cntr_rdwords   : std_logic;
  signal s_dp23_cmd_bit_dp2_rst_cntr_ovfl      : std_logic;
  signal s_dp23_cmd_bit_dp2_rst_cntr_full      : std_logic;
  signal s_dp23_cmd_bit_dp2_latch_cntr_words   : std_logic;
  signal s_dp23_cmd_bit_dp2_latch_cntr_rdwords : std_logic;
  signal s_dp23_cmd_bit_dp2_latch_cntr_ovfl    : std_logic;
  signal s_dp23_cmd_bit_dp2_latch_cntr_full    : std_logic;
  signal s_dp23_cmd_bit_dp3_rst_cntr_words     : std_logic;
  signal s_dp23_cmd_bit_dp3_rst_cntr_rdwords   : std_logic;
  signal s_dp23_cmd_bit_dp3_rst_cntr_ovfl      : std_logic;
  signal s_dp23_cmd_bit_dp3_rst_cntr_full      : std_logic;
  signal s_dp23_cmd_bit_dp3_latch_cntr_words   : std_logic;
  signal s_dp23_cmd_bit_dp3_latch_cntr_rdwords : std_logic;
  signal s_dp23_cmd_bit_dp3_latch_cntr_ovfl    : std_logic;
  signal s_dp23_cmd_bit_dp3_latch_cntr_full    : std_logic;

  signal s_dp23_sts_dp2_wrds_msb   : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp2_wrds_lsb   : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp2_rdwrds_msb : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp2_rdwrds_lsb : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp2_ovfl       : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp2_full       : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp3_wrds_msb   : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp3_wrds_lsb   : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp3_rdwrds_msb : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp3_rdwrds_lsb : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp3_ovfl       : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  signal s_dp23_sts_dp3_full       : std_logic_vector(WB_DATA_WIDTH-1 downto 0);

  -- probe related signals
  signal gpif_ii_dq_o : std_logic_vector(GPIF_WIDTH-1 downto 0);

  signal wbm_ack_i, wbm_err_i : std_logic;

  attribute mark_debug of gpif_ii_dq_o     : signal is ENABLE_DEBUG;
  attribute mark_debug of faddr            : signal is ENABLE_DEBUG;
  attribute mark_debug of pktend_n         : signal is ENABLE_DEBUG;
  attribute mark_debug of flagd            : signal is ENABLE_DEBUG;
  attribute mark_debug of flagc            : signal is ENABLE_DEBUG;
  attribute mark_debug of flagb            : signal is ENABLE_DEBUG;
  attribute mark_debug of flaga            : signal is ENABLE_DEBUG;
  attribute mark_debug of sloe_n           : signal is ENABLE_DEBUG;
  attribute mark_debug of slrd_n           : signal is ENABLE_DEBUG;
  attribute mark_debug of slwr_n           : signal is ENABLE_DEBUG;
  attribute mark_debug of slcs_n           : signal is ENABLE_DEBUG;

begin  -- architecture

  -- assign CTL port directions
  FX3_GPIF_II_CTL_T(0)  <= '0';         -- output
  FX3_GPIF_II_CTL_T(1)  <= '0';         -- output
  FX3_GPIF_II_CTL_T(2)  <= '0';         -- output
  FX3_GPIF_II_CTL_T(3)  <= '0';         -- output
  FX3_GPIF_II_CTL_T(4)  <= '1';         -- input
  FX3_GPIF_II_CTL_T(5)  <= '1';         -- input
  FX3_GPIF_II_CTL_T(6)  <= '1';         -- input
  FX3_GPIF_II_CTL_T(7)  <= '0';         -- output
  FX3_GPIF_II_CTL_T(8)  <= '1';         -- input
  FX3_GPIF_II_CTL_T(9)  <= '1';         -- input
  FX3_GPIF_II_CTL_T(10) <= '1';         -- input
  FX3_GPIF_II_CTL_T(11) <= '0';         -- output
  FX3_GPIF_II_CTL_T(12) <= '0';         -- output

  FX3_GPIF_II_DQ_T <= not sloe_n;

  -- outputs
  FX3_GPIF_II_CTL_o(12)          <= faddr(0);  --gpio 29
  FX3_GPIF_II_CTL_o(11)          <= faddr(1);  --gpio 28
  FX3_GPIF_II_CTL_o(10 downto 9) <= gpio;      --gpio 27, 26
  FX3_GPIF_II_CTL_o(8)           <= '0';       --gpio 25
  FX3_GPIF_II_CTL_o(7)           <= pktend_n;  --gpio 24
  FX3_GPIF_II_CTL_o(6)           <= '0';       --gpio 23
  FX3_GPIF_II_CTL_o(5)           <= '0';       --gpio 22
  FX3_GPIF_II_CTL_o(4)           <= '0';       --gpio 21
  FX3_GPIF_II_CTL_o(3)           <= slrd_n;    --gpio 20
  FX3_GPIF_II_CTL_o(2)           <= sloe_n;    --gpio 19
  FX3_GPIF_II_CTL_o(1)           <= slwr_n;    --gpio 18
  FX3_GPIF_II_CTL_o(0)           <= slcs_n;    --gpio 17

  -- inputs
  flagd <= FX3_GPIF_II_CTL_i(8);
  flagc <= FX3_GPIF_II_CTL_i(6);
  flagb <= FX3_GPIF_II_CTL_i(5);
  flaga <= FX3_GPIF_II_CTL_i(4);

  FX3_UART_RX       <= FX3_UART_TX;     -- currently a loopback here
  FX3_GPIF_II_INT_n <= '1';
  gpio              <= (others => '0');

  -- reset for INITIAL_RESET_DELAY
  p_FX3_reset : process (CLK, RST) is
    variable timer : integer range 0 to INITIAL_RESET_DELAY;
  begin
    if RST = '1' then
      FX3_GPIF_II_RESET_n <= '0';
      timer               := 0;
    elsif rising_edge(CLK) then
      if timer >= INITIAL_RESET_DELAY-1 then
        FX3_GPIF_II_RESET_n <= '1';
      else
        timer               := timer + 1;
        FX3_GPIF_II_RESET_n <= '0';
      end if;
    end if;
  end process p_FX3_reset;


  -- PCLK as output of a ODDR
  ODDR_inst : ODDRE1
    port map (
      Q  => FX3_GPIF_II_PCLK,
      C  => CLK,
      D1 => '0',
      D2 => '1',
      SR => RST
      );

  -- FX3 controller
  usb_if_wrpr_inst : usb_if_wrpr
    generic map (
      GpifCtlWidth               => GPIF_CTL_WIDTH,
      GpifWidth                  => GPIF_WIDTH,
      WbDataWidth                => WB_DATA_WIDTH,
      G_SEE_MITIGATION_TECHNIQUE => G_SEE_MITIGATION_TECHNIQUE,
      MISMATCH_EN                => MISMATCH_EN,
      MISMATCH_REGISTERED        => MISMATCH_REGISTERED
      )
    port map (
      clk_i  => CLK,
      rst_i  => RST,
      wb_clk => WB_CLK,
      wb_rst => WB_RST,

      FLAGA_i   => flaga,
      FLAGB_i   => flagb,
      FLAGC_i   => flagc,
      FLAGD_i   => flagd,
      SLADDR_o  => faddr,
      SLOEn_o   => sloe_n,
      SLCSn_o   => slcs_n,
      SLRDn_o   => slrd_n,
      SLWRn_o   => slwr_n,
      PKTENDn_o => pktend_n,
      DQ_i      => FX3_GPIF_II_DQ_i,
      DQ_o      => gpif_ii_dq_o,

      WB_RST_WORDS_COUNT_DP2     => s_dp23_cmd_bit_dp2_rst_cntr_words,
      WB_RST_RDWORDS_COUNT_DP2   => s_dp23_cmd_bit_dp2_rst_cntr_rdwords,
      WB_RST_OVFL_COUNT_DP2      => s_dp23_cmd_bit_dp2_rst_cntr_ovfl,
      WB_RST_FULL_COUNT_DP2      => s_dp23_cmd_bit_dp2_rst_cntr_full,
      WB_LATCH_WORDS_COUNT_DP2   => s_dp23_cmd_bit_dp2_latch_cntr_words,
      WB_LATCH_RDWORDS_COUNT_DP2 => s_dp23_cmd_bit_dp2_latch_cntr_rdwords,
      WB_LATCH_OVFL_COUNT_DP2    => s_dp23_cmd_bit_dp2_latch_cntr_ovfl,
      WB_LATCH_FULL_COUNT_DP2    => s_dp23_cmd_bit_dp2_latch_cntr_full,
      WB_RST_WORDS_COUNT_DP3     => s_dp23_cmd_bit_dp3_rst_cntr_words,
      WB_RST_RDWORDS_COUNT_DP3   => s_dp23_cmd_bit_dp3_rst_cntr_rdwords,
      WB_RST_OVFL_COUNT_DP3      => s_dp23_cmd_bit_dp3_rst_cntr_ovfl,
      WB_RST_FULL_COUNT_DP3      => s_dp23_cmd_bit_dp3_rst_cntr_full,
      WB_LATCH_WORDS_COUNT_DP3   => s_dp23_cmd_bit_dp3_latch_cntr_words,
      WB_LATCH_RDWORDS_COUNT_DP3 => s_dp23_cmd_bit_dp3_latch_cntr_rdwords,
      WB_LATCH_OVFL_COUNT_DP3    => s_dp23_cmd_bit_dp3_latch_cntr_ovfl,
      WB_LATCH_FULL_COUNT_DP3    => s_dp23_cmd_bit_dp3_latch_cntr_full,

      WB_WORDS_COUNT_MSB_DP2   => s_dp23_sts_dp2_wrds_msb,
      WB_WORDS_COUNT_LSB_DP2   => s_dp23_sts_dp2_wrds_lsb,
      WB_RDWORDS_COUNT_MSB_DP2 => s_dp23_sts_dp2_rdwrds_msb,
      WB_RDWORDS_COUNT_LSB_DP2 => s_dp23_sts_dp2_rdwrds_lsb,
      WB_OVFL_COUNT_DP2        => s_dp23_sts_dp2_ovfl,
      WB_FULL_COUNT_DP2        => s_dp23_sts_dp2_full,
      WB_WORDS_COUNT_MSB_DP3   => s_dp23_sts_dp3_wrds_msb,
      WB_WORDS_COUNT_LSB_DP3   => s_dp23_sts_dp3_wrds_lsb,
      WB_RDWORDS_COUNT_MSB_DP3 => s_dp23_sts_dp3_rdwrds_msb,
      WB_RDWORDS_COUNT_LSB_DP3 => s_dp23_sts_dp3_rdwrds_lsb,
      WB_OVFL_COUNT_DP3        => s_dp23_sts_dp3_ovfl,
      WB_FULL_COUNT_DP3        => s_dp23_sts_dp3_full,

      dp0_rdclk_i => DP0_RDCLK_I,
      dp0_dt_o    => DP0_DT_O,
      dp0_epty_o  => DP0_EPTY_O,
      dp0_rd_i    => DP0_RD_I,

      dp1_wrclk_i => DP1_WRCLK_I,
      dp1_dt_i    => DP1_DT_I,
      dp1_full_o  => DP1_FULL_O,
      dp1_wr_i    => DP1_WR_I,

      clk_dp2_wr_i      => CLK_DP2_WR_I,
      dpo2_dti_i        => DPO2_DTI_I,
      dpo2_full_o       => DPO2_FULL_O,
      dpo2_almst_full_o => DPO2_ALMST_FULL_O,
      dpo2_wr_i         => DPO2_WR_I,
      dpo2_epty_o       => DPO2_EPTY_O,
      dpo2_done_o       => DPO2_DONE_O,
      dpo2_rst_wrclk_i  => DPO2_RST_WRCLK_I,

      clk_dp3_wr_i      => CLK_DP3_WR_I,
      dpo3_dti_i        => DPO3_DTI_I,
      dpo3_full_o       => DPO3_FULL_O,
      dpo3_almst_full_o => DPO3_ALMST_FULL_O,
      dpo3_wr_i         => DPO3_WR_I,
      dpo3_epty_o       => DPO3_EPTY_O,
      dpo3_done_o       => DPO3_DONE_O,
      dpo3_rst_wrclk_i  => DPO3_RST_WRCLK_I
      );

  FX3_GPIF_II_DQ_o <= gpif_ii_dq_o;

  INST_ws_usb_if : entity work.ws_usb_if
    generic map (
      DP_SELECT_WIDTH => DP_SELECT_WIDTH)
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => WB_WBS_I,
      WB_WBS_O => WB_WBS_O,

      DP23_STS_DP2_WRDS_MSB   => s_dp23_sts_dp2_wrds_msb,
      DP23_STS_DP2_WRDS_LSB   => s_dp23_sts_dp2_wrds_lsb,
      DP23_STS_DP2_RDWRDS_MSB => s_dp23_sts_dp2_rdwrds_msb,
      DP23_STS_DP2_RDWRDS_LSB => s_dp23_sts_dp2_rdwrds_lsb,
      DP23_STS_DP2_OVFL       => s_dp23_sts_dp2_ovfl,
      DP23_STS_DP2_FULL       => s_dp23_sts_dp2_full,

      DP23_STS_DP3_WRDS_MSB   => s_dp23_sts_dp3_wrds_msb,
      DP23_STS_DP3_WRDS_LSB   => s_dp23_sts_dp3_wrds_lsb,
      DP23_STS_DP3_RDWRDS_MSB => s_dp23_sts_dp3_rdwrds_msb,
      DP23_STS_DP3_RDWRDS_LSB => s_dp23_sts_dp3_rdwrds_lsb,
      DP23_STS_DP3_OVFL       => s_dp23_sts_dp3_ovfl,
      DP23_STS_DP3_FULL       => s_dp23_sts_dp3_full,

      DP23_CMD_bit_dp2_rst_cntr_words   => s_dp23_cmd_bit_dp2_rst_cntr_words,
      DP23_CMD_bit_dp2_rst_cntr_rdwords => s_dp23_cmd_bit_dp2_rst_cntr_rdwords,
      DP23_CMD_bit_dp2_rst_cntr_ovfl    => s_dp23_cmd_bit_dp2_rst_cntr_ovfl,
      DP23_CMD_bit_dp2_rst_cntr_full    => s_dp23_cmd_bit_dp2_rst_cntr_full,

      DP23_CMD_bit_dp2_latch_cntr_words   => s_dp23_cmd_bit_dp2_latch_cntr_words,
      DP23_CMD_bit_dp2_latch_cntr_rdwords => s_dp23_cmd_bit_dp2_latch_cntr_rdwords,
      DP23_CMD_bit_dp2_latch_cntr_ovfl    => s_dp23_cmd_bit_dp2_latch_cntr_ovfl,
      DP23_CMD_bit_dp2_latch_cntr_full    => s_dp23_cmd_bit_dp2_latch_cntr_full,

      DP23_CMD_bit_dp3_rst_cntr_words   => s_dp23_cmd_bit_dp3_rst_cntr_words,
      DP23_CMD_bit_dp3_rst_cntr_rdwords => s_dp23_cmd_bit_dp3_rst_cntr_rdwords,
      DP23_CMD_bit_dp3_rst_cntr_ovfl    => s_dp23_cmd_bit_dp3_rst_cntr_ovfl,
      DP23_CMD_bit_dp3_rst_cntr_full    => s_dp23_cmd_bit_dp3_rst_cntr_full,

      DP23_CMD_bit_dp3_latch_cntr_words   => s_dp23_cmd_bit_dp3_latch_cntr_words,
      DP23_CMD_bit_dp3_latch_cntr_rdwords => s_dp23_cmd_bit_dp3_latch_cntr_rdwords,
      DP23_CMD_bit_dp3_latch_cntr_ovfl    => s_dp23_cmd_bit_dp3_latch_cntr_ovfl,
      DP23_CMD_bit_dp3_latch_cntr_full    => s_dp23_cmd_bit_dp3_latch_cntr_full,

      DP2_CFG_PRODUCER_SELECT => DPO2_PRODUCER_SELECT,
      DP3_CFG_PRODUCER_SELECT => DPO3_PRODUCER_SELECT
      );

end architecture usb_if_arch;
