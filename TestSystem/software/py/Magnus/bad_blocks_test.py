"""!@file flash_test.py
@brief The purpose of this class is to provide unittests for the flash interface

@author = magnus.ersdal@uib.no

"""
from __future__ import print_function

import logging
import unittest
from logging.config import fileConfig

from HWIO.PA3 import PA3
from HWIO.PA3_flash import FlashPa3
from flash_make_bad_block_db import MakeBadBlockDatabase
from read_pkg_file.read_WB_addresses import read_wb_adresses
from utils.read_cfg import get_cfg
from utils.setup_registers import get_register_set_for_pa3
from utils.formatters import format_page_data_to_nice_string
from utils.register_cls import SuperRegister


class TestFlash(unittest.TestCase):
    """!@test This is the main test of the flash interface

    """

    def setUp(self):
        dk = get_cfg()
        pkg_path, id_card, gbt_ch = (dk["pkg_path"], dk["id_card"], dk["gbt_ch"])
        fileConfig('logging_config.ini', disable_existing_loggers=False)
        self.logger = logging.getLogger("ecc_test")

        self.regs = get_register_set_for_pa3()
        self.pa3 = PA3(id_card, 2, gbt_ch, 'CRU')
        self.addresses = read_wb_adresses(pkg_path)  # get all wb addresses
        self.flash = FlashPa3(self.pa3, self.addresses, skipwait=False)
        self.logger.info("start test")

        self.regs.ECC_COMMAND.write(0x0)  # disable ECC
        self.flash_block_adr_reg = SuperRegister(
            [self.regs.FLASH_PAGE_ADDR,
             self.regs.FLASH_MINOR_BLOCK_ADDR,
             self.regs.FLASH_MAJOR_BLOCK_ADDR], data_size=8)

        self.trx_size_reg = SuperRegister(
            [self.regs.FLASH_MINOR_TRX_SIZE,
             self.regs.FLASH_MAJOR_TRX_SIZE], data_size=8)
        self.trx_size_reg.write(0x1001)

    def tearDown(self):
        self.logger.info("stop test")
        # self.trx_size_reg.write(0x1000)

    # @unittest.skip("skip")
    def test_badblock_functionality(self):
        page_adr = 0x500 * 0x40
        for jerk in [0x1000 - 257, 0x1000 - 256, 0x1000, 0x1001]:
            data = [0xff] * 0x1080
            data[jerk] = 0xaa
            self.regs.ECC_COMMAND.write(0x20)
            self.flash.flash_write_data(data, 0x500, ECC=False, override_page_size=0x1080)

            data_read = self.flash.flash_read_page(page_adr, override_page_size=0x1080)
            print("sizes w/r: {}/{}, set: {}/{}".format(len(data), len(data_read), set(data), set(data_read)))
            self.assertListEqual(data, list(data_read), msg="failed 0x1080 read/write")
            print("page:\n", format_page_data_to_nice_string(data_read[-400:]))
            self.trx_size_reg.write(0x1001)
            tool = MakeBadBlockDatabase()
            bad_blocks, dbg = tool.find_bad_blocks()
            print([hex(x) for x in bad_blocks])
            if 0x500 in bad_blocks:
                print("found the bastard! ")
                print("n is {}".format(hex(jerk)))

        self.assertIn(0x500, bad_blocks, msg="Failed to detect error in block 0x500")

    @unittest.skip("skip")
    def test_counter_of_style_bad_blocks(self):
        page_adr = 0x500 * 0x40
        self.flash_block_adr_reg.write(page_adr)
        countdata = list(range(0, 256)) * 1
        countdata = countdata + list(range(0, 128))
        print(len(countdata))
        cd = [0] * 0x1080
        cd[0x1000 - 256:0x1000] = [1] * 256
        cd[0x1000:0x1000 + 256] = range(256)
        print("CD:::")
        print(cd[-256 * 2:])
        self.flash.flash_write_data(cd, 0x500, ECC=False, override_page_size=0x1080)
        self.trx_size_reg.write(0x1001)
        self.regs.FLASH_CTRL.write(0x82)
        for i in range(0, 18):
            while self.regs.FIFO_STATUS.read() & 0xf == 8:  # wait for full
                pass
            self.regs.ECC_COMMAND.write(0x2)
        data_out = self.regs.FIFO_DATA_RD.read()
        print("read: {0} / 0x{0:x}".format(data_out))

    @unittest.skip("skip")
    def test_all_ends(self):
        self.regs.ECC_COMMAND.write(0x0)  # turn off ecc
        page_adr = 0x500 * 0x40
        self.flash_block_adr_reg.write(page_adr)
        data = [0xff] * 0x1080
        indices = list(range(256, 0x1080, 256))
        for cnt, i in enumerate(indices):
            data[i] = cnt + 1
            data[i - 2] = (cnt) << 4 | 0x0f
            data[i - 1] = (cnt + 1) << 4 | 0x0f
            data[i + 1] = (cnt + 1) | 0xf0
            data[i + 2] = (cnt) | 0xf0
        self.flash.flash_write_data(data, 0x500, ECC=False, override_page_size=0x1080)
        data_read = self.flash.flash_read_page(page_adr, override_page_size=0x1080)
        print([hex(x) for x in
               [data_read[256], data_read[256 * 2], data_read[256 * 3], data_read[256 * 4], data_read[256 * 5]]])
        self.regs.ECC_COMMAND.write(0x0)  # turn off ecc
        self.trx_size_reg.write(0x1001)
        j = 0
        dout = []
        for i in range(16):
            self.regs.FLASH_CTRL.write(0x82)  # start read
            # dump n:
            while True:  # write
                j += 1
                while self.regs.FIFO_STATUS.read() & 0b1 == 0:  # wait for full
                    pass
                self.regs.ECC_COMMAND.write(0x2)  # clear the 256 buffer

                if j > i:
                    break
            # new poller !
            while self.regs.FIFO_STATUS.read() & 0b10 == 0b10:  # wait for fifo not empty
                pass
            readbyte = self.regs.FIFO_DATA_RD.read()
            dout.append(dict(index=indices[i], data=hex(readbyte), skippedblocks=j))

        self.trx_size_reg.write(0x1000)  # reset value
        print("16 values, each should be an increment from the last.")
        print(dout)


if __name__ == '__main__':
    unittest.main()
