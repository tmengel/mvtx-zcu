-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
-- Date        : Tue Feb  6 01:15:58 2018
-- Host        : PCEPAIDVELURE running 64-bit Service Pack 1  (build 7601)
-- Command     : write_vhdl -force -mode funcsim
--               E:/proj/RUv1_Test_AV_dev/modules/wishbone/source/ip/system_management_wiz_0/system_management_wiz_0_sim_netlist.vhdl
-- Design      : system_management_wiz_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xcku060-ffva1156-1-c
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_management_wiz_0_system_management_wiz_0_sysmon is
  port (
    daddr_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    den_in : in STD_LOGIC;
    di_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dwe_in : in STD_LOGIC;
    do_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drdy_out : out STD_LOGIC;
    dclk_in : in STD_LOGIC;
    reset_in : in STD_LOGIC;
    vp : in STD_LOGIC;
    vn : in STD_LOGIC;
    busy_out : out STD_LOGIC;
    channel_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    eoc_out : out STD_LOGIC;
    eos_out : out STD_LOGIC;
    ot_out : out STD_LOGIC;
    user_supply1_alarm_out : out STD_LOGIC;
    user_supply0_alarm_out : out STD_LOGIC;
    alarm_out : out STD_LOGIC
  );
  attribute ORIG_REF_NAME : string;
  attribute ORIG_REF_NAME of system_management_wiz_0_system_management_wiz_0_sysmon : entity is "system_management_wiz_0_sysmon";
end system_management_wiz_0_system_management_wiz_0_sysmon;

architecture STRUCTURE of system_management_wiz_0_system_management_wiz_0_sysmon is
  signal NLW_inst_sysmon_I2C_SCLK_TS_UNCONNECTED : STD_LOGIC;
  signal NLW_inst_sysmon_I2C_SDA_TS_UNCONNECTED : STD_LOGIC;
  signal NLW_inst_sysmon_JTAGBUSY_UNCONNECTED : STD_LOGIC;
  signal NLW_inst_sysmon_JTAGLOCKED_UNCONNECTED : STD_LOGIC;
  signal NLW_inst_sysmon_JTAGMODIFIED_UNCONNECTED : STD_LOGIC;
  signal NLW_inst_sysmon_ALM_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_inst_sysmon_MUXADDR_UNCONNECTED : STD_LOGIC_VECTOR ( 4 downto 0 );
  signal NLW_inst_sysmon_VAUXN_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal NLW_inst_sysmon_VAUXP_UNCONNECTED : STD_LOGIC_VECTOR ( 15 downto 0 );
  attribute box_type : string;
  attribute box_type of inst_sysmon : label is "PRIMITIVE";
begin
inst_sysmon: unisim.vcomponents.SYSMONE1
    generic map(
      INIT_40 => X"3000",
      INIT_41 => X"21DE",
      INIT_42 => X"1F00",
      INIT_43 => X"200C",
      INIT_44 => X"0000",
      INIT_45 => X"DE0C",
      INIT_46 => X"0003",
      INIT_47 => X"0003",
      INIT_48 => X"4701",
      INIT_49 => X"0000",
      INIT_4A => X"4700",
      INIT_4B => X"0000",
      INIT_4C => X"0000",
      INIT_4D => X"0000",
      INIT_4E => X"0000",
      INIT_4F => X"0000",
      INIT_50 => X"B723",
      INIT_51 => X"4E81",
      INIT_52 => X"A147",
      INIT_53 => X"BC33",
      INIT_54 => X"AA5F",
      INIT_55 => X"4963",
      INIT_56 => X"9555",
      INIT_57 => X"AF7B",
      INIT_58 => X"4E81",
      INIT_59 => X"5555",
      INIT_5A => X"9999",
      INIT_5B => X"6AAA",
      INIT_5C => X"4963",
      INIT_5D => X"5111",
      INIT_5E => X"91EB",
      INIT_5F => X"6666",
      INIT_60 => X"93D6",
      INIT_61 => X"8665",
      INIT_62 => X"9A74",
      INIT_63 => X"4D39",
      INIT_64 => X"0000",
      INIT_65 => X"0000",
      INIT_66 => X"0000",
      INIT_67 => X"0000",
      INIT_68 => X"85C1",
      INIT_69 => X"7999",
      INIT_6A => X"98BF",
      INIT_6B => X"4C5E",
      INIT_6C => X"0000",
      INIT_6D => X"0000",
      INIT_6E => X"0000",
      INIT_6F => X"0000",
      INIT_70 => X"0000",
      INIT_71 => X"0000",
      INIT_72 => X"0000",
      INIT_73 => X"0000",
      INIT_74 => X"0000",
      INIT_75 => X"0000",
      INIT_76 => X"0000",
      INIT_77 => X"0000",
      INIT_78 => X"0000",
      INIT_79 => X"0000",
      INIT_7A => X"0000",
      INIT_7B => X"0000",
      INIT_7C => X"0000",
      INIT_7D => X"0000",
      INIT_7E => X"0000",
      INIT_7F => X"0000",
      IS_CONVSTCLK_INVERTED => '0',
      IS_DCLK_INVERTED => '0',
      SIM_MONITOR_FILE => "design.dat",
      SYSMON_VUSER0_BANK => 64,
      SYSMON_VUSER0_MONITOR => "VCCO_TOP",
      SYSMON_VUSER1_BANK => 67,
      SYSMON_VUSER1_MONITOR => "VCCO",
      SYSMON_VUSER2_BANK => 0,
      SYSMON_VUSER2_MONITOR => "NONE",
      SYSMON_VUSER3_BANK => 0,
      SYSMON_VUSER3_MONITOR => "NONE"
    )
        port map (
      ALM(15 downto 10) => NLW_inst_sysmon_ALM_UNCONNECTED(15 downto 10),
      ALM(9) => user_supply1_alarm_out,
      ALM(8) => user_supply0_alarm_out,
      ALM(7) => alarm_out,
      ALM(6 downto 0) => NLW_inst_sysmon_ALM_UNCONNECTED(6 downto 0),
      BUSY => busy_out,
      CHANNEL(5 downto 0) => channel_out(5 downto 0),
      CONVST => '0',
      CONVSTCLK => '0',
      DADDR(7 downto 0) => daddr_in(7 downto 0),
      DCLK => dclk_in,
      DEN => den_in,
      DI(15 downto 0) => di_in(15 downto 0),
      DO(15 downto 0) => do_out(15 downto 0),
      DRDY => drdy_out,
      DWE => dwe_in,
      EOC => eoc_out,
      EOS => eos_out,
      I2C_SCLK => '0',
      I2C_SCLK_TS => NLW_inst_sysmon_I2C_SCLK_TS_UNCONNECTED,
      I2C_SDA => '0',
      I2C_SDA_TS => NLW_inst_sysmon_I2C_SDA_TS_UNCONNECTED,
      JTAGBUSY => NLW_inst_sysmon_JTAGBUSY_UNCONNECTED,
      JTAGLOCKED => NLW_inst_sysmon_JTAGLOCKED_UNCONNECTED,
      JTAGMODIFIED => NLW_inst_sysmon_JTAGMODIFIED_UNCONNECTED,
      MUXADDR(4 downto 0) => NLW_inst_sysmon_MUXADDR_UNCONNECTED(4 downto 0),
      OT => ot_out,
      RESET => reset_in,
      VAUXN(15 downto 0) => NLW_inst_sysmon_VAUXN_UNCONNECTED(15 downto 0),
      VAUXP(15 downto 0) => NLW_inst_sysmon_VAUXP_UNCONNECTED(15 downto 0),
      VN => vn,
      VP => vp
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity system_management_wiz_0 is
  port (
    daddr_in : in STD_LOGIC_VECTOR ( 7 downto 0 );
    den_in : in STD_LOGIC;
    di_in : in STD_LOGIC_VECTOR ( 15 downto 0 );
    dwe_in : in STD_LOGIC;
    do_out : out STD_LOGIC_VECTOR ( 15 downto 0 );
    drdy_out : out STD_LOGIC;
    dclk_in : in STD_LOGIC;
    reset_in : in STD_LOGIC;
    busy_out : out STD_LOGIC;
    channel_out : out STD_LOGIC_VECTOR ( 5 downto 0 );
    eoc_out : out STD_LOGIC;
    eos_out : out STD_LOGIC;
    ot_out : out STD_LOGIC;
    user_supply1_alarm_out : out STD_LOGIC;
    user_supply0_alarm_out : out STD_LOGIC;
    alarm_out : out STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of system_management_wiz_0 : entity is true;
end system_management_wiz_0;

architecture STRUCTURE of system_management_wiz_0 is
begin
U0: entity work.system_management_wiz_0_system_management_wiz_0_sysmon
     port map (
      alarm_out => alarm_out,
      busy_out => busy_out,
      channel_out(5 downto 0) => channel_out(5 downto 0),
      daddr_in(7 downto 0) => daddr_in(7 downto 0),
      dclk_in => dclk_in,
      den_in => den_in,
      di_in(15 downto 0) => di_in(15 downto 0),
      do_out(15 downto 0) => do_out(15 downto 0),
      drdy_out => drdy_out,
      dwe_in => dwe_in,
      eoc_out => eoc_out,
      eos_out => eos_out,
      ot_out => ot_out,
      reset_in => reset_in,
      user_supply0_alarm_out => user_supply0_alarm_out,
      user_supply1_alarm_out => user_supply1_alarm_out,
      vn => '0',
      vp => '0'
    );
end STRUCTURE;
