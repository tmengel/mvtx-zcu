#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import sys
import errno
import time
from itertools import starmap

import testbench
from proasic3_enums import Pa3Register
from gbt_sca import ScaChannel

# instantiate a testbench object and initialize it
tb = testbench.Testbench()
tb.setup_standalone()
tb.rdo.comm.discardall_dp1(20)

# setup logging
logdir = os.path.join(os.getcwd(), 'results')
try:
    os.makedirs(logdir)
except OSError as e:
    if e.errno != errno.EEXIST:
        raise

serial_nr = input("Enter RU serial number:")
logfile_name = "results_" + serial_nr[-4:] + ".log"

log_file = os.path.join(logdir, logfile_name)

fh = logging.FileHandler(log_file)
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter(
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

fh.setFormatter(formatter)

# add this as a log handler for the testbench object
tb.logger.addHandler(fh)

tb.logger.info("Start testPA3I2C")
tb.logger.info("Board serial number = {}".format(serial_nr))

tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.set_gbtx_forward_to_usb(0)
tb.cru.reset_gbt_fpga()
time.sleep(3.0)

tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv2.xml", 0)
time.sleep(1.0)
lock_status = tb.rdo.i2c_gbtx.read_data(0, 427)
if lock_status == 15:
    tb.logger.info("GBTx0 locked to CRU")
else:
    tb.logger.error("GBTx0 didn't lock to CRU. Lock status = {}".format(lock_status))
    exit(-1)

tb.cru.initialize
time.sleep(2)
tb.cru.sca.initialize
time.sleep(1)
tb.cru.pa3.initialize
time.sleep(1)

startLOLcnt = tb.cru.pa3.read_reg(5)
tb.logger.info("startLOLcnt = {}".format(startLOLcnt))
startC1Bcnt = tb.cru.pa3.read_reg(6)
tb.logger.info("startC1Bcnt = {}".format(startC1Bcnt))
startC2Bcnt = tb.cru.pa3.read_reg(7)
tb.logger.info("startC2Bcnt = {}".format(startC2Bcnt))

PRINT_INTERVAL = 1
start = time.time()
total_tests = 0
failed_tests_1 = 0
failed_tests_2 = 0
last_read = start
tb.logger.setLevel('CRITICAL')
cur_reg = 0
failed_regs_1 = []
failed_regs_2 = []
while total_tests < 500:
    total_tests += 1
    try:
        tb.cru.pa3.set_i2c_channel(ScaChannel.I2C0)
        for register in Pa3Register:
            cur_reg = register
            tb.cru.pa3.read_reg(address=register)

    except KeyboardInterrupt as ki:
        tb.logger.setLevel('INFO')
        tb.logger.info("Test stopped with %s", ki)
        tb.logger.info("{0:0.2f} reads per second".format(total_tests/(time.time()-start)))
        tb.logger.info("Average read time {0:e}s".format((time.time()-start)/(total_tests)))
        tb.logger.info("Number of tests failed on i2c0: %d/%d", failed_tests_1, total_tests)
        tb.logger.info("Number of tests failed on i2c5: %d/%d", failed_tests_2, total_tests)
        tb.logger.info('Failing regs i2c0:')
        tb.logger.info('\n'.join(starmap('{}: {}'.format, enumerate(failed_regs_1))))
        tb.logger.info('Failing regs i2c5:')
        tb.logger.info('\n'.join(starmap('{}: {}'.format, enumerate(failed_regs_2))))

        break
    except Exception as ae:
        tb.logger.info(ae)
        failed_tests_1 += 1
        failed_regs_1.append(cur_reg)

    try:
        tb.cru.pa3.set_i2c_channel(ScaChannel.I2C5)
        for register in Pa3Register:
            cur_reg = register
            tb.cru.pa3.read_reg(address=register)

    except KeyboardInterrupt as ki:
        tb.logger.setLevel('INFO')
        tb.logger.info("Test stopped with %s", ki)
        tb.logger.info("{0:0.2f} reads per second".format(total_tests/(time.time()-start)))
        tb.logger.info("Average read time {0:e}s".format((time.time()-start)/(total_tests)))
        tb.logger.info("Number of tests failed on i2c0: %d/%d", failed_tests_1, total_tests)
        tb.logger.info("Number of tests failed on i2c5: %d/%d", failed_tests_2, total_tests)
        tb.logger.info('Failing regs i2c0:')
        tb.logger.info('\n'.join(starmap('{}: {}'.format, enumerate(failed_regs_1))))
        tb.logger.info('Failing regs i2c5:')
        tb.logger.info('\n'.join(starmap('{}: {}'.format, enumerate(failed_regs_2))))

        break
    except Exception as ae:
        tb.logger.info(ae)
        failed_tests_2 += 1
        failed_regs_2.append(cur_reg)

    if(time.time() - last_read) > PRINT_INTERVAL:
        last_read = time.time()
        tb.logger.setLevel('INFO')
        tb.logger.info("Number of tests failed on i2c0: %d/%d", failed_tests_1, total_tests)
        tb.logger.info("Number of tests failed on i2c5: %d/%d", failed_tests_2, total_tests)
        tb.logger.setLevel('CRITICAL')

tb.logger.setLevel('INFO')
tb.logger.info("{0:0.2f} reads per second".format(total_tests/(time.time()-start)))
tb.logger.info("Average read time {0:e}s".format((time.time()-start)/(total_tests)))
if failed_tests_1 != 0:
    tb.logger.error("Number of tests failed on i2c0: %d/%d", failed_tests_1, total_tests)
    tb.logger.error('Failing regs i2c0:')
    tb.logger.error('\n'.join(starmap('{}: {}'.format, enumerate(failed_regs_1))))
if failed_tests_2 != 0:
    tb.logger.error("Number of tests failed on i2c5: %d/%d", failed_tests_2, total_tests)
    tb.logger.error('Failing regs i2c5:')
    tb.logger.error('\n'.join(starmap('{}: {}'.format, enumerate(failed_regs_2))))

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
