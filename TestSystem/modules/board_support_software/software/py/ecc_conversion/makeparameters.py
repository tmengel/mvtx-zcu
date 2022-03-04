"""
@author = magnus.ersdal@uib.no
"""
from math import ceil

import os
import fire

from ecc_functions import make_ecc_file


def make_parameter_file(paramfile_name, startblock=0x100, scrubstartblock=0x300):
    # todo make firmware sizes constant
    paramfile_name = os.path.realpath(paramfile_name)
    PAGE_SIZE = 4096
    # some constants from Gitle M.
    PAGE_PER_BLOCK = 64
    BLOCK_SIZE = PAGE_SIZE * PAGE_PER_BLOCK
    PATTERN = 0x665599AA  # 0xAA995566 in other endian ! .
    # magical constants for xilinx xkcu! please please do not touch..
    FWSIZE = 5889
    BSSIZE = 4504

    print([hex(x) for x in [PAGE_SIZE, PAGE_PER_BLOCK, BLOCK_SIZE, FWSIZE, BSSIZE]])

    FW_PAGE_ADDR = startblock * PAGE_PER_BLOCK
    SCRUB_PAGE_ADDR = scrubstartblock * PAGE_PER_BLOCK

    data = [(FW_PAGE_ADDR, 3), (0, 1),
            ((FW_PAGE_ADDR + FWSIZE), 3), (0, 1), (PATTERN, 4)]
    data += [(SCRUB_PAGE_ADDR, 3), (0, 1),
             ((SCRUB_PAGE_ADDR + BSSIZE), 3), (0, 1), (PATTERN, 4)]

    result = bytearray()
    for d, size in data:
        bytesdata = d.to_bytes(length=size, byteorder='big')
        result.extend(bytesdata)

    remlen = PAGE_SIZE - len(result)
    result.extend(b'\xFF' * (remlen))
    assert len(result) == PAGE_SIZE
    with open(paramfile_name, 'wb+') as f:
        nchrs = f.write(result[:])
        print("parameter file of {} chars written".format(nchrs))
    return paramfile_name


def make_parameter_file_and_ecc(paramfile_name, startblock, scrubstartblock):
    """ make file and ecc  it """
    pfile = make_parameter_file(paramfile_name, startblock, scrubstartblock)
    ecfile = make_ecc_file(pfile)
    return ecfile


class FireInterface:
    """ simple interface to generate parameter files manually """

    def make_parameter_file_and_ecc(self, paramfile_name, startblock, scrubstartblock):
        """ generate ecc coded parameter file"""
        return make_parameter_file_and_ecc(paramfile_name, startblock, scrubstartblock)


if __name__ == '__main__':
    fire.Fire(FireInterface)
