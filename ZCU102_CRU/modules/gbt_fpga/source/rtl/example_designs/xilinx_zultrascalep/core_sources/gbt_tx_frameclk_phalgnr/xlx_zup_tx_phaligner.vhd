----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.01.2016 17:21:58
-- Design Name: 
-- Module Name: xlx_k7v7_phaligner_mmcm_controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity xlx_zup_tx_phaligner is
  Port ( 
      -- Reset
      RESET_IN              : in std_logic;
      
      -- Clocks
      CLK_IN                : in std_logic;
      CLK_OUT               : out std_logic;
      
      -- Control
      SHIFT_IN              : in std_logic;
      SHIFT_COUNT_IN        : in std_logic_vector(7 downto 0);
      
      -- Status
      LOCKED_OUT            : out std_logic
  );
end xlx_zup_tx_phaligner;

architecture Behavioral of xlx_zup_tx_phaligner is
    -- COMPONENTS
    COMPONENT xlx_zup_tx_pll PORT(
      clk_in1: in std_logic;
      RESET: in std_logic;
      CLK_OUT1: out std_logic;
      LOCKED: out std_logic;
      psclk             : in     std_logic;
      psen              : in     std_logic;
      psincdec          : in     std_logic;
      psdone            : out    std_logic
    );
    END COMPONENT;
   
    -- SIGNALS
    signal txPLLLocked_s               : std_logic;
	signal shift_to_mmcm               : std_logic;
    signal done_from_mmcm              : std_logic;
    signal phaseShiftCmd_to_ctrller    : std_logic;
    
    signal shiftDoneLatch              : std_logic;
    
begin

    --==================================--
    -- Tx PLL                           -- 
    --==================================--
    txPll: xlx_zup_tx_pll
      port map (
         clk_in1                                  => CLK_IN,
         CLK_OUT1                                 => CLK_OUT,
         -----------------------------------------  
         RESET                                    => RESET_IN,
         LOCKED                                   => txPLLLocked_s,
         
         psclk                                    => CLK_IN,
         psen                                     => shift_to_mmcm,
         psincdec                                 => '1',
         psdone                                   => done_from_mmcm
      );
        
--    latchProc: process(CLK_IN, RESET_IN)
--    begin  
    
--        if RESET_IN = '1' then
--            LOCKED_OUT <= '0';
            
--        elsif rising_edge(CLK_IN) then
        
--            if shiftDoneLatch = '1' then
--                LOCKED_OUT <= '1';
--            end if;
            
--        end if;
        
--    end process;
    
    LOCKED_OUT <= txPLLLocked_s;
    
    mmcm_inst: entity work.phaligner_mmcm_controller
      Port map(
          CLK_I                 => CLK_IN,
          RESET_I               => RESET_IN,
          
          PHASE_SHIFT_TO_MMCM   => shift_to_mmcm,
          SHIFT_DONE_FROM_MMCM  => done_from_mmcm,
          
          PHASE_SHIFT           => SHIFT_IN,
          SHIFT_DONE            => shiftDoneLatch,
          PLL_LOCKED            => txPLLLocked_s,
          
          SHIFT_CNTER           => SHIFT_COUNT_IN
       );
   
end Behavioral;
