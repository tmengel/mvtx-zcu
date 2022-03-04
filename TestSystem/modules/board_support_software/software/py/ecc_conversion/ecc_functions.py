"""
@author = magnus.ersdal@uib.no
For usage see make_all_ECC_files.py
"""

import io
import operator as op
import struct
from functools import lru_cache
from itertools import count, zip_longest
from multiprocessing import Pool
import os
import numpy as np

# precalc values
C_precalc = [0x55, 0xaa, 0x33, 0xcc, 0x0f, 0xf0]
A_precalc = [0b1 << i for i in range(7)]


# Support for ECC functions.


def make_ecc(data):
    """create ecc data"""
    s = bytearray(data)
    # padding functions
    modlarge = len(s) % 4096
    if modlarge != 0:
        print("Padding to 4096")
        s.extend([0xff] * (4096 - modlarge))

    nbytes = 128
    schunks = chunks(s, nbytes)
    # generator obj

    ab = np.array(list(schunks))
    finallen = len(ab[-1])
    if finallen != 128:
        temp = bytearray(ab[-1])
        temp.extend(b'\xFF' * (128 - finallen))
        ab[-1] = temp
        # we need to pad.
    # end padding
    print("running ecc code generation")
    ec_codes = gen_ecc_multithread(ecc, ab)
    # ec_codes = gen_ecc_singlethread(ecc, ab) # commented out for convenience

    colshape = ec_codes.shape[0]
    ec_codes_col = ec_codes[np.array(range(colshape)), 1]
    ec_codes_li = ec_codes[np.array(range(colshape)), 0]

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


@lru_cache(maxsize=None)
def indices_with_cache(cnt):
    f_a = list(map(lambda x: (cnt & x) != x, A_precalc))  # 0x1, 0x2, 0x4 etc.
    return np.fromiter(map(op.sub, range(1, 15, 2), f_a), dtype=np.uint8)  # 1 - True = 0. make parity indices


# more precalculated values for ecc function
pre_count = list(range(128))
precalc_indices_d = [indices_with_cache(x) for x in range(128)]
precalc_indices = np.array(precalc_indices_d)


def bits_to_ints(bits, bits2):
    a = b = i = 0
    for aval, bval in zip_longest(bits, bits2, fillvalue=0):
        a += aval * (1 << i)
        b += bval * (1 << i)
        i += 1
    return a, b


def ecc(userbytes):
    """Makes error correcting codes with 14 bits of line parity and 6 bits of column parity"""
    lp = [0] * 14
    cp = [0] * 6
    for cnt in pre_count:
        # line parity
        prty = parity_with_cache(userbytes[cnt])
        for i in precalc_indices_d[cnt]:  # precalculation of indices is 33% gain
            lp[i] = lp[i] ^ prty
        cp = calc_col_parity_with_cache(userbytes[cnt], cp)
    return bits_to_ints(lp, cp)


def gen_ecc_singlethread(ECC, ab):
    """slow, but works anywhere"""
    return np.array(list(map(ECC, ab)))


def gen_ecc_multithread(ECC, ab):
    """multithreaded ECC generation. Significantly faster for large datasets
    to optimize change number in Pool(4) to number of cores on your system"""
    with Pool(4) as p:
        try:
            ec_codes = np.array(list(p.map(ECC, ab)))  # from ECC to ecc_gen_sb
        finally:
            p.close()  # no more tasks
            p.join()  # wrap up current tasks
    return ec_codes


def int_to_bytes(data):  # for python 2.7 :(
    return struct.pack("<l", data)[0:3]


def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]


def make_ecc_file(infilename, fileending="_ecc.bit", pagefile=False):
    fn = os.path.realpath(infilename)
    with io.open(fn, 'rb') as f:
        sb = f.read()
        s = bytearray(sb)
    print("read file", infilename)
    result = make_ecc(s)
    print("generated ecc for", infilename)
    ofname = fn[0:-4] + fileending
    print("filename:" + ofname)
    with open(ofname, 'wb+') as f:
        nchrs = f.write(result[:])
        print("{} chars written".format(nchrs))
    return ofname


def parallel_swar(i):
    """hamming weight"""
    i = i - ((i >> 1) & 0x55555555)
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333)
    i = (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24
    return int(i % 2)


def calc_col_parity_with_cache(byte, cp):
    it = zip(C_precalc, cp)
    cp = [parity_with_cache(byte & x[0]) ^ x[1] for x in it]
    return cp


@lru_cache(512)
def parity_with_cache(v):
    """returns even parity"""
    v ^= v >> 16
    v ^= v >> 8
    return parallel_swar(v & 0xff)
