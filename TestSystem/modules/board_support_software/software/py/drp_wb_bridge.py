"""Class to implement MGT DRP-wishbone bridge"""

from wishbone_module import WishboneModule
from enum import IntEnum

class WsDrpWbAddress(IntEnum):
  TMR_REGADDR_MISC = 0;
  DRP_REGADDR_ADDR = 1;
  DRP_REGADDR_DATA = 2;


class WsDrpCtrl(WishboneModule):
    """DRP Wishbone Slave"""

    def __init__(self, moduleid, board_obj):
        super(WsDrpCtrl, self).__init__(moduleid=moduleid, name="DRP_WB_Slave", board_obj=board_obj)

    def write_drp(self, address, data, transceiver=0, commitTransaction=True):
        """Write to the drp port of "transceiver" (defaults to 0)"""
        assert transceiver < 28, "transceiver must be  between 0 and 27"
        address = address & 0x1FF
        address |= (transceiver<<9)
        data = data & 0xFFFF
        self.write(WsDrpWbAddress.DRP_REGADDR_ADDR, address, False)
        self.write(WsDrpWbAddress.DRP_REGADDR_DATA, data, commitTransaction)

    def read_drp(self, address, transceiver=0, commitTransaction=True):
        """Read from the drp port of "transceiver" (defaults to 0)"""
        assert transceiver < 28, "transceiver must be  between 0 and 27"
        address = address & 0x1FF
        address |= (transceiver<<9)
        self.write(WsDrpWbAddress.DRP_REGADDR_ADDR, address, False)
        return self.read(WsDrpWbAddress.DRP_REGADDR_DATA, commitTransaction=commitTransaction)

    def read_prbs_counter(self, transceiver=0):
        self.read_drp(0x15E, transceiver, False)
        self.read_drp(0x15F ,transceiver, False)
        results = self.read_all()
        return (results[1]<<15 | results[0])
