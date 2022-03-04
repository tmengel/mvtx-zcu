-------------------------------------------------------------------------------
-- Title      : Fabric Bitslip for Ultrascale
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : BitSlipInLogic_8b.vhd
-- Author     : J. Schambach
-- Company    : University of Texas at Austin
-- Created    : 2017-07-14
-- Last update: 2018-01-12
-- Platform   : Vivado 2016.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Modified from original Xilinx sources in xapp1208, deleted
--              the compare and fixed value bitslip methods, just keep simple
--              pulsed bitslip.
--
-- Appnote:    https://www.xilinx.com/support/documentation/application_notes/xapp1208-bitslip-logic.pdf 
-- Refdesign : https://www.xilinx.com/member/forms/download/design-license.html?cid=356522&filename=xapp1208-bitslip-logic.zip
-------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /
-- \   \   \/    Copyright 2014 Xilinx, Inc. All rights reserved.
--  \   \        This file contains confidential and proprietary information of Xilinx, Inc.
--  /   /        and is protected under U.S. and international copyright and other
-- /___/   /\    intellectual property laws.
-- \   \  /  \
--  \___\/\___\
--
---------------------------------------------------------------------------------------------
-- Device:              UltraScale, 7-Series
-- Author:              Defossez
-- Entity Name:         BitSlipInLogic_8b
-- Purpose:             Perform bitslip operations on parallel data.
--                      Extended functionality than native Virtex & UltraScale, 7-Series bitslip.
-- Tools:               Vivado_2014.1 or newer
-- Limitations:         none
--
-- Vendor:              Xilinx Inc.
-- Version:             V0.01
-- Filename:            BitSlipInLogic_8b.vhd
-- Date Created:        5 Dec 2014
-- Date Last Modified:  May 2014
---------------------------------------------------------------------------------------------
-- Disclaimer:
--              This disclaimer is not a license and does not grant any rights to the materials
--              distributed herewith. Except as otherwise provided in a valid license issued to you
--              by Xilinx, and to the maximum extent permitted by applicable law: (1) THESE MATERIALS
--              ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL
--              WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED
--              TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR
--              PURPOSE; and (2) Xilinx shall not be liable (whether in contract or tort, including
--              negligence, or under any other theory of liability) for any loss or damage of any
--              kind or nature related to, arising under or in connection with these materials,
--              including for any direct, or any indirect, special, incidental, or consequential
--              loss or damage (including loss of data, profits, goodwill, or any type of loss or
--              damage suffered as a result of any action brought by a third party) even if such
--              damage or loss was reasonably foreseeable or Xilinx had been advised of the
--              possibility of the same.
--
-- CRITICAL APPLICATIONS
--              Xilinx products are not designed or intended to be fail-safe, or for use in any
--              application requiring fail-safe performance, such as life-support or safety devices
--              or systems, Class III medical devices, nuclear facilities, applications related to
--              the deployment of airbags, or any other applications that could lead to death,
--              personal injury, or severe property or environmental damage (individually and
--              collectively, "Critical Applications"). Customer assumes the sole risk and
--              liability of any use of Xilinx products in Critical Applications, subject only to
--              applicable laws and regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--
-- Contact:    e-mail  hotline@xilinx.com        phone   + 1 800 255 7778
---------------------------------------------------------------------------------------------
-- Revision History:
--  Rev. May 2014
--  Checked simulations and implementation.
--  Reorganise design to fit Olympus and UltraScale, 7-Series XiPhy / ISERDES.
---------------------------------------------------------------------------------------------
-- Naming Conventions:
--  Generics start with:                                    "C_*"
--  Ports
--      All words in the label of a port name start with a upper case, AnInputPort.
--      Active low ports end in                             "*_n"
--      Active high ports of a differential pair end in:    "*_p"
--      Ports being device pins end in _pin                 "*_pin"
--      Reset ports end in:                                 "*Rst"
--      Enable ports end in:                                "*Ena", "*En"
--      Clock ports end in:                                 "*Clk", "ClkDiv", "*Clk#"
--  Signals and constants
--      Signals and constant labels start with              "Int*"
--      Registered signals end in                           "_d#"
--      User defined types:                                 "*_TYPE"
--      State machine next state:                           "*_Ns"
--      State machine current state:                        "*_Cs"
--      Counter signals end in:                             "*Cnt", "*Cnt_n"
--   Processes:                                 "<Entity_><Function>_PROCESS"
--   Component instantiations:                  "<Entity>_I_<Component>_<Function>"
---------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gbtx_controller_pkg.all;
---------------------------------------------------------------------------------------------
-- Entity pin description
---------------------------------------------------------------------------------------------
entity BitSlipInLogic_8b is
  generic (
    C_Slip_Backward : integer := 1;     -- 0 = slip forward, 1 = slip backward
    C_InputReg      : integer := 0      -- 0 = No, 1 = Yes
    );
  port (
    DataIn_pin      : in  std_logic_vector(7 downto 0);
    Bitslip_pin     : in  std_logic;
    Load_pin        : in  std_logic;
    Bitslip_num_pin : in  std_logic_vector(2 downto 0);
    Ena_pin         : in  std_logic;
    Rst_pin         : in  std_logic;
    Clk_pin         : in  std_logic;
    DataOut_pin     : out std_logic_vector(7 downto 0)
    );
end BitSlipInLogic_8b;
---------------------------------------------------------------------------------------------
-- Architecture section
---------------------------------------------------------------------------------------------
architecture BitSlipInLogic_8b_arch of BitSlipInLogic_8b is
---------------------------------------------------------------------------------------------
-- Component Instantiation
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Constants, Signals and Attributes Declarations
---------------------------------------------------------------------------------------------
-- Functions
-- Constants
-- Signals
  signal IntBitSlipPosition                          : std_logic_vector(7 downto 0);
  signal IntFrstBitSlipPstn                          : std_logic;
  signal IntBitSlipData                              : std_logic_vector(7 downto 0);
  signal IntRankOne                                  : std_logic_vector(7 downto 0);
  signal IntRankTwo                                  : std_logic_vector(7 downto 0);
  signal IntRankTre                                  : std_logic_vector(7 downto 0);
-- Attributes
  attribute KEEP_HIERARCHY                           : string;
  attribute KEEP_HIERARCHY of BitSlipInLogic_8b_arch : architecture is "YES";
---------------------------------------------------------------------------------------------
begin
---------------------------------------------------------------------------------------------
-- Extra front input register.
-- Adds one pipeline stage!
-----------------------------------------------------------------------------------------
  Gen_1_0 : if (C_InputReg = 1) generate
    BitSlipInLogic_8b_PROCESS_Rnk1 : process (Clk_pin, Rst_pin)  -- TODO : sync reset?
    begin
      if (Rst_pin = '1') then
        IntRankOne <= (others => '0');
      elsif rising_edge(Clk_pin) then
        if (Ena_pin = '1') then
          IntRankOne <= DataIn_pin;
        end if;
      end if;
    end process;
  end generate Gen_1_0;
--
  Gen_1_1 : if (C_InputReg = 0) generate
    IntRankOne <= DataIn_pin;
  end generate Gen_1_1;
-----------------------------------------------------------------------------------------
-- These are the bitslip registers.
-----------------------------------------------------------------------------------------
  BitSlipInLogic_8b_PROCESS_Data : process (Clk_pin, Rst_pin)  -- TODO : sync reset?
  begin
    if (Rst_pin = '1') then
      IntRankTwo <= (others => '0');
      IntRankTre <= (others => '0');
    elsif rising_edge(Clk_pin) then
      if (Ena_pin = '1') then
        IntRankTwo <= IntRankOne;
      end if;
      IntRankTre <= IntBitSlipData;
    end if;
  end process;
--
  DataOut_pin <= IntRankTre;
--
  Gen_2_0 : if (C_Slip_Backward = 1) generate
    BitSlipInLogic_8b_PROCESS_Mux : process (Ena_pin, IntBitSlipPosition,
                                             IntRankOne, IntRankTwo)

      subtype Sel is std_logic_vector (8 downto 0);
    begin
      case Sel'(Ena_pin & IntBitSlipPosition) is
        when "100000000" => IntBitSlipData <= IntRankOne(7 downto 0);
        when "100000001" => IntBitSlipData <= IntRankTwo(6 downto 0) & IntRankOne(7);
        when "100000010" => IntBitSlipData <= IntRankTwo(5 downto 0) & IntRankOne(7 downto 6);
        when "100000100" => IntBitSlipData <= IntRankTwo(4 downto 0) & IntRankOne(7 downto 5);
        when "100001000" => IntBitSlipData <= IntRankTwo(3 downto 0) & IntRankOne(7 downto 4);
        when "100010000" => IntBitSlipData <= IntRankTwo(2 downto 0) & IntRankOne(7 downto 3);
        when "100100000" => IntBitSlipData <= IntRankTwo(1 downto 0) & IntRankOne(7 downto 2);
        when "101000000" => IntBitSlipData <= IntRankTwo(0) & IntRankOne(7 downto 1);
        when "110000000" => IntBitSlipData <= IntRankOne(7 downto 0);
        when others      => IntBitSlipData <= "00000000";
      end case;
    end process;
  end generate Gen_2_0;

  Gen_2_1 : if (C_Slip_Backward = 0) generate
    BitSlipInLogic_8b_PROCESS_Mux : process (Ena_pin, IntBitSlipPosition,
                                             IntRankOne, IntRankTwo)
      subtype Sel is std_logic_vector (8 downto 0);
    begin
      case Sel'(Ena_pin & IntBitSlipPosition) is
        when "100000000" => IntBitSlipData <= IntRankOne(7 downto 0);
        when "100000001" => IntBitSlipData <= IntRankOne(0) & IntRankTwo(7 downto 1);
        when "100000010" => IntBitSlipData <= IntRankOne(1 downto 0) & IntRankTwo(7 downto 2);
        when "100000100" => IntBitSlipData <= IntRankOne(2 downto 0) & IntRankTwo(7 downto 3);
        when "100001000" => IntBitSlipData <= IntRankOne(3 downto 0) & IntRankTwo(7 downto 4);
        when "100010000" => IntBitSlipData <= IntRankOne(4 downto 0) & IntRankTwo(7 downto 5);
        when "100100000" => IntBitSlipData <= IntRankOne(5 downto 0) & IntRankTwo(7 downto 6);
        when "101000000" => IntBitSlipData <= IntRankOne(6 downto 0) & IntRankTwo(7);
        when "110000000" => IntBitSlipData <= IntRankOne(7 downto 0);
        when others      => IntBitSlipData <= "00000000";
      end case;
    end process;
  end generate Gen_2_1;


-----------------------------------------------------------------------------------------
-- This is the bitslip controller.
-----------------------------------------------------------------------------------------
  BitSlipInLogic_8b_PROCESS_Bitslip : process (Clk_pin, Rst_pin)  -- TODO : sync reset?
  begin
    if (Rst_pin = '1') then
      IntBitSlipPosition <= (others => '0');
      IntBitSlipPosition(to_integer(unsigned(C_GBTX_BITSLIP_RX_VALUE_DEFAULT))) <= '1';
      IntFrstBitSlipPstn <= '0';
    elsif rising_edge(Clk_pin) then
      if (Ena_pin = '1') then
        if ((Bitslip_pin = '1') and (IntFrstBitSlipPstn = '0') and (Load_pin = '0')) then
          IntBitSlipPosition <= IntBitSlipPosition(6 downto 0) & not IntBitSlipPosition(7);
        elsif ((Bitslip_pin = '1') and (IntFrstBitSlipPstn /= '0') and (Load_pin = '0')) then
          IntBitSlipPosition <= IntBitSlipPosition(6 downto 0) & IntBitSlipPosition(7);
        elsif ((Bitslip_pin = '0') and (Load_pin = '1')) then
          IntBitSlipPosition                                        <= (others => '0');
          IntBitSlipPosition(to_integer(unsigned(Bitslip_num_pin))) <= '1';
        end if;
        if (Bitslip_pin = '1') then
          IntFrstBitSlipPstn <= '1';
        end if;
      end if;
    end if;
  end process;


-----------------------------------------------------------------------------------------
end BitSlipInLogic_8b_arch;
--
