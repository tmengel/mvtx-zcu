#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import errno
import time

import testbench

# instantiate a testbench object and initialize it
tb = testbench.Testbench()
tb.setup_standalone()

# setup logging
serial_nr = input("Enter RU serial number:")
logfile_name = "results_" + serial_nr[-4:] + ".log"
logdir = os.path.join(os.getcwd(), 'results')
try:
    os.makedirs(logdir)
except OSError as e:
    if e.errno != errno.EEXIST:
        raise
log_file = os.path.join(logdir, logfile_name)
fh = logging.FileHandler(log_file)
fh.setLevel(logging.DEBUG)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
fh.setFormatter(formatter)
# add this as a log handler for the testbench object
tb.logger.addHandler(fh)

tb.logger.info("Start testBUTTON")
tb.logger.info("Board serial number = {}".format(serial_nr))

tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.set_gbtx_forward_to_usb(0)

dipswitch = tb.rdo.status.get_dipswitch()
if (dipswitch==0x1):

    # initialize GBTx0
    tb.rdo.i2c_gbtx.gbtx_config("../../modules/gbt/software/GBTx_configs/GBTx0_Config_RUv1_1.xml", 0)
    time.sleep(0.5)
    lock_status = tb.rdo.i2c_gbtx.read_data(0, 427)
    if lock_status == 15:
        tb.logger.info("GBTx0 locked to CRU")
    else:
        tb.logger.error("GBTx0 didn't lock to CRU. Lock status = {}".format(lock_status))
        exit(-1)

    tb.cru.initialize()

    tb.logger.info("dipswitch = {}".format(hex(dipswitch)))
    while (dipswitch!=0x3FF):
        dipswitchNew=tb.rdo.status.get_dipswitch()
        while dipswitchNew == dipswitch:
            time.sleep(0.1)
            dipswitchNew=tb.rdo.status.get_dipswitch()
        dipswitchNew=tb.rdo.status.get_dipswitch()
        if dipswitchNew == ((dipswitch << 1) + 1):
            dipswitch=dipswitchNew
            tb.logger.info("dipswitch = {}".format(hex(dipswitch)))
        else:
            tb.logger.error("dipswitch = {} expected = {} ERROR!!!!!".format(hex(dipswitchNew), hex((dipswitch << 1) + 1)))
            break

    pushbuttonNext=0x01
    while (pushbuttonNext != 0x10):
        pushbutton=tb.rdo.status.get_pushbutton()
        if pushbutton == 0:
            tb.logger.info("Pushbutton = {}".format(hex(pushbutton)))
            while tb.rdo.status.get_pushbutton() == 0x0:
                time.sleep(0.1)
        else:
            tb.logger.error("pushbutton = {} expected =0  ERROR!!!!!".format(pushbutton))
            break
        pushbutton = tb.rdo.status.get_pushbutton()
        if pushbutton == pushbuttonNext:
            tb.logger.info("pushbutton = {}".format(pushbutton))
            while tb.rdo.status.get_pushbutton() == pushbuttonNext:
                time.sleep(0.1)
            pushbuttonNext <<=1
        else:
            tb.logger.error("pushbutton = {} expected ={} ERROR!!!!!".format(pushbutton, pushbuttonNext))
            break
    tb.logger.info("Start testing Jitter Cleaner")
    freqJitterCleaner = tb.rdo.status.get_freq_ctr()
    tb.logger.info("FreqJitterCleaner local clk= {}".format(freqJitterCleaner))
    if not(26240 < freqJitterCleaner < 26270):
        tb.logger.error("Wrong edge counter {}; expected value between 26240 or 26270. ERROR!!!!!".format(freqJitterCleaner))

else:
    tb.logger.info("testBUTTON must start with dipswitch set to 0x01, not {}".format(hex(dipswitch)))
