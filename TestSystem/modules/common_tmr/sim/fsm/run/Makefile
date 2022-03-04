SHELL:=/bin/bash
# Makefile

################################################################################
## Title        : sim Makefile
## Project      : RUv0a
################################################################################
## File         : Makefile
## Author       : Matteo Lupi (matteo.lupi@cern.ch)
## Company      : Goethe Universitaet Frankfurt am Main / CERN
## Created      : 2017-03.01
## Last update  : 2017-03.01
################################################################################
## Description: Makefile
##
##              targets:
##
##		check_compile
##			compiles and scan report for error/warnings (sim)
##		sim
##                      starts simulation after compiling and elaborating (compile)
##		compile
##			compiles vhdl, vlog and elaborates (compile_vlog, compile_vhdl, elaborate)
##              compile_vhdl
##                      compiles the vhdl files
##		compile_vlog
##			compiles the vlog files
##		compile_pALPIDE4
##			compiles the ALPIDE lightweight model
##		elaborate
##			elaborates the design
##		compile_fifo
##                      compiles the vhdl fifos
##		compile_ghbl
##			compiles the global vlog module used in sim
##		target
##			shows the actual files lists that are compiled
##		usb_clean_sim_fifo
##                      cleans usb python communication fifo-files (before sim)
##              clean_simlib_ius:
##			cleans the simlib for ius to have a clean compilation
##		help
##			guess what it does...
##############################################################################/
##-----------------------------------------------------------------------------
## Revisions  :
## Date        Version  Author        Description
## 2016-08-02  1.0      ML            Added header
## 2016-08-04  1.0      ML            Adapted to master: pALPIDE model not compiled
## 2016-09-01		ML            Adapted modifications from MB (update to Vivado 2016.1 -> IP change)
##-----------------------------------------------------------------------------

#Paths
TOP=top

# NCelab coverage
NCELAB_COVERAGE_FILE='./coverage.cff'

# VHDL source files
VHDL_SRC='../scripts/vhdl_sources.txt'
VHDL_SRC_SIM='../scripts/vhdl_sources_sim.txt'
VHDL_SRC_IP='../scripts/vhdl_sources_ip.txt'
VHDL_SRC_GBT='../scripts/vhdl_sources_gbt.txt'

# Verilog source files
VLOG_SRC='../scripts/vlog_sources.txt'
VLOG_SRC_IP='../scripts/vlog_sources_ip.txt'
VLOG_SRC_SIM='../scripts/vlog_sources_sim.txt'

# Ip blocks compiled into different work libraries

LIB_PALPIDE4=pALPIDE4_lib

NCELAB_TARG='worklib.$(TOP)'
NCSIM_TARG="worklib.$(TOP)"

#ALPIDE PATH
RELATIVE_PATH_TO_PALPIDE4_PROJECT=../../../source/bench/alpide-lightweight-model/sim/rtl_sim
FILELISTS_PALPIDE4_VERILOG=$(RELATIVE_PATH_TO_PALPIDE4_PROJECT)/run/filelist_lightweight_compile_vhdl.txt
FILELISTS_PALPIDE4_VHDL=$(RELATIVE_PATH_TO_PALPIDE4_PROJECT)/run/filelist_lightweight_compile_verilog.txt

HAL_DESIGN_INFO=../scripts/design_info.hal

#logfiles
NCVHDL_LOGFILE = ncvhdl.log
NCVLOG_LOGFILE = irun.log
NCELAB_LOGFILE = ncelab.log
NCSIM_LOGFILE  = ncsim.log

#filtered warnings
NCVHDL_LOGFILTER = ""
NCVLOG_LOGFILTER = ""
NCELAB_LOGFILTER = "CUSRCH"
NCSIM_LOGFILTER  = ""

NCSIM_OPTS =	-gui \
		-update \
		-covoverwrite \
		-COVSCOPE mmr_register \
		-COVTEST regression \
		-covworkdir ./cov_work
HAL_OPTS =  	-design_info $(HAL_DESIGN_INFO)
NCELAB_OPTS=	-timescale 1ns/1ps \
		-vhdl_time_precision 1ps \
		-override_precision \
		-access +rwc \
		-update \
		-coverage ALL \
		-COVDUT $(NCELAB_TARG) \
		-covfile $(NCELAB_COVERAGE_FILE) \
		-logfile $(NCELAB_LOGFILE)
FLAGS =		-MESSAGES \
		-APPEND_LOG \
		-update \
		-errormax 5
NCVLOG_FLAGS=	$(FLAGS) \
		-compile \
		-logfile $(NCVLOG_LOGFILE)
NCVHDL_FLAGS=	$(FLAGS) \
		-assert \
		-V93 \
		-RELAX \
		-logfile $(NCVHDL_LOGFILE)

#targets
check_compile: sim

	if cat $(NCVHDL_LOGFILE) | grep *E; \
	then cat $(NCVHDL_LOGFILE) | grep *E;\
	else echo "No Errors Founds";\
	fi

	if cat $(NCVHDL_LOGFILE) | grep *W ; \
	then cat $(NCVHDL_LOGFILE) | grep *W ;   \
	else echo "No Warnings Found";\
	fi

	if cat $(NCVLOG_LOGFILE) | grep *E; \
	then cat $(NCVLOG_LOGFILE) | grep *E; \
	else echo "NO ERRORS FOUND"; \
	fi

	if cat $(NCVLOG_LOGFILE) | grep *W ; \
	then cat $(NCVLOG_LOGFILE) | grep *W ; \
	else echo "No Warnings Found" ;\
	fi

	if cat $(NCELAB_LOGFILE) | grep *E; \
	then cat $(NCELAB_LOGFILE) | grep *E; \
	else echo "NO ERRORS FOUND"; \
	fi

	if cat $(NCELAB_LOGFILE) | grep *W |grep -v $(NCELAB_LOGFILTER); \
then cat $(NCELAB_LOGFILE) | grep *W |grep -v $(NCELAB_LOGFILTER); \
	else echo "No Warnings Found" ;\
	fi

	if cat $(NCSIM_LOGFILE) | grep *E; \
	then cat $(NCSIM_LOGFILE) | grep *E;\
	else echo "No Errors Founds";\
	fi

	if cat $(NCSIM_LOGFILE) | grep *W; \
	then cat $(NCSIM_LOGFILE) | grep *W; \
	else echo "No Warnings Found";\
	fi

sim: cleanlog compile
	(ncsim $(NCSIM_OPTS) $(NCSIM_TARG) &)
hal: compile gen_design_info_file
	(hal $(HAL_OPTS) $(NCSIM_TARG):sv)
	(ncbrowse -sortby severity -sortby category -sortby tag hal.log)
gen_design_info_file:
	source ../scripts/gen_design_file_hal.sh $(HAL_DESIGN_INFO) $(VHDL_SRC_SIM) $(VHDL_SRC_IP) \
								   $(VLOG_SRC_IP) \
								   $(FILELISTS_PALPIDE4_VERILOG) $(FILELISTS_PALPIDE4_VHDL)
cleanlog:
	(rm -rf *.log)
compile: compile_vlog elaborate
#compile: compile_vlog compile_vhdl elaborate
compile_vhdl: compile_vhdl_rtl
#compile_vhdl: compile_vhdl_ip compile_vhdl_rtl compile_vhdl_sim

compile_vhdl_ip:
	(ncvhdl $(NCVHDL_FLAGS) -WORK worklib -f $(VHDL_SRC_IP))
compile_vhdl_rtl:
	(ncvhdl $(NCVHDL_FLAGS) -WORK worklib -f $(VHDL_SRC))
compile_vhdl_sim:
	(ncvhdl $(NCVHDL_FLAGS) -WORK worklib -f $(VHDL_SRC_SIM))
compile_vhdl_gbt:
	(ncvhdl $(NCVHDL_FLAGS) -WORK worklib -f $(VHDL_SRC_GBT))

#compile_vlog: compile_vlog_ip compile_vlog_rtl compile_vlog_sim
compile_vlog: compile_vlog_rtl compile_vlog_sim

compile_vlog_rtl:
	(irun $(NCVLOG_FLAGS) -WORK worklib -f $(VLOG_SRC))
compile_vlog_sim:
	(irun $(NCVLOG_FLAGS) -WORK worklib -f $(VLOG_SRC_SIM))
compile_vlog_ip:
	(irun $(NCVLOG_FLAGS) -WORK worklib -f $(VLOG_SRC_IP))


compile_pALPIDE4:
	make -f ${RELATIVE_PATH_TO_PALPIDE4_PROJECT}/scripts/makefile compile \
	CDSLIB_FILE=./cds.lib \
	HDLVAR_FILE=./hdl.var COMPILE_LIB=${LIB_PALPIDE4} \
	RUN_FOLDER_RELATIVE_PATH=${RELATIVE_PATH_TO_PALPIDE4_PROJECT}/run

elaborate:
	(ncelab -relax -messages $(NCELAB_OPTS)  $(NCELAB_TARG))
clean_simlib_ius:
	(rm -rf ../libs_ius)
	(git checkout ../libs_ius)

irun: cleanlog sim_irun ckeck_compile

sim_irun:
	(irun $(FLAGS) -gui -v93 -access rwc -smartorder -covdut $(NCELAB_TARG) \
	-WORK worklib \
	-f $(VHDL_SRC) \
	-f $(VLOG_SRC) \
	-f $(VLOG_SRC_SIM))


target:
	(cat $(VHDL_SRC) && cat $(VLOG_SRC))
irun_doc:
	evince /afs/cern.ch/project/parc/incisiv141/doc/irun/irun.pdf  &
hal_doc:
	evince /afs/cern.ch/project/parc/incisiv141/doc/halref/halref.pdf  &
help:
	(cat Makefile)
