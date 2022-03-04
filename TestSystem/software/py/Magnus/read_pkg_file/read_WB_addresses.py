"""
@author = magnus.ersdal@uib.no
"""
import os
from utils.verbosefilter import VerboseFilter, EmptyVerboseFilter
from collections import namedtuple

entry = namedtuple('wb_addr_info', 'name address rwmode_str')  # use this in setup_registers.py
Newentry = namedtuple('wb_addr_info',
                      'name address rwmode_str defaultvalue width type part docstr')  # use this in setup_registers.py
Opcode = namedtuple('opcode', 'desc code hex')


def read_wb_adresses(filename="auxFPGA_pkg.vhd"):
    with open(filename, 'r') as f:
        lines = f.readlines()
    adrdict = {}

    for line in lines:
        block = "REGSPACE" in line
        block2 = "MEMSPACE" in line
        block3 = "NOTE!" in line
        if "cADD" in line and not (block or block2 or block3):
            tl = line.split()
            # print(tl)
            tl.pop(0)  # rem constant

            cname = tl.pop(0)

            tl.pop(0)  # rem " : "
            tl.pop(0)  # rem " natural"
            tl.pop(0)  # rem :=
            numberstr = tl.pop(0)
            if ";" in numberstr:
                caddr = int(numberstr[0:-1])  # removes semicolon
            else:
                caddr = int(numberstr)

            adrdict[cname[5:]] = caddr
            tl.pop(0)
            crwmode = tl.pop(0)
    return adrdict


def read_wb_adresses_new(filename="auxFPGA_pkg.vhd"):
    with open(filename, 'r') as f:
        lines = f.readlines()
    adrdict = {}
    list_of_registers = []
    for line in lines:
        block = "REGSPACE" in line
        block2 = "MEMSPACE" in line
        if "cADD" in line and not (block or block2):
            tl = line.split()
            tl.pop(0)  # rem constant

            cname = tl.pop(0)

            tl.pop(0)  # rem " : "
            tl.pop(0)  # rem " natural"
            tl.pop(0)  # rem :=
            numberstr = tl.pop(0)
            if ";" in numberstr:
                caddr = int(numberstr[0:-1])  # removes semicolon
            else:
                caddr = int(numberstr)

            name = cname[5:]
            caddr
            tl.pop(0)
            crwmode = tl.pop(0)

            # adrdict[name] =
            key = entry(name=name, address=caddr, rwmode_str=crwmode)
            list_of_registers.append(key)
    return list_of_registers


def read_wb_adresses_post_a202(filename="auxFPGA_pkg.vhd"):
    with open(filename, 'r') as f:
        lines = f.readlines()
    adrdict = {}
    list_of_registers = []
    documentation = ""
    for line in lines:
        try:
            block = "REGSPACE" in line
            block2 = "MEMSPACE" in line
            if "cADD" in line and not (block or block2):
                line = line.replace(';', ' ')
                tl = line.split()
                # print(tl)
                tl.pop(0)  # rem constant

                cname = tl.pop(0)

                tl.pop(0)  # rem " : "
                tl.pop(0)  # rem " natural"
                tl.pop(0)  # rem :=
                numberstr = tl.pop(0)
                if ";" in numberstr:
                    caddr = int(numberstr[0:-1])  # removes semicolon
                else:
                    caddr = int(numberstr)

                name = cname[5:]
                tl.pop(0)
                clen = int(tl.pop(0))
                crwmode = tl.pop(0)
                ctype = tl.pop(0)  # DBG / constant / STAT / DATA
                cont = ""
                if "of" in tl[0]:
                    cont = tl.pop(0)
                cdefaultval = tl.pop(0)
                if "-" not in cdefaultval:
                    cdefaultval = int(cdefaultval, 16)
                else:
                    cdefaultval = -1

                if "\"" in line:
                    documentation = line.split("\"")[-1].split("]")[-1].strip()

                # print(tl)
                # adrdict[name] =
                key = Newentry(name=name, address=caddr,
                               rwmode_str=crwmode, defaultvalue=cdefaultval,
                               width=clen, type=ctype, part=cont,
                               docstr=documentation)
                list_of_registers.append(key)
        except ValueError:
            # print("something went wrong on line\n" + line)
            pass
    return list_of_registers


def read_fw_version(filename="auxFPGA_pkg.vhd"):
    with open(filename, 'r') as f:
        lines = f.readlines()
    for line in lines:
        vername = ""
        if "constant C_VERSION" in line:
            # print(line)
            tl = line.split()
            for elem in tl:
                if "X" in elem:
                    vername = elem
                    break
            if ";" in vername:
                vername = vername[0:-1]  # X"A202"
            vername = int(vername[2:-1], 16)  # A202 to int base 16
            return vername


#   constant C_VERSION : std_logic_vector(15 downto 0) := X"A202";
def read_wb_adresses_multiline_descriptor(registers, filename="auxFPGA_pkg.vhd"):
    previous_width = 0
    next_desc = []
    vfs = []
    opcodes = []
    for cnt, reg in enumerate(registers):
        vf = EmptyVerboseFilter(reg.name, reg.docstr)
        offset = 0
        desclist = []
        oplist = []
        opclist = []
        name = reg.name
        with open(filename, 'r') as f:
            lines = f.readlines()
        descfield, descfound = (False, False)
        desc_startline, desc_stopline = (0, 0)
        for i, line in enumerate(lines):
            if "_" + name in line:  # fix for confusion of CC_ and ECC_
                if "\"" in line:
                    # line has descriptor field.
                    # print("found descriptor field")
                    descfield = True
                    desc_startline = i
            elif "\"" in line and descfield:
                # end of desc field
                descfield = False
                descfound = True
                desc_stopline = i
                # print("startline", desc_startline, "stopline", desc_stopline)

        if descfound:
            desc = lines[desc_startline:desc_stopline + 1]
            # print("".join(desc).split("\""))
            desc = "".join(desc).split("\"")[1]
            for x in desc.splitlines():
                if "[" in x and "NOTE!" not in x:
                    # print(x.strip(" --"))
                    desclist.append(x.strip(" --"))
                if ":" in x and "h" in x and "[" not in x:
                    oplist.append(x)

        if "of" in reg.part:
            startidx = int(reg.part[0])
            stopidx = int(reg.part[3])
            if startidx > 1:
                offset = startidx * previous_width
                # print(reg.name,"offset ::",offset)
            else:
                offset = 0

        if desclist or next_desc:
            # print(desclist)
            desclist += next_desc
            next_desc = []
            for line in desclist:
                if "[" in line:
                    split = line.find("]")
                    position_str = line[1:split]
                    text_str = desc[split + 1:]
                    positions = [int(x) for x in position_str.split(":")]
                    maxpos = max(positions)
                    minpos = min(positions)
                    if (maxpos - offset) > reg.width:
                        # belongs to next register
                        minval = 0
                        maxval = maxpos - offset
                        # print("appending ", line)
                        nline = "[{}:{}] {}".format(maxval, minval, text_str)
                        next_desc.append(line)
                        #                           --                       hF: others"
            vf = VerboseFilter(reg.name, desclist, register_width=reg.width, offset=offset, docstr=reg.docstr)

        if oplist:
            for opline in oplist:
                try:
                    k = opline.strip()
                    kr = k.split("--")[-1].split(":")
                    cmd = kr[-1].strip()  # command
                    valstr = kr[0].strip()  # "h313"
                    val = int(valstr[1:], 16)
                    for dline in desclist:  # yes, desclist. [7] : execute (T) like
                        if "execute" in dline.lower() and "[" in dline:
                            # We have an execute bit !
                            nb = dline.split("[")[-1].split("]")[0]
                            nb = int(nb)
                            val = val | (0b1 << nb)  # append execute bit.
                    oc = Opcode(desc=cmd, code=val, hex=hex(val))
                    opclist.append(oc)
                except (TypeError, ValueError):  # ignore this error
                    pass

        opcodes.append(opclist)
        vfs.append(vf)
        previous_width = reg.width
    return vfs, opcodes


if __name__ == "__main__":
    wbbus = read_wb_adresses_post_a202(filename="new_auxFPGA_pkg.vhd")
    print(wbbus)
    print(hex(read_fw_version()))
    vs, ocs = read_wb_adresses_multiline_descriptor(wbbus, filename="new_auxFPGA_pkg.vhd")
