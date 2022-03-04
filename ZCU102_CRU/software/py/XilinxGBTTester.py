#!/usr/bin/env python
import time
import socket
import sys
import ntpath
import csv
import os
import shutil

from threading import Thread
from VivadoLIB import VivadoLIB
from VivadoTCPClientLib import VivadoTCPClientLib
from GBTFPGAConfLIB import GBTFPGAConfLIB

# Not used in the user example scripts
# from DSO9254A import DSO9254A
# from Latency import LatencyLib

# Configuration
gbtRoot = "/home/yj6/ALICE/gbt-fpga/"
projectPath = "/home/yj6/ALICE/gbt-fpga/example_designs/xilinx_zultrascalep/zcu102/vivado_project"
projectName = "xlx_zcu102_gbt_exmpldsgn"

numLinks=[1,1,1,1]
TxOpt=["STANDARD","LATENCY_OPTIMIZED","STANDARD","LATENCY_OPTIMIZED"]
RxOpt=["STANDARD","LATENCY_OPTIMIZED","STANDARD","LATENCY_OPTIMIZED"]
TxEnc=["GBT_FRAME","GBT_FRAME","GBT_FRAME","GBT_FRAME"]
RxEnc=["GBT_FRAME","GBT_FRAME","GBT_FRAME","GBT_FRAME"]
DataPatGen=["ENABLED","ENABLED","ENABLED","ENABLED"]
DataPatCheck=["ENABLED","ENABLED","ENABLED","ENABLED"]
MatchFlag=["ENABLED","ENABLED","ENABLED","ENABLED"]
ClockingScheme=["BC_CLOCK","BC_CLOCK","FULL_MGTFREQ","FULL_MGTFREQ"]

# bitFileName = ["Standard_BCClock.bit", "LatOpt_BCClock.bit", "Standard_Unified.bit", "LatOpt_Unified.bit"]
bitFileName = ["Standard_BCClock.bit"]

#numberOfResets = 500
numberOfResets = 5

# scopeIpAddr = "169.254.226.69"
# scopePort = 5025
# numberOfSampleForLatencyMeas = 5000

# Tester
# scope = DSO9254A(scopeIpAddr, scopePort)
# lat = LatencyLib(scope)
for i in range(0, len(bitFileName)):

    print("[Step] %s bitfile generation" %(bitFileName[i]))

    # Generate the test package
    #gbtFPGAConf = GBTFPGAConfLIB("%s/example_designs/core_sources/exampleDsgn_package.vhd" %(gbtRoot))
    #gbtFPGAConf.createConfig(numLinks[i], TxOpt[i], RxOpt[i], TxEnc[i], RxEnc[i], DataPatGen[i], DataPatCheck[i], MatchFlag[i], ClockingScheme[i])

    # Compile
    vivado = VivadoLIB(projectPath, projectName)
    #if vivado.synthesis("synth.log", enInfoVerb=False, enWarningVerb=False) != 0:
    #    exit(-1)

    #if vivado.implementation("imp.log", enInfoVerb=False, enWarningVerb=False) != 0:
    #    exit(-1)

    #if vivado.write_bitstream("bit.log", enInfoVerb=False, enWarningVerb=False) != 0:
    #    exit(-1)

    # Move the bitFile
    #vivado.copyBitFile(bitFileName[i])

    # Load the firmware and prepare the test
    hwServThread = vivado.runTCPServerInThread("run.log", enInfoVerb=True, enWarningVerb=True)

    connectId = 0

    while connectId < 10:
        try:
            gbtfpga = VivadoTCPClientLib()
            break
        except socket.error as exc:
            print("Socket error: {}".format(exc))
            connectId = connectId + 1
            time.sleep(1)

    print(f"connectId {connectId}")
    if connectId >= 10:
        exit(-1)

    gbtfpga.configure_fpga("%s/%s.xpr" %(projectPath, projectName), bitFileName[i])

    #latencyMeasFileName = "%s_matchflag_latency.csv" %(ntpath.basename(bitFileName[i])[:-4])

    #reportFile = open(latencyMeasFileName, "wb")
    #latmeas_file = csv.writer(reportFile)
    #latmeas_file.writerow(["Configuration"])
    #latmeas_file.writerow([" "])
    #latmeas_file.writerow(["Tx Optimization",TxOpt[i]])
    #latmeas_file.writerow(["Rx Optimization",RxOpt[i]])
    #latmeas_file.writerow(["Tx Encoding",TxEnc[i]])
    #latmeas_file.writerow(["Rx Encoding",RxEnc[i]])
    #latmeas_file.writerow(["Data Pattern Generator",DataPatGen[i]])
    #latmeas_file.writerow(["Data Pattern Checker",DataPatCheck[i]])
    #latmeas_file.writerow(["Match flag",MatchFlag[i]])
    #latmeas_file.writerow(["Clocking scheme",ClockingScheme[i]])
    #latmeas_file.writerow([" "])
    #latmeas_file.writerow(["Measurement"])
    #latmeas_file.writerow(["Id","Mean","Minimum","Maximum","Std deviation","Number of samples","Number of bits received","Number of bit corrected","Link B.E.R","Data Error flag"])

    # Test procedure
    for resetId in range(0, numberOfResets):

        # Set Reset on Even bitslip to 0
        gbtfpga.write_vio("rxBitSlipRstOnEven_from_user", 0)

        # Select counter frame
        gbtfpga.write_vio("testPatterSel_from_user", 1)

        # Reset the core
        gbtfpga.write_vio("resetgbtfpga_from_vio", 1)
        time.sleep(1)
        gbtfpga.write_vio("resetgbtfpga_from_vio", 0)
        time.sleep(5)

        # Check Tx frameclk PLL locked
        TxPLLLocked = gbtfpga.read_vio("txFrameClkPllLocked_from_gbtExmplDsgn")
        print(f"Step {resetId}: TxPLLLocked = {TxPLLLocked}")
        if TxPLLLocked != 1:
            # Trigger error
            sys.stdout.write("\r                                                                                                     ")
            sys.stdout.write("\r\t\033[1;91m* ERROR: Tx PLL [FrameClock] is not locked \n\033[0m")
            gbtfpga.shutdown()
            hwServThread.join()
            vivado.close()
            gbtfpga.close()

            exit(-1)

        # Check the MGT Ready
        MGTReady = gbtfpga.read_vio("mgtReady_from_gbtExmplDsgn")
        print(f"Step {resetId}: MGTReady = {MGTReady}")
        if MGTReady != 1:
            # Change the reset on event bitslip value
            gbtfpga.write_vio("rxBitSlipRstOnEven_from_user", 1)

            # Wait
            time.sleep(5)

            # Check again
            MGTReady = gbtfpga.read_vio("mgtReady_from_gbtExmplDsgn")
            if MGTReady != 1:
                # Trigger error
                sys.stdout.write("\r                                                                                                     ")
                sys.stdout.write("\r\t\033[1;91m* ERROR: MGT is not ready \n\033[0m")
                gbtfpga.shutdown()
                hwServThread.join()
                vivado.close()
                gbtfpga.close()

                exit(-1)

        # Check GBTRxReady
        GBTRxReady = gbtfpga.read_vio("gbtRxReady_from_gbtExmplDsgn")
        print(f"Step {resetId}: GBTRxReady = {GBTRxReady}")
        if GBTRxReady != 1:
            # Trigger error
            sys.stdout.write("\r                                                                                                     ")
            sys.stdout.write("\r\t\033[1;91m* ERROR: GBT Rx is not ready \n\033[0m")
            gbtfpga.shutdown()
            hwServThread.join()
            vivado.close()
            gbtfpga.close()

            exit(-1)

        # Measure latency
#        scope.send(":SYST:HEAD OFF")
#        scope.reset()

#        scope.enableChannel(2, 0.50)
#        scope.enableChannel(4, 0.50)
#        scope.set50DCchannel(2)
#        scope.set50DCchannel(4)

#        scope.send(":CHANNEL2:OFFSET 0")
#        scope.send(":CHANNEL4:OFFSET 0")

#        scope.setTrigger("POS", 0.200, 2)

#        scope.setTimebaseOffset(1e-4)
#        scope.setTimebaseFullScale(2e-4)
#        scope.setSamplingRateMax()

#        sys.stdout.write("\r                                                                                                     \r")
#        latres = lat.measure(2, 4, numberOfSampleForLatencyMeas, resetId, numberOfResets)
#        sys.stdout.write("\r                                                                                                                                           ")
#        sys.stdout.write("\r\t\033[1m* INFO: Mean latency: %0.3fns\n\033[0m" %(float(latres["mean"])*1000000000))
        latres = []
        latres["mean"] = 0
        latres["min"] = 0
        latres["max"] = 0
        latres["std_deviation"] = 0
        latres["count"] = 0

        # Run for 10^11 bits
        CountReceivedWords = gbtfpga.read_vio("countWordReceived")
        while CountReceivedWords < (100000000000 / 84):
            CountReceivedWords = gbtfpga.read_vio("countWordReceived")
            time.sleep(1)

        # Error detected?
        ErrorDataFlag = gbtfpga.read_vio("rxDataErrorSeen_from_gbtExmplDsgn")

        # Number of bit toggled by the decoder
        BitModifiedCount = gbtfpga.read_vio("countBitsModified")
        sys.stdout.write("\r                                                                                                     ")
        sys.stdout.write("\r\t\033[1m* INFO: FEC toggled %e bits over %e bits received (Line B.E.R < %e )\n\033[0m" %(BitModifiedCount, (84 * CountReceivedWords), (float(1 + BitModifiedCount) / float(84 * CountReceivedWords))))

        if ErrorDataFlag == 1:
            # Trigger error
            sys.stdout.write("\r                                                                                                     ")
            sys.stdout.write("\r\t\033[1;91m* ERROR: Data errors have been detected \n\033[0m")
            gbtfpga.shutdown()
            hwServThread.join()
            vivado.close()
            gbtfpga.close()

            exit(-1)

        #latmeas_file.writerow([resetId, float(latres["mean"]), float(latres["min"]), float(latres["max"]), float(latres["std_deviation"]), float(latres["count"]), (84 * CountReceivedWords), BitModifiedCount, (float(1 + BitModifiedCount) / float(84 * CountReceivedWords)), ErrorDataFlag])

    gbtfpga.exit()
    hwServThread.join()
    vivado.close()
    gbtfpga.close()
    #reportFile.close()

    # Save generated reports
    #SaveDirName = "%s_%s" %(projectName, ntpath.basename(bitFileName[i])[:-4])
    #if not os.path.exists(SaveDirName):
    #    os.makedirs(SaveDirName)

    #finalOutputDir = "%s/%s" %(SaveDirName, time.strftime("%Y%m%d_%H%M%S"))
    #if not os.path.exists(finalOutputDir):
    #    os.makedirs(finalOutputDir)

    #shutil.copyfile(latencyMeasFileName, "%s/%s" %(finalOutputDir,latencyMeasFileName))
    #shutil.copyfile(bitFileName[i], "%s/bitfile.bit" %(finalOutputDir))
    #shutil.copyfile("synth.log", "%s/synth.log" %(finalOutputDir))
    #shutil.copyfile("imp.log", "%s/imp.log" %(finalOutputDir))
    #shutil.copyfile("bit.log", "%s/bit.log" %(finalOutputDir))
    #shutil.copyfile("run.log", "%s/run.log" %(finalOutputDir))
