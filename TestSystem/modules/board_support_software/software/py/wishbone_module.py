"""Abstraction of a wishbone accessed module.

Provides Read/Write functionality to a module with given module_id on
construction time.

"""

import logging

class WishboneModule(object):
    """ Abstract wishbone module providing basic communication functions """

    def __init__(self, moduleid, name, board_obj):
        self.moduleid = moduleid
        self.board = board_obj
        self.comm = self.board.comm
        self.logger = logging.getLogger("Module Id {0}: {1}".format(moduleid, name))

    def write(self, addr, data, commitTransaction=True):
        """Write to a specific address of the module. Optionally commit transaction"""
        self.logger.debug("Writing reg \t0x{0:02X}{1:02X}, value \t0x{2:04X}".format(self.moduleid, addr, data))
        self.comm.register_write(self.moduleid, addr, data)
        if commitTransaction:
            self.comm.flush()

    def read(self, addr, commitTransaction=True):
        """Read from a specific address from the module. Optionally commit transaction"""
        self.logger.debug("Reading reg\t0x{0:02X}{1:02X}, not_committed".format(self.moduleid, addr))
        self.comm.register_read(self.moduleid, addr)
        if commitTransaction:
            self.comm.flush()
            ret = self.comm.read_results()
            if len(ret) != 1:
                print("Unexpected length of result: {0}, expected length 1; ignore further results".format(
                    len(ret)))
                print(ret)
            if len(ret) == 0:
                data = None
            else:
                data = ret[0][1]
            self.logger.debug("Reading reg\t0x{0:02X}{1:02X}, value 0x{2:04X}".format(self.moduleid, addr, data))
            return data
        else:
            return None

    def flush(self):
        """Flush all pending transactions."""
        self.comm.flush()

    def firmware_wait(self, wait_value, commitTransaction=True):
        """Execute a wait of wait_value*6.25 ns"""
        self.board.wait(wait_value, commitTransaction=commitTransaction)

    def read_all(self):
        """Read all results after a flush()"""
        self.comm.flush()
        ret = self.comm.read_results()
        data = []
        for item in ret:
            data.append(item[1])
        return data

    def dump_config(self):
        """Dump the modules state and configuration as a string"""
        return "Not implemented yet\n"
