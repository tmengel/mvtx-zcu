import struct

from ecc.memoize import Memoize

"""
@author = magnus.ersdal@uib.no
"""
# imports
import numpy as np
import io
from multiprocessing import Pool
from itertools import count
import operator as op


# Support for ECC functions.
def getKeys(cfgfn="config.ini"):
    import configparser
    try:
        cfg = configparser.ConfigParser()
        cfg.read(cfgfn)
        allkeys = {"createBS": False,
                   "fnEnding": "_ECC_",
                   "pagefname": "pagefile.bit",
                   "inFileName": "RUv1_top_180126_1918_2226746.bit"}
        # get key vals.
        allkeys['fnEnding'] = cfg['config']['DefaultFilenameAppen'] + ".bit"
        allkeys['createBS'] = cfg['config'].getboolean('createblindscrubfile')
        allkeys['bsfile'] = cfg['ofnames']['BlindScrubfile']
        allkeys['pagefname'] = cfg['ofnames']['PageFileName']
    except KeyError as e:
        print("Key failure. please check the config file for the key " + str(e))

    return allkeys


def ECC(userbytes):
    """Makes error correcting codes with 14 bits of line parity and 6 bits of column parity"""
    a = [0b1 << i for i in range(7)]
    b = list(range(1, 15, 2))
    c = [0x55, 0xaa, 0x33, 0xcc, 0x0f, 0xf0]
    lp = [0] * 14
    cp = [0] * 6
    # tmp_parity = list(map(parity, userbytes))
    # line parity
    for cnt, byte in zip(count(), userbytes):
        prty = parity(byte)
        f_a = list(map(lambda x: (cnt & x) != x, a))  # 0x1, 0x2, 0x4 etc.
        prty_indices = list(
            map(op.sub, b, f_a))  # 1 - True = 0. make parity indices
        #  prty_indices = list(map(op.sub,))
        for i in prty_indices:
            lp[i] = lp[i] ^ prty
        # column parity
        # cp[n] = (prty & c[n]) ^ cp[n]
        # cp = list(map(lambda x, y: (prty & x) ^ y, c, cp))
        cp = list(map(lambda x, y: parity(byte & x) ^ y, c, cp))
    lp_i = int(''.join(str(j) for j in lp[::-1]), 2)
    cp_i = int(''.join(str(j) for j in cp[::-1]), 2)
    return lp_i, cp_i


def make_ecc(data):
    s = bytearray(data)
    modlarge = len(s) % 4096
    if modlarge != 0:
        print("Padding to 4096")
        s.extend([0xff] * (4096 - modlarge))

    nbytes = 128
    schunks = chunks(s, nbytes)
    # generator obj

    ab = np.array(list(schunks))  # TODO PAD, size % 4096 ==0 0xFF
    finallen = len(ab[-1])
    if finallen != 128:
        temp = bytearray(ab[-1])
        temp.extend(b'\xFF' * (128 - finallen))
        ab[-1] = temp
        # we need to pad.

    ec_codes = np.array(list(map(ECC, ab)))  # from ECC to ecc_gen_sb

    cols = ec_codes.shape[0]
    ec_codes_col = ec_codes[np.array(range(cols)), 1]
    ec_codes_li = ec_codes[np.array(range(cols)), 0]

    result = bytearray()
    for data, li, co in zip(ab, ec_codes_li, ec_codes_col):
        lico = (li << 6) | co  # 2 lsbit in li = 2 msb in co
        try:
            lico = int(lico).to_bytes(3, byteorder='little')  # should be little
        except AttributeError:
            lico = int_to_bytes(lico)
        data = list(data) + list(lico)  # li + co
        result.extend(data)
    return result[:]



def int_to_bytes(data): # for python 2.7 :(
    return struct.pack("<l",data)[0:3]

def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]


@Memoize
def parity(v):
    """returns even parity"""
    v ^= v >> 16
    v ^= v >> 8
    return parallel_swar(v & 0xff)


def parallel_swar(i):
    """hamming weight"""
    i = i - ((i >> 1) & 0x55555555)
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333)
    i = (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24
    return int(i % 2)
