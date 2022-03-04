"""GBTx monitor module for readout of RXRDY lost counters"""

from enum import IntEnum
from counter_monitor import WsCounterMonitor, WsCounterMonitorAddress


class WsGbtxMonitorAddress(IntEnum):
    """Memory mapping for the gbtx_monitor"""

    LATCH_COUNTERS         = 0x00
    RESET_COUNTERS         = 0x01
    COUNTER_GBTX0_LOCKLOSS = 0x02
    COUNTER_GBTX2_LOCKLOSS = 0x03


class WsGbtxMonitor(WsCounterMonitor):
    """Wishbone slave for monitoring GBTx RXRDY lost events"""

    def __init__(self, moduleid, board_obj):
        super(WsGbtxMonitor, self).__init__(moduleid=moduleid, name="Gbtx Monitor", board_obj=board_obj)

    def read_counters(self):
        """Read all counters inside the GBTxMonitor wishbone slave"""
        self.latch_all_counters(commitTransaction=False)
        results = self._get_counters(WsGbtxMonitorAddress, commitTransaction=True)
        ret = {}
        ret['gbtx0_lockloss_counts'] = results[0]
        ret['gbtx2_lockloss_counts'] = results[1]
        return ret

    def dump_config(self):
        """Dump the modules state and configuration as a string"""
        config_str = "--- GBTx MONITOR module ---\n"
        for address in WsGbtxMonitorAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#06X}\n".format(name, value)
        return config_str
