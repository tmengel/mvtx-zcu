-------------------------------------------------------------------------------
-- Title      : GPIO Loopback Wishbone Slave
-- Project    : RUv2 Test System
-------------------------------------------------------------------------------
-- File       : ws_gpio_loopback.vhd
-- Author     : Joachim Schambach  <jschamba@physics.utexas.edu>
-- Company    : University of Texas at Austin
-- Author     : Marcel Rossewij <m.j.rossewij@uu.nl>
-- Institute  : Utrecht University
-- Created    : 2018-10-17
-- Last update: 2019-01-03
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone slave for GPIO Loopback module
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

entity ws_gpio_loopback is
  port (
    -- Wishbone interface
    WB_CLK   : in  std_logic;           -- Wishbone clock
    WB_RST   : in  std_logic;           -- Wishbone reset
    WB_WBS_I : in  wbs_i_type;          -- Wishbone slave input signals
    WB_WBS_O : out wbs_o_type;          -- Wishbone slave output signals
    -- register interface
    WB_REG_I : in  t_wb_reg_rd;         -- registers to read
    WB_REG_O : out t_wb_reg_wr          -- registers to write
    );

end ws_gpio_loopback;

architecture str of ws_gpio_loopback is

  signal s_wbs_reg_i : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Read registers
  signal s_wbs_reg_o : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Write registers


begin

  -- Read and write registers to be passed to the wishbone register module
  p_wishbone_data : process (WB_REG_I, s_wbs_reg_o) is
  begin  -- process p_wishbone_data
    s_wbs_reg_i                               <= (others => (others => '0'));
    -- Read
    s_wbs_reg_i(WB_ADD'pos(smaJ21J22Error))   <= std_logic_vector(WB_REG_I.smaErrorCnt);
    s_wbs_reg_i(WB_ADD'pos(headerJ13_0Error)) <= std_logic_vector(WB_REG_I.headerJ13ErrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(headerJ13_1Error)) <= std_logic_vector(WB_REG_I.headerJ13ErrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(headerJ13_2Error)) <= std_logic_vector(WB_REG_I.headerJ13ErrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(headerJ13_3Error)) <= std_logic_vector(WB_REG_I.headerJ13ErrorCnt(3));
    s_wbs_reg_i(WB_ADD'pos(headerJ13_4Error)) <= std_logic_vector(WB_REG_I.headerJ13ErrorCnt(4));

    s_wbs_reg_i(WB_ADD'pos(PA3headerJ14_0Error)) <= std_logic_vector(WB_REG_I.PA3headerJ14ErrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(PA3headerJ14_1Error)) <= std_logic_vector(WB_REG_I.PA3headerJ14ErrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(PA3headerJ14_2Error)) <= std_logic_vector(WB_REG_I.PA3headerJ14ErrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(PA3headerJ14_3Error)) <= std_logic_vector(WB_REG_I.PA3headerJ14ErrorCnt(3));
    s_wbs_reg_i(WB_ADD'pos(PA3headerJ14_4Error)) <= std_logic_vector(WB_REG_I.PA3headerJ14ErrorCnt(4));

    s_wbs_reg_i(WB_ADD'pos(pa3_0Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(pa3_1Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(pa3_2Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(pa3_3Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(3));
    s_wbs_reg_i(WB_ADD'pos(pa3_4Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(4));
    s_wbs_reg_i(WB_ADD'pos(pa3_5Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(5));
    s_wbs_reg_i(WB_ADD'pos(pa3_6Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(6));
    s_wbs_reg_i(WB_ADD'pos(pa3_7Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(7));
    s_wbs_reg_i(WB_ADD'pos(pa3_8Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(8));
    s_wbs_reg_i(WB_ADD'pos(pa3_9Error))  <= std_logic_vector(WB_REG_I.pa3ErrorCnt(9));

    s_wbs_reg_i(WB_ADD'pos(DCTRL_0Error)) <= std_logic_vector(WB_REG_I.DCTRLerrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(DCTRL_1Error)) <= std_logic_vector(WB_REG_I.DCTRLerrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(DCTRL_2Error)) <= std_logic_vector(WB_REG_I.DCTRLerrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(DCTRL_3Error)) <= std_logic_vector(WB_REG_I.DCTRLerrorCnt(3));
    s_wbs_reg_i(WB_ADD'pos(DCTRL_4Error)) <= std_logic_vector(WB_REG_I.DCTRLerrorCnt(4));

    s_wbs_reg_i(WB_ADD'pos(DCLKB_0Error)) <= std_logic_vector(WB_REG_I.DCLKbErrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(DCLKB_1Error)) <= std_logic_vector(WB_REG_I.DCLKbErrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(DCLKB_2Error)) <= std_logic_vector(WB_REG_I.DCLKbErrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(DCLKB_3Error)) <= std_logic_vector(WB_REG_I.DCLKbErrorCnt(3));
    s_wbs_reg_i(WB_ADD'pos(DCLKB_4Error)) <= std_logic_vector(WB_REG_I.DCLKbErrorCnt(4));

    s_wbs_reg_i(WB_ADD'pos(DCLKC_0Error)) <= std_logic_vector(WB_REG_I.DCLKCErrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(DCLKC_1Error)) <= std_logic_vector(WB_REG_I.DCLKCErrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(DCLKC_2Error)) <= std_logic_vector(WB_REG_I.DCLKCErrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(DCLKC_3Error)) <= std_logic_vector(WB_REG_I.DCLKCErrorCnt(3));
    s_wbs_reg_i(WB_ADD'pos(DCLKC_4Error)) <= std_logic_vector(WB_REG_I.DCLKCErrorCnt(4));

    s_wbs_reg_i(WB_ADD'pos(aux_0Error)) <= std_logic_vector(WB_REG_I.auxErrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(aux_1Error)) <= std_logic_vector(WB_REG_I.auxErrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(aux_2Error)) <= std_logic_vector(WB_REG_I.auxErrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(aux_3Error)) <= std_logic_vector(WB_REG_I.auxErrorCnt(3));

    s_wbs_reg_i(WB_ADD'pos(pu_0Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(0));
    s_wbs_reg_i(WB_ADD'pos(pu_1Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(1));
    s_wbs_reg_i(WB_ADD'pos(pu_2Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(2));
    s_wbs_reg_i(WB_ADD'pos(pu_3Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(3));
    s_wbs_reg_i(WB_ADD'pos(pu_4Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(4));
    s_wbs_reg_i(WB_ADD'pos(pu_5Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(5));
    s_wbs_reg_i(WB_ADD'pos(pu_6Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(6));
    s_wbs_reg_i(WB_ADD'pos(pu_7Error)) <= std_logic_vector(WB_REG_I.puErrorCnt(7));

    -- Write

    -- Write feedback
    s_wbs_reg_i(WB_ADD'pos(loopbackCTRL)) <= s_wbs_reg_o(WB_ADD'pos(loopbackCTRL));
  end process p_wishbone_data;

  process(WB_CLK)
  begin
    if rising_edge(WB_CLK) then
      WB_REG_O.clearError   <= s_wbs_reg_o(WB_ADD'pos(clearError));
      WB_REG_O.injectError  <= s_wbs_reg_o(WB_ADD'pos(injectError));
      WB_REG_O.loopbackCTRL <= s_wbs_reg_o(WB_ADD'pos(loopbackCTRL));
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Wishbone register handling
  -----------------------------------------------------------------------------
  INST_wishbone_slave_register : entity work.ws_reg
    generic map (
      WB_ADD_WE      => C_WB_ADD_WE,
      WB_ILLEGAL_VAL => x"DEAD",
      WB_REG_INIT    => C_WB_REG_DEFAULT
      )
    port map (
      WB_CLK    => WB_CLK,
      WB_RST    => WB_RST,
      WB_WBS_I  => WB_WBS_I,
      WB_WBS_O  => WB_WBS_O,
      WBS_REG_I => s_wbs_reg_i,
      WBS_REG_O => s_wbs_reg_o
      );

end architecture str;

