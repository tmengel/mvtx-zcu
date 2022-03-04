#!/usr/bin/env python

from VivadoTCPClientLib import VivadoTCPClientLib
from collections import OrderedDict


class ScaComm(VivadoTCPClientLib):

    def __init__(self, ip='127.0.0.1', port=8555, end=1):
        VivadoTCPClientLib.__init__(self, ip, port, end)

    def init_sca(self):
        self.write_vio('testPatterSel_from_user', 3)
        self.write_ctrl_reg(50, 0x1)  # SCA reset
        self.write_ctrl_reg(50, 0x2)  # SCA connect
        self.read_ctrl_reg(48)  # clear received status bit

    def sca_write(self, channel, tid, cmd, data):
        self.write_ctrl_reg(49, data)
        self.write_ctrl_reg(48, (cmd << 16) + (channel << 8) + tid)
        self.write_ctrl_reg(50, 0x4)

    def sca_read(self):
        sca_status = self.read_ctrl_reg(48)
        sca_data = -1
        if sca_status & 0x80000000 == 0x80000000:
            sca_data = self.read_ctrl_reg(49)
        ret = OrderedDict([
            ("Received", sca_status >> 31),
            ("Error", (sca_status >> 16) & 0xff),
            ("TID", sca_status & 0xff),
            ("Channel", (sca_status >> 8) & 0xff),
            ("Data", sca_data)
        ])
        return ret

    def initialize_adc_channel(self):
        self.sca_write(channel=0x0, tid=0x03, cmd=0x06, data=0xff000000)
        print(self.sca_read())
        self.sca_write(channel=0x14, tid=0x2, cmd=0x60, data=0x01800000)
        return self.sca_read()

    def read_adc_channel(self, adc_ch):
        self.sca_write(channel=0x14, tid=0x08, cmd=0x50, data=adc_ch)
        print(self.sca_read())
        self.sca_write(channel=0x14, tid=0x07, cmd=0x02, data=0x00000001)
        ret = self.sca_read()
        if ret['Received'] == 1:
            if adc_ch == 15:
                results = 21.0 * ret['Data'] / 4095.0
            elif adc_ch == 31:
                results = (716 - 1000 * ret['Data'] / 4095.0) / 1.829
            elif adc_ch == 23 or adc_ch == 24:
                results = 0.634286 * ret['Data'] - 259.74
            elif adc_ch == 16 or adc_ch == 17:
                results = 532.0 - 0.163 * ret['Data']
            elif adc_ch < 13 and adc_ch > 7:
                results = 2.0 * ret['Data'] / 4095.0
            else:
                results = 5.0 * ret['Data'] / 4095.0
        else:
            results = ret
        return results
