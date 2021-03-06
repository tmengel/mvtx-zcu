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

  constant cADD_REGSPACE               : natural := 0;   -- slave address
  --constant cADD_MEMSPACE        : natural := 1;   -- mem address
  -- global adresses            (memspace x00 - x07)
  constant cADD_MINOR_VERSION          : natural := 0;   -- r  from bus
  constant cADD_MAJOR_VERSION          : natural := 1;   -- r  from bus
  constant cADD_RESET                  : natural := 2;   -- w  from bus, r   from module (will issue pulses)
  constant cADD_STATUS_CLOCK           : natural := 3;   -- r  from bus, set from hardwire input
  constant cADD_CNFG_CLOCK             : natural := 4;   -- rw from bus, rw  from module
  -- config controller adresses (memspace x08 - x0F)
  constant cADD_CC_CMD                 : natural := 8;   -- rw from bus, rw from module
  constant cADD_CC_STATUS              : natural := 9;   -- r  from bus, rw from module
  constant cADD_CC_ACTIVE_STATE        : natural := 10;  -- r  from bus, rw from module
  constant cADD_CC_MINOR_SCRUB_CNT     : natural := 11;  -- r  from bus, rw from module
  constant cADD_CC_MAJOR_SCRUB_CNT     : natural := 12;  -- r  from bus, rw from module
  -- read controller            (memspace x10 - x17)
  constant cADD_RC_CMD                 : natural := 16;  -- r  from bus, rw from module
  constant cADD_RC_STATUS              : natural := 17;  -- r  from bus, rw from module
  -- SelectMap addresses        (memspace x18 - x1F)
  constant cADD_SMAP_CMD               : natural := 24;  -- rw from bus, rw  from module
  constant cADD_SMAP_DATA_TX           : natural := 25;  -- r  from bus, rw from module
  constant cADD_SMAP_DATA_RX           : natural := 26;  -- rw from bus,r from module
  constant cADD_SMAP_STATUS            : natural := 27;  -- r  from bus, rw from module
  -- flash adresses             (memspace x20 - x2F)
  constant cADD_FLASH_CTRL             : natural := 32;  -- rw from bus, r  from module
  constant cADD_FLASH_STATUS           : natural := 33;  -- r  from bus, rw from module
  constant cADD_FLASH_PATTERN          : natural := 34;  -- rw from bus, r  from module
  constant cADD_FLASH_MIS_CNT          : natural := 35;  -- r  from bus, rw from module
  constant cADD_FLASH_PAGE_ADDR        : natural := 36;  -- rw from bus, r  from module
  constant cADD_FLASH_MINOR_BLOCK_ADDR : natural := 37;  -- rw from bus, r  from module
  constant cADD_FLASH_MAJOR_BLOCK_ADDR : natural := 38;  -- rw from bus, r  from module
  constant cADD_FLASH_MINOR_TRX_SIZE   : natural := 39;  -- rw from bus, r  from module
  constant cADD_FLASH_MAJOR_TRX_SIZE   : natural := 40;  -- rw from bus, r  from module
  constant cADD_FLASH_STATE_0          : natural := 70;  -- r  from bus, rw from module
  constant cADD_FLASH_STATE_1          : natural := 71;  -- r  from bus, rw from module
  constant cADD_FLASH_STATE_2          : natural := 72;  -- r  from bus, rw from module
  constant cADD_FLASH_STATE_3          : natural := 77;  -- r  from bus, rw from module
  constant cADD_FLASH_ST_WRD          : natural := 78;  -- r  from bus, rw from module
 
  
  -- Read fifo                  (memspace x30 - x37)
  constant cADD_FIFO_DATA_RD           : natural := 48;  -- r  from bus, rw from module
  constant cADD_FIFO_DATA_WR           : natural := 49;  -- rw from bus, r  from module
  constant cADD_FIFO_STATUS            : natural := 50;  -- r  from bus, rw from module
  -- Write controller
  constant cADD_FIFO_WRITER_CMD        : natural := 51;  -- rw from bus, rw  from module
  constant cADD_FIFO_WRITER_STATUS     : natural := 52;  -- r  from bus, rw from module
  -- ECC                        (memspace x38 - x3F)
  constant cADD_ECC_COMMAND            : natural := 56;  -- wt from bus, r from module
  constant cADD_ECC_STATUS             : natural := 57;  -- wt from bus, w from module (cleared when writing to)
  constant cADD_ECC_SB_CNT             : natural := 58;  -- r  from bus, w from module
  constant cADD_ECC_FIFOTMR_ERR_CNT    : natural := 59;  -- r  from bus, w from module
  -- debug type registers       (memspace x40 ->)
  constant cADD_DIPSWITCH1             : natural := 64;  -- r  from bus, set from hardwire input
  constant cADD_DIPSWITCH2             : natural := 65;  -- r  from bus, set from hardwire input
  constant cADD_PUSHBUTTON             : natural := 66;  -- r  from bus, set from hardwire input
  constant cADD_CTRL_LEDs              : natural := 67;  -- rw from bus, r  from module
  -- CRC-32
  constant cADD_CRC_0                  : natural := 73; -- r  from bus, rw from module
  constant cADD_CRC_1                  : natural := 74; -- r  from bus, rw from module
  constant cADD_CRC_2                  : natural := 75; -- r  from bus, rw from module
  constant cADD_CRC_3                  : natural := 76; -- r  from bus, rw from module

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
    status        : std_logic_vector(3 downto 0);
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
