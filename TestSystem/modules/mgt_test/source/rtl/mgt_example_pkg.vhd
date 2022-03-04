-------------------------------------------------------------------------------
-- Title      : MGT Example Wishbone Package
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mgt_example_pkg.vhd
-- Author     : Joachim Schambach  <jschamba@pisces.rhip.utexas.edu>
-- Company    : University of Texas at Austin
-- Created    : 2018-06-06
-- Last update: 2021-07-16
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone definitions for MGT example test
-------------------------------------------------------------------------------
-- Copyright (c) 2018 University of Texas at Austin
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018-06-06  1.0      jschamba  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.intercon_pkg.all;

package mgt_example_pkg is

  type WB_ADD is (
    -- write
    A_PRBS_SEL00,                       -- 0
    A_PRBS_SEL01,                       -- 1
    A_PRBS_SEL02,                       -- 2
    A_PRBS_SEL03,                       -- 3
    A_PRBS_SEL04,                       -- 4
    A_PRBS_SEL05,                       -- 5
    A_PRBS_SEL06,                       -- 6
    A_PRBS_SEL07,                       -- 7
    A_PRBS_SEL08,                       -- 8
    A_PRBS_SEL09,                       -- 9
    A_PRBS_SEL10,                       -- 10
    A_PRBS_SEL11,                       -- 11
    A_PRBS_SEL12,                       -- 12
    A_PRBS_SEL13,                       -- 13
    A_PRBS_SEL14,                       -- 14
    A_PRBS_SEL15,                       -- 15
    A_PRBS_SEL16,                       -- 16
    A_PRBS_SEL17,                       -- 17
    A_PRBS_SEL18,                       -- 18
    A_PRBS_SEL19,                       -- 19
    A_PRBS_SEL20,                       -- 20
    A_PRBS_SEL21,                       -- 21
    A_PRBS_SEL22,                       -- 22
    A_PRBS_SEL23,                       -- 23
    A_PRBS_SEL24,                       -- 24
    A_PRBS_SEL25,                       -- 25
    A_PRBS_SEL26,                       -- 26
    A_PRBS_SEL27,                       -- 27
    A_RESET,                            -- 28
    A_PRBS_CTR_RST_LSB,                 -- 29
    A_PRBS_CTR_RST_MSB,                 -- 30
    -- read
    A_STATUS,                           -- 31
    A_INIT_RTRY_CTR,                    -- 32
    A_POWERGOOD_LSB,                    -- 33
    A_POWERGOOD_MSB,                    -- 34
    A_PMARST_DONE_LSB,                  -- 35
    A_PMARST_DONE_MSB,                  -- 36
    A_PRBS_ERR_LSB,                     -- 37
    A_PRBS_ERR_MSB,                     -- 38
    A_PRBS_LOCKED_LSB,                  -- 39
    A_PRBS_LOCKED_MSB,                  -- 40
    A_ENABLE_ERRORS                     -- 41
    );

  -- Read/Write enable array
  constant C_WB_ADD_WE : t_wbs_reg_we_array(WB_ADD'pos(WB_ADD'high) downto 0) := (
    WB_ADD'pos(A_PRBS_SEL00)       => rw,
    WB_ADD'pos(A_PRBS_SEL01)       => rw,
    WB_ADD'pos(A_PRBS_SEL02)       => rw,
    WB_ADD'pos(A_PRBS_SEL03)       => rw,
    WB_ADD'pos(A_PRBS_SEL04)       => rw,
    WB_ADD'pos(A_PRBS_SEL05)       => rw,
    WB_ADD'pos(A_PRBS_SEL06)       => rw,
    WB_ADD'pos(A_PRBS_SEL07)       => rw,
    WB_ADD'pos(A_PRBS_SEL08)       => rw,
    WB_ADD'pos(A_PRBS_SEL09)       => rw,
    WB_ADD'pos(A_PRBS_SEL10)       => rw,
    WB_ADD'pos(A_PRBS_SEL11)       => rw,
    WB_ADD'pos(A_PRBS_SEL12)       => rw,
    WB_ADD'pos(A_PRBS_SEL13)       => rw,
    WB_ADD'pos(A_PRBS_SEL14)       => rw,
    WB_ADD'pos(A_PRBS_SEL15)       => rw,
    WB_ADD'pos(A_PRBS_SEL16)       => rw,
    WB_ADD'pos(A_PRBS_SEL17)       => rw,
    WB_ADD'pos(A_PRBS_SEL18)       => rw,
    WB_ADD'pos(A_PRBS_SEL19)       => rw,
    WB_ADD'pos(A_PRBS_SEL20)       => rw,
    WB_ADD'pos(A_PRBS_SEL21)       => rw,
    WB_ADD'pos(A_PRBS_SEL22)       => rw,
    WB_ADD'pos(A_PRBS_SEL23)       => rw,
    WB_ADD'pos(A_PRBS_SEL24)       => rw,
    WB_ADD'pos(A_PRBS_SEL25)       => rw,
    WB_ADD'pos(A_PRBS_SEL26)       => rw,
    WB_ADD'pos(A_PRBS_SEL27)       => rw,
    WB_ADD'pos(A_RESET)            => w,
    WB_ADD'pos(A_PRBS_CTR_RST_LSB) => w,
    WB_ADD'pos(A_PRBS_CTR_RST_MSB) => w,
    WB_ADD'pos(A_STATUS)           => r,
    WB_ADD'pos(A_INIT_RTRY_CTR)    => r,
    WB_ADD'pos(A_POWERGOOD_LSB)    => r,
    WB_ADD'pos(A_POWERGOOD_MSB)    => r,
    WB_ADD'pos(A_PMARST_DONE_LSB)  => r,
    WB_ADD'pos(A_PMARST_DONE_MSB)  => r,
    WB_ADD'pos(A_PRBS_ERR_LSB)     => r,
    WB_ADD'pos(A_PRBS_ERR_MSB)     => r,
    WB_ADD'pos(A_PRBS_LOCKED_LSB)  => r,
    WB_ADD'pos(A_PRBS_LOCKED_MSB)  => r,
    WB_ADD'pos(A_ENABLE_ERRORS)    => rw
    );

  -----------------------------------------------------------------------------
  -- wishbone default settings
  -----------------------------------------------------------------------------
  constant C_PRBS_SEL_DEFAULT  : std_logic_vector(3 downto 0) := x"1";
  constant C_ENABLE_ERRORS_bit : integer                      := 0;

  constant C_WB_REG_DEFAULT : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0) := (
    WB_ADD'pos(A_PRBS_SEL00) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL01) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL02) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL03) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL04) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL05) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL06) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL07) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL08) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL09) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL10) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL11) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL12) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL13) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL14) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL15) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL16) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL17) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL18) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL19) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL20) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL21) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL22) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL23) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL24) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL25) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL26) => wb_resize(C_PRBS_SEL_DEFAULT),
    WB_ADD'pos(A_PRBS_SEL27) => wb_resize(C_PRBS_SEL_DEFAULT),
    others                   => x"0000"
    );

  type t_wishbone_registers_i is record
    status         : std_logic_vector(3 downto 0);
    init_retry_ctr : std_logic_vector(3 downto 0);
    powergood      : std_logic_vector(27 downto 0);
    pmareset_done  : std_logic_vector(27 downto 0);
    prbs_err       : std_logic_vector(27 downto 0);
    prbs_locked    : std_logic_vector(27 downto 0);
  end record t_wishbone_registers_i;

  type t_wishbone_registers_o is record
    resets         : std_logic_vector(4 downto 0);
    prbssel        : std_logic_vector(111 downto 0);
    prbs_ctr_reset : std_logic_vector(27 downto 0);
    enable_err     : std_logic;
  end record t_wishbone_registers_o;

end package mgt_example_pkg;
