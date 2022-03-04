import datetime
import json
from collections import OrderedDict

# import enums that define the registers.
from proasic3_enums import Pa3Register, \
    CcActiveState, CcCmdOpcode, CcStatus, RcCmdOpcode, \
    RcState, SmapCmdOpcode, SmapStatus, FlashCmdOpcode, \
    FlashFsmBlockEraseControllerState, FlashFsmNandControllerState, \
    FlashFsmPageReadController, FlashFsmPageWriteController, \
    FlashFsmReadIdControllerState, FifoState, FifoWriterCmdOpcode, \
    FifoWriterStatus, FlashSelectICOpcode, EccCmdFlags, \
    EccCmdOpcodes, LocalClockMuxInputSelect

EXEC = 0x80


class ConvenienceInitializer:
    """ send PA3 write, read, and logger methods to this

    why not use the Pa3 object you ask? answer: because the methods needed are explicitly these.
    So this will look cleaner, and be easier to read.
    """

    def __init__(self, write_f, read_f, logger):
        assert callable(write_f)
        assert callable(read_f)
        self.write_f = write_f
        self.read_f = read_f
        self.logger = logger


class ConvenienceBase:
    """ parent of convenience functions. Takes initalizer of class ConvenienceInitializer
    usages: child = Child(Initializer)
    , ecc_commands = Ecc(Initializer)"""

    def __init__(self, convcarrier: ConvenienceInitializer):
        self.read_reg = convcarrier.read_f
        self.write_reg = convcarrier.write_f
        self.logger = convcarrier.logger


class Status(ConvenienceBase):
    """Basic status items"""

    def version(self, verbose=True):
        """Gets the PA3 FPGA design version"""
        version_msb = self.read_reg(Pa3Register.MAJOR_VERSION)
        version_lsb = self.read_reg(Pa3Register.MINOR_VERSION)
        version = ((version_msb & 0xFF) << 8) | (version_lsb & 0xFF)
        if verbose:
            self.logger.info(f"ProAsic3 Ru Board firmware v{version:04X}")
        return version

    def get_dipswitches(self):
        lsb = self.read_reg(Pa3Register.DIPSWITCH1)
        msb = self.read_reg(Pa3Register.DIPSWITCH2)
        return msb << 8 | lsb

    def get_led(self):
        return self.read_reg(Pa3Register.CTRL_LEDS)

    def set_led(self, value):
        assert value <= 0xF
        self.write_reg(Pa3Register.CTRL_LEDS, value)

    def config_get(self, filename=None) -> dict:
        """Print (or if filename is set, log to file) all wishbone registers of the PA3"""
        regs = dict()
        regs["TIMESTAMP"] = datetime.datetime.now().isoformat()
        for register in Pa3Register:
            regs[register.name] = f"0x{self.read_reg(register):02x}"  # hex(self.read_reg(register))
        if filename:
            with open(filename, 'a') as logfile:
                json.dump(regs, logfile)
        return regs

    def githash(self):
        regs = [Pa3Register.HASH_0, Pa3Register.HASH_1,
                Pa3Register.HASH_2, Pa3Register.HASH_3]
        hashcode = 0
        for i, reg in enumerate(regs):
            regval = self.read_reg(reg)
            hashcode = hashcode | (regval << 8 * i)
        print("githash of pa3 fw is", hex(hashcode))
        return hashcode


class ConfigController(ConvenienceBase):
    """Configuration controller module, responsible for scrubbing and programming of the ultrascale

    reprogram_ultrascale loads the firmare onto the Xilinx

    (start/stop)_blind_scrubbing controls the blind scrubbing. If this works you should see the scrubbing counter increase

    get_scrubbing_counter shows the n.o. times scrubbing has occured since reset

    cc is short for Configuration Controller
    """

    def set_cc_command_register(self, opcode, execute=True):
        """Writes the CC_CMD register"""
        opcode = CcCmdOpcode(opcode)
        self.write_reg(Pa3Register.CC_CMD, opcode | (execute and EXEC))

    def get_cc_command_register(self):
        """Reads the CC_CMD register"""
        value = self.read_reg(Pa3Register.CC_CMD)
        name = None
        if value in [item.value for item in CcCmdOpcode]:
            name = CcCmdOpcode(value).name
        return value, name

    def get_program_done(self):
        value = self.read_reg(Pa3Register.SMAP_STATUS)
        return (value >> SmapStatus.XILINX_DONE_PIN) & 1, value

    def reprogram_ultrascale(self):
        self.set_cc_command_register(CcCmdOpcode.INIT_CONFIG)

    def start_blind_scrubbing(self):
        self.set_cc_command_register(CcCmdOpcode.CONT_SCRUB)

    def stop_blind_scrubbing(self):
        self.set_cc_command_register(CcCmdOpcode.STOP)

    def run_single_scrub(self):
        self.set_cc_command_register(CcCmdOpcode.SINGLE_SCRUB)

    def clear_scrubbing_counter(self):
        self.logger.info("Resetting PA3 scrubbing counter")
        self.set_cc_command_register(CcCmdOpcode.SCRUB_CNT_CLR)

    def get_cc_status(self):
        value = self.read_reg(Pa3Register.CC_STATUS)
        ret_dict = {}
        for flag in CcStatus:
            ret_dict[flag.name] = (value >> flag.value) & 1
        return value, ret_dict

    def get_scrubbing_counter(self):
        scrub_cnt_lsb = self.read_reg(Pa3Register.CC_SCRUB_CNT_LSB)
        scrub_cnt_msb = self.read_reg(Pa3Register.CC_SCRUB_CNT_MSB)
        scrub_cnt = (scrub_cnt_msb << 8) | scrub_cnt_lsb
        return scrub_cnt

    def get_crc(self):
        crc_0 = self.read_reg(Pa3Register.CRC_0)
        crc_1 = self.read_reg(Pa3Register.CRC_1)
        crc_2 = self.read_reg(Pa3Register.CRC_2)
        crc_3 = self.read_reg(Pa3Register.CRC_3)
        crc = (crc_3 << 24) | (crc_2 << 16) | (crc_1 << 8) | crc_0
        return crc

    def is_idle(self):
        return self.get_cc_status()[1]['IDLE'] == 1

    def is_init_config_done(self):
        return self.get_cc_status()[1]['INIT_CONFIG_DONE'] == 1

    def is_scrubbing(self):
        return self.get_cc_status()[1]['SCRUBBING_ONGOING'] == 1

    def get_cc_active_state(self):
        value = self.read_reg(Pa3Register.CC_ACTIVE_STATE)
        return value, CcActiveState(value).name


class Ecc(ConvenienceBase):
    """ Ecc module, responsible for data integrity on the flash chip."""
    ECC_CMD = Pa3Register.ECC_CMD

    def get_ecc_command_register(self):
        value = self.read_reg(Pa3Register.ECC_CMD)
        ret_dict = {}
        for flag in EccCmdFlags:
            ret_dict[str(flag.name)] = (value >> flag.value) & 1
        return value, ret_dict

    def enable_ecc(self):
        self.write_reg(Ecc.ECC_CMD, EccCmdOpcodes.ECC_CLEAR_ENABLE)

    def disable_ecc(self):
        self.write_reg(Ecc.ECC_CMD, EccCmdOpcodes.ECC_CLEAR_DISABLE)

    def reset_ecc_counters_and_status(self):
        if self.ecc_on():
            self.write_reg(Ecc.ECC_CMD, EccCmdOpcodes.ECC_CLEAR_ENABLE)
        else:
            self.write_reg(Ecc.ECC_CMD, EccCmdOpcodes.ECC_CLEAR_DISABLE)

    def get_ecc_sb_error_counter(self):
        return self.read_reg(Pa3Register.ECC_SB_ERROR_CNT)

    def get_ecc_fifo_tmr_error(self):
        return self.read_reg(Pa3Register.ECC_FIFO_TMR_ERROR)

    def clear_ecc_status(self):
        self.write_reg(Pa3Register.ECC_STATUS, 0xF)

    def get_status(self):
        return self.read_reg(Pa3Register.ECC_STATUS)

    def ecc_on(self) -> bool:
        """is ecc on?"""
        return self.read_reg(Pa3Register.ECC_CMD) & 0b1 == 1


class Flash(ConvenienceBase):
    """Flash module registers"""

    # if pattern verification is wanted this function must be adapted to read/write function to check status of bit 6
    def set_flash_command_register(self, opcode, execute=True):
        """
        Write opcode to flash control module
        :param FlashCmdOpcode opcode: opcode. Careful!
        :param bool execute: should always be True
        """
        opcode = FlashCmdOpcode(opcode)
        self.write_reg(Pa3Register.FLASH_CTRL, opcode | (execute and EXEC))

    def get_flash_command_register(self):
        value = self.read_reg(Pa3Register.FLASH_CTRL)
        name = None
        if value in [item.value for item in FlashCmdOpcode]:
            name = FlashCmdOpcode(value).name
        return value, name

    def set_flash_address(self, block_address=0, page_address=0, whole_address=None):
        """Uses either block_address and page_addres OR the whole_address
        :param int block_address: 16 bit "block" address
        :param int page_address: 8 bit "page" address
        :param int whole_address: 19 bit address (8192 block count * 64 pages per block)
        """
        if whole_address is None:
            assert block_address <= 0xFFFF
            assert page_address <= 0xFF
            block_address_msb = block_address >> 8
            block_address_lsb = block_address & 0xFF
        else:
            page_address = whole_address & 0xff
            block_address_lsb = (whole_address >> 8) & 0xff
            block_address_msb = (whole_address >> 16) & 0xff
        self.write_reg(Pa3Register.FLASH_BLOCK_ADDR_MSB, block_address_msb)
        self.write_reg(Pa3Register.FLASH_BLOCK_ADDR_LSB, block_address_lsb)
        self.write_reg(Pa3Register.FLASH_PAGE_ADDR, page_address)

    def get_flash_byte_counter(self):
        value = self.read_reg(Pa3Register.FLASH_TRX_CNT_LSB)
        value = self.read_reg(Pa3Register.FLASH_TRX_CNT_MSB) << 8 | value
        return value

    def set_flash_select_ic(self, value):
        """
        b00: Not legal value. Default flash b01 (IC 1) is selected  \n
        b01: Flash IC 1 (FLASH_CE1/FLASH_R_B1_n)  \n
        b10: Flash IC 2 (FLASH_CE2/FLASH_R_B2_n)  \n
        b11: Both IC1 and IC2 active (NOT LEGAL FOR READ PAGE OR READ ID OPERATION - WILL CORRUPT DATA. Writing and Erasing is OK.
        """
        self.write_reg(Pa3Register.FLASH_SELECT_IC, value)

    def get_flash_select_ic(self):
        value = self.read_reg(Pa3Register.FLASH_SELECT_IC)
        if value in [item.value for item in FlashSelectICOpcode]:
            name = FlashSelectICOpcode(value).name
        return value, name

    def get_flash_status_word(self):
        value = self.read_reg(Pa3Register.FLASH_STATUS_WORD)
        return value

    def get_flash_status(self):
        """
        #1 [0] Done with command (Read/Write/Erase/Read ID)
        #2 [1] Fifo Status (Write FIFO EMPTY or Read FIFO FULL)
        #4 [2] Status Bit from Flash after ended command. '1' means an error has occured.
        #8 [3] Write Active
        #0x10 [4] Read Active
        #0x20 [5] Command Active (ReadID, Erase, Reset)
        #0x40 [6] Trx_done (Sticky bit)"
        :return:
        """

        status_dict = OrderedDict({'Done_with_command': False, 'WfifoEmpty_or_RfifoFull': False,
                                   'Error_bit': False, 'Write_active': False, 'Read_active': False,
                                   'Command_active': False, 'done_sticky': False, 'activity': False})
        value = self.read_reg(Pa3Register.FLASH_STATUS)
        for bitn, key in enumerate(status_dict.keys()):
            status_dict[key] = bool((value >> bitn) & 0b1)
        status_dict['activity'] = status_dict['Write_active'] or status_dict['Read_active'] or status_dict[
            'Command_active']
        return value, status_dict

    def set_pattern_checker(self, value):
        self.write_reg(Pa3Register.FLASH_PATTERN, value)
        self.write_reg(Pa3Register.FLASH_CTRL, 0x40)
        return value

    def get_flash_state(self):
        value = (self.read_reg(Pa3Register.FLASH_STATE_0) |
                 self.read_reg(Pa3Register.FLASH_STATE_1) << 8 |
                 self.read_reg(Pa3Register.FLASH_STATE_2) << 16 |
                 self.read_reg(Pa3Register.FLASH_STATE_3) << 24)
        ret_dict = {}

        value_tmp = value & 0xF  # [3:0]
        name = None
        if value_tmp in [item.value for item in FlashFsmNandControllerState]:
            name = FlashFsmNandControllerState(value_tmp).name
        ret_dict['fsm_nand_controller'] = (value_tmp, name)

        value_tmp = value >> 4 & 0x3F  # [9:4]
        name = None
        if value_tmp in [item.value for item in FlashFsmPageWriteController]:
            name = FlashFsmPageWriteController(value_tmp).name
        ret_dict['fsm_page_write_controller'] = (value_tmp, name)

        value_tmp = (value >> 9) & 0x3F  # [15:9]
        name = None
        if value_tmp in [item.value for item in FlashFsmPageReadController]:
            name = FlashFsmPageReadController(value_tmp).name
        ret_dict['fsm_page_read_controller'] = (value_tmp, name)

        value_tmp = (value >> 16) & 0x3F  # [21:16]
        name = None
        if value_tmp in [item.value for item in FlashFsmBlockEraseControllerState]:
            name = FlashFsmBlockEraseControllerState(value_tmp).name
        ret_dict['fsm_block_erase_controller'] = (value_tmp, name)

        value_tmp = (value >> 22) & 0xF  # [25:22]
        name = None
        if value_tmp in [item.value for item in FlashFsmReadIdControllerState]:
            name = FlashFsmReadIdControllerState(value_tmp).name
        ret_dict['fsm_read_id_controller'] = (value_tmp, name)

        return value, ret_dict

    def get_flash_page_size(self):
        page_size_lsb = self.read_reg(Pa3Register.FLASH_TRX_SIZE_LSB)
        page_size_msb = self.read_reg(Pa3Register.FLASH_TRX_SIZE_MSB)
        return (page_size_msb << 8) | page_size_lsb

    def set_flash_page_size(self, page_size):
        self.write_reg(Pa3Register.FLASH_TRX_SIZE_LSB, page_size & 0xFF)
        self.write_reg(Pa3Register.FLASH_TRX_SIZE_MSB, (page_size >> 8) & 0xFF)



class Clock(ConvenienceBase):
    """legacy code, be careful"""

    def get_clock_status(self):
        """Get Status of clocks"""
        value = self.read_reg(Pa3Register.CLOCK_STATUS)
        ret_dict = {'lcl_clk_lol': (value >> 0) & 1,
                    'lcl_clk_c1b': (value >> 1) & 1,
                    'lcl_clk_c2b': (value >> 2) & 1}
        return value, ret_dict

    def set_clock_config(self, lcl_clk_in_se=None, lcl_clk_cs=None, lcl_clk_rst=None):
        """Set the clock configuration"""
        do_read = False
        if lcl_clk_in_se is None or lcl_clk_cs is None or lcl_clk_rst is None:
            do_read = True
        if do_read:
            _, read_value = self.get_clock_config()
        if lcl_clk_in_se is None:
            lcl_clk_in_se = read_value['lcl_clk_in_se']
        if lcl_clk_cs is None:
            lcl_clk_cs = read_value['lcl_clk_cs']
        if lcl_clk_rst is None:
            lcl_clk_rst = read_value['lcl_clk_rst']
        assert lcl_clk_in_se in range(2)
        assert lcl_clk_cs in range(2)
        assert lcl_clk_rst in range(2)
        write_value = lcl_clk_rst << 2 | lcl_clk_cs << 1 | lcl_clk_in_se
        self.write_reg(Pa3Register.CLOCK_CONFIG, write_value)

    def get_clock_config(self):
        """Gets the clock configuration"""
        value = self.read_reg(Pa3Register.CLOCK_CONFIG)
        ret_dict = {'lcl_clk_in_se': (value >> 0) & 1,
                    'lcl_clk_cs': (value >> 1) & 1,
                    'lcl_clk_rst': (value >> 2) & 1}
        return value, ret_dict

    def set_clock_mux_input(self, value):
        """Sets the clock multiplexer on the RU"""
        value = LocalClockMuxInputSelect(value)
        self.set_clock_config(lcl_clk_in_se=value)

    def get_clock_mux_input(self):
        """Gets the clock multiplexer on the RU"""
        info = self.get_clock_config()[1]['lcl_clk_in_se']
        return LocalClockMuxInputSelect(info).name

    def set_clock_mux_source_crystal(self):
        self.set_clock_mux_input(LocalClockMuxInputSelect.CRYSTAL)

    def set_clock_mux_source_jitter_cleaner(self):
        self.set_clock_mux_input(LocalClockMuxInputSelect.JITTER_CLEANER)


class Fifo(ConvenienceBase):
    def get_fifo_rx_data(self):
        return self.read_reg(Pa3Register.FIFO_RX_DATA)

    def set_fifo_tx_data(self, data):
        assert data <= 0xFF
        self.write_reg(Pa3Register.FIFO_TX_DATA, data)

    def get_fifo_status(self):
        value = self.read_reg(Pa3Register.FIFO_STATUS)
        ret_dict = {}
        for flag in FifoState:
            ret_dict[str(flag.name)] = bool((value >> flag.value) & 1)
        return value, ret_dict

    def set_fifo_writer_command_register(self, opcode, execute=True):
        """
        :param FifoWriterCmdOpcode opcode: opcodes defined by enum
        :param bool execute: True as default
        """
        opcode = FifoWriterCmdOpcode(opcode)  # auto asserts
        self.write_reg(Pa3Register.FIFO_WRITER_CMD, opcode | (execute and EXEC))

    def get_fifo_writer_command_register(self):
        value = self.read_reg(Pa3Register.FIFO_WRITER_CMD)
        name = None
        if value in [item.value for item in FifoWriterCmdOpcode]:
            name = FifoWriterCmdOpcode(value).name
        return value, name

    def get_fifo_writer_status(self):
        value = self.read_reg(Pa3Register.FIFO_WRITER_STATUS)
        ret_dict = {}
        for flag in FifoWriterStatus:
            ret_dict[str(flag.name)] = bool((value >> flag.value) & 1)
        return value, ret_dict


class SelectMap(ConvenienceBase):
    """Select map IF registers"""

    def set_smap_command_register(self, opcode, execute=True):
        assert opcode in [item.value for item in SmapCmdOpcode], "Invalid SMAP CMD opcode"
        opcode = SmapCmdOpcode(opcode)
        self.write_reg(Pa3Register.SMAP_CMD, opcode | (execute and EXEC))

    def get_smap_command_register(self):
        value = self.read_reg(Pa3Register.SMAP_CMD)
        name = None
        if value in [item.value for item in SmapCmdOpcode]:
            name = SmapCmdOpcode(value).name
        return value, name

    def set_smap_byte_tx(self, byte):  # ! TODO nonsense
        assert byte <= 0xFF
        self.write_reg(Pa3Register.SMAP_DATA_TX, byte)

    def get_smap_byte_tx(self):
        return self.read_reg(Pa3Register.SMAP_DATA_TX)

    def get_smap_byte_rx(self):
        return self.read_reg(Pa3Register.SMAP_DATA_RX)

    def get_smap_status(self):
        value = self.read_reg(Pa3Register.SMAP_STATUS)
        ret_dict = {}
        for flag in SmapStatus:
            ret_dict[str(flag.name)] = (value >> flag.value) & 1
        return value, ret_dict


class ReadController(ConvenienceBase):
    """Readcontroller class, see RcCmdOpcode enum """

    def set_rc_command_register(self, opcode, execute=True):
        assert opcode in [item.value for item in RcCmdOpcode], "Invalid RC CMD opcode"
        opcode = RcCmdOpcode(opcode)
        self.write_reg(Pa3Register.RC_CMD, opcode | (execute and EXEC))

    def get_rc_command_register(self):
        value = self.read_reg(Pa3Register.RC_CMD)
        name = None
        if value in [item.value for item in RcCmdOpcode]:
            name = RcCmdOpcode(value).name
        return value, name

    def get_rc_current_page(self):
        value = self.read_reg(Pa3Register.RC_FLASHPAGE1)
        value = self.read_reg(Pa3Register.RC_FLASHPAGE2) << 8 | value
        value = self.read_reg(Pa3Register.RC_FLASHPAGE3) << 16 | value
        return value

    def get_rc_status(self):
        value = self.read_reg(Pa3Register.RC_STATUS)
        ret_dict = {}
        for flag in RcState:
            ret_dict[str(flag.name)] = (value >> flag.value) & 1
        return value, ret_dict
