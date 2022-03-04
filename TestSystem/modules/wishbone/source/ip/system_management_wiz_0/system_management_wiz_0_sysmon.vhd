-- file: system_management_wiz_0.vhd
-- (c) Copyright 2013 - 2013 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity system_management_wiz_0_sysmon is
   port
   (
    daddr_in        : in  STD_LOGIC_VECTOR (7 downto 0);     -- Address bus for the dynamic reconfiguration port
    den_in          : in  STD_LOGIC;                         -- Enable Signal for the dynamic reconfiguration port
    di_in           : in  STD_LOGIC_VECTOR (15 downto 0);    -- Input data bus for the dynamic reconfiguration port
    dwe_in          : in  STD_LOGIC;                         -- Write Enable for the dynamic reconfiguration port
    do_out          : out  STD_LOGIC_VECTOR (15 downto 0);   -- Output data bus for dynamic reconfiguration port
    drdy_out        : out  STD_LOGIC;                        -- Data ready signal for the dynamic reconfiguration port
    dclk_in         : in  STD_LOGIC;                         -- Clock input for the dynamic reconfiguration port
    reset_in        : in  STD_LOGIC;                         -- Reset signal for the System Monitor control logic
    vp              : in  STD_LOGIC;
    vn              : in  STD_LOGIC;
    busy_out        : out  STD_LOGIC;                        -- ADC Busy signal
    channel_out     : out  STD_LOGIC_VECTOR (5 downto 0);    -- Channel Selection Outputs
    eoc_out         : out  STD_LOGIC;                        -- End of Conversion Signal
    eos_out         : out  STD_LOGIC;                        -- End of Sequence Signal
    ot_out          : out  STD_LOGIC;                        -- Over-Temperature alarm output
    user_supply1_alarm_out : out  STD_LOGIC;
    user_supply0_alarm_out : out  STD_LOGIC;
    alarm_out       : out STD_LOGIC
);
end system_management_wiz_0_sysmon;

architecture xilinx of system_management_wiz_0_sysmon is


  signal FLOAT_VCCAUX_ALARM : std_logic;
  signal FLOAT_VCCINT_ALARM : std_logic;
  signal FLOAT_USER_TEMP_ALARM : std_logic;
  signal FLOAT_VBRAM_ALARM : std_logic;
  signal FLOAT_MUXADDR : std_logic_vector (4 downto 0);
  signal aux_channel_p : std_logic_vector (15 downto 0);
  signal aux_channel_n : std_logic_vector (15 downto 0);
  signal alm_int : std_logic_vector (15 downto 0);
signal i2c_sda_master : std_logic;
signal i2c_sclk_master : std_logic;
signal i2c_sda_slave0 : std_logic;
signal i2c_sclk_slave0 : std_logic;
signal i2c_sda_slave1 : std_logic;
signal i2c_sclk_slave1 : std_logic;
signal i2c_sda_slave2 : std_logic;
signal i2c_sclk_slave2 : std_logic;

begin

          user_supply1_alarm_out <= alm_int(9);
          user_supply0_alarm_out <= alm_int(8);
          alarm_out <= alm_int(7);

-- inout logic for i2c_sda and i2c_sclk ports


 inst_sysmon: SYSMONE1
     generic map(
        INIT_40 => X"3000", -- config reg 0
        INIT_41 => X"21DE", -- config reg 1
        INIT_42 => X"1F00", -- config reg 2
        INIT_43 => X"200C", -- config reg 3
        INIT_45 => X"DE0C", -- Analog Bus Register
        INIT_46 => X"0003", -- Sequencer Channel selection (Vuser0-3)
        INIT_47 => X"0003", -- Sequencer Average selection (Vuser0-3)
        INIT_48 => X"4701", -- Sequencer channel selection
        INIT_49 => X"0000", -- Sequencer channel selection
        INIT_4A => X"4700", -- Sequencer Average selection
        INIT_4B => X"0000", -- Sequencer Average selection
        INIT_4C => X"0000", -- Sequencer Bipolar selection
        INIT_4D => X"0000", -- Sequencer Bipolar selection
        INIT_4E => X"0000", -- Sequencer Acq time selection
        INIT_4F => X"0000", -- Sequencer Acq time selection
        INIT_50 => X"B723", -- Temp alarm trigger
        INIT_51 => X"4E81", -- Vccint upper alarm limit
        INIT_52 => X"A147", -- Vccaux upper alarm limit
        INIT_53 => X"BC33", -- Temp alarm OT upper
        INIT_54 => X"AA5F", -- Temp alarm reset
        INIT_55 => X"4963", -- Vccint lower alarm limit
        INIT_56 => X"9555", -- Vccaux lower alarm limit
        INIT_57 => X"AF7B", -- Temp alarm OT reset
        INIT_58 => X"4E81", -- Vccbram upper alarm limit
        INIT_5C => X"4963", -- Vbccram lower alarm limit
        INIT_59 => X"5555", -- vccpsintlp upper alarm limit
        INIT_5D => X"5111", -- vccpsintlp lower alarm limit
        INIT_5A => X"9999", -- vccpsintfp upper alarm limit
        INIT_5E => X"91EB", -- vccpsintfp lower alarm limit
        INIT_5B => X"6AAA", -- vccpsaux upper alarm limit
        INIT_5F => X"6666", -- vccpsaux lower alarm limit
        INIT_60 => X"93D6", -- Vuser0 upper alarm limit
        INIT_61 => X"8665", -- Vuser1 upper alarm limit
        INIT_62 => X"9A74", -- Vuser2 upper alarm limit
        INIT_63 => X"4D39", -- Vuser3 upper alarm limit
        INIT_68 => X"85C1", -- Vuser0 lower alarm limit
        INIT_69 => X"7999", -- Vuser1 lower alarm limit
        INIT_6A => X"98BF", -- Vuser2 lower alarm limit
        INIT_6B => X"4C5E", -- Vuser3 lower alarm limit
        SYSMON_VUSER0_BANK    => 64,
        SYSMON_VUSER0_MONITOR => "VCCO_TOP",
        SYSMON_VUSER1_BANK    => 67,
        SYSMON_VUSER1_MONITOR => "VCCO",
        SIM_MONITOR_FILE => "design.dat"
        )

port map (
        CONVST              => '0',
        CONVSTCLK           => '0',
        DADDR               => daddr_in,            --: in (7 downto 0)
        DCLK                => dclk_in,
        DEN                 => den_in,
        DI(15 downto 0)     => di_in(15 downto 0),
        DWE                 => dwe_in,
        RESET               => reset_in,
        VAUXN(15 downto 0)  => aux_channel_n(15 downto 0),
        VAUXP(15 downto 0)  => aux_channel_p(15 downto 0),
        ALM                 => alm_int,
        BUSY                => busy_out,
        CHANNEL             => channel_out,
        DO(15 downto 0)     => do_out(15 downto 0),
        DRDY                => drdy_out,
        EOC                 => eoc_out,
        EOS                 => eos_out,
        JTAGBUSY            => open,
        JTAGLOCKED          => open,
        JTAGMODIFIED        => open,
        OT                  => ot_out,
        I2C_SCLK            => '0',
        I2C_SDA             => '0',
        I2C_SCLK_TS         => open,
        I2C_SDA_TS          => open,
     
        MUXADDR             => open,
        VN                  => vn,
        VP                  => vp
         );




end xilinx;

