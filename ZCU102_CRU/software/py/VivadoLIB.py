#!/usr/bin/env python
import tempfile
import shutil
import subprocess
import sys
import time
import glob
import os
import inspect

from queue import Queue, Empty
from threading import Thread

# -------------------------------------------------------------
#  ------------------------- Class Vivado ---------------------
# -------------------------------------------------------------


class VivadoLIB:

    def __init__(self, projectDir, projectName):
        self.project_file = "%s/%s.xpr" %(projectDir, projectName)
        self.project_dir = projectDir
        self.project_name = projectName
        self.tmp_dir = tempfile.mkdtemp()

        print("[Success] Created temporary directory: %s" %(self.tmp_dir))

    def copyBitFile(self, dest):
        for file in os.listdir("%s/%s.runs/impl_1" %(self.project_dir, self.project_name)):
            if file.endswith(".bit"):
                print("[Success] Copy %s/%s.runs/impl_1/%s to %s" %(self.project_dir, self.project_name, file, dest))
                shutil.copyfile("%s/%s.runs/impl_1/%s" %(self.project_dir, self.project_name, file), dest)

    def enqueue_output(self, out, queue):
        for line in iter(out.readline, b''):
            queue.put(line)

    def runVivadoTcl(self, tclFile, logFileName, enStatusVerb=True, enInfoVerb=True, enWarningVerb=True, enCriticalWarningVerb=True, enErrorVerb=True):

        logFile = open(logFileName,"wb")

        start = time.time()
        process = subprocess.Popen("vivado -mode tcl -source %s" %(tclFile), stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)

        stdoutQueue = Queue()
        stderrQueue = Queue()

        stdoutThread = Thread(target=self.enqueue_output, args=(process.stdout, stdoutQueue))
        stdoutThread.daemon = True # thread dies with the program
        stdoutThread.start()

        stderrThread = Thread(target=self.enqueue_output, args=(process.stderr, stderrQueue))
        stderrThread.daemon = True # thread dies with the program
        stderrThread.start()

        i = 0

        while True:

            if stdoutThread.isAlive() is False and stderrThread.isAlive() is False:
                break

            try:
                nextStderrline = stderrQueue.get_nowait() # or q.get(timeout=.1)
            except Empty:
                pass # Null: nothing to do
            else:
                end = time.time()
                ellapsed_time = "(Elapsed: %fs)     " %((end - start))
                sys.stdout.write("\r[On-going] Vivado command " + "." * i + " " * (10 - i) + ellapsed_time)
                sys.stdout.flush()

                i = i + 1
                if i >= 10:
                    i = 0

                if enErrorVerb:
                    sys.stdout.write("\r                             " + " " * i + " " * (10 - i) + "                      ")
                    sys.stdout.write("\r\t\033[1;91m* [STDERR] ERROR: %s\033[0m" %(nextStderrline))

                logFile.write(nextStderrline)

            try:
                nextStdoutline = stdoutQueue.get_nowait() # or q.get(timeout=.1)
            except Empty:
                pass     # Null: nothing to do
            else:
                end = time.time()
                ellapsed_time = "(Elapsed: %fs)     " %((end - start))
                sys.stdout.write("\r[On-going] Vivado command " + "." * i + " " * (10 - i) + ellapsed_time)
                sys.stdout.flush()

                i = i + 1
                if i >= 10:
                    i = 0

                if str(nextStdoutline).startswith("ERROR:") and enErrorVerb:
                    sys.stdout.write("\r                             " + " " * i + " " * (10 - i) + "                      ")
                    sys.stdout.write("\r\t\033[1;91m* %s\033[0m" %(nextStdoutline))

                if str(nextStdoutline).startswith("WARNING:") and enWarningVerb:
                    sys.stdout.write("\r                             " + " " * i + " " * (10 - i) + "                      ")
                    sys.stdout.write("\r\t\033[93m* %s\033[0m" %(nextStdoutline))

                if str(nextStdoutline).startswith("CRITICAL WARNING:") and enCriticalWarningVerb:
                    sys.stdout.write("\r                             " + " " * i + " " * (10 - i) + "                      ")
                    sys.stdout.write("\r\t\033[1;93m* %s\033[0m" %(nextStdoutline))

                if str(nextStdoutline).startswith("INFO:") and enInfoVerb:
                    sys.stdout.write("\r                             " + " " * i + " " * (10 - i) + "                      ")
                    sys.stdout.write("\r\t\033[94m* %s\033[0m" %(nextStdoutline))

                if nextStdoutline[0] == '#' and enStatusVerb:
                    sys.stdout.write("\r                             " + " " * i + " " * (10 - i) + "                      ")
                    sys.stdout.write("\r\t%s" %(nextStdoutline))

                if "Time (s)" in str(nextStdoutline) and enStatusVerb:
                    sys.stdout.write("\r                             " + " " * i + " " * (10 - i) + "                      ")
                    sys.stdout.write("\r\t# %s" %(nextStdoutline))

                logFile.write(nextStdoutline)

        logFile.close()

        end = time.time()
        ellapsed_time = "(Elapsed: %fs)     " %((end - start))
        sys.stdout.write("\r[Finished] Vivado command " + "." * i + " " * (10 - i) + ellapsed_time + "\n")

        stdoutThread.join()
        stderrThread.join()

        process.communicate()[0]
        return process.returncode

    def synthesis(self, logFileName, enStatusVerb=True, enInfoVerb=True, enWarningVerb=True, enCriticalWarningVerb=True, enErrorVerb=True):
        synthFileName = "%s\\synth.tcl" %(self.tmp_dir)
        file = open(synthFileName,"w")

        file.write("open_project %s \n\n" %(self.project_file))

        file.write("reset_run synth_1 \n\n")

        file.write("catch { \n")
        file.write("    launch_runs synth_1 -jobs 4 \n")
        file.write("    wait_on_run synth_1 \n")
        file.write("} synth_err\n\n")

        file.write("if {[get_property STATUS [get_runs synth_1]] eq \"synth_design ERROR\"} { puts [format \"ERROR: %s\" [get_property STATUS [get_runs synth_1]]]; exit -1 } \n\n")

        file.write("open_run synth_1 -name synth_1 \n\n")
        file.write("report_clock_interaction -delay_type min_max -significant_digits 3 -name timing_1 -file ./post_syn_clock_interaction.rpt \n")

        file.write("close_project \n\n")

        file.write("exit 0\n")

        file.close()

        print("[Success] Created synth TCL file")

        print("[Success] Run Vivado: : %s file" % (synthFileName))
        return self.runVivadoTcl(synthFileName, logFileName, enStatusVerb, enInfoVerb, enWarningVerb, enCriticalWarningVerb, enErrorVerb)

    def implementation(self, logFileName, enStatusVerb=True, enInfoVerb=True, enWarningVerb=True, enCriticalWarningVerb=True, enErrorVerb=True):
        impFileName = "%s\\imp.tcl" %(self.tmp_dir)
        file = open(impFileName,"w")

        file.write("open_project %s \n\n" %(self.project_file))

        file.write("reset_run impl_1 \n\n")

        file.write("launch_runs impl_1 -jobs 4 \n")
        file.write("wait_on_run impl_1 \n\n")

        file.write("if {[get_property STATUS [get_runs impl_1]] eq \"place_design ERROR\"} { puts [format \"ERROR: %s\" [get_property STATUS [get_runs impl_1]]]; exit -1 } \n")
        file.write("if {[get_property STATUS [get_runs impl_1]] eq \"route_design ERROR\"} { puts [format \"ERROR: %s\" [get_property STATUS [get_runs impl_1]]]; exit -1 } \n")

        file.write("if {[string compare [get_property STATUS [get_runs impl_1]] \"route_design Complete!\"]!=0} { exit -3 } \n\n")

        file.write("open_run impl_1 -name impl_1 \n\n")
        file.write("report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -name timing_1 -file post_imp_timing_summary.rpt \n")

        file.write("close_project \n\n")

        file.write("exit \n")

        file.close()

        print("[Success] Created implementation TCL file")

        print("[Success] Run Vivado: : %s file" % (impFileName))
        return self.runVivadoTcl(impFileName, logFileName, enStatusVerb, enInfoVerb, enWarningVerb, enCriticalWarningVerb, enErrorVerb)

    def write_bitstream(self, logFileName, enStatusVerb=True, enInfoVerb=True, enWarningVerb=True, enCriticalWarningVerb=True, enErrorVerb=True):
        bitFileName = "%s\\write_bitstream.tcl" %(self.tmp_dir)
        file = open(bitFileName,"w")

        file.write("open_project %s \n\n" %(self.project_file))

        file.write("launch_runs impl_1 -to_step write_bitstream -jobs 4 \n")
        file.write("wait_on_run impl_1 \n\n")

        file.write("if {[get_property STATUS [get_runs impl_1]] eq \"place_design ERROR\"} { puts [format \"ERROR: %s\" [get_property STATUS [get_runs impl_1]]]; exit -1 } \n")
        file.write("if {[get_property STATUS [get_runs impl_1]] eq \"route_design ERROR\"} { puts [format \"ERROR: %s\" [get_property STATUS [get_runs impl_1]]]; exit -1 } \n")

        file.write("if {[string compare [get_property STATUS [get_runs impl_1]] \"write_bitstream Complete!\"]!=0} { puts [format \"ERROR: %s\" [get_property STATUS [get_runs impl_1]]]; exit -3 } \n\n")

        file.write("close_project \n\n")

        file.write("exit \n")

        file.close()

        print("[Success] Created write_bitstream TCL file")

        print("[Success] Run Vivado: : %s file" % (bitFileName))
        return self.runVivadoTcl(bitFileName, logFileName, enStatusVerb, enInfoVerb, enWarningVerb, enCriticalWarningVerb, enErrorVerb)

    def runTCPServerInThread(self, logFileName, enStatusVerb=True, enInfoVerb=True, enWarningVerb=True, enCriticalWarningVerb=True, enErrorVerb=True):
        scriptPath = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

        hwServThread = Thread(target=self.runVivadoTcl, args=("%s/xilinx_tcpserv.tcl" %(scriptPath), logFileName, enStatusVerb, enInfoVerb, enWarningVerb, enCriticalWarningVerb, enErrorVerb))
        hwServThread.daemon = True # thread dies with the program
        hwServThread.start()

        return hwServThread

    def close(self):
        shutil.rmtree(self.tmp_dir)
