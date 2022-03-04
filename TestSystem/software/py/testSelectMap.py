#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import sys
import errno
import time

import testbench
from proasic3_enums import XIL_ADDR

# instantiate a testbench object and initialize it
tb = testbench.Testbench()
tb.setup_standalone()

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

tb.logger.info("Start testSelectMap")
tb.logger.info("Board serial number = {}".format(serial_nr))
tb.cru.set_gbtx_forward_to_usb(0)
tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.set_gbtx_forward_to_usb(0)

tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
time.sleep(0.5)
lock_status = tb.rdo.i2c_gbtx.read_data(0, 427)
if lock_status == 15:
    tb.logger.info("GBTx0 locked to CRU")
else:
    tb.logger.error("GBTx0 didn't lock to CRU. Lock status = {}".format(lock_status))
    exit(-1)

tb.cru.initialize()
tb.cru.sca.initialize()
tb.cru.pa3.initialize()

selMapIdCode = tb.cru.pa3._SelMap.get_idcode()
tb.logger.info("selectMap Id Code = {}".format(hex(selMapIdCode)))
if selMapIdCode != 0x13919093:
    tb.logger.error("Wrong ID code returned, expected 0x13919093 ERROR!!!!!!!!!! ERROR!!!!!")
LocalClkCnt = tb.rdo.status.get_freq_ctr()
if LocalClkCnt == 26214 or LocalClkCnt == 26215:
    tb.logger.info("Local Clock counter ok = {} ".format(LocalClkCnt))
else:
    tb.logger.error("Local Clock counter = {} expected =26214  ERROR!!!!!".format(LocalClkCnt))

time.sleep(0.5)
clockStatus, status_dict = tb.cru.pa3._Clock.get_clock_status()
if clockStatus == 2:
    tb.logger.info("Ok, Jitter Cleaner clockStatus = {}, Now press S4 ".format(clockStatus))
    while clockStatus == 2:
        clockStatus, _ = tb.cru.pa3._Clock.get_clock_status()
    if clockStatus == 7:
        tb.logger.info("Ok, Jitter Cleaner clockStatus = {}, Now release S4 ".format(clockStatus))
        while clockStatus == 7:
            clockStatus, _ = tb.cru.pa3._Clock.get_clock_status()
        if (clockStatus == 3) or (clockStatus == 1):
            tb.logger.info("Ok, Jitter Cleaner clockStatus = {}, wait 1 second to lock".format(clockStatus))
            time.sleep(1)
            clockStatus, _ = tb.cru.pa3._Clock.get_clock_status()
        if clockStatus == 2:
            tb.logger.info("Ok, Jitter Cleaner clockStatus = {}, Jitter Cleaner ok".format(clockStatus))
        else:
            tb.logger.error("Jitter Cleaner Clock status= {} expected = 2 ERROR!!!!!".format(clockStatus))
    else:
        tb.logger.error("Jitter Cleaner Clock status= {} expected = 7 ERROR!!!!!".format(clockStatus))
else:
    tb.logger.error("Jitter Cleaner Clock status= {} expected = 2 ERROR!!!!!".format(clockStatus))
