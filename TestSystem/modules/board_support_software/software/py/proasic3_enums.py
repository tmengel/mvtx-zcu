from enum import IntEnum, unique


@unique
class Pa3Register(IntEnum):
    MINOR_VERSION = 0x0  # Firmware version [7:0] Minor num
    MAJOR_VERSION = 0x1  # Firmware version
    # [7:4] A = alpha, B = Beta, 0 = final release
    # [3:0] Major Num
    CLOCK_STATUS = 0x3  # [0] lcl_clk_lol
    # [1] lcl_clk_c1b
    # [2] lcl_clk_c2b
    CLOCK_CONFIG = 0x4  # [0] lcl_clk_in_sel
    # [1] lcl_clk_cs
    # [2] lcl_clk_rst
    CC_CMD = 0x8  # Configuration controller command register
    # [6:0] Config Controller Command Register
    #   h01: Init_config
    #   h02: continuous scrubbing
    #   h04: single scrubbing cycle
    #   h08: Stop continuous scrubbing
    #   h10: Clear Scrubbing Counter
    # [7] EXECUTE command = '1' (T)"
    CC_STATUS = 0x9  # Config controller Status Register
    # [0] busy
    # [1] config done
    # [2] scrubbing"
    CC_ACTIVE_STATE = 0xA  # DEBUG Active state of cc state machine
    #  h0: idle
    #  h1: init_sm_wait
    #  h2: init_flash_read
    #  h3: fifo_status
    #  h4: transfer_data
    #  h5: transfer_data_done
    #  h6: startup_wait
    #  h7: pause_scrub
    #  hF: others
    CC_SCRUB_CNT_LSB = 0xB  # Number of scrubbing cycles executed LSB
    CC_SCRUB_CNT_MSB = 0xC  # Number of scrubbing cycles executed MSB
    CC_CTRL = 0xD  # [0] Set high to pause continuous scrubbing

    RC_CMD = 0x10  # [6:0] Read Controller Command Register
    #   h01: READ_PARAMETER
    #   h02: READ_CONFIG
    #   h04: READ_SCRUB
    #   h08: START_PAGE
    #   h10: STOP_PAGE
    # [7] EXECUTE command = '1' (T)"
    RC_STATUS = 0x11  # "Read Controller Status Register:
    #  [0] RC_busy
    #  [1] Waiting_for_flash
    #  [2] Reading bitfile
    #  [3] Reading parameters
    #  [4] Config parameter ok
    #  [5] Blind scrubbing parameter ok
    #  [6] Parameter error
    #  [7] Config with ecc (not used)
    RC_FLASHPAGE1 = 0x12  # Page address read from flash [7:0]
    RC_FLASHPAGE2 = 0x13  # Page address read from flash [15:8]
    RC_FLASHPAGE3 = 0x14  # Page address read from flash [18:16]

    SMAP_CMD = 0x18  # [5:0] SelectMAP Command register
    #   h01: Init Xilinx
    #   h02: Startup
    #   h04: write one byte
    #   h08: read one byte
    #   h10: abort
    #   h20: read/write finished
    # [6] Clears any error in selectmap interface. (T)
    # [7] EXECUTE command = '1' (T)"
    SMAP_DATA_TX = 0x19  # Byte read from Xilinx selectmap interface
    SMAP_DATA_RX = 0x1A  # Byte to write to Xilinx selectmap interface
    SMAP_STATUS = 0x1B  # SelectMap Interface Status Register
    #  [0] init_b does not respons to prog_b = 0
    #  [1] init_b does not go high after prog_b
    #  [2] done never goes high during startup
    #  [3] Done status from Xilinx (High if device is configured
    #  [4] Configuration done successfully
    #  [5] interface busy"

    FLASH_CTRL = 0x20  # Flash interface Command Register
    # [5:0] Command
    #   h01: PAGE_WRITE
    #   h02: PAGE_READ
    #   h04: READ_ID
    #   h08: READ_STATUS
    #   h10: RESET_FLASH
    #  h20: BLOCK_ERASE
    # [6] Verify Pattern
    # [7] Flash Interface Execute (T)
    FLASH_STATUS = 0x21  # Flash interface Status Register
    # [0] Done with command (Read/Write/Erase/Read ID)
    # [1] Fifo Status (Write FIFO EMPTY or Read FIFO FULL)
    # [2] Status Bit from Flash after ended command. '1' means an error has occured.
    # [3] Write Active
    # [4] Read Active
    # [5] Command Active (ReadID, Erase, Reset)
    # [6] Trx_done (Sticky bit)"
    FLASH_PATTERN = 0x22  # Debug feature. If the bit 'Verify Pattern' in cADD_FLASH_CTRL is set, each byte in the read back page is verified against this pattern.
    FLASH_MIS_COUNT = 0x23  # Debug feature. Number of pattern recognition errors if 'Verify Pattern' is selected. This counter is don't care otherwise.
    FLASH_PAGE_ADDR = 0x24  # Page address within block given by BLOCK_ADDR registers
    FLASH_BLOCK_ADDR_LSB = 0x25  # Block address[12:0]
    FLASH_BLOCK_ADDR_MSB = 0x26  # Block address[17:13]
    FLASH_TRX_SIZE_LSB = 0x27  # Page size on Flash [7:0]
    #  4096 (0x1000): Not using spare section (default)
    #  4192 (0x1060): Page size for ECC encoding (32x3 bytes hamming codes)
    #  4224 (0x1080): Page size incl full spare section "
    FLASH_TRX_SIZE_MSB = 0x28  # Page size on Flash [12:8]
    FLASH_STATUS_WORD = 0x29  # Status word transferred from flash memory after erase command -- Table 3 page 55 data sheet
    FLASH_SELECT_IC = 0x2A  # Select which flash IC to use. Default is chip 1.
    #  b00: Not legal value. Default flash b01 (IC 1) is selected
    #  b01: Flash IC 1 (FLASH_CE1/FLASH_R_B1_n)
    #  b10: Flash IC 2 (FLASH_CE2/FLASH_R_B2_n)
    #  b11: Both IC1 and IC2 active (NOT LEGAL FOR READ PAGE OR READ ID OPERATION - WILL CORRUPT DATA. Writing and Erasing is OK.
    FLASH_TRX_CNT_MSB = 0x2B  # Number of bytes written or read by flash interface (in a page) MSB
    FLASH_TRX_CNT_LSB = 0x2C  # Number of bytes written or read by flash interface (in a page) LSB
    FLASH_STATE_0 = 0x46  # Debug registers showing active states of all FSMs in Flash interface. Design entity file with state definition are given next to the bitwidth:
    FLASH_STATE_1 = 0x47  # [3:0] nand_flash_controller.vhd
    FLASH_STATE_2 = 0x48  # [9:4] page_write_ctrl.vhd
    FLASH_STATE_3 = 0x4D  # [15:10] page_read_ctrl.vhd
    # [21:16] block_erase_ctrl.vhd
    # [25:22] read_id_ctrl.vhd
    FLASH_ST_WRD = 0x4E  # Status word from Flash after a transaction is finished
    # [0] Error flag, positive polarity"
    # [7:1] Don't care
    FIFO_RX_DATA = 0x30  # Return data from ECC FIFO (anything read from flash will be here)
    FIFO_TX_DATA = 0x31  # Data to write to Flash.
    # WHEN WRITING TO FLASH THE NUMBER OF BYTES WRITTEN TO THE FLASH MUST MATCH PAGE SIZE GIVEN BY cADD_FLASH_TRX_SIZE_(LSB/MSB)
    FIFO_STATUS = 0x32  # Status of both Write FIFO and Read FIFO
    #  [0] Read FIFO full
    #  [1] Read FIFO empty
    #  [2] Write FIFO full
    #  [3] Write FIFO empty
    #  [4] Xilinx FIFO Empty ('1' if Xilinx is configured, '0' if not)
    FIFO_WRITER_CMD = 0x33  # FIFO Write controller command register
    #  [6:0] Command
    #    h01: Write to flash via Xilinx FIFO
    #    h02: Write to Flash via I2C/UART
    #    h04: Stop writing. Executed after all data has been written
    #    h08: Clear error flags
    #  [7] Execute (T)"
    FIFO_WRITER_STATUS = 0x34  # Status register of FIFO write controller
    #  [0] Ready to accept data
    #  [1] Active input ('0' = I2C/UART, '1' = Xilinx)
    #  [2] Ending data transmission active
    #  [3] Error
    #  [4] Command not recognized"
    ECC_CMD = 0x38  # ECC Command and Control register
    #  [0] Enable ECC (positive polarity)
    #  [1] Clear Status and Counters (T)"
    ECC_STATUS = 0x39  # ECC Status register
    #  [0] Double bit error (uncorrectable)
    #  [1] Single bit error
    #  [2] ECC error (single bit error in ECC code)
    #  [3] TMR error in Read FIFO
    #  Writing any value to this register clears it
    ECC_SB_ERROR_CNT = 0x3A  # Single Bit Error Counter
    ECC_FIFO_TMR_ERROR = 0x3B  # Number of TMR errors in triplicated Read FIFO
    DIPSWITCH1 = 0x40  # Status of connected dipswitches (Default value is depending position of switches) [7:0]
    DIPSWITCH2 = 0x41  # [9:8]
    PUSHBUTTON = 0x42  # [3:0] Pushbutton Values. Always 0 unless pressed down. Pushbutton[0] is used as master reset so this will always show up as 0.
    CTRL_LEDS = 0x43  # [1:0] Value to put out on LEDs of PA3
    CRC_0 = 0x49  # [7:0] Calculated CRC-32 value from the CRC checker
    CRC_1 = 0x4A  # [15:8]
    CRC_2 = 0x4B  # [23:16]
    CRC_3 = 0x4C  # [31:24]
    # hascodes
    HASH_0 = 80
    HASH_1 = 81
    HASH_2 = 82
    HASH_3 = 83


@unique
class LocalClockMuxInputSelect(IntEnum):
    """Selects the clock multiplexer on the RU"""
    CRYSTAL = 0
    JITTER_CLEANER = 1


@unique
class CcCmdOpcode(IntEnum):
    """
    Config controller opcode mapping
    """
    INIT_CONFIG = 0x01  # Configuration with redundancy (if enabled)
    CONT_SCRUB = 0x02  # Continuous blind scrubbing
    SINGLE_SCRUB = 0x04  # Single blind scrubbing
    STOP = 0x08  # Stop continuous blind scrubbing
    SCRUB_CNT_CLR = 0x10  # Clear blind scrubbing counter


@unique
class CcActiveState(IntEnum):
    """
    Config controller FSM state
    """
    IDLE = 0x0
    INIT_SM_WAIT = 0x1
    INIT_FLASH_READ = 0x2
    FIFO_STATUS = 0x3
    TRANSFER_DATA = 0x4
    TRANSFER_DATA_DONE = 0x5
    STARTUP_WAIT = 0x6


@unique
class CcStatus(IntEnum):
    """CC status"""
    IDLE = 0
    INIT_CONFIG_DONE = 1
    SCRUBBING_ONGOING = 2
    SCRUBBING_DONE = 3


@unique
class RcCmdOpcode(IntEnum):
    """
    Read controller opcode mapping
    """
    READ_PARAMETER = 0x01
    READ_CONFIG = 0x02
    READ_SCRUB = 0x04
    START_PAGE = 0x08
    STOP_PAGE = 0x10


@unique
class RcState(IntEnum):
    """
    Read controller FSM state
    """
    BUSY = 0
    WAIT_FOR_FLASH = 1
    READING_BITFILE = 2
    READING_PARAMETERS = 3
    CONFIG_PARAMETERS_OK = 4
    BS_PARAMETERS_OK = 5
    PARAMETER_ERROR = 6
    CONFIG_WITH_ECC_NON_VALID = 7


@unique
class SmapCmdOpcode(IntEnum):
    """
    Smap controller opcode mapping
    """
    INIT_XILINX = 0x01
    STARTUP = 0x02
    WRITE = 0x04
    READ = 0x08
    ABORT = 0x10
    WR_FINISHED = 0x20
    CLEAR_STATUS_REGISTER = 0x40


@unique
class SmapStatus(IntEnum):
    """
    Smap controller Status Register
    """
    INIT_B_DID_NOT_RESPOND_TO_PROG_B_EQ_0 = 0
    INIT_B_DID_NOT_GO_HIGH_AFTER_PROG_B = 1
    DONE_NEVER_GOES_HIGH = 2
    XILINX_DONE_PIN = 3
    IF_BUSY = 4


@unique
class FlashCmdOpcode(IntEnum):
    """
    Flash command register opcodes
    """
    PAGE_WRITE = 0x01
    PAGE_READ = 0x02
    PAGE_READ_ID = 0x04
    READ_STATUS = 0x08
    RESET_FLASH = 0x10
    BLOCK_ERASE = 0x20


@unique
class FlashStatus(IntEnum):
    """
    Flash controller status
    """
    TRX_DONE = 0
    FIFO_STATUS = 1
    TRX_ERROR = 2
    WRITE_ACTIVE = 3
    READ_ACTIVE = 4
    COMMAND_ACTIVE = 5
    TRX_DONE_STICKY = 6


@unique
class FlashSelectICOpcode(IntEnum):
    """
    Flash command register opcodes
    """
    NA = 0x00
    FLASH_IC1 = 0x01
    FLASH_IC2 = 0x02
    FLASH_BOTH_IC = 0x03


@unique
class FlashFsmNandControllerState(IntEnum):
    """[3:0] FSM NAND Flash Controller"""
    IDLE = 0x0
    INIT_RDID = 0x1
    WAIT_RDID = 0x2
    INIT_ERASE = 0x3
    WAIT_ERASE = 0x4
    INIT_READ = 0x5
    WAIT_READ = 0x6
    INIT_WRITE = 0x7
    WAIT_WRITE = 0x8
    SET_RESET = 0x9
    INIT_RESET = 0xA
    WAIT_RESET = 0xB


@unique
class FlashFsmPageWriteController(IntEnum):
    """[9:4] FSM page write controller """
    IDLE = 0x00
    WR_CMDL0 = 0x01
    WR0_CMDL0 = 0x02
    WR1_CMDL0 = 0x03
    END_CMDL0 = 0x04
    WR_ADD0 = 0x05
    WR0_ADD0 = 0x06
    WR1_ADD0 = 0x07
    END_ADD0 = 0x08
    WR_ADD1 = 0x09
    WR0_ADD1 = 0x0A
    WR1_ADD1 = 0x0B
    END_ADD1 = 0x0C
    WR_ADD2 = 0x0D
    WR0_ADD2 = 0x0E
    WR1_ADD2 = 0x0F
    END_ADD2 = 0x10
    WR_ADD3 = 0x11
    WR0_ADD3 = 0x12
    WR1_ADD3 = 0x13
    END_ADD3 = 0x14
    WR_ADD4 = 0x15
    WR0_ADD4 = 0x16
    WR1_ADD4 = 0x17
    END_ADD4 = 0x18
    WR_INIT = 0x19
    WR0_DATA = 0x1A
    WR1_DATA = 0x1B
    FIFO_WAIT = 0x1C
    END_DATA = 0x1D
    WR_CMDL1 = 0x1E
    WR0_CMDL1 = 0x1F
    WR1_CMDL1 = 0x20
    END_CMDL1 = 0x21
    WAIT1_RNB = 0x22
    WAIT2_RNB = 0x23
    WAIT3_RNB = 0x24
    WAIT4_RNB = 0x25
    WAIT5_RNB = 0x26
    CHK_RnB = 0x27
    DONE = 0x28


@unique
class FlashFsmPageReadController(IntEnum):
    """[15:9] FSM page read controller"""
    IDLE = 0x00
    WR_CMDL0 = 0x01
    WR0_CMDL0 = 0x02
    WR1_CMDL0 = 0x03
    END_CMDL0 = 0x04
    WR_ADD0 = 0x05
    WR0_ADD0 = 0x06
    WR1_ADD0 = 0x07
    END_ADD0 = 0x08
    WR_ADD1 = 0x09
    WR0_ADD1 = 0x0A
    WR1_ADD1 = 0x0B
    END_ADD1 = 0x0C
    WR_ADD2 = 0x0D
    WR0_ADD2 = 0x0E
    WR1_ADD2 = 0x0F
    END_ADD2 = 0x10
    WR_ADD3 = 0x11
    WR0_ADD3 = 0x12
    WR1_ADD3 = 0x13
    END_ADD3 = 0x14
    WR_ADD4 = 0x15
    WR0_ADD4 = 0x16
    WR1_ADD4 = 0x17
    END_ADD4 = 0x18
    RD_INIT = 0x19
    RD0_DATA = 0x1A
    RD1_DATA = 0x1B
    FIFO_WAIT = 0x1C
    END_DATA = 0x1D
    WR_CMDL1 = 0x1E
    WR0_CMDL1 = 0x1F
    WR1_CMDL1 = 0x20
    END_CMDL1 = 0x21
    CHK_RnB = 0x22
    WAIT1_RNB = 0x23
    WAIT2_RNB = 0x24
    WAIT3_RNB = 0x25
    WAIT4_RNB = 0x26
    WAIT5_RNB = 0x27
    DONE = 0x28


@unique
class FlashFsmBlockEraseControllerState(IntEnum):
    """[21:16] FSM block erase controller"""
    IDLE = 0x00
    WR_CMDL0 = 0x01
    WR0_CMDL0 = 0x02
    WR1_CMDL0 = 0x03
    END_CMDL0 = 0x04
    WR_ADD0 = 0x05
    WR0_ADD0 = 0x06
    WR1_ADD0 = 0x07
    END_ADD0 = 0x08
    WR_ADD1 = 0x09
    WR0_ADD1 = 0x0A
    WR1_ADD1 = 0x0B
    END_ADD1 = 0x0C
    WR_ADD2 = 0x0D
    WR0_ADD2 = 0x0E
    WR1_ADD2 = 0x0F
    END_ADD2 = 0x10
    WR_CMDL1 = 0x11
    WR0_CMDL1 = 0x12
    WR1_CMDL1 = 0x13
    END_CMDL1 = 0x14
    CHK_RnB = 0x15
    WAIT1_RNB = 0x16
    WAIT2_RNB = 0x17
    WAIT3_RNB = 0x18
    WAIT4_RNB = 0x19
    WAIT5_RNB = 0x1A
    STATS0_CMD = 0x1B
    STATS1_CMD = 0x1C
    STATS2_CMD = 0x1D
    STATS3_CMD = 0x1E
    RST0_CMD = 0x1F
    RST1_CMD = 0x21
    RST2_CMD = 0x22
    RST3_CMD = 0x23
    ENDRST_CMD = 0x24
    DONE = 0x25


@unique
class FlashFsmReadIdControllerState(IntEnum):
    """[25:22] FSM Read ID controller"""
    IDLE = 0x00
    WR_CMDL0 = 0x01
    WR0_CMDL0 = 0x02
    WR1_CMDL0 = 0x03
    END_CMDL0 = 0x04
    WR_ADD0 = 0x05
    WR0_ADD0 = 0x06
    WR1_ADD0 = 0x07
    END_ADD0 = 0x08
    RD_INIT = 0x09
    RD0_DATA = 0x0A
    RD1_DATA = 0x0B
    END_DATA = 0x0C
    DONE = 0x0D


@unique
class FifoState(IntEnum):
    """
    Fifo status flags
    """
    INTERNAL_RD_FIFO_FULL = 0
    INTERNAL_RD_FIFO_EMPTY = 1
    INTERNAL_WR_FIFO_FULL = 2
    INTERNAL_WR_FIFO_EMPTY = 3
    XILINX_FIFO_WR_FULL = 4


@unique
class FifoWriterCmdOpcode(IntEnum):
    """
    Fifo writer command opcodes
    """
    WRITE_XILINX = 0x01
    WRITE_BUS = 0x02
    STOP = 0x04
    CLEAR_ERRORS = 0x08


@unique
class FifoWriterStatus(IntEnum):
    """
    Fifo Writer flags
    """
    READY = 0
    ACTIVE_INPUT_IS_XIL_FIFO_NOT_I2C = 1
    STOPPING = 2
    FIFO_WRITE_ERROR = 3
    WRONG_COMMAND_ERROR = 4


@unique
class EccCmdFlags(IntEnum):
    """
    ECC command register bit meaning
    """
    ECC_ENABLE = 0
    CLEAR_STATUS_AND_COUNTERS = 1


@unique
class EccCmdOpcodes(IntEnum):
    ECC_CLEAR_DISABLE = 0x2
    ECC_CLEAR_ENABLE = 0x3
    ECC_ENABLE = 0x1


@unique
class EccStatus(IntEnum):
    """
    ECC status
    """
    DB_ERROR = 0
    SB_ERROR = 1
    ECCSB_ERROR = 2
    TMR_ERROR_IN_READ_FIFO = 3


@unique
class XIL_ADDR(IntEnum):
    """smap xilinx addresses"""
    CRC = 0
    FAR = 1
    FDRI = 2
    FDRO = 3
    CMD = 4
    CTL0 = 5
    MASK = 6
    STAT = 7
    LOUT = 8
    COR0 = 9
    MFWR = 10
    CBC = 11
    IDCODE = 12
    AXSS = 13
    COR1 = 14
    WBSTAR = 16
    TIMER = 17
    BOOTSTS = 22
    CTL1 = 24
    BSPI = 31
