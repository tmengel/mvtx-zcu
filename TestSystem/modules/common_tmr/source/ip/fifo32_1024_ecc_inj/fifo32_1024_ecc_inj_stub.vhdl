-- Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2015.4 (win64) Build 1412921 Wed Nov 18 09:43:45 MST 2015
-- Date        : Fri Oct 07 14:32:08 2016
-- Host        : KSIELEWIPC running 64-bit Service Pack 1  (build 7601)
-- Command     : write_vhdl -force -mode synth_stub p:/source/ip/fifo32_1024_ecc_inj/fifo32_1024_ecc_inj_stub.vhdl
-- Design      : fifo32_1024_ecc_inj
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo32_1024_ecc_inj is
  Port ( 
    rst : in STD_LOGIC;
    wr_clk : in STD_LOGIC;
    rd_clk : in STD_LOGIC;
    din : in STD_LOGIC_VECTOR ( 31 downto 0 );
    wr_en : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    injectdbiterr : in STD_LOGIC;
    injectsbiterr : in STD_LOGIC;
    dout : out STD_LOGIC_VECTOR ( 31 downto 0 );
    full : out STD_LOGIC;
    almost_full : out STD_LOGIC;
    empty : out STD_LOGIC;
    almost_empty : out STD_LOGIC;
    sbiterr : out STD_LOGIC;
    dbiterr : out STD_LOGIC
  );

end fifo32_1024_ecc_inj;

architecture stub of fifo32_1024_ecc_inj is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "rst,wr_clk,rd_clk,din[31:0],wr_en,rd_en,injectdbiterr,injectsbiterr,dout[31:0],full,almost_full,empty,almost_empty,sbiterr,dbiterr";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fifo_generator_v13_0_1,Vivado 2015.4";
begin
end;
