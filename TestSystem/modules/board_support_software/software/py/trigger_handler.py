"""Class to implement the trigger handler wishbone slave abstraction layer"""

from wishbone_module import WishboneModule
from enum import IntEnum, IntFlag

class WsTriggerHandlerAddress(IntEnum):
    """memory mapping for trigger handler module"""
    ENABLE                          = 0x00
    TRIGGER_PERIOD                  = 0x01
    PULSE_nTRIGGER                  = 0x02
    TRIGGER_MIN_DISTANCE            = 0x03
    MODE                            = 0x04
    OPCODE_GATING                   = 0x05
    MISMATCH_WB                     = 0x06
    ENABLE_GPIO_PACKER              = 0x07
    ENABLE_GTH_PACKER               = 0x08


class Pulse_nTrigger(IntEnum):
    """Pulse or trigger selection"""
    Trigger = 0x00
    Pulse   = 0x01

class TriggerHandler(WishboneModule):
    """trigger handler wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(TriggerHandler, self).__init__(moduleid=moduleid, name="TRIGGER HANDLER", board_obj=board_obj)

    def enable(self, commitTransaction=True):
        self.write(WsTriggerHandlerAddress.ENABLE, 1, commitTransaction=commitTransaction)

    def disable(self, commitTransaction=True):
        self.write(WsTriggerHandlerAddress.ENABLE, 0, commitTransaction=commitTransaction)

    def is_enable(self, commitTransaction=True):
        return self.read(WsTriggerHandlerAddress.ENABLE, commitTransaction=commitTransaction)

    def disable_gpio_packer(self, commitTransaction=True):
        self.write(WsTriggerHandlerAddress.ENABLE_GPIO_PACKER, 0, commitTransaction=commitTransaction)

    def enable_gpio_packer(self, commitTransaction=True):
        self.write(WsTriggerHandlerAddress.ENABLE_GPIO_PACKER, 1, commitTransaction=commitTransaction)

    def gpio_packer_is_enabled(self, commitTransaction=True):
        return self.read(WsTriggerHandlerAddress.ENABLE_GPIO_PACKER, commitTransaction=commitTransaction)

    def disable_gth_packer(self, commitTransaction=True):
        self.write(WsTriggerHandlerAddress.ENABLE_GTH_PACKER, 0, commitTransaction=commitTransaction)

    def enable_gth_packer(self, commitTransaction=True):
        self.write(WsTriggerHandlerAddress.ENABLE_GTH_PACKER, 1, commitTransaction=commitTransaction)

    def gth_packer_is_enabled(self, commitTransaction=True):
        return self.read(WsTriggerHandlerAddress.ENABLE_GTH_PACKER, commitTransaction=commitTransaction)

    def set_trigger_period(self, value, commitTransaction=True):
        """Sets the continuous mode trigger period in units of 6.25ns"""
        assert value | 0xFFFF == 0xFFFF
        self.write(WsTriggerHandlerAddress.TRIGGER_PERIOD, value, commitTransaction=commitTransaction)

    def get_trigger_period(self, commitTransaction=True):
        """Gets the continuous mode trigger period in units of 6.25ns"""
        return self.read(WsTriggerHandlerAddress.TRIGGER_PERIOD, commitTransaction=commitTransaction)

    def _set_pulse_ntrigger(self, value, commitTransaction=True):
        assert value in range(2)
        self.write(WsTriggerHandlerAddress.PULSE_nTRIGGER, value, commitTransaction=commitTransaction)

    def get_pulse_ntrigger(self, commitTransaction=True):
        return self.read(WsTriggerHandlerAddress.PULSE_nTRIGGER, commitTransaction=commitTransaction)

    def configure_to_send_pulses(self, commitTransaction=True):
        self._set_pulse_ntrigger(Pulse_nTrigger.Pulse, commitTransaction=commitTransaction)

    def configure_to_send_triggers(self, commitTransaction=True):
        self._set_pulse_ntrigger(Pulse_nTrigger.Trigger, commitTransaction=commitTransaction)

    def set_trigger_minimum_distance(self, value, commitTransaction=True):
        """Sets the trigger minimum_temporal distance in units of 6.25ns"""
        assert value | 0xFFFF == 0xFFFF
        self.write(WsTriggerHandlerAddress.TRIGGER_MIN_DISTANCE, value, commitTransaction=commitTransaction)

    def get_trigger_minimum_distance(self, commitTransaction=True):
        """Gets the trigger minimum_temporal distance in units of 6.25ns"""
        return self.read(WsTriggerHandlerAddress.TRIGGER_MIN_DISTANCE, commitTransaction=commitTransaction)

    def get_operating_mode(self, commitTransaction=True):
        """Returns the operating mode of the trigger_handler"""
        ret = self.read(WsTriggerHandlerAddress.MODE, commitTransaction=commitTransaction)
        retdict = {}
        retdict['is_triggered']  = ret & 1
        retdict['is_continuous'] = ret>> 1 & 1
        return ret, retdict

    def set_opcode_gating(self, value, commitTransaction=True):
        """Allows gating the trigger/pulse signal to the alpide control generating an empty gbt packet
        """
        assert value in range(2)
        self.write(WsTriggerHandlerAddress.OPCODE_GATING, value, commitTransaction=commitTransaction)

    def get_opcode_gating(self, commitTransaction=True):
        """returns the current setting of the opcode gating register
        """
        return self.read(WsTriggerHandlerAddress.OPCODE_GATING, commitTransaction=commitTransaction)

    def get_mismatch(self, commitTransaction=True):
        return self.read(WsTriggerHandlerAddress.MISMATCH_WB, commitTransaction=commitTransaction)

    def dump_config(self):
        config_str = "--- TRIGGER HANDLER module ---\n"
        for address in WsTriggerHandlerAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#X}\n".format(name, value)
        return config_str
