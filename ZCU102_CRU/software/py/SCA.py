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
