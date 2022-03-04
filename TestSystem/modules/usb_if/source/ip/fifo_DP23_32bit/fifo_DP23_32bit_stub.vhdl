-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
-- Date        : Sat Mar  3 12:01:42 2018
-- Host        : pisces running 64-bit Ubuntu Bionic Beaver (development branch)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/jschamba/ALICE/RUv1_Test_clean/modules/usb_if/source/ip/fifo_DP23_32bit/fifo_DP23_32bit_stub.vhdl
-- Design      : fifo_DP23_32bit
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku060-ffva1156-1-c
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_DP23_32bit is
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
    overflow : out STD_LOGIC;
    empty : out STD_LOGIC;
    almost_empty : out STD_LOGIC
  );

end fifo_DP23_32bit;

architecture stub of fifo_DP23_32bit is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,dout[31:0],full,almost_full,overflow,empty,almost_empty";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v13_2_1,Vivado 2017.4";
begin
end;
