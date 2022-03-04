-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief IC control - Tx FIFO and encoding/serialization
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;
--! Used to convert std_logic_vector to integer and manage fifo pointer
use ieee.numeric_std.all;

--! Include the work library
library work;

--! @brief IC_tx Entity - Tx FIFO and encoding/serialization
--! @details
--! The IC_tx entity control the FIFO used to store the command to be sent
--! and perform the HDLC encoding in parallel of the serialization process.
entity ic_tx is
    generic (
        g_FIFO_DEPTH        : integer := 20                         --! Depth of the internal FIFO used to improve the timming performance
    );
   port (
        -- Clock and reset
        tx_clk_i            : in std_logic;                         --! Tx clock (Tx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        tx_clk_en           : in std_logic;                         --! Tx clock enable signal must be used in case of multi-cycle path(tx_clk_i > LHC frequency). By default: always enabled

        reset_i             : in std_logic;                         --! Reset all of the TX processes

        -- Status
        tx_ready_o          : out std_logic;                        --! IC core ready for a transaction

        -- Configuration
        GBTx_address_i      : in std_logic_vector(7 downto 0);      --! I2C address of the GBTx
        Register_addr_i     : in std_logic_vector(15 downto 0);     --! Address of the first register to be accessed
        nb_to_be_read_i     : in std_logic_vector(15 downto 0);     --! Number of words/bytes to be read (only for read transactions)

        parity_err_mask_i   : in std_logic_vector(7 downto 0);

        -- Internal FIFO
        wr_clk_i            : in std_logic;                         --! Fifo's writing clock
        wr_i                : in std_logic;                         --! Request a write operation into the internal FIFO (Data to GBTx)
        data_i              : in std_logic_vector(7 downto 0);      --! Data to be written into the internal FIFO

        -- FSM Control
        start_read          : in std_logic;                         --! Request a write config. to the GBTx
        start_write         : in std_logic;                         --! Request a read config. to the GBTx

        -- IC lines
        tx_data_o           : out std_logic_vector(1 downto 0)      --! (TX) Array of bits to be mapped to the TX GBT-Frame (bits 83/84)
   );
end ic_tx;

--! @brief IC_tx architecture - Tx FIFO and encoding/serialization
--! @details
--! The IC_tx architecture describes the behavior of the two components used to manage the IC line
--! in order to send a specific command: write register/burst (consists of a specific header followed by the data)
--! or read register/burst (consists of a specific header to inform the start register and the number of
--! byte to be read).
architecture behaviour of ic_tx is

    -- Types & Subtypes
    subtype reg2    is std_logic_vector(1 downto 0);		--! Subtype: bus of 2 bits (IC and EC lines)
    subtype reg8    is std_logic_vector(7 downto 0);		--! Subtype: bus of 8 bits (Bytes)
    subtype reg16   is std_logic_vector(15 downto 0);		--! Subtype: bus of 16 bits (Used for the CRC computing)
    subtype reg32   is std_logic_vector(31 downto 0);		--! Subtype: bus of 32 bits (Used for the data)

    type reg8_arr   is array(integer range <>) of reg8;		--! Type: array of bytes
    type reg16_arr  is array(integer range <>) of reg16;	--! Type: array of 16 bits buses
    type reg2_arr   is array(integer range <>) of reg2;		--! Type: array of 2 bits buses
    type reg32_arr  is array(integer range <>) of reg32;	--! Type: array of 32 bits buses

    -- Constant
    constant DEL_PACKET     : std_logic_vector(7 downto 0)    := "01111110";

    -- Types
    --! The hdlcstate_t type defines the states available for the hdlcproc process
    type hdlcstate_t is (s0_waitForStart,
                            s2_sendSOF,
                            s3_sendCommand,
                            s4_sendCRC,
                            s5_sendEOF);

    -- Signals
    signal word_cnt         : integer range 0 to g_FIFO_DEPTH;          --! Counter used to count the number of data written into the FIFO (write command)
    signal word_cnt_v       : std_logic_vector(15 downto 0);            --! Same as word_cnt but with a std_logic_vector type
    signal wr_ptr           : integer range 7 to (7+g_FIFO_DEPTH);      --! Write pointer to manage the write position into the FIFO (reset value: 7, after the header)

    signal fifo             : reg8_arr(g_FIFO_DEPTH+7 downto 0);        --! FIFO memory: user defined depth + 7 bytes for the command header (GBTx documentation)
    signal fifo_r           : reg8_arr(g_FIFO_DEPTH+7 downto 0);        --! FIFO memory: user defined depth + 7 bytes for the command header (GBTx documentation)

    signal cmd_len          : integer range 0 to (7+g_FIFO_DEPTH);      --! Save command length in register
    signal tx_parity        : std_logic_vector(7 downto 0);             --! Tx Data parity (xor between data words)
    signal parity           : std_logic_vector(7 downto 0);             --! Final parity register (xor between header words and tx_parity signal)


    signal hdlc_state       : hdlcstate_t := s0_waitForStart;           --! HDLC encoding FSM state register


    signal start_write_s0   : std_logic    := '0';                      --! Register to detect start_write pulse
    signal start_read_s0    : std_logic    := '0';                      --! Register to detect start_read pulse
    signal reset_fifo       : std_logic := '0';                         --! Reset synchronization signal between FIFO and HDLC FSM. FIFO is reseted when the command has been fully sent.
    signal reset_fifo_r     : std_logic := '0';                         --! Reset synchronization signal between FIFO and HDLC FSM. FIFO is reseted when the command has been fully sent.

    signal ongoing_write_s  : std_logic;
    signal ongoing_read_s   : std_logic;
    signal ongoing_write_r  : std_logic;
    signal ongoing_read_r   : std_logic;
    signal ongoing_write_s0 : std_logic;
    signal ongoing_read_s0  : std_logic;

    signal start_wr_s0      : std_logic;
    signal start_rd_s0      : std_logic;
begin                 --========####   Architecture Body   ####========--

    word_cnt_v <= std_logic_vector(to_unsigned((word_cnt), 16));

    -- TX Fifo
    --! The wr_fifo process generate, create the command and store the data
    --! to be sent. All of the signal are synchronous with the tx_clk_i
    --! clock and can be managed at full speed (no use of the clk_en signal)
    wr_fifo: process(wr_clk_i, reset_fifo_r)
    begin
        if reset_fifo_r = '1' then
            ongoing_write_s   <= '0';
            ongoing_read_s    <= '0';
            word_cnt          <= 0;
            wr_ptr            <= 7;
            cmd_len           <= 7;
            tx_parity         <= (others => '0');

        elsif rising_edge(wr_clk_i) then

            start_wr_s0 <= start_write;
            start_rd_s0 <= start_read;

            if ongoing_write_s = '1' or ongoing_read_s = '1' then
                null; -- Wait for end of transmission

            elsif start_wr_s0 = '0' and start_write = '1' then
                fifo(0)          <= GBTx_address_i(6 downto 0) & '0';
                fifo(1)          <= GBTx_address_i(6 downto 0) & '0';
                fifo(2)          <= "00000000";
                fifo(3)          <= (word_cnt_v(7 downto 0));
                fifo(4)          <= (word_cnt_v(15 downto 8));
                fifo(5)          <= (Register_addr_i(7 downto 0));
                fifo(6)          <= (Register_addr_i(15 downto 8));

                cmd_len          <= wr_ptr;
                ongoing_write_s  <= '1';

            elsif start_rd_s0 = '0' and start_read = '1' then
                fifo(0)           <= GBTx_address_i(6 downto 0) & '1';
                fifo(1)           <= GBTx_address_i(6 downto 0) & '1';
                fifo(2)           <= "00000000";
                fifo(3)           <= (nb_to_be_read_i(7 downto 0));
                fifo(4)           <= (nb_to_be_read_i(15 downto 8));
                fifo(5)           <= (Register_addr_i(7 downto 0));
                fifo(6)           <= (Register_addr_i(15 downto 8));

                cmd_len           <= 7;
                ongoing_read_s    <= '1';

            elsif wr_i = '1' then

                fifo(wr_ptr)        <= data_i;
                tx_parity           <= tx_parity xor data_i;
                word_cnt            <= word_cnt + 1;
                wr_ptr              <= wr_ptr + 1;

            end if;

        end if;

    end process;

    -- Clock domain crossing
    clockDomainCrossing_tofifo: process(wr_clk_i, reset_fifo)
    begin
        if reset_fifo = '1' then
            reset_fifo_r <= '1';

        elsif rising_edge(wr_clk_i) then
            reset_fifo_r <= '0';
        end if;
    end process;

    clockDomainCrossing_tohdlc_rd: process(tx_clk_i, ongoing_read_s)
    begin
        if ongoing_read_s = '0' then
            ongoing_read_r   <= '0';
        elsif rising_edge(tx_clk_i) then
            ongoing_read_r   <= '1';
        end if;
    end process;

    clockDomainCrossing_tohdlc_wr: process(tx_clk_i, ongoing_write_s)
    begin
        if ongoing_write_s = '0' then
            ongoing_write_r  <= '0';
        elsif rising_edge(tx_clk_i) then
            ongoing_write_r  <= '1';
        end if;
    end process;

    clockDomainCrossing_tohdlc_fifo: process(tx_clk_i)
    begin
        if rising_edge(tx_clk_i) then
            fifo_r           <= fifo;
        end if;
    end process;

    -- TX Serializer
    --! The hdlcproc process encodes and serializes the command into the two
    --! bits of the IC line.
    --! The process implements the following state machine:
    --!     * *s0_waitForStart*: Wait for a start_write or start_read instruction and calculate the parity byte
    --!     * *s2_sendSOF*: Send start of frame delimiter (serialization of the "01111110" byte)
    --!     * *s3_sendCommand*: Read the FIFO and encode/serialize the data
    --!     * *s4_sendCRC*: Send the parity byte
    --!     * *s5_sendEOF*: Send end of frame delimiter (serialization of the "01111110" byte)
    hdlcproc: process(tx_clk_i, reset_i)

        variable offset_pos         : integer range 0 to 8;
        variable reg_pos            : integer range 0 to 8+g_FIFO_DEPTH;
        variable high_lvl_cnter     : integer range 0 to 6;

    begin

        if rising_edge(tx_clk_i) then

			if reset_i = '1' then
                offset_pos          := 0;
                high_lvl_cnter      := 0;

                reset_fifo          <= '1';
                tx_ready_o          <= '0';
                tx_data_o           <= "11";

                hdlc_state          <= s0_waitForStart;
                reg_pos             := 0;

			elsif tx_clk_en = '1' then

                tx_ready_o <= '0';

                ongoing_write_s0  <= ongoing_write_r;
                ongoing_read_s0   <= ongoing_read_r;

                case hdlc_state is

                    when s0_waitForStart    =>

                        reset_fifo <= '0';

                        -- Send idle
                        reg_pos             := 0;
                        tx_ready_o          <= '1';

                        tx_data_o(1)        <= '1';
                        tx_data_o(0)        <= '1';

                        -- Check start signal
                        if ongoing_write_s0 = '0' and ongoing_write_r = '1' then

                            tx_ready_o <= '0';

                            -- Compute the parity word
                            parity <=
                                (
                                    tx_parity                       xor
                                    word_cnt_v(7 downto 0)          xor
                                    word_cnt_v(15 downto 8)         xor
                                    Register_addr_i(7 downto 0)     xor
                                    Register_addr_i(15 downto 8)
                                ) xor parity_err_mask_i;

                            tx_data_o(1)        <= DEL_PACKET(0);
                            tx_data_o(0)        <= DEL_PACKET(1);
                            offset_pos          := 2;

                            hdlc_state <= s2_sendSOF;

                        elsif ongoing_read_s0 = '0' and ongoing_read_r = '1' then

                            tx_ready_o <= '0';

                            -- Compute the parity word
                            parity <=
                                (
                                    nb_to_be_read_i(7 downto 0)     xor
                                    nb_to_be_read_i(15 downto 8)    xor
                                    Register_addr_i(7 downto 0)     xor
                                    Register_addr_i(15 downto 8)
                                ) xor parity_err_mask_i;

                            tx_data_o(1)        <= DEL_PACKET(0);
                            tx_data_o(0)        <= DEL_PACKET(1);
                            offset_pos          := 2;

                            hdlc_state <= s2_sendSOF;

                        end if;

                    when s2_sendSOF         =>
                        -- Data have been copied into the vector buffer
                        --      -> The fifo can be reseted

                        -- Send delimiter without bit stuffing
                        tx_data_o(1)     <= DEL_PACKET(offset_pos);
                        tx_data_o(0)     <= DEL_PACKET(offset_pos+1);

                        offset_pos      := offset_pos + 2;

                        --make sure that the bit stuffing counter is always zeroed at the beginning of the transaction
                        high_lvl_cnter  := 0;

                        -- Delimiter has been fully sent?
                        if offset_pos > 7 then
                            offset_pos  := 0;
                            hdlc_state  <= s3_sendCommand;
                        end if;

                    when s3_sendCommand     =>


                        -- Enough data to send 2 bits?
                        if offset_pos < 7 then

                            -- (MSB) Bit stuffing?
                            if high_lvl_cnter >= 5 then

                                tx_data_o(1)        <= '0';
                                high_lvl_cnter     := 0;

                            -- (MSB) Send data
                            else

                                tx_data_o(1)        <= fifo_r(reg_pos)(offset_pos);
                                if fifo_r(reg_pos)(offset_pos) = '1' then
                                    high_lvl_cnter := high_lvl_cnter + 1;
                                else
                                    high_lvl_cnter := 0;
                                end if;

                                offset_pos         := offset_pos + 1;

                            end if;

                            -- (LSB) Bit stuffing?
                            if high_lvl_cnter >= 5 then

                                tx_data_o(0)        <= '0';
                                high_lvl_cnter     := 0;

                            -- (LSB) Send data
                            else

                                tx_data_o(0)        <= fifo_r(reg_pos)(offset_pos);
                                if fifo_r(reg_pos)(offset_pos) = '1' then
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
                                    reg_pos         := reg_pos + 1;
                                else
                                    hdlc_state      <= s4_sendCRC;
                                end if;

                            end if;

                        -- 1 bit still have to been sent, then CRC
                        elsif offset_pos < 8 then

                            -- (MSB) Bit stuffing?
                            if high_lvl_cnter >= 5 then

                                tx_data_o(1)     <= '0';
                                high_lvl_cnter   := 0;

                                tx_data_o(0)     <= fifo_r(reg_pos)(7);
                                if fifo_r(reg_pos)(offset_pos) = '1' then
                                    high_lvl_cnter     := high_lvl_cnter + 1;
                                else
                                    high_lvl_cnter     := 0;
                                end if;

                                offset_pos      := 0;

                                if reg_pos < (cmd_len-1) then
                                    reg_pos         := reg_pos + 1;
                                else
                                    hdlc_state      <= s4_sendCRC;
                                end if;

                            -- (MSB) Send data
                            else

                                tx_data_o(1)        <= fifo_r(reg_pos)(7);
                                if fifo_r(reg_pos)(offset_pos) = '1' then
                                    high_lvl_cnter := high_lvl_cnter + 1;
                                else
                                    high_lvl_cnter := 0;
                                end if;

                                -- (LSB) Bit stuffing?
                                if high_lvl_cnter >= 5 then
                                    tx_data_o(0)     <= '0';
                                    high_lvl_cnter  := 0;

                                    offset_pos      := 0;

                                    if reg_pos < (cmd_len-1) then
                                        reg_pos         := reg_pos + 1;
                                    else
                                        hdlc_state      <= s4_sendCRC;
                                    end if;

                                elsif reg_pos < (cmd_len-1) then

                                    reg_pos         := reg_pos + 1;

                                    tx_data_o(0)     <= fifo_r(reg_pos)(0);
                                    if fifo_r(reg_pos)(0) = '1' then
                                        high_lvl_cnter := high_lvl_cnter + 1;
                                    else
                                        high_lvl_cnter := 0;
                                    end if;

                                    offset_pos      := 1;

                                else
                                    tx_data_o(0)     <= parity(0);
                                    if parity(0) = '1' then
                                        high_lvl_cnter := high_lvl_cnter + 1;
                                    else
                                        high_lvl_cnter := 0;
                                    end if;

                                    offset_pos      := 1;
                                    hdlc_state      <= s4_sendCRC;

                                end if;

                            end if;

                        end if;

                    when s4_sendCRC             =>

                        -- Enough data to send 2 bits?
                        if offset_pos < 7 then

                            -- (MSB) Bit stuffing?
                            if high_lvl_cnter >= 5 then

                                tx_data_o(1)        <= '0';
                                high_lvl_cnter     := 0;

                            -- (MSB) Send data
                            else

                                tx_data_o(1)         <= parity(offset_pos);
                                if parity(offset_pos) = '1' then
                                    high_lvl_cnter := high_lvl_cnter + 1;
                                else
                                    high_lvl_cnter := 0;
                                end if;

                                offset_pos          := offset_pos + 1;

                            end if;

                            -- (LSB) Bit stuffing?
                            if high_lvl_cnter >= 5 then

                                tx_data_o(0)        <= '0';
                                high_lvl_cnter     := 0;

                            -- (LSB) Send data
                            else

                                tx_data_o(0)        <= parity(offset_pos);
                                if parity(offset_pos) = '1' then
                                    high_lvl_cnter := high_lvl_cnter + 1;
                                else
                                    high_lvl_cnter := 0;
                                end if;

                                offset_pos      := offset_pos + 1;

                            end if;

                            -- End of command?
                            if offset_pos = 8 then

                                offset_pos      := 0;
                                reset_fifo      <= '1';
                                hdlc_state      <= s5_sendEOF;

                            end if;

                        -- 1 bit still have to been sent, then CRC
                        elsif offset_pos < 8 then

                            -- (MSB) Bit stuffing?
                            if high_lvl_cnter >= 5 then

                                tx_data_o(1)     <= '0';
                                high_lvl_cnter   := 0;

                                tx_data_o(0)     <= parity(offset_pos);

                                if parity(offset_pos) = '1' then
                                    high_lvl_cnter     := 1;
                                end if;

                                offset_pos      := 0;
                                reset_fifo      <= '1';
                                hdlc_state      <= s5_sendEOF;

                            -- (MSB) Send data
                            else

                                tx_data_o(1)        <= parity(offset_pos);
                                if parity(offset_pos) = '1' then
                                    high_lvl_cnter := high_lvl_cnter + 1;
                                else
                                    high_lvl_cnter := 0;
                                end if;

                                -- (LSB) Bit stuffing?
                                if high_lvl_cnter >= 5 then
                                    tx_data_o(0)     <= '0';

                                    high_lvl_cnter  := 0;
                                    offset_pos      := 0;
                                    reset_fifo      <= '1';
                                    hdlc_state      <= s5_sendEOF;

                                else

                                    tx_data_o(0)     <= DEL_PACKET(0);
                                    offset_pos      := 1;
                                    reset_fifo      <= '1';
                                    hdlc_state      <= s5_sendEOF;

                                end if;
                            end if;

                        end if;

                    when s5_sendEOF         =>

                        -- (MSB) Send delimiter
                        tx_data_o(1)            <= DEL_PACKET(offset_pos);
                        offset_pos              := offset_pos + 1;

                        -- Fully sent?
                        if offset_pos > 7 then

                            tx_data_o(0)        <= '1';
                            hdlc_state          <= s0_waitForStart;

                        else

                            -- (LSB) Send delimiter
                            tx_data_o(0)        <= DEL_PACKET(offset_pos);
                            offset_pos          := offset_pos + 1;

                            -- Fully sent?
                            if offset_pos > 7 then
                                hdlc_state         <= s0_waitForStart;
                            end if;

                        end if;
                end case;

			end if;

        end if;

    end process;

end behaviour;
--============================================================================--
--############################################################################--
--============================================================================--
