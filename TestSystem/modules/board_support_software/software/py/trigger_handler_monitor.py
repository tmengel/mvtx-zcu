"""Class to implement the trigger handler wishbone slave abstraction layer"""

from wishbone_module import WishboneModule
from enum import IntEnum, IntFlag

class WsTriggerHandlerMonitorAddress(IntEnum):
    """memory mapping for trigger handler module"""
    CNTR_RST                        = 0x00
    CNTR_LATCH                      = 0x01
    CNTR_TRIGGER_SENT_LSB           = 0x02
    CNTR_TRIGGER_SENT_MSB           = 0x03
    CNTR_TRIGGER_NOT_SENT           = 0x04
    CNTR_TRG_FIFO_GTH_FULL          = 0x05
    CNTR_TRG_FIFO_GTH_OVFL          = 0x06
    CNTR_TRG_FIFO_GPIO_FULL         = 0x07
    CNTR_TRG_FIFO_GPIO_OVFL         = 0x08
    CNTR_RX_FIFO_DATA_AVAILABLE_LSB = 0x09
    CNTR_RX_FIFO_DATA_AVAILABLE_MSB = 0x0A
    CNTR_TRIGGER_GATED_LSB          = 0x0B
    CNTR_TRIGGER_GATED_MSB          = 0x0C

class CountersBitMapping(IntFlag):
    """bit mapping of the reset/latch counter registers"""
    TRIGGER_SENT           = 0
    TRIGGER_NOT_SENT       = 1
    TRG_FIFO_GTH_FULL      = 2
    TRG_FIFO_GTH_OVFL      = 3
    TRG_FIFO_GPIO_FULL     = 4
    TRG_FIFO_GPIO_OVFL     = 5
    RX_FIFO_DATA_AVAILABLE = 6
    TRIGGER_GATED          = 7

class TriggerHandlerMonitor(WishboneModule):
    """trigger handler wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(TriggerHandlerMonitor, self).__init__(moduleid=moduleid, name="TRIGGER HANDLER MONITOR", board_obj=board_obj)

    def _set_counters_latch(self, value, commitTransaction=True):
        assert value  | (1<<len(CountersBitMapping)) -1 == (1<<len(CountersBitMapping)) -1
        self.write(WsTriggerHandlerMonitorAddress.CNTR_LATCH, value, commitTransaction=commitTransaction)

    def latch_counters(self, commitTransaction=True):
        """Latches all the counters"""
        self._set_counters_latch((1<<len(CountersBitMapping)) -1, commitTransaction=False)
        self._set_counters_latch(0, commitTransaction=commitTransaction)

    def _set_counters_reset(self, value, commitTransaction=True):
        assert value  | (1<<len(CountersBitMapping)) -1 == (1<<len(CountersBitMapping)) -1
        self.write(WsTriggerHandlerMonitorAddress.CNTR_RST, value, commitTransaction=commitTransaction)

    def reset_counters(self, commitTransaction=True):
        """Resets all the counters"""
        self._set_counters_reset((1<<len(CountersBitMapping)) -1, commitTransaction=False)
        self._set_counters_reset(0, commitTransaction=commitTransaction)

    def get_counters(self, reset_after=False, commitTransaction=True):
        """Reads all counters and returns dictionary"""
        self.latch_counters(commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRIGGER_SENT_MSB, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRIGGER_SENT_LSB, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRIGGER_NOT_SENT, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRG_FIFO_GTH_FULL, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRG_FIFO_GTH_OVFL, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRG_FIFO_GPIO_FULL, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRG_FIFO_GPIO_OVFL, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_RX_FIFO_DATA_AVAILABLE_MSB, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_RX_FIFO_DATA_AVAILABLE_LSB, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRIGGER_GATED_MSB, commitTransaction=False)
        self.read(WsTriggerHandlerMonitorAddress.CNTR_TRIGGER_GATED_LSB, commitTransaction=False)
        if reset_after:
            self.reset_counters(commitTransaction=False)
        if commitTransaction:
            self.comm.flush()
            results = self.comm.read_results()
            assert len(results) == 11
            ret_dict = {}
            ret_dict['trigger_sent']                = results[0][1]<<16 | results[1][1]
            ret_dict['trigger_not_sent']            = results[2][1]
            ret_dict['trigger_fifo_gth_full']       = results[3][1]
            ret_dict['trigger_fifo_gth_overflow']   = results[4][1]
            ret_dict['trigger_fifo_gpio_full']      = results[5][1]
            ret_dict['trigger_fifo_gpio_overflow']  = results[6][1]
            ret_dict['rx_fifo_data_available']      = results[7][1]<<16 | results[8][1]
            ret_dict['trigger_gated']               = results[9][1]<<16 | results[10][1]
            return ret_dict

    def dump_config(self):
        config_str = "--- TRIGGER HANDLER MONITOR module ---\n"
        for address in WsTriggerHandlerMonitorAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#X}\n".format(name, value)
        return config_str
