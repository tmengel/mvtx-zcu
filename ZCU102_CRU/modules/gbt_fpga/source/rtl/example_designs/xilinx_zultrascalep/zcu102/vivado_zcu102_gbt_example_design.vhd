--=================================================================================================--
--##################################   Module Information   #######################################--
--=================================================================================================--
--
-- Company:               CERN
-- Engineer:              Hampus Sandberg (hampus.sandberg@cern.ch)
--
-- Project Name:          GBT-FPGA
-- Module Name:           ZCU102 - GBT Bank example design
--
-- Language:              VHDL'93
--
-- Target Device:         ZCU102 (Xilinx Zynq UltraScale+ MPSoC)
-- Tool version:          Vivado 2020.2
--
-- Description:
--
-- Additional Comments:   Note!! Only ONE GBT Bank with ONE link can be used in this example design.
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                                                                                           !!
-- !! * The different parameters of the GBT Bank are set through:                               !!
-- !!   (Note!! These parameters are vendor specific)                                           !!
-- !!                                                                                           !!
-- !!   - The MGT control ports of the GBT Bank module (these ports are listed in the records   !!
-- !!     of the file "<vendor>_<device>_gbt_bank_package.vhd").                                !!
-- !!     (e.g. xlx_v6_gbt_bank_package.vhd)                                                    !!
-- !!                                                                                           !!
-- !!   - By modifying the content of the file "<vendor>_<device>_gbt_bank_user_setup.vhd".     !!
-- !!     (e.g. xlx_v6_gbt_bank_user_setup.vhd)                                                 !!
-- !!                                                                                           !!
-- !! * The "<vendor>_<device>_gbt_bank_user_setup.vhd" is the only file of the GBT Bank that   !!
-- !!   may be modified by the user. The rest of the files MUST be used as is.                  !!
-- !!                                                                                           !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--

--! Use Xilinx simulation library
library unisim;
use unisim.vcomponents.all;

--! Use standard library
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Custom libraries and packages
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_exampledesign_package.all;

--! @brief Entity declaration of vivado_zcu102_gbt_example_design
--! @details
--! Connects all the modules together.\n
entity vivado_zcu102_gbt_example_design is
  port(
    -- General reset
    CPU_RESET                   : in  std_logic;

    --! @name System clock
    CLK_125_P                   : in  std_logic;
    CLK_125_N                   : in  std_logic;

    -- MGT(GTX) reference clock
    -- Comment: * The MGT reference clock is provided by the onboard Si5328
    --          * The MGT reference clock frequency must be 120MHz for the latency-optimized GBT Bank.
    SFP_SI5328_OUT_C_P          : in  std_logic;
    SFP_SI5328_OUT_C_N          : in  std_logic;

    -- Serial lanes
    SFP0_TX_P                   : out std_logic;
    SFP0_TX_N                   : out std_logic;
    SFP0_RX_P                   : in  std_logic;
    SFP0_RX_N                   : in  std_logic;

    -- SFP control
    SFP0_TX_DISABLE_N             : out std_logic);
end vivado_zcu102_gbt_example_design;

--! Structural implementation of vivado_zcu102_gbt_example_design
architecture structural of vivado_zcu102_gbt_example_design is
  -- ***************************************************************************
  --! @name Attributes
  -- ***************************************************************************
  attribute mark_debug          : string;
  attribute dont_touch          : string;

  -- ***************************************************************************
  --! @name Internal signals
  -- ***************************************************************************
  --! @name General reset
  signal reset_from_genRst      : std_logic;
  --attribute mark_debug of reset_from_genRst : signal is "true";
  
  ------------------------------------------------------------------------------    
  --! @name MGT(GTX) reference clock
  signal mgtRefClk_from_smaMgtRefClkIbufdsGte : std_logic;

  ------------------------------------------------------------------------------
  --! @name Frame clock
  signal mgtClk_to_Buf          : std_logic;
  signal mgtClkBuf_to_txPll     : std_logic;
  signal txFrameClk_from_txPll  : std_logic;

  ------------------------------------------------------------------------------
  --! @name 125 MHz clock
  signal clk_125M               : std_logic;
  signal clk_125M_bufg          : std_logic;

  ------------------------------------------------------------------------------
  --! @name GBT Bank control
  signal txPllReset                                 : std_logic;
  signal resetgbtfpga_from_jtag                     : std_logic;
  signal resetgbtfpga_from_vio                      : std_logic;
  signal generalReset_from_user                     : std_logic;
  signal manualResetTx_from_user                    : std_logic;
  signal manualResetRx_from_user                    : std_logic;
  signal testPatterSel_from_user                    : std_logic_vector(1 downto 0);
  signal loopBack_from_user                         : std_logic_vector(2 downto 0);
  signal resetDataErrorSeenFlag_from_user           : std_logic;
  signal resetGbtRxReadyLostFlag_from_user          : std_logic;
  signal txIsDataSel_from_user                      : std_logic;

  signal latOptGbtBankTx_from_gbtExmplDsgn          : std_logic;
  signal latOptGbtBankRx_from_gbtExmplDsgn          : std_logic;
  signal txFrameClkPllLocked_from_gbtExmplDsgn      : std_logic;
  signal mgtReady_from_gbtExmplDsgn                 : std_logic;
  signal rxFrameClkReady_from_gbtExmplDsgn          : std_logic;
  signal gbtRxReady_from_gbtExmplDsgn               : std_logic;
  signal rxIsData_from_gbtExmplDsgn                 : std_logic;
  signal gbtRxReadyLostFlag_from_gbtExmplDsgn       : std_logic;
  signal rxDataErrorSeen_from_gbtExmplDsgn          : std_logic;
  signal rxExtrDataWidebusErSeen_from_gbtExmplDsgn  : std_logic;
  signal rxBitSlipRstCount_from_gbtExmplDsgn        : std_logic_vector(7 downto 0);
  signal rxBitSlipRstOnEvent_from_user              : std_logic;

  ------------------------------------------------------------------------------
  --! @name GBT Bank data
  signal txData_from_gbtExmplDsgn                   : std_logic_vector(83 downto 0);
  signal rxData_from_gbtExmplDsgn                   : std_logic_vector(83 downto 0);
  signal txExtraDataWidebus_from_gbtExmplDsgn       : std_logic_vector(115 downto 0);
  signal rxExtraDataWidebus_from_gbtExmplDsgn       : std_logic_vector(115 downto 0);

  ------------------------------------------------------------------------------
  --! @name Jtag to Axi component and signals:
  --     Used to control the design and monitor the signals in order to
  --     perform automatic tests.
  signal m_axi_awaddr           : std_logic_vector(31 downto 0);
  signal m_axi_awprot           : std_logic_vector(2 downto 0);
  signal m_axi_awvalid          : std_logic;
  signal m_axi_awready          : std_logic;
  signal m_axi_wdata            : std_logic_vector(31 downto 0);
  signal m_axi_wstrb            : std_logic_vector(3 downto 0);
  signal m_axi_wvalid           : std_logic;
  signal m_axi_wready           : std_logic;
  signal m_axi_bresp            : std_logic_vector(1 downto 0);
  signal m_axi_bvalid           : std_logic;
  signal m_axi_bready           : std_logic;
  signal m_axi_araddr           : std_logic_vector(31 downto 0);
  signal m_axi_arprot           : std_logic_vector(2 downto 0);
  signal m_axi_arvalid          : std_logic;
  signal m_axi_arready          : std_logic;
  signal m_axi_rdata            : std_logic_vector(31 downto 0);
  signal m_axi_rresp            : std_logic_vector(1 downto 0);
  signal m_axi_rvalid           : std_logic;
  signal m_axi_rready           : std_logic; 

  ------------------------------------------------------------------------------
  --! @name Chipscope
  signal vioControl_from_icon       : std_logic_vector(35 downto 0); 
  signal txIlaControl_from_icon     : std_logic_vector(35 downto 0); 
  signal rxIlaControl_from_icon     : std_logic_vector(35 downto 0); 
  signal gbtErrorDetected           : std_logic;
  signal modifiedBitsCnt            : std_logic_vector(7 downto 0);
  signal countWordReceived          : std_logic_vector(31 downto 0);
  signal countBitsModified          : std_logic_vector(31 downto 0);
  signal countWordErrors            : std_logic_vector(31 downto 0);
  signal gbtModifiedBitFlagFiltered : std_logic_vector(127 downto 0);
  signal gbtModifiedBitFlag         : std_logic_vector(83 downto 0);

  signal shiftTxClock_from_vio      : std_logic;
  signal txShiftCount_from_vio      : std_logic_vector(7 downto 0);
  signal txAligned_from_gbtbank     : std_logic;
  signal txAlignComputed_from_gbtbank   : std_logic;
  signal txAligned_from_gbtbank_latched : std_logic;

  signal sync_from_vio              : std_logic_vector(11 downto 0);
  signal async_to_vio               : std_logic_vector(17 downto 0);

  signal txEncoding_from_vio        : std_logic;
  signal rxEncoding_from_vio        : std_logic;

  ------------------------------------------------------------------------------
  --! @name Latency measurement
  signal DEBUG_CLK_ALIGNMENT_debug      : std_logic_vector(2 downto 0);
  signal txFrameClk_from_gbtExmplDsgn   : std_logic;
  signal txWordClk_from_gbtExmplDsgn    : std_logic;
  signal rxFrameClk_from_gbtExmplDsgn   : std_logic;
  signal rxWordClk_from_gbtExmplDsgn    : std_logic;
  signal txMatchFlag_from_gbtExmplDsgn  : std_logic;
  signal rxMatchFlag_from_gbtExmplDsgn  : std_logic;

  ------------------------------------------------------------------------------
  --! @name Main MMCM
  signal independent_clock_120M   : std_logic;
  signal main_mmcm_locked         : std_logic;

  -- ***************************************************************************
  --! @name Components
  -- ***************************************************************************
  -- Vivado synthesis tool does not support mixed-language
  -- Solution: http://www.xilinx.com/support/answers/47454.html
  component jtagctrl_gbtfpgatest
    port(
      aclk : in std_logic;
      aresetn : in std_logic;
      m_axi_awaddr : out std_logic_vector(31 downto 0);
      m_axi_awprot : out std_logic_vector(2 downto 0);
      m_axi_awvalid : out std_logic;
      m_axi_awready : in std_logic;
      m_axi_wdata : out std_logic_vector(31 downto 0);
      m_axi_wstrb : out std_logic_vector(3 downto 0);
      m_axi_wvalid : out std_logic;
      m_axi_wready : in std_logic;
      m_axi_bresp : in std_logic_vector(1 downto 0);
      m_axi_bvalid : in std_logic;
      m_axi_bready : out std_logic;
      m_axi_araddr : out std_logic_vector(31 downto 0);
      m_axi_arprot : out std_logic_vector(2 downto 0);
      m_axi_arvalid : out std_logic;
      m_axi_arready : in std_logic;
      m_axi_rdata : in std_logic_vector(31 downto 0);
      m_axi_rresp : in std_logic_vector(1 downto 0);
      m_axi_rvalid : in std_logic;
      m_axi_rready : out std_logic);
  end component;

  component xlx_zup_vivado_debug
    port(
      clk: in std_logic;
      probe0: in std_logic_vector(83 downto 0);
      probe1: in std_logic_vector(115 downto 0);
      probe2: in std_logic_vector(0 downto 0);
      probe3: in std_logic_vector(0 downto 0));
  end component;

  component xlx_zup_vio
    port(
      clk : in std_logic;
      probe_in0 : in std_logic_vector(0 downto 0);
      probe_in1 : in std_logic_vector(0 downto 0);
      probe_in2 : in std_logic_vector(0 downto 0);
      probe_in3 : in std_logic_vector(0 downto 0);
      probe_in4 : in std_logic_vector(0 downto 0);
      probe_in5 : in std_logic_vector(5 downto 0);
      probe_in6 : in std_logic_vector(0 downto 0);
      probe_in7 : in std_logic_vector(0 downto 0);
      probe_in8 : in std_logic_vector(0 downto 0);
      probe_in9 : in std_logic_vector(0 downto 0);
      probe_in10 : in std_logic_vector(0 downto 0);
      probe_in11 : in std_logic_vector(0 downto 0);
      probe_in12 : in std_logic_vector(0 downto 0);
      probe_in13 : in std_logic_vector(31 downto 0);
      probe_in14 : in std_logic_vector(31 downto 0);
      probe_in15 : in std_logic_vector(0 downto 0);
      probe_in16 : in std_logic_vector(0 downto 0);
      probe_in17 : in std_logic_vector(7 downto 0);
      probe_out0 : out std_logic_vector(0 downto 0);
      probe_out1 : out std_logic_vector(0 downto 0);
      probe_out2 : out std_logic_vector(1 downto 0);
      probe_out3 : out std_logic_vector(2 downto 0);
      probe_out4 : out std_logic_vector(0 downto 0);
      probe_out5 : out std_logic_vector(0 downto 0);
      probe_out6 : out std_logic_vector(0 downto 0);
      probe_out7 : out std_logic_vector(0 downto 0);
      probe_out8 : out std_logic_vector(0 downto 0);
      probe_out9 : out std_logic_vector(2 downto 0);
      probe_out10 : out std_logic_vector(0 downto 0);
      probe_out11 : out std_logic_vector(7 downto 0);
      probe_out12 : out std_logic_vector(0 downto 0);
      probe_out13 : out std_logic_vector(0 downto 0);
      probe_out14 : out std_logic_vector(0 downto 0);
      probe_out15 : out std_logic_vector(0 downto 0));
  end component;

  component main_mmcm
    port(
      clk_in_125M             : in  std_logic;
      clk_out_120M            : out std_logic;
      locked                  : out std_logic);
  end component;

-- #############################################################################
begin
  -- ***************************************************************************
  --! Main MMCM
  -- ***************************************************************************
  main_mmcm_inst : main_mmcm
    port map ( 
      clk_in_125M     => clk_125M_bufg,
      clk_out_120M    => independent_clock_120M,
      locked          => main_mmcm_locked);

  -- ***************************************************************************
  --! SFP control
  -- ***************************************************************************
  SFP0_TX_DISABLE_N <= '1';

  -- ***************************************************************************
  --! General reset
  -- ***************************************************************************
  genRst : entity work.xlx_zup_reset
    generic map (
      CLK_FREQ      => 120e6)
    port map (
      CLK_I         => independent_clock_120M,
      RESET1_B_I    => not CPU_RESET,
      RESET2_B_I    => not generalReset_from_user,
      RESET_O       => reset_from_genRst);

  -- ***************************************************************************
  --! Clocks
  -- ***************************************************************************   
  -- ***************************************************************************
  --! Clock 125 MHz
  -- ***************************************************************************
  clk_125M_ibufds_inst : IBUFDS
    generic map (
      IBUF_LOW_PWR              => FALSE,
      IOSTANDARD                => "LVDS_25")
    port map (
      O                         => clk_125M,
      I                         => CLK_125_P,
      IB                        => CLK_125_N);

  clk_125M_bufg_inst : BUFG
    port map (
      I                         => clk_125M,
      O                         => clk_125M_bufg);

   -- MGT(GTX) reference clock
  smaMgtRefClkIbufdsGte : ibufds_gte4
    generic map (
      REFCLK_EN_TX_PATH   => '0',
      REFCLK_HROW_CK_SEL  => "00",
      REFCLK_ICNTL_RX     => "00")
    port map (
      O                   => mgtRefClk_from_smaMgtRefClkIbufdsGte,
      ODIV2               => mgtClk_to_Buf,
      CEB                 => '0',
      I                   => SFP_SI5328_OUT_C_P,
      IB                  => SFP_SI5328_OUT_C_N);

  -- Frame clock
  txPllBuf_inst : bufg_gt
    port map (
      O                   => mgtClkBuf_to_txPll,
      I                   => mgtClk_to_Buf,
      CE                  => '1',
      DIV                 => "000",
      CLR                 => '0',
      CLRMASK             => '0',
      CEMASK              => '0');

  txFrameclkGen_inst : entity work.xlx_zup_tx_phaligner
    port map (
    -- Reset
    RESET_IN              => txPllReset,
    -- Clocks
    CLK_IN                => mgtClkBuf_to_txPll,
    CLK_OUT               => txFrameClk_from_txPll,
    -- Control
    SHIFT_IN              => shiftTxClock_from_vio,
    SHIFT_COUNT_IN        => txShiftCount_from_vio,
    -- Status
    LOCKED_OUT            => txFrameClkPllLocked_from_gbtExmplDsgn);
          
  -- ***************************************************************************
  -- GBT Bank
  -- ***************************************************************************
  gbtExmplDsgn_inst : entity work.xlx_zup_gbt_example_design
    generic map (
      NUM_LINKS                                       => NUM_LINK_Conf,         -- Up to 4
      TX_OPTIMIZATION                                 => TX_OPTIMIZATION_Conf,  -- LATENCY_OPTIMIZED or STANDARD
      RX_OPTIMIZATION                                 => RX_OPTIMIZATION_Conf,  -- LATENCY_OPTIMIZED or STANDARD
      TX_ENCODING                                     => TX_ENCODING_Conf,      -- GBT_FRAME or WIDE_BUS
      RX_ENCODING                                     => RX_ENCODING_Conf,      -- GBT_FRAME or WIDE_BUS

      DATA_GENERATOR_ENABLE                           => DATA_GENERATOR_ENABLE_Conf,
      DATA_CHECKER_ENABLE                             => DATA_CHECKER_ENABLE_Conf,
      MATCH_FLAG_ENABLE                               => MATCH_FLAG_ENABLE_Conf,
      CLOCKING_SCHEME                                 => CLOCKING_SCHEME_Conf)
    port map (
      -- Clocks
      FRAMECLK_40MHZ                                  => txFrameClk_from_txPll,
      XCVRCLK                                         => mgtRefClk_from_smaMgtRefClkIbufdsGte,
      TX_FRAMECLK_O(1)                                => txFrameClk_from_gbtExmplDsgn,        
      TX_WORDCLK_O(1)                                 => txWordClk_from_gbtExmplDsgn,          
      RX_FRAMECLK_O(1)                                => rxFrameClk_from_gbtExmplDsgn,
      RX_WORDCLK_O(1)                                 => rxWordClk_from_gbtExmplDsgn,      
      RX_FRAMECLK_RDY_O(1)                            => rxFrameClkReady_from_gbtExmplDsgn,
      -- Reset
      GBTBANK_GENERAL_RESET_I                         => reset_from_genRst,
      GBTBANK_MANUAL_RESET_TX_I                       => manualResetTx_from_user,
      GBTBANK_MANUAL_RESET_RX_I                       => manualResetRx_from_user,
      -- Serial lanes
      GBTBANK_MGT_RX_P(1)                             => SFP0_RX_P,
      GBTBANK_MGT_RX_N(1)                             => SFP0_RX_N,
      GBTBANK_MGT_TX_P(1)                             => SFP0_TX_P,
      GBTBANK_MGT_TX_N(1)                             => SFP0_TX_N,
      -- Data    
      GBTBANK_GBT_DATA_I(1)                           => (others => '0'),
      GBTBANK_WB_DATA_I(1)                            => (others => '0'),
      TX_DATA_O(1)                                    => txData_from_gbtExmplDsgn,            
      WB_DATA_O(1)                                    => txExtraDataWidebus_from_gbtExmplDsgn,
      GBTBANK_GBT_DATA_O(1)                           => rxData_from_gbtExmplDsgn,
      GBTBANK_WB_DATA_O(1)                            => rxExtraDataWidebus_from_gbtExmplDsgn,
      -- Reconfiguration
      -- Table 2-1 in PG182 (v1.7) notes that the free-running clock (which the below clock input is connected to)
      -- should have a frequency <= FRXUSRCLK2 = 120 MHz. NOTE: 125 MHz seems to also work
      GBTBANK_MGT_DRP_RST                             => '0',
      GBTBANK_MGT_DRP_CLK                             => independent_clock_120M,
      -- TX control
      TX_ENCODING_SEL_i(1)                            => txEncoding_from_vio,
      GBTBANK_TX_ISDATA_SEL_I(1)                      => txIsDataSel_from_user,
      GBTBANK_TEST_PATTERN_SEL_I                      => testPatterSel_from_user, 
      -- RX control
      RX_ENCODING_SEL_i(1)                            => rxEncoding_from_vio,
      GBTBANK_RESET_GBTRXREADY_LOST_FLAG_I(1)         => resetGbtRxReadyLostFlag_from_user,
      GBTBANK_RESET_DATA_ERRORSEEN_FLAG_I(1)          => resetDataErrorSeenFlag_from_user,
      GBTBANK_RXFRAMECLK_ALIGNPATTER_I                => DEBUG_CLK_ALIGNMENT_debug,
      GBTBANK_RXBITSLIT_RSTONEVEN_I(1)                => rxBitSlipRstOnEvent_from_user,
      -- TX Status
      GBTBANK_LINK_READY_O(1)                         => mgtReady_from_gbtExmplDsgn,
      GBTBANK_TX_MATCHFLAG_O                          => txMatchFlag_from_gbtExmplDsgn,
      GBTBANK_TX_ALIGNED_O(1)                         => txAligned_from_gbtbank,
      GBTBANK_TX_ALIGNCOMPUTED_O(1)                   => txAlignComputed_from_gbtbank,
      -- RX Status
      GBTBANK_GBTRX_READY_O(1)                        => gbtRxReady_from_gbtExmplDsgn,
      GBTBANK_GBTRXREADY_LOST_FLAG_O(1)               => gbtRxReadyLostFlag_from_gbtExmplDsgn,
      GBTBANK_RXDATA_ERRORSEEN_FLAG_O(1)              => rxDataErrorSeen_from_gbtExmplDsgn,
      GBTBANK_RXEXTRADATA_WIDEBUS_ERRORSEEN_FLAG_O(1) => rxExtrDataWidebusErSeen_from_gbtExmplDsgn,
      GBTBANK_RX_MATCHFLAG_O(1)                       => rxMatchFlag_from_gbtExmplDsgn,
      GBTBANK_RX_ISDATA_SEL_O(1)                      => rxIsData_from_gbtExmplDsgn,
      GBTBANK_RX_ERRORDETECTED_O(1)                   => gbtErrorDetected,
      GBTBANK_RX_BITMODIFIED_FLAG_O(1)                => gbtModifiedBitFlag,
      GBTBANK_RXBITSLIP_RST_CNT_O(1)                  => rxBitSlipRstCount_from_gbtExmplDsgn,
      -- XCVR control
      GBTBANK_LOOPBACK_I                              => loopBack_from_user,
      GBTBANK_TX_POL(1)                               => '0',
      GBTBANK_RX_POL(1)                               => '0');
   
  -- ***************************************************************************
  -- BER
  -- ***************************************************************************
  countWordReceivedProc : process(reset_from_genRst, rxframeclk_from_gbtExmplDsgn)
  begin
    if reset_from_genRst = '1' then
       countWordReceived <= (others => '0');
       countBitsModified <= (others => '0');
       countWordErrors <= (others => '0');

    elsif rising_edge(rxframeclk_from_gbtExmplDsgn) then
      if gbtRxReady_from_gbtExmplDsgn = '1' then
        if gbtErrorDetected = '1' then
          countWordErrors <= std_logic_vector(unsigned(countWordErrors) + 1);                
        end if;
        countWordReceived <= std_logic_vector(unsigned(countWordReceived) + 1);
      end if;
      countBitsModified <= std_logic_vector(unsigned(modifiedBitsCnt) + unsigned(countBitsModified));
    end if;
  end process;

  gbtModifiedBitFlagFiltered(127 downto 84) <= (others => '0');
  gbtModifiedBitFlagFiltered(83 downto 0)   <= gbtModifiedBitFlag when gbtRxReady_from_gbtExmplDsgn = '1' else
                                               (others => '0');

  countOnesCorrected : entity work.CountOnes
    generic map (
      SIZE            => 128,
      MAXOUTWIDTH     => 8)
      port map (
      Clock           => rxframeclk_from_gbtExmplDsgn, -- Warning: Because the enable signal (1 over 3 or 6 clock cycle) is not used, the number of error is multiplied by 3 or 6.
      I               => gbtModifiedBitFlagFiltered,
      O               => modifiedBitsCnt);            
               
  -- ***************************************************************************
  -- Test control
  -- ***************************************************************************
  jtag_master_inst : jtagCtrl_gbtfpgaTest
    port map (
      aclk                  => txFrameClk_from_txPll,
      aresetn               => txFrameClkPllLocked_from_gbtExmplDsgn,
      m_axi_awaddr          => m_axi_awaddr,
      m_axi_awprot          => m_axi_awprot,
      m_axi_awvalid         => m_axi_awvalid,
      m_axi_awready         => m_axi_awready,
      m_axi_wdata           => m_axi_wdata,
      m_axi_wstrb           => m_axi_wstrb,
      m_axi_wvalid          => m_axi_wvalid,
      m_axi_wready          => m_axi_wready,
      m_axi_bresp           => m_axi_bresp,
      m_axi_bvalid          => m_axi_bvalid,
      m_axi_bready          => m_axi_bready,
      m_axi_araddr          => m_axi_araddr,
      m_axi_arprot          => m_axi_arprot,
      m_axi_arvalid         => m_axi_arvalid,
      m_axi_arready         => m_axi_arready,
      m_axi_rdata           => m_axi_rdata,
      m_axi_rresp           => m_axi_rresp,
      m_axi_rvalid          => m_axi_rvalid,
      m_axi_rready          => m_axi_rready);

  gbtfpga_controller_inst : entity work.gbtfpga_controller
    port map (
      -- AXI4LITE Interface
      S_AXI_ACLK            => txFrameClk_from_txPll,
      S_AXI_ARESETN         => txFrameClkPllLocked_from_gbtExmplDsgn,
      S_AXI_AWADDR          => m_axi_awaddr(4 downto 0),
      S_AXI_AWVALID         => m_axi_awvalid,
      S_AXI_AWREADY         => m_axi_awready,
      S_AXI_WDATA           => m_axi_wdata,
      S_AXI_WSTRB           => m_axi_wstrb,
      S_AXI_WVALID          => m_axi_wvalid,
      S_AXI_WREADY          => m_axi_wready,
      S_AXI_BRESP           => m_axi_bresp,
      S_AXI_BVALID          => m_axi_bvalid,
      S_AXI_BREADY          => m_axi_bready,
      S_AXI_ARADDR          => m_axi_araddr(4 downto 0),
      S_AXI_ARVALID         => m_axi_arvalid,
      S_AXI_ARREADY         => m_axi_arready,
      S_AXI_RDATA           => m_axi_rdata,
      S_AXI_RRESP           => m_axi_rresp,
      S_AXI_RVALID          => m_axi_rvalid,
      S_AXI_RREADY          => m_axi_rready,
      -- To GBT-FPGA
      reset_gbtfpga         => resetgbtfpga_from_jtag,
      -- From GBT-FPGA
      gbtRxReady            => gbtRxReady_from_gbtExmplDsgn);
    
  txILa : xlx_zup_vivado_debug
    port map (
      CLK => clk_125M_bufg,
      PROBE0 => txData_from_gbtExmplDsgn,
      PROBE1 => txExtraDataWidebus_from_gbtExmplDsgn,
      PROBE2(0) => txIsDataSel_from_user,
      PROBE3(0) => '0');  
   
  rxIla : xlx_zup_vivado_debug
    port map (
      CLK => clk_125M_bufg,
      PROBE0 => rxData_from_gbtExmplDsgn,
      PROBE1 => rxExtraDataWidebus_from_gbtExmplDsgn,
      PROBE2(0) => rxIsData_from_gbtExmplDsgn,
      PROBE3(0) => gbtErrorDetected);  
    
  generalReset_from_user <= resetgbtfpga_from_vio or resetgbtfpga_from_jtag or not(txFrameClkPllLocked_from_gbtExmplDsgn);
        
  alignmenetLatchProc : process(txFrameClk_from_txPll, reset_from_genRst)
  begin
    if reset_from_genRst = '1' then
      txAligned_from_gbtbank_latched <= '0';
    elsif rising_edge(txFrameClk_from_txPll) then
      if txAlignComputed_from_gbtbank = '1' then
        txAligned_from_gbtbank_latched <= txAligned_from_gbtbank;
      end if;
    end if;
  end process;
      
  vio : xlx_zup_vio
    port map (
      clk => clk_125M_bufg,
      probe_in0(0) => rxIsData_from_gbtExmplDsgn,
      probe_in1(0) => txFrameClkPllLocked_from_gbtExmplDsgn,
      probe_in2(0) => latOptGbtBankTx_from_gbtExmplDsgn,
      probe_in3(0) => mgtReady_from_gbtExmplDsgn,
      probe_in4(0) => txMatchFlag_from_gbtExmplDsgn,
      probe_in5    => (others => '0'),
      probe_in6(0) => rxFrameClkReady_from_gbtExmplDsgn,
      probe_in7(0) => gbtRxReady_from_gbtExmplDsgn,
      probe_in8(0) => gbtRxReadyLostFlag_from_gbtExmplDsgn,
      probe_in9(0) => rxDataErrorSeen_from_gbtExmplDsgn,
      probe_in10(0) => rxExtrDataWidebusErSeen_from_gbtExmplDsgn,
      probe_in11(0) => '0',
      probe_in12(0) => latOptGbtBankRx_from_gbtExmplDsgn,
      probe_in13    => countBitsModified,
      probe_in14    => countWordReceived,
      probe_in15(0)    => txAligned_from_gbtbank_latched,
      probe_in16(0)    => txAlignComputed_from_gbtbank,
      probe_in17       => rxBitSlipRstCount_from_gbtExmplDsgn,
      probe_out0(0) => resetgbtfpga_from_vio,
      probe_out1(0) => open,
      probe_out2 => testPatterSel_from_user,
      probe_out3 => loopBack_from_user,
      probe_out4(0) => resetDataErrorSeenFlag_from_user,
      probe_out5(0) => resetGbtRxReadyLostFlag_from_user,
      probe_out6(0) => txIsDataSel_from_user,
      probe_out7(0) => manualResetTx_from_user,
      probe_out8(0) => manualResetRx_from_user,
      probe_out9    => DEBUG_CLK_ALIGNMENT_debug,
      probe_out10(0) => shiftTxClock_from_vio,
      probe_out11    => txShiftCount_from_vio,
      probe_out12(0) => rxBitSlipRstOnEvent_from_user,
      probe_out13(0) => txPllReset,
      probe_out14(0) => txEncoding_from_vio,
      probe_out15(0) => rxEncoding_from_vio);
             
  latOptGbtBankTx_from_gbtExmplDsgn <= '1' when TX_OPTIMIZATION_Conf = LATENCY_OPTIMIZED else '0';
  latOptGbtBankRx_from_gbtExmplDsgn <= '1' when RX_OPTIMIZATION_Conf = LATENCY_OPTIMIZED else '0';

  -- ***************************************************************************
  -- ***************************************************************************
  -- ***************************************************************************
end structural;
