#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import sys
import errno
import time

import testbench

# instantiate a testbench object and initialize it
tb = testbench.Testbench()
tb.setup_standalone()
tb.rdo.comm.discardall_dp1(20)

# setup logging
logdir = os.path.join(os.getcwd(),'results')
try:
    os.makedirs(logdir)
except OSError as e:
    if e.errno != errno.EEXIST:
        raise

serial_nr = input("Enter RU serial number:")
logfile_name = "results_" + serial_nr + ".log"

log_file = os.path.join(logdir, logfile_name)

fh = logging.FileHandler(log_file)
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter(
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

fh.setFormatter(formatter)

# add this as a log handler for the testbench object
tb.logger.addHandler(fh)

# Now do the tests: log some basic stuff
tb.version()
tb.logger.info("GBTx0 register 374 = {}".format(hex(tb.rdo.i2c_gbtx.read_data(0, 374))))

# e.g. here is the MGT test:
wait_time = 10.0
tb.rdo.mgt_test.reset_all()
tb.logger.info("MGT status: {}".format(tb.rdo.mgt_test.read_status()))
tb.rdo.mgt_test.enable_errors()
tb.logger.info("MGT errors: {}".format(tb.rdo.mgt_test.read_prbs_err()))
tb.logger.info("read_prbs_locked: {}".format(hex(tb.rdo.mgt_test.read_prbs_locked())))
for i in range(28):
    tb.logger.info("PRBS counter {} = {}".format(i, tb.rdo.drp_ctrl.read_prbs_counter(i)))
tb.logger.info("wait {} seconds".format(wait_time))
time.sleep(wait_time)
for i in range(28):
    tb.logger.info("PRBS counter {} = {}".format(i, tb.rdo.drp_ctrl.read_prbs_counter(i)))
