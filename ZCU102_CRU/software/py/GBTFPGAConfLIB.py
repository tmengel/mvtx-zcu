#!/usr/bin/env python
import tempfile
import shutil
import subprocess
import sys
import time
import glob
import os

# -------------------------------------------------------------
#  ----------------- Class GBTFPGA Config ---------------------
# -------------------------------------------------------------

class GBTFPGAConfLIB():
    
    def __init__(self, filename):
        try:
            os.remove(filename)
        except OSError:
            pass

        self.file_name = filename

    def createConfig(self, NumLinks = 1, TxOpt = "STANDARD", RxOpt = "STANDARD", TxEnc = "GBT_FRAME", RxEnc = "GBT_FRAME", DataPatGen = "ENABLED", DataPatCheck = "ENABLED", MatchFlag = "ENABLED", ClockingScheme = "BC_CLOCK"):

        confFile = open(self.file_name,"w")
        confFile.write("------------------------------------------------------- \n")
        confFile.write("--! @file\n")
        confFile.write("--! @author Julian Mendez <julian.mendez@cern.ch> (CERN - EP-ESE-BE)\n")
        confFile.write("--! @version 6.0\n")
        confFile.write("--! @brief GBT-FPGA IP - Common package\n")
        confFile.write("-------------------------------------------------------\n")
        confFile.write("\n")
        confFile.write("-- IEEE VHDL standard library:\n")
        confFile.write("library ieee;\n")
        confFile.write("use ieee.std_logic_1164.all;\n")
        confFile.write("use ieee.numeric_std.all;\n")
        confFile.write("\n")
        confFile.write("-- Custom libraries and packages:\n")
        confFile.write("use work.gbt_bank_package.all;\n")
        confFile.write("\n")
        confFile.write("package gbt_exampledesign_package is  \n")
        confFile.write("\n")
        confFile.write("   --=============================== Constant Declarations ===============================--\n")
        confFile.write("   constant ENABLED								: integer := 1;                              --! Enable constant definition\n")
        confFile.write("   constant DISABLED							: integer := 0;                              --! Disable constant definition\n")
        confFile.write("   \n")
        confFile.write("   constant GATED_CLOCK			                : integer := 0;\n")
        confFile.write("   constant PLL					                : integer := 1;\n")
        confFile.write("	\n")
        confFile.write("   constant BC_CLOCK                            : integer := 0;\n")
        confFile.write("   constant FULL_MGTFREQ                        : integer := 1;    \n")
        confFile.write("\n")
        confFile.write("   --================================= Configuration ================================-- \n")
        confFile.write("   constant NUM_LINK_Conf                       : integer := %d;\n" %(NumLinks))
        confFile.write("   constant TX_OPTIMIZATION_Conf                : integer := %s;\n" %(TxOpt))
        confFile.write("   constant RX_OPTIMIZATION_Conf                : integer := %s;\n" %(RxOpt))
        confFile.write("   constant TX_ENCODING_Conf                    : integer := %s;\n" %(TxEnc))
        confFile.write("   constant RX_ENCODING_Conf                    : integer := %s;\n" %(RxEnc))
        confFile.write("   constant DATA_GENERATOR_ENABLE_Conf          : integer := %s;\n" %(DataPatGen))
        confFile.write("   constant DATA_CHECKER_ENABLE_Conf            : integer := %s;\n" %(DataPatCheck))
        confFile.write("   constant MATCH_FLAG_ENABLE_Conf              : integer := %s;\n" %(MatchFlag))
        confFile.write("   constant CLOCKING_SCHEME_Conf                : integer := %s;\n" %(ClockingScheme))
        confFile.write("	\n")
        confFile.write("   --=====================================================================================--   \n")
        confFile.write("end gbt_exampledesign_package;\n")
        confFile.write("--=================================================================================================--\n")
        confFile.write("--#################################################################################################--\n")
        confFile.write("--=================================================================================================--\n")
        
        confFile.close()
