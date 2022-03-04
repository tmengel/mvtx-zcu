#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import sys
import errno
import time
from progressbar import ProgressBar

import testbench

WAIT_TIME1 = 5.0
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

# prepare MGT test
mgtErrors = 0
tb.rdo.mgt_test.reset_all()
time.sleep(0.5)
tb.logger.info("MGT status: {}".format(tb.rdo.mgt_test.read_status()))
tb.rdo.mgt_test.enable_errors()
tb.logger.info("MGT errors: {}".format(tb.rdo.mgt_test.read_prbs_err()))
mgt_inputs_locked = tb.rdo.mgt_test.read_prbs_locked()
if mgt_inputs_locked == 0xFFFFFFF:
    tb.logger.info("read_prbs_locked: MGT locked {}".format(hex(mgt_inputs_locked)))
else:
    tb.logger.error("read_prbs_locked: MGT locked {}".format(hex(mgt_inputs_locked)))
    mgtErrors = 1
tb.rdo.mgt_test.force_error()

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

result = tb.rdo.gpio_loopback_test.get_SMAJ21J22Error()
msg = "smaError {}".format(result)
if result == 6:
    tb.logger.info("OK, {}".format(msg))
else:
    tb.logger.error(msg)
    nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_headerJ13_Error(i)
    msg = "headerJ13Error{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_Pa3headerJ14_Error(i)
    msg = "PA3headerJ14Error{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_pa3_Error(i)
    msg = "PA3Error{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_pa3_Error(i+5)
    msg = "PA3Error{0} {1}".format(i+5, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_DCTRL_Error(i)
    msg = "DCTRLerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_DCLKB_Error(i)
    msg = "DCLKBerror{0} {1}".format(i, result)
    if result == 0:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_DCLKC_Error(i)
    msg = "DCLKCerror{0} {1}".format(i, result)
    if result == 0:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(4):
    result = tb.rdo.gpio_loopback_test.get_aux_Error(i)
    msg = "AUXerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

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
if mgtErrors==0:
    tb.logger.info("Number of MGT errors so far = {}".format(mgtErrors))
else:
    tb.logger.error("Number of MGT Errors so far = {}".format(mgtErrors))

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

result = tb.rdo.gpio_loopback_test.get_SMAJ21J22Error()
msg = "smaError {}".format(result)
if result == 6:
    tb.logger.info("OK, {}".format(msg))
else:
    tb.logger.error(msg)
    nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_headerJ13_Error(i)
    msg = "headerJ13Error{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_Pa3headerJ14_Error(i)
    msg = "PA3headerJ14Error{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_pa3_Error(i)
    msg = "PA3Error{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_pa3_Error(i+5)
    msg = "PA3Error{0} {1}".format(i+5, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_DCTRL_Error(i)
    msg = "DCTRLerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_DCLKB_Error(i)
    msg = "DCLKBerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(5):
    result = tb.rdo.gpio_loopback_test.get_DCLKC_Error(i)
    msg = "DCLKCerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(4):
    result = tb.rdo.gpio_loopback_test.get_aux_Error(i)
    msg = "AUXerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

for i in range(8):
    result = tb.rdo.gpio_loopback_test.get_pu_Error(i)
    msg = "PUerror{0} {1}".format(i, result)
    if result == (i+1)*6:
        tb.logger.info("OK, {0}".format(msg))
    else:
        tb.logger.error(msg)
        nErrors += 1

if mgtErrors == 1:
    tb.logger.error("MGT lock error(s)")
mgtErrors = 0
for i in range(28):
    result = tb.rdo.drp_ctrl.read_prbs_counter(i)
    msg = "PRBS counter {} = {}".format(i, result)
    if result == 1:
        tb.logger.info("OK, {}".format(msg))
    elif result==0 and i==8:
        tb.logger.info("OK, {}, BUSY loopback".format(msg))
    else:
        tb.logger.error(msg)
        mgtErrors += 1

if nErrors==0:
    tb.logger.info("Number of GPIO Errors = {}".format(nErrors))
else:
    tb.logger.error("Number of GPIO Errors = {}".format(nErrors))

if mgtErrors==0:
    tb.logger.info("Number of faulty MGT channels = {}".format(mgtErrors))
else:
    tb.logger.error("Number of faulty MGT channels = {}".format(mgtErrors))

comment_txt = input("Enter comments:")
tb.logger.info(comment_txt)
