from utils.setup_registers import get_register_set_for_pa3


def pyAssignmentStr(stringtuple, indentation=""):
    return indentation + " ".join([stringtuple[0], "=", stringtuple[1], "\n"])


def get_CC_CMD_opcodes(REGS):
    names = ["INIT_CONFIG", "CONT_SCRUB", "SINGLE_SCRUB", "STOP", "SCRUB_CNT_CLR"]
    opcodes = REGS.CC_CMD.opcodes
    cclines = []
    cclines.append("\n")
    cclines.append("class Pa3CcCmdOpcode(IntEnum):\n")
    for name, oc in zip(names, opcodes):
        print(name, oc[-1])
        line = pyAssignmentStr((name, oc[-1]), "    ")
        cclines.append(line)
    return "".join(cclines)


lines = []

if __name__ == '__main__':
    lines.append("class Pa3Register(IntEnum):\n")
    REGS = get_register_set_for_pa3("../hardware_config.ini", pkg_path_override="../read_pkg_file/auxFPGA_pkg.vhd")
    for reg in REGS.registers():
        line = pyAssignmentStr((reg.name, str(hex(reg.adr))), "    ")
        lines.append(line)
    lines.extend(get_CC_CMD_opcodes(REGS))

    print("".join(lines))
