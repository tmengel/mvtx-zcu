""" Generic I2C module

"""

import collections
import logging

from wishbone_module import WishboneModule


class I2CModule(WishboneModule):
    """Class to handle I2C modules"""

    def __init__(self, moduleid, board_obj):
        super(I2CModule, self).__init__(moduleid=moduleid, board_obj=board_obj, name="I2C")


    def dump_config(self):
        config_str = "--- I2C module ---\n"
        return config_str
