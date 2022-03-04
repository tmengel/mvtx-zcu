-------------------------------------------------------------------------------
-- Title      : rtLane
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : rtLane.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
--              Krzysztof Marek Sielewicz (krzysztof.sielewicz@cern.ch)
-- Company    : CERN
-- Created    : 2016-02-23
-- Last update: 2016-05-19
-- Platform   : Windows 10 64bit, Xilinx Vivado 2015.3
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description:
-- 'rtLane' is the basic element for testing CLB logic, both combinatorial and
-- FFs. It contains an hardened pattern generator, a shift register containing
-- the target 'rtCLB' bloks, and an hardened comparator to spot differencies 
-- between the pattern generator data and the shift register outcome.
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

-- SYNTHESIS GENERICS:
--   -> 'C_WIDTH' defines the width of the the shift register bus, it should match
--      the actual LUT size in the target FPGA. 
--   -> 'C_STEPS' defines the number of 'rtCLB' blocks implemented within the
--      shift register. It should be tuned so the shift register input and output
--      signals match at every clock cyle (it has to be an integer number of
--      periods of the 'rtCLB' transfer function).
--   -> 'C_ID' is an optional generic (default 0) used to identify the lane. It
--      is passed to child entities, so they can differentiate themselves among
--      different lanes.    
--   -> 'C_MRL' defines the level of Modulare Redundancy of the hardened components
--      in the lane (patter generator, discriminator, etc...). It should be odd and it 
--      is anyway suggested to only use the 3 and 5 values. 
--   -> 'C_SR_MRL' defines the modular redundancy level within each CLB of the test 
--      Shift Register, and it is usually set to 3. Use odd numbers and beware that 
--      already 'C_SR_MRL = 5' generates huge logic footprints.
--   -> 'C_SR_MRC' is a flag setting whether to replicate the combinatorial logic (true) 
--      or not (false) into each CLB of the test Shift Register.
--   -> 'C_SR_MRR' is a flag setting whether to replicate the register logic (true) or 
--      not (false) into each CLB of the test Shift Register.
--   -> 'C_SR_MRO' is a flag setting whether to keep modular redundancy at the IN/OUT
--      ports or not (it generates 'C_MRL * C_WIDTH' wide inputs and outputs) between
--      the CLB blocks composing the test Shift Register.
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this clock,
--      i.e. they change state just after the 'CLK' rising edge.
--  ->  'RST_N' is the active-low synchronous reset. Every values is set to '0'
--      during reset time.
--  ->  'EN' active high, enables the output of the unit. It is usually driven
--      by the 'RDY' output of the pattern generator, so to 
--  ->  'DIFF' is a logic port which outputs '0' as long as the shift register
--      contained in the lane produces the expected pattern, and '1' when its
--      output differ from the reference pattern feeded through 'INPUT'
--  ->  'WARN' is a logic port which outputs a warning flag which, if high, 
--      indicates that within the voting system of the comparator not all 
--      signals agree, i.e. that some upset is affecting the comparator itself.
--      The signal is synchronous with 'CLK' and tied to '0' during reset.
--
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author          Description
-- 2016-01-29   1.0         Piero        Created
------------------------------------------------------------------------------- 

-- Libraries.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Packages.
use work.mrTools_pkg.all;

--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity rtLane_xN is
	generic(
    -- SYNTHESIS TRANSLATE_OFF
    CS_MODE               : integer;  -- Simulation mode.
    CS_ERR_TARGET         : integer;  -- Error injection target.   
    CS_ERR_CLKS_INTERVAL  : natural;  -- Average clocks between errors.
    CS_ERR_CLKS_LENGTH    : natural;  -- Average error duration.  
    -- SYNTHESIS TRANSLATE_ON
    C_WIDTH     : natural := 6;     -- Test pattern bus width.
		C_STEPS     : natural := 16;    -- The steps of the shift register.
    C_SUB_LANES : natural := 3;     -- Number of parralel sublanes
		C_ID        : integer := 0;     -- Specific ID to differentiate the Lanes.
		C_MRL       : natural := 3;     -- Modular Redundancy Level for hardened structures.
		C_SR_MRL    : natural := 3;     -- Shift Register Redundancy level of MR protection.
    C_SR_MRC    : boolean := false; -- Shift Register Replicates combinatorial logic.
    C_SR_MRR    : boolean := false; -- Shift Register Replicates registers.
    C_SR_MRO    : boolean := false  -- Shift Register Replicates inputs and outputs.
	);
	port(
		CLK    : in  std_logic;
		RST_N  : in  std_logic;
		EN     : in std_logic;
		DIFF   : out std_logic;
		WARN   : out std_logic
	);
	
	-- Makes the unit not touchable by synthesis and implementation.
    attribute DONT_TOUCH of rtLane_xN: entity is "true";
end rtLane_xN;


--------------------------------------------------------------------------------
--                  Architecture 'Behavioral' Declaration                     --
--------------------------------------------------------------------------------    
architecture Behavioral of rtLane_xN is

  component mvtr is
  generic(
    M : natural;
    N : natural
  );
  port(
    vtr_i   : in std_logic_vector(M*N-1 downto 0);
    vtr_o   : out std_logic_vector(N-1 downto 0);
    warn_o  : out std_logic
  );
  end component mvtr;

	-- Signals from the PG.
	signal sPGOut   : std_logic_vector(C_WIDTH - 1 downto 0);
	signal sPGWarn  : std_logic;
	signal sPGReady : std_logic;
	signal sPGCycle : std_logic;
	
	-- Signal connecting the SR to the comparator.
	signal sSROut   : std_logic_vector(C_WIDTH * C_SUB_LANES - 1 downto 0);
  signal sVtrOut  : std_logic_vector(C_WIDTH - 1 downto 0);
  
  signal sWarnVtr : std_logic;
  
  -- Signals at the output of the comparator.
  signal sCompDiff : std_logic_vector(C_MRL - 1 downto 0);
  signal sCompWarn : std_logic;
  
  -- Signals at the output of the edge . sEdgeDiff
  -- also casts from std_logic_vector to std_logic.
  signal sDiscDiff : std_logic_vector(0 downto 0);
  signal sDiscWarn : std_logic;

begin
  -- The Pattern Generator feeding the shift register with the test pattern.
  PG: entity work.mrPG
  generic map(
    C_WIDTH => C_WIDTH,     
    C_MRL   => C_MRL
  )
  port map(
    CLK     => CLK,
    RST_N   => RST_N,
    READY   => sPGReady,
    CYCLE   => sPGCycle,
    PTRN    => sPGOut,
    WARN    => sPGWarn
  );
  
  -- The Shift Register composed by 'C_STEPS' 'rtCLB' test blocks, each one
  -- containing combinatorial logic and registers (FFs).
  SUB_LANE : for i in 0 to C_SUB_LANES - 1 generate
    SUB_LANE: entity work.rtSR
    generic map(
      -- SYNTHESIS TRANSLATE_OFF
      CS_MODE               => CS_MODE, 
      CS_ERR_TARGET         => CS_ERR_TARGET,
      CS_ERR_CLKS_INTERVAL  => CS_ERR_CLKS_INTERVAL,
      CS_ERR_CLKS_LENGTH    => CS_ERR_CLKS_LENGTH,
      -- SYNTHESIS TRANSLATE_ON
      C_WIDTH => C_WIDTH,
      C_STEPS => C_STEPS,
      C_ID    => C_ID,
      C_MRL   => C_SR_MRL,
      C_MRC   => C_SR_MRC,
      C_MRR   => C_SR_MRR,
      C_MRO   => C_SR_MRO
    )
    port map(
      CLK    => CLK,
      RST_N  => RST_N,
      IPTRN  => sPGOut,
      OPTRN  => sSROut(C_WIDTH * i + (C_WIDTH - 1) downto C_WIDTH * i)
    );
  end generate;
  
  -- -- Generates the registers voter(s).
  -- V: entity work.mrVotingStage
  -- generic map (
    -- C_WIDTH => C_WIDTH,
    -- C_MRL   => 3,
    -- C_MRO   => false,
    -- C_MRW   => true
  -- )
  -- port map(
    -- INPUT   => sSROut,
    -- OUTPUT  => sVtrOut,
    -- WARN    => sWarnVtr
  -- );
  
  INST_mvtr : mvtr
  generic map(
    M => 3,
    N => 6 
  )
  port map(
    vtr_i   => sSROut,
    vtr_o   => sVtrOut,
    warn_o  => sWarnVtr
  );
  
	-- The Comparator checks the outputs of the patter generator and of the shift
	-- register and assert a synchronous '1' if they were different at the moment
	-- of the 'CLK' rising edge.
  CMP: entity work.mrComp
    generic map(
      C_WIDTH => C_WIDTH,
      C_MRL   => C_MRL,
      C_MRO   => true
    )
    port map(
      CLK     => CLK,
      RST_N   => RST_N,
      PTRN1   => sPGOut,
      PTRN2   => sVtrOut,
      DIFF    => sCompDiff,
      WARN    => sCompWarn
    );

  -- The Discriminator filters the comparator output and issues a single pulse
  -- at the end of a pattern cycle in case at least one difference has been 
  -- catched by the comparator. Being the last stage, it is forced to generate
  -- a single bit output ('C_MRO = false').
  DSC: entity work.mrDisc
  generic map (
    C_MRL     => C_MRL,
    C_MRO     => false
  )
  port map (  
    CLK       => CLK,
    RST_N     => RST_N,
    EN        => EN,
    CYCLE     => sPGCycle,
    READY     => sPGReady,
    INPUT     => sCompDiff,
    OUTPUT(0) => DIFF,
    WARN      => sDiscWarn
  );
  
  -- Warn output addressing. Put in or the warning status from the
	-- Pattern Generator and the Comparator, to warn against unwanted
	-- upsets in these components. 
    OR_WARN: process (sPGWarn, sCompWarn, sDiscWarn, sWarnVtr)
    begin
      WARN <= sPGWarn or sCompWarn or sDiscWarn or sWarnVtr;
    end process;
  
end Behavioral;
