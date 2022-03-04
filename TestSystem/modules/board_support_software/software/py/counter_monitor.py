"""Implements the control for the counter_monitor wishbone slave"""
from enum import IntEnum
from wishbone_module import WishboneModule


class WsCounterMonitorAddress(IntEnum):
    LATCH_COUNTERS = 0x00
    RESET_COUNTERS = 0x01


class WsCounterMonitor(WishboneModule):
    """Parent class for counter monitor slaves that use the counter_monitor.vhd WB slave"""

    def __init__(self, moduleid, name, board_obj):
        super(WsCounterMonitor, self).__init__(moduleid=moduleid, name=name, board_obj=board_obj)
        self.LATCH_CMD = 0x0001
        self.RESET_ONE_CMD = 0xF000
        self.RESET_ALL_CMD = 0xFFFF

    def reset_counter(self, register, commitTransaction=True):
        """Resets counter specified in 'register'"""
        assert (register | 0xff) == 0xff
        data = register | self.RESET_ONE_CMD
        self.write(WsCounterMonitorAddress.RESET_COUNTERS, data, commitTransaction=commitTransaction)

    def reset_all_counters(self, commitTransaction=True):
        """Resets all counters"""
        self.write(WsCounterMonitorAddress.RESET_COUNTERS, self.RESET_ALL_CMD, commitTransaction=commitTransaction)

    def latch_all_counters(self, commitTransaction=True):
        """Latches values of all counters into WB register"""
        self.write(WsCounterMonitorAddress.LATCH_COUNTERS, self.LATCH_CMD, commitTransaction=commitTransaction)

    def _get_counters(self, registers, commitTransaction=True):
        """Gets the values of the counters in a counter monitor"""
        assert registers.LATCH_COUNTERS == WsCounterMonitorAddress.LATCH_COUNTERS
        assert registers.RESET_COUNTERS == WsCounterMonitorAddress.RESET_COUNTERS
        for address in registers:
            if (address != WsCounterMonitorAddress.RESET_COUNTERS) and (address != WsCounterMonitorAddress.LATCH_COUNTERS):
                self.read(address, commitTransaction=False)
        ret = []
        if commitTransaction:
            self.comm.flush()
            results = self.comm.read_results()
            assert len(results) == len(registers)-2
            for i, address in enumerate(list(registers)[2:]):
                assert ((results[i][0] >> 8) & 0x7f) == self.moduleid, \
                    "Requested to read module {0}, but got result for module {1}, iteration {2}".format(self.moduleid, ((results[i][0] >> 8) & 0x7f), i)
                assert (results[i][0] & 0xff) == address.value, \
                    "Requested to read address {0}, but got result for address {1}, iteration {2}".format(address.value, (results[i][0] & 0xff), i)
                ret.append(results[i][1])
        return ret
