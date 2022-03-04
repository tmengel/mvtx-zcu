#!/usr/bin/env python3
"""Generic test routines"""

import logging
import os
import sys
import random
import errno
import time
from progressbar import ProgressBar

import testbench

script_path = os.path.dirname(os.path.realpath(__file__))
modules_path = os.path.join(
    script_path, '../../modules/dcs_canbus/software/can_hlp/')
sys.path.append(modules_path)

import can_hlp

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

tb.logger.info("Start testCAN")
tb.logger.info("Board serial number = {}".format(serial_nr))
tb.cru.set_gbtx_forward_to_usb(0)
tb.rdo.comm.discardall_dp1(20)
tb.cru.comm.discardall_dp1(20)
tb.cru.set_gbtx_forward_to_usb(0)

wait_time = 30.0

githash_expect = tb.rdo.status.get_git_hash()

can = can_hlp.CanHlp('can0')
can_dev_id = 0xff
timeout_ms = 100

read_attempts = 0
read_success = 0
write_attempts = 0
write_success = 0
total_tests = 0
failed_tests = 0
can_hlp_timeout_count = 0
can_hlp_wrong_id_count = 0
can_hlp_wrong_reponse_count = 0

start = time.time()
last_test_iteration = start


tb.logger.info("wait {} seconds".format(wait_time))

while (time.time() - last_test_iteration) < wait_time:
    try:
        test_failed = False

        total_tests += 1
        read_attempts += 1
        githash_lsb = can.readHLP(can_dev_id, can_hlp.UsRegisters.GITHASH_LSB, timeout_ms)

        read_attempts += 1
        githash_msb = can.readHLP(can_dev_id, can_hlp.UsRegisters.GITHASH_MSB, timeout_ms)

        githash_read = (githash_msb << 16) | githash_lsb

        if githash_read == githash_expect:
            read_success += 2
        else:
            test_failed = True

        rand_data = random.randint(0, 2**16-1)

        write_attempts += 1
        can.writeHLP(can_dev_id, can_hlp.UsRegisters.CAN_TEST, rand_data, timeout_ms)

        read_attempts += 1
        read_data = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_TEST, timeout_ms)

        if rand_data == read_data:
            read_success += 1
            write_success += 1
        else:
            test_failed = True

        if test_failed:
            failed_tests += 1

    except can_hlp.CanHlpTimeout as re:
        failed_tests += 1
        can_hlp_timeout_count += 1

    except can_hlp.CanHlpWrongReponse as re:
        failed_tests += 1
        can_hlp_wrong_reponse_count += 1

    except can_hlp.CanHlpWrongId as re:
        failed_tests += 1
        can_hlp_wrong_id_count += 1

    except KeyboardInterrupt as ki:
        tb.logger.info("keyboard interrupt")
        comment_txt = input("Enter comment for keyboard interrupt:")
        tb.logger.info(comment_txt)
        break

    except Exception as re:
        tb.logger.info("Unknown exception: {}".format(str(re)))
        raise

tests_failed = False
if failed_tests==0:
    tb.logger.info("Number of tests failed: {}/{}".format(failed_tests, total_tests))
else:
    tb.logger.error("Number of tests failed: {}/{}   ERROR!!!!!!!".format(failed_tests, total_tests))
    tests_failed = True
if read_success==read_attempts:
    tb.logger.info("Successful reads: {}/{}".format(read_success, read_attempts))
else:
    tb.logger.error("Successful reads: {}/{}     ERROR!!!!!!".format(read_success, read_attempts))
    test_failed = True
if write_success==write_attempts:
    tb.logger.info("Successful writes: {}/{}".format(write_success, write_attempts))
else:
    tb.logger.error("Successful writes: {}/{}     ERROR!!!!!".format(write_success, write_attempts))
    tests_failed = True
if can_hlp_timeout_count==0:
    tb.logger.info("Timeouts: {}".format(can_hlp_timeout_count))
else:
    tb.logger.error("Timeouts: {}     ERROR!!!!!!".format(can_hlp_timeout_count))
    tests_failed = True
if can_hlp_wrong_reponse_count==0:
    tb.logger.info("Wrong reponses: {}".format(can_hlp_wrong_reponse_count))
else:
    tb.logger.error("Wrong reponses: {}     ERROR!!!!!".format(can_hlp_wrong_reponse_count))
    test_failed = True
if can_hlp_wrong_id_count==0:
    tb.logger.info("Wrong IDs: {}".format(can_hlp_wrong_id_count))
else:
    tb.logger.error("Wrong IDs: {}     ERROR!!!!!".format(can_hlp_wrong_id_count))
    tests_failed = True

tb.logger.info("{0:0.2f} test iterations per second".format(total_tests/(time.time()-start)))
tb.logger.info("{0:0.2f} attempted transactions per second".format((read_attempts+write_attempts)/(time.time()-start)))
tb.logger.info("{0:0.2f} successful transactions per second".format((read_success+write_success)/(time.time()-start)))
tb.logger.info("Average test iteration attempt time {0:e}s".format((time.time()-start)/(total_tests)))
tb.logger.info("Average transaction attempt time {0:e}s".format((time.time()-start)/(read_attempts+write_attempts)))

try:
    can_reg_rx_msg_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_RX_MSG_COUNT, timeout_ms)
    can_reg_tx_msg_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_TX_MSG_COUNT, timeout_ms)
    can_reg_read_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_READ_COUNT, timeout_ms)
    can_reg_write_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_WRITE_COUNT, timeout_ms)
    can_reg_status_alert_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_STATUS_ALERT_COUNT, timeout_ms)
    can_reg_unknown_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_UNKNOWN_COUNT, timeout_ms)

    tb.logger.info("")
    tb.logger.info("can_reg_rx_msg_count: {}".format(can_reg_rx_msg_count))
    tb.logger.info("can_reg_tx_msg_count: {}".format(can_reg_tx_msg_count))
    tb.logger.info("can_reg_read_count: {}".format(can_reg_read_count))
    tb.logger.info("can_reg_write_count: {}".format(can_reg_write_count))
    tb.logger.info("can_reg_status_alert_count: {}".format(can_reg_status_alert_count))
    tb.logger.info("can_reg_unknown_count: {}".format(can_reg_unknown_count))

except Exception as ae:
    tb.logger.error("Got exception while reading count registers after test.")
    tests_failed = True

if tests_failed:
    tb.logger.error("At least one of the tests failed")
else:
    tb.logger.info("testCAN successful")

comment_txt = input("Enter comments:")
tb.logger.info(comment_txt)
