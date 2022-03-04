"""file implementing the control for the ws_i2_gbt wishbone slave"""

from enum import IntEnum
from wishbone_module import WishboneModule
import time
from xml.dom import minidom

class WsI2cGbtxAddress(IntEnum):
    """memory mapping for the ws_i2gbtx got from ?"""
    ADDRESS_GBTX0 = 0
    ADDRESS_GBTX1 = 1
    ADDRESS_GBTX2 = 2
    DATA          = 3

class WsI2cGbtx(WishboneModule):
    """wishbone slave instatiated inside the usb_if executing the control over
    the DP2, DP3 fifos and the DP1, DP0 errors"""

    def __init__(self, moduleid, board_obj):
        """init"""
        super(WsI2cGbtx, self).__init__(moduleid=moduleid, name="Wishbone i2gbtx", board_obj=board_obj)

    def set_address(self, address, gbtx=0, commitTransaction=True):
        """Sets the address for the next I2C transaction in GBTx gbtx """
        assert address | 0xFFFF == 0xFFFF
        self.write(WsI2cGbtxAddress.ADDRESS_GBTX0 + gbtx, address, commitTransaction=commitTransaction)

    def get_address(self, gbtx=0, commitTransaction=True):
        """Gets the address for the next I2C transaction"""
        return self.read(WsI2cGbtxAddress.ADDRESS_GBTX0 + gbtx, commitTransaction=commitTransaction)

    def _write_data(self, data, commitTransaction=True):
        """Writes the data to the corresponding GBTx register set in the last set_address
        operation (if no write/read happened in between)

        NOTE: this operation increases the address by 1!"""
        self.write(WsI2cGbtxAddress.DATA, data, commitTransaction=commitTransaction)

    def _read_data(self, commitTransaction=True):
        """Writes the data to the corresponding GBTx register set in the last set_address
        operation (if no write/read happened in between)

        NOTE: this operation increases the address by 1!"""
        return self.read(WsI2cGbtxAddress.DATA, commitTransaction=commitTransaction)

    def write_data(self, gbtx, address, data, commitTransaction=True):
        """Writes the data to the corresponding GBTx register"""
        self.set_address(address, gbtx, commitTransaction=False)
        self._write_data(data, commitTransaction=commitTransaction)

    def read_data(self, gbtx, address, commitTransaction=True):
        """Reads the data to the corresponding GBTx register"""
        self.set_address(address, gbtx, commitTransaction=False)
        return self._read_data(commitTransaction=commitTransaction)

    def get_phase_detector_charge_pump(self, gbtx):
        """read the phase detector charge pump value of gbtx"""
        return((self.read_data(gbtx, 35))>>4)

    def set_phase_detector_charge_pump(self, gbtx, value):
        """set the GBTx charge pump value of gbtx"""
        assert value | 0xf == 0xf
        current_val = self.read_data(gbtx, 35)
        new_val = (current_val & 0x0f) | (value<<4)
        self.write_data(gbtx, 35, new_val)

    def dump_gbtx_config(self, gbtx):
        """Dump the modules state and configuration as a string"""
        assert gbtx in range(3)
        GBTx_REG_MAX = 435
        SINGLE_I2C_TRANSACTION_TIME = 72000 # in WB_CLK clock cycles
        waittime = GBTx_REG_MAX*SINGLE_I2C_TRANSACTION_TIME
        config_str = "--- GBTx {0} ASIC ---\n".format(gbtx)
        config_str += "  - :\n"
        self.set_address(address=0, gbtx=gbtx, commitTransaction=False)
        for address in range(GBTx_REG_MAX):
            self._read_data(commitTransaction=False)
        #self.firmware_wait(waittime)
        self.flush()
        time.sleep(waittime*6.25e-9)
        results = self.read_all()
        for address in range(GBTx_REG_MAX):
            value = results[address]
            config_str += "    - {0} : {1:#06X}\n".format(address, value)
        return config_str


    def dump_config(self):
        """Dump the modules state and configuration as a string"""
        config_str = "--- I2C GBT module ---\n"
        config_str += "  - Write phase register:\n"
        for address in WsI2cGbtxAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#06X}\n".format(name, value)
        return config_str

    def gbtx_config(self, filename, gbtx=0):
        """Write GBTx xml configuration data in file "filename" to GBTx "gbtx" """
        assert gbtx in range(3)

        xmldoc = minidom.parse(filename)
        signalList = xmldoc.getElementsByTagName("Signal")

        reg = [0] * 366
        for signal in signalList:
            name = signal.attributes["name"].value
            tripl = True if (signal.attributes["triplicated"].value == "true") else False
            nob = int(signal.attributes["numberBits"].value)
            val = int(signal.getElementsByTagName("value")[0].firstChild.data)
            startAddr0 = int(signal.getElementsByTagName("location")[0].getAttribute("startAddress"))
            startBit0 = int(signal.getElementsByTagName("location")[0].getAttribute("startBitIndex"))
            lastBit0 = int(signal.getElementsByTagName("location")[0].getAttribute("lastBitIndex"))
            reg[startAddr0] |= (val << startBit0)
            if tripl:
                startAddr1 = int(signal.getElementsByTagName("location")[1].getAttribute("startAddress"))
                startBit1 = int(signal.getElementsByTagName("location")[1].getAttribute("startBitIndex"))
                lastBit1 = int(signal.getElementsByTagName("location")[1].getAttribute("lastBitIndex"))
                reg[startAddr1] |= val << startBit1

                startAddr2 = int(signal.getElementsByTagName("location")[2].getAttribute("startAddress"))
                startBit2 = int(signal.getElementsByTagName("location")[2].getAttribute("startBitIndex"))
                lastBit2 = int(signal.getElementsByTagName("location")[2].getAttribute("lastBitIndex"))
                reg[startAddr2] |= val << startBit2


        # set address of appropriate GBTx to 0
        self.set_address(0, gbtx, False)

        # write registers (firmware auto-increments)
        for r in reg:
            self._write_data(r, False)

        self.flush()
