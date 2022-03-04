"""file implementing the control for the mmcm_monitor wishbone slave"""

from enum import IntEnum
from wishbone_module import WishboneModule


class MmcmMonitorAddress(IntEnum):
    """memory mapping for the mmcm_monitor got from mmcm_monitor_pkg.vhd"""
    GET_LOCK_COUNTER        = 0
    MISMATCH_LSB            = 1
    MISMATCH_MSB            = 2
    MISMATCH_2ND_LSB        = 3
    MISMATCH_2ND_MSB        = 4
    MISMATCH_COUNTER        = 5
    MISMATCH_2ND_COUNTER    = 6
    LATCH_COUNTERS          = 7
    RESET_COUNTERS          = 8
    GET_COUNTER_CLK_0_FIRST = RESET_COUNTERS + 1
    GET_COUNTER_CLK_0_LAST  = GET_COUNTER_CLK_0_FIRST + 3
    GET_COUNTER_CLK_N_FIRST = GET_COUNTER_CLK_0_FIRST + 3*6
    GET_COUNTER_CLK_N_LAST  = GET_COUNTER_CLK_0_FIRST + 3*7 -1

class MmcmMonitor(WishboneModule):
    """wishbone slave instatiated inside the wishbone mmcm monitor handling the DP1, DP0 errors"""
    LOCK_COUNTER = 7

    def __init__(self, moduleid, board_obj, index):
        """init"""
        super(MmcmMonitor, self).__init__(moduleid=moduleid, name="Wishbone mmcm monitor {0}".format(index), board_obj=board_obj)
        self.index = index

    def _latch_counters(self, mask=None, commitTransaction=True):
        """Latches the counters
        A mask can be given to latch only part of the counters"""
        if mask is None:
            mask = 0xFF
        assert mask | 0xFF == 0xFF
        self.write(MmcmMonitorAddress.LATCH_COUNTERS, mask, commitTransaction=commitTransaction)
        self.write(MmcmMonitorAddress.LATCH_COUNTERS, 0, commitTransaction=commitTransaction)

    def _reset_counters(self, mask=None, commitTransaction=True):
        """Resetes the counters
        A mask can be given"""
        if mask is None:
            mask = 0xFF
        assert mask | 0xFF == 0xFF
        self.write(MmcmMonitorAddress.RESET_COUNTERS, mask, commitTransaction=commitTransaction)
        self.write(MmcmMonitorAddress.RESET_COUNTERS, 0, commitTransaction=commitTransaction)

    def _latch_lock_monitor_counter(self, commitTransaction):
        """Latches the lock monitor counter"""
        self._latch_counters(mask=1<<self.LOCK_COUNTER, commitTransaction=commitTransaction)

    def _reset_lock_monitor_counter(self, commitTransaction):
        """Resetes the lock monitor counter"""
        self._reset_counters(mask=1<<self.LOCK_COUNTER, commitTransaction=commitTransaction)

    def get_counters(self, verbose=True):
        """gets the values of the free running counters"""
        address_list = range(MmcmMonitorAddress.GET_COUNTER_CLK_0_FIRST, MmcmMonitorAddress.GET_COUNTER_CLK_N_LAST+1)
        self._latch_counters(0x7F, commitTransaction=False)
        self.firmware_wait(0x10, commitTransaction=False)
        for index, address in enumerate(address_list):
            self.read(address, commitTransaction=False)
        self.comm.flush()
        self.firmware_wait(0x80, commitTransaction=False)
        results = self.comm.read_results()
        counters = []
        assert len(results)==len(address_list)
        for address, data in results:
            counters.append(data)
            if verbose:
                self.logger.info("Counter with address {0} is {1}".format(address-self.index, data))
        return counters

    def get_lock_counter(self, verbose=False):
        """gets the values of the lock counter"""
        self._latch_lock_monitor_counter(commitTransaction=False)
        self.firmware_wait(0x10, commitTransaction=False)
        address = MmcmMonitorAddress.GET_LOCK_COUNTER
        self.read(address, commitTransaction=False)
        self.comm.flush()
        results = self.comm.read_results()
        counter = results[0][1]
        counters = []
        for i in range(3):
            counters.append(counter>>(5*i) & 0x1F)
            if verbose:
                self.logger.info("Lock counter with address {0} is {1}".format(i, counters[i]))
        return counters

    def get_mismatch(self, verbose=False):
        """gets the actual mismatch status"""
        self.read(MmcmMonitorAddress.MISMATCH_LSB, commitTransaction=False)
        self.read(MmcmMonitorAddress.MISMATCH_MSB, commitTransaction=False)
        self.read(MmcmMonitorAddress.MISMATCH_2ND_LSB, commitTransaction=False)
        self.read(MmcmMonitorAddress.MISMATCH_2ND_MSB, commitTransaction=False)
        self.comm.flush()
        results = self.comm.read_results()
        mismatch = results[1][1]<<16 | results[0][1]
        mismatch_2nd = results[3][1]<<16 | results[2][1]
        if verbose:
            self.logger.info("Mismatch {0}, mismatch_2nd {1}".format(mismatch,
                                                                     mismatch_2nd))
        return mismatch, mismatch_2nd

    def dump_config(self):
        """Dump the modules state and configuration as a string"""
        config_str = "--- MMCM MONITOR CONFIG module ---\n"
        config_str += "  - Write phase register:\n"
        self._latch_counters(commitTransaction=False)
        self.flush()
        for address in MmcmMonitorAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#06X}\n".format(name, value)
        return config_str
