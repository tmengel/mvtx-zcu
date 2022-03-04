-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
-- Date        : Fri Jul 16 13:50:30 2021
-- Host        : pc0127025.ornl.gov running 64-bit CentOS Linux release 7.9.2009 (Core)
-- Command     : write_vhdl -force -mode synth_stub
--               /home/yj6/ALICE/TestSystem/modules/mgt_test/source/ip/gtwizard_ultrascale_0/gtwizard_ultrascale_0_stub.vhdl
-- Design      : gtwizard_ultrascale_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcku060-ffva1156-1-c
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity gtwizard_ultrascale_0 is
  Port ( 
    gtwiz_userclk_tx_active_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userclk_rx_active_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_clk_freerun_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_all_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_pll_and_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_pll_and_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_datapath_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_cdr_stable_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_tx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_reset_rx_done_out : out STD_LOGIC_VECTOR ( 0 to 0 );
    gtwiz_userdata_tx_in : in STD_LOGIC_VECTOR ( 447 downto 0 );
    gtwiz_userdata_rx_out : out STD_LOGIC_VECTOR ( 447 downto 0 );
    gtrefclk01_in : in STD_LOGIC_VECTOR ( 6 downto 0 );
    qpll1outclk_out : out STD_LOGIC_VECTOR ( 6 downto 0 );
    qpll1outrefclk_out : out STD_LOGIC_VECTOR ( 6 downto 0 );
    drpaddr_in : in STD_LOGIC_VECTOR ( 251 downto 0 );
    drpclk_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    drpdi_in : in STD_LOGIC_VECTOR ( 447 downto 0 );
    drpen_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    drpwe_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    gthrxn_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    gthrxp_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    rxprbscntreset_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    rxprbssel_in : in STD_LOGIC_VECTOR ( 111 downto 0 );
    rxusrclk_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    rxusrclk2_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    txprbsforceerr_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    txprbssel_in : in STD_LOGIC_VECTOR ( 111 downto 0 );
    txusrclk_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    txusrclk2_in : in STD_LOGIC_VECTOR ( 27 downto 0 );
    drpdo_out : out STD_LOGIC_VECTOR ( 447 downto 0 );
    drprdy_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    gthtxn_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    gthtxp_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    gtpowergood_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    rxoutclk_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    rxpmaresetdone_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    rxprbserr_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    rxprbslocked_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    txoutclk_out : out STD_LOGIC_VECTOR ( 27 downto 0 );
    txpmaresetdone_out : out STD_LOGIC_VECTOR ( 27 downto 0 )
  );

end gtwizard_ultrascale_0;

architecture stub of gtwizard_ultrascale_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "gtwiz_userclk_tx_active_in[0:0],gtwiz_userclk_rx_active_in[0:0],gtwiz_reset_clk_freerun_in[0:0],gtwiz_reset_all_in[0:0],gtwiz_reset_tx_pll_and_datapath_in[0:0],gtwiz_reset_tx_datapath_in[0:0],gtwiz_reset_rx_pll_and_datapath_in[0:0],gtwiz_reset_rx_datapath_in[0:0],gtwiz_reset_rx_cdr_stable_out[0:0],gtwiz_reset_tx_done_out[0:0],gtwiz_reset_rx_done_out[0:0],gtwiz_userdata_tx_in[447:0],gtwiz_userdata_rx_out[447:0],gtrefclk01_in[6:0],qpll1outclk_out[6:0],qpll1outrefclk_out[6:0],drpaddr_in[251:0],drpclk_in[27:0],drpdi_in[447:0],drpen_in[27:0],drpwe_in[27:0],gthrxn_in[27:0],gthrxp_in[27:0],rxprbscntreset_in[27:0],rxprbssel_in[111:0],rxusrclk_in[27:0],rxusrclk2_in[27:0],txprbsforceerr_in[27:0],txprbssel_in[111:0],txusrclk_in[27:0],txusrclk2_in[27:0],drpdo_out[447:0],drprdy_out[27:0],gthtxn_out[27:0],gthtxp_out[27:0],gtpowergood_out[27:0],rxoutclk_out[27:0],rxpmaresetdone_out[27:0],rxprbserr_out[27:0],rxprbslocked_out[27:0],txoutclk_out[27:0],txpmaresetdone_out[27:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "gtwizard_ultrascale_0_gtwizard_top,Vivado 2020.2";
begin
end;
