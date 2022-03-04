"""
@author = magnus.ersdal@uib.no
"""

# Imports
import os
import argparse
from generateScrubbingFile import Scrub
from ecc_functions import make_ecc_file
from makeparameters import make_parameter_file_and_ecc

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('filename', metavar='f', type=str,
                    help='filename of xilinx bit-file generated from vivado')
args = parser.parse_args()
realpath = os.path.realpath(args.filename)
path, fn = os.path.split(realpath)
# Load configuration
# filename as param, filename[-12:] includes githash!

cfgkeys = {'inFileName': realpath,
           'paramfname': os.path.join(path, "paramfile_" + fn[-12:]),
           'fnEnding': '_ecc.bit',
           'bsfile': "need_to_fill"
           }


def do():
    print("Configuration:")
    print(cfgkeys)
    print("Please be patient. this might take a while")
    # Make blind scrubbing file
    s = Scrub()
    name = s.generate_scrubbing_file(cfgkeys['inFileName'])
    cfgkeys['bsfile'] = name
    print("generated blind scrubbing file " + name)

    # Make Page file
    make_parameter_file_and_ecc(cfgkeys['paramfname'],0x100, 0x200)

    # Make ECC bit-and blind-scrubbing -file
    make_ecc_file(cfgkeys['inFileName'], cfgkeys['fnEnding'])
    #
    make_ecc_file(cfgkeys['bsfile'], cfgkeys['fnEnding'])


if __name__ == '__main__':
    do()
