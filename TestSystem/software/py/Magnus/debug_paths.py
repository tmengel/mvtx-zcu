"""!@file flash_test.py
@brief make bad block database

@author = magnus.ersdal@uib.no

"""
from __future__ import print_function

import logging
from datetime import datetime
from logging.config import fileConfig

import dataset
from progressbar import ProgressBar
# import six
from six.moves import range, input  # 2 and 3 compat
import os
import sys

script_path = os.path.dirname(os.path.realpath(__file__))
extrapaths = ['modules/board_support_software/software/py/', 'software/py/']
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

if __name__ == '__main__':
    print("hello")
    tb = testbench.Testbench()
    tb.setup_standalone()
    print(tb)
    print(tb.cru.__dict__)
    print(hex(tb.cru.pa3.read_reg(1))) # works after setup_standalone.

    REGS=get_register_set_for_pa3(readf=tb.cru.pa3.read_reg, writef=tb.cru.pa3.write_reg)

    REGS.print_all_registers()

    tb.stop()
