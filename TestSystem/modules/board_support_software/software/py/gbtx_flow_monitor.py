"""Class to implement the latest capabilities of the GbtxFlowMonitor"""

from wishbone_module import WishboneModule
from enum import IntEnum

class WsGbtxFlowMonitorAddress(IntEnum):
    """memory mapping for sca controller module"""
    LATCH_COUNTERS                     = 0x00
    RESET_COUNTERS                     = 0x01
    READ_COUNTER_SWT_DOWNLINK_LSB      = 0x02
    READ_COUNTER_TRG_DOWNLINK_LSB      = 0x03
    READ_COUNTER_SWT_UPLINK_LSB        = 0x04
    READ_COUNTER_SOP_UPLINK_LSB        = 0x05
    READ_COUNTER_EOP_UPLINK_LSB        = 0x06
    READ_COUNTER_OVERFLOW_DOWNLINK_LSB = 0x07
    READ_COUNTER_OVERFLOW_UPLINK_LSB   = 0x08
    READ_COUNTER_SWT_DOWNLINK_MSB      = 0x09
    READ_COUNTER_TRG_DOWNLINK_MSB      = 0x0A
    READ_COUNTER_SWT_UPLINK_MSB        = 0x0B
    READ_COUNTER_SOP_UPLINK_MSB        = 0x0C
    READ_COUNTER_EOP_UPLINK_MSB        = 0x0D
    READ_COUNTER_OVERFLOW_DOWNLINK_MSB = 0x0E
    READ_COUNTER_OVERFLOW_UPLINK_MSB   = 0x0F

class WsGbtxFlowMonitorAddress_bit(IntEnum):
    """Bit mapping of the {RESET|LATCH}_COUNTERS registers"""
    SWT_DOWNLINK      = 0
    TRG_DOWNLINK      = 1
    SWT_UPLINK        = 2
    SOP_UPLINK        = 3
    EOP_UPLINK        = 4
    OVERFLOW_DOWNLINK = 5
    OVERFLOW_UPLINK   = 6
    NUM_COUNTERS      = 7

class GbtxFlowMonitor(WishboneModule):
    """GBTx flow monitor wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(GbtxFlowMonitor, self).__init__(moduleid=moduleid, name="GbtxFlowMonitor", board_obj=board_obj)
        self.verbose = False

    def reset_counters(self, mask=2**WsGbtxFlowMonitorAddress_bit.NUM_COUNTERS-1, commitTransaction=True):
        """Resets the counters
        A bit mask can be eventually provided: if the n-th bit is one the corresponding counter is reset.
        Default it all reset"""
        assert mask < 2**WsGbtxFlowMonitorAddress_bit.NUM_COUNTERS
        self.write(WsGbtxFlowMonitorAddress.RESET_COUNTERS, mask, commitTransaction=False)
        self.write(WsGbtxFlowMonitorAddress.RESET_COUNTERS, 0, commitTransaction=commitTransaction)

    def latch_counters(self, mask=(2**WsGbtxFlowMonitorAddress_bit.NUM_COUNTERS) -1, commitTransaction=True):
        """Latches the counters
        A bit mask can be eventually provided: if the n-th bit is one the corresponding counter is latched.
        Default it all reset"""
        assert mask < 2**WsGbtxFlowMonitorAddress_bit.NUM_COUNTERS
        self.write(WsGbtxFlowMonitorAddress.LATCH_COUNTERS, mask, commitTransaction=False)
        self.write(WsGbtxFlowMonitorAddress.LATCH_COUNTERS, 0, commitTransaction=commitTransaction)

    def _get_counters(self, commitTransaction=True):
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_SWT_DOWNLINK_LSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_TRG_DOWNLINK_LSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_SWT_UPLINK_LSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_SOP_UPLINK_LSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_EOP_UPLINK_LSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_OVERFLOW_DOWNLINK_LSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_OVERFLOW_UPLINK_LSB,commitTransaction=False)

        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_SWT_DOWNLINK_MSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_TRG_DOWNLINK_MSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_SWT_UPLINK_MSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_SOP_UPLINK_MSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_EOP_UPLINK_MSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_OVERFLOW_DOWNLINK_MSB,commitTransaction=False)
        self.read(WsGbtxFlowMonitorAddress.READ_COUNTER_OVERFLOW_UPLINK_MSB,commitTransaction=False)
        if commitTransaction:
            self.comm.flush()
            results = self.comm.read_results()
            assert len(results)==14
            ret = {}
            ret['swt_downlink']      = results[7][1]<<16  | results[0][1]
            ret['trg_downlink']      = results[8][1]<<16  | results[1][1]
            ret['swt_uplink']        = results[9][1]<<16  | results[2][1]
            ret['sop_uplink']        = results[10][1]<<16 | results[3][1]
            ret['eop_uplink']        = results[11][1]<<16 | results[4][1]
            ret['overflow_downlink'] = results[12][1]<<16 | results[5][1]
            ret['overflow_uplink']   = results[13][1]<<16 | results[6][1]
        return ret

    def read_counters(self):
        """Reads all counters: returns a list.
        The list is ordered as in WsGbtxflowmonitoraddress_bit"""
        self.latch_counters(commitTransaction=False)
        self.firmware_wait(100,commitTransaction=False)
        return self._get_counters()

    def dump_config(self):
        config_str = "--- GBTx flow monitor module ---\n"
        config_str += "\n"
        for address in WsGbtxFlowMonitorAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#X}\n".format(name, value)
        return config_str
