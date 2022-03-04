-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief SCA control - SCA RX (HDLC decoder)
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;
--! Used to convert std_logic_vector to integer and manage fifo pointer
use ieee.numeric_std.all;

--! @brief SCA_rx Entity - SCA RX (HDLC decoder)
--! @details 
--! The SCA_rx entity handles the deserialization and decoding
--! of the received frame on the couple of bits dedicated to
--! the EC control.
entity sca_rx is
    port (
        -- Clock & reset
        rx_clk_i        : in std_logic;                         --! Rx clock (Rx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        clk_en          : in std_logic;                         --! Rx clock enable signal must be used in case of multi-cycle path(rx_clk_i > LHC frequency). By default: always enabled
		  
        reset_i         : in std_logic;                         --! Reset RX datapath
        
        -- Satus
        done_o          : out std_logic;                        --! Reply received flag (pulse)
        crc_err_o       : out std_logic;                        --! CRC Error detected on received frame (not supported yet)
        
        -- RX data
        address_o       : out std_logic_vector(7 downto 0);     --! Reply: address field (According to the SCA manual)
        control_o       : out std_logic_vector(7 downto 0);     --! Reply: control field (According to the SCA manual)
        transID_o       : out std_logic_vector(7 downto 0);     --! Reply: transaction ID field (According to the SCA manual)
        channel_o       : out std_logic_vector(7 downto 0);     --! Reply: channel field (According to the SCA manual)
        len_o           : out std_logic_vector(7 downto 0);     --! Reply: len field (According to the SCA manual)
        error_o         : out std_logic_vector(7 downto 0);     --! Reply: error field (According to the SCA manual)
        data_o          : out std_logic_vector(31 downto 0);    --! Reply: data field (According to the SCA manual)
        
        -- IC Line
        rx_data_i       : in std_logic_vector(1 downto 0)       --! (RX) EC line from the RX GBT-Frame
    );   
end sca_rx;

--! @brief SCA_rx Architecture - SCA RX (HDLC decoder)
--! @details 
--! The SCA_rx architecture implements the components and logic used to manage the EC line
--! in order to decode the data received from the SCA and format the command received. The
--! deserializer synchronize and control a FIFO. The deserialized bytes are saved and
--! set in output of the FIFO when a delimiter packet is detected (EOF). Finally, a few
--! logic elements are implemented to format the reply and to connect the data to the reply buses.
architecture behaviour of sca_rx is

    -- Signals
    signal byte_from_des_s      : std_logic_vector(7 downto 0);     --! Deserialized word (from deserializer)
    signal wr_command_s         : std_logic;                        --! Write command to the internal FIFO (from deserializer)
    signal delimiter_detected_s : std_logic;                        --! Delimiter detected flag (from deserializer), used to generate reply received flag

    signal cmd_v                : std_logic_vector(159 downto 0);   --! parallelized command (from FIFO)

    signal data_word_s2         : std_logic_vector(31 downto 0);    --! Data word from the command when len = 2 bytes
    signal data_word_s4         : std_logic_vector(31 downto 0);    --! Data word from the command when len = 4 bytes
    signal len_s                : std_logic_vector(7 downto 0);     --! Computed length of the command (field value from the SCA is wrong)
    
    signal fifo_cnt             : std_logic_vector(7 downto 0);     --! Number of word in FIFO (std_logic_vector)
    signal fifo_cnt_i           : integer range 0 to 15;            --! Number of word in FIFO (integer - used to compute the reply length)
    signal len_from_fifo        : integer range 0 to 15;            --! Computed data length (number of word in FIFO - 8 bytes of header)  
    
    signal rx_received_s        : std_logic;                        --! Reply received flag (from FIFO)

    -- Components
    --! @brief SCA_Deserializer Entity - EC line deserializer
    --! @details 
    --! The SCA_Deserializer entity deserializes the EC line and control the FIFO
    --! to save the 8bit words.
    component sca_deserializer is
        generic (
            g_WORD_SIZE        : integer := 8;
            g_DELIMITER        : std_logic_vector(7 downto 0) := "01111110";
            g_IDLE             : std_logic_vector(7 downto 0) := "01111111"
        );
        port (
            rx_clk_i           : in  std_logic;
            clk_en             : in  std_logic;
		  
            reset_i            : in  std_logic;

            -- Data
            data_i             : in  std_logic_vector(1 downto 0);
            data_o             : out std_logic_vector((g_WORD_SIZE-1) downto 0);

            -- Control & status
            write_o            : out std_logic;        
            delimiter_found_o  : out std_logic
        );
    end component sca_deserializer;

    --! @brief SCA_Rx_FIFO Entity - EC RX FIFO
    --! @details 
    --! The SCA_Rx_FIFO entity is used to save the deserialized word before
    --! formating the command when the frame has been fully received.
    component sca_rx_fifo is
        generic (
            g_DEPTH       : integer := 20;
            g_SIZE        : integer := 8
        );
        port (
            rx_clk_i      : in std_logic;
            clk_en        : in  std_logic;
		  
            reset_i       : in std_logic;
            
            -- Data
            data_i        : in  std_logic_vector((g_SIZE-1) downto 0);
            data_o        : out std_logic_vector(((g_SIZE*g_DEPTH)-1) downto 0);

            -- Control
            new_word_i    : in  std_logic;
            write_i       : in  std_logic;
            
            --Status
            to_be_read_o  : out std_logic;
            len_o         : out std_logic_vector(7 downto 0)
        );
    end component sca_rx_fifo;
    
begin          --========####   Architecture Body   ####========-- 

    sca_deserializer_inst: sca_deserializer
       port map(
            rx_clk_i            => rx_clk_i,
            clk_en              => clk_en,
				
            reset_i             => reset_i,
            
            -- Data
            data_i              => rx_data_i,
            data_o              => byte_from_des_s,        
            
            -- Control & status
            write_o             => wr_command_s,
            delimiter_found_o   => delimiter_detected_s
       );

    sca_rx_fifo_inst: sca_rx_fifo
       port map(
            rx_clk_i            => rx_clk_i,
            clk_en              => clk_en,
            reset_i             => reset_i,
            
            -- Data
            data_i              => byte_from_des_s,
            data_o              => cmd_v,
            
            -- Control
            write_i             => wr_command_s,
            new_word_i          => delimiter_detected_s,
            
            -- Status
            to_be_read_o        => rx_received_s,
            len_o               => fifo_cnt
       );

    -- Filters SREJ replies
    done_o         <= rx_received_s; -- when cmd_v(8) /= '1' else
                    --'0';

    -- Preparation
    fifo_cnt_i      <= to_integer(unsigned(fifo_cnt));
    
    len_from_fifo   <= fifo_cnt_i - 8 when cmd_v(8) /= '1' and fifo_cnt_i > 8
                       else 0;
    
    len_s           <= std_logic_vector(to_unsigned(len_from_fifo,8));
    --cmd_v(47 downto 40) when cmd_v(8) /= '1' else
    --                   x"00";

    data_word_s2    <= cmd_v(63 downto 56) &    -- Dx
                       cmd_v(55 downto 48) &    -- Dx
                       x"0000";                 -- LSB (x"0000")

    data_word_s4    <= cmd_v(63 downto 56) &    -- Dx
                       cmd_v(55 downto 48) &    -- Dx
                       cmd_v(79 downto 72) &    -- Dx
                       cmd_v(71 downto 64);     -- Dx

    -- Link the fields to the output
    address_o       <= cmd_v(7 downto 0);
    control_o       <= cmd_v(15 downto 8);
    transID_o       <= cmd_v(23 downto 16) when cmd_v(8) /= '1' else x"00";
    channel_o       <= cmd_v(31 downto 24) when cmd_v(8) /= '1' else x"00";
    error_o         <= cmd_v(39 downto 32) when cmd_v(8) /= '1' else x"00";
    len_o           <= std_logic_vector(to_unsigned(len_from_fifo,8));
    data_o          <= data_word_s2 when (len_s = x"01" or len_s = x"02") else
                       data_word_s4 when (len_s = x"03" or len_s = x"04") else
                       x"00000000";

end behaviour;
--============================================================================--
--############################################################################--
--============================================================================--