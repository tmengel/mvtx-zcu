-------------------------------------------------------
--! @file
--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)
--! @date April, 2017
--! @version 1.0
--! @brief IC control - TOP level
-------------------------------------------------------

--! Include the IEEE VHDL standard library
library ieee;
--! Use STD_Logic to define vector types
use ieee.std_logic_1164.all;

--! @brief IC_top Entity - TOP Level of the IC component
--! @details
--! The IC_top entity handles the communication with the GBTx internal control
--! module. It generates the 2 bits encoded with an HDLC subset encoding to
--! read and write the internal register of the ASIC.
entity ic_top is
    generic (
        g_ToLpGBT           : integer range 0 to 1 := 0;
        g_FIFO_DEPTH        : integer := 20                         --! Depth of the internal FIFO used to improve the timming performance
    );
    port (
        -- Clock and reset
        tx_clk_i            : in  std_logic;                        --! Tx clock (Tx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        tx_clk_en           : in  std_logic;                        --! Tx clock enable signal must be used in case of multi-cycle path(tx_clk_i > LHC frequency). By default: always enabled

        rx_clk_i            : in  std_logic;                        --! Rx clock (Rx_frameclk_o from GBT-FPGA IP): must be a multiple of the LHC frequency
        rx_clk_en           : in  std_logic;                        --! Rx clock enable signal must be used in case of multi-cycle path(rx_clk_i > LHC frequency). By default: always enabled

        rx_reset_i          : in  std_logic;                        --! Reset RX datapath
        tx_reset_i          : in  std_logic;                        --! Reset TX datapath

        -- Configuration
        tx_GBTx_address_i   : in  std_logic_vector(7 downto 0);     --! I2C address of the GBTx
        tx_register_addr_i  : in  std_logic_vector(15 downto 0);    --! Address of the first register to be accessed
        tx_nb_to_be_read_i  : in  std_logic_vector(15 downto 0);    --! Number of words/bytes to be read (only for read transactions)

        parity_err_mask_i   : in std_logic_vector(7 downto 0);

        -- Internal FIFO
        wr_clk_i            : in std_logic;                         --! Fifo's writing clock
        tx_wr_i             : in  std_logic;                        --! Request a write operation into the internal FIFO (Data to GBTx)
        tx_data_to_gbtx_i   : in  std_logic_vector(7 downto 0);     --! Data to be written into the internal FIFO

        rd_clk_i            : in  std_logic;
        rx_rd_i             : in  std_logic;                        --! Request a read operation of the internal FIFO (GBTx reply)
        rx_data_from_gbtx_o : out std_logic_vector(7 downto 0);     --! Data from the FIFO

        -- FSM Control
        tx_start_write_i    : in  std_logic;                        --! Request a write config. to the GBTx
        tx_start_read_i     : in  std_logic;                        --! Request a read config. to the GBTx

        -- Status
        tx_ready_o          : out std_logic;                        --! IC core ready for a transaction
        rx_empty_o          : out std_logic;                        --! Rx FIFO is empty (no reply from GBTx)

        -- IC lines
        tx_data_o           : out std_logic_vector(1 downto 0);     --! (TX) Array of bits to be mapped to the TX GBT-Frame (bits 83/84)
        rx_data_i           : in  std_logic_vector(1 downto 0)      --! (RX) Array of bits to be mapped to the RX GBT-Frame (bits 83/84)
    );
end ic_top;

--! @brief IC_top architecture - TOP Level of the IC component
--! @details
--! Writting and/or reading register to/from the GBTx is made in two steps. To improve the performance
--! and because the ASIC memory can be accessed by burst, an internal FIFO is implemented to store the
--! data to be sent or received. Then the access from the outside looks like a FIFO interface with
--! Read and write signals associated to their data busses. This file implements the TX and RX dedicated
--! component and only a few logic elements to invert the MSB/LSB order of the IC line (2 bits).
architecture behaviour of ic_top is

    -- Signals
    --! Tx line is inverted (MSB/LSB) to get the same order as for the SCA communication line
    signal data_ic_tx_inv       : std_logic_vector(1 downto 0);
    --! Tx line is inverted (MSB/LSB) to get the same order as for the SCA communication line
    signal data_ic_rx_inv       : std_logic_vector(1 downto 0);

    -- Components
    --! @brief IC_tx Entity - Tx FIFO and encoding/serialization
    --! @details
    --! The IC_tx entity control the FIFO used to store the command to be sent
    --! and perform the HDLC encoding in parallel of the serialization process.
    component ic_tx
        generic (
            g_FIFO_DEPTH        : integer := 10
        );
        port (
            -- Clock and reset
            tx_clk_i            : in std_logic;
            tx_clk_en           : in std_logic;

            reset_i             : in std_logic;

            -- Status
            tx_ready_o          : out std_logic;

            -- Configuration
            GBTx_address_i      : in std_logic_vector(7 downto 0);
            Register_addr_i     : in std_logic_vector(15 downto 0);
            nb_to_be_read_i     : in std_logic_vector(15 downto 0);

            parity_err_mask_i   : in std_logic_vector(7 downto 0);

            -- Internal FIFO
            wr_clk_i            : in std_logic;                         --! Fifo's writing clock
            wr_i                : in std_logic;
            data_i              : in std_logic_vector(7 downto 0);

            -- FSM Control
            start_write         : in std_logic;
            start_read          : in std_logic;

            -- IC line
            tx_data_o           : out std_logic_vector(1 downto 0)
        );
    end component ic_tx;

    --! @brief IC_rx Entity - Rx deserialization and decoding
    --! @details
    --! The IC_rx entity handles the deserialization and decoding
    --! of the received frame on the couple of bits dedicated to
    --! the IC control.
    component ic_rx is
        generic (
            g_FIFO_DEPTH:  integer := 10
        );
        port (
            -- Clock and reset
            rx_clk_i        : in  std_logic;
            rx_clk_en       : in  std_logic;

            reset_i         : in  std_logic;

            -- Status
            rx_empty_o      : out std_logic;

            -- Internal FIFO
            rd_clk_i        : in  std_logic;
            rd_i            : in  std_logic;
            data_o          : out std_logic_vector(7 downto 0);

            -- IC lines
            rx_data_i       : in std_logic_vector(1 downto 0)
       );
    end component ic_rx;

    signal ic_rst_rx_s   : std_logic;

begin       --========####   Architecture Body   ####========--

    gbtx_connectivity: if g_ToLpGBT = 0 generate
        tx_data_o(0)            <= data_ic_tx_inv(1);
        tx_data_o(1)            <= data_ic_tx_inv(0);
        data_ic_rx_inv(0)       <= rx_data_i(1);
        data_ic_rx_inv(1)       <= rx_data_i(0);
    end generate;

    lpgbt_connectivity: if g_ToLpGBT = 1 generate
        tx_data_o       <= data_ic_tx_inv;
        data_ic_rx_inv  <= rx_data_i;
    end generate;

    -- TX
    tx_inst: ic_tx
        generic map (
            g_FIFO_DEPTH    => g_FIFO_DEPTH
        )
        port map (
            -- Clock and reset
            tx_clk_i        => tx_clk_i,
            tx_clk_en       => tx_clk_en,

            reset_i         => tx_reset_i,

            -- Status
            tx_ready_o      => tx_ready_o,

            -- Configuration
            GBTx_address_i  => tx_GBTx_address_i,
            Register_addr_i => tx_register_addr_i,
            nb_to_be_read_i => tx_nb_to_be_read_i,

            parity_err_mask_i => parity_err_mask_i,


            -- FSM Control
            start_write     => tx_start_write_i,
            start_read      => tx_start_read_i,

            -- Internal FIFO
            wr_clk_i        => wr_clk_i,
            wr_i            => tx_wr_i,
            data_i          => tx_data_to_gbtx_i,

            -- IC line
            tx_data_o       => data_ic_tx_inv
        );

    -- RX

    ic_rst_rx_s   <= rx_reset_i or tx_start_write_i or tx_start_read_i;

    rx_inst: entity work.ic_rx
        generic map (
            g_FIFO_DEPTH    => g_FIFO_DEPTH
        )
        port map (
            -- Clock and reset
            rx_clk_i        => rx_clk_i,
            rx_clk_en       => rx_clk_en,

            reset_i         => ic_rst_rx_s,

            -- Status
            rx_empty_o      => rx_empty_o,

            -- Internal FIFO
            rd_clk_i        => rd_clk_i,
            rd_i            => rx_rd_i,
            data_o          => rx_data_from_gbtx_o,

            -- IC line
            rx_data_i       => data_ic_rx_inv
        );

end behaviour;
--============================================================================--
--############################################################################--
--============================================================================--