"""
register_cls.py :
This is a dynamic class for making "register" objects, collected into a RegisterSet class.
It is set up in setup_registers.py
Be aware that this kind of dynamic functionality is termed an "anti-pattern" because its attributes are not static,
and the usage of this might lead to very confusing code.
In this case, it is made for the purpose of representing registers, that are read from a _pkg.vhd file on the fly.
though this might change in the future.
8/9/18:10
__author__ = Magnus (magnus.ersdal@uib.no)
"""
from collections import namedtuple
import sys

Rw_params = namedtuple('rw', 'r w')
import re

clean = lambda varStr: re.sub('\W|^(?=\d)', '_', varStr)


class Register:
    def __init__(self, name, adr, defaultvalue=None, rw=Rw_params(r=True, w=False), defaultmethod=None, readmethod=None,
                 writemethod=None, bitmask=None, bitlength=32, ignorepoll=False, verbosefilter=None, regtype=None,
                 opcodes=None):
        """ Name and adr are mandatory, the rest is sugar \n
            The readmethod MUST be a f(adr) that returns the data \n
            The writemethod MUST be a f(adr,data)"""
        # self.docstr = docstr
        self.name = name
        self.adr = adr
        self.data = defaultvalue
        self.rw = rw
        self.callmethod = defaultmethod
        self.readf = readmethod
        self.writef = writemethod
        self.bitlength = bitlength
        self.verbosefilter = verbosefilter
        self.regtype = regtype
        self.opcodes = []
        if bitmask:
            self.bitmask = bitmask
        else:
            self.bitmask = 0
        if ignorepoll:
            self.poll = lambda x: True  # should overwrite polling functionality.
        if opcodes:
            for opc in opcodes:
                # oc = Opcode(desc=cmd, code=val, hex=hex(val))
                try:
                    desc = clean(opc[0])
                    code = opc[1]
                    setattr(self, desc, code)
                    self.opcodes.append((desc, hex(code)))
                except TypeError:
                    pass

    def __call__(self, *args, **kwargs):
        return self.adr
        # return "Reg {2} {0}/0x{0:X} with data {1}/0x{1:X}".format(self.addr, self.data, self.name)

    def __str__(self):
        return str(self.adr)

    def __int__(self):
        return self.adr

    def __hex__(self):
        return hex(self.adr)

    def getobj(self):
        """just an alias of repr"""
        return self.__repr__()

    def read(self):
        self.data = self.readf(self.adr)
        return self.data

    def verbose_read(self, override_data=0):
        if override_data:
            data = override_data
        else:
            data = self.read()
        self.verbosefilter.verbose_print(data)

    def disp_fields(self):
        self.verbosefilter.print_all_fields()

    def disp_opcodes(self):
        if self.opcodes:
            for oc in self.opcodes:
                print(oc)
        elif self.regtype == "CMD":
            self.disp_fields()

    def get_opcodes(self):
        ocs = ""
        if self.opcodes:
            for oc in self.opcodes:
                ocs += str(oc) + ";"
        elif self.regtype == "CMD":
            ocs = self.verbosefilter.get_all_fields()
        return ocs

    def write(self, data):
        try:
            self.writef(self.adr, data)
        except TypeError:
            tb = sys.exc_info()[2]
            errstr = "Write function for register \"{}\" not defined".format(self.name)
            raise NotImplementedError(errstr).with_traceback(tb)
        return 0

    def update(self):
        self.read()
        self.write(self.data)
        return self.data

    def clear(self):
        self.write(0)

    def poll(self, lambda_expr):
        while not lambda_expr(self.read()):
            pass

    def disp(self):
        previous_data = self.data
        self.read()
        print("Register \"{0:<24}\" : {1:<3}/ 0x{1:<3x} mode {4} has value {2:<3}/ 0x{2:<3x} \
               (previously {3:<3}/ 0x{3:<3x}".format(self.name, self.adr, self.data,
                                                     previous_data,
                                                     self.get_rw_string()))

    def get_rw_string(self):
        rw_params = ""
        if self.rw.r:
            rw_params += "r"
        if self.rw.w:
            rw_params += "w"
        return rw_params.upper()

    def safewrite(self, data, mask, invertmask=False, bitlength=None):
        """mask should be one where you want to protect the values, if one is where you want to write, set invertflag"""
        if bitlength is None:
            bitlength = self.bitlength
        notmask = ~mask & int("0b" + "1" * bitlength, 2)
        if invertmask:
            # mask is one where you write to.!!
            # switch mask values !
            mask, notmask = (notmask, mask)
        temp_a = data & mask
        read_data = self.read()
        temp_b = read_data & notmask

        safe_data = temp_a | temp_b
        self.write(safe_data)


class SuperRegister:
    """
    This class is for the registers which are really a combined value
    example : A, B, C is [lsb:msb] in Super_ABC, where A,B,C has bit size of 8.
    usage : sreg = SuperRegister([A,B,C])
    @DynamicAttrs
    """

    def __init__(self, registers_lsb_to_msb, data_size=8):
        self.regs = registers_lsb_to_msb
        self.datasize = data_size
        self.wordmask = int("1" * self.datasize, 2)
        self.data_sizes = [0]
        shift = 0
        for r in self.regs:  # get indices for proper length bitshifting.
            if r.bitlength:
                shift += r.bitlength
                self.data_sizes.append(shift)
            else:
                shift += self.datasize
                self.data_sizes.append(shift)

    def read(self):
        data = 0
        for register, shift in zip(self.regs, self.data_sizes):
            data += (register.read() << shift)
        return data

    def write(self, data):
        for register, shift in zip(self.regs, self.data_sizes):
            word_data = (data >> shift) & self.wordmask  # eg. >> 0, 8, 16
            register.write(word_data)


class RegisterSet(dict):
    """
    Very dynamic object
    @DynamicAttrs
     TODO define "super-registers",
    """

    def __init__(self, *args):
        dict.__init__(self, args)

    def __setitem__(self, key, value):
        # override RegisterSet[key] functionality
        setattr(self, key, value)  # this makes it into a RegisterSet.Register functionality
        dict.__setitem__(self, key, value)

    def __setattr__(self, key, value):
        # override RegisterSet.key functionality
        dict.__setitem__(self, key, value)
        super(RegisterSet, self).__setattr__(key, value)  # avoiding recursion
        # setattr(self,key,value)

    def registers(self):
        return self.values()

    def append(self, item):
        key = item.name
        self.__setitem__(key, item)

    def print_all_registers(self):
        if sys.version_info < (3, 0):
            for rname, reg in sorted(self.items(), key=lambda t: (t[1].adr, t[0])):
                print("Register \"{0:<24}\" : {1:<3}/ 0x{1:<3x} has value {2:<3}/ 0x{2:<3x}".format(rname, reg.adr,
                                                                                                    reg.read()))
        else:
            for rname, reg in self.items():
                print("Register \"{0:<24}\" : {1:<3}/ 0x{1:<3x} has value {2:<3}/ 0x{2:<3x}".format(rname, reg.adr,
                                                                                                    reg.read()))

    def get_all_registers_string(self):
        strings = []
        if sys.version_info < (3, 0):
            for rname, reg in sorted(self.items(), key=lambda t: (t[1].adr, t[0])):
                strings.append(
                    "Register \"{0:<24}\" : {1:<3}/ 0x{1:<3x} has value {2:<3}/ 0x{2:<3x} \n".format(rname, reg.adr,
                                                                                                     reg.read()))
            else:
                for rname, reg in self.items():
                    strings.append(
                        "Register \"{0:<24}\" : {1:<3}/ 0x{1:<3x} has value {2:<3}/ 0x{2:<3x} \n".format(rname, reg.adr,
                                                                                                         reg.read()))
        return "".join(strings)

    def print_all_reg_names(self):
        for rname in self.keys():
            print(rname)


def bits(data, datasize=8):
    bitlist = [False] * datasize
    for cnt, bit in enumerate(bitlist):
        bitlist[cnt] = (data >> cnt) & 0b1 == 1
    return bitlist


############ some demo usage.
if __name__ == "__main__":
    def pf(x):
        print(x)
        return x + 1


    def pfd(x, y):
        print(x, y)
        return x


    a = Register(name="First", adr=4, defaultvalue=99, readmethod=pf)
    tlist = [a, a(), a.data, a.adr, a.rw, a.getobj()]
    print("enumerate")
    for x in enumerate(tlist):
        print(x)
    print("just a list")
    for x in tlist:
        print(x)
    print("zipped")
    for x, y in zip(tlist, tlist):
        print(x, y)
    print("...")
    print("...")
    print(a.read())
    print("...")
    print("...")
    rs = RegisterSet()

    rs.append(Register(name="blank", adr=0x4, readmethod=pf, writemethod=pfd))
    rs.append(Register(name="two", adr=0x10, readmethod=pf))
    rs.append(a)
    ttlist = [rs.First, rs.blank, rs.two, rs["blank"], rs["two"], rs.two.readf]
    for x in ttlist:
        print(x)
    rs.blank.read()
    rs.blank.rw = (True, True)
    rs.blank.write(11)
    rs.blank.read()
    rs.blank.safewrite(0xFF, 0b00101)
    # rs.newobj=Register(name="newobj")
    print("testdump")
    rs.print_all_registers()
    print("=========")
    rs.append(Register(name="CC_CMD", adr=0x123, readmethod=pf))
    print(rs.CC_CMD.name, hex(rs.CC_CMD.read()))

    print(rs.items())

    sr = SuperRegister([rs.blank, rs.blank], data_size=4)
    print(sr)
    sr.write(1234)
    ka = sr.read()
    print(ka)
    print(rs.blank)
