-------------------------------------------------------------------------------
-- Title      : rtTop
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : rtTop.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-01-29
-- Last update: 2016-08-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Top entity for the radiation testing test structures. This is 
-- a wrapper to verify the behaviour of the tst shift registers 'rtSR', the
-- pattern generator 'rtPG' and comparator 'rtComp'.
--
-- SYMULATION ONLY GENERICS:
--   -> 'CS_MODE' (simulation only) defines specific simulation parameters.
--      Set to '0' to disable error injection.
--   -> 'CS_ERR_TARGET' (simulaiton only) is used to set a specific target
--      entity for error generation. Mostly used in pair with the 'C_ID'
--      generic to match a particular entity.
--   -> 'CS_ERR_CLKS_INTERVAL' (simulaiton only) defines the average number 
--      of clocks between two errors in the target unit.
--   -> 'CS_ERR_CLKS_LENGTH' (simulation only) defines the average number 
--      of clocks an error lasts in the target unit.
--
--  SYNTHESIS GENERICS
--   -> 'C_WIDTH' defines the width of the the shift register bus, it should match
--      the actual LUT size in the target FPGA. 
--   -> 'C_STEPS' defines the number of 'rtCLB' blocks implemented within the
--      shift register. It should be tuned so the shift register input and output
--      signals match at every clock cyle (it has to be an integer number of
--      periods of the 'rtCLB' transfer function). 
--   -> 'C_LANES' defines how many replicas of a test lane will be created in the 
--      compiled design.
--   -> 'C_MRL' defines the level of Modulare Redundancy of the hardened components
--      should be odd and it is anyway suggested to only use the 3 and 5 values. 
--   -> 'C_SR_MRL' defines the modular redundancy level within each CLB of the test 
--      Shift Register, and it is usually set to 3. Use odd numbers and beware that 
--      already 'C_SR_MRL = 5' generates huge logic footprints.
--   -> 'C_SR_MRC' is a flag setting whether to replicate the combinatorial logic (true) 
--      or not (false) into each CLB of the test Shift Register.
--   -> 'C_SR_MRR' is a flag setting whether to replicate the register logic (true) or 
--      not (false) into each CLB of the test Shift Register.
--   -> 'C_SR_MRCR' is a flag setting whether to add a further voting stage between
--      the combinatorial logic and the registers.
--   -> 'C_SR_MRB' is a flag setting whether to keep modular redundancy at the IN/OUT
--      ports or not (it generates 'C_MRL * C_WIDTH' wide inputs and outputs) between
--      the CLB blocks composing the test Shift Register.
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this clock,
--      i.e. they change state just after the 'CLK' rising edge.
--  ->  'RST' is the active-high synchronous reset. The unit start working after
--      'RST' goes low.
--  ->  'DIFF' is a 'C_LINES' width port which outputs in parallel the status of
--      each comparator at the end of a test shift register line. When a difference
--      between the reference pattern and the ith shift register output is detected
--      the corresponding 'DIFF(i)' output raises to '1' for as many clock cycles 
--      as the difference persist. In case of CRAM corruption the difference could
--      remain until the corrupted cell is corrected and/or the device reprogrammed.
--      The signal is synchronous with 'CLK' and tied to '0' during reset.
--  ->  'WARN' is a 'C_LINES' width port which outputs in parallel a warning flag
--      which, if high, indicates that within the voting system of the ith comparator
--      not all signals agree, i.e. that some upset is affecting the comparator itself.
--      The signal is synchronous with 'CLK' and tied to '0' during reset.

-- Libraries.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity rtTop is
  generic(
    -- SYNTHESIS TRANSLATE_OFF
    CS_MODE               : integer;          -- Simulation mode
    CS_ERR_TARGET         : integer;          -- Error injection target
    CS_ERR_CLKS_INTERVAL  : natural;          -- Average clocks between errors
    CS_ERR_CLKS_LENGTH    : natural;          -- Average error duration
    -- SYNTHESIS TRANSLATE_ON
    C_WIDTH               : natural := 6;     -- The data width of the 'testSR'
    C_STEPS               : natural := 4;     -- The steps of the 'testSR'
    C_LANES               : natural := 1;     -- The number of 'testSR' copies
    C_MRL                 : natural := 3;     -- Redundancy level of MR protection
    C_SR_MRL              : natural := 3;     -- Shift Register Redundancy level of MR protection
    C_SR_MRC              : boolean := true;  -- Shift Register Replicates combinatorial logic
    C_SR_MRR              : boolean := true;  -- Shift Register Replicates registers
    C_SR_MRCR             : boolean := false; -- Add redundant voter between logic and registers
    C_SR_MRB              : boolean := false  -- Shift Register Replicates outputs (use with care)
  );
  port(
    CLK   : in  std_logic;
    RST   : in  std_logic;
    DIFF  : out std_logic_vector(C_LANES - 1 downto 0);
    WARN  : out std_logic_vector(C_LANES - 1 downto 0)
);
end rtTop;

--------------------------------------------------------------------------------
--                    Architecture Behavioral Declaration                     --
--------------------------------------------------------------------------------    
architecture Behavioral of rtTop is
begin
  -- Array of 'rtLane' test structures.
  LANE : for i in 0 to C_LANES - 1 generate
    LN : entity work.rtLane
    generic map(
      -- SYNTHESIS TRANSLATE_OFF
      CS_MODE               => CS_MODE, 
      CS_ERR_TARGET         => CS_ERR_TARGET,
      CS_ERR_CLKS_INTERVAL  => CS_ERR_CLKS_INTERVAL,
      CS_ERR_CLKS_LENGTH    => CS_ERR_CLKS_LENGTH,
      -- SYNTHESIS TRANSLATE_ON
      C_WIDTH               => C_WIDTH,
      C_STEPS               => C_STEPS,
      C_ID                  => (i * C_STEPS),
      C_MRL                 => C_MRL,
      C_SR_MRL              => C_SR_MRL,
      C_SR_MRC              => C_SR_MRC,
      C_SR_MRR              => C_SR_MRR,
      C_SR_MRCR             => C_SR_MRCR,
      C_SR_MRB              => C_SR_MRB
    )
    port map(
      CLK   => CLK,
      RST   => RST,
      EN    => '1',
      DIFF  => DIFF(i),
      WARN  => WARN(i)
    );
  end generate;
end Behavioral;
