-------------------------------------------------------------------------------
-- Title      : GBT Pattern Generator
-- Project    : MVTX
-------------------------------------------------------------------------------
-- File       : gbt_pattern_generator.vhd
-- Author     : Jo Schambach (yj6)  <schambachjj@ornl.gov>
-- Company    : ORNL
-- Created    : 2021-09-10
-- Last update: 2021-09-10
-- Platform   : Vivado 2018.3
-- Target     : ZCU102
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Copied from GBT-FPGA project and modified locally
-------------------------------------------------------------------------------
-- Copyright (c) 2021 ORNL
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2021-09-10  1.0      yj6  Created
-------------------------------------------------------------------------------

--=================================================================================================--
--##################################   Module Information   #######################################--
--=================================================================================================--
--                                                                                         
-- Company:               CERN (PH-ESE-BE)                                                         
-- Engineer:              Manoel Barros Marin (manoel.barros.marin@cern.ch) (m.barros.marin@ieee.org)
--                        (Original design by F. Marin (CPPM) & S.Baron (CERN))   
--                                                                                                 
-- Project Name:          GBT-FPGA                                                                
-- Module Name:           GBT pattern generator                                        
--                                                                                                 
-- Language:              VHDL'93                                                                  
--                                                                                                   
-- Target Device:         Device agnostic                                                         
-- Tool version:                                                                            
--                                                                                                   
-- Version:               3.5                                                                      
--
-- Description:             
--
-- Versions history:      DATE         VERSION   AUTHOR            DESCRIPTION
--                                                                 
--                        10/05/2009   0.1       F. Marin          First .bdf entity definition           
--                                                                 
--                        07/07/2009   0.2       S. Baron          Translate from .bdf to .vhd
--                                                                 
--                        15/01/2010   0.3       S. Baron          Use of agnostic counters
--                                                                 
--                        23/06/2013   1.0       M. Barros Marin   - Cosmetic modifications
--                                                                 - Added pattern selector multiplexor
--                                                                 - Added static pattern
--                                                                 - Merged with "agnostic_21bits_counter"
--                                                                 
--                        06/08/2013   1.1       M. Barros Marin   - Added Wide-Bus extra data generation
--                                                                 
--                        12/02/2014   3.0       M. Barros Marin   - Added GBT-8b10b extra data generation
--                                                                 - Removed dynamic encoding selection
--
--                        05/10/2014   3.5       M. Barros Marin   - Added SC-IC (constant "11") & SC-EC patterns
--
--                        05/10/2014   3.6       J. Mendez         - Removed 8b10b extra data generation
--                                                                 
-- Additional Comments:                                                                               
--                                                                                                   
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--

-- IEEE VHDL standard library:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Custom libraries and packages:
use work.gbt_bank_package.all;
use work.vendor_specific_gbt_bank_package.all;
use work.gbt_exampledesign_package.all;

--=================================================================================================--
--#######################################   Entity   ##############################################--
--=================================================================================================--

entity gbt_pattern_generator is
  generic (
    CLOCKING_SCHEME : integer := BC_CLOCK
    );
  port (

    --===============--
    -- Reset & Clock --
    --===============-- 
    -- Reset:
    ---------   
    GENERAL_RST_I                      : in  std_logic;
    RESET_I                            : in  std_logic;
    -- Clock:                                 
    ---------                           
    TX_FRAMECLK_I                      : in  std_logic;
    TX_WORDCLK_I                       : in  std_logic;
    TX_FRAMECLK_O                      : out std_logic;
    TX_CLKEN_o                         : out std_logic;
    --========--                              
    -- Inputs --                              
    --========--
    -- Encoding:
    ------------
    TX_ENCODING_SEL_I                  : in  std_logic_vector(1 downto 0);
    -- Test pattern:
    ----------------
    TEST_PATTERN_SEL_I                 : in  std_logic_vector(2 downto 0);
    -----------------------------------------------
    STATIC_PATTERN_SCEC_I              : in  std_logic_vector(1 downto 0);
    STATIC_PATTERN_DATA_I              : in  std_logic_vector(79 downto 0);
    STATIC_PATTERN_EXTRADATA_WIDEBUS_I : in  std_logic_vector(31 downto 0);
    --=========--                             
    -- Outputs --                             
    --=========--                       
    -- Common data:           
    ---------------           
    TX_DATA_O                          : out std_logic_vector(83 downto 0);
    -- Wide-Bus extra data:          
    ----------------------- 
    TX_EXTRA_DATA_WIDEBUS_O            : out std_logic_vector(31 downto 0)
    );
end gbt_pattern_generator;

--=================================================================================================--
--####################################   Architecture   ###########################################-- 
--=================================================================================================--

architecture behavioral of gbt_pattern_generator is

  signal txframeclk_s : std_logic;
  signal txclken_s    : std_logic;

  constant C_LFSR_SEED : std_logic_vector(6 downto 0) := "1001000";
  signal sLFSR_rst     : std_logic                    := '0';
  signal sLFSR_o       : std_logic_vector(6 downto 0) := (others => '0');

--=================================================================================================--
begin  --========####   Architecture Body   ####========-- 
--=================================================================================================--

  --==================================== User Logic =====================================--
  bcclock_gen : if CLOCKING_SCHEME = BC_CLOCK generate

    txframeclk_s <= TX_FRAMECLK_I;
    txclken_s    <= '1';

  end generate;

  mgtclock_gen : if CLOCKING_SCHEME = FULL_MGTFREQ generate

    txframeclk_s <= TX_WORDCLK_I;

    engen_proc : process(GENERAL_RST_I, TX_WORDCLK_I)
      variable flagCnterV : integer range 0 to GBT_WORD_RATIO;
    begin
      if GENERAL_RST_I = '1' then
        txclken_s  <= '0';
        flagCnterV := 0;

      elsif rising_edge(TX_WORDCLK_I) then

        flagCnterV := flagCnterV + 1;
        if flagCnterV = GBT_WORD_RATIO then
          flagCnterV := 0;
        end if;

        txclken_s <= '0';
        if flagCnterV = 0 then
          txclken_s <= '1';
        end if;

      end if;
    end process;
  end generate;

  TX_FRAMECLK_O <= txframeclk_s;
  TX_CLKEN_o    <= txclken_s;

  -- generate LFSR patterns according to GBTx manual
  INST_LFSR : entity work.LFSR
    port map (
      CLK          => txframeclk_s,
      RST          => sLFSR_rst,
      SEED         => C_LFSR_SEED,
      PARALLEL_OUT => sLFSR_o
      );

  main : process(RESET_I, txframeclk_s)
    constant SCECCOUNTER_OVERFLOW        : integer := 2**2;
    constant COMMONWORDCOUNTER_OVERFLOW  : integer := 2**20;
    constant WIDEBUSWORDCOUNTER_OVERFLOW : integer := 2**16;
    variable scEcWordCounter             : unsigned(1 downto 0);
    variable commonWordCounter           : unsigned(19 downto 0);
    variable widebusWordCounter          : unsigned(15 downto 0);
  begin
    if RESET_I = '1' then
      scEcWordCounter         := (others => '0');
      commonWordCounter       := (others => '0');
      widebusWordCounter      := (others => '0');
      TX_DATA_O               <= (others => '0');
      TX_EXTRA_DATA_WIDEBUS_O <= (others => '0');
      sLFSR_rst               <= '1';
    elsif rising_edge(txframeclk_s) then
      -- default
      sLFSR_rst <= '1';

      if txclken_s = '1' then

        --==========================--
        -- Internal Control (SC-IC) --
        --==========================--

        -- Comment: The patter is constant "11" in order to reset the SC FSM of the GBTx ASIC.

        TX_DATA_O(83 downto 82) <= "11";

        case TEST_PATTERN_SEL_I is

--        --=========--
--        -- Counter --
--        --=========--
          when "001" =>
            -- External Control (SC-EC) counter pattern generation:
            -------------------------------------------------------               
            TX_DATA_O(81 downto 80) <= std_logic_vector(scEcWordCounter);
            if commonWordCounter = SCECCOUNTER_OVERFLOW-1 then
              scEcWordCounter := (others => '0');
            else
              scEcWordCounter := scEcWordCounter + 1;
            end if;
            -- Common data counter pattern generation:
            ------------------------------------------
            for i in 0 to 3 loop
              TX_DATA_O((20*i)+19 downto (20*i)) <= std_logic_vector(commonWordCounter);
            end loop;
            if commonWordCounter = COMMONWORDCOUNTER_OVERFLOW-1 then
              commonWordCounter := (others => '0');
            else
              commonWordCounter := commonWordCounter + 1;
            end if;
            -- Wide-Bus extra data counter pattern generation:
            ---------------------------------------------------
            if TX_ENCODING_SEL_I = "01" then
              for i in 0 to 1 loop
                TX_EXTRA_DATA_WIDEBUS_O((16*i)+15 downto (16*i)) <= std_logic_vector(widebusWordCounter);
              end loop;
              if widebusWordCounter = WIDEBUSWORDCOUNTER_OVERFLOW-1 then
                widebusWordCounter := (others => '0');
              else
                widebusWordCounter := widebusWordCounter + 1;
              end if;
            else
              TX_EXTRA_DATA_WIDEBUS_O <= (others => '0');
            end if;

--        --========--
--        -- Static --
--        --========--      
          when "010" =>
            -- External Control (SC-EC) static pattern generation:
            ------------------------------------------------------
            TX_DATA_O(81 downto 80) <= STATIC_PATTERN_SCEC_I;
                                        -- Common data static pattern generation:
                                        -----------------------------------------               
            TX_DATA_O(79 downto 0)  <= STATIC_PATTERN_DATA_I;
                                        -- Wide-Bus extra data static pattern generation:
                                        --------------------------------------------------               
            if TX_ENCODING_SEL_I = "01" then
              TX_EXTRA_DATA_WIDEBUS_O <= STATIC_PATTERN_EXTRADATA_WIDEBUS_I;
            else
              TX_EXTRA_DATA_WIDEBUS_O <= (others => '0');
            end if;

--        --======--
--        -- LFSR --
--        --======-- 
          when "111" =>
            sLFSR_rst               <= '0';
            TX_DATA_O(81 downto 80) <= '1' & sLFSR_rst;
            TX_DATA_O(79 downto 0)  <= sLFSR_o & sLFSR_o & sLFSR_o & sLFSR_o & sLFSR_o & sLFSR_o & sLFSR_o &
                                       sLFSR_o & sLFSR_o & sLFSR_o & sLFSR_o & sLFSR_o(6 downto 4);
            
--        --==========--
--        -- Disabled --
--        --==========-- 
          when others =>

            TX_DATA_O(81 downto 0)  <= (others => '0');
            TX_EXTRA_DATA_WIDEBUS_O <= (others => '0');

        end case;
      end if;
    end if;
  end process;

--=====================================================================================--
end behavioral;
--=================================================================================================--
--#################################################################################################--
--=================================================================================================--
