"""Class to implement the latest capabilities of the wishbone_wait block relative to wait commands"""

from enum import IntEnum
from wishbone_module import WishboneModule

class WsWishboneWaitAddress(IntEnum):
    """memory mapping for wishbone_wait/ctrl module"""
    WAIT_VALUE                  = 0
    RST_CTRL_CNTRS              = 1
    READ_WAIT_EXEC_CNTR         = 2

class WishboneWait(WishboneModule):
    """wishbone_wait wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(WishboneWait, self).__init__(moduleid=moduleid, name="WISHBONE_WAIT", board_obj=board_obj)
        self.verbose = False

    def rst_ctrl_cntrs(self):
        """resets all the counters"""
        self.write(WsWishboneWaitAddress.RST_CTRL_CNTRS, 0x01, False)
        self.write(WsWishboneWaitAddress.RST_CTRL_CNTRS, 0, False)
        self.flush()

    def _read_counters(self):
        """gets the value of all the counters and returns them into a dictionary"""
        ret = {}
        ret['wait_exec'] = self.read(WsWishboneWaitAddress.READ_WAIT_EXEC_CNTR)
        self.logger.debug("Counters: %s", ret)
        return ret

    def get_counters(self):
        """latches and reads all the counters"""
        return self._read_counters()

    def _single_wait(self, waitvalue, commitTransaction=True):
        """set the wait time in number of WB_CLK_PERIOD.

        NOTE: if the wait is longer that 0xFFFF - 2(WB delay) the watchdog
        will assert a write error.
        NOTE: mininum waittime is 4 clock cycles @WB_CLK_PERIOD

        if commitTransaction is false, it only schedule it and
        transmit it at the next self.flush()
        """
        assert waitvalue|0xFFFF == 0xFFFF
        self.write(WsWishboneWaitAddress.WAIT_VALUE, waitvalue, commitTransaction)

    def wait(self, wait_value, commitTransaction=True):
        """Implements the wait function of the wait wishbone slave"""

        assert wait_value | 0xFFFFFFFF == 0xFFFFFFFF
        repeats = int(wait_value/0xFFF0)
        rest = wait_value%0xFFF0
        assert repeats*0xFFF0 + rest == wait_value
        for i in range(repeats):
            self._single_wait(0xFFF0,commitTransaction=False)
        self._single_wait(rest,commitTransaction=commitTransaction)

    def dump_config(self):
        config_str = "--- ALPIDE WISHBONE_WAIT module ---\n"

        config_str += "  - Write phase register:\n"
        for address in WsWishboneWaitAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#X}\n".format(name, value)
        return config_str
