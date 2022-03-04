library ieee;
use ieee.std_logic_1164.all;

package auxFPGA_pkg is
-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------
  -- VERSION VALUE
  constant C_VERSION : std_logic_vector(15 downto 0) := X"A203";
  --(15:12): A = alpha, B = Beta, 0 = final release
  --(11:8) : Major num,
  --(7:0)  : Minor num
  
  -- STOP CODE! WRITING THIS CODE WILL MAKE HALT ANY INIT CONFIG ON POWER UP!!
  constant C_ABORT_POR_CONFIG : std_logic_vector(15 downto 0) := X"A956";

  -- CONFIG PARAMETER OK: 4 byte word that is read from flash parameter
  constant C_PARAM_OK_WORD : std_logic_vector(31 downto 0) := X"AA995566";

  -- CLOCK SPEED
  constant C_CLK_PERIOD : integer := 25000;  -- ps - 40 MHZ clock


  ------------------
  constant C_INIT_PARAM_PAGE  : natural := 0;
  constant C_TRNX_SIZE        : std_logic_vector(12 downto 0) := '1' & X"000";
  constant C_PAGE_SIZE_ECC    : natural := 4192;
  -- one programming file is 5889,87 pages
  -- this gives a 13 bit counter

-------------------------------------------------------------------------------
-- REGISTER DEFINITIONS
-- address is defined as:
--      [15:12] - baseaddress slave
--      [11:0]  - subaddress in slave
-- There are two slaves at the moment:
--      (1) One register slave that contains all registers
--      (2) One direct interface to the memory in the Flash interface
-------------------------------------------------------------------------------

  constant cADD_REGSPACE               : natural := 0;  -- slave address
                                                        -- Width;Access;Type;Sub;Default Value;Description
  -- global adresses            (memspace x00 - x07)
  constant cADD_MINOR_VERSION          : natural := 0;  -- 8;R;STAT;1of2;0x03;[7:0] Minor num 
  constant cADD_MAJOR_VERSION          : natural := 1;  -- 8;R;STAT;2of2;0xA2;"[7:4] A = alpha, B = Beta, 0 = final release
                                                        --                     [3:0] Major Num"
  constant cADD_STATUS_CLOCK           : natural := 3;  -- 3;R;STAT;1of1;0x00;"[0] lcl_clk_lol 
                                                        --                     [1] lcl_clk_c1b
                                                        --                     [2] lcl_clk_c2b"
  constant cADD_CNFG_CLOCK             : natural := 4;  -- 3;RW;CMD;1of1;0x00;"[0] lcl_clk_in_sel 
                                                        --                     [1] lcl_clk_cs
                                                        --                     [2] lcl_clk_rst"
  -- config controller adresses (memspace x08 - x0F)     
  constant cADD_CC_CMD                 : natural := 8;  -- 8;RW;CMD;1of1;0x00;"[6:0] Config Controller Command Register 
                                                        --                                                h01: Init_config
                                                        --                                                h02: continuous scrubbing
                                                        --                                                h04: single scrubbing cycle
                                                        --                                                h08: Stop continuous scrubbing
                                                        --                                                h10: Clear Scrubbing Counter
                                                        --                                             [7] EXECUTE command = ’1’ (T)"
  constant cADD_CC_STATUS              : natural := 9;  -- 3;R;STAT;1of1;0x00;"Config controller Status Register 
                                                        --                     [0] busy
                                                        --                          [1] config done
                                                        --                          [2] scrubbing"
  constant cADD_CC_ACTIVE_STATE        : natural := 10; -- 4;R;DBG;1of1;0x00;"DEBUG Active state of cc state machine 
                                                        --                       h0: idle
                                                        --                       h1: init_sm_wait
                                                        --                       h2: init_flash_read
                                                        --                       h3: fifo_status
                                                        --                       h4: transfer_data
                                                        --                       h5: transfer_data_done
                                                        --                       h6: startup_wait
                                                        --                       hF: others"
  constant cADD_CC_MINOR_SCRUB_CNT     : natural := 11; -- 8;R;STAT;1of2;0x00;Number of scrubbing cycles executed
  constant cADD_CC_MAJOR_SCRUB_CNT     : natural := 12; -- 8;R;STAT;2of2;0x00;
  -- read controller            (memspace x10 - x17)     
  constant cADD_RC_CMD                 : natural := 16; -- 8;RW;CMD;1of1;0x00;"[6:0] Read Controller Command Register
                                                        --                       h01: READ_PARAMETER
                                                        --                       h02: READ_CONFIG
                                                        --                       h04: READ_SCRUB
                                                        --                       h08: START_PAGE
                                                        --                       h10: STOP_PAGE
                                                        --                     [7] EXECUTE command = ’1’ (T)"
  constant cADD_RC_STATUS              : natural := 17; -- 8;RW;STAT;1of1;0x00;"Read Controller Status Register: 
                                                        --                     [0] RC_busy
                                                        --                     [1] Waiting_for_flash
                                                        --                     [2] Reading bitfile
                                                        --                     [3] Reading parameters
                                                        --                     [4] Config parameter ok
                                                        --                     [5] BS parameter ok
                                                        --                     [6] Parameter error
                                                        --                     [7] Config with ecc (not valid)"
  -- SelectMap addresses        (memspace x18 - x1F)     
  constant cADD_SMAP_CMD               : natural := 24; -- 8;RW;CMD;1of1;0x00;"[5:0] SelectMAP Command register
                                                        --                       h01: Init Xilinx
                                                        --                       h02: Startup
                                                        --                       h04: write one byte
                                                        --                       h08: read one byte
                                                        --                       h10: abort
                                                        --                       h20: read/write finished
                                                        --                     [6] Clears any error in selectmap interface. Issues ABORT sequence to Xilinx. (T)
                                                        --                     [7] EXECUTE command = ’1’ (T)"
  constant cADD_SMAP_DATA_TX           : natural := 25; -- 8;R;DATA;1of1;0x00;Byte read from Xilinx selectmap interface
  constant cADD_SMAP_DATA_RX           : natural := 26; -- 8;RW;DATA;1of1;0x00;Byte to write to Xilinx selectmap interface
  constant cADD_SMAP_STATUS            : natural := 27; -- 6;R;STAT;1of1;0x00;"SelectMap Interface Status Register
                                                        --                     [0] init_b does not respons to prog_b = 0
                                                        --                     [1] init_b does not go high after prog_b
                                                        --                     [2] done never goes high during startup 
                                                        --                     [3] Done status from Xilinx (High if device is configured
                                                        --                     [4] Configuration done successfully
                                                        --                     [5] interface busy"
  -- flash adresses             (memspace x20 - x2F)     
  constant cADD_FLASH_CTRL             : natural := 32; -- 8;RW;CMD;1of1;0x00;"Flash interface Command Register
                                                        --                    [5:0] Command
                                                        --                      h01: PAGE_WRITE 
                                                        --                      h02: PAGE_READ
                                                        --                      h04: READ_ID 
                                                        --                      h08: READ_STATUS
                                                        --                      h10: RESET_FLASH
                                                        --                     h20: BLOCK_ERASE 
                                                        --                    [6] Verify Pattern
                                                        --                    [7] Flash Interface Execute (T)"
  constant cADD_FLASH_STATUS           : natural := 33; -- 7;R;STAT;1of1;0x00;"Flash interface Status Register
                                                        --                     [0] Done with command (Read/Write/Erase/Read ID)
                                                        --                     [1] Fifo Status (Write FIFO EMPTY or Read FIFO FULL)
                                                        --                     [2] Status Bit from Flash after ended command. '1' means an error has occured.
                                                        --                     [3] Write Active
                                                        --                     [4] Read Active
                                                        --                     [5] Command Active (ReadID, Erase, Reset)
                                                        --                     [6] Trx_done (Sticky bit)"
  constant cADD_FLASH_PATTERN          : natural := 34; -- 8;RW;DATA;1of1;0x00;Debug feature. If the bit 'Verify Pattern' in cADD_FLASH_CTRL is set, each byte in the read back page is verified against this pattern.
  constant cADD_FLASH_MIS_CNT          : natural := 35; -- 8;R;STAT;1of1;0x00;Debug feature. Number of pattern recognition errors if 'Verify Pattern' is selected. This counter is don't care otherwise.
  constant cADD_FLASH_PAGE_ADDR        : natural := 36; -- 8;RW;CTRL;1of3;0x00;Page address within block given by BLOCK_ADDR registers
  constant cADD_FLASH_MINOR_BLOCK_ADDR : natural := 37; -- 8;RW;CTRL;2of3;0x00;Block address[12:0]
  constant cADD_FLASH_MAJOR_BLOCK_ADDR : natural := 38; -- 5;RW;CTRL;3of3;0x00;
  constant cADD_FLASH_MINOR_TRX_SIZE   : natural := 39; -- 8;RW;CTRL;1of2;0x00;"Page size on Flash:
                                                        --                      4096 (0x1000): Not using spare section (default)
                                                        --                      4192 (0x1060): Page size for ECC encoding (32x3 bytes hamming codes)
                                                        --                      4224 (0x1080): Page size incl full spare section "
  constant cADD_FLASH_MAJOR_TRX_SIZE   : natural := 40; -- 5;RW;CTRL;2of2;0x10;
  constant cADD_FLASH_STATE_0          : natural := 70; -- 8;R;DBG;1of4;0x00;"Debug registers showing active states of all FSMs in Flash interface. Design entity file with state definition are given next to the bitwidth:
                                                        --                    [3:0] nand_flash_controller.vhd
                                                        --                    [9:4] page_write_ctrl.vhd
                                                        --                    [15:10] page_read_ctrl.vhd
                                                        --                    [21:16] block_erase_ctrl.vhd
                                                        --                    [25:22] read_id_ctrl.vhd"
  constant cADD_FLASH_STATE_1          : natural := 71; -- 8;R;DBG;2of4;0x00;
  constant cADD_FLASH_STATE_2          : natural := 72; -- 8;R;DBG;3of4;0x00;
  constant cADD_FLASH_STATE_3          : natural := 77; -- 2;R;DBG;4of4;0x00;
  constant cADD_FLASH_ST_WRD           : natural := 78; -- 8;R;STAT;1of1;0x00;"Status word from Flash after a transaction is finished.
                                                        --                     [0] Error flag, positive polarity"
                                                        --                     [7:1] Don't care
  -- Read fifo                  (memspace x30 - x37)
  constant cADD_FIFO_DATA_RD           : natural := 48; -- 8;R;DATA;1of1;0x00;"Return data from ECC FIFO.
                                                        --                     NOTE!!! MUST NOT BE READ DURING INIT CONFIG OR SCRUBBING"
  constant cADD_FIFO_DATA_WR           : natural := 49; -- 8;(R)W;DATA;1of1;0x00;"Data to write to Flash. 
                                                        --                        NOTE!!! WHEN WRITING TO FLASH THE NUMBER OF BYTES WRITTEN TO THE FLASH MUST MATCH PAGE SIZE GIVEN BY cADD_FLASH_(MINOR/MAJOR)_TRX_SIZE  "
  constant cADD_FIFO_STATUS            : natural := 50; -- 5;R;STAT;1of1;0x1A;"Status of both Write FIFO and Read FIFO
                                                        --                     [0] Read FIFO full
                                                        --                     [1] Read FIFO empty
                                                        --                     [2] Write FIFO full
                                                        --                     [3] Write FIFO empty
                                                        --                     [4] Xilinx FIFO Empty ('1' if Xilinx is configured, '0' if not)"
  -- Write controller                                   
  constant cADD_FIFO_WRITER_CMD        : natural := 51; -- 8;RW;CMD;1of1;0x0;"FIFO Write controller command register 
                                                        --                   [6:0] Command
                                                        --                     h01: Write to flash via Xilinx FIFO
                                                        --                     h02: Write to Flash via I2C/UART
                                                        --                     h04: Stop writing. Executed after all data has been written
                                                        --                     h08: Clear error flags
                                                        --                   [7] Execute (T)"
  constant cADD_FIFO_WRITER_STATUS     : natural := 52; -- 5;R;STAT;1of1;0x01;"Status register of FIFO write controller
                                                        --                     [0] Ready to accept data
                                                        --                     [1] Active input ('0' = I2C/UART, '1' = Xilinx)
                                                        --                     [2] Ending data transmission active
                                                        --                     [3] Error
                                                        --                     [4] Command not recognized"
  -- ECC                        (memspace x38 - x3F)
  constant cADD_ECC_COMMAND            : natural := 56; -- 2;RW;CMD;1of1;0x0;"ECC Command and Control register
                                                        --                    [0] Enable ECC (positive polarity)
                                                        --                    [1] Clear Status and Counters (T)"
  constant cADD_ECC_STATUS             : natural := 57; -- 3;R;STAT;1of1;0x0;"ECC Status register
                                                        --                    [0] Double bit error (uncorrectable)
                                                        --                    [1] Single bit error
                                                        --                    [2] ECC error (single bit error in ECC code)
                                                        --                    [3] TMR error in Read FIFO
                                                        --                    Writing any value to this register clears it"
  constant cADD_ECC_SB_CNT             : natural := 58; -- 8;R;STAT;1of1;0x00;Single Bit Error Counter
  constant cADD_ECC_FIFOTMR_ERR_CNT    : natural := 59; -- 8;R;STAT;1of1;0x00;Number of TMR errors in triplicated Read FIFO
  -- debug type registers       (memspace x40 ->)       
  constant cADD_DIPSWITCH1             : natural := 64; -- 8;R;STAT;1of2;0x--;"Status of connected dipswitches (Default value is depending position of switches)
                                                        --                     [9:0] Value of Dipswitches"
  constant cADD_DIPSWITCH2             : natural := 65; -- 2;R;STAT;2of2;0x--;
  constant cADD_PUSHBUTTON             : natural := 66; -- 4;R;DBG;1of1;0x0;"Pushbutton Values. Always 0 unless pressed down. 
                                                        --                   NOTE! Pushbutton[0] is used as master reset so this will always show up as 0."
  constant cADD_CTRL_LEDs              : natural := 67; -- 2;RW;DBG;1of1;0x0;Value to put out on LEDs of PA3
  -- CRC-32
  constant cADD_CRC_0                  : natural := 73; -- 8;R;DBG;1of4;0x0;Calculated CRC-32 value from the CRC checker
  constant cADD_CRC_1                  : natural := 74; -- 8;R;DBG;2of4;0x0;
  constant cADD_CRC_2                  : natural := 75; -- 8;R;DBG;3of4;0x0;
  constant cADD_CRC_3                  : natural := 76; -- 8;R;DBG;4of4;0x0;
                                             
  
-------------------------------------------------------------------------------
-- Selectmap interface
-------------------------------------------------------------------------------
  -- COMMANDS FOR SELECTMAP
  constant C_SM_INIT      : std_logic_vector(5 downto 0):= "000001";  -- Generate init command
  constant C_SM_STARTUP   : std_logic_vector(5 downto 0):= "000010";  -- Tell selmap IF to do startup
  constant C_SM_WRITE     : std_logic_vector(5 downto 0):= "000100";  -- Write to selectmap (command/data)
  constant C_SM_READ      : std_logic_vector(5 downto 0):= "001000";  -- Read from selectmap
  constant C_SM_ABORT     : std_logic_vector(5 downto 0):= "010000";  -- issue abort command
  constant C_SM_RDWR_DONE : std_logic_vector(5 downto 0):= "100000";  -- Finished writing/reading
  -------------------------------------------------------------------------------
  constant C_MODE_SLAVE_SM : std_logic_vector(2 downto 0) := "110"; --slave selectMAP

  -- timing values
  constant C_tPROGRAM      : integer := 300000;     -- Program pulse width = min 250 ns -- set to 300 ns
  constant C_tPL           : integer := 7500000;    -- Maximum Program latency = 7.5 ms (given in ns))
  constant C_tSCCK         : integer := 2500;       -- Slave CCLK min low/high time = 2.5 ns;
  constant C_fSCCK         : integer := 125;        -- 125 MHz Max frequency
  constant C_DONE_CYCLES_L : integer := 63;         -- max num of clks before done is released (startup)
  constant C_DONE_CYCLES_H : integer := 24;         -- num of cclks after done is released (startup)

-------------------------------------------------------------------------------
-- Flash interface
-------------------------------------------------------------------------------
  -- Command set for transactions (decoding of the byte from reg bank)
  constant C_PAGE_WRITE   : std_logic_vector(5 downto 0) := "000001"; -- x81
  constant C_PAGE_READ    : std_logic_vector(5 downto 0) := "000010"; -- x82
  constant C_READ_ID      : std_logic_vector(5 downto 0) := "000100"; -- x84
  constant C_READ_STATUS  : std_logic_vector(5 downto 0) := "001000"; -- x88
  constant C_RESET_FLASH  : std_logic_vector(5 downto 0) := "010000"; -- x80
  constant C_BLOCK_ERASE  : std_logic_vector(5 downto 0) := "100000"; -- xA0

 --  Internal command set for flash memory
  constant cCMD1_Read     : STD_LOGIC_VECTOR(7 downto 0) := X"00";
  constant cCMD2_Read     : STD_LOGIC_VECTOR(7 downto 0) := X"30";
  constant cCMD1_RdRndm   : STD_LOGIC_VECTOR(7 downto 0) := X"05";
  constant cCMD2_RdRndm   : STD_LOGIC_VECTOR(7 downto 0) := X"E0";
  constant cCMD1_erase    : STD_LOGIC_VECTOR(7 downto 0) := X"60";
  constant cCMD2_erase    : STD_LOGIC_VECTOR(7 downto 0) := X"D0";
  constant cCMD_ReadID    : STD_LOGIC_VECTOR(7 downto 0) := X"90";
  constant cCMD_Reset     : STD_LOGIC_VECTOR(7 downto 0) := X"FF";
  constant cCMD_RD_STATUS : STD_LOGIC_VECTOR(7 downto 0) := X"70";
  constant cCMD1_Write    : STD_LOGIC_VECTOR(7 downto 0) := X"80";
  constant cCMD2_Write    : STD_LOGIC_VECTOR(7 downto 0) := X"10";


-------------------------------------------------------------------------------
-- Read controller
-------------------------------------------------------------------------------
  constant C_READ_CMD_BITS  : natural := 5;
  constant C_READ_PARAMETER : std_logic_vector(C_READ_CMD_BITS-1 downto 0) := (0 => '1', others => '0'); -- "0000001";
  constant C_READ_CONFIG    : std_logic_vector(C_READ_CMD_BITS-1 downto 0) := (1 => '1', others => '0'); -- "0000010";
  constant C_READ_SCRUB     : std_logic_vector(C_READ_CMD_BITS-1 downto 0) := (2 => '1', others => '0'); -- "0000100";
  constant C_START_PAGE     : std_logic_vector(C_READ_CMD_BITS-1 downto 0) := (3 => '1', others => '0'); -- "0001000";
  constant C_STOP_PAGE      : std_logic_vector(C_READ_CMD_BITS-1 downto 0) := (4 => '1', others => '0'); -- "0010000";

-------------------------------------------------------------------------------
-- Configuration Controller
-------------------------------------------------------------------------------
  constant C_CC_NUMBER_OF_CMD  : natural := 5;
  constant C_CC_STATUS_BITS    : natural := 4;
  constant C_CC_INIT_CONFIG    : std_logic_vector(C_CC_NUMBER_OF_CMD-1 downto 0) := (0 => '1', others => '0');--:= "0000001";  -- full programming cycle
  constant C_CC_CONT_SCRUB     : std_logic_vector(C_CC_NUMBER_OF_CMD-1 downto 0) := (1 => '1', others => '0');--:= "0000010";  -- continuous scrubbing cycle
  constant C_CC_SINGLE_SCRUB   : std_logic_vector(C_CC_NUMBER_OF_CMD-1 downto 0) := (2 => '1', others => '0');--:= "0000100";  -- single scrubbing cycle
  constant C_CC_STOP           : std_logic_vector(C_CC_NUMBER_OF_CMD-1 downto 0) := (3 => '1', others => '0');--:= "0001000";  -- Stop continuous scrubbing
  constant C_CC_SCRUB_CNT_CLR  : std_logic_vector(C_CC_NUMBER_OF_CMD-1 downto 0) := (4 => '1', others => '0');--:= "0010000";  -- Clear scrubbing counter
  --constant C_CC_FRVC           : std_logic_vector(C_CC_NUMBER_OF_CMD-1 downto 0) := (5=> '1', others => '0');--:= "0100000";  -- frame by frame readback, verification & correction

-------------------------------------------------------------------------------
-- Write Controller commands
-------------------------------------------------------------------------------
  constant C_WRITER_CMD_WRITE_XIL      : std_logic_vector(6 downto 0) := "0000001";  -- start writing to flash from xilinx fifo
  constant C_WRITER_CMD_WRITE_BUS      : std_logic_vector(6 downto 0) := "0000010";  -- start writing to flash from bus fifo
  constant C_WRITER_CMD_STOP           : std_logic_vector(6 downto 0) := "0000100";  -- stop operation
  constant C_WRITER_CMD_CLEAR_ERRORS   : std_logic_vector(6 downto 0) := "0001000";  -- clear error flags

-------------------------------------------------------------------------------
  attribute syn_keep : boolean;
  attribute syn_keep of C_TRNX_SIZE : constant is true;
  attribute syn_keep of C_VERSION   : constant is true;

-- TYPES
-------------------------------------------------------------------------------

  ----------------------------------------
  --- Wishbone interface types (from WP10 intercon_pkg.vhd)
  ----------------------------------------
  constant WB_DATA_WIDTH   : natural := 8;
  constant WB_ADD_WIDTH    : natural := 7; -- only one slave
  constant WB_ADDS_WIDTH   : natural := 0;  --slave internal address
  constant WB_ADDB_WIDTH   : natural := (WB_ADD_WIDTH - WB_ADDS_WIDTH); --width of slave internal addressing bus
  -- Watchdog constants definition  --
  constant c_WD_TIMEOUT_WIDTH : positive := 32;
  constant c_WD_TIMEOUT       : std_logic_vector(c_WD_TIMEOUT_WIDTH-1 downto 0) := x"000FFFFF";
  -- Flash interface
  constant C_ROW_WIDTH : natural := 19;
  -- FIFO
  constant C_FIFO_DEPTH : natural := 8; --number of address bits

  -- wishbone slave input data (Master output)
  type t_wbs_in is record
    data   : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    we     : std_logic;
    addr   : std_logic_vector(WB_ADD_WIDTH-1 downto 0);
    cyc    : std_logic;
    stb    : std_logic;
  end record;

  -- wishbone slave output data (Master input)
  type t_wbs_out is record
    data  : std_logic_vector(WB_DATA_WIDTH-1 downto 0);
    err   : std_ulogic;                 -- changed to ulogic to check for address clash
    ack   : std_ulogic;                 -- changed to ulogic to check for address clash
  end record;

  ----------------------------------------
  --- clock control types
  ----------------------------------------
  type t_clkctrl_in is record
    lcl_clk_lol     : std_logic; -- Jitter cleaner: loss of lock (PLL)
    lcl_clk_c1b     : std_logic; -- Jitter cleaner: loss of signal, GBT clock
    lcl_clk_c2b     : std_logic; -- Jitter cleaner: loss of signal, Local clock (X2)
  end record;

  type t_clkctrl_out is record
    lcl_clk_rst     : std_logic; -- Jitter cleaner: active low reset
    lcl_clk_cs      : std_logic; -- Jitter cleaner: clock select:
                                 --                 0 - GBT clock
                                 --                 1 - Local clock (OSC X2)
    lcl_clk_in_sel  : std_logic; -- Clock MUX:
                                 --       0 - jitter cleaner clock
                                 --       1 - local clock (OSC X1)
  end record;



  ----------------------------------------
  --- selectmap interface types
  ----------------------------------------
  type t_selectmap_in is record
    done          : std_logic;
    init_b        : std_logic;
    data          : std_logic_vector(7 downto 0);
  end record;

  type t_selectmap_out is record
    rdwr_b        : std_logic;
    cs_b          : std_logic;
    prog_b        : std_logic;
    cclk          : std_logic;
    data          : std_logic_vector(7 downto 0);
  end record;

  type t_selectmap_internal_in is record
    clear_error   : std_logic;                    -- clears the error register and initiates an abort sequence
    execute       : std_logic;                    -- executes command in command reg
    command       : std_logic_vector(5 downto 0); -- read, write, init, startup, abort
    data          : std_logic_vector(7 downto 0); -- byte to write
  end record;

  type t_selectmap_internal_out is record
    busy          : std_logic;
    status        : std_logic_vector(4 downto 0);
    data          : std_logic_vector(7 downto 0);
  end record;
  ----------------------------------------

  ----------------------------------------
  --- flash interface types
  ----------------------------------------
  type t_flash_internal_in is record
    command        : std_logic_vector(5 downto 0);
    test_ptrn       : std_logic_vector(7 downto 0);  -- Test pattern to be verified on fly while reading Flash memory
    vrfy_ptrn       : std_logic;                     -- Bit set to compare the test pattern and count the mismatch
    execute         : std_logic;                     -- execute command
    flash_address   : std_logic_vector(C_ROW_WIDTH-1 downto 0); -- row address in flash
  end record;

  type t_flash_internal_out is record
    status         : std_logic_vector(5 downto 0);      -- error and whatever
    active_states  : std_logic_vector(25 downto 0);
    mismatch_cnt   : std_logic_vector(7 downto 0);      -- Number of mismatches found with the pattern compared.
  end record;

  type t_flash_buffer_in is record
    data    : std_logic_vector(7 downto 0);  -- data to write to flash
    addr    : std_logic_vector(11 downto 0);
    en      : std_logic;
    rnw     : std_logic;
  end record;

  type t_flash_buffer_out is record
    data    : std_logic_vector(7 downto 0);      -- data returned from flash
  end record;

  type t_flashif_in is record
    R_nB1          : std_logic;
    R_nB2          : std_logic;
    data           : std_logic_vector(7 downto 0);
  end record;

  type t_flashif_out is record
    cle            : std_logic;
    ale            : std_logic;
    we_n           : std_logic;
    re_n           : std_logic;
    ce1_n          : std_logic;
    ce2_n          : std_logic;
    wp_n           : std_logic;
    data           : std_logic_vector(7 downto 0);
  end record;
  ----------------------------------------
  type t_flashctrl_out is record
    cle            : std_logic;
    ale            : std_logic;
    we_n           : std_logic;
    re_n           : std_logic;
    ce_n          : std_logic;
    wp_n           : std_logic;
  end record;
  type t_flashctrl_in is record
    R_nB            : std_logic;
  end record;
  ----------------------------------------
  --- ECC module (data flow is (almost) standard FIFO interface)
  ----------------------------------------
  type t_ecc_data_in is record  
    we   : std_logic;                           -- Write enable
    re   : std_logic;                           -- Read enable
    data : std_logic_vector(7 downto 0);        -- data in to ecc module
  end record;
  
  type t_ecc_data_out is record
    full   : std_logic;                    -- High if fifo is full High when ecc cannot accept more data (fifo full or internal busy set)
    empty  : std_logic;                    -- Emulates FIFO empty signal 
    data   : std_logic_vector(7 downto 0); -- data out from ecc module
  end record;
  
  type t_ecc_status is record
    cnt_flash_sb_errors  : std_logic_vector(7 downto 0); -- number of single bit errors detected in flash
    --cnt_flash_db_errors  : std_logic_vector(3 downto 0); -- number of double bit errors detected in flash
    --cnt_flash_ecc_errors : std_logic_vector(3 downto 0); -- number of ecc code errors detected in flash
    flash_db_error       : std_logic;
    flash_sb_error       : std_logic;
    flash_ecc_error      : std_logic;
  end record;
  
  type t_ecc_fifo_status is record
    cnt_tmr_errors  : std_logic_vector(7 downto 0); -- number of tmr errors detected in FIFO
    tmr_error       : std_logic;  
  end record;  

  type t_ecc_cmd is record
    clear_status        : std_logic; -- clears errors, status and counters
    enable_ecc          : std_logic; -- default high
  end record;
  
  type t_ecc_result is record -- for ecc internal use
    marker         : std_logic_vector(1 downto 0);
    singleBitError : std_logic;
    address        : std_logic_vector(6 downto 0);
    bitpos         : std_logic_vector(2 downto 0);
  end record t_ecc_result;
  
  
  ----------------------------------------
  --- FIFO interface types
  ----------------------------------------
  type t_fifo_in is record
    we_n : std_logic;                           -- Write enable
    re_n : std_logic;                           -- Read enable
    data : std_logic_vector(7 downto 0);        -- Fifo data in
  end record;

  type t_fifo_out is record
    full   : std_logic;                         -- Fifo full
    -- afull  :                                 -- Fifo almost full (Not used at the moment)
    empty  : std_logic;                         -- Fifo empty
    -- aempty : std_logic;                      -- Fifo almost empty (Not used at the moment)
    data   : std_logic_vector(7 downto 0);      -- Fifo data out
  end record;


  type t_read_ctrl_in is record
    execute : std_logic;
    command : std_logic_vector(C_READ_CMD_BITS-1 downto 0);
  end record;

  type t_read_ctrl_out is record
    status   : std_logic_vector(3 downto 0);
  end record;

  ----------------------------------------

  type t_parameter_out is record
    conf_start  : std_logic_vector(C_ROW_WIDTH-1 downto 0);
    conf_stop   : std_logic_vector(C_ROW_WIDTH-1 downto 0);
    bs_start    : std_logic_vector(C_ROW_WIDTH-1 downto 0);
    bs_stop     : std_logic_vector(C_ROW_WIDTH-1 downto 0);
    conf_ok     : std_logic;
    bs_ok       : std_logic;
    param_error : std_logic;
    conf_ecc    : std_logic;
    bs_ecc      : std_logic;
  end record;

  type t_parameter_in is record
    execute        : std_logic;
    --command        : std_logic_vector(7 downto 0);
  end record;

  ----------------------------------------
  --- Write controller types
  ----------------------------------------
  type t_fifo_write_in is record
    data            : std_logic_vector(7 downto 0);
    we              : std_logic;
  end record;

  type t_fifo_write_out is record
    full            : std_logic;
  end record;

  type t_fifo_read_in is record
    re              : std_logic;
  end record;

  type t_fifo_read_out is record
    data            : std_logic_vector(7 downto 0);
    empty           : std_logic;
  end record;

    -- wishbone types
  type t_wb_fifo_writer_in is record
    command         : std_logic_vector(6 downto 0);
    execute         : std_logic;
    addr            : std_logic_vector(C_ROW_WIDTH-1 downto 0);
    fifo_data       : std_logic_vector(7 downto 0);
    fifo_we         : std_logic;
    --page_size       : std_logic_vector(12 downto 0);
  end record;

  type t_wb_fifo_writer_out is record
    ready               : std_logic;
    active_input        : std_logic;
    fifo_empty          : std_logic;
    fifo_full           : std_logic;
    xil_fifo_empty      : std_logic;
    stopping            : std_logic;
    error_wrong_command : std_logic;
    error_fifo_write    : std_logic;
  end record;


  ----------------------------------------
  --- Config controller interface types
  ----------------------------------------
  type t_confctrl_in is record
    execute        : std_logic;
    command        : std_logic_vector(C_CC_NUMBER_OF_CMD-1 downto 0);
  end record;

  type t_confctrl_out is record
    status       : std_logic_vector(C_CC_STATUS_BITS-1 downto 0);  -- busy, config_done, error
    active_state : std_logic_vector(3 downto 0);  -- Indicates the active state in state mashine
    scrub_cnt    : std_logic_vector(15 downto 0); -- Counter for number of scrub cycles done
  end record;
  ----------------------------------------


-------------------------------------------------------------------------------
-- END TYPES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- FUNCTIONS AND PROCEDURES
-------------------------------------------------------------------------------
  function bitswap(input : in std_logic_vector) return std_logic_vector;
  
  -- Generates a hamming code for a 8 bit word
  function hamming8(data    : in std_logic_vector(7 downto 0) )          return std_logic_vector;
  -- calculates syndrome based on received word
  function hamming8_syndrome(data    : in std_logic_vector(7 downto 0);
                    hmg_code: in std_logic_vector(4 downto 0))           return std_logic_vector;

end package auxFPGA_pkg;

package body auxFPGA_pkg is


  --purpose: swapping bits of an input vector
  function bitswap(input : in std_logic_vector) return std_logic_vector is
    variable output : std_logic_vector(input'range);
  begin
    for I in 0 to input'high loop
      output(I) :=  input(input'high-I); -- bit swap
    end loop;
    return output;
  end;
  
  --purpose: hamming decoding 8 bit
  function hamming8 (data : in std_logic_vector(7 downto 0) )            return std_logic_vector is
    variable hmg: std_logic_vector(4 downto 0);
  begin
    hmg(0) := data(0) xor data(1) xor data(3) xor data(4) xor data(6);
    hmg(1) := data(0) xor data(2) xor data(3) xor data(5) xor data(6);
    hmg(2) := data(1) xor data(2) xor data(3) xor data(7);
    hmg(3) := data(4) xor data(5) xor data(6) xor data(7); 
    hmg(4) := hmg(0) xor hmg(1) xor hmg(2) xor hmg(3) xor data(0) xor data(1) xor data(2) xor 
              data(3) xor data(4) xor data(5) xor data(6) xor data(7); 
    return hmg;
  end function hamming8;
  
  
  -- calculates new hamming code based on received word
  -- then calculates syndrome
  function hamming8_syndrome (data : in std_logic_vector(7 downto 0);
                     hmg_code: in std_logic_vector(4 downto 0) )         return std_logic_vector is
    variable hmg: std_logic_vector(4 downto 0);
  begin
    hmg := hamming8(data);
    return (hmg xor hmg_code);
  end function hamming8_syndrome;

  
  
end package body;
