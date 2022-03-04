"""Run a simple test using the CANbus High Level Protocol.
Reads out githash value, counter values for the CAN HLP module, and tests write
and read using the CAN_TEST register found in the CAN HLP module's wishbone slave"""

import can_hlp

print("Starting CAN bus HLP test")

try:
    can = can_hlp.CanHlp('can0')
    can_dev_id = 0x01
    timeout_ms = 100
    githash_lsb = can.readHLP(can_dev_id, can_hlp.UsRegisters.GITHASH_LSB, timeout_ms)
    githash_msb = can.readHLP(can_dev_id, can_hlp.UsRegisters.GITHASH_MSB, timeout_ms)

    if githash_lsb is None:
        print('readHLP() for githash_lsb did not return anything')
    elif githash_msb is None:
        print('readHLP() for githash_msb did not return anything')
    else:
        githash = (githash_msb << 16) | githash_lsb

        print("githash: {:04X}".format(githash))


    # Write a test value to TEST register in CAN module
    can.writeHLP(can_dev_id, can_hlp.UsRegisters.CAN_TEST, 12345, timeout_ms)

    can_reg_rx_msg_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_RX_MSG_COUNT, timeout_ms)
    can_reg_tx_msg_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_TX_MSG_COUNT, timeout_ms)
    can_reg_read_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_READ_COUNT, timeout_ms)
    can_reg_write_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_WRITE_COUNT, timeout_ms)
    can_reg_status_alert_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_STATUS_ALERT_COUNT, timeout_ms)
    can_reg_unknown_count = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_UNKNOWN_COUNT, timeout_ms)
    can_reg_test = can.readHLP(can_dev_id, can_hlp.UsRegisters.CAN_TEST, timeout_ms)

    print("can_reg_rx_msg_count: {}".format(can_reg_rx_msg_count))
    print("can_reg_tx_msg_count: {}".format(can_reg_tx_msg_count))
    print("can_reg_read_count: {}".format(can_reg_read_count))
    print("can_reg_write_count: {}".format(can_reg_write_count))
    print("can_reg_status_alert_count: {}".format(can_reg_status_alert_count))
    print("can_reg_unknown_count: {}".format(can_reg_unknown_count))
    print("can_reg_test: {}".format(can_reg_test))


    date_lsb = can.readHLP(can_dev_id, can_hlp.UsRegisters.DATE_LSB, timeout_ms)
    date_csb = can.readHLP(can_dev_id, can_hlp.UsRegisters.DATE_CSB, timeout_ms)
    date_msb = can.readHLP(can_dev_id, can_hlp.UsRegisters.DATE_MSB, timeout_ms)
    year = date_msb >> 8 & 0xFF
    month = date_msb & 0xFF
    day = date_csb >> 8 & 0xFF
    hh = date_csb & 0xFF
    mm = date_lsb >> 8 & 0xFF
    ss = date_lsb & 0xFF
    date = "20{0:02x}/{1:02x}/{2:02x} {3:02x}:{4:02x}:{5:02x}".format(year,
                                                                      month,
                                                                      day,
                                                                      hh,
                                                                      mm,
                                                                      ss)
    print("XCKU firmware git commit date: {}".format(date))

except KeyboardInterrupt:
    print("C-C caught")
finally:
    print("exiting SAFELY")
