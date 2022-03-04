#!/usr/bin/env python

"""Power unit wishbone module

NOTE: use latest documentation

Twiki: https://twiki.cern.ch/twiki/bin/view/ALICE/Documentation

Documentation at: https://twiki.cern.ch/twiki/pub/ALICE/Documentation/2018_09_04_ITS_power_system_V15_32-channel_operation_manual.pdf
and
https://twiki.cern.ch/twiki/pub/ALICE/Documentation/2018_09_04_ITS_power_system_V15_32-channel_operation_manual.docx
"""

from collections import OrderedDict
from enum import IntEnum

from wishbone_module import WishboneModule

class WbI2cPuAddress(IntEnum):
    InternalRegister         = 0x0
    TempThreshConfigAddress  = 0x1
    ThresCurrAddress_0       = 0x2
    ThresCurrAddress_1       = 0x3
    ThresCurrAddress_2       = 0x4
    ThresCurrAddress_3       = 0x5
    PotPowerAddress_0        = 0x6
    PotPowerAddress_1        = 0x7
    PotPowerAddress_2        = 0x8
    PotPowerAddress_3        = 0x9
    PotBiasAddress           = 0xA
    ADCAddressSetup_0        = 0xB
    ADCAddressSetup_1        = 0xC
    ADCAddressSetup_2        = 0xD
    ADCAddressSetup_3        = 0xE
    ADCBiasAddressSetup      = 0xF
    ADCAddress_0             = 0x10
    ADCAddress_1             = 0x11
    ADCAddress_2             = 0x12
    ADCAddress_3             = 0x13
    ADCBiasAddress           = 0x14
    TempThreshRdAddress      = 0x15
    IOExpanderBiasAddress    = 0x16
    IOExpanderPowerAddress_0 = 0x20
    IOExpanderPowerAddress_1 = 0x21

class PowerUnit(WishboneModule):
    """Class for performing I2C transactions with the Power Unit on RUv1"""

    # see power unit manual Chapter 9.1, Table 17
    CONFIG_RTD_BYTE3_60HZ = 0xc2
    CONFIG_RTD_BYTE3_50HZ = 0xc3

    def __init__(self, board_obj, moduleid):
        super(PowerUnit, self).__init__(moduleid=moduleid, name='PowerUnit', board_obj=board_obj)
        # register mapping is different than power unit documentation.
        # refer to vhdl file
        self.ThresCurrAddress = (0x02, 0x03, 0x04, 0x05)
        self.PotPowerAddress = (0x06, 0x07, 0x08, 0x09)
        self.PotBiasAddress = (0x0A)
        self.ADCAddressSetup = (0x0B, 0x0C, 0x0D, 0x0E)
        self.ADCBiasAddressSetup = (0x0F)
        self.ADCAddress = (0x10, 0x11, 0x12, 0x13)
        self.ADCBiasAddress = (0x14)
        self.IOExpanderBiasAddress = (0x16)
        self.IOExpanderPowerAddress = (0x20, 0x21)
        self.TempThreshConfigAddress = (0x1)
        self.TempThreshRdAddress = (0x15)

    def initialize(self):
        self.ConfigureBiasADC()
        self.ConfigurePowerADC()

    def _VBiasToCode(self,vbias):
        code = int(vbias * (-125.0/5.0)) # Chap 9.4 manual v1.5
        if code > 0xff:
            self.logger.warning("code out of range, set to max (code:{0}/255)".format(code))
            code=0xff
        if code < 0:
            self.logger.warning("code out of range, set to 0 (code: {0})".format(code))
            code=0
        return code

    def _code_to_vbias(self, code):
        """V in V
        """
        return -(5.12 / 4096) * code

    def _code_to_ibias(self, code):
        """I in mA
        """
        i = 1000* (2.56 / 4096) * code
        if i < 0:
            i = 0
        return i

    def _VoutToCode(self,vout, offset = 0):
        code = int((vout / 0.00486) - 306) # Chap 9.3 manual v1.5
        code = code - offset
        if code < 0:
            self.logger.warning("code out of range, set to 0 (code:{0})".format(code))
            code = 0
        elif code > 0xff:
            self.logger.warning("code out of range, set to max (code:{0}/255)".format(code))
            code = 0xff
        return code

    def _code_to_vout(self, code):
        """V in V
        """
        return (2.56 / 4096) * code

    def _IthToCode(self,ith):
        code = int(410 + (3685.0 / 3.0) * ith) # Chap 9.2 manual v1.5
        if code < 0:
            self.logger.warning("code out of range, set to 0 (code:{0})".format(code))
            code = 0
        if code > 0xFFF:
            self.logger.warning("code out of range, set to max (code: 0X{0:03X}/0xFFF)".format(code))
            code = 0xFFF
        return code

    def _code_to_i(self, code):
        """I in mA
        """
        i = 1000 * ((2.56 / 4096) * code - 0.25) * 1.333
        if i < 0:
            i = 0
        return i

    def setup_power_IB(self,
                     dvdd=1.9, dvdd_current=1.5,
                     avdd=1.9, avdd_current=1.5,
                     bb=0.0, bb_current=None,
                     module=0):
        self.setup_power_IBs(dvdd=dvdd, dvdd_current=dvdd_current,
                           avdd=avdd, avdd_current=avdd_current,
                           bb=bb, bb_current=bb_current,
                           module_list=[module])

    def setup_power_IBs(self,
                     dvdd=1.9, dvdd_current=1.5,
                     avdd=1.9, avdd_current=1.5,
                     bb=0,bb_current=None,
                     module_list=[0,1]):

        if bb_current is not None:
            raise NotImplementedError
        for module in module_list:
            assert module in range(8)

        # built-in extra safety
        assert dvdd >= 0 and dvdd <= 2.0
        assert avdd >= 0 and avdd <= 2.0
        assert dvdd_current >= 0 and dvdd_current <= 3.0
        assert avdd_current >= 0 and avdd_current <= 3.0

        dvdd_code = self._VoutToCode(vout=dvdd, offset=0x12)
        avdd_code = self._VoutToCode(vout=avdd, offset=0x12)
        bb_code = self._VBiasToCode(vbias=bb)
        dvdd_current_code = self._IthToCode(ith=dvdd_current)
        avdd_current_code = self._IthToCode(ith=avdd_current)

        analog = 0
        digital = 1
        for module in module_list:
            self.SetPowerVoltage(channel=analog +2*module, voltagecode=avdd_code)
            self.SetPowerVoltage(channel=digital+2*module, voltagecode=dvdd_code)
        if bb :
            self.SetBiasVoltage(voltagecode=bb_code)

        self.RaiseThresholdsToMax()
        for module in module_list:
            self.SetThreshold(channel=analog +module*2, value=avdd_current_code)
            self.SetThreshold(channel=digital+module*2, value=dvdd_current_code)

    def log_enable_status(self):
        power_enable_status = self.get_power_enable_status()
        bias_enable_status = self.get_bias_enable_status()
        self.logger.info("Power enable status: %04X, Bias enable status: %02X",
                         power_enable_status,
                         bias_enable_status)
        return power_enable_status, bias_enable_status

    def power_on_IB(self, module, backbias_en=0):
        self.power_on_IBs(module_list=[module], backbias_en=backbias_en)

    def power_on_IBs(self, module_list=[0,1], backbias_en=0):
        for module in module_list:
            assert module in range(8)
            self.logger.info("Setup power for IB on module {0}".format(module))

        self.logger.info("All off")
        self.log_enable_status()
        self.logger.info("Bias powering ON")
        mask_b = 0
        if backbias_en :
            for module in module_list:
                mask_b = mask_b | (0x1 << module)
            self.EnableBiasWithMask(mask=mask_b)
            self.logger.info("BB on")
            power_enable_status, bias_enable_status = self.log_enable_status()
            assert power_enable_status == 0
            assert bias_enable_status == mask_b

        mask_ad = 0
        self.logger.info("Analog + Digital powering on")
        for module in module_list:
            self.logger.info("Powering module {0}".format(module))
            mask_ad = mask_ad | (0x1 << (module * 2))
            self.EnablePowerWithMask(mask=mask_ad) # analog
            power_enable_status, bias_enable_status = self.log_enable_status()
            assert power_enable_status == mask_ad
            assert bias_enable_status == mask_b
            mask_ad = mask_ad | (0x3 << (module * 2))
            self.EnablePowerWithMask(mask=mask_ad) # digital + analog
            power_enable_status, bias_enable_status = self.log_enable_status()
            assert power_enable_status == mask_ad
            assert bias_enable_status == mask_b

        self.logger.info("All on")
        for i in range(10):
            self.log_enable_status()

    def power_off_all(self):
        self.DisablePowerAll()
        self.DisableBiasAll()
        self.SetPowerVoltageAll(voltagecode=0)
        self.SetBiasVoltage(voltagecode=0)
        self.LowerThresholdsToMin()

    def get_values_IB(self, module):
        self.get_values_IBs(module_list=[module])

    def get_values_IBs(self, module_list=[0,1]):
        power_enable_status = self.get_power_enable_status()
        bias_enable_status = self.get_bias_enable_status()
        vdd_ret = {}
        for module in module_list:
            vdd_ret[module] = self.get_power_adc_values(module)
        bb_voltage = self.ReadBiasADCChannel(channel=2)
        bb_current = self.ReadBiasADCChannel(channel=0)

        values = OrderedDict([
            ("power_enable_status" , power_enable_status),
            ("bias_enable_status"  , bias_enable_status),
            ("bb_voltage"   , bb_voltage),
            ("bb_current"   , bb_current)
        ])
        for module in module_list:
            for key, dict_value in vdd_ret[module].items():
                values["module_{0}_{1}".format(module, key)] = dict_value
        return values

    def log_values_IB(self, module):
        self.log_values_IBs(module_list=[module])

    def log_values_IBs(self, module_list=[0,1]):
        values = self.get_values_IBs(module_list=module_list)
        self.logger.info("Power enable status: 0x{0:04X}".format(values["power_enable_status"]))
        self.logger.info("Bias enable status: 0x{0:02X}".format(values["bias_enable_status"]))
        self.logger.info("Backbias: {0:.3f} V, {1:.1f} mA".format(self._code_to_vbias(values["bb_voltage"]),
                                                                  self._code_to_ibias(values["bb_current"])))
        for module in module_list:
            for vdd in ["avdd", "dvdd"]:
                self.logger.info("Module {0}, {1}: {2:.3f} V, {3:.1f} mA ".format(module,
                                                                                  vdd,
                                                                                  self._code_to_vout(values["module_{0}_{1}_voltage".format(module, vdd)]),
                                                                                  self._code_to_i(values["module_{0}_{1}_current".format(module, vdd)])))

    def RaiseThresholdsToMax(self, commitTransaction=True):
        """Set current thresholds of all channels to 0xffff"""
        byte1 = 0x3f
        byte2 = 0xff
        byte3 = 0xff

        self.write(0, byte1, commitTransaction=False)

        data = (byte2 << 8) | byte3
        for i in range(4) :
            self.write(self.ThresCurrAddress[i], data, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def LowerThresholdsToMin(self, commitTransaction=True):
        """Set current thresholds of all channels to 0x0000"""

        byte1 = 0x3f
        byte2 = 0x00
        byte3 = 0x00

        self.write(0, byte1, commitTransaction=False)

        data = (byte2 << 8) | byte3
        for i in range(4) :
            self.write(self.ThresCurrAddress[i], data, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def SetThreshold(self, channel, value, commitTransaction=True):
        """Set threshold of channel 'channel' to 'value'

        16 channels
        0 + 2*module: analog
        1 + 2*module: digital"""
        assert channel | 0xF == 0xF
        assert value | 0xFFF == 0xFFF

        channel_msb = channel >> 2
        channel_lsb = channel & 0x3

        byte1 = (0x3 << 4) | channel_lsb
        byte2 = (value >> 4) & 0xff
        byte3 = (value & 0xf) << 4

        self.write(0, byte1, commitTransaction=False)

        data = (byte2 << 8) | byte3
        self.write(self.ThresCurrAddress[channel_msb], data, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def SetThresholdWithMask(self, mask, value, commitTransaction=True):
        """Set threshold of each channel of bitposition in 'mask' to 'value'"""
        assert value | 0xFFF == 0xFFF
        assert mask | 0xFFFF == 0xFFFF
        for i in range(16):
            if ((mask >> i) & 1):
                self.SetThreshold(i, value, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def SetThresholdAll(self, value, commitTransaction=True):
        """Set threshold of all channels to 'value'"""
        assert value | 0xFFF == 0xFFF

        byte1 = 0x3f
        byte2 = (value >> 4) & 0xff
        byte3 = (value & 0xf) << 4

        self.write(0, byte1, commitTransaction=False)

        data = (byte2 << 8) | byte3
        for i in range(4) :
            self.write(self.ThresCurrAddress[i], data, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def EnablePowerAll(self, commitTransaction=True):
        """Enable all power channels"""

        byte3 = 0xff
        self.write(self.IOExpanderPowerAddress[0], byte3, commitTransaction=False)
        self.write(self.IOExpanderPowerAddress[1], byte3, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def EnableBiasAll(self, commitTransaction=True):
        """Enable all bias channels"""

        byte3 = 0x00
        self.write(self.IOExpanderBiasAddress, byte3, commitTransaction=commitTransaction)

    def EnablePower(self, channel, commitTransaction=True):
        """Enable power channel 'channel'"""
        assert channel in range(16)

        channel_msb = channel >> 3
        channel_lsb = channel & 0x7
        byte3 = 0x01 << channel_lsb
        self.write(self.IOExpanderPowerAddress[channel_msb], byte3, commitTransaction=commitTransaction)

    def EnablePowerWithMask(self, mask, commitTransaction=True):
        """Enable each power channel of bitposition in 'mask'"""
        assert mask | 0xFFFF == 0xFFFF

        byte3 = mask & 0xff
        self.write(self.IOExpanderPowerAddress[0], byte3, commitTransaction=False)
        byte3 = (mask >> 8) & 0xff
        self.write(self.IOExpanderPowerAddress[1], byte3, commitTransaction=commitTransaction)

    def EnableBiasWithMask(self, mask, commitTransaction=True):
        """Enable each bias for channels in bit position of mask"""
        assert mask | 0xFF == 0xFF

        byte3 = 0xff ^ mask
        self.write(self.IOExpanderBiasAddress, byte3, commitTransaction=commitTransaction)

    def DisablePowerAll(self, commitTransaction=True):
        """Disable each power channel"""

        byte3 = 0x00
        self.write(self.IOExpanderPowerAddress[0], byte3, commitTransaction=False)
        self.write(self.IOExpanderPowerAddress[1], byte3, commitTransaction=commitTransaction)

    def DisableBiasAll(self, commitTransaction=True):
        """Disable each bias channel"""

        byte3 = 0xff
        self.write(self.IOExpanderBiasAddress, byte3, commitTransaction=commitTransaction)

    def SetPowerVoltage(self, channel, voltagecode, commitTransaction=True):
        """Set output voltage setting of power 'channel' to 'voltage'"""
        assert channel in range(16)
        assert voltagecode | 0xFF == 0xFF

        channel_msb = channel >> 2
        channel_lsb = channel & 0x3

        byte2 = channel_lsb
        byte3 = voltagecode
        data = (byte2 << 8) | byte3
        self.write(self.PotPowerAddress[channel_msb], data, commitTransaction=commitTransaction)

    def SetPowerVoltageAll(self, voltagecode, commitTransaction=True):
        """Set output voltage setting of all power channels to 'voltage'"""
        for channel in range(16):
            self.SetPowerVoltage(channel, voltagecode, commitTransaction=commitTransaction)

    def SetBiasVoltage(self, voltagecode, commitTransaction=True):
        """Set output voltage setting of bias channels to 'voltage'"""
        assert voltagecode | 0xFF == 0xFF
        byte2 = 0x11
        byte3 = voltagecode
        data = (byte2 << 8) | byte3
        self.write(self.PotBiasAddress, data, commitTransaction=commitTransaction)

    def ConfigurePowerADC(self, commitTransaction=True):
        """Configure control registers of all Power ADCs"""

        for SlaveAddress in self.ADCAddressSetup:
            #byte2 = 0x00 # Table 33 manual v1.5
            #byte3 = 0x00
            #data = (byte2 << 8) | byte3
            data = 0
            self.write(SlaveAddress, data, commitTransaction=False)
            byte2 = 0x07 # Table 33 manual v1.5
            byte3 = 0x01
            data = (byte2 << 8) | byte3
            self.write(SlaveAddress, data, commitTransaction=False)
            byte2 = 0x0B # Table 33 manual v1.5
            byte3 = 0x02
            data = (byte2 << 8) | byte3
            self.write(SlaveAddress, data, commitTransaction=False)
            byte2 = 0x00 # Table 33 manual v1.5
            byte3 = 0x01
            data = (byte2 << 8) | byte3
            self.write(SlaveAddress, data, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def ConfigureBiasADC(self, commitTransaction=True):
        """Configure control registers of all Bias ADCs"""

        SlaveAddress = self.ADCBiasAddressSetup
        #byte2 = 0x00 # Table 33 manual v1.5
        #byte3 = 0x00
        #data = (byte2 << 8) | byte3
        data = 0
        self.write(SlaveAddress, data, commitTransaction=False)
        byte2 = 0x07 # Table 33 manual v1.5
        byte3 = 0x01
        data = (byte2 << 8) | byte3
        self.write(SlaveAddress, data, commitTransaction=False)
        byte2 = 0x0B # Table 33 manual v1.5
        byte3 = 0x02
        data = (byte2 << 8) | byte3
        self.write(SlaveAddress, data, commitTransaction=False)
        byte2 = 0x00 # Table 33 manual v1.5
        byte3 = 0x01
        data = (byte2 << 8) | byte3
        self.write(SlaveAddress, data, commitTransaction=False)
        if commitTransaction:
            self.flush()

    def get_power_enable_status(self, commitTransaction=True):
        """Read enable status of all power channels as a mask"""
        self.read(self.IOExpanderPowerAddress[0], commitTransaction=False)
        self.read(self.IOExpanderPowerAddress[1], commitTransaction=False)
        if commitTransaction:
            self.flush()
            results = self.comm.read_results()
            return self._format_get_power_enable_status(results)

    def _format_get_power_enable_status(self, results):
        assert len(results) == 2
        ret = ((results[1][1] & 0xFF) << 8) | (results[0][1] & 0xFF)
        return ret

    def get_bias_enable_status(self, commitTransaction=True):
        """Read enable status of all bias channels as a mask"""
        self.read(self.IOExpanderBiasAddress, commitTransaction=False)
        if commitTransaction:
            self.flush()
            results = self.comm.read_results()
            return self._format_get_bias_enable_status(results)

    def _format_get_bias_enable_status(self, results):
        assert len(results) == 1
        ret = (results[0][1] & 0xFF) ^ 0xFF
        return ret

    def ReadPowerADC(self):
        """Trigger ADC conversion and readout of all Power ADC channels"""

        ADCData = []
        for SlaveAddress in self.ADCAddress:
            for channel in range(8):
                byte3 = 0x20 | channel
                self.write(SlaveAddress, byte3, commitTransaction=True)
                ADCValue = self.read(SlaveAddress)
                ADCData.append(ADCValue >> 4) # 4LSB are not in use, see table 36 manual v1.5
                # convert to V or A
                #if channel%2:  # current measurements
                #    ADCData.append( (((ADCValue>>4)/4096.)*2.56 - 0.25)/(0.005*150) )
                #else:  # voltage measurements
                #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
        return ADCData

    def ReadBiasADC(self):
        """Trigger ADC conversion and readout of all Bias ADC channels"""

        ADCData = []
        SlaveAddress = self.ADCBiasAddress
        for channel in [0,2]:
            byte3 = 0x20 | channel
            self.write(SlaveAddress, byte3, commitTransaction=True)
            ADCValue = self.read(SlaveAddress)
            ADCData.append(ADCValue >> 4) # 4LSB are not in use, see table 36 manual v1.5
            # convert to V or A
            #if channel%2:
            #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
            #else:
            #    ADCData.append( -((ADCValue>>4)/4096.)*5.12 )
        return ADCData

    def get_power_adc_values(self, module):
        assert module in range(8), "module {0} not in range(8)".format(module)
        avdd_voltage = self.ReadPowerADCChannel(0 + 4*module)
        avdd_current = self.ReadPowerADCChannel(1 + 4*module)
        dvdd_voltage = self.ReadPowerADCChannel(2 + 4*module)
        dvdd_current = self.ReadPowerADCChannel(3 + 4*module)
        ret = OrderedDict([
            ("avdd_voltage" , avdd_voltage),
            ("avdd_current" , avdd_current),
            ("dvdd_voltage" , dvdd_voltage),
            ("dvdd_current" , dvdd_current)
        ])
        return ret

    def ReadPowerADCChannel(self, channel):
        """Trigger ADC conversion and readout a Power ADC channel
        """
        assert channel in range(32), "channel not in range (0 <= channel < 32)"

        channel_msb = channel >> 3
        channel_lsb = channel & 0x7

        byte3 = 0x20 | channel_lsb
        SlaveAddress = self.ADCAddress[channel_msb]
        self.write(SlaveAddress, byte3, commitTransaction=True)
        ADCValue = self.read(SlaveAddress)
        ADCData = ADCValue >> 4 # 4LSB are not in use, see table 36 manual v1.5
        # convert to V or A
        #if channel%2:  # current measurements
        #    ADCData.append( (((ADCValue>>4)/4096.)*2.56 - 0.25)/(0.005*150) )
        #else:  # voltage measurements
        #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
        return ADCData

    def ReadBiasADCChannel(self, channel):
        """Trigger ADC conversion and readout of a Bias ADC channel"""
        assert channel in [0, 2], "channel not valid, [0, 2]"

        SlaveAddress = self.ADCBiasAddress
        byte3 = 0x20 | channel
        self.write(SlaveAddress, byte3, commitTransaction=True)
        ADCValue = self.read(SlaveAddress)
        ADCData = ADCValue >> 4 # 4LSB are not in use, see table 36 manual v1.5
        # convert to V or A
        #if channel%2:
        #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
        #else:
        #    ADCData.append( -((ADCValue>>4)/4096.)*5.12 )
        return ADCData

    def ConfigureRTD(self, SensorID, commitTransaction=True):
        """Configure temperature sensor with ID SensorID"""

        SlaveAddress = self.TempThreshConfigAddress
        # byte values according to chapter 9.1, Table 17
        byte1 = 0x1 << (SensorID-1)
        byte2 = 0x80
        byte3 = self.CONFIG_RTD_BYTE3_60HZ
        data = (byte2 << 8) | byte3

        self.write(0, byte1, commitTransaction=False)
        self.write(SlaveAddress, data, commitTransaction=False)

        if commitTransaction:
            self.flush()

    def ReadRTD(self, SensorID, commitTransaction = True):
        """Read temperature Sensor with ID SensorID"""
        assert SensorID >= 1 and SensorID <=3, "SensorID not 1, 2, or 3)"
        SlaveAddress = self.TempThreshRdAddress

        # See Chapter 9.8 Table 38 manual v1.5

        byte1 = 0x1 << (SensorID-1)
        byte2 = 0x1
        byte3 = 0xff
        data = (byte2 << 8) | byte3

        self.write(0, byte1, commitTransaction=False)

        # first 3-byte write, followed by 2-byte read
        self.write(SlaveAddress, data, commitTransaction = False)
        self.read(SlaveAddress, commitTransaction = False)


        byte2 = 0x2
        data = (byte2 << 8) | byte3

        # second 3-byte write, followed by 2-byte read
        self.write(SlaveAddress, data, commitTransaction = False)
        self.read(SlaveAddress, commitTransaction = False)

        if commitTransaction:
            results = self.read_all()
            assert len(results) == 2
            ResistanceValue =((results[0] & 0xff)<<7) | ((results[1] & 0xff)>>1)
            TemperatureValue = (ResistanceValue - 8192.)/31.54

            return TemperatureValue
