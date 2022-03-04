#!/usr/bin/env python

from driver_comm import DriverComm

# -------------------------------------------------------------
#  ------------------- Class LPGBT (low-layer) ---------------
# -------------------------------------------------------------


class VivadoTCPClientLib(DriverComm):

    def __init__(self, ip='127.0.0.1', port=8555, end=1):
        DriverComm.__init__(self, ip, port, end)
        self.c_ADDR_OFFSET = 0x00000000

    def configure_fpga(self, project_name, bitfile_name):
        message = "configure %s %s\n" % (project_name, bitfile_name)
        # print("%s" %(message))
        self.disableTimeout()
        data = self.query(message)
        self.enableTimeout(10)
        data = int(data)
        return data

    def exit(self):
        message = "exit\n"
        self.send(message)

    def read_vio(self, signal):
        message = "rvio %s\n" %(signal)
        data = self.query(message)
        datalng = int(data,16)
        return datalng

    def write_vio(self, signal, value):
        message = "wvio %s 0x%0.8X\n" %(signal, value)
        data = self.query(message)
        data = int(data)
        return data

    def write_ctrl_reg(self, reg_addr, reg_value):
        message = "w 0x%0.8X 0x%0.8X\n" % (reg_addr + self.c_ADDR_OFFSET, reg_value)
        # print("%s" %(message))
        data = self.query(message)
        data = int(data)
        return data

    def read_ctrl_reg(self, reg_addr):
        message = "r 0x%0.8X\n" % (reg_addr + self.c_ADDR_OFFSET)
        data = self.query(message)
        data = int(data, 16)
        return data

    def ping(self):
        message = "ping\n"
        data = self.query(message)
        print("ping message return :", data)
