-------------------------------------------------------------------------------
-- Title      : <title string>
-- Project    :
-------------------------------------------------------------------------------
-- File       : dna_port_wrpr.vhd
-- Author     : Matteo Lupi <matteo.lupi@cern.ch>
-- Company    : CERN European Organization for Nuclear Research
-------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-30  1.0      ML      Created
------------------------------------------------------------CD -------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity dna_port_wrpr is
  generic (
    SIM_DNA_VALUE : std_logic_vector(95 downto 0));
  port (
    DOUT  : out std_logic;
    CLK   : in  std_logic;
    DIN   : in  std_logic;
    READ  : in  std_logic;
    SHIFT : in  std_logic);
end entity dna_port_wrpr;

architecture std of dna_port_wrpr is

begin  -- architecture std

-- DNA_PORT: Device DNA Access Port
--7 Series
-- Xilinx HDL Libraries Guide, version 2016.4
  DNA_PORT_inst : DNA_PORTE2
    generic map (
      SIM_DNA_VALUE => SIM_DNA_VALUE
      )
    port map (
      DOUT  => DOUT,                    -- 1-bit output: DNA output data.
      CLK   => CLK,                     -- 1-bit input: Clock input.
      DIN   => DIN,                     -- 1-bit input: User data input pin.
      READ  => READ,  -- 1-bit input: Active high load DNA, active low read input.
      SHIFT => SHIFT  -- 1-bit input: Active high shift enable input.
      );
-- End of DNA_PORT_inst instantiation

end architecture std;
