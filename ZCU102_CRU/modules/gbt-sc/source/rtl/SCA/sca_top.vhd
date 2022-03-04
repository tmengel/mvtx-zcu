-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief SCA control - SCA top level
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;

--! Include the work library
library work;
--! Use SCA Package to define specific types (vector arrays)
use work.SCA_PKG.all;

--! @brief SCA_top Entity - SCA top level
--! @details 
--! The SCA_top entity handles the communication with the SCA modules. 
--! It generates the couple of bits encoded with the HDLC standard to
--! access the internal register of the ASIC.
entity sca_top is
    generic (
        g_SCA_COUNT         : integer := 1                                      --! Number of SCAs to be controlled through the link (up to 41)
    );
    port (
        tx_clk_i            : in  std_logic;                                    --! Tx clock (Tx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        tx_clk_en           : in  std_logic := '1';                             --! Tx clock enable signal must be used in case of multi-cycle path(tx_clk_i > LHC frequency). By default: always enabled
		  
        rx_clk_i            : in  std_logic;                                    --! Rx clock (Rx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        rx_clk_en           : in  std_logic := '1';                             --! Rx clock enable signal must be used in case of multi-cycle path(rx_clk_i > LHC frequency). By default: always enabled
		  
        rx_reset_i          : in  std_logic;                                    --! Reset RX datapath
        tx_reset_i          : in  std_logic;                                    --! Reset TX datapath
        
        enable_i            : in  std_logic_vector((g_SCA_COUNT-1) downto 0);   --! Enable flag, bit position correspond to the SCA ID ('1': enabled / '0': Disabled)
        start_reset_cmd_i   : in  std_logic;                                    --! Send a reset command to the enabled SCAs
        start_connect_cmd_i : in  std_logic;                                    --! Send a connect command to the enabled SCAs
        start_command_i     : in  std_logic;                                    --! Send the command set in input to the enabled SCAs
        inject_crc_error    : in  std_logic;                                    --! Emulate a CRC error
        
        tx_address_i        : in  std_logic_vector(7 downto 0);                 --! Command: address field (According to the SCA manual)
        tx_transID_i        : in  std_logic_vector(7 downto 0);                 --! Command: transaction ID field (According to the SCA manual)
        tx_channel_i        : in  std_logic_vector(7 downto 0);                 --! Command: channel field (According to the SCA manual)
        tx_len_i            : in  std_logic_vector(7 downto 0);                 --! Command: Len field (not used anymore, fixed to 4 bytes)
        tx_command_i        : in  std_logic_vector(7 downto 0);                 --! Command: command field (According to the SCA manual)
        tx_data_i           : in  std_logic_vector(31 downto 0);                --! Command: data field (According to the SCA manual)

        rx_received_o       : out std_logic_vector((g_SCA_COUNT-1) downto 0);   --! Reply received flag (pulse), bit position correspond to the SCA ID
        rx_address_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);           --! Reply: address field (According to the SCA manual)
        rx_control_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);           --! Reply: control field (According to the SCA manual)
        rx_transID_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);           --! Reply: transaction ID field (According to the SCA manual)
        rx_channel_o        : out reg8_arr((g_SCA_COUNT-1) downto 0);           --! Reply: channel field (According to the SCA manual)
        rx_len_o            : out reg8_arr((g_SCA_COUNT-1) downto 0);           --! Reply: len field (According to the SCA manual)
        rx_error_o          : out reg8_arr((g_SCA_COUNT-1) downto 0);           --! Reply: error field (According to the SCA manual)
        rx_data_o           : out reg32_arr((g_SCA_COUNT-1) downto 0);          --! Reply: data field (According to the SCA manual)

        tx_data_o           : out reg2_arr((g_SCA_COUNT-1) downto 0);           --! (TX) Array of 2 bits to be mapped to the TX GBT-Frame
        rx_data_i           : in  reg2_arr((g_SCA_COUNT-1) downto 0)            --! (RX) Array of 2 bits to be mapped to the RX GBT-Frame
        
    );   
end sca_top;


--! @brief SCA control Architecture - SCA top level
--! @details 
--! The SCA top level architecture implements the TX and RX modules required
--! to handle the communication with the ASIC. Because multiple chips can
--! be controlled through one GBT link (using e-links), the instantiation is
--! duplicated. As many SCA_tx and SCA_rx components as SCAs ASICs to be 
--! controlled are instantiated. The SCA_gen instance multiplies the module 
--! number using a generate for loop.
architecture behaviour of sca_top is

    -- Signals
    signal tx_control_s     : reg8_arr((g_SCA_COUNT-1) downto 0);           --! Control field of the HDLC frame is used to acknowledge the command received. Then this field is managed internally, using the received value
    signal rx_control_s     : reg8_arr((g_SCA_COUNT-1) downto 0);           --! Received control field value
    
    signal start_command_s  : std_logic_vector((g_SCA_COUNT-1) downto 0);   --! Used to detect a start_command request with enable = '1' for a specific SCA link
    signal start_connect_s  : std_logic_vector((g_SCA_COUNT-1) downto 0);   --! Used to detect a start_connect request with enable = '1' for a specific SCA link
    signal start_reset_s    : std_logic_vector((g_SCA_COUNT-1) downto 0);   --! Used to detect a start_reset request with enable = '1' for a specific SCA link
    
    -- Components
    --! @brief SCA_rx Entity - RX deserializer/decoder
    --! @details 
    --! The SCA_rx entity handles the deserialization and decoding
    --! of the received frame on the couple of bits dedicated to
    --! the SCA control.
    component sca_rx is
        port (
            -- Clock & reset
            rx_clk_i        : in std_logic;
            clk_en          : in  std_logic;
		  
            reset_i         : in std_logic;
            
            -- Satus
            done_o          : out std_logic;
            crc_err_o       : out std_logic;    -- Not supported yet
            
            -- RX data
            address_o       : out std_logic_vector(7 downto 0);
            control_o       : out std_logic_vector(7 downto 0);
            transID_o       : out std_logic_vector(7 downto 0);
            channel_o       : out std_logic_vector(7 downto 0);
            len_o           : out std_logic_vector(7 downto 0);
            error_o         : out std_logic_vector(7 downto 0);
            data_o          : out std_logic_vector(31 downto 0);
            
            -- IC Line
            rx_data_i       : in std_logic_vector(1 downto 0)
        );   
    end component sca_rx;
    
    --! @brief SCA_tx Entity - Tx encoding/serialization
    --! @details 
    --! The IC_tx entity performs the HDLC encoding in parallel 
    --! of the serialization process.
    component sca_tx is
        port (
            clock           : in  std_logic;
            clk_en          : in  std_logic;
		  
            reset           : in  std_logic;
        
            start_input     : in  std_logic;
            start_connect   : in  std_logic;
            start_reset     : in  std_logic;
        
            address         : in  std_logic_vector(7 downto 0);
            control         : in  std_logic_vector(7 downto 0);
            transID         : in  std_logic_vector(7 downto 0);
            channel         : in  std_logic_vector(7 downto 0);
            len             : in  std_logic_vector(7 downto 0);
            command         : in  std_logic_vector(7 downto 0);
            data            : in  std_logic_vector(31 downto 0);
            data_out        : out std_logic_vector(1 downto 0);

            --Debug
            crc_inj_err     : in  std_logic
        
        );
    end component sca_tx;
    
begin           --========####   Architecture Body   ####========-- 

    sca_gen: for i in 0 to (g_SCA_COUNT-1) generate

        start_command_s(i)      <= enable_i(i) and start_command_i;
        start_connect_s(i)      <= enable_i(i) and start_connect_cmd_i;
        start_reset_s(i)        <= enable_i(i) and start_reset_cmd_i;

        --! @brief Time domain crossing (control field)
        --! @details
        --! Clock domain crossing for the control field is managed inside
        --! of the ctrl_timedomain_crossing process. It just consist in
        --! clocking the rx_control_s signal with the tx_clock.
        --! Because no command must be sent before receiving the reply of
        --! the previous one, we do not have any timing issue with the control
        --! register.
        ctrl_timedomain_crossing: process(tx_reset_i, tx_clk_i)
        begin
        
            if rising_edge(tx_clk_i) then
				
                if tx_reset_i = '1' then
                    tx_control_s(i)    <= x"00";
                else
                    tx_control_s(i)    <= rx_control_s(i);
                end if;
                
            end if;
            
        end process;
        
        -- TX: The command is sent to all of the SCA enabled
        tx_inst: sca_tx
            port map (
                clock           => tx_clk_i,
                clk_en          => tx_clk_en,
					 
                reset           => tx_reset_i,

                start_input     => start_command_s(i),
                start_connect   => start_connect_s(i),
                start_reset     => start_reset_s(i),

                address         => tx_address_i,
                control         => tx_control_s(i),
                transID         => tx_transID_i,
                channel         => tx_channel_i,
                len             => tx_len_i,
                command         => tx_command_i,
                data            => tx_data_i,

                data_out        => tx_data_o(i),
                
                crc_inj_err     => inject_crc_error -- Used for test only
            );
        
        -- RX: individual for each SCA
        rx_inst: sca_rx
            port map(
                rx_clk_i        => rx_clk_i,
                clk_en          => rx_clk_en,
					 
                reset_i         => rx_reset_i,
                
                done_o          => rx_received_o(i),
                
                address_o       => rx_address_o(i),
                control_o       => rx_control_s(i),
                transID_o       => rx_transID_o(i),
                channel_o       => rx_channel_o(i),
                len_o           => rx_len_o(i),
                error_o         => rx_error_o(i),
                data_o          => rx_data_o(i),
                
                rx_data_i       => rx_data_i(i)
            );
   
        rx_control_o(i)         <= rx_control_s(i);

    end generate;
    
end behaviour;
--============================================================================--
--############################################################################--
--============================================================================--'