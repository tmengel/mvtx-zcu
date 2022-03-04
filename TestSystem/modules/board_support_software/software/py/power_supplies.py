import logging
import time
from collections import Counter


class ChipPowerSupply(object):
    """Implementation of the chip powering scheme"""

    def power_on(self):
        """power on """
        raise NotImplementedError()
    def power_off(self):
        raise NotImplementedError()

    def set_voltages(self, avdd=1.8, dvdd=1.8, pvdd=None, backbias=None):
        raise NotImplementedError()

    def get_values(self):
        raise NotImplementedError()

class DummyPowerSupply(object):
    """Implementation of a dummy power supply"""
    def __init__(self):
        super(DummyPowerSupply, self).__init__()
        self.logger = logging.getLogger("DummyPowerSupply")

    def power_on(self):
        """power on """
        self.logger.warning("Nothing to power on")

    def power_off(self):
        self.logger.warning("Nothing to power off")

    def set_voltages(self, avdd=1.8, dvdd=1.8, pvdd=None, backbias=None):
        self.logger.warning("No voltage to set")

    def get_values(self):
        self.logger.debug("Nothing to return")
        values = {}
        values['AVDD']         = -1.0
        values['AVDD_CURRENT'] = -1.0
        values['DVDD']         = -1.0
        values['DVDD_CURRENT'] = -1.0
        return values

class ChipPowerSupplyInternal(ChipPowerSupply):
    def __init__(self, chippower):
        super(ChipPowerSupplyInternal, self).__init__()
        self.chippower = chippower

    def power_on(self):
        """power on """
        self.chippower.enable_voltages(True, True)
    def power_off(self):
        self.chippower.enable_voltages(False, False)

    def set_voltages(self, avdd=1.8, dvdd=1.8, pvdd=None, backbias=None):
        assert pvdd is None
        assert backbias is None

        self.chippower.set_voltages(avdd, dvdd)

    def get_values(self):
        return self.chippower.read_values()


class ChipPowerSupplyHameg(ChipPowerSupply):
    def __init__(self, hameg_supply):
        super(ChipPowerSupplyHameg, self).__init__()
        self.hameg_supply = hameg_supply

        for i in range(2,self.hameg_supply.number_channels+1):
            self.hameg_supply.configure_channel(i,0,0.01)

        self.pvdd_used = False

    def power_on(self):
        if self.pvdd_used:
            self.hameg_supply.activate_channels([2,3,4])
        else:
            self.hameg_supply.activate_channels([2,3])
    def power_off(self):
        self.hameg_supply.deactivate_channels([2,3,4])

    def set_voltages(self, avdd=1.8, dvdd=1.8, pvdd=None, backbias=None):
        assert backbias is None

        self.hameg_supply.configure_channel(2,avdd,0.4)
        self.hameg_supply.configure_channel(3,dvdd,0.6)
        if pvdd:
            self.hameg_supply.configure_channel(4,pvdd,0.1)
            self.pvdd_used = True
        else:
            self.pvdd_used = False
    def get_values(self):
        values = {}
        values['AVDD']         = self.hameg_supply.get_voltage(2)
        values['AVDD_CURRENT'] = self.hameg_supply.get_current(2)
        values['DVDD']         = self.hameg_supply.get_voltage(3)
        values['DVDD_CURRENT'] = self.hameg_supply.get_current(3)

        return values

class CompositeChipPowerSupply(ChipPowerSupply):
    def __init__(self, supplies):
        super(CompositeChipPowerSupply, self).__init__()
        self.power_supplies = supplies

    def power_on(self):
        for ps in self.power_supplies:
            ps.power_on()

    def power_off(self):
        for ps in self.power_supplies:
            ps.power_off()

    def set_voltages(self, avdd=1.8, dvdd=1.8, pvdd=None, backbias=None):
        for ps in self.power_supplies:
            ps.set_voltages(avdd,dvdd,pvdd,backbias)

    def get_values(self):
        all_values = {}
        value_list = [Counter(ps.get_values()) for ps in self.power_supplies]
        all_values = Counter()
        for value in value_list:
            all_values += value
        return dict(all_values)


class ChipPowerSupplyHamegStave(ChipPowerSupply):
    def __init__(self, hameg_supply):
        super(ChipPowerSupplyHamegStave, self).__init__()
        self.hameg_supply = hameg_supply

        for i in range(2,self.hameg_supply.number_channels+1):
            self.hameg_supply.configure_channel(i,0,0.01)
        self.pvdd_used = False
        self.logger = logging.getLogger("ChipPowerSupplyHamegStave")


    def power_on(self):
            self.hameg_supply.activate_channels([3,4])

    def power_off(self):
        self.hameg_supply.deactivate_channels([3,4])

    def set_voltages(self, avdd=None, dvdd=None, pvdd=None, backbias=None):
        assert backbias is None
        if avdd or dvdd:
            self.logger.warn("Using on-stave regulator, voltage settings ignored")
        self.hameg_supply.configure_channel(3, 3.0, 0.3)
        self.hameg_supply.configure_channel(4, 3.0, 1.5)

    def get_values(self):
        values = {}
        values['AVDD']         = self.hameg_supply.get_voltage(3)
        values['AVDD_CURRENT'] = self.hameg_supply.get_current(3)
        values['DVDD']         = self.hameg_supply.get_voltage(4)
        values['DVDD_CURRENT'] = self.hameg_supply.get_current(4)

        return values


class ChipPowerSupplyMixed(ChipPowerSupply):
    """Mixed Powersupply with Ru internal for AVDD and DVDD and HAMEG for Backbias"""
    def __init__(self, chippower, hameg_supply, max_bb_current=2):
        super(ChipPowerSupplyMixed, self).__init__()
        self.hameg_supply = hameg_supply
        self.chippower = chippower

        for i in range(2,self.hameg_supply.number_channels+1):
            self.hameg_supply.configure_channel(i,0,0.01)

        self.backbias_used = False
        self.max_bb_current = max_bb_current
        self.bb_voltage = None
        self.bb_current_limit = 0.02

        self.logger = logging.getLogger("ChipPowerSupplyMixed")

    def power_on(self):
        if self.backbias_used:
            self.hameg_supply.configure_channel(2,1,self.bb_current_limit)
            self.hameg_supply.activate_channel(2)
            time.sleep(0.5)
            current = self.hameg_supply.get_current(2)
            if current > self.max_bb_current:
                self.logger.error("Backbias current overflow: %f mA", current)
                self.hameg_supply.deactivate_channel(2)
                raise RuntimeError("BB current overflow")
            self.hameg_supply.configure_channel(2,self.bb_voltage,self.bb_current_limit)

        self.chippower.enable_voltages(True, True)
    def power_off(self):
        self.chippower.enable_voltages(False, False)

        if self.backbias_used:
            self.hameg_supply.deactivate_channel(2)

    def set_voltages(self, avdd=1.8, dvdd=1.8, pvdd=None, backbias=None):
        assert pvdd is None

        self.chippower.set_voltages(avdd, dvdd)

        if backbias is not None:
            self.backbias_used = True
            self.bb_voltage = backbias
            self.hameg_supply.configure_channel(2,backbias,self.bb_current_limit)
        else:
            self.backbias_used = False
            self.hameg_supply.deactivate_channel(2)

    def get_values(self):
        values = self.chippower.read_values()
        if self.backbias_used:
            values['BB']         = self.hameg_supply.get_voltage(2)
            values['BB_CURRENT'] = self.hameg_supply.get_current(2)
        return values
