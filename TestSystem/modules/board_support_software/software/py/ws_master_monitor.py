"""Implements the control for the ws_master_monitor wishbone slave"""

from enum import IntEnum
from wishbone_module import WishboneModule


class WsMasterMonitorAddress(IntEnum):
    """Memory mapping for the ws_master_monitor taken from ws_master_pkg.vhd"""
    READ_WBM_WRERRCNTR  = 0x00
    READ_WBM_RDERRCNTR  = 0x01
    READ_WBM_SEEERRCNTR = 0x02
    RESET_COUNTERS      = 0x03
    MISMATCH            = 0x04


class WsMasterMonitor(WishboneModule):
    """Wishbone slave instantiated inside the wishbone master handling the DP1, DP0 errors"""

    def __init__(self, moduleid, board_obj):
        """init"""
        super(WsMasterMonitor, self).__init__(moduleid=moduleid, name="Wishbone master monitor", board_obj=board_obj)

    def read_counters(self):
        """Reads all the values of the error counters in the wishbone master"""
        self.read(WsMasterMonitorAddress.READ_WBM_WRERRCNTR, commitTransaction=False)
        self.read(WsMasterMonitorAddress.READ_WBM_RDERRCNTR, commitTransaction=False)
        self.read(WsMasterMonitorAddress.READ_WBM_SEEERRCNTR, commitTransaction=False)
        results = self.read_all()
        ret = {}
        ret['write_error_counts'] = results[0]
        ret['read_error_counts']  = results[1]
        ret['see_error_counts']   = results[2]
        return ret

    def reset_counter(self, register, commitTransaction=True):
        """Resets counter specified in 'register'"""
        assert (register < 3)
        data = 1 << register
        self.write(WsMasterMonitorAddress.RESET_COUNTERS, data, commitTransaction=commitTransaction)

    def reset_all_counters(self, commitTransaction=True):
        """Resets all counters"""
        self.write(WsMasterMonitorAddress.RESET_COUNTERS, 0xff, commitTransaction=commitTransaction)

    def get_mismatch(self):
        """gets the actual mismatch status"""
        return self.read(WsMasterMonitorAddress.MISMATCH)

    def dump_config(self):
        """Dump the modules state and configuration as a string"""
        config_str = "--- MASTER MONITOR module ---\n"
        for address in WsMasterMonitorAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#06X}\n".format(name, value)
        return config_str
