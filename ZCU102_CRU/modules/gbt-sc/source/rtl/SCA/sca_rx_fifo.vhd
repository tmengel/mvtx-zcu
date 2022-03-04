-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief SCA Control - SCA RX FIFO
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;
--! Used to convert std_logic_vector to integer and manage fifo pointer
use ieee.numeric_std.all;

--! @brief SCA_rx_fifo Entity - SCA RX FIFO
--! @details
--! The SCA_rx_fifo is used to store the deserialized bytes from
--! the EC line. Then, the bytes are concatenate to provide one 
--! word command when a delimiter (EOF) is received.
entity sca_rx_fifo is
    generic (
        g_DEPTH         : integer := 20;                                        --! Depth of the FIFO
        g_SIZE          : integer := 8                                          --! Size of the input vectors
    );
    port (
        rx_clk_i        : in std_logic;                                         --! Rx clock (Rx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        clk_en          : in std_logic;                                         --! Rx clock enable signal must be used in case of multi-cycle path(rx_clk_i > LHC frequency). By default: always enabled
		  
        reset_i         : in std_logic;                                         --! Reset the FIFO
        
        -- Data
        data_i          : in  std_logic_vector((g_SIZE-1) downto 0);            --! Input word (g_DEPTH length)
        data_o          : out std_logic_vector(((g_SIZE*g_DEPTH)-1) downto 0);  --! Output word (g_DEPTH*g_SIZE length)

        -- Control
        new_word_i      : in  std_logic;                                        --! Equivalent to a read command. It reset the FIFO and concatanate all of the words of the memory to the data_o output register
        write_i         : in  std_logic;                                        --! Request a write into the FIFO
        
        --Status
        to_be_read_o    : out std_logic;                                        --! Flag generated when new_word command is received and FIFO len > 0
        len_o           : out std_logic_vector(7 downto 0)                      --! Number of bytes stored into the FIFO
    );
end sca_rx_fifo;


--! @brief SCA_rx_fifo Architecture - SCA RX FIFO
--! @details 
--! The SCA_rx_fifo architecture implements the logic to save data with a specific
--! size and concatenate and the memory array to provide a unique word output when
--! a new_word_i flag is received.
architecture behaviour of sca_rx_fifo is

    -- Types
    subtype reg is std_logic_vector((g_SIZE-1) downto 0);
    type ramreg_t is array(integer range<>) of reg;
    
    -- Signals
    signal mem_arr: ramreg_t(g_DEPTH-1 downto 0);    
    signal wr_ptr: integer range 0 to g_DEPTH-1;
    
begin                 --========####   Architecture Body   ####========-- 

    ram_proc: process(reset_i, rx_clk_i)
    begin

        if rising_edge(rx_clk_i) then
		  
		      if reset_i = '1' then
					wr_ptr                  <= 0;
					data_o                  <= (others => '0');
					
					for i in 0 to g_DEPTH-1 loop
						 mem_arr(i)          <= (others => '0');
					end loop;
						 
			   elsif clk_en = '1' then

					to_be_read_o            <= '0';
					
					if write_i = '1' then
						 mem_arr(wr_ptr)     <= data_i;
						 wr_ptr              <= wr_ptr + 1;
					
					elsif new_word_i = '1' and wr_ptr > 0 then

						 to_be_read_o        <= '1';
						 len_o               <= std_logic_vector(to_unsigned(wr_ptr,8));
						 wr_ptr              <= 0;
						 
						 for i in 0 to g_DEPTH-1 loop
							  mem_arr(i)      <= (others => '0');
						 end loop;
					
						 for i in 1 to g_DEPTH loop
							  data_o(((8*i)-1) downto ((i-1)*8))  <= mem_arr(i-1);
						 end loop;

					end if;
				end if;	
        end if;
        
    end process;

end behaviour;
--============================================================================--
--############################################################################--
--============================================================================--
