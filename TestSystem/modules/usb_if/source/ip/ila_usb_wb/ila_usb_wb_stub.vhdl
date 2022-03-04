-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.4 (lin64) Build 1733598 Wed Dec 14 22:35:42 MST 2016
-- Date        : Mon Feb  6 17:00:51 2017
-- Host        : pcitsupgrade4.cern.ch running 64-bit CentOS Linux release 7.3.1611 (Core)
-- Command     : write_vhdl -force -mode synth_stub
--               /afs/cern.ch/work/m/mbonora/private/git/test_itswp10/clean_checkout/firmware/RUv0a/source/ip/ila_usb_wb/ila_usb_wb_stub.vhdl
-- Design      : ila_usb_wb
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ila_usb_wb is
  Port ( 
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe1 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe2 : in STD_LOGIC_VECTOR ( 15 downto 0 );
    probe3 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe4 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe5 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe6 : in STD_LOGIC_VECTOR ( 0 to 0 );
    probe7 : in STD_LOGIC_VECTOR ( 0 to 0 )
  );

end ila_usb_wb;

architecture stub of ila_usb_wb is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe0[15:0],probe1[15:0],probe2[15:0],probe3[0:0],probe4[0:0],probe5[0:0],probe6[0:0],probe7[0:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "ila,Vivado 2016.4";
begin
end;
