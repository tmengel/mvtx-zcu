-- Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2015.4 (win64) Build 1412921 Wed Nov 18 09:43:45 MST 2015
-- Date        : Mon Sep 12 20:57:02 2016
-- Host        : KSIELEWIPC running 64-bit Service Pack 1  (build 7601)
-- Command     : write_vhdl -force -mode synth_stub P:/source/ip/tb_arr_mmcm/tb_arr_mmcm_stub.vhdl
-- Design      : tb_arr_mmcm
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_arr_mmcm is
  Port ( 
    clk_in1 : in STD_LOGIC;
    clk_out1 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC
  );

end tb_arr_mmcm;

architecture stub of tb_arr_mmcm is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_in1,clk_out1,reset,locked";
begin
end;
