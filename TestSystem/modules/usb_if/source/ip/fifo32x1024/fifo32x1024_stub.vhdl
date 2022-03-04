-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
-- Date        : Fri Jul 16 13:51:56 2021
-- Host        : pc0127025.ornl.gov running 64-bit CentOS Linux release 7.9.2009 (Core)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/yj6/ALICE/TestSystem/modules/usb_if/source/ip/fifo32x1024/fifo32x1024_stub.vhdl
-- Design      : fifo32x1024
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku060-ffva1156-1-c
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo32x1024 is
  Port ( 
    rst : in STD_LOGIC;
    wr_clk : in STD_LOGIC;
    rd_clk : in STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    dout : out STD_LOGIC_VECTOR ( 31 downto 0 );
    full : out STD_LOGIC;
    almost_full : out STD_LOGIC;
    empty : out STD_LOGIC;
    almost_empty : out STD_LOGIC
  );

end fifo32x1024;

architecture stub of fifo32x1024 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,dout[31:0],full,almost_full,empty,almost_empty";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v13_2_5,Vivado 2020.2";
begin
end;
