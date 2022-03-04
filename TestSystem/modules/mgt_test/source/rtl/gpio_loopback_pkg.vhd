-------------------------------------------------------------------------------
-- Title      : GPIO Loopback package
-- Project    : RUv2 Testsystem
-------------------------------------------------------------------------------
-- File       : gpio_loopback_pkg.vhd
-- Author     : Joachim Schambach  <jschamba@physics.utexas.edu>
-- Company    : University of Texas at Austin
-- Author     : Marcel Rossewij  <m.j.rossewij@uu.nl>
-- Company    : Utrecht University
-- Created    : 2018-10-17
-- Last update: 2019-01-03
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: wishbone package for loopback test
-------------------------------------------------------------------------------
-- Copyright (c) 2018 University of Texas at Austin
-- Copyright (c) 2017 CERN European Organization for Nuclear Research
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018-10-17  1.0      jschamba  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

-- Wishbone interface package
use work.intercon_pkg.all;

package gpio_loopback_pkg is

  -- Mapping of WB Registers
  type WB_ADD is (
    clearError,
    injectError,
    loopbackCTRL,
    SMAJ21J22Error,
    headerJ13_0Error,
    headerJ13_1Error,
    headerJ13_2Error,
    headerJ13_3Error,
    headerJ13_4Error,
    PA3headerJ14_0Error,
    PA3headerJ14_1Error,
    PA3headerJ14_2Error,
    PA3headerJ14_3Error,
    PA3headerJ14_4Error,
    pa3_0Error,
    pa3_1Error,
    pa3_2Error,
    pa3_3Error,
    pa3_4Error,
    pa3_5Error,
    pa3_6Error,
    pa3_7Error,
    pa3_8Error,
    pa3_9Error,
    DCTRL_0Error,
    DCTRL_1Error,
    DCTRL_2Error,
    DCTRL_3Error,
    DCTRL_4Error,
    DCLKB_0Error,
    DCLKB_1Error,
    DCLKB_2Error,
    DCLKB_3Error,
    DCLKB_4Error,
    DCLKC_0Error,
    DCLKC_1Error,
    DCLKC_2Error,
    DCLKC_3Error,
    DCLKC_4Error,
    aux_0Error,
    aux_1Error,
    aux_2Error,
    aux_3Error,
    pu_0Error,
    pu_1Error,
    pu_2Error,
    pu_3Error,
    pu_4Error,
    pu_5Error,
    pu_6Error,
    pu_7Error
    );

  -- Register write enable
  constant C_WB_ADD_WE : t_wbs_reg_we_array(WB_ADD'pos(WB_ADD'high) downto 0) := (
    WB_ADD'pos(clearError)          => rw,
    WB_ADD'pos(injectError)         => rw,
    WB_ADD'pos(loopbackCTRL)        => rw,
    WB_ADD'pos(smaJ21J22Error)      => r,
    WB_ADD'pos(headerJ13_0Error)    => r,
    WB_ADD'pos(headerJ13_1Error)    => r,
    WB_ADD'pos(headerJ13_2Error)    => r,
    WB_ADD'pos(headerJ13_3Error)    => r,
    WB_ADD'pos(headerJ13_4Error)    => r,
    WB_ADD'pos(PA3headerJ14_0Error) => r,
    WB_ADD'pos(PA3headerJ14_1Error) => r,
    WB_ADD'pos(PA3headerJ14_2Error) => r,
    WB_ADD'pos(PA3headerJ14_3Error) => r,
    WB_ADD'pos(PA3headerJ14_4Error) => r,
    WB_ADD'pos(pa3_0Error)          => r,
    WB_ADD'pos(pa3_1Error)          => r,
    WB_ADD'pos(pa3_2Error)          => r,
    WB_ADD'pos(pa3_3Error)          => r,
    WB_ADD'pos(pa3_4Error)          => r,
    WB_ADD'pos(pa3_5Error)          => r,
    WB_ADD'pos(pa3_6Error)          => r,
    WB_ADD'pos(pa3_7Error)          => r,
    WB_ADD'pos(pa3_8Error)          => r,
    WB_ADD'pos(pa3_9Error)          => r,
    WB_ADD'pos(DCTRL_0Error)        => r,
    WB_ADD'pos(DCTRL_1Error)        => r,
    WB_ADD'pos(DCTRL_2Error)        => r,
    WB_ADD'pos(DCTRL_3Error)        => r,
    WB_ADD'pos(DCTRL_4Error)        => r,
    WB_ADD'pos(DCLKb_0Error)        => r,
    WB_ADD'pos(DCLKb_1Error)        => r,
    WB_ADD'pos(DCLKb_2Error)        => r,
    WB_ADD'pos(DCLKb_3Error)        => r,
    WB_ADD'pos(DCLKb_4Error)        => r,
    WB_ADD'pos(DCLKc_0Error)        => r,
    WB_ADD'pos(DCLKc_1Error)        => r,
    WB_ADD'pos(DCLKc_2Error)        => r,
    WB_ADD'pos(DCLKc_3Error)        => r,
    WB_ADD'pos(DCLKc_4Error)        => r,
    WB_ADD'pos(aux_0Error)          => r,
    WB_ADD'pos(aux_1Error)          => r,
    WB_ADD'pos(aux_2Error)          => r,
    WB_ADD'pos(aux_3Error)          => r,
    WB_ADD'pos(pu_0Error)           => r,
    WB_ADD'pos(pu_1Error)           => r,
    WB_ADD'pos(pu_2Error)           => r,
    WB_ADD'pos(pu_3Error)           => r,
    WB_ADD'pos(pu_4Error)           => r,
    WB_ADD'pos(pu_5Error)           => r,
    WB_ADD'pos(pu_6Error)           => r,
    WB_ADD'pos(pu_7Error)           => r
    );

  -- Reset value for writable registers
  constant C_WB_REG_DEFAULT : t_wbs_reg_array := (WB_ADD'pos(WB_ADD'high) downto 0 => (others => '0'));

  type auxType is array (0 to 3) of std_logic_vector(0 downto 0);
  type headerType is array (0 to 4) of std_logic_vector(0 downto 0);
  type puType is array (0 to 7) of std_logic_vector(0 downto 0);
  type pa3Type is array (0 to 9) of std_logic_vector(0 downto 0);
  type auxErrorType is array (0 to 3) of unsigned (WB_DATA_WIDTH-1 downto 0);
  type headerErrorType is array (0 to 4) of unsigned (WB_DATA_WIDTH-1 downto 0);
  type puErrorType is array (0 to 7) of unsigned (WB_DATA_WIDTH-1 downto 0);
  type pa3ErrorType is array (0 to 9) of unsigned (WB_DATA_WIDTH-1 downto 0);

  type t_wb_reg_rd is record
    smaErrorCnt          : unsigned(WB_DATA_WIDTH-1 downto 0);
    headerJ13ErrorCnt    : headerErrorType;
    PA3headerJ14ErrorCnt : headerErrorType;
    pa3ErrorCnt          : pa3ErrorType;
    DCTRLerrorCnt        : headerErrorType;
    DCLKbErrorCnt        : headerErrorType;
    DCLKCErrorCnt        : headerErrorType;
    auxErrorCnt          : auxErrorType;
    puErrorCnt           : puErrorType;
  end record t_wb_reg_rd;

  type t_wb_reg_wr is record
    clearError   : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    injectError  : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    loopbackCTRL : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
  end record t_wb_reg_wr;

end package gpio_loopback_pkg;
