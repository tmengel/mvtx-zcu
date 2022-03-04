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
NR_RETRIES = 100

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

tb.logger.info("Start testAll")
tb.logger.info("Board serial number = {}".format(serial_nr))
tb.cru.set_gbtx_forward_to_usb(0)
tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.set_gbtx_forward_to_usb(0)
tb.cru.set_test_pattern(0)

# Now do the tests: log some basic stuff
tb.version()

dna = hex(tb.rdo.status.get_dna_value())
tb.logger.info("DNA = {}".format(dna))

#tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv2.xml", 0)
tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
#tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx2_Config_RUv2.xml", 2)
tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 2)

time.sleep(2.0)

# check if GBTx0 is accessable by reading the fixed pattern register
fixedpattern = tb.rdo.i2c_gbtx.read_data(0, 374)
tb.logger.info("Fixedpattern GBTx0(address=374)={}".format(hex(fixedpattern)))
if fixedpattern != 165:
    tb.logger.error("GBTx0 not accessible from I2C, fixedpattern (address 374) != 0xA5")
    exit(-1)

# check if GBTx1 is accessable by reading the fixed pattern register
fixedpattern = tb.rdo.i2c_gbtx.read_data(1, 374)
tb.logger.info("Fixedpattern GBTx1(address=374)={}".format(hex(fixedpattern)))
if fixedpattern != 165:
    tb.logger.error("GBTx1 not accessible from I2C, fixedpattern (address 374) != 0xA5")
    exit(-1)

# check if GBTx2 is accessable by reading the fixed pattern register
fixedpattern = tb.rdo.i2c_gbtx.read_data(2, 374)
tb.logger.info("Fixedpattern GBTx2(address=374)={}".format(hex(fixedpattern)))
if fixedpattern != 165:
    tb.logger.error("GBTx2 not accessible from I2C, fixedpattern (address 374) != 0xA5")
    exit(-1)

# Now also configure GBTx1
tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx1_Config.xml", 1)

# reset the CRU emulator
tb.cru.reset_gbt_fpga()
rx_ready = False
for _ in range(NR_RETRIES):
    rx_ready = tb.cru.is_gbt_rx_ready()
    if rx_ready:
        break;
    else:
        time.sleep(0.25)

if not rx_ready:
    # try to reload all config files again
    #tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv2.xml", 0)
    tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
    #tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx2_Config_RUv2.xml", 2)
    tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 2)
    time.sleep(1.0)
    tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx1_Config.xml", 1)
    time.sleep(1.0)
    _
# Now check the lock status register in GBTx0 and GBTx2
lock_status = tb.rdo.i2c_gbtx.read_data(0, 427)
if lock_status == 15:
    tb.logger.info("GBTx0 locked to CRU")
else:
    tb.logger.error("GBTx0 didn't lock to CRU. Lock status = {}".format(lock_status))
    exit(-1)

lock_status = tb.rdo.i2c_gbtx.read_data(2, 427)
if lock_status == 15:
    tb.logger.info("GBTx2 locked to CRU")
else:
    tb.logger.error("GBTx2 didn't lock to CRU. Lock status = {}".format(lock_status))
    exit(-1)

# Now read the GBTx serial numbers/TestFuse1-2
testFuse1 = tb.rdo.i2c_gbtx.read_data(0, 367)
testFuse2 = tb.rdo.i2c_gbtx.read_data(0, 368)
tb.logger.info("GBTx0(adres=367=testFuse1) = {}".format(hex(testFuse1)))
tb.logger.info("GBTx0(adres=368=testFuse2) = {}".format(hex(testFuse2)))

testFuse1 = tb.rdo.i2c_gbtx.read_data(1, 367)
testFuse2 = tb.rdo.i2c_gbtx.read_data(1, 368)
tb.logger.info("GBTx1(adres=367=testFuse1) = {}".format(hex(testFuse1)))
tb.logger.info("GBTx1(adres=368=testFuse2) = {}".format(hex(testFuse2)))

testFuse1 = tb.rdo.i2c_gbtx.read_data(2, 367)
testFuse2 = tb.rdo.i2c_gbtx.read_data(2, 368)
tb.logger.info("GBTx2(adres=367=testFuse1) = {}".format(hex(testFuse1)))
tb.logger.info("GBTx2(adres=368=testFuse2) = {}".format(hex(testFuse2)))

tb.cru.set_test_pattern(0)
time.sleep(1.0)
tb.cru.set_test_pattern(7)
time.sleep(1.0)

tb.cru.reset_error_flags()

if not tb.cru.is_gbt_rx_ready:
    tb.logger.error("GBTx not ready after setting up PRBS loopback test")
    exit(-1)

st_flags = tb.cru.get_status_flags()

if st_flags['GbtRxReadyLostFlag'] != 0:
    tb.logger.error("CRU-Rx not locked to GBT link")
    tb.logger.info("CRU status flags:")
    for fl, val in st_flags.items():
        tb.logger.info("{0:22} {1}".format(fl, val))
    exit(-1)

if st_flags['GbtRxDataErrorseenFlag'] != 0:
    tb.logger.error("CRU-Rx data error seen after flag reset")
    tb.logger.info("CRU status flags:")
    for fl, val in st_flags.items():
        tb.logger.info("{0:22} {1}".format(fl, val))
    exit(0)

tb.cru.reset_counters()

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

fec_errors_beginning = tb.cru.get_fec_counter()
gbtx0_fec_errors_beginning = tb.rdo.i2c_gbtx.read_data(0, 435)
gbtx2_fec_errors_beginning = tb.rdo.i2c_gbtx.read_data(2, 435)
tb.logger.info("Number of RUv0 FEC Errors at beginning of testAll = {}".format(fec_errors_beginning))
tb.logger.info("Number of GBTx0 FEC Errors at beginning of testAll = {}".format(gbtx0_fec_errors_beginning))
tb.logger.info("Number of GBTx2 FEC Errors at beginning of testAll = {}".format(gbtx2_fec_errors_beginning))

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
    elif result == 0 and i == 8:
        tb.logger.info("OK, {}, BUSY loopback".format(msg))
    else:
        tb.logger.error(msg)
        mgtErrors += 1

# results from GBT test
st_flags = tb.cru.get_status_flags()
tb.logger.info("CRU status flags:")
for fl, val in st_flags.items():
    tb.logger.info("{0:22} {1}".format(fl, val))

fec_errors = tb.cru.get_fec_counter()
gbtx0_fec_errors = tb.rdo.i2c_gbtx.read_data(0, 435)
gbtx2_fec_errors = tb.rdo.i2c_gbtx.read_data(2, 435)

if (fec_errors - fec_errors_beginning) == 0:
    tb.logger.info("Number of RUv0 FEC Errors {}, same as start of test".format(fec_errors))
else:
    tb.logger.info("Number of RUv0 FEC Errors {}, increased from {}".format(fec_errors, fec_errors_beginning))

if (gbtx0_fec_errors - gbtx0_fec_errors_beginning) == 0:
    tb.logger.info("Number of GBTx0 FEC Errors {}, same as start of test".format(gbtx0_fec_errors))
else:
    tb.logger.info("Number of GBTx0 FEC Errors {}, increased from {}".format(gbtx0_fec_errors, gbtx0_fec_errors_beginning))

if (gbtx2_fec_errors - gbtx2_fec_errors_beginning) == 0:
    tb.logger.info("Number of GBTx2 FEC Errors {}, same as start of test".format(gbtx2_fec_errors))
else:
    tb.logger.info("Number of GBTx2 FEC Errors {}, increased from {}".format(gbtx2_fec_errors, gbtx2_fec_errors_beginning))

if (st_flags['GbtRxDataErrorseenFlag'] == 0) and (st_flags['GbtRxReadyLostFlag'] == 0):
    tb.logger.info("No Data errors and link errors")
else:
    tb.logger.error("GBT error in PRBS loopback test")
    tb.logger.error("Number of Link Errors = {}".format(tb.cru.get_link_error_counter_dis()))
    tb.logger.error("Number of Data Errors = {}".format(tb.cru.get_data_error_counter()))

if nErrors == 0:
    tb.logger.info("Number of GPIO Errors = {}".format(nErrors))
else:
    tb.logger.error("Number of GPIO Errors = {}".format(nErrors))

if mgtErrors == 0:
    tb.logger.info("Number of faulty MGT channels = {}".format(mgtErrors))
else:
    tb.logger.error("Number of faulty MGT channels = {}".format(mgtErrors))

comment_txt = input("Enter comments:")
tb.logger.info(comment_txt)
