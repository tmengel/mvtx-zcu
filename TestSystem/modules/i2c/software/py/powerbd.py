#!/usr/bin/env python

import logging
import logging.handlers
import random
import subprocess
import traceback
import sys
import os
from datetime import datetime
import time
from collections import OrderedDict


class PowerBoard:
    """Class for performing I2C transactionswith the Power Board on RUv1"""

    def __init__(self, comm, logger, module_id=5):
        self.logger = logger
        self.comm = comm
        self.module_id = module_id
        self.ThresCurrAddress = (0x02, 0x03, 0x04, 0x05)
        self.IOExpanderPowerAddress = (0x20, 0x21)
        self.IOExpanderBiasAddress = (0x16)
        self.PotPowerAddress = (0x06, 0x07, 0x08, 0x09)
        self.PotBiasAddress = (0x0A)
        self.ADCAddressSetup = (0x0B, 0x0C, 0x0D, 0x0E)
        self.ADCBiasAddressSetup = (0x0F)
        self.ADCAddress = (0x10, 0x11, 0x12, 0x13)
        self.ADCBiasAddress = (0x14)

    def initialize(self,PowerUnitID=1):
        self.ConfigureBiasADC(PowerUnitID)
        self.ConfigurePowerADC(PowerUnitID)

    def _VBiasToCode(self,vbias):
        code = int(vbias * (-125.0/5.0))
        if code > 255:
            code=255
        return code

    def _VoutToCode(self,vout):
        code = int((vout / 0.00486) - 306)
        if code < 0:
            code = 0
        elif code > 255:
            code = 255
        return code

    def _IthToCode(self,ith):
        code = int(410 + (3685.0/3.0) * ith)

        if code > 0xFFF:
            code = 0xFFF

        return code

    def SetupPowerIB(self,PowerUnitID=1,
                     DVDD=1.8, DVDD_CURR=1.5,
                     AVDD=1.8, AVDD_CURR=1.5,
                     BB=-3.3,BB_CURR=0.05):

        #self.PowerOffIB(PowerUnitID)

        dvdd_code = self._VoutToCode(DVDD) - 0x12
        avdd_code = self._VoutToCode(AVDD) - 0x12
        bb_code = 0x53 #self._VBiasToCode(BB)

        dvdd_curr_code = self._IthToCode(DVDD_CURR)
        avdd_curr_code = self._IthToCode(AVDD_CURR)

        self.ConfigurePowerADC(PowerUnitID)
        self.ConfigureBiasADC(PowerUnitID)

        # TODO, check SetPowerVoltage
        self.SetPowerVoltageAll(voltage=dvdd_code,PowerUnitID=PowerUnitID)

        self.SetBiasVoltage(voltage=bb_code,PowerUnitID=PowerUnitID)

        self.RaiseThresholdsToMax(PowerUnitID=1)

        self.SetThreshold(channel=1,value=dvdd_curr_code,PowerUnitID=PowerUnitID)
        self.SetThreshold(channel=0,value=avdd_curr_code,PowerUnitID=PowerUnitID)

    def PowerOnIB(self,PowerUnitID=1):
        pls = self.ReadPowerLatchStatus(PowerUnitID)
        bls = self.ReadBiasLatchStatus(PowerUnitID)
        self.logger.info("All Off: Powerlatch status: %04X, Biaslatchstatus: %02X",pls,bls)

        #        self.UnlatchBias(0,PowerUnitID=PowerUnitID)
        self.UnlatchBiasAll(PowerUnitID=PowerUnitID)
#        time.sleep(1)

        #print(self.ReadPowerADC(PowerUnitID=PowerUnitID))

        pls = self.ReadPowerLatchStatus(PowerUnitID)
        bls = self.ReadBiasLatchStatus(PowerUnitID)
        self.logger.info("Bias on: Powerlatch status: %04X, Biaslatchstatus: %02X",pls,bls)

        #self.UnlatchBiasAll(PowerUnitID=PowerUnitID)
        self.UnlatchPower(channel=0,PowerUnitID=PowerUnitID)
#        time.sleep(1)

        pls = self.ReadPowerLatchStatus(PowerUnitID)
        bls = self.ReadBiasLatchStatus(PowerUnitID)
        self.logger.info("Analog on: Powerlatch status: %04X, Biaslatchstatus: %02X",pls,bls)

        self.UnlatchPowerWithMask(mask=0x3,PowerUnitID=PowerUnitID)
 #       time.sleep(1)

        pls = self.ReadPowerLatchStatus(PowerUnitID)
        bls = self.ReadBiasLatchStatus(PowerUnitID)
        self.logger.info("All On: Powerlatch status: %04X, Biaslatchstatus: %02X",pls,bls)

    def PowerOffIB(self,PowerUnitID=1):
        self.DisablePowerAll(PowerUnitID)
        self.DisableBiasAll(PowerUnitID)

    def ReadValuesIB(self,PowerUnitID=1):
        pls = self.ReadPowerLatchStatus(PowerUnitID)
        bls = self.ReadBiasLatchStatus(PowerUnitID)
        avdd_voltage = self.ReadPowerADCChannel(0)
        avdd_current = self.ReadPowerADCChannel(1)
        dvdd_voltage = self.ReadPowerADCChannel(2)
        dvdd_current = self.ReadPowerADCChannel(3)
        bb_voltage = self.ReadBiasADCChannel(2)
        bb_current = self.ReadBiasADCChannel(0)
        values = OrderedDict([
            ("Powerlatch_status" , pls),
            ("Biaslatch_status"  , bls),
            ("dvdd_voltage" , dvdd_voltage),
            ("avdd_voltage" , avdd_voltage),
            ("dvdd_current" , dvdd_current),
            ("avdd_current" , avdd_current),
            ("bb_voltage"   , bb_voltage),
            ("bb_current"   , bb_current)
        ])

        return values

    def RaiseThresholdsToMax(self, PowerUnitID = 1):
        """Set current thresholds of all channels to 0xffff, PowerUnitID = <1,2>"""
        mod = self.module_id + PowerUnitID
        byte1 = 0x3f
        byte2 = 0xff
        byte3 = 0xff

        self.comm.register_write(mod, 0, byte1)

        data = (byte2<<8) | byte3
        self.comm.register_write(mod,self.ThresCurrAddress[0], data)
        self.comm.register_write(mod,self.ThresCurrAddress[1], data)
        self.comm.register_write(mod,self.ThresCurrAddress[2], data)
        self.comm.register_write(mod,self.ThresCurrAddress[3], data)
        self.comm.flush()

    def LowerThresholdsToMin(self, PowerUnitID = 1):
        """Set current thresholds of all channels to 0x0000, PowerUnitID = <1,2>"""
        mod = self.module_id + PowerUnitID
        byte1 = 0x3f
        byte2 = 0x00
        byte3 = 0x00

        self.comm.register_write(mod, 0, byte1)

        data = (byte2<<8) | byte3
        self.comm.register_write(mod,self.ThresCurrAddress[0], data)
        self.comm.register_write(mod,self.ThresCurrAddress[1], data)
        self.comm.register_write(mod,self.ThresCurrAddress[2], data)
        self.comm.register_write(mod,self.ThresCurrAddress[3], data)
        self.comm.flush()

    def SetThreshold(self, channel, value, PowerUnitID = 1):
        """Set threshold of channel 'channel' to 'value'; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        byte1 = (0x3<<4) | (channel%4)
        byte2 = (value>>4) & 0xff
        byte3 = (value&0xf)<<4

        self.comm.register_write(mod, 0, byte1)

        data = (byte2<<8) | byte3
        self.comm.register_write(mod,self.ThresCurrAddress[int(channel/4)], data)
        self.comm.flush()

    def SetThresholdWithMask(self, mask, value, PowerUnitID=1):
        """Set threshold of each channel of bitposition in 'mask' to 'value'; PowerUnitID=<1,2>"""
        for i in range(16):
            if ((mask>>i) & 1):
                self.SetThreshold(i, value, PowerUnitID)

    def SetThresholdAll(self, value, PowerUnitID=1):
       """Set threshold of all channels to 'value'; PowerUnitID=<1,2>"""
       mod = self.module_id + PowerUnitID
       byte1 = 0x3f
       byte2 = (value>>4) & 0xff
       byte3 = (value&0xf)<<4

       self.comm.register_write(mod, 0, byte1)

       data = (byte2<<8) | byte3
       self.comm.register_write(mod,self.ThresCurrAddress[0], data)
       self.comm.register_write(mod,self.ThresCurrAddress[1], data)
       self.comm.register_write(mod,self.ThresCurrAddress[2], data)
       self.comm.register_write(mod,self.ThresCurrAddress[3], data)
       self.comm.flush()

    def UnlatchPowerAll(self, PowerUnitID=1):
        """Unlatch all power channels for PowerUnitID (<1,2>)"""
        mod = self.module_id + PowerUnitID
        byte3 = 0xff
        self.comm.register_write(mod, self.IOExpanderPowerAddress[0], byte3)
        self.comm.register_write(mod, self.IOExpanderPowerAddress[1], byte3)
        self.comm.flush()

    def UnlatchBiasAll(self, PowerUnitID=1):
        """Unlatch all bias channels for PowerUnitID (<1,2>)"""
        mod = self.module_id + PowerUnitID
        byte3 = 0x00
        self.comm.single_write(mod, self.IOExpanderBiasAddress, byte3)

    def UnlatchPower(self, channel, PowerUnitID=1):
        """Unlatch power channel 'channel' for PowerUnitID (<1,2>)"""
        mod = self.module_id + PowerUnitID
        byte3 = 0x01<<(channel%8)
        self.comm.single_write(mod, self.IOExpanderPowerAddress[int(channel/8)], byte3)

    def UnlatchPowerWithMask(self, mask, PowerUnitID=1):
        """Unlatch each power channel of bitposition in 'mask'; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        if (mask & 0xFF):
            byte3 = mask & 0xff
            self.comm.register_write(mod, self.IOExpanderPowerAddress[0], byte3)
        if ((mask>>8) & 0xFF):
            byte3 = (mask>>8) & 0xff
            self.comm.register_write(mod, self.IOExpanderPowerAddress[1], byte3)
        self.comm.flush()

    def UnlatchBias(self, channel, PowerUnitID=1):
        """Unlatch each bias channel of bitposition in 'mask'; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        byte3 = 0xff^2**channel
        self.comm.single_write(mod, self.IOExpanderBiasAddress, byte3)

    def DisablePowerAll(self, PowerUnitID=1):
        """Latch (disable) each power channel; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        byte3 = 0x00
        self.comm.register_write(mod, self.IOExpanderPowerAddress[0], byte3)
        self.comm.register_write(mod, self.IOExpanderPowerAddress[1], byte3)
        self.comm.flush()

    def DisableBiasAll(self, PowerUnitID=1):
        """Latch (disable) each bias channel; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        byte3 = 0xff
        self.comm.single_write(mod, self.IOExpanderBiasAddress, byte3)

    def SetPowerVoltage(self, channel, voltage, PowerUnitID=1):
        """Set output voltage setting of power 'channel' to 'voltage'; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        byte2 = channel%4
        byte3 = voltage & 0xFF
        data = (byte2<<8) | byte3
        self.comm.single_write(mod, self.PotPowerAddress[int(channel/4)], data)

    def SetPowerVoltageAll(self, voltage, PowerUnitID=1):
        """Set output voltage setting of all power channels to 'voltage'; PowerUnitID=<1,2>"""
        for channel in range(16):
            self.SetPowerVoltage(channel, voltage, PowerUnitID)

    def SetBiasVoltage(self, voltage, PowerUnitID=1):
        """Set output voltage setting of bias channels to 'voltage'; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        byte2 = 0x11
        byte3 = voltage & 0xFF
        data = (byte2<<8) | byte3
        self.comm.single_write(mod, self.PotBiasAddress, data)


    def ConfigurePowerADC(self, PowerUnitID=1):
        """Configure control registers of all Power ADCs; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        for SlaveAddress in self.ADCAddressSetup:
            byte2 = 0x0B
            byte3 = 0x02
            data = (byte2<<8) | byte3
            self.comm.register_write(mod, SlaveAddress, data)
            byte2 = 0x00
            byte3 = 0x01
            data = (byte2<<8) | byte3
            self.comm.register_write(mod, SlaveAddress, data)
        self.comm.flush()

    def ConfigureBiasADC(self, PowerUnitID=1):
        """Configure control registers of all Bias ADCs; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        SlaveAddress = self.ADCBiasAddressSetup
        byte2 = 0x0B
        byte3 = 0x02
        data = (byte2<<8) | byte3
        self.comm.register_write(mod, SlaveAddress, data)
        byte2 = 0x00
        byte3 = 0x01
        data = (byte2<<8) | byte3
        self.comm.register_write(mod, SlaveAddress, data)
        self.comm.flush()


    # Read transactions
    def ReadPowerLatchStatus(self, PowerUnitID=1):
        """Read latch status of all power channels as a mask; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        results = self.comm.single_read(mod,self.IOExpanderPowerAddress[0]) & 0xFF
        results = results | ((self.comm.single_read(mod,self.IOExpanderPowerAddress[1]) & 0xFF)<<8)
        return results

    def ReadBiasLatchStatus(self, PowerUnitID=1):
        """Read latch status of all bias channels as a mask; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        results = self.comm.single_read(mod,self.IOExpanderBiasAddress) & 0xFF
        return results

    def ReadPowerADC(self, PowerUnitID=1):
        """Trigger ADC conversion and readout of all Power ADC channels; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        ADCData = []
        for SlaveAddress in self.ADCAddress:
            for channel in range(8):
                byte3 = 0x20 + channel
                self.comm.single_write(mod, SlaveAddress, byte3)
                ADCValue = self.comm.single_read(mod,SlaveAddress)
                ADCData.append(ADCValue>>4)
                # convert to V or A
                #if channel%2:  # current measurements
                #    ADCData.append( (((ADCValue>>4)/4096.)*2.56 - 0.25)/(0.005*150) )
                #else:  # voltage measurements
                #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
        return ADCData

    def ReadBiasADC(self, PowerUnitID=1):
        """Trigger ADC conversion and readout of all Bias ADC channels; PowerUnitID=<1,2>"""
        mod = self.module_id + PowerUnitID
        ADCData = []
        SlaveAddress = self.ADCBiasAddress
        for channel in range(0,3,2):
            byte3 = 0x20 + channel
            self.comm.single_write(mod, SlaveAddress, byte3)
            ADCValue = self.comm.single_read(mod,SlaveAddress)
            ADCData.append(ADCValue>>4)
            # convert to V or A
            #if channel%2:
            #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
            #else:
            #    ADCData.append( -((ADCValue>>4)/4096.)*5.12 )
        return ADCData

    def ReadPowerADCChannel(self, channel, PowerUnitID=1):
        """Trigger ADC conversion and readout a Power ADC channel; PowerUnitID=<1,2>"""
        assert channel < 32, "channel must be < 2"
        mod = self.module_id + PowerUnitID
        byte3 = 0x20 + (channel%8)
        SlaveAddress = self.ADCAddress[int(channel/8)]
        self.comm.single_write(mod, SlaveAddress, byte3)
        ADCValue = self.comm.single_read(mod,SlaveAddress)
        ADCData = ADCValue>>4
        # convert to V or A
        #if channel%2:  # current measurements
        #    ADCData.append( (((ADCValue>>4)/4096.)*2.56 - 0.25)/(0.005*150) )
        #else:  # voltage measurements
        #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
        return ADCData

    def ReadBiasADCChannel(self, channel, PowerUnitID=1):
        """Trigger ADC conversion and readout of a Bias ADC channel; PowerUnitID=<1,2>"""
        assert channel<3, "channel must be < 3"
        mod = self.module_id + PowerUnitID
        SlaveAddress = self.ADCBiasAddress
        byte3 = 0x20 + channel
        self.comm.single_write(mod, SlaveAddress, byte3)
        ADCValue = self.comm.single_read(mod,SlaveAddress)
        ADCData = ADCValue>>4
        # convert to V or A
        #if channel%2:
        #    ADCData.append( ((ADCValue>>4)/4096.)*2.56 )
        #else:
        #    ADCData.append( -((ADCValue>>4)/4096.)*5.12 )
        return ADCData

