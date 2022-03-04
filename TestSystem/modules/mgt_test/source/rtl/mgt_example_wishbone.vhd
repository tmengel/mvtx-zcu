-------------------------------------------------------------------------------
-- Title      : MGT Example Wishbone
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mgt_example_wishbone.vhd
-- Author     : Joachim Schambach  <jschamba@pisces.rhip.utexas.edu>
-- Company    : University of Texas at Austin
-- Created    : 2018-06-06
-- Last update: 2018-06-07
-- Platform   : Vivado 2017.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone interface for MGT example test
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
use work.mgt_example_pkg.all;

entity mgt_example_wishbone is
  port (
    WB_CLK           : in  std_logic;
    WB_RST           : in  std_logic;
    WB_WBS_I         : in  wbs_i_type;
    WB_WBS_O         : out wbs_o_type;
    --
    -- MGT example interface
    WB_REGISTERS_in  : in  t_wishbone_registers_i;
    WB_REGISTERS_out : out t_wishbone_registers_o
    );
end entity mgt_example_wishbone;

architecture structural of mgt_example_wishbone is

  -- wishbone
  signal s_wishbone_registers_o : t_wishbone_registers_o;

  signal s_wbs_reg_i : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Read registers
  signal s_wbs_reg_o : t_wbs_reg_array(WB_ADD'pos(WB_ADD'high) downto 0);  -- Write registers

begin  -- architecture structural

  -- assign  outputs
  WB_REGISTERS_out <= s_wishbone_registers_o;

  p_wishbone_data : process (WB_REGISTERS_in, s_wbs_reg_o,
                             s_wishbone_registers_o) is
  begin  -- process p_wishbone_data
    s_wbs_reg_i <= (others => x"0000");  -- initialize all bits to 0

    -- Read
    s_wbs_reg_i(WB_ADD'pos(A_STATUS))          <= wb_resize(WB_REGISTERS_in.status);
    s_wbs_reg_i(WB_ADD'pos(A_INIT_RTRY_CTR))   <= wb_resize(WB_REGISTERS_in.init_retry_ctr);
    s_wbs_reg_i(WB_ADD'pos(A_POWERGOOD_LSB))   <= WB_REGISTERS_in.powergood(15 downto 0);
    s_wbs_reg_i(WB_ADD'pos(A_POWERGOOD_MSB))   <= x"0" & WB_REGISTERS_in.powergood(27 downto 16);
    s_wbs_reg_i(WB_ADD'pos(A_PMARST_DONE_LSB)) <= WB_REGISTERS_in.pmareset_done(15 downto 0);
    s_wbs_reg_i(WB_ADD'pos(A_PMARST_DONE_MSB)) <= x"0" & WB_REGISTERS_in.pmareset_done(27 downto 16);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_ERR_LSB))    <= WB_REGISTERS_in.prbs_err(15 downto 0);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_ERR_MSB))    <= x"0" & WB_REGISTERS_in.prbs_err(27 downto 16);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_LOCKED_LSB)) <= WB_REGISTERS_in.prbs_locked(15 downto 0);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_LOCKED_MSB)) <= x"0" & WB_REGISTERS_in.prbs_locked(27 downto 16);

    -- Write
    s_wishbone_registers_o.resets                       <= s_wbs_reg_o(WB_ADD'pos(A_RESET))(4 downto 0);
    s_wishbone_registers_o.enable_err                   <= s_wbs_reg_o(WB_ADD'pos(A_ENABLE_ERRORS))(C_ENABLE_ERRORS_bit);
    s_wishbone_registers_o.prbs_ctr_reset(15 downto 0)  <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_CTR_RST_LSB));
    s_wishbone_registers_o.prbs_ctr_reset(27 downto 16) <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_CTR_RST_MSB))(11 downto 0);
    s_wishbone_registers_o.prbssel(3 downto 0)          <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL00))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(7 downto 4)          <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL01))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(11 downto 8)         <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL02))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(15 downto 12)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL03))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(19 downto 16)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL04))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(23 downto 20)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL05))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(27 downto 24)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL06))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(31 downto 28)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL07))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(35 downto 32)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL08))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(39 downto 36)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL09))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(43 downto 40)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL10))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(47 downto 44)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL11))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(51 downto 48)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL12))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(55 downto 52)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL13))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(59 downto 56)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL14))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(63 downto 60)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL15))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(67 downto 64)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL16))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(71 downto 68)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL17))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(75 downto 72)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL18))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(79 downto 76)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL19))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(83 downto 80)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL20))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(87 downto 84)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL21))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(91 downto 88)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL22))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(95 downto 92)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL23))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(99 downto 96)        <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL24))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(103 downto 100)      <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL25))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(107 downto 104)      <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL26))(C_PRBS_SEL_DEFAULT'range);
    s_wishbone_registers_o.prbssel(111 downto 108)      <= s_wbs_reg_o(WB_ADD'pos(A_PRBS_SEL27))(C_PRBS_SEL_DEFAULT'range);



    -- Write feedback
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL00))    <= x"000" & s_wishbone_registers_o.prbssel(3 downto 0);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL01))    <= x"000" & s_wishbone_registers_o.prbssel(7 downto 4);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL02))    <= x"000" & s_wishbone_registers_o.prbssel(11 downto 8);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL03))    <= x"000" & s_wishbone_registers_o.prbssel(15 downto 12);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL04))    <= x"000" & s_wishbone_registers_o.prbssel(19 downto 16);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL05))    <= x"000" & s_wishbone_registers_o.prbssel(23 downto 20);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL06))    <= x"000" & s_wishbone_registers_o.prbssel(27 downto 24);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL07))    <= x"000" & s_wishbone_registers_o.prbssel(31 downto 28);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL08))    <= x"000" & s_wishbone_registers_o.prbssel(35 downto 32);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL09))    <= x"000" & s_wishbone_registers_o.prbssel(39 downto 36);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL10))    <= x"000" & s_wishbone_registers_o.prbssel(43 downto 40);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL11))    <= x"000" & s_wishbone_registers_o.prbssel(47 downto 44);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL12))    <= x"000" & s_wishbone_registers_o.prbssel(51 downto 48);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL13))    <= x"000" & s_wishbone_registers_o.prbssel(55 downto 52);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL14))    <= x"000" & s_wishbone_registers_o.prbssel(59 downto 56);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL15))    <= x"000" & s_wishbone_registers_o.prbssel(63 downto 60);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL16))    <= x"000" & s_wishbone_registers_o.prbssel(67 downto 64);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL17))    <= x"000" & s_wishbone_registers_o.prbssel(71 downto 68);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL18))    <= x"000" & s_wishbone_registers_o.prbssel(75 downto 72);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL19))    <= x"000" & s_wishbone_registers_o.prbssel(79 downto 76);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL20))    <= x"000" & s_wishbone_registers_o.prbssel(83 downto 80);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL21))    <= x"000" & s_wishbone_registers_o.prbssel(87 downto 84);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL22))    <= x"000" & s_wishbone_registers_o.prbssel(91 downto 88);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL23))    <= x"000" & s_wishbone_registers_o.prbssel(95 downto 92);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL24))    <= x"000" & s_wishbone_registers_o.prbssel(99 downto 96);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL25))    <= x"000" & s_wishbone_registers_o.prbssel(103 downto 100);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL26))    <= x"000" & s_wishbone_registers_o.prbssel(107 downto 104);
    s_wbs_reg_i(WB_ADD'pos(A_PRBS_SEL27))    <= x"000" & s_wishbone_registers_o.prbssel(111 downto 108);
    s_wbs_reg_i(WB_ADD'pos(A_ENABLE_ERRORS)) <= wb_resize_bit(s_wishbone_registers_o.enable_err, C_ENABLE_ERRORS_bit);
    -- all others are "pulsed" (set to 0 when not written to)

  end process p_wishbone_data;

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


end architecture structural;
