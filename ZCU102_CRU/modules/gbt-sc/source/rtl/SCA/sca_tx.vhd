-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief SCA control - SCA TX (HDLC encoder)
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;
--! Used to convert std_logic_vector to integer and use math functions (adder)
use ieee.numeric_std.all;

--! Include the work library
library work;
--! Use SCA Package to define specific types (vector arrays)
use work.SCA_PKG.all;

--! @brief SCA_tx Entity - Tx encoding/serialization
--! @details 
--! The IC_tx entity performs the HDLC encoding in parallel 
--! of the serialization process.
entity sca_tx is
    port (
        clock           : in  std_logic;                        --! Tx clock (Tx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        clk_en          : in  std_logic;                        --! Tx clock enable signal must be used in case of multi-cycle path(tx_clk_i > LHC frequency). By default: always enabled
		  
        reset           : in  std_logic;                        --! Reset TX datapath
        
        start_input     : in  std_logic;                        --! Send the command set in input
        start_connect   : in  std_logic;                        --! Send a connect command
        start_reset     : in  std_logic;                        --! Send a reset command
    
        address         : in  std_logic_vector(7 downto 0);     --! Command: address field (According to the SCA manual)
        control         : in  std_logic_vector(7 downto 0);     --! Command: control field (According to the SCA manual)
        transID         : in  std_logic_vector(7 downto 0);     --! Command: transaction ID field (According to the SCA manual)
        channel         : in  std_logic_vector(7 downto 0);     --! Command: channel field (According to the SCA manual)
        len             : in  std_logic_vector(7 downto 0);     --! Command: Len field (not used anymore, fixed to 4 bytes)
        command         : in  std_logic_vector(7 downto 0);     --! Command: command field (According to the SCA manual)
        data            : in  std_logic_vector(31 downto 0);    --! Command: data field (According to the SCA manual)
        data_out        : out std_logic_vector(1 downto 0);     --! (TX) Couple of bits to be connected to the SCA link
    
        --Debug
        crc_inj_err     : in  std_logic                         --! Emulate a CRC error
    
    );   
end sca_tx;

--! @brief SCA_tx Architecture - Tx encoding/serialization
--! @details 
--! The SCA_tx architecture describes the logic used to generate the encoded frame
--! defined by the SCA manual. It is based on a state machine running at the tx_clock
--! frequency. Everytime the process is executed, two bits are generated and mapped
--! to the EC line.
architecture behaviour of sca_tx is

    -- Constants
    constant IDLE_PACKET        : std_logic_vector(7 downto 0)    := "01111111";    --! Idle pattern as defined by the HDLC standard
    constant DELIMITER_PACKET   : std_logic_vector(7 downto 0)    := "01111110";    --! Delimiter packet as defined by the HDLC standard (SOF/EOF)
    
    -- Type
    --! The hdlcstate_t type defines the states available for the hdlcproc process
    type    hdlc_state_t    is  (   s0_waitForStart, 
                                    s1_waitForIdleFinished, 
                                    s2_sendSOF, 
                                    s3_sendCommand, 
                                    s4_sendCRC, 
                                    s5_sendEOF
                                );

    -- Signals
    signal hdlc_state           : hdlc_state_t := s0_waitForStart;                  --! HDLC encoding FSM state register
    
    signal cmd_reg              : reg8_arr(9 downto 0);                             --! Set of 8bit register that contains the command to be sent
    signal cmd_len              : integer range 0 to 10;                            --! Register to save the length of the command
    
    signal crc                  : std_logic_vector(15 downto 0);                    --! Register used to generate the CRC                   
    signal rev_crc              : std_logic_vector(15 downto 0);                    --! Inverted CRC
    
    signal ctrl_cnt             : unsigned(2 downto 0);                             --! Internal control counter used to number the packet (must be incremented everytime a new command is sent)

begin                 --========####   Architecture Body   ####========-- 
    
    rev_crc     <= reverse_v(crc);

    -- HDLC process
    --! The hdlcproc process encodes and serializes the command into the two
    --! bits of the EC line.
    --! The process implements the following state machine:
    --!     * *s0_waitForStart*: Serializes the IDLE_PACKET word until a start command. Upon a start, the cmd_reg set of register is filled out and the encoding start.
    --!     * *s1_waitForIdleFinished*: Sends the end of the IDLE_PACKET word.
    --!     * *s2_sendSOF*: Sends the SOF DELIMITER_PACKET word.
    --!     * *s3_sendCommand*: Sends the command registered into the cmd_reg with '0' insertion and CRC computing.
    --!     * *s4_sendCRC*: Sends the CRC computed during the previous stage (incl. '0' insertion).
    --!     * *s5_sendEOF*: Sends the EOF DELIMITER_PACKET word.
    hdlcproc: process(clock, reset)
    
        variable offset_pos         : integer range 0 to 17 := 0;
        variable reg_pos            : integer range 0 to 11 := 0;
        variable high_lvl_cnter     : integer range 0 to 6  := 0;
        
    begin
    
        if rising_edge(clock) then
		  
			if reset = '1' then
				data_out        <= "11";
				offset_pos      := 0;
				reg_pos         := 0;
				ctrl_cnt        <= (others => '0');
				cmd_len         <= 0;
            
			elsif clk_en = '1' then
            
				case hdlc_state is

					when s0_waitForStart        =>    
						-- Generate tx_data_o
						if offset_pos <= 6 then
							data_out(1) <= IDLE_PACKET(offset_pos);
							data_out(0) <= IDLE_PACKET(offset_pos+1);
							
							offset_pos  := offset_pos + 2;
						
							if offset_pos > 7 then
								offset_pos  := 0;
							end if;                        
							
						elsif offset_pos > 6 then                    
							data_out(1) <= IDLE_PACKET(7);
							data_out(0) <= IDLE_PACKET(0);
							
							offset_pos  := 1;
						end if;
						
						-- First word is always the address
						cmd_reg(0) <= (address);
						
						-- Send command asked
						if start_input = '1' then

							-- Control field computing
							if crc_inj_err = '0' then
								ctrl_cnt                <= ctrl_cnt + 1;
							end if;
							
							cmd_reg(1)(7)           <= control(3) and not(control(0));
							cmd_reg(1)(6)           <= control(2) and not(control(0));
							cmd_reg(1)(5)           <= control(1) and not(control(0));
							cmd_reg(1)(4)           <= '0';
							cmd_reg(1)(3 downto 1)  <= std_logic_vector(ctrl_cnt);
							cmd_reg(1)(0)           <= '0';

							-- Save in register
							cmd_reg(2)              <= (transID);
							cmd_reg(3)              <= (channel);
							cmd_reg(4)              <= (len);
							cmd_reg(5)              <= (command);    

							-- JM: Not supported anymore because of SCA's issues
							
							--if len = x"01" or len = x"02" then
							--    cmd_reg(6)          <= (data(23 downto 16));
							--    cmd_reg(7)          <= (data(31 downto 24));
							--    cmd_reg(8)          <= x"00";
							--    cmd_reg(9)          <= x"00";
							--    
							--    cmd_len             <= 8;
								
							--elsif len = x"03" or len = x"04" then
								cmd_reg(6)          <= (data(23 downto 16));
								cmd_reg(7)          <= (data(31 downto 24));
								cmd_reg(8)          <= (data(7 downto 0));
								cmd_reg(9)          <= (data(15 downto 8));
								
								cmd_len             <= 10;
							
							--else
							--    cmd_reg(6)          <= (others => '0');
							--    cmd_reg(7)          <= (others => '0');
							--    cmd_reg(8)          <= (others => '0');
							--    cmd_reg(9)          <= (others => '0');
							--    
							--    cmd_len             <= 10;
							--
							--end if;
							
							offset_pos              := 0;
							hdlc_state              <= s1_waitForIdleFinished;

						-- Send connect asked
						elsif start_connect = '1' then    
							cmd_reg(1)              <= x"2F";
							cmd_reg(2)              <= (others => '0');
							cmd_len                 <= 2;
							
							offset_pos              := 0;
							hdlc_state              <= s1_waitForIdleFinished;

						-- Send reset asked
						elsif start_reset = '1' then    
							cmd_reg(1)              <= x"8F";
							cmd_reg(2)              <= (others => '0');
							cmd_len                 <= 2;
							
							offset_pos              := 0;
							hdlc_state              <= s1_waitForIdleFinished;
							
						end if;
						
					when s1_waitForIdleFinished =>    
						-- Send 8 times '1'
						data_out        <= "11";
						offset_pos      := offset_pos + 2;
						
						if offset_pos > 7 then
							hdlc_state  <= s2_sendSOF;
							offset_pos  := 0;
						end if;
					
					when s2_sendSOF             =>    
						
						-- Send 8 times '1'
						data_out(1)        <= DELIMITER_PACKET(offset_pos);
						data_out(0)        <= DELIMITER_PACKET(offset_pos+1);
						offset_pos         := offset_pos + 2;
						
						if offset_pos > 7 then
							hdlc_state  <= s3_sendCommand;
							reg_pos     := 0;
							offset_pos  := 0;
							
							if crc_inj_err = '1' then
								crc         <= x"0000";
								
							else
								crc         <=  nextCRC16_D8(
													reverse_v(cmd_reg(0)), 
													x"FFFF"
												);
							end if;
							
						end if;
					
						high_lvl_cnter     := 0;
					
					when s3_sendCommand         =>                  
					
						-- Enough data to send 2 bits?
						if offset_pos < 7 then
						
							-- (MSB) Bit stuffing?
							if high_lvl_cnter >= 5 then
							
								data_out(1)        <= '0';
								high_lvl_cnter     := 0;
							
							-- (MSB) Send data
							else
							
								data_out(1)        <= cmd_reg(reg_pos)(offset_pos);
								if cmd_reg(reg_pos)(offset_pos) = '1' then
									high_lvl_cnter := high_lvl_cnter + 1;
								else
									high_lvl_cnter := 0;
								end if;
								
								offset_pos         := offset_pos + 1;
							
							end if;
						
							-- (LSB) Bit stuffing?
							if high_lvl_cnter >= 5 then
							
								data_out(0)        <= '0';
								high_lvl_cnter     := 0;
							
							-- (LSB) Send data
							else
							
								data_out(0)        <= cmd_reg(reg_pos)(offset_pos);
								if cmd_reg(reg_pos)(offset_pos) = '1' then
									high_lvl_cnter := high_lvl_cnter + 1;
								else
									high_lvl_cnter := 0;
								end if;
								
								offset_pos         := offset_pos + 1;
							
							end if;
							
							-- End of command?
							if offset_pos = 8 then
							
								offset_pos      := 0;
								
								if reg_pos < (cmd_len-1) then
									reg_pos         :=  reg_pos + 1;
									crc             <=  nextCRC16_D8(
															reverse_v(
																cmd_reg(reg_pos)
															),
															crc
														);
								else
									hdlc_state      <= s4_sendCRC;
								end if;
								
							end if;
						
						-- 1 bit still have to been sent, then CRC
						elsif offset_pos < 8 then
						
							-- (MSB) Bit stuffing?
							if high_lvl_cnter >= 5 then
							
								high_lvl_cnter  := 0;
								
								data_out(1)     <= '0';
								data_out(0)     <= cmd_reg(reg_pos)(7);
								
								if cmd_reg(reg_pos)(offset_pos) = '1' then
									high_lvl_cnter     := high_lvl_cnter + 1;
								else
									high_lvl_cnter     := 0;
								end if;
								
								offset_pos      := 0;
								
								if reg_pos < (cmd_len-1) then
									reg_pos         :=  reg_pos + 1;
									crc             <=  nextCRC16_D8(
															reverse_v(
																cmd_reg(reg_pos)
															), 
															crc
														);
								else
									hdlc_state      <= s4_sendCRC;
								end if;
								
							-- (MSB) Send data
							else
							
								data_out(1)        <= cmd_reg(reg_pos)(7);
								if cmd_reg(reg_pos)(offset_pos) = '1' then
									high_lvl_cnter := high_lvl_cnter + 1;
								else
									high_lvl_cnter := 0;
								end if;
								
							
								-- (LSB) Bit stuffing?
								if reg_pos < (cmd_len-1) then
								
									reg_pos         :=  reg_pos + 1;
									crc             <=  nextCRC16_D8(
															reverse_v(
																cmd_reg(reg_pos)
															), 
															crc
														);
									
									if high_lvl_cnter >= 5 then
										data_out(0)     <= '0';
										high_lvl_cnter  := 0;
										offset_pos      := 0;
										
									else
										data_out(0)     <= cmd_reg(reg_pos)(0);
										if cmd_reg(reg_pos)(0) = '1' then
											high_lvl_cnter := high_lvl_cnter + 1;
										else
											high_lvl_cnter := 0;
										end if;
										
										offset_pos      := 1;
									end if;
										
								else
									if high_lvl_cnter >= 5 then
										data_out(0)     <= '0';
										high_lvl_cnter  := 0;
										offset_pos      := 0;
									
									else
										data_out(0)     <= rev_crc(0);
										if rev_crc(0) = '1' then
											high_lvl_cnter := high_lvl_cnter + 1;
										else
											high_lvl_cnter := 0;
										end if;

										offset_pos      := 1;    
										
									end if;
									
									hdlc_state      <= s4_sendCRC;
								
								end if;
								
							end if;
						
						end if;
					
					when s4_sendCRC             =>
					
						-- Enough data to send 2 bits?
						if offset_pos < 15 then
						
							-- (MSB) Bit stuffing?
							if high_lvl_cnter >= 5 then
							
								data_out(1)        <= '0';
								high_lvl_cnter     := 0;
							
							-- (MSB) Send data
							else
							
								data_out(1)         <= rev_crc(offset_pos);
								if rev_crc(offset_pos) = '1' then
									high_lvl_cnter := high_lvl_cnter + 1;
								else
									high_lvl_cnter := 0;
								end if;
								
								offset_pos          := offset_pos + 1;
							
							end if;
						
							-- (LSB) Bit stuffing?
							if high_lvl_cnter >= 5 then
							
								data_out(0)        <= '0';
								high_lvl_cnter     := 0;
							
							-- (LSB) Send data
							else
							
								data_out(0)        <= rev_crc(offset_pos);
								if rev_crc(offset_pos) = '1' then
									high_lvl_cnter := high_lvl_cnter + 1;
								else
									high_lvl_cnter := 0;
								end if;
								
								offset_pos      := offset_pos + 1;
							
							end if;
							
							-- End of command?
							if offset_pos = 16 then
							
								offset_pos      := 0;
								hdlc_state      <= s5_sendEOF;
								
							end if;
						
						-- 1 bit still have to been sent, then CRC
						elsif offset_pos < 16 then
						
							-- (MSB) Bit stuffing?
							if high_lvl_cnter >= 5 then
							
								high_lvl_cnter  := 0;
								
								data_out(1)     <= '0';
								data_out(0)     <= rev_crc(offset_pos);
								
								if rev_crc(offset_pos) = '1' then
									high_lvl_cnter     := 0;
								end if;
								
								offset_pos      := 0;
								hdlc_state      <= s5_sendEOF;
								
							-- (MSB) Send data
							else
							
								data_out(1)        <= rev_crc(offset_pos);
								if rev_crc(offset_pos) = '1' then
									high_lvl_cnter := high_lvl_cnter + 1;
								else
									high_lvl_cnter := 0;
								end if;
							
								-- (LSB) Bit stuffing?
								if high_lvl_cnter >= 5 then
									data_out(0)     <= '0';
									
									high_lvl_cnter  := 0;
									offset_pos      := 0;
									hdlc_state      <= s5_sendEOF;

								else
									
									data_out(0)     <= DELIMITER_PACKET(0);
									offset_pos      := 1;
									hdlc_state      <= s5_sendEOF;
									
								end if;
							end if;
						
						end if;    
					
					when s5_sendEOF             =>  
					
						if offset_pos <= 6 then
							data_out(1) <= DELIMITER_PACKET(offset_pos);
							data_out(0) <= DELIMITER_PACKET(offset_pos+1);
							
							offset_pos  := offset_pos + 2;
							
							if offset_pos > 7 then
								offset_pos      := 0;
								hdlc_state      <= s0_waitForStart;
							end if;
							
						elsif offset_pos > 6 then                    
							data_out(1) <= DELIMITER_PACKET(7);
							data_out(0) <= IDLE_PACKET(0);
							
							offset_pos      := 1;
							hdlc_state      <= s0_waitForStart;
						end if;
						
				end case;
			end if;
        end if;
    end process;
    
end behaviour;
--============================================================================--
--############################################################################--
--============================================================================--