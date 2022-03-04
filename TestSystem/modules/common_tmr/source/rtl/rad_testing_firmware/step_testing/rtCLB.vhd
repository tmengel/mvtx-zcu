-------------------------------------------------------------------------------
-- Title      : rtCLB
-- Project    : ITS Readout Electronic Firmware
-------------------------------------------------------------------------------
-- File       : rtCLB.vhd
-- Author     : Piero Giubilato (piero.giubilato@cern.ch)
-- Company    : CERN
-- Created    : 2016-01-29
-- Last update: 2016-12-12
-- Platform   : Windows 10 64bit, Xilinx Vivado 2016.1
-- Target     : Xilinx Kintex-7 (XC7K325TFFG900-1)
-- Standard   : VHDL'2008
-------------------------------------------------------------------------------
-- Description: Combinatorial Logic Block test structure for radiation testing.
-- Each 'CLB' incorporates a combinatorial logic blok (LUT) using 'C_WIDTH' bits
-- as input and 'C_WIDTH' output registers (FFs) to latch the LUT outputs at the
-- 'CLK' clock rising edge.
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
--   -> 'C_WIDTH' defines the in/out width of the CLB, usually it should match
--      the actual LUT size in the target FPGA. 
--   -> 'C_ID' is an optional generic which can be used to personalize the LUT
--      implemented logic accordingly to it, or to simply distinguish each CLB
--      in an array structure. 
--   -> 'C_MRL' defines the modular redundancy level, and it is usually set to 3. 
--      Use odd numbers and beware that already 5 generates huge logic footprints.
--   -> 'C_MRC' is a flag setting whether to replicate the combinatorial logic (true) 
--      or not (false).
--   -> 'C_MRR' is a flag setting whether to replicate the register logic (true) or 
--      not (false).
--   -> 'C_MRCR' is a flag setting whether to add a further voting stage between
--      the combinatorial logic and the registers.
--   -> 'C_MRI' is a flag setting whether to keep modular redundancy at the IPTRN
--      ports or not (it generates 'C_MRL * C_WIDTH' wide inputs).
--   -> 'C_MRO' is a flag setting whether to keep modular redundancy at the OPTRN
--      ports or not (it generates 'C_MRL * C_WIDTH' wide outputs).
--      'C_MRC', 'C_MRR', 'C_MRI' and 'C_MRO' can be freely combined to test different 
--      protection schemes.
--
-- I/O PORTS:
--  ->  'CLK' is the entity clock, and the outputs are synchronous with this clock,
--      i.e. they change state just after the 'CLK' rising edge.
--  ->  'RST' is the active-high synchronous reset. During the reset 'OUTPUT' is
--      tied at 'INPUT'.
--  ->  'IPTRN' is a 'C_WIDTH' width port which feeds the combinatorial logic.
--  ->  'OPTRN' is a 'C_WIDTH' width port which outputs the values stored in
--      the registers at the 'CLK' rising edge.

-- Libraries
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Packages
use work.mrTools_pkg.all;

--------------------------------------------------------------------------------
--                             Entity Declaration                             --
--------------------------------------------------------------------------------
entity rtCLB is
  generic(
    -- SYNTHESIS TRANSLATE_OFF
    CS_MODE               : integer;          -- Simulation mode
    CS_ERR_TARGET         : integer;          -- Error injection target
    CS_ERR_CLKS_INTERVAL  : natural;          -- Average clocks between errors
    CS_ERR_CLKS_LENGTH    : natural;          -- Average error duration
    -- SYNTHESIS TRANSLATE_ON
    C_WIDTH               : natural := 6;     -- Width of the data path
    C_ID                  : integer := 0;     -- ID for the CLB block
    C_MRL                 : natural := 3;     -- Redundancy level of MR protection
    C_MRC                 : boolean := false; -- Replicates combinatorial logic
    C_MRR                 : boolean := false; -- Replicates registers
    C_MRCR                : boolean := false; -- Add redundant voter between logic and registers
    C_MRI                 : boolean := false; -- MR redundant inputs
    C_MRO                 : boolean := false  -- MR redundant outputs
  );
  port(
    CLK   : in  std_logic;
    RST   : in  std_logic;
    IPTRN : in  std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRI) - 1 downto 0);
    OPTRN : out std_logic_vector(mrPortWidth(C_WIDTH, C_MRL, C_MRO) - 1 downto 0)
  );
	
	-- Makes the unit not touchable by synthesis and implementation.
  attribute DONT_TOUCH of rtCLB: entity is "true";
  
	-- SYNTHESIS TRANSLATE_OFF
  package rtTools is new work.rtTools_pkg generic map (
    CS_MODE               => CS_MODE,
    CS_ERR_TARGET         => CS_ERR_TARGET,
    CS_ERR_CLKS_INTERVAL  => CS_ERR_CLKS_INTERVAL,
    CS_ERR_CLKS_LENGTH    => CS_ERR_CLKS_LENGTH,
    C_WIDTH               => C_WIDTH 
  );
  -- SYNTHESIS TRANSLATE_ON
end rtCLB;

--------------------------------------------------------------------------------
--                          Architecture Declaration                          --
--------------------------------------------------------------------------------
architecture Behavioral of rtCLB is
  -- SYNTHESIS TRANSLATE_OFF
  -- Use the 'rtTools' 'tErr' protected structure to manage 
  -- the error injection during SIMULATION ONLY .    
  shared variable cErr : rtTools.tErr;    
  -- SYNTHESIS TRANSLATE_ON

  -- Derives the width of the signal from the combinatorial(s) logic block(s).
  signal sPtrn: std_logic_vector(C_WIDTH * mrSel(C_MRL, 1, C_MRC) - 1 downto 0);

  -- Derives the width of the signal from the combinatorial(s) logic block(s) voters.
  signal sPtrnV: std_logic_vector(C_WIDTH * mrSel(C_MRL, 1, C_MRC and C_MRR) - 1 downto 0);
--------------------------------------------------------------------------------
--                          Architecture Behavioral                           --
--------------------------------------------------------------------------------    
begin
  -- Instantiates the required number of logic tables
  CLs: for i in 0 to mrSel(C_MRL, 1, C_MRC) - 1 generate
    TABLE: entity work.muTable
    generic map (
      C_WIDTH => C_WIDTH
    )
    port map(
      INPUT => IPTRN( mrBusMSB(C_WIDTH, C_MRL, C_MRI, i) downto mrBusLSB(C_WIDTH, C_MRL, C_MRI, i) ),
      OUTPUT => sPtrn( (i + 1) * C_WIDTH - 1 downto i * C_WIDTH )
    );     
    end generate CLs;
  
  -- Generates the voters for the combinatorial logic if needed. Generation truth table is:
  -- Otherwise simply connects the output of the combinatorial logic block to the register(s).
  CLVs: entity work.mrVotingStage
    generic map (
      C_WIDTH => C_WIDTH,
      C_MR    => C_MRC and C_MRCR,
      C_MRL   => C_MRL,
      C_MRO   => C_MRC and C_MRR,
      C_MRW   => false
    )
    port map(
      INPUT   => sPtrn,
      OUTPUT  => sPtrnV
  );
  
  -- Initializes the register block. The register block provides MR with voting
  -- structure accordingly to the 'C_MRL' and 'C_MRO' parameter.
  REGs: entity work.mrRegister
  generic map (
    C_WIDTH => C_WIDTH,
    C_MR    => C_MRR,
    C_MRL   => C_MRL,
    C_MRI   => C_MRC,
    C_MRO   => C_MRO,
    C_MRW   => false
  )
  port map(
    CLK     => CLK,
    RST     => RST,
    INPUT   => sPtrnV,
    OUTPUT  => OPTRN
  );
  
  -- SYNTHESIS TRANSLATE_OFF
  -- The ERR process injects errors at various posiiton within the CLB block, depending
  -- on the current 'CS_MODE' and at the condition that the 'CS_ERR' variabled matches
  -- the current CLB 'CS_ID'set in the rt package for the error class:
  -- 'CS_MODE = 0' No error injection.
  -- 'CS_MODE = 1' Complete override, the error is injected at the output of the CLB.
  -- 'CS_MODE = 2' Error injected after the combinatorial logic.
  -- 'CS_MODE = 3' Error injected after the combinatorial logic voter(s).
  -- 'CS_MODE = 4' Error injected after the register(s).
  -- 'CS_MODE = 5' Error injected after the register(s) voter(s).
  -- This part of the code is compiled only during simulation, so the synthesis
  -- of the entity it is not affected in any way. It uses the protected structure
  -- 'cErr' to both time and generate the error events.
  ERR : process(CLK, RST, sPtrn, sPtrnV) 
    begin
      if (rising_edge(CLK)) then
      --if (RST = '0') then
        if (RST = '1') then --@ksielewi
          cErr.reset;
          OPTRN <= release;
        else
          -- Update the clocks count on the 'cErr' structure.
          cErr.clk;

          -- In case the error status is ON, inject the error signal.
          if (cErr.flag(C_ID) = true) then
            case cErr.mode(C_ID) is
              when 1 => OPTRN(C_WIDTH - 1 downto 0) <= force cErr.rndError(IPTRN(C_WIDTH - 1 downto 0));
              when 2 => sPtrn(C_WIDTH - 1 downto 0) <= force cErr.rndError(IPTRN(C_WIDTH - 1 downto 0));
              when 3 => sPtrnV(C_WIDTH - 1 downto 0) <= force cErr.rndError(sPtrn(C_WIDTH - 1 downto 0));
              --when 4 => rPtrn(C_WIDTH - 1 downto 0) <= force cErr.rndError(sPtrnV(C_WIDTH - 1 downto 0));
              --when 5 => rPtrnV(C_WIDTH - 1 downto 0) <= force cErr.rndError(rPtrn(C_WIDTH - 1 downto 0));
              when others => null;   
            end case; 
          else
            case cErr.mode(C_ID) is
              when 1 => OPTRN  <= release;
              when 2 => sPtrn  <= release;
              when 3 => sPtrnV <= release;
              --when 4 => rPtrn  <= release;
              --when 5 => rPtrnV <= release;
              when others => null;
            end case;
          end if;
      end if;
    end if;
  end process;
  -- SYNTHESIS TRANSLATE_ON

end Behavioral;
