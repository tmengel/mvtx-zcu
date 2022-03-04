"""!@file verbosefilter.py : classes for holding register descriptions.
8/15/18:15
@author = Magnus (magnus.ersdal@uib.no)
"""
from collections import namedtuple

Range = namedtuple("bitrange", "min max")


class RegisterDescription:
    """Individual descriptions on a bitfield range"""

    def __init__(self, minpos, maxpos, description_text, reg_width):
        self.range = Range(minpos, maxpos)
        self.text = description_text
        self.reg_width = reg_width

    def in_range(self, value):
        """see if this item is in range"""
        bval = list(bin(value)[2:])
        bval.reverse()
        relevant_digits = bval[self.range.min:self.range.max + 1]
        return '1' in relevant_digits

    def old_in_range(self, value):
        return "1" in bin(self.filter(value))

    def filter(self, value):
        try:
            binn = bin(value)[2:]
            totlen = self.reg_width
            binn = "{:0{length}b}".format(value, length=totlen)
            filtered_n = binn[totlen - self.range.min - 1:totlen - self.range.max]  # for correct endian-ness
            print("filered_n:", filtered_n, self.text, self.reg_width)
            if int(filtered_n, 2) != 0:
                pass
            return int(filtered_n, 2)
        except ValueError:
            return 0


class VerboseFilter:
    """All description fields over the total range of a single register"""

    def __init__(self, registername, descriptionlist, register_width, docstr, offset=0):
        self.name = registername
        self.descr = descriptionlist
        self.desc_items = []
        self.docstr = docstr

        for desc in self.descr:
            split = desc.find("]")
            position_str = desc[1:split]
            text_str = desc[split + 1:]
            positions = [int(x) for x in position_str.split(":")]
            maxpos = max(positions)  # - offset
            minpos = min(positions)  # - offset
            self.desc_items.append(
                RegisterDescription(minpos, maxpos, description_text=text_str, reg_width=register_width))

    def verbose_print(self, data):
        print(self.name, self.docstr)
        for this_desc in self.desc_items:
            if this_desc.in_range(data):
                infodata = [this_desc.text, this_desc.range.max, this_desc.range.min, data]
                estr = 'Field \"{:<40}\" {} downto {} is high, data: 0x{:02X}'.format(*infodata)
                print(estr)

    def print_all_fields(self):
        print(self.name, self.docstr)
        for this_desc in self.desc_items:
            infodata = [this_desc.range.max, this_desc.range.min, this_desc.text]
            print("[{}:{}] -> {}".format(*infodata))

    def get_all_fields(self):
        """get all fields, excluding name of course"""
        strs = []
        for this_desc in self.desc_items:
            infodata = [this_desc.range.max, this_desc.range.min, this_desc.text]
            strs.append("[{}:{}] -> {};".format(*infodata))
        return "".join(strs)

class EmptyVerboseFilter():
    def __init__(self, registername, docstr="no description"):
        self.name = registername
        self.descr = docstr
        self.desc_items = []
        self.docstr = ""

    def verbose_print(self, data):
        print(self.name, hex(data))

    def print_all_fields(self):
        print(self.name, self.descr)

    def get_all_fields(self):
        return "_"
