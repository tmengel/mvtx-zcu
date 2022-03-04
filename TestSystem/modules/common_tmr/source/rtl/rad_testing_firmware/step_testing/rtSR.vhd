-------------------------------------------------------------------------------
-- Title      : rtSR
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : rtSR.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-01-29
-- Last update: 2016-05-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description:
-- 'testST' generates a test shift register by replicating 'C_STEPS' time the
-- basic building block 'testCLB', which incorporates a combinatorial logic
-- structure and a clocked output register.
--
-- SIMULATION ONLY GENERICS: 
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
-- SYNTHESIS GENERICS: 
--   -> 'C_WIDTH' defines the width of the the shift register bus, it should match
--      the actual LUT size in the target FPGA. 
--   -> 'C_STEPS' defines the number of 'rtCLB' blocks implemented within the
--      shift register. It should be tuned so the shift register input and output
--      signals match at every clock cyle (it has to be an integer number of
--      periods of the 'rtCLB' transfer function). 
--   -> 'C_ID' is an optional generic which can be used to personalize the LUT
--      implemented logic accordingli to it, or to simply distinguish each CLB
--      in an array structure.
--   -> 'C_MRL' defines the modular redundancy level, and it is usually set to 3. 
--      Use odd numbers and beware that already 5 generates huge logic footprints.
--   -> 'C_MRC' is a flag setting whether to replicate the combinatorial logic (true) 
--      or not (false).
--   -> 'C_MRR' is a flag setting whether to replicate the register logic (true) or 
--      not (false).
--   -> 'C_MRO' is a flag setting whether to keep modular redundancy at the IN/OUT
--      ports or not (it generates 'C_MRL * C_WIDTH' wide inputs and outputs).
--      'C_MRC', 'C_MRR' and 'C_MRO' can be freely combined to test different protection 
--      schemes.
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this clock,
--      i.e. they change state just after the 'CLK' rising edge.
--  ->  'RST' is the active-high synchronous reset. During the reset 'OUTPUT' is
--      tied at 'INPUT'.
--  ->  'IPTRN' is a 'C_WIDTH' width port which feeds the combinatorial logic.
--  ->  'OPTRN' is a 'C_WIDTH' width port which outputs the values stored in
--      the registers at the 'CLK' rising edge.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author          Description
-- 2016-01-29   1.0         Piero        Created
------------------------------------------------------------------------------- 

-- Libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Packages
use work.mrTools_pkg.all;

--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity rtSR is
	generic(
    -- SYNTHESIS TRANSLATE_OFF
    CS_MODE               : integer;          -- Simulation mode
    CS_ERR_TARGET         : integer;          -- Error injection target
    CS_ERR_CLKS_INTERVAL  : natural;          -- Average clocks between errors
    CS_ERR_CLKS_LENGTH    : natural;          -- Average error duration
    -- SYNTHESIS TRANSLATE_ON
    C_WIDTH               : natural := 3;     -- The data width of the shift register (should match the hardware LUT size)
    C_STEPS               : natural := 8;     -- The steps of the shift register
    C_ID                  : integer := 0;     -- Specific ID to differentiate the SR
    C_MRL                 : natural := 3;     -- Redundancy level of MR protection
    C_MRC                 : boolean := false; -- Replicates combinatorial logic
    C_MRR                 : boolean := false; -- Replicates registers
    C_MRCR                : boolean := false; -- Add redundant voter between logic and registers
    C_MRB                 : boolean := false  -- Replicates inputs and outputs
	);
	port(
		CLK   : in  std_logic;
		RST   : in  std_logic;
		IPTRN : in  std_logic_vector(C_WIDTH - 1 downto 0);
		OPTRN : out std_logic_vector(C_WIDTH - 1 downto 0)
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
  attribute DONT_TOUCH of rtSR: entity is "true";
end rtSR;

--------------------------------------------------------------------------------
--                    Architecture 'Behavioral' Declaration                   --
-------------------------------------------------------------------------------- 
architecture Behavioral of rtSR is
	-- Signal connecting the chain of logic blocks 'rtCLB' ('C_STEPS' instead of
	-- 'C_STEPS - 1' to allocate start and end points).
	type tStep is array (0 to C_STEPS - 2) of std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRB) - 1 downto 0);
	signal sStep : tStep;

--------------------------------------------------------------------------------
--                          Architecture Behavioral                           --
--------------------------------------------------------------------------------    
begin
  -- FIRST stage of the chain is forced to have single input, whatever the generics.
  FIRST : entity work.rtCLB
  generic map(
    -- SYNTHESIS TRANSLATE_OFF
    CS_MODE               => CS_MODE, 
    CS_ERR_TARGET         => CS_ERR_TARGET,
    CS_ERR_CLKS_INTERVAL  => CS_ERR_CLKS_INTERVAL,
    CS_ERR_CLKS_LENGTH    => CS_ERR_CLKS_LENGTH,
    -- SYNTHESIS TRANSLATE_ON
    C_WIDTH               => C_WIDTH,
    C_ID                  => C_ID,
    C_MRL                 => C_MRL,
    C_MRC                 => C_MRC,
    C_MRR                 => C_MRR,
    C_MRCR                => C_MRCR,
    C_MRI                 => false,
    C_MRO                 => C_MRB
   )
   port map(
    CLK   => CLK,
    RST   => RST,
    IPTRN => IPTRN,
    OPTRN => sStep(0)
  );
  
   -- LAST stage of the chain is forced to have single output, whatever the generics.
  LAST : entity work.rtCLB
  generic map(
    -- SYNTHESIS TRANSLATE_OFF
    CS_MODE               => CS_MODE, 
    CS_ERR_TARGET         => CS_ERR_TARGET,
    CS_ERR_CLKS_INTERVAL  => CS_ERR_CLKS_INTERVAL,
    CS_ERR_CLKS_LENGTH    => CS_ERR_CLKS_LENGTH,
    -- SYNTHESIS TRANSLATE_ON
    C_WIDTH               => C_WIDTH,
    C_ID                  => (C_ID + C_STEPS - 1),
    C_MRL                 => C_MRL,
    C_MRC                 => C_MRC,
    C_MRR                 => C_MRR,
    C_MRCR                => C_MRCR,
    C_MRI                 => C_MRB,    
    C_MRO                 => false
  )
  port map(
    CLK   => CLK,
    RST   => RST,
    IPTRN => sStep(C_STEPS - 2),
    OPTRN => OPTRN
  );
  
	-- Shift register bulk chain made of 'C_STEPS - 1' 'rtCLB'.
  ARR : for i in 0 to C_STEPS - 3 generate
    CLB : entity work.rtCLB
    generic map(
      -- SYNTHESIS TRANSLATE_OFF
      CS_MODE               => CS_MODE, 
      CS_ERR_TARGET         => CS_ERR_TARGET,
      CS_ERR_CLKS_INTERVAL  => CS_ERR_CLKS_INTERVAL,
      CS_ERR_CLKS_LENGTH    => CS_ERR_CLKS_LENGTH,
      -- SYNTHESIS TRANSLATE_ON
      C_WIDTH               => C_WIDTH,
      C_ID                  => (C_ID + 1 + i),
      C_MRL                 => C_MRL,
      C_MRC                 => C_MRC,
      C_MRR                 => C_MRR,
      C_MRCR                => C_MRCR,
      C_MRI                 => C_MRB,
      C_MRO                 => C_MRB
    )
    port map(
      CLK   => CLK,
      RST   => RST,
      IPTRN => sStep(i),
      OPTRN => sStep(i + 1)
    );
  end generate ARR;
end Behavioral;
