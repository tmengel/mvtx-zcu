-------------------------------------------------------------------------------
-- Title      : Minority voted TMR Output
-- Project    : ALICE ITS WP10
-------------------------------------------------------------------------------
-- File       : mvtmr_output.vhd
-- Author     : Joachim Schambach  <jschamba@pisces>
-- Company    : University of Texas at Austin
-- Created    : 2018-02-14
-- Last update: 2018-02-14
-- Platform   : Vivado 2016.4
-- Target     : Kintex Ultrascale
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Triplicated output of a single-ended signal according to
--              the description from Xilinx XAPP197
--              Minority voted TMR as shown in Fig 19
-------------------------------------------------------------------------------
-- Copyright (c) 2018 University of Texas at Austin
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018-02-14  1.0      jschamba  Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mvtmr_output is
  
  port (
    -- triplicated signals input
    TR0_i : in  std_logic;
    TR1_i : in  std_logic;
    TR2_i : in  std_logic;
    -- outputs
    TR0_o : out std_logic;
    TR0_T : out std_logic;
    TR1_o : out std_logic;
    TR1_T : out std_logic;
    TR2_o : out std_logic;
    TR2_T : out std_logic
    );

end entity mvtmr_output;

architecture rtl of mvtmr_output is

  component minority_voter is
    port (
      primary_i         : in  std_logic;
      reference_i       : in  std_logic_vector(1 downto 0);
      driver_tristate_o : out std_logic);
  end component minority_voter;
  
begin  -- architecture rtl

  INST_mv0 : minority_voter
    port map (
      primary_i         => TR0_i,
      reference_i(0)    => TR1_i,
      reference_i(1)    => TR2_i,
      driver_tristate_o => TR0_T
      );
  
  INST_mv1 : minority_voter
    port map (
      primary_i         => TR1_i,
      reference_i(0)    => TR0_i,
      reference_i(1)    => TR2_i,
      driver_tristate_o => TR1_T
      );
  
  INST_mv2 : minority_voter
    port map (
      primary_i         => TR2_i,
      reference_i(0)    => TR1_i,
      reference_i(1)    => TR0_i,
      driver_tristate_o => TR2_T
      );

  TR0_o <= TR0_i;
  TR1_o <= TR1_i;
  TR2_o <= TR2_i;

end architecture rtl;
