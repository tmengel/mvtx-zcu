#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import sys
import errno
import time
import sqlite3
import shutil

script_path = os.path.dirname(os.path.realpath(__file__))
modules_path = os.path.join(
    script_path, '../../modules/board_support_software/software/py/')
sys.path.append(modules_path)

from bad_blocks_io import store_bad_blocks, add_dna_mapping
import testbench

# instantiate a testbench object and initialize it
tb = testbench.Testbench()
tb.setup_standalone()

tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)

# setup logging
logdir = os.path.join(os.getcwd(), 'results')
try:
    os.makedirs(logdir)
except OSError as e:
    if e.errno != errno.EEXIST:
        raise

boardserialFull = input("Enter RU board serial number:")
boardserial = boardserialFull[-4:]


script_path = os.path.dirname(os.path.realpath(__file__))
db_file = os.path.normpath(script_path + '/ITS_WP10_RU_board_badblocks.db')

if os.path.isfile(db_file):
    backupDB = "ITS_WP10_RU_board_badblocks_" + boardserial + ".db"
    print("first making a copy of ITS_WP10_RU_board_badblocks.db to", backupDB)
    shutil.copy('ITS_WP10_RU_board_badblocks.db', backupDB)

logfile_name = "results_" + boardserial + ".log"

log_file = os.path.join(logdir, logfile_name)

fh = logging.FileHandler(log_file)
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter(
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

fh.setFormatter(formatter)

# add this as a log handler for the testbench object
tb.logger.addHandler(fh)



tb.logger.info("Start Bad Block Readback")
tb.logger.info("Board serial number = {}".format(boardserial))

tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
time.sleep(1.0)
lock_status = tb.rdo.i2c_gbtx.read_data(0, 427)
if lock_status == 15:
    tb.logger.info("GBTx0 locked to CRU")
else:
    tb.logger.error("GBTx0 didn't lock to CRU. Lock status = {}".format(lock_status))
    exit(-1)

tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.initialize()
tb.cru.sca.initialize()
tb.cru.pa3.initialize()

startLOLcnt = tb.cru.pa3.read_reg(5)
tb.logger.info("startLOLcnt = {}".format(startLOLcnt))
startC1Bcnt = tb.cru.pa3.read_reg(6)
tb.logger.info("startC1Bcnt = {}".format(startC1Bcnt))
startC2Bcnt = tb.cru.pa3.read_reg(7)
tb.logger.info("startC2Bcnt = {}".format(startC2Bcnt))

dna = tb.rdo.get_dna_value()
db_connection = sqlite3.connect('ITS_WP10_RU_board_badblocks.db')
bad_blocks = tb.cru.pa3._FlashIf.find_bad_blocks()
stored_data = store_bad_blocks(dna, bad_blocks, db_connection)
add_dna_mapping(boardserial, dna, db_connection)
tb.logger.debug('Created table')
tb.logger.debug(stored_data)

stopLOLcnt = tb.cru.pa3.read_reg(5)
if startLOLcnt != stopLOLcnt:
    tb.logger.error("StopLOLcnt (%d) changed from startLOLcnt (%d)", stopLOLcnt, startLOLcnt)
else:
    tb.logger.info("Ok: StopLOLcnt (%d) equals startLOLcnt (%d)", stopLOLcnt, startLOLcnt)
stopC1Bcnt = tb.cru.pa3.read_reg(6)
if startC1Bcnt != stopC1Bcnt:
    tb.logger.error("StopC1Bcnt (%d) changed from startC1Bcnt (%d)", stopC1Bcnt, startC1Bcnt)
else:
    tb.logger.info("Ok: StopC1Bcnt (%d) equals startC1Bcnt (%d)", stopC1Bcnt, startC1Bcnt)
stopC2Bcnt = tb.cru.pa3.read_reg(7)
if startC2Bcnt != stopC2Bcnt:
    tb.logger.error("StopC2Bcnt (%d) changed from startC2Bcnt (%d)", stopC2Bcnt, startC2Bcnt)
else:
    tb.logger.info("Ok: StopC2Bcnt (%d) equals startC2Bcnt (%d)", stopC2Bcnt, startC2Bcnt)   
