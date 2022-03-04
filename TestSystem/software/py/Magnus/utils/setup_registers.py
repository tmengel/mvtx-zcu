"""
setup_registers.py:
Setup dynamic registers, with their read and write methods
The goal is that this will be basically the only place in the codebase where we touch PA3
__author__ = Magnus (magnus.ersdal@uib.no)
"""
from read_pkg_file.read_WB_addresses import read_wb_adresses_new, \
    read_wb_adresses_post_a202, entry, read_wb_adresses_multiline_descriptor, Newentry
from utils.read_cfg import get_cfg
from utils.register_cls import Register, RegisterSet, Rw_params, SuperRegister


def get_rw_tuple_from_string(rwstring):
    """input is rw or r or rw**"""
    read, write = (False, False)
    if "W" in rwstring.upper():
        write = True
    if "R" in rwstring.upper():
        read = True
    rw = Rw_params(r=read, w=write)
    return rw


def get_register_set_for_pa3(fn_overrive=None, ignorepoll=False, pkg_path_override=None, readf=print, writef=print):
    if fn_overrive:
        dataconf = get_cfg(fn_overrive)
    else:
        dataconf = get_cfg()
    if pkg_path_override:
        pkg_path = pkg_path_override
        id_card, gbt_ch = (dataconf["id_card"], dataconf["gbt_ch"])
    else:
        pkg_path, id_card, gbt_ch = (dataconf["pkg_path"], dataconf["id_card"], dataconf["gbt_ch"])
    # self.logger.setLevel("INFO")
    addresses = read_wb_adresses_post_a202(pkg_path)  # get all wb addresses
    vfs, ocs = read_wb_adresses_multiline_descriptor(addresses, pkg_path)
    # pa3 = PA3(id_card, 2, gbt_ch, 'CRU') # Todo REPLACE with cru emulator shit.

    # print(ocs)
    # print(len(ocs), len(vfs))

    def pa3_read_reg(adr):
        return readf(adr)

    def pa3_write_reg(adr, data):
        return writef(adr, data)

    # print(addresses)
    pa3_registers = RegisterSet()
    for data, verbosity_info, opcodes in zip(addresses, vfs, ocs):
        data = Newentry(*data)  # data[0], data[1], data[2])
        pa3_registers.append(
            Register(name=data.name, adr=data.address, rw=get_rw_tuple_from_string(data.rwmode_str),
                     bitlength=data.width, regtype=data.type,
                     readmethod=pa3_read_reg, writemethod=pa3_write_reg,
                     ignorepoll=ignorepoll, verbosefilter=verbosity_info,
                     opcodes=opcodes))
    # todo generate file !
    # todo h01 -- commands ! 
    return pa3_registers


if __name__ == "__main__":
    REGS = get_register_set_for_pa3("../hardware_config.ini", pkg_path_override="../read_pkg_file/auxFPGA_pkg.vhd")
    # print(REGS)
    # REGS.print_all_registers()
    # for item in REGS.values():
    #     item.disp()
    #     if item.rw.w == True:
    #         print("write to this guy")
    # for reg in REGS.registers():
    #     reg.disp_fields()
    #     # reg.verbose_read()
    REGS.ECC_STATUS.verbose_read(1)
    REGS.ECC_COMMAND.disp_opcodes()
