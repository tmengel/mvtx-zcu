-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @version 6.0
--! @brief GBT-FPGA IP - Transceiver reset synchronizer
-------------------------------------------------------

--! IEEE VHDL standard library:
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! @brief xlx_zup_mgt_ip_reset_synchronizer - Transceiver reset synchronizer
--! @details 
--! The xlx_zup_mgt_ip_reset_synchronizer synchronizes the resets with a specific clock domain
entity xlx_zup_mgt_ip_reset_synchronizer is                                            
   port (
      CLK_IN           : in  std_logic;
      RST_IN           : in  std_logic;
      RST_OUT          : out std_logic      
   );
end xlx_zup_mgt_ip_reset_synchronizer;

--! @brief xlx_zup_mgt_ip_reset_synchronizer - Transceiver reset
--! @details The xlx_zup_mgt_ip_reset_synchronizer implements a reset bridge system
architecture Behavioral of xlx_zup_mgt_ip_reset_synchronizer is

    signal rst_in_meta:     std_logic;
    signal rst_in_sync1:    std_logic;
    signal rst_in_sync2:    std_logic;
    signal rst_in_sync3:    std_logic;
    signal rst_in_out:      std_logic;
    
begin

    rstFsm_proc: process(clk_in, rst_in)
    begin
        if rst_in = '1' then
            rst_in_meta     <= '1';
            rst_in_sync1    <= '1';
            rst_in_sync2    <= '1';
            rst_in_sync3    <= '1';
            rst_in_out      <= '1';
        elsif rising_edge(clk_in) then
            rst_in_meta     <= '0';
            rst_in_sync1    <= rst_in_meta;
            rst_in_sync2    <= rst_in_sync1;
            rst_in_sync3    <= rst_in_sync2;
            rst_in_out      <= rst_in_sync3;        
        end if;
    end process;
    
    rst_out <= rst_in_out;
    
end Behavioral;
