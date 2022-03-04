"""Chip power module.

Enable chip voltages, set voltages, readback voltages and currents for
AVDD,DVDD

"""

import collections

from wishbone_module import WishboneModule


class ConversionParameter:
    """Simple class to store conversion parameters and convert values"""

    def __init__(self, k=1, d=0):
        self.k = k
        self.d = d

    def step_to_value(self, step):
        """Convert a DAC/ADC step to a value"""
        if step is None:
            return None
        else:
            return step * self.k + self.d

    def value_to_step(self, voltage):
        """Convert a value to a DAC/ADC step"""
        return int(round((voltage - self.d) / self.k))


class ChipPower(WishboneModule):
    """Class to handle chip power settings"""

    def __init__(self, comm, moduleId, ru_nr=0):
        super(ChipPower, self).__init__(moduleId, comm, "ChipPower")
        self.parameters = {}
        self._create_parameter_table(ru_nr)

    def _create_parameter_table(self, ru_nr):
        """Define conversion parameters"""
        self.parameters["DAC_AVDD"] = ConversionParameter(
            k=0.0027868811, d=1.6145428629)
        self.parameters["DAC_DVDD"] = ConversionParameter(
            k=0.0027857802, d=1.61976)
        self.parameters["ADC_DVDD_CURRENT"] = ConversionParameter(
            k=0.23089, d=0)
        self.parameters["ADC_AVDD_CURRENT"] = ConversionParameter(
            k=0.0593333696, d=0)
        self.parameters["ADC_AVDD"] = ConversionParameter(
            k=0.0006102496, d=6.2943e-5)
        self.parameters["ADC_DVDD"] = ConversionParameter(
            k=0.0006102496, d=6.2943e-5)

    def initialize(self):
        """Initialize the module"""
        self.init_ADC()
        self.set_voltages(1.8, 1.8)

    def enable_voltages(self, AVDD=True, DVDD=True,commitTransaction=True):
        """Enable AVDD and / or DVDD.
        True: Enable,
        False: Disalbe,
        None: keep
        """
        if AVDD is None or DVDD is None:
            data = self.read(0)
        else:
            data = 0

        if AVDD is True:
            data |= 1
        elif AVDD is False:
            data &= ~1
        if DVDD is True:
            data |= 2
        elif DVDD is False:
            data &= ~2

        self.write(0, data,commitTransaction)

    def set_voltages(self, AVDD=None, DVDD=None,commitTransaction=True):
        """Set AVDD and DVDD voltages (if not none)"""
        avdd_reg = None
        dvdd_reg = None
        if AVDD is not None:
            avdd_reg = self.parameters["DAC_AVDD"].value_to_step(AVDD)
        if DVDD is not None:
            dvdd_reg = self.parameters["DAC_DVDD"].value_to_step(DVDD)
        self._set_voltages_raw(avdd_reg, dvdd_reg,commitTransaction)

    def _set_voltages_raw(self, avdd_step=None, dvdd_step=None, commitTransaction=True):
        """Set AVDD and DVDD voltages in DAC steps (if not none)"""
        voltage_writes = 0
        if avdd_step is not None:
            self.write(2, avdd_step,commitTransaction=False)
            voltage_writes |= 1
        if dvdd_step is not None:
            self.write(3, dvdd_step,commitTransaction=False)
            voltage_writes |= 2

        self.write(1, voltage_writes,commitTransaction=commitTransaction)

    def init_ADC(self):
        """Initialize the ADC for readout"""
        # "Internal voltage reference, GP0 is Busy indicator, CMOS drive"
        # "write to register 2"
        data = 1 | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 10) | (0x2 << 11)
        self.write(4, data, False)
        self.write(6, 0x2, True)

        self._wait_ack(100)

        # "Activate all channels for channel sequencer"
        data = 0xF | (1 << 10) | (0x1 << 11)
        self.write(4, data, False)
        self.write(6, 0x2, True)
        self._wait_ack(100)

    def _wait_ack(self, maxCnt=100):
        """Wait for ADC acknowledge bit"""
        dataread = self.read(6)
        cnt = 0

        while dataread is not None and (dataread & 0x4 == 0) and cnt < maxCnt:
            dataread = self.read(6)

        return dataread & 0x4 != 0

    def log_currents(self):
        """Logs ADC values (AVDD, DVDD currents and voltages)"""
        values = self.read_values()
        self.logger.info(
            "ADC status:\tAVDD voltage %2.2f V,\tAVDD current %2.2f mA,\tDVDD voltage %2.2f V,\tDVDD current %2.2f mA",
            values['AVDD'],
            values['DVDD'],
            values['AVDD_CURRENT'],
            values['DVDD_CURRENT'])
        return values

    def read_values(self):
        """Read values for AVDD,DVDD (voltages, currents)"""
        values_raw = self.read_values_raw()
        return self._convert_raw_values(values_raw)

    def _convert_raw_values(self, values_raw):
        """Convert raw ADC steps to voltage/current values"""
        self.logger.debug("Values raw:")
        self.logger.debug(values_raw)
        adc_mapping = {0: "AVDD_CURRENT", 1: "DVDD", 2: "AVDD", 3: "DVDD_CURRENT"}

        values = {adc_mapping[key]: self.parameters["ADC_" + adc_mapping[key]].step_to_value(
            value) for (key, value) in values_raw.items()}
        return values

    def read_values_raw(self):
        """Read raw ADC values for AVDD,DVDD (voltages, currents)"""
        MAX_NR_TRIES = 8
        values_raw = {0: None, 1: None, 2: None, 3: None}
        self.write(4, 0x00)

        nr_tries = 0
        while None in values_raw.values() and nr_tries < MAX_NR_TRIES:
            self.write(6, 0x1)
            self._wait_ack()
            data = self.read(5)

            nr = data >> 13
            values_raw[nr] = data & 0x0FFF
            self.logger.debug("Idx: {0}, nr: {1}, value: {2}".format(nr_tries, nr, values_raw[nr]))
            nr_tries += 1

        if None in values_raw.values():
            self.logger.error("Could not read all ADC values. None results still present")
            self.logger.error(values_raw)

        return values_raw

    def readreg_powerbank_switch(self):
        """Read the Powerbank switch register"""
        reg = self.read(0)

        result = collections.OrderedDict()

        result['AVDD_POWERON'] = reg >> 0 & 0x1
        result['DVDD_POWERON'] = reg >> 1 & 0x1

        return result

    def dump_config(self):
        config_str = "--- Chip voltage control module ---\n"

        config_str += "  - Transceiver settings:\n"
        settings = self.readreg_powerbank_switch()
        for name, value in settings.items():
            config_str += "    - {0} : {1:#X}\n".format(name, value)

        return config_str
