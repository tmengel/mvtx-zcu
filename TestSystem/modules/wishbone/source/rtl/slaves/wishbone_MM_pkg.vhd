-------------------------------------------------------------------------------
-- Title      : wishbone Memory Mapping
-- Project    : RUv0a
-------------------------------------------------------------------------------
-- File       : wishbone_MM.vhd
-- Author     : Matteo Lupi  <matteo.lupi@cern.ch>
-- Company    : CERN / Goethe Universitaet Frankfurt am Main
-- Created    : 2016-02-26
-- Last update: 2017-09-11
-- Platform   : Vivado 2105.04
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wishbone register memory mapping package.
--              Here all the registers are defined
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-02-26  1.0      mlupi   Created
-- 2016-02-29  2.1      ML      Added STS record as record of records (adc_type
--                              is the only available at the moment)
-- 2016-03-01           ML      Replaced TRIGGER with COMMAND, CNFG with CFG
-- 2016-03-01           ML      CFN ports are now WB_DATA_WIDTH-bit and
--                              connected on the destination block
-- 2016-03-01           ML      Added procedure to write on output bus used in
--                              ws_cfg_reg
-- 2016-03-08           ML      ADDB defined as record
-- 2016-04-06           ML MB   adapted to RUv0a
-- 2016-09-12           ML      Added STS bus for githash and date
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

-- Wishbone interface package
use work.intercon_pkg.all;

package wishbone_MM is

  -------------------------------------------
  -- Configuration Registers: block address defined above
  -------------------------------------------
  constant WS_CFG_NUM : integer := 13;   -- MAX 2**WB_ADDS_WIDTH

  type t_WS_ADDS_CFG is record
    delay_cnt   : integer;
    gbtx_cfg    : integer;
    testpattern : integer;
    bitslip     : integer;
  end record;

  -- Mapping internal to WS Status
  constant WS_ADDS_CFG : t_WS_ADDS_CFG := (delay_cnt   => 0,
                                           gbtx_cfg    => 10,
                                           testpattern => 11,
                                           bitslip     => 12
                                           );

  -- bit mapping of WS_CFG_switches
  constant WS_CFG_bit_gbtx_cfg : integer := 0;

  -- CFG BUS definition as record
  subtype t_sRegister_ws_cfg is std_logic_vector(WS_CFG_NUM*WB_DATA_WIDTH -1 downto 0);
  type t_gbt_delay_cnt is array (0 to 9) of std_logic_vector(8 downto 0);

  -- CFG_BUS_TYPE
  type t_cfg_bus is record
    delay_cnt   : t_gbt_delay_cnt;
    gbtx_cfg    : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    testpattern : std_logic_vector(1 downto 0);
    bitslip     : std_logic_vector(2 downto 0);
  end record;



  -------------------------------------------
  -- Status Registers: block address defined above
  -------------------------------------------
  constant WS_STS_NUM : integer := 5;   -- MAX 2**WB_ADDS_WIDTH

  type t_WS_ADDS_STS is record
    githash_lsb : integer;
    githash_msb : integer;
    date_llsb   : integer;
    date_lsb    : integer;
    date_msb    : integer;
  end record;

  -- Mapping internal to WS Status
  constant WS_ADDS_STS : t_WS_ADDS_STS := (githash_lsb => 0,
                                           githash_msb => 1,
                                           date_llsb   => 2,
                                           date_lsb    => 3,
                                           date_msb    => 4
                                           );

  -- STS BUS definition as record
  subtype t_sRegister_ws_sts is std_logic_vector(WS_STS_NUM*WB_DATA_WIDTH -1 downto 0);

  type t_githash is record
    lsb : std_logic_vector(WB_DATA_WIDTH -1 downto 0);
    msb : std_logic_vector(WB_DATA_WIDTH -1 downto 0);
  end record;

  type t_date is record
    llsb : std_logic_vector(WB_DATA_WIDTH -1 downto 0);
    lsb  : std_logic_vector(WB_DATA_WIDTH -1 downto 0);
    msb  : std_logic_vector(WB_DATA_WIDTH -1 downto 0);
  end record;

  -- STS_BUS_TYPE
  type t_sts_bus is record
    githash : t_githash;
    date    : t_date;
  end record;
  ---------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------
  -- PROCEDURES  DECLARATION
  ---------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------
  -- CFG
  ---------------------------------------------------------------------------------

  -- procedure invoked inside ws_cfg_reg.vhd to assign the sRegisters to the
  -- output bus, which is then sent out of the wishbone slave
  procedure proc_ws_cfg_wr2bus (
    constant sRegisters : in  t_sRegister_ws_cfg;
    signal busout       : out t_cfg_bus);

  function f_assign2bus (
    constant address    : integer;
    constant width      : integer;
    constant sRegisters : t_sRegister_ws_cfg)
    return std_logic_vector;

  ---------------------------------------------------------------------------------
  -- STS
  ---------------------------------------------------------------------------------

  -- procedure invoked inside ws_status_reg.vhd to assign the bus to the sRegisters,
  -- which are then read from the wb
  procedure proc_ws_sts_wrfrombus (
    signal sRegisters : out t_sRegister_ws_sts;
    constant busin    : in  t_sts_bus);

end package wishbone_MM;

-------------------------------------------------------------------------------------------------------------
-- #########################################################################################################
-------------------------------------------------------------------------------------------------------------

package body wishbone_MM is

  ---------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------
  -- PROCEDURES BODY
  ---------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- CFG
  ---------------------------------------------------------------------------

  -- function to assign the value to the bus to reduce overhead and increase
  -- readability of procedure
  function f_assign2bus (
    constant address    : integer;
    constant width      : integer;
    constant sRegisters : t_sRegister_ws_cfg)
    return std_logic_vector is
  begin  -- function f_assign2bus
    return sRegisters(address*WB_DATA_WIDTH + width-1 downto address*WB_DATA_WIDTH);
  end function f_assign2bus;

  procedure proc_ws_cfg_wr2bus (
    constant sRegisters : in  t_sRegister_ws_cfg;
    signal busout       : out t_cfg_bus) is
  begin
    for i in 0 to 9 loop
      busout.delay_cnt(i) <= f_assign2bus(WS_ADDS_CFG.delay_cnt+i, 9, sRegisters);
    end loop;
    busout.gbtx_cfg    <= f_assign2bus(WS_ADDS_CFG.gbtx_cfg, 16, sRegisters);
    busout.testpattern <= f_assign2bus(WS_ADDS_CFG.testpattern, 2, sRegisters);
    busout.bitslip     <= f_assign2bus(WS_ADDS_CFG.bitslip, 3, sRegisters);
  end procedure proc_ws_cfg_wr2bus;

  ---------------------------------------------------------------------------
  -- STS
  ---------------------------------------------------------------------------

  procedure proc_ws_sts_wrfrombus (
    signal sRegisters : out t_sRegister_ws_sts;
    constant busin    : in  t_sts_bus) is
  begin
                                        -- git hash
    sRegisters(WS_ADDS_STS.githash_lsb * WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto WS_ADDS_STS.githash_lsb * WB_DATA_WIDTH) <=
      busin.githash.lsb;
    sRegisters(WS_ADDS_STS.githash_msb * WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto WS_ADDS_STS.githash_msb * WB_DATA_WIDTH) <=
      busin.githash.msb;

                                        -- date
    sRegisters(WS_ADDS_STS.date_llsb * WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto WS_ADDS_STS.date_llsb * WB_DATA_WIDTH) <=
      busin.date.llsb;
    sRegisters(WS_ADDS_STS.date_lsb * WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto WS_ADDS_STS.date_lsb * WB_DATA_WIDTH) <=
      busin.date.lsb;
    sRegisters(WS_ADDS_STS.date_msb * WB_DATA_WIDTH + WB_DATA_WIDTH -1 downto WS_ADDS_STS.date_msb * WB_DATA_WIDTH) <=
      busin.date.msb;
  end procedure proc_ws_sts_wrfrombus;

end package body wishbone_MM;
