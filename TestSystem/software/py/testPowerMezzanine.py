#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import sys
import errno
import time
from progressbar import ProgressBar

import testbench

WAIT_TIME1 = 1.0
WAIT_TIME2 = 300

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

tb.logger.info("Start testGPIO")
tb.logger.info("Board serial number = {}".format(serial_nr))
tb.rdo.comm.discardall_dp1(20)

# Now do the tests: log some basic stuff
tb.version()

dna = hex(tb.rdo.status.get_dna_value())
tb.logger.info("DNA = {}".format(dna))

tb.logger.info("Disable DCLK")
tb.rdo.gpio_loopback_test.disableDCLK()

tb.logger.info("reset all prbs  receivers")
tb.rdo.gpio_loopback_test.resetAllGPIOprbs()

tb.logger.info("clear all prbs error counters")
tb.rdo.gpio_loopback_test.clearError(0x0fff)

tb.logger.info("inject errors")
tb.rdo.gpio_loopback_test.injectError(0xff)
tb.rdo.gpio_loopback_test.injectError(0xfe)
tb.rdo.gpio_loopback_test.injectError(0xfc)
tb.rdo.gpio_loopback_test.injectError(0xf8)
tb.rdo.gpio_loopback_test.injectError(0xf0)
tb.rdo.gpio_loopback_test.injectError(0xe0)
tb.rdo.gpio_loopback_test.injectError(0xc0)
tb.rdo.gpio_loopback_test.injectError(0x80)

tb.logger.info("wait {} seconds".format(WAIT_TIME1))
try:
    time.sleep(WAIT_TIME1)
    tb.logger.info("sleep done")
except KeyboardInterrupt as ki:
    tb.logger.info("keyboard interrupt")
    comment_txt = input("Enter comment:")
    tb.logger.info(comment_txt)
    exit(0)

nErrors = 0

for i in range(8):
    result = tb.rdo.gpio_loopback_test.get_pu_Error(i)
    msg = "PUerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

tb.logger.info("Enable DCLK")
tb.rdo.gpio_loopback_test.enableDCLK()

tb.logger.info("reset all prbs  receivers")
tb.rdo.gpio_loopback_test.resetAllGPIOprbs()

tb.logger.info("clear all prbs error counters")
tb.rdo.gpio_loopback_test.clearError(0x0fff)

tb.logger.info("inject errors")
tb.rdo.gpio_loopback_test.injectError(0xff)
tb.rdo.gpio_loopback_test.injectError(0xfe)
tb.rdo.gpio_loopback_test.injectError(0xfc)
tb.rdo.gpio_loopback_test.injectError(0xf8)
tb.rdo.gpio_loopback_test.injectError(0xf0)
tb.rdo.gpio_loopback_test.injectError(0xe0)
tb.rdo.gpio_loopback_test.injectError(0xc0)
tb.rdo.gpio_loopback_test.injectError(0x80)

tb.logger.info("wait {} seconds".format(WAIT_TIME2))
if nErrors==0:
    tb.logger.info("Number of GPIO Errors so far = {}".format(nErrors))
else:
    tb.logger.error("Number of GPIO Errors so far = {}".format(nErrors))

try:
    pbar = ProgressBar()
    for _ in pbar(range(WAIT_TIME2)):
        time.sleep(1.0)
    tb.logger.info("sleep done")
except KeyboardInterrupt as ki:
    tb.logger.info("keyboard interrupt")
    comment_txt = input("Enter comment:")
    tb.logger.info(comment_txt)
    exit(0)

for i in range(8):
    result = tb.rdo.gpio_loopback_test.get_pu_Error(i)
    msg = "PUerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

if nErrors==0:
    tb.logger.info("Number of GPIO Errors = {}".format(nErrors))
else:
    tb.logger.error("Number of GPIO Errors = {}".format(nErrors))

comment_txt = input("Enter comments:")
tb.logger.info(comment_txt)
