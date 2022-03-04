-------------------------------------------------------------------------------
-- Title      : GPIO Loopback test
-- Project    : RUv2 Test System
-------------------------------------------------------------------------------
-- File       : gpio_loopback.vhd
-- Author     : Marcel Rossewij <m.j.rossewij@uu.nl>
-- Institute  : Utrecht University
-- Author     : Joachim Schambach  <jschamba@physics.utexas.edu>
-- Company    : University of Texas at Austin
-- Created    : 2018-10-17
-- Last update: 2019-01-03
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Loopback tests for I/Os other than MGT
-------------------------------------------------------------------------------
-- Copyright (c) 2018 University of Texas at Austin
-- Copyright (c) 2016 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018-10-17  1.0      jschamba  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

-- Wishbone interface package
use work.intercon_pkg.all;
use work.gpio_loopback_pkg.all;

entity gpio_loopback is
  port (
    -- Wishbone interface
    WB_CLK              : in  std_logic;  -- Wishbone clock
    WB_RST              : in  std_logic;  -- Wishbone reset
    WB_WBS_I            : in  wbs_i_type;  -- Wishbone slave input signals
    WB_WBS_O            : out wbs_o_type;  -- Wishbone slave output signals
    -- I/O pins to test
    SMA_OUT             : out std_logic;  -- prbs out (for SMA J22)
    SMA_IN              : in  std_logic;  -- prbs in (from SMA J21)
    HEADER_OUT          : out std_logic_vector(4 downto 0);  -- prbs out (for J13 pin 0...4)
    HEADER_IN           : in  std_logic_vector(4 downto 0);  -- prbs in (from J13 pin 5...9)
    PA3_OUT             : out std_logic_vector(4 downto 0);  -- prbs out (for PA3_J14 pin 0...4)
    PA3_IN              : in  std_logic_vector(4 downto 0);  -- prbs in (from PA3_J14 pin 5...9)
    PA3_IO_I            : in  std_logic_vector(9 downto 0);
    ALPIDE_DCLK_A       : out std_logic_vector(4 downto 0);
    ALPIDE_DCLK_B       : in  std_logic_vector(4 downto 0);
    ALPIDE_DCLK_C       : in  std_logic_vector(4 downto 0);
    ALPIDE_DCLK_EN      : out std_logic_vector(4 downto 0);
    ALPIDE_DCLK_A_T     : out std_logic_vector(4 downto 0);
    ALPIDE_DCTRL_O      : out std_logic_vector(4 downto 0);
    ALPIDE_DCTRL_T      : out std_logic;
    ALPIDE_DCTRL_I      : in  std_logic_vector(4 downto 0);
    AUX_OUT             : out std_logic_vector(3 downto 0);
    AUX_IN              : in  std_logic_vector(3 downto 0);
    PU1_SDA_WRITE       : out std_logic;
    PU1_SDA_READ        : in  std_logic;
    PU1_SCL_WRITE       : out std_logic;
    PU1_SCL_READ        : in  std_logic;
    PU1_SDA_AUX_WRITE   : out std_logic;
    PU1_SDA_AUX_READ    : in  std_logic;
    PU1_SCL_AUX_WRITE   : out std_logic;
    PU1_SCL_AUX_READ    : in  std_logic;
    PU2_SDA_WRITE       : out std_logic;
    PU2_SDA_READ        : in  std_logic;
    PU2_SCL_WRITE       : out std_logic;
    PU2_SCL_READ        : in  std_logic;
    PU2_SDA_AUX_WRITE   : out std_logic;
    PU2_SDA_AUX_READ    : in  std_logic;
    PU2_SCL_AUX_WRITE   : out std_logic;
    PU2_SCL_AUX_READ    : in  std_logic;
    INJECT_GLOBAL_ERROR : in  std_logic;  -- injects error on all prbs output signals
    CLEAR_GLOBAL_ERROR  : in  std_logic;  -- clears all error counters
    -- Error indicator LED
    ERROR_DETECT        : out std_logic   --
    );

end gpio_loopback;

architecture str of gpio_loopback is

  constant C_POLY_LENGHT : natural := 7;
  constant C_POLY_TAP    : natural := 6;
  constant C_INV_PATTERN : boolean := false;

  component prbs_any
    generic (
      CHK_MODE    : boolean;
      INV_PATTERN : boolean;
      POLY_LENGHT : natural range 0 to 63;
      POLY_TAP    : natural range 0 to 63;
      NBITS       : natural range 0 to 512
      );
    port (
      RST      : in  std_logic;         -- sync reset active high
      CLK      : in  std_logic;         -- system clock
      DATA_IN  : in  std_logic_vector(NBITS - 1 downto 0);  -- inject error/data to be checked
      EN       : in  std_logic;         -- enable/pause pattern generation
      DATA_OUT : out std_logic_vector(NBITS - 1 downto 0)  -- generated prbs pattern/errors found
      );
  end component;

  signal s_inj_error_vector : std_logic_vector (0 downto 0);
  signal s_prbs_out         : std_logic_vector (0 downto 0);
  signal s_prbs             : std_logic_vector (7 downto 0);

  signal s_sma      : std_logic_vector (0 downto 0);
  signal s_smaError : std_logic_vector (0 downto 0);

  signal s_aux, s_auxError : auxType;

  signal s_headerJ13, s_headerJ13Error, s_PA3headerJ14,
    s_PA3headerJ14Error, s_DCLKb, s_DCLKbError,
    s_DCLKc, s_DCLKcError, s_DCTRL, s_DCTRLerror : headerType;

  signal s_pu, s_puError : puType;

  signal s_pa3, s_pa3Error : pa3Type;

  signal sWbReg_rd : t_wb_reg_rd;
  signal sWbReg_wr : t_wb_reg_wr;

begin

  INST_ws_gpio_loopback: entity work.ws_gpio_loopback
    port map (
      WB_CLK   => WB_CLK,
      WB_RST   => WB_RST,
      WB_WBS_I => WB_WBS_I,
      WB_WBS_O => WB_WBS_O,
      WB_REG_I => sWbReg_rd,
      WB_REG_O => sWbReg_wr
      );

  ----------------------------------------------                
  -- Instantiate the PRBS generator
  ----------------------------------------------        
  s_inj_error_vector(0) <= INJECT_GLOBAL_ERROR;

  INST_PRBS_ANY_VHD_GEN : prbs_any
    generic map (
      CHK_MODE    => false,
      INV_PATTERN => C_INV_PATTERN,
      POLY_LENGHT => C_POLY_LENGHT,
      POLY_TAP    => C_POLY_TAP,
      NBITS       => 1
      )
    port map(
      RST      => '0',
      CLK      => WB_CLK,
      DATA_IN  => s_inj_error_vector,
      EN       => '1',
      DATA_OUT => s_prbs_out
      );

  SMA_OUT <= s_prbs_out(0) xor sWbReg_wr.injectError(0);

  process(WB_CLK)
  begin
    if rising_edge(WB_CLK) then
      s_prbs <= s_prbs(6 downto 0) & s_prbs_out(0);
    end if;
  end process;

  HEADER_OUT        <= s_prbs(4 downto 0) xor sWbReg_wr.injectError(4 downto 0);
  PA3_OUT           <= s_prbs(4 downto 0) xor sWbReg_wr.injectError(4 downto 0);
  AUX_OUT           <= s_prbs(3 downto 0) xor sWbReg_wr.injectError(3 downto 0);
  PU1_SDA_WRITE     <= s_prbs(0) xor sWbReg_wr.injectError(0);
  PU1_SCL_WRITE     <= s_prbs(1) xor sWbReg_wr.injectError(1);
  PU1_SDA_AUX_WRITE <= s_prbs(2) xor sWbReg_wr.injectError(2);
  PU1_SCL_AUX_WRITE <= s_prbs(3) xor sWbReg_wr.injectError(3);
  --
  PU2_SDA_WRITE     <= s_prbs(4) xor sWbReg_wr.injectError(4);
  PU2_SCL_WRITE     <= s_prbs(5) xor sWbReg_wr.injectError(5);
  PU2_SDA_AUX_WRITE <= s_prbs(6) xor sWbReg_wr.injectError(6);
  PU2_SCL_AUX_WRITE <= s_prbs(7) xor sWbReg_wr.injectError(7);

  -----------------------------------------------------------------------------
  -- PRBS on DCLK_A
  ALPIDE_DCLK_A <= s_prbs(4 downto 0) xor sWbReg_wr.injectError(4 downto 0) when sWbReg_wr.loopbackCTRL(0) = '0'
                   else (others => '0');

  ALPIDE_DCLK_A_T <= (others => '0') when sWbReg_wr.loopbackCTRL(0) = '0'
                     else (others => '1');

  -- PRBS on DCTRL
  ALPIDE_DCLK_EN <= (others => '0') when sWbReg_wr.loopbackCTRL(0) = '1'
                    else (others => '1');

  ALPIDE_DCTRL_O <= s_prbs(4 downto 0) xor sWbReg_wr.injectError(4 downto 0) when sWbReg_wr.loopbackCTRL(0) = '1'
                    else (others => '0');

  ALPIDE_DCTRL_T <= '0' when sWbReg_wr.loopbackCTRL(0) = '1'
                    else '1';

  ----------------------------------------------        
  -- Instantiate the checker for SMA CLKOUT CLKIN
  ----------------------------------------------
  s_sma(0) <= SMA_IN;
  INST_PRBS_ANY_VHD : prbs_any
    generic map(
      CHK_MODE    => true,
      INV_PATTERN => C_INV_PATTERN,
      POLY_LENGHT => C_POLY_LENGHT,
      POLY_TAP    => C_POLY_TAP,
      NBITS       => 1
      )
    port map(
      RST      => '0',
      CLK      => WB_CLK,
      DATA_IN  => s_sma,
      EN       => '1',
      DATA_OUT => s_smaError
      );

  ERROR_DETECT <= s_smaError(0);

  process(WB_CLK)
  begin
    if rising_edge(WB_CLK) then
      if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(0) = '1')then  -- (synchr) clear count takes precedence over enable
        sWbReg_rd.smaErrorCnt <= (others => '0');
      elsif s_smaError(0) = '1' then
        sWbReg_rd.smaErrorCnt <= sWbReg_rd.smaErrorCnt + 1;
      end if;
    end if;
  end process;

  ----------------------------------------------        
  -- Instantiate the checker for HEADER J13
  ----------------------------------------------
  GENERATE_HEADER_J13 : for hi in 0 to 4 generate
    s_headerJ13(hi)(0) <= HEADER_IN(hi);
    INST_PRBS_HEADER_J13_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => '0',
        CLK      => WB_CLK,
        DATA_IN  => s_headerJ13(hi),
        EN       => '1',
        DATA_OUT => s_headerJ13Error(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.headerJ13ErrorCnt(hi) <= (others => '0');
        elsif s_headerJ13Error(hi)(0) = '1' then
          sWbReg_rd.headerJ13ErrorCnt(hi) <= sWbReg_rd.headerJ13ErrorCnt(hi) + 1;
        end if;
      end if;
    end process;

  end generate GENERATE_HEADER_J13;

  ----------------------------------------------        
  -- Instantiate the checker for PA3 LVDS signals via HEADER J14
  ----------------------------------------------
  GENERATE_PA3_HEADER_J14 : for hi in 0 to 4 generate
    s_PA3headerJ14(hi)(0) <= PA3_IN(hi);
    INST_PRBS_PA3_HEADER_J143_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => '0',
        CLK      => WB_CLK,
        DATA_IN  => s_PA3headerJ14(hi),
        EN       => '1',
        DATA_OUT => s_PA3headerJ14Error(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.PA3headerJ14ErrorCnt(hi) <= (others => '0');
        elsif s_PA3headerJ14Error(hi)(0) = '1' then
          sWbReg_rd.PA3headerJ14ErrorCnt(hi) <= sWbReg_rd.PA3headerJ14ErrorCnt(hi) + 1;
        end if;
      end if;
    end process;
  end generate GENERATE_PA3_HEADER_J14;

----------------------------------------------        
  -- Instantiate the checker for PA3 single ended signals 
  ----------------------------------------------
  GENERATE_PA3 : for hi in 0 to 9 generate
    process(WB_CLK)
    begin
      if falling_edge(WB_CLK) then s_pa3(hi)(0) <= PA3_IO_I(hi); end if;
    end process;

    INST_PA3_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => '0',
        CLK      => WB_CLK,
        DATA_IN  => s_pa3(hi),
        EN       => '1',
        DATA_OUT => s_pa3Error(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.pa3ErrorCnt(hi) <= (others => '0');
        elsif s_pa3Error(hi)(0) = '1' then
          sWbReg_rd.pa3ErrorCnt(hi) <= sWbReg_rd.pa3ErrorCnt(hi) + 1;
        end if;
      end if;
    end process;
  end generate GENERATE_PA3;

  ----------------------------------------------        
  -- Instantiate the checker for ALPIDE_DCTRL_I signal 
  ----------------------------------------------
  GENERATE_ALPIDE_DCTRL_I : for hi in 0 to 4 generate
    process(WB_CLK)
    begin
      if falling_edge(WB_CLK) then s_DCTRL(hi)(0) <= ALPIDE_DCTRL_I(hi); end if;
    end process;
    INST_DCTRL_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => sWbReg_wr.clearError(12),
        CLK      => WB_CLK,
        DATA_IN  => s_DCTRL(hi),
        EN       => '1',
        DATA_OUT => s_DCTRLerror(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.DCTRLerrorCnt(hi) <= (others => '0');
        elsif s_DCTRLerror(hi)(0) = '1' then
          sWbReg_rd.DCTRLerrorCnt(hi) <= sWbReg_rd.DCTRLerrorCnt(hi) + 1;
        end if;
      end if;
    end process;
  end generate GENERATE_ALPIDE_DCTRL_I;

  ----------------------------------------------        
  -- Instantiate the checker for ALPIDE_DCLK_B signal 
  ----------------------------------------------
  GENERATE_ALPIDE_DCLK_B : for hi in 0 to 4 generate
    process(WB_CLK)
    begin
      if falling_edge(WB_CLK) then s_DCLKb(hi)(0) <= ALPIDE_DCLK_B(hi); end if;
    end process;
    INST_DCLKb_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => sWbReg_wr.clearError(12),
        CLK      => WB_CLK,
        DATA_IN  => s_DCLKb(hi),
        EN       => '1',
        DATA_OUT => s_DCLKbError(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.DCLKbErrorCnt(hi) <= (others => '0');
        elsif s_DCLKbError(hi)(0) = '1' then
          sWbReg_rd.DCLKbErrorCnt(hi) <= sWbReg_rd.DCLKbErrorCnt(hi) + 1;
        end if;
      end if;
    end process;
  end generate GENERATE_ALPIDE_DCLK_B;

  ----------------------------------------------        
  -- Instantiate the checker for ALPIDE_DCLK_C signal 
  ----------------------------------------------
  GENERATE_ALPIDE_DCLK_C : for hi in 0 to 4 generate
    process(WB_CLK)
    begin
      if falling_edge(WB_CLK) then s_DCLKc(hi)(0) <= ALPIDE_DCLK_C(hi); end if;
    end process;
    INST_DCLKc_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => sWbReg_wr.clearError(12),
        CLK      => WB_CLK,
        DATA_IN  => s_DCLKc(hi),
        EN       => '1',
        DATA_OUT => s_DCLKcError(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.DCLKcErrorCnt(hi) <= (others => '0');
        elsif s_DCLKcError(hi)(0) = '1' then
          sWbReg_rd.DCLKcErrorCnt(hi) <= sWbReg_rd.DCLKcErrorCnt(hi) + 1;
        end if;
      end if;
    end process;
  end generate GENERATE_ALPIDE_DCLK_C;

  ----------------------------------------------        
  -- Instantiate the checker for AUX signals 
  ----------------------------------------------
  GENERATE_AUX : for hi in 0 to 3 generate
    s_aux(hi)(0) <= AUX_IN(hi);
    INST_AUX_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => '0',
        CLK      => WB_CLK,
        DATA_IN  => s_aux(hi),
        EN       => '1',
        DATA_OUT => s_auxError(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.auxErrorCnt(hi) <= (others => '0');
        elsif s_auxError(hi)(0) = '1' then
          sWbReg_rd.auxErrorCnt(hi) <= sWbReg_rd.auxErrorCnt(hi) + 1;
        end if;
      end if;
    end process;
  end generate GENERATE_AUX;
  ----------------------------------------------        
  -- Instantiate the checker for PU signals 
  ----------------------------------------------
  s_pu(0)(0) <= not PU2_SDA_AUX_READ;  -- PU1_SDA_WRITE     <= prbs(0) xor injectErrorReg(0);
  s_pu(1)(0) <= not PU2_SCL_AUX_READ;  -- PU1_SCL_WRITE     <= prbs(1) xor injectErrorReg(1);
  s_pu(2)(0) <= not PU2_SDA_READ;  -- PU1_SDA_AUX_WRITE <= prbs(2) xor injectErrorReg(2);
  s_pu(3)(0) <= not PU2_SCL_READ;  -- PU1_SCL_AUX_WRITE <= prbs(3) xor injectErrorReg(3);
  s_pu(4)(0) <= not PU1_SDA_AUX_READ;  -- PU2_SDA_WRITE     <= prbs(4) xor injectErrorReg(4);
  s_pu(5)(0) <= not PU1_SCL_AUX_READ;  -- PU2_SCL_WRITE     <= prbs(5) xor injectErrorReg(5);
  s_pu(6)(0) <= not PU1_SDA_READ;  -- PU2_SDA_AUX_WRITE <= prbs(6) xor injectErrorReg(6);
  s_pu(7)(0) <= not PU1_SCL_READ;  -- PU2_SCL_AUX_WRITE <= prbs(7) xor injectErrorReg(7);

  GENERATE_PU : for hi in 0 to 7 generate
    INST_PU_hi : prbs_any
      generic map(
        CHK_MODE    => true,
        INV_PATTERN => C_INV_PATTERN,
        POLY_LENGHT => C_POLY_LENGHT,
        POLY_TAP    => C_POLY_TAP,
        NBITS       => 1
        )
      port map(
        RST      => '0',
        CLK      => WB_CLK,
        DATA_IN  => s_pu(hi),
        EN       => '1',
        DATA_OUT => s_puError(hi)
        );

    process(WB_CLK)
    begin
      if rising_edge(WB_CLK) then
        if (CLEAR_GLOBAL_ERROR = '1' or sWbReg_wr.clearError(hi) = '1') then  -- (synchr) clear count takes precedence over enable
          sWbReg_rd.puErrorCnt(hi) <= (others => '0');
        elsif s_puError(hi)(0) = '1' then
          sWbReg_rd.puErrorCnt(hi) <= sWbReg_rd.puErrorCnt(hi) + 1;
        end if;
      end if;
    end process;
  end generate GENERATE_PU;

end architecture str;

