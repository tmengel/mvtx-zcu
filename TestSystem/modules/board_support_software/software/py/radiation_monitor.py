"""Class to implement the latest capabilities of the SCAController"""

from wishbone_module import WishboneModule
from enum import IntEnum

import collections

class WsRadiationMonitorSizes(IntEnum):
    """Used for memory mapping"""
    MODULE_0_WIDTH = 11 #DCTRL
    MODULE_1_WIDTH = 5  #GBTX01
    MODULE_2_WIDTH = 5  #GBTX2
    MODULE_3_WIDTH = 7  #WBSMSTR
    MODULE_4_WIDTH = 4  #DP_FIFOS
    MODULE_5_WIDTH = 1  #SYSMON
    MODULE_6_WIDTH = 10  # DATAPATH
    MODULE_7_WIDTH = 7  # TRIGGER_HANDLER
    MODULE_DUMMY_WIDTH = 1  #DP_DUMMY
    MODULE_NUM = 8 # number of connected counters

class WsRadiationMonitorAddress(IntEnum):
    """memory mapping for radiation monitor module"""
    MODULE_0_FIRST       = 0x00
    MODULE_0_LAST        = MODULE_0_FIRST + WsRadiationMonitorSizes.MODULE_0_WIDTH -1
    MODULE_1_FIRST       = MODULE_0_LAST + 1
    MODULE_1_LAST        = MODULE_1_FIRST + WsRadiationMonitorSizes.MODULE_1_WIDTH -1
    MODULE_2_FIRST       = MODULE_1_LAST + 1
    MODULE_2_LAST        = MODULE_2_FIRST + WsRadiationMonitorSizes.MODULE_2_WIDTH -1
    MODULE_3_FIRST       = MODULE_2_LAST + 1
    MODULE_3_LAST        = MODULE_3_FIRST + WsRadiationMonitorSizes.MODULE_3_WIDTH -1
    MODULE_4_FIRST       = MODULE_3_LAST + 1
    MODULE_4_LAST        = MODULE_4_FIRST + WsRadiationMonitorSizes.MODULE_4_WIDTH -1
    MODULE_5_FIRST       = MODULE_4_LAST + 1
    MODULE_5_LAST        = MODULE_5_FIRST + WsRadiationMonitorSizes.MODULE_5_WIDTH -1
    MODULE_6_FIRST       = MODULE_5_LAST + 1
    MODULE_6_LAST        = MODULE_6_FIRST + WsRadiationMonitorSizes.MODULE_6_WIDTH -1
    MODULE_7_FIRST       = MODULE_6_LAST + 1
    MODULE_7_LAST        = MODULE_7_FIRST + WsRadiationMonitorSizes.MODULE_7_WIDTH -1
    MODULE_DUMMY_FIRST   = MODULE_7_LAST + 1
    MODULE_DUMMY_LAST    = MODULE_DUMMY_FIRST + WsRadiationMonitorSizes.MODULE_DUMMY_WIDTH -1
    NUM_REGS             = MODULE_DUMMY_LAST + 1

class WsRadiationMonitor(WishboneModule):
    """radiation monitor wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(WsRadiationMonitor, self).__init__(moduleid=moduleid, name="RadiationMonitor", board_obj=board_obj)
        self.verbose = False
        self.read_range_lut = {0: range(WsRadiationMonitorAddress.MODULE_0_FIRST, WsRadiationMonitorAddress.MODULE_0_LAST+1),
                               1: range(WsRadiationMonitorAddress.MODULE_1_FIRST, WsRadiationMonitorAddress.MODULE_1_LAST+1),
                               2: range(WsRadiationMonitorAddress.MODULE_2_FIRST, WsRadiationMonitorAddress.MODULE_2_LAST+1),
                               3: range(WsRadiationMonitorAddress.MODULE_3_FIRST, WsRadiationMonitorAddress.MODULE_3_LAST+1),
                               4: range(WsRadiationMonitorAddress.MODULE_4_FIRST, WsRadiationMonitorAddress.MODULE_4_LAST+1),
                               5: range(WsRadiationMonitorAddress.MODULE_5_FIRST, WsRadiationMonitorAddress.MODULE_5_LAST+1),
                               6: range(WsRadiationMonitorAddress.MODULE_6_FIRST, WsRadiationMonitorAddress.MODULE_6_LAST+1),
                               7: range(WsRadiationMonitorAddress.MODULE_7_FIRST, WsRadiationMonitorAddress.MODULE_7_LAST+1),
                               8: range(WsRadiationMonitorAddress.MODULE_DUMMY_FIRST, WsRadiationMonitorAddress.MODULE_DUMMY_LAST+1)
                               }

    def get_counters(self, module):
        """returns the counters for the given module as a dictionary of tuples,
        the key is the address of the registers"""
        assert module < WsRadiationMonitorSizes.MODULE_NUM
        read_range = self.read_range_lut[module]
        values = {}
        for address in read_range:
            #print("address {0:#04X}".format(address))
            value = self.read(address)
            values[address] = format_counter(value)
        return values

    def get_all(self):
        """returns the counters as a dictionary of tuples,
        the key is the address of the registers"""
        values = {}
        for address in range(WsRadiationMonitorAddress.NUM_REGS):
            #print("address {0:#04X}".format(address))
            value = self.read(address)
            values[address] = format_counter(value)
        return values

    def dump_config(self):
        config_str = "--- radiation monitor module ---\n"

        config_str += "  - Write phase register:\n"
        for address in WsRadiationMonitorAddress:
            if address.value < WsRadiationMonitorAddress.NUM_REGS:
                name = address.name
                value = self.read(address.value)
                config_str += "    - {0} : {1:#X}\n".format(name, value)
        return config_str

    def dump_register_mapping(self):
        for address in WsRadiationMonitorAddress:
            name = address.name
            value = address.value
            self.logger.info("Address of {0} register is {1}".format(name, value))

def format_counter(value):
    assert value <= 0xFFFF
    return (value & 0xFF, value>>8 & 0xFF)
