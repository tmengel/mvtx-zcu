""" Class to communicate with the Xilinx System Monitor (SYSMON) """

from wishbone_module import WishboneModule
from enum import IntEnum

import collections


class WsSysmonAddess(IntEnum):
    """ Wishbone Register mapping for SYSMON """
    TMR_MISC = 0x00
    DRP_ADDR = 0x01
    DRP_DATA = 0x02


class DrpSysmonAddress(IntEnum):
    """ Dynamic Reconfiguration Port Register mapping for SYSMON """
    STATUS_TEMPERATURE = 0x00
    STATUS_VCC_INT = 0x01
    STATUS_VCC_AUX = 0x02
    STATUS_VP_VN = 0x03
    STATUS_VREF_P = 0x04
    STATUS_VREF_N = 0x05
    STATUS_VCC_BRAM = 0x06
    STATUS_SUPPLY_OFF = 0x08
    STATUS_ADC_OFF = 0x09
    STATUS_ADC_GAIN = 0x0A
    STATUS_MAX_TEMP = 0x20
    STATUS_MAX_VCC_INT = 0x21
    STATUS_MAX_VCC_AUX = 0x22
    STATUS_MAX_VCC_BRAM = 0x23
    STATUS_MIN_TEMP = 0x24
    STATUS_MIN_VCC_INT = 0x25
    STATUS_MIN_VCC_AUX = 0x26
    STATUS_MIN_VCC_BRAM = 0x27
    STATUS_FLAG_1 = 0x3E
    STATUS_FLAG_0 = 0x3F
    STATUS_VUSER_0 = 0x80
    STATUS_VUSER_1 = 0x81
    STATUS_VUSER_2 = 0x82
    STATUS_VUSER_3 = 0x83
    STATUS_MAX_VUSER_0 = 0xA0
    STATUS_MAX_VUSER_1 = 0xA1
    STATUS_MAX_VUSER_2 = 0xA2
    STATUS_MAX_VUSER_3 = 0xA3
    STATUS_MIN_VUSER_0 = 0xA8
    STATUS_MIN_VUSER_1 = 0xA9
    STATUS_MIN_VUSER_2 = 0xAA
    STATUS_MIN_VUSER_3 = 0xAB
    CONFIG_REGISTER_0 = 0x40
    CONFIG_REGISTER_1 = 0x41
    CONFIG_REGISTER_2 = 0x42
    CONFIG_REGISTER_3 = 0x43
    CONFIG_REGISTER_4 = 0x44
    CONFIG_SEQCHSEL0 = 0x46
    CONFIG_SEQCHSEL1 = 0x48
    CONFIG_SEQCHSEL2 = 0x49
    CONFIG_SLOWCHSEL0 = 0x7A
    CONFIG_SLOWCHSEL1 = 0x7B
    CONFIG_SLOWCHSEL2 = 0x7C
    CONFIG_SEQAVG0 = 0x47
    CONFIG_SEQAVG1 = 0x4A
    CONFIG_SEQAVG2 = 0x4B
    CONFIG_SEQINMODE0 = 0x4C
    CONFIG_SEQINMODE1 = 0x4D
    CONFIG_SEQACQ0 = 0x4E
    CONFIG_SEQACQ1 = 0x4F
    CONFIG_TEMP_UPP = 0x50
    CONFIG_VCC_INT_UPP = 0x51
    CONFIG_VCC_AUX_UPP = 0x52
    CONFIG_OT_UPP = 0x53
    CONFIG_TEMP_LOW = 0x54
    CONFIG_VCC_INT_LOW = 0x55
    CONFIG_VCC_AUX_LOW = 0x56
    CONFIG_OT_LOW = 0x57
    CONFIG_VCC_BRAM_UPP = 0x58
    CONFIG_VCC_BRAM_LOW = 0x5C
    CONFIG_VUSER_0_UPP = 0x60
    CONFIG_VUSER_1_UPP = 0x61
    CONFIG_VUSER_2_UPP = 0x62
    CONFIG_VUSER_3_UPP = 0x63
    CONFIG_VUSER_0_LOW = 0x68
    CONFIG_VUSER_1_LOW = 0x69
    CONFIG_VUSER_2_LOW = 0x6A
    CONFIG_VUSER_3_LOW = 0x6B


class DrpSysmonFlagMasks(IntEnum):
    FLAG0_ALM0 = (1 << 0)
    FLAG0_ALM1 = (1 << 1)
    FLAG0_ALM2 = (1 << 2)
    FLAG0_OT = (1 << 3)
    FLAG0_ALM3 = (1 << 4)
    FLAG0_ALM4 = (1 << 5)
    FLAG0_ALM5 = (1 << 6)
    FLAG0_ALM6 = (1 << 7)
    FLAG0_JTGR = (1 << 9)
    FLAG1_ALM8 = (1 << 0)
    FLAG1_ALM9 = (1 << 1)
    FLAG1_ALM10 = (1 << 2)
    FLAG1_ALM11 = (1 << 3)


class DrpSysmonConfigMasks(IntEnum):
    CFG0_CH0 = (1 << 0)
    CFG0_CH1 = (1 << 1)
    CFG0_CH2 = (1 << 2)
    CFG0_CH3 = (1 << 3)
    CFG0_CH4 = (1 << 4)
    CFG0_CH5 = (1 << 5)
    CFG0_ACQ = (1 << 8)
    CFG0_EC = (1 << 9)
    CFG0_BU = (1 << 10)
    CFG0_MUX = (1 << 11)
    CFG0_AVG0 = (1 << 12)
    CFG0_AVG1 = (1 << 13)
    CFG0_CAVG = (1 << 15)
    CFG1_OT = (1 << 0)
    CFG1_ALM0 = (1 << 1)
    CFG1_ALM1 = (1 << 2)
    CFG1_ALM2 = (1 << 3)
    CFG1_CAL0 = (1 << 4)
    CFG1_CAL2 = (1 << 6)
    CFG1_CAL3 = (1 << 7)
    CFG1_ALM3 = (1 << 8)
    CFG1_ALM4 = (1 << 9)
    CFG1_ALM5 = (1 << 10)
    CFG1_ALM6 = (1 << 11)
    CFG1_SEQ0 = (1 << 12)
    CFG1_SEQ1 = (1 << 13)
    CFG1_SEQ2 = (1 << 14)
    CFG1_SEQ3 = (1 << 15)
    CFG2_CD0 = (1 << 8)
    CFG2_CD1 = (1 << 9)
    CFG2_CD2 = (1 << 10)
    CFG2_CD3 = (1 << 11)
    CFG2_CD4 = (1 << 12)
    CFG2_CD5 = (1 << 13)
    CFG2_CD6 = (1 << 14)
    CFG2_CD7 = (1 << 15)
    CFG3_ALM8 = (1 << 0)
    CFG3_ALM9 = (1 << 1)
    CFG3_ALM10 = (1 << 2)
    CFG3_ALM11 = (1 << 3)


class Sysmon(WishboneModule):
    """ System Monitor Wishbone Slave """

    def __init__(self, moduleid, board_obj):
        super(Sysmon, self).__init__(moduleid=moduleid, name="Sysmon",
                                     board_obj=board_obj)
        self.verbose = False

    def set_data(self, address, value, commitTransaction=True):
        self.write(address, value, commitTransaction)

    def get_data(self, address, commitTransaction=True):
        return self.read(address, commitTransaction)

    def set_drp_address(self, value, commitTransaction=True):
        """ Set the ADDR Register for next transaction """
        self.set_data(WsSysmonAddess.DRP_ADDR, value, commitTransaction)

    def get_drp_data(self, commitTransaction=True):
        """ Returns data present in the DATA Register """
        return self.get_data(WsSysmonAddess.DRP_DATA, commitTransaction)

    def set_drp_data(self, value, commitTransaction=True):
        """ Set the DATA Register """
        self.write(WsSysmonAddess.DRP_DATA, value, commitTransaction)

    def _convertTemperature(self, digitalValue, nBits=16, onChip=True):
        if onChip:
            return (digitalValue * 501.3743) / (1 << nBits) - 273.6777
        else:
            return (digitalValue * 502.9098) / (1 << nBits) - 273.8195

    def _convertVoltage(self, digital_value, n_bits=16):
        return (digital_value * 3) / (1 << n_bits)

    def get_temperature(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_TEMPERATURE, commitTransaction=False)
        return self._convertTemperature(self.get_drp_data())

    def get_vcc_int(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_VCC_INT, commitTransaction=False)
        return self._convertVoltage(self.get_drp_data())

    def get_vcc_aux(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_VCC_AUX, commitTransaction=False)
        return self._convertVoltage(self.get_drp_data())

    def get_vref_p(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_VREF_P, commitTransaction=False)
        return self._convertVoltage(self.get_drp_data())

    def get_vref_n(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_VREF_N, commitTransaction=False)
        return self._convertVoltage(self.get_drp_data())

    def get_vcc_bram(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_VCC_BRAM, commitTransaction=False)
        return self._convertVoltage(self.get_drp_data())

    def disable_ot_protection(self, commitTransaction=True):
        self.set_drp_address(DrpSysmonAddress.CONFIG_REGISTER_1, commitTransaction=False)
        data = self.get_drp_data(commitTransaction=True)
        data |= DrpSysmonConfigMasks.CFG1_OT  # Set to 1 to disable OT
        self.set_drp_data(data, commitTransaction=commitTransaction)

    def enable_ot_protection(self, commitTransaction=True):
        self.set_drp_address(DrpSysmonAddress.CONFIG_REGISTER_1, commitTransaction=False)
        data = self.get_drp_data(commitTransaction = True)
        data &= ~DrpSysmonConfigMasks.CFG1_OT  # Set to 0 to disable OT
        self.set_drp_data(data, commitTransaction=commitTransaction)

    def get_ot_status(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_FLAG_0, commitTransaction=False)
        data = self.get_drp_data() & DrpSysmonFlagMasks.FLAG0_OT
        return data != 0

    def get_tmr_mismatch(self, commitTransaction=True):
        data = self.get_data(WsSysmonAddess.TMR_MISC, commitTransaction=commitTransaction)
        return data != 0

    def get_vcc_alpide_3v3(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_VUSER_0, commitTransaction=False)
        return 2 * self._convertVoltage(self.get_drp_data())

    def get_vcc_sca_1v5(self):
        self.set_drp_address(DrpSysmonAddress.STATUS_VUSER_1, commitTransaction=False)
        return self._convertVoltage(self.get_drp_data())

    def get_mismatch(self):
        """gets the actual mismatch status"""
        return self.read(WsSysmonAddess.TMR_MISC)

    def dump_config(self):
        configuration = "--- SYSMON Status ---\n"

        for address in DrpSysmonAddress:
            self.set_drp_address(address)
            name = address.name
            data = self.get_drp_data()
            configuration += "  - {0}\t\t: {1:#X}\n".format(name, data)

        return configuration
