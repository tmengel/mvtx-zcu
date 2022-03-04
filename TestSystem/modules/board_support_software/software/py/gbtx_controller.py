"""Class to implement the latest capabilities of the GBTxController"""

from wishbone_module import WishboneModule
from enum import IntEnum

class WsGbtxControllerAddress(IntEnum):
    """memory mapping for gbtx controller module"""
    GBTX_CONTROLLER_ENABLE = 0x00
    GBTX_RESET             = 0x01
    SET_IDELAY_VALUE0      = 0x02
    SET_IDELAY_VALUE1      = 0x03
    SET_IDELAY_VALUE2      = 0x04
    SET_IDELAY_VALUE3      = 0x05
    SET_IDELAY_VALUE4      = 0x06
    SET_IDELAY_VALUE5      = 0x07
    SET_IDELAY_VALUE6      = 0x08
    SET_IDELAY_VALUE7      = 0x09
    SET_IDELAY_VALUE8      = 0x0A
    SET_IDELAY_VALUE9      = 0x0B
    GET_IDELAY_VALUE0      = 0x0C
    GET_IDELAY_VALUE1      = 0x0D
    GET_IDELAY_VALUE2      = 0x0E
    GET_IDELAY_VALUE3      = 0x0F
    GET_IDELAY_VALUE4      = 0x10
    GET_IDELAY_VALUE5      = 0x11
    GET_IDELAY_VALUE6      = 0x12
    GET_IDELAY_VALUE7      = 0x13
    GET_IDELAY_VALUE8      = 0x14
    GET_IDELAY_VALUE9      = 0x15
    IDELAY_LOAD            = 0x16
    BITSLIP_RX_VALUE       = 0x17
    BITSLIP_TX_VALUE       = 0x18
    BITSLIP_LOAD           = 0x19
    TX_PATTERN_SELECTION   = 0x1A
    TX1_PATTERN_SELECTION  = 0x1B
    MISMATCH               = 0x1C
    NUM_REGS               = 0x1D

class GBTxController(WishboneModule):
    """GBTx controller wishbone slave"""

    def __init__(self, moduleid, board_obj):
        super(GBTxController, self).__init__(moduleid=moduleid, name="GBTxController", board_obj=board_obj)
        self.verbose = False

    def enable_controller(self, commitTransaction=True):
        """Enables the gbtx controller"""
        self.write(WsGbtxControllerAddress.GBTX_CONTROLLER_ENABLE, 1, commitTransaction=commitTransaction)

    def disable_controller(self, commitTransaction=True):
        """Enables the gbtx controller"""
        self.write(WsGbtxControllerAddress.GBTX_CONTROLLER_ENABLE, 0, commitTransaction=commitTransaction)

    def reset_gbtx_asic(self, commitTransaction=True):
        """Resets the GBTx ASIC"""
        self.write(WsGbtxControllerAddress.GBTX_RESET, 0b0, commitTransaction=commitTransaction)
        self.write(WsGbtxControllerAddress.GBTX_RESET, 0b1, commitTransaction=commitTransaction)

    def _load_idelay(self, commitTransaction=True):
        """commits the idelay value into the IDELAY"""
        self.write(WsGbtxControllerAddress.IDELAY_LOAD, 1, commitTransaction=commitTransaction)

    def _set_idelay_value_i(self, i, idelayi=None, commitTransaction=True):
        """sets the input delay for ports of the i_th group"""
        assert idelayi | 0x1FF == 0x1FF
        assert i in range(10)
        self.write(WsGbtxControllerAddress.SET_IDELAY_VALUE0+i, idelayi, commitTransaction=commitTransaction)

    def set_idelay(self, idelays=10*[None], idelay_all=None, commitTransaction=True):
        """sets the input delay of all the elinks groups ports, in they are not None"""
        if idelay_all is not None:
            idelays = 10*[idelay_all]
        for i in range(10):
            if idelays[i] is not None:
                self._set_idelay_value_i(i=i, idelayi=idelays[i], commitTransaction=commitTransaction)
        self._load_idelay(commitTransaction=commitTransaction)

    def get_idelay(self):
        """gets the idelay values and check if values are consistent,
        returns a tuple with the idelays 0 to 9"""
        idelay = idelay_read = 10*[None]
        for i in range(10):
            idelay[i] = self.read(WsGbtxControllerAddress.SET_IDELAY_VALUE0 + i)
            idelay_read[i] = self.read(WsGbtxControllerAddress.GET_IDELAY_VALUE0 + i)
        for i in range(10):
            assert idelay[i] == idelay_read[i], "idelay{0} value set is not consisistend with read value: SET {1} GET {2}".format(i, idelay[i], idelay_read[i])
        return idelay_read

    def _load_bitslip(self, commitTransaction=True):
        """Loads the bitslip values for RX and TX in the GBTx controller"""
        self.write(WsGbtxControllerAddress.BITSLIP_LOAD, 1, commitTransaction=False)
        self.write(WsGbtxControllerAddress.BITSLIP_LOAD, 0, commitTransaction=commitTransaction)

    def set_bitslip_rx(self, value, commitTransaction=True):
        """sets the bitslip value in rx to be used on the GBTx module"""
        assert value | 0x7 == 0x7
        self.write(WsGbtxControllerAddress.BITSLIP_RX_VALUE, value, commitTransaction=False)
        self._load_bitslip(commitTransaction=commitTransaction)

    def get_bitslip_rx(self):
        """gets the bitslip value in rx to be used on the GBTx module"""
        return self.read(WsGbtxControllerAddress.BITSLIP_RX_VALUE)

    def set_bitslip_tx(self, value, commitTransaction=True):
        """sets the bitslip value in tx to be used on the GBTx module"""
        assert value | 0x7 == 0x7
        self.write(WsGbtxControllerAddress.BITSLIP_TX_VALUE, value, commitTransaction=False)
        self._load_bitslip(commitTransaction=commitTransaction)

    def get_bitslip_tx(self):
        """gets the bitslip value in tx to be used on the GBTx module"""
        return self.read(WsGbtxControllerAddress.BITSLIP_TX_VALUE)

    def set_tx_pattern(self, value, commitTransaction=True):
        """sets the transmission pattern to be used on the GBTx module"""
        assert value | 0x3 == 0x3
        self.write(WsGbtxControllerAddress.TX_PATTERN_SELECTION, value, commitTransaction=commitTransaction)

    def get_tx_pattern(self):
        """gets the transmission pattern to be used on the GBTx module"""
        return self.read(WsGbtxControllerAddress.TX_PATTERN_SELECTION)

    def set_tx1_pattern(self, value, commitTransaction=True):
        """sets the transmission pattern to be used on the GBTx module"""
        assert value | 0x3 == 0x3
        self.write(WsGbtxControllerAddress.TX1_PATTERN_SELECTION, value, commitTransaction=commitTransaction)

    def get_tx1_pattern(self):
        """gets the transmission pattern to be used on the GBTx module"""
        return self.read(WsGbtxControllerAddress.TX1_PATTERN_SELECTION)

    def get_mismatch(self):
        """returns the mismatch flags for the gbtx module.
        Returns a tuple containing a dictionary, and the bare value of the register read"""
        C_MISMATCH_bit_WISHBONE    = 0
        C_MISMATCH_bit_HANDLER     = 1
        C_MISMATCH_bit_BITSLIP_FSM = 2
        C_MISMATCH_bit_FIFO        = 3
        value = self.read(WsGbtxControllerAddress.MISMATCH)
        ret = {}
        ret['Wishbone'] = value >> C_MISMATCH_bit_WISHBONE & 0x1
        ret['Handler'] = value >> C_MISMATCH_bit_HANDLER & 0x1
        ret['Bitslip_Fsm'] = value >> C_MISMATCH_bit_BITSLIP_FSM & 0x1
        ret['Fifo'] = value >> C_MISMATCH_bit_FIFO & 0x1
        return (ret, value)

    def dump_config(self):
        config_str = "--- GBTx controller module ---\n"

        config_str += "  - Write phase register:\n"
        for address in WsGbtxControllerAddress:
            name = address.name
            value = self.read(address.value)
            config_str += "    - {0} : {1:#X}\n".format(name, value)
        return config_str
