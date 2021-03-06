-- Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2016.4 (lin64) Build 1756540 Mon Jan 23 19:11:19 MST 2017
-- Date        : Tue Apr 18 15:23:40 2017
-- Host        : pcphaiddt001 running 64-bit CentOS Linux release 7.3.1611 (Core)
-- Command     : write_vhdl -force -mode synth_stub
--               /afs/cern.ch/work/m/mlupi/work/git/RUv0_radtest/modules/common_tmr/source/ip/SEM_IP/SEM_IP_stub.vhdl
-- Design      : SEM_IP
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7k325tffg900-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SEM_IP is
  Port ( 
    status_heartbeat : out STD_LOGIC;
    status_initialization : out STD_LOGIC;
    status_observation : out STD_LOGIC;
    status_correction : out STD_LOGIC;
    status_classification : out STD_LOGIC;
    status_injection : out STD_LOGIC;
    status_essential : out STD_LOGIC;
    status_uncorrectable : out STD_LOGIC;
    monitor_txdata : out STD_LOGIC_VECTOR ( 7 downto 0 );
    monitor_txwrite : out STD_LOGIC;
    monitor_txfull : in STD_LOGIC;
    monitor_rxdata : in STD_LOGIC_VECTOR ( 7 downto 0 );
    monitor_rxread : out STD_LOGIC;
    monitor_rxempty : in STD_LOGIC;
    inject_strobe : in STD_LOGIC;
    inject_address : in STD_LOGIC_VECTOR ( 39 downto 0 );
    icap_o : in STD_LOGIC_VECTOR ( 31 downto 0 );
    icap_csib : out STD_LOGIC;
    icap_rdwrb : out STD_LOGIC;
    icap_i : out STD_LOGIC_VECTOR ( 31 downto 0 );
    icap_clk : in STD_LOGIC;
    icap_request : out STD_LOGIC;
    icap_grant : in STD_LOGIC;
    fecc_crcerr : in STD_LOGIC;
    fecc_eccerr : in STD_LOGIC;
    fecc_eccerrsingle : in STD_LOGIC;
    fecc_syndromevalid : in STD_LOGIC;
    fecc_syndrome : in STD_LOGIC_VECTOR ( 12 downto 0 );
    fecc_far : in STD_LOGIC_VECTOR ( 25 downto 0 );
    fecc_synbit : in STD_LOGIC_VECTOR ( 4 downto 0 );
    fecc_synword : in STD_LOGIC_VECTOR ( 6 downto 0 )
  );

end SEM_IP;

architecture stub of SEM_IP is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "status_heartbeat,status_initialization,status_observation,status_correction,status_classification,status_injection,status_essential,status_uncorrectable,monitor_txdata[7:0],monitor_txwrite,monitor_txfull,monitor_rxdata[7:0],monitor_rxread,monitor_rxempty,inject_strobe,inject_address[39:0],icap_o[31:0],icap_csib,icap_rdwrb,icap_i[31:0],icap_clk,icap_request,icap_grant,fecc_crcerr,fecc_eccerr,fecc_eccerrsingle,fecc_syndromevalid,fecc_syndrome[12:0],fecc_far[25:0],fecc_synbit[4:0],fecc_synword[6:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "sem_v4_1_7_x7_sem_controller,Vivado 2016.4";
begin
end;
