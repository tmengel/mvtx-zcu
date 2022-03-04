"""!@file flash_test.py
@brief make bad block database. Modified to function with CRU emulator hardware

@author = magnus.ersdal@uib.no
credits to ML, JS for making the testbench.py
"""
from __future__ import print_function

from itertools import chain
import logging
from datetime import datetime
from logging.config import fileConfig

# import dataset
from progressbar import ProgressBar
# import six
from six.moves import range, input  # 2 and 3 compat
import os
import sys

script_path = os.path.dirname(os.path.realpath(__file__))
extrapaths = ['../../../modules/board_support_software/software/py/', '../']
for p in extrapaths:
    modules_path = os.path.join(
        script_path, p)
    print("extending path with", modules_path)
    sys.path.append(modules_path)
from module_includes import *

from db_io.ru_board_db_io import ITSdb
from read_pkg_file.read_WB_addresses import read_wb_adresses
from utils.read_cfg import get_cfg
from utils.register_cls import SuperRegister
from utils.setup_registers import get_register_set_for_pa3
import testbench
import shutil

class MakeBadBlockDatabase():
    """!@test This is the main test of the flash interface

    """

    def __init__(self, readregf=print, writeregf=print):
        dk = get_cfg()
        pkg_path, id_card, gbt_ch = (dk["pkg_path"], dk["id_card"], dk["gbt_ch"])
        fileConfig('logging_config.ini', disable_existing_loggers=False)
        self.logger = logging.getLogger("flash_make_bad_block_db")

        self.regs = get_register_set_for_pa3(ignorepoll=False, readf=readregf, writef=writeregf)
        self.addresses = read_wb_adresses(pkg_path)  # get all wb addresses
        self.logger.info("start collection")
        # self.db = dataset.connect()  # ????1 is this nessecary ? creates "sqlite://"

    def tearDown(self):
        self.regs.ECC_COMMAND.write(0x3)
        self.regs.ECC_COMMAND.write(0x2)
        self.logger.info("stop collection")

    # @logonly((TimeoutError, timeout_decorator.TimeoutError))
    def find_bad_blocks(self):
        """Bad block info is in page 0 or 1 of every block, located at byte no 0x1000"""
        flash_block_adr_reg = SuperRegister(
            [self.regs.FLASH_PAGE_ADDR,
             self.regs.FLASH_MINOR_BLOCK_ADDR,
             self.regs.FLASH_MAJOR_BLOCK_ADDR], data_size=8)
        self.trx_size_reg = SuperRegister(
            [self.regs.FLASH_MINOR_TRX_SIZE,
             self.regs.FLASH_MAJOR_TRX_SIZE], data_size=8)
        self.trx_size_reg.write(0x1001)
        self.regs.ECC_COMMAND.write(0x2)  # Ecc, as 0x1000 is not in ecc blocks

        pbar = ProgressBar()
        debug_data = []

        page_addresses = []  # [0,1, 0x40, 0x41, etc]
        bad_blocks = []
        # range(0x400 * 0x40, 0x600 * 0x40,0x40): # for debug
        for page in range(0, 2 ** 13 * 0x40, 0x40):  # gives len 8192 start should be zero but hey.
            for i in [0, 1]:
                page_addresses.append(page + i)

        page_range = range(0, 0x1000 // 256)  # len = 16, max = 15 [0,16)
        self.regs.ECC_COMMAND.write(0x2)  # the first one of these will affect trx size
        self.trx_size_reg.write(0x1001)  # trying to compensate for fw "effects"
        for page in pbar(page_addresses):  # loop all blocks [0,0x1000) = [0,256*16)
            # write address. and read123
            self.regs.ECC_COMMAND.write(0x2)  # make sure that we are zeroed.
            flash_block_adr_reg.write(page)
            self.regs.FLASH_CTRL.write(0x82)  # read page command
            for index in page_range:  # loop single page, order is critical
                while self.regs.FIFO_STATUS.read() & 0xf == 8:  # wait for full
                    pass
                self.regs.ECC_COMMAND.write(0x2)  # make sure that we are zeroed.
            # exit page loop to read final bytes
            data = self.regs.FIFO_DATA_RD.read()  # get 1 byte, automatically skip ecc bytes
            if data != 0xff:
                print("read", data, "from page", hex(page))
                block_address = page // 0x40
                bad_blocks.append(block_address)

        return bad_blocks, debug_data

    @staticmethod
    def create_intervals(bad_blocks):
        """input bad blocks, get out valid interval indices"""
        MINRANGE = 97

        def not_sequencial(tp):
            a, b = tp
            return b - a != 1

        def good_range(tp):
            a, b = tp
            return abs(a - b) > MINRANGE

        allblocks_set = list(range(2 ** 13 + 1))  # set(range(start=0x40, stop=2 ** 13 + 1, step=0x40))
        filtered_blocks = [x for x in allblocks_set if x not in bad_blocks]

        win = zip(filtered_blocks, filtered_blocks[1:])  # sliding window of size 2
        indices = list(chain(*filter(not_sequencial, win)))

        # fix start and end of list
        if 2 ** 13 not in indices:
            for i in range(10):  # try 10
                if 2 ** 13 - i not in bad_blocks:
                    indices.append(2 ** 13 - i)
                    break
        if 1 not in indices:
            for i in range(10):
                if 1 + i not in bad_blocks:
                    indices = [1 + i] + indices
                    break
        # then filter for range > 100:
        assert len(indices) >= 2, f"error on {indices}"
        win2 = zip(indices, indices[1:])  # sliding window of size 2
        indices_in_range = list(filter(good_range, win2))

        # convert to page addresses !
        page_address_tuples = []
        for tp in indices_in_range:
            a, b = tp
            memory_range = (a * 0x40, b * 0x40 + 0x39)
            page_address_tuples.append(memory_range)
        return page_address_tuples



    def run_proceedure(self, dna):
        boardserialFull = input("Enter board serial number:")
        boardserial = boardserialFull[-4:]
        backupDB="ITS_WP10_RU_board_badblocks_"+boardserial+".db"
        print("first make copy of ITS_WP10_RU_board_badblocks.db to", backupDB)
        shutil.copy('ITS_WP10_RU_board_badblocks.db',backupDB)
        db = ITSdb(str(dna))
        #print(db.badblocks_table, db.hash_table)
        print("start time:", datetime.now())
        db.add_board_id(boardserial)
        for i, fd in zip([0b01, 0b10], [0, 1]):
            # read both flashes
            print("reading flash, part {} of 2".format(fd + 1))
            self.regs.FLASH_SELECT_IC.write(i)

            bad_blocks, debug_data = self.find_bad_blocks()
            if bad_blocks:
                print("found {} bad blocks".format(len(bad_blocks)))
                db.add_bad_blocks(bad_blocks, fd)
                intervals = self.create_intervals(bad_blocks)
                db.add_good_memory_areas(intervals, fd)
            else:
                print("found no bad blocks")
            print("done reading flash at:", datetime.now())
            # print([hex(x) for x in bad_blocks])

        print("stop time:", datetime.now())


if __name__ == '__main__':
    print("hello")
    tb = testbench.Testbench()
    try:
        # setup of communication from testbench.py:
        tb.setup_standalone()
        dna = tb.rdo.get_dna_value()
        # run my stuff
        dbtool = MakeBadBlockDatabase(readregf=tb.cru.pa3.read_reg, writeregf=tb.cru.pa3.write_reg)
        dbtool.run_proceedure(dna=dna)
        dbtool.tearDown()  # stop db tool first
    finally:
        tb.stop()  # finally stop tool
