"""Continually run tests in a loop using the CANbus High Level Protocol.
Reads out githash value, counter values for the CAN HLP module, and tests write
and read using the CAN_TEST register found in the CAN HLP module's wishbone slave.
Test statistics are printed when the program is terminated (CTRL+C)"""

import can_hlp
import time
import random
import datetime

print("Starting CAN bus HLP loop test")

can = can_hlp.CanHlp('can0')
can_dev_ids = {0x01}
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

PRINT_INTERVAL = 10
start = time.time()
last_test_iteration = start

# Change this to reflect githash, it is not updated automatically from repo
githash_expect = 0x88EC51C


while True:
    try:
        for can_dev_id in can_dev_ids:
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

            if test_failed == True:
                failed_tests += 1

    except KeyboardInterrupt as ki:
        print("")
        print("Test stopped")
        print("Number of tests failed: {}/{}".format(failed_tests, total_tests))
        print("Number of failed test iterations: {}/{}".format(failed_tests, total_tests))
        print("Successful reads: {}/{}".format(read_success, read_attempts))
        print("Successful writes: {}/{}".format(write_success, write_attempts))
        print("Timeouts: {}".format(can_hlp_timeout_count))
        print("Wrong reponses: {}".format(can_hlp_wrong_reponse_count))
        print("Wrong IDs: {}".format(can_hlp_wrong_id_count))

        print("{0:0.2f} test iterations per second".format(total_tests/(time.time()-start)))
        print("{0:0.2f} attempted transactions per second".format((read_attempts+write_attempts)/(time.time()-start)))
        print("{0:0.2f} successful transactions per second".format((read_success+write_success)/(time.time()-start)))
        print("Average test iteration attempt time {0:e}s".format((time.time()-start)/(total_tests)))
        print("Average transaction attempt time {0:e}s".format((time.time()-start)/(read_attempts+write_attempts)))

        try:
            can_reg_rx_msg_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_RX_MSG_COUNT, timeout_ms)
            can_reg_tx_msg_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_TX_MSG_COUNT, timeout_ms)
            can_reg_read_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_READ_COUNT, timeout_ms)
            can_reg_write_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_WRITE_COUNT, timeout_ms)
            can_reg_status_alert_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_STATUS_ALERT_COUNT, timeout_ms)
            can_reg_unknown_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_UNKNOWN_COUNT, timeout_ms)

            print("")
            print("can_reg_rx_msg_count: {}".format(can_reg_rx_msg_count))
            print("can_reg_tx_msg_count: {}".format(can_reg_tx_msg_count))
            print("can_reg_read_count: {}".format(can_reg_read_count))
            print("can_reg_write_count: {}".format(can_reg_write_count))
            print("can_reg_status_alert_count: {}".format(can_reg_status_alert_count))
            print("can_reg_unknown_count: {}".format(can_reg_unknown_count))

        except Exception as ae:
            print("Got exception while reading count registers after test.")

        break

    except can_hlp.CanHlpTimeout as re:
        failed_tests += 1
        can_hlp_timeout_count += 1

    except can_hlp.CanHlpWrongReponse as re:
        failed_tests += 1
        can_hlp_wrong_reponse_count += 1

    except can_hlp.CanHlpWrongId as re:
        failed_tests += 1
        can_hlp_wrong_id_count += 1


    if(time.time() - last_test_iteration) > PRINT_INTERVAL:
        last_test_iteration = time.time()

        print("")
        print("Time: {}".format(datetime.datetime.now()))
        print("Number of failed test iterations: {}/{}".format(failed_tests, total_tests))
        print("Successful reads: {}/{}".format(read_success, read_attempts))
        print("Successful writes: {}/{}".format(write_success, write_attempts))
        print("Timeouts: {}".format(can_hlp_timeout_count))
        print("Wrong reponses: {}".format(can_hlp_wrong_reponse_count))
        print("Wrong IDs: {}".format(can_hlp_wrong_id_count))
