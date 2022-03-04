from typing import List, Dict

import math
import os
import random
import time
from collections import OrderedDict
from itertools import zip_longest

from progressbar import ProgressBar
from tqdm import tqdm
from timeout_decorator.timeout_decorator import TimeoutError
from timeout_decorator.timeout_decorator import timeout

from multiprocessing import Process
from ecc_conversion.ecc_functions import make_ecc_file
from ecc_conversion.generateScrubbingFile import Scrub
from ecc_conversion.makeparameters import make_parameter_file_and_ecc
from gbt_sca import Sca
from proasic3_convenience import Flash, Fifo, Ecc
from proasic3_enums import Pa3Register, \
    FlashCmdOpcode, \
    FlashFsmBlockEraseControllerState, FlashFsmNandControllerState, \
    FlashFsmPageReadController, FlashFsmPageWriteController, \
    FlashFsmReadIdControllerState, FifoWriterCmdOpcode, \
    FlashSelectICOpcode, EccCmdOpcodes

EXEC = 0x80


class ProAsic3Flash(Flash, Fifo, Ecc):
    """Flash interface higher-level functions"""
    BLOCK_COUNT = 8192
    PAGE_SIZE = 4096
    PAGE_PER_BLOCK = 64
    BLOCK_SIZE = PAGE_SIZE * PAGE_PER_BLOCK
    ADDRESS_MAX = PAGE_PER_BLOCK * BLOCK_COUNT

    def __init__(self, conv_init, write_fifo_f):
        super(ProAsic3Flash, self).__init__(conv_init)
        self.ECC_ON = None
        self.write_fifo_reg_multi_byte = write_fifo_f

    def initialize(self):
        ecc_cmd = self.read_reg(Pa3Register.ECC_CMD)
        self.ECC_ON = bool(ecc_cmd & 0b1)
        if self.ECC_ON:
            ProAsic3Flash.PAGE_SIZE = 0x1060
        else:
            ProAsic3Flash.PAGE_SIZE = 0x1000

    def _flash_erase_blocks(self, start_block, num_blocks):
        """Erase a range of blocks from the FLASH"""

        assert start_block + num_blocks in range(ProAsic3Flash.BLOCK_COUNT)  # change with <= ?
        start = start_block
        stop = (start_block + num_blocks)
        logstr = f"ereasing blocks 0x{start:x} to 0x{stop:x} pages 0x{start * 0x40:x} to 0x{stop * 0x40:x}"
        self.logger.info(logstr)
        pbar = ProgressBar()
        for block in pbar(range(start_block, start_block + num_blocks)):
            page_adr = block * ProAsic3Flash.PAGE_PER_BLOCK
            self.set_flash_address(whole_address=page_adr)

            self.set_flash_command_register(FlashCmdOpcode.BLOCK_ERASE)
            self.flash_wait_ready()

    def flash_write_data(self, data, start_block, ECC=False, override_page_size=0):
        """Write a binary file to flash
        warning : erases whole blocks.
        """
        t0 = time.strftime("%H:%M:%S", time.gmtime())
        self.logger.info("started at " + t0)
        self.logger.info("this function might fail in some cases if you write to a bad block.\n"
                         "To solve this, choose another block, for example increment the block by 0x100")
        page_address = start_block * ProAsic3Flash.PAGE_PER_BLOCK
        assert 0 <= page_address < ProAsic3Flash.ADDRESS_MAX, \
            "Page address invalid: does not fit in flash address space"
        if ECC or self.ecc_on():
            self.set_flash_page_size(0x1060)
            page_size = 0x1060
        else:
            self.set_flash_page_size(0x1000)
            page_size = 0x1000
        if override_page_size:
            self.set_flash_page_size(override_page_size)
            page_size = page_size

        size_pages = math.ceil(len(data) / page_size)
        size_blocks = int(math.ceil(size_pages / ProAsic3Flash.PAGE_PER_BLOCK))  # !! gives 95 =!=!=!=!
        self.logger.debug("Writing a file to the flash\nSize is {} blocks".format(size_blocks))

        self._flash_erase_blocks(start_block, size_blocks)
        # todo insert flash_select_ic
        self.set_fifo_writer_command_register(FifoWriterCmdOpcode.CLEAR_ERRORS)

        # Set bitfile start page addr
        addres_of_start_block = start_block * ProAsic3Flash.PAGE_PER_BLOCK
        self.set_flash_address(whole_address=addres_of_start_block)
        self.logger.info("Writing to page {:04X}".format(int(addres_of_start_block)))
        fws_val, fws_dict = self.get_fifo_writer_status()  # fws = fifo_writer_status
        assert fws_dict['READY'], "PA3 write controller reports busy"

        self.set_fifo_writer_command_register(FifoWriterCmdOpcode.WRITE_BUS)  # Start writing with wb bus as input
        if (len(data) % page_size) != 0:
            self.logger.debug("Filling out the bytearray")
            delta_l = page_size - (len(data) % page_size)
            data.extend([0xFF] * delta_l)

        pbar = ProgressBar(min_value=0, max_value=len(data) // 16)
        for bytes in pbar(grouper(data, 16)):
            self.write_fifo_reg_multi_byte(Pa3Register.FIFO_TX_DATA, bytes)

        self.set_fifo_writer_command_register(FifoWriterCmdOpcode.STOP)
        self.flash_wait_ready()

        t1 = time.strftime("%H:%M:%S", time.gmtime())
        self.logger.info("write to flash ended at " + t1)

    @timeout(3, exception_message="FLASH never ready")
    def flash_wait_ready(self):
        """Waits until PA3 flash status register returns ready"""
        i = 0
        kvalues = set()
        while True:
            flash_status_value, flash_status = self.get_flash_status()  # self.regs.FLASH_STATUS.read()
            kvalues.add(hex(flash_status_value))
            ready = flash_status['done_sticky'] and not flash_status['activity']
            error = flash_status['Error_bit']
            if ready:
                break
            if error:
                self.logger.warning("Hardware reports flash Error bit")
                raise ValueError("Hardware reports flash Error bit")
            i += 1
            if i % 100 == 0:
                self.logger.info("flash waiting i:{}, k:0x{:02X} \n values:{}".format(i, flash_status_value, kvalues))

    def _flash_empty_read_fifo(self):
        """Empty the FLASH Read FIFO"""
        while (self.read_reg(Pa3Register.FIFO_STATUS) & 0b10) == 0:
            # Todo: Timeouts?
            self.read_reg(Pa3Register.FIFO_RX_DATA)

    @timeout(5, exception_message="INTERNAL_RD_FIFO_EMPTY bit not low")
    def _flash_poll_internal_rd_fifo_not_empty(self):
        """
        poll the INTERNAL_RD_FIFO_EMPTy bit for negative value
        """
        while True:
            status_val, status_dict = self.get_fifo_status()
            if (status_val & 0b10) == 0:
                break

    def flash_read_page(self, page_address, ECC=False, override_page_size=None):
        """Reads a page from the flash and returns it as a bytearray
        """
        assert 0 <= page_address < ProAsic3Flash.ADDRESS_MAX, \
            "Page address invalid: does not fit in flash address space"
        data_size = 0x1000  # data size is always! 0x1000, no matter ecc or not. unless override
        if ECC or self.ecc_on():
            self.set_flash_page_size(0x1060)
        else:
            self.set_flash_page_size(0x1000)
        if override_page_size:
            self.set_flash_page_size(override_page_size)
            data_size = override_page_size

        # Empty read fifo
        self._flash_empty_read_fifo()  # ok
        self.set_flash_address(whole_address=page_address)
        self.set_flash_command_register(FlashCmdOpcode.PAGE_READ)
        page_buf = []  # bytearray() #bytearray([0x00] * page_size)
        try:
            for i in range(data_size):
                self._flash_poll_internal_rd_fifo_not_empty()  # this is 2
                val = self.get_fifo_rx_data()
                page_buf.append(val)
        except TimeoutError as e:
            self.logger.info("reached page", hex(i), "of", hex(data_size), "before timeout")
            raise e

        return bytearray(page_buf)

    def _dump_page(self, page_buf, page_address, to_screen=False, path='.', file_base_name='page_dump'):
        """Dumps the selected page to file.
        if to_screen is True it writes it into the logfile"""
        page_buf = get_words_from_list(xs=page_buf)

        if to_screen:
            self.logger.info(page_buf)
        else:
            directory = path + '/flash_dump/'
            if not os.path.exists(directory):
                os.makedirs(directory)
            filename = '{0}_{1}'.format(file_base_name, page_address)
            with open(directory + filename, 'w+') as f:
                f.write(page_buf)
            self.logger.info("dumped page {0} to file {1}".format(page_address, directory + filename))

    def disp_page(self, page_address):
        data = self.flash_read_page(page_address, self.ecc_on())
        self._dump_page(data, 0, to_screen=True)

    def display_fw_locations(self):
        data = self.flash_read_page(0, self.ecc_on())
        bitfile_raw = int.from_bytes(data[0:4], 'big')
        scrubfile_raw = int.from_bytes(data[12:12 + 4], 'big')

        bitfile_page = bitfile_raw >> 8
        scrubfile_page = scrubfile_raw >> 8

        bitfile_block = bitfile_page // 64
        scrubfile_block = scrubfile_page // 64

        self.logger.info(f"bifile    on page 0x{bitfile_page:06X}, block 0x{bitfile_block:04X}\n"
                         f"scrubfile on page 0x{scrubfile_page:06X}, block 0x{scrubfile_block:04X}")

    def test_readback(self, block=0x300):
        """
        Test readback of page 0 in a block.
        :return: None
        """

        self.write_reg(Pa3Register.ECC_CMD, EccCmdOpcodes.ECC_CLEAR_DISABLE)

        address = block * ProAsic3Flash.PAGE_PER_BLOCK
        my_seed = random.randint(15485867, 654188383)  # for repeatability
        self.logger.info(f"random seed for flash random data:{my_seed}")
        random.seed(my_seed)
        # entropy of around ~~ 5.54345
        my_randoms = random.sample(list(range(0xff + 1)) * 17, 0x1000)

        assert len(my_randoms) == 0x1000

        self.flash_write_data(data=my_randoms, start_block=block)

        ret_data = self.flash_read_page(address)
        self.write_reg(Pa3Register.ECC_CMD, EccCmdOpcodes.ECC_CLEAR_ENABLE)

        for cnt, t in enumerate(zip(my_randoms, ret_data)):
            a, b = t
            if a != b:
                self.logger.error(f"mistmatch in data {cnt}")
                break
        else:
            self.logger.info("test successful")
            self.logger.info("flash readback test successful")
        self.logger.info(list(zip(my_randoms, ret_data))[0:10])

    def _speed_test(self):
        t0_n = time.monotonic()
        n = 20
        for i in range(n):
            _ = []
            _ = self.flash_read_page(0)
        t1_n = time.monotonic()
        ds = t1_n - t0_n
        bps = (n + 1) * 4096 / ds
        self.logger.info(f"done reading {n + 1} pages in {ds} seconds\n"
                         f" for a speedy total of {bps} bytes per second")

    def flash_write_file(self, filename, start_block, ECC=True):
        """Write a binary file to flash"""
        if ECC:
            page_size_actual = 0x1060
        else:
            page_size_actual = 0x1000
        with open(os.path.realpath(filename), 'rb') as infile:
            data = bytearray(infile.read())
        self.logger.info(
            "data length is {} with {} pages or {} blocks".format(len(data), len(data) / (page_size_actual),
                                                                  len(data) / (page_size_actual * 64)))

        self.flash_write_data(data, start_block, ECC)

    def generate_and_write_all_firmware(self, bitfile_name, bitfile_block, scrubfile_block):
        ok = self._write_warning()
        if not ok:
            return
        self.logger.info("starting generation and writing of bitfiles...")
        self.logger.info("Please be patient. this might take a while")
        s = Scrub()
        scrubfile_name = s.generate_scrubbing_file(bitfile_name)
        self.logger.info("generated blind scrubbing file " + scrubfile_name)
        # Make ECC bit-and blind-scrubbing -file
        bitfile_ecc = make_ecc_file(bitfile_name)  # first,
        scrubfile_ecc = make_ecc_file(scrubfile_name)

        self.write_all_firmware(ecc_bitfile=bitfile_ecc, ecc_scrubfile=scrubfile_ecc,
                                bitfile_block=bitfile_block, scrubfile_block=scrubfile_block,
                                skipwarn=ok, update_param=True)

        self.update_parameter_page(bitfile_block, scrubfile_block)
        self.logger.info("bitfiles and parameter written to flash...")

    def write_all_firmware(self, ecc_bitfile, ecc_scrubfile, bitfile_block, scrubfile_block, skipwarn=False,
                           update_param=False):
        if not skipwarn:
            ok = self._write_warning()
            if not ok:
                return
        self.flash_write_file(ecc_bitfile, bitfile_block)
        self.flash_write_file(ecc_scrubfile, scrubfile_block)
        if update_param:
            self.update_parameter_page(bitfile_block, scrubfile_block)

    def update_parameter_page(self, bitfile_block, scrubfile_block):
        timestr = time.strftime("%Y-%m-%d-%H_%M")
        parameters = make_parameter_file_and_ecc("paramfile_autogen" + timestr + ".bit", bitfile_block, scrubfile_block)
        self.flash_write_file(parameters, 0)

    def _write_warning(self):
        cc = input("warning. this will write files to the flash. continue? (c or n cancels)\n")
        if cc.lower() in ['c', 'n']:
            self.logger.info("writing cancelled")
            return False
        else:
            return True

    def find_bad_blocks(self) -> Dict[int, List[int]]:
        """scan both chips to get bad blocks"""
        bad_blocks = {}
        for ic, flash_device in zip([0b01, 0b10], [0, 1]):
            self.set_flash_select_ic(ic)
            data = self._find_bad_blocks()
            bad_blocks[flash_device] = data
        return bad_blocks

    def _find_bad_blocks(self) -> List[int]:
        """Bad block info is in page 0 or 1 of every block, located at byte no 0x1000"""
        self.set_flash_page_size(0x1001)
        self.disable_ecc()  # clears ecc errors, clears read buffer of size 256
        bad_blocks = []

        page_addresses = [page + offset for page
                          in range(0x40, 2 ** 13 * 0x40, 0x40)
                          for offset in [0, 1]
                          ]

        page_range = range(0, 0x1000 // 256)  # len = 16, max = 15 [0,16)
        self.disable_ecc()  # the first one of these will affect trx size
        self.set_flash_page_size(0x1001)  # trying to compensate for fw "effects"
        for page in tqdm(page_addresses):  # loop all blocks [0,0x1000) = [0,256*16)
            # write address. and read123
            self.disable_ecc()  # make sure that we are zeroed.
            self.set_flash_address(whole_address=page)
            self.write_reg(Pa3Register.FLASH_CTRL, FlashCmdOpcode.PAGE_READ | EXEC)  # read page cmd
            for index in page_range:  # loop single page, order is critical
                while self.read_reg(Pa3Register.FIFO_STATUS) & 0xf == 8:
                    pass
                self.disable_ecc()  # make sure that we are zeroed.
            # exit page loop to read final bytes
            data = self.read_reg(Pa3Register.FIFO_RX_DATA)  # get 1 byte, automatically skip ecc bytes
            if data != 0x00:
                block_address = page // 0x40
                bad_blocks.append(block_address)
        self.logger.info(f"bad blocks data: \n{[hex(x) for x in bad_blocks]}")
        return bad_blocks


def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return zip_longest(*args, fillvalue=fillvalue)


def get_words_from_list(xs, word_grouping=4, group_grouping=4, **kwargs) -> str:
    """
    Group string with words grouped in firstformat and groups grouped in second format with their respective separators and group sizes
    Ex. get_words_from_list([1,2,3,4,1,2,3,4], word_grouping=2, group_grouping=2, group_sep=" -- ", firstformat=lambda x:f"{x:X}") -> "0x12 0x34 -- 0x12 0x34 -- "

    :return: str

    :param xs: list of iterables

    :param int word_grouping: how many iterables in a word

    :param int group_grouping: how many words in a group (separated by group_sep)

    :param kwargs: firstformat (lambda x: f"{x:02X}"), secondformat (lambda x: "0x" + "".join(x)), word_sep (" "), group_sep (newline)

    """
    # config:
    firstformat = kwargs.get("firstformat", lambda x: f"{x:02X}", )
    secondformat = kwargs.get("secondformat", lambda x: "0x" + "".join(x))
    word_sep = kwargs.get("word_sep", " ")
    group_sep = kwargs.get("group_sep", "\n")

    # logic:
    first_format = map(firstformat, xs)
    joined_words = map(secondformat, grouper(first_format, word_grouping, fillvalue=""))
    joined_groups = map(lambda x: word_sep.join(x) + group_sep, grouper(joined_words, group_grouping, fillvalue=""))
    output_string = "".join(joined_groups)
    return output_string
