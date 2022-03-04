#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import errno
import time
from progressbar import ProgressBar

import testbench

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

tb.logger.info("Start testGBT1")
tb.logger.info("Board serial number = {}".format(serial_nr))
tb.cru.set_gbtx_forward_to_usb(0)
tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.set_gbtx_forward_to_usb(0)
tb.cru.reset_gbt_fpga()
time.sleep(3.0)

wait_time = 200

# tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv2.xml", 0)
tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
time.sleep(1.0)
tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx1_Config.xml", 1)
time.sleep(1.0)

lock_status = tb.rdo.i2c_gbtx.read_data(0, 427)
if lock_status == 15:
    tb.logger.info("GBTx0 locked to CRU")
else:
    tb.logger.error("GBTx0 didn't lock to CRU. Lock status = {}".format(lock_status))
    exit(-1)


tb.cru.set_test_pattern(0)
time.sleep(1.0)
tb.cru.set_test_pattern(7)
time.sleep(1.0)

tb.cru.reset_error_flags()

if not tb.cru.is_gbt_rx_ready:
    tb.logger.error("GBTx not ready after setting up PRBS loopback test")
    exit(-1)

st_flags = tb.cru.get_status_flags()

error = 0
msg = ""
if st_flags['MGTLinkReady'] != 1:
    msg += "MGTLinkReady flag not set\n"
    error = 1

if st_flags['RxWordClockReady'] != 1:
    msg += "RxWordClockReady flag not set\n"
    error = 1

if st_flags['RxFrameClockReady'] != 1:
    msg += "RxFrameClockReady flag not set\n"
    error = 1

if st_flags['GbtRxReady'] != 1:
    msg += "GbtRxReady flag not set"
    error = 1

if (st_flags['GbtRxDataErrorseenFlag'] != 0) or (st_flags['GbtRxReadyLostFlag'] != 0):
    msg += "Data or link loss errors before starting test\n"
    error = 1

if error != 0:
    tb.logger.info("CRU status flags:")
    for fl, val in st_flags.items():
        tb.logger.info("{0:22} {1}".format(fl, val))
    tb.logger.error(msg)
    exit(0)

tb.logger.info("GBTx0 charge pump setting = {}".format(tb.rdo.i2c_gbtx.get_phase_detector_charge_pump(0)))

tb.cru.reset_counters()

fec_errors_beginning = tb.cru.get_fec_counter()
gbtx0_fec_errors_beginning = tb.rdo.i2c_gbtx.read_data(0, 435)
tb.logger.info("Number of RUv0 FEC Errors at beginning of testGBT1 = {}".format(fec_errors_beginning))
tb.logger.info("Number of GBTx0 FEC Errors at beginning of testGBT1 = {}".format(gbtx0_fec_errors_beginning))

tb.logger.info("wait {} seconds".format(wait_time))
try:
    pbar = ProgressBar()
    for _ in pbar(range(wait_time)):
        time.sleep(1.0)
    tb.logger.info("sleep done")
except KeyboardInterrupt:
    tb.logger.info("keyboard interrupt")
    comment_txt = input("Enter comment:")
    tb.logger.info(comment_txt)
    exit(0)

fec_errors = tb.cru.get_fec_counter()
gbtx0_fec_errors = tb.rdo.i2c_gbtx.read_data(0, 435)

if (fec_errors - fec_errors_beginning) == 0:
    tb.logger.info("Number of RUv0 FEC Errors {}, same as start of test".format(fec_errors))
else:
    tb.logger.info("Number of RUv0 FEC Errors {}, increased from {}".format(fec_errors, fec_errors_beginning))

if (gbtx0_fec_errors - gbtx0_fec_errors_beginning) == 0:
    tb.logger.info("Number of GBTx0 FEC Errors {}, same as start of test".format(gbtx0_fec_errors))
else:
    tb.logger.info("Number of GBTx0 FEC Errors {}, increased from {}".format(gbtx0_fec_errors, gbtx0_fec_errors_beginning))

# results from GBT test
errors = 0
st_flags = tb.cru.get_status_flags()
tb.logger.info("CRU status flags at end of test:")
for fl, val in st_flags.items():
    tb.logger.info("{0:22} {1}".format(fl, val))

if st_flags['MGTLinkReady'] != 1:
    tb.logger.error("MGTLinkReady not set")
    errors = 1

if st_flags['RxWordClockReady'] != 1:
    tb.logger.error("RxWordClockReady not set")
    errors = 1

if st_flags['RxFrameClockReady'] != 1:
    tb.logger.error("RxFrameClockReady not set")
    errors = 1

if st_flags['GbtRxReady'] != 1:
    tb.logger.error("GbtRxReady not set")
    errors = 1

if st_flags['GbtRxReadyLostFlag'] != 0:
    tb.logger.error("CRU-Rx not locked to GBT link")
    errors = 1

if (st_flags['GbtRxDataErrorseenFlag'] == 0) and (st_flags['GbtRxReadyLostFlag'] == 0):
    tb.logger.info("No data or link loss errors")
else:
    tb.logger.error("GBT1 error in PRBS loopback test")
    tb.logger.error("Number of Link Errors = {}".format(tb.cru.get_link_error_counter_dis()))
    tb.logger.error("Number of Data Errors = {}".format(tb.cru.get_data_error_counter()))

if errors == 0:
    tb.logger.info("GBT1 loopback test completed without errors")
else:
    tb.logger.error("GBT1 loopback test failed")

comment_txt = input("Enter comments:")
tb.logger.info(comment_txt)
