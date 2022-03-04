import os
import sys


script_path = os.path.dirname(os.path.realpath(__file__))
extrapaths = ['modules/board_support_software/software/py/', 'software/py/']
for p in extrapaths:
    modules_path = os.path.join(
        script_path, p)
    print("extending path with", modules_path)
    sys.path.append(modules_path)

from proasic3_flash import ProAsic3Flash
from ru_board import RUv0_CRU

import testbench

if __name__ == '__main__':
    tb = testbench.Testbench()
    # type hints for easier editing. Must be for instance of
    # the object since we are overriding the declaration in the __init__ function
    tb.cru: RUv0_CRU
    tb.cru.Pa3_FlashIF: ProAsic3Flash
    print("hello")
    try:
        # setup of communication from testbench.py:
        tb.setup_standalone()
        dna = tb.rdo.get_dna_value()
        print(f"Xkcu dna : {dna:x}")
        print("disabling ECC")
        tb.cru.pa3.Ecc.disable_ecc()
        # run the flash readback test.
        tb.cru.Pa3_FlashIF.test_readback()  # function in proasic3_flash.py
    finally:
        tb.stop()  # finally stop tool

