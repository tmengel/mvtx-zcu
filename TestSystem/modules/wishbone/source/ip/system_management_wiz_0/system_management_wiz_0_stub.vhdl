-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
-- Date        : Thu Jan 25 19:19:30 2018
-- Host        : PCEPAIDVELURE running 64-bit Service Pack 1  (build 7601)
-- Command     : write_vhdl -force -mode synth_stub
--               E:/prog/gitlab-runner/builds/4d6b20e9/0/alice-its-wp10-firmware/RUv1_Test/modules/wishbone/source/ip/system_management_wiz_0/system_management_wiz_0_stub.vhdl
-- Design      : system_management_wiz_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku060-ffva1156-1-c
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity system_management_wiz_0 is
  Port ( 
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

end system_management_wiz_0;

architecture stub of system_management_wiz_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "daddr_in[7:0],den_in,di_in[15:0],dwe_in,do_out[15:0],drdy_out,dclk_in,reset_in,busy_out,channel_out[5:0],eoc_out,eos_out,ot_out,user_supply1_alarm_out,user_supply0_alarm_out,alarm_out";
begin
end;
