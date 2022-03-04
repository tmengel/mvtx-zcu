-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
-- Date        : Tue Dec 18 11:40:59 2018
-- Host        : pisces running 64-bit Ubuntu 18.04.1 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/jschamba/ALICE/TestSystem/modules/mgt_test/source/ip/gtwizard_ultrascale_0_vio_0/gtwizard_ultrascale_0_vio_0_stub.vhdl
-- Design      : gtwizard_ultrascale_0_vio_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku060-ffva1156-1-c
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity gtwizard_ultrascale_0_vio_0 is
  Port ( 
    clk : in STD_LOGIC;
    probe_in0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in1 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in2 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in3 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe_in4 : in STD_LOGIC_VECTOR ( 27 downto 0 );
    probe_in5 : in STD_LOGIC_VECTOR ( 27 downto 0 );
    probe_in6 : in STD_LOGIC_VECTOR ( 27 downto 0 );
    probe_in7 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in8 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe_in9 : in STD_LOGIC_VECTOR ( 27 downto 0 );
    probe_in10 : in STD_LOGIC_VECTOR ( 27 downto 0 );
    probe_out0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    probe_out1 : out STD_LOGIC_VECTOR ( 0 to 0 );
    probe_out2 : out STD_LOGIC_VECTOR ( 0 to 0 );
    probe_out3 : out STD_LOGIC_VECTOR ( 0 to 0 );
    probe_out4 : out STD_LOGIC_VECTOR ( 111 downto 0 );
    probe_out5 : out STD_LOGIC_VECTOR ( 27 downto 0 )
  );

end gtwizard_ultrascale_0_vio_0;

architecture stub of gtwizard_ultrascale_0_vio_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe_in0[0:0],probe_in1[0:0],probe_in2[0:0],probe_in3[3:0],probe_in4[27:0],probe_in5[27:0],probe_in6[27:0],probe_in7[0:0],probe_in8[0:0],probe_in9[27:0],probe_in10[27:0],probe_out0[0:0],probe_out1[0:0],probe_out2[0:0],probe_out3[0:0],probe_out4[111:0],probe_out5[27:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "vio,Vivado 2018.3";
begin
end;
