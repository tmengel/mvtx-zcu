# Makefile

################################################################################
## Title        : ZCU_CRU main FPGA Makefile
## Project      : ITS
################################################################################
## File         : Makefile
## Author       : Matteo Lupi (matteo.lupi@cern.ch)
## Company      : Goethe Universitaet Frankfurt am Main / CERN
## Author       : Matthias Bonora (matthias.bonora@cern.ch)
## Company      : University of Salzburg / CERN
## Created      : 2015-07-05
## Last update  : 2019-11-25
################################################################################
## Description: Makefile
##
## targets:
##
##    restore
##      Opens the vivado project in gui
##    cp
##      Copies the actual fw with the current date/name/githash in name
##    scp
##      Copies the bitfiles to the FLP pre_release bitfile folder
##    batch_create_run
##      Erases the old project and regenerates it
##      (executes create_project_vivado) in batch mode
##      and runs the tasks specified as paramteres afterwards
##    batch_run
##      Opens existing project in batch mode and runs specified tasks
##    check_vivado:
##      Executes a check on the vivado log file
##    batch
##      Executes batch_execute, check_vivado and cp commands
##    upgrade
##      Runs IP upgrade in addition to full flow, used when updating Vivado
##    gui
##      Erases the old project and regenerates it
##      (executes create_project_vivado) in gui mode
##    create_ecc_bitfiles
##  	Creates the ecc bitfiles
##    create_filelist
##      Generates file lists used in synthesis and simulation
##    alpide_lightweight
##      Generates alpide leightweight filelist used in simulation
##    compile_simlib_ius
##      Compiles vivado sim libs for CADENCE ncsim
##    compile_simlib_modelsim
##      Compiles vivado sim libs for questasim
##    compile_simlib_questasim
##      Compiles vivado sim libs for questasim
##    program_ru
##       Programs connected RU, provide path to bitfile as parameter
##    bug_report
##      Generates a bug report file to be attached to the gitlab.cern.ch in the issue
##    help
##      guess what it does...
##############################################################################/
##-----------------------------------------------------------------------------
## Revisions  :
## Date        Version  Author        Description
## 2016-07-07  1.0      ML            Added header
## 2016-07-18           ML            Adapted to RUv0a (program* to
##                                    be implemented in RUv0a)
## 2016-08-08           ML            Added Vivado version as variable
## 2016-09-01           ML            Porting sim environment to 2016.1
## 2017-10-23           AV            Adapt for Windows and Questa
## 2017-01-21           AV            Enable running batch runs without recreating project
## 2019-01-16           ML            Added bug_report target
## 2019-03-30           ML            Added create_ecc_bitfiles
## 2019-11-22           AV            Add upgrade options
## 2019-11-25           ML            Fixed issue with timing grep catching Critical Cell
##                                    instead of Critical Warning
## 2020-01-20           ML            Added scp target
##-----------------------------------------------------------------------------
#xterm -e emacs +[line number] [file name]
#Paths
RUN_DIR ="vivado"
include env_var.mk
-include env_var_local.mk
PRJ_NAME=ZCU102_CRU
TOP_NAME=$(PRJ_NAME)_top

# Set DEBUG_VIVADO in environment to make scripts echo commands and to turn off
# message suppression in Vivado
ifndef DEBUG_VIVADO
  NOTRACE="-notrace"
else
  NOTRACE=""
endif

CREATE_FILELIST_SCRIPT="modules/common/software/py/create_filelist.py"
SIMLIB_IUS_SCRIPT="modules/common/software/tcl/compile_simlib_ius.tcl"
SIMLIB_IUS_PATH="${VIVADO_PATH}/${VIVADO_VER}/simlib_ius"
SIMLIB_MODELSIM_SCRIPT="modules/common/software/tcl/compile_simlib_modelsim.tcl"


ifeq ($(OS),Windows_NT)
  VIV_KIT="$(VIVADO_PATH)/$(VIVADO_VER)/settings64.bat"
else
  VIV_KIT=source $(VIVADO_PATH)/$(VIVADO_VER)/settings64.sh
endif

GIT_CHANGES=$(shell git status -uno --porcelain)
ifeq ($(GIT_CHANGES),)
  GIT_UNCOM=
else
  GIT_UNCOM=_uncommittedSources
endif
IMPL_NR=1
CP_FROM_PATH_L=vivado/$(PRJ_NAME)/$(PRJ_NAME).runs/impl_$(IMPL_NR)/
ifeq ($(OS),Windows_NT)
  CP=copy
  CP_FROM_PATH=$(subst /,\,$(CP_FROM_PATH_L))
  BF_DATE=$(shell powershell "(get-item $(CP_FROM_PATH_L)$(TOP_NAME).bit).LastWriteTime.ToString('yyMMdd_HHmm')")
  SUPRESS=|| exit /B 0
else
  CP=cp
  SCP=scp
  CP_FROM_PATH=$(CP_FROM_PATH_L)
  BF_DATE=$(shell date -r $(CP_FROM_PATH)$(TOP_NAME).bit +%y%m%d_%H%M)
  SUPRESS=|| :
endif
CP_TO_PATH=$(TOP_NAME)_$(BF_DATE)_$(shell git log -1 --pretty=%h --abbrev=8)$(GIT_UNCOM)

VIVADO_LOG='vivado/vivado.log'
TIMING_REPORT=${CP_FROM_PATH}post_route_phys_opt_report_timing_summary_0.rpt
CHECK_TIMING_SCRIPT=modules/common/software/py/verify_timing.py


BUG_REPORT_FILE = bug_report.log

#targets
restore:
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode gui $(PRJ_NAME)/$(PRJ_NAME).xpr)

cp:
	$(CP) $(CP_FROM_PATH)$(TOP_NAME).bit $(CP_TO_PATH).bit
	-$(CP) $(CP_FROM_PATH)$(TOP_NAME).ltx  $(CP_TO_PATH).ltx $(SUPRESS)
	-$(CP) $(CP_FROM_PATH)$(TOP_NAME).mcs $(CP_TO_PATH).mcs $(SUPRESS)
	-$(CP) $(CP_FROM_PATH)$(TOP_NAME).prm $(CP_TO_PATH).prm $(SUPRESS)

batch_create_run: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode batch -source "scripts/create_project_vivado.tcl" $(NOTRACE) \
	-tclargs $(word 2, $(MAKECMDGOALS)))

batch_create_run_all: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode batch -source "scripts/create_project_vivado.tcl" $(NOTRACE) \
	-tclargs "lsi")

batch_create_run_all_upgrade: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode batch -source "scripts/create_project_vivado.tcl" $(NOTRACE) \
	-tclargs "ulsi")

batch_run:
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode batch -source "scripts/run_task_vivado.tcl" $(NOTRACE) \
	-tclargs $(word 2, $(MAKECMDGOALS)))

check_vivado:
ifeq ($(OS),Windows_NT)
else
	@(echo '-----------------------------------------------------------------------------')
	@(echo '-----------------------------------------------------------------------------')
	@(echo '---------<<<<<<---REPORTING ERRORS/WARNINGS/TIMING--->>>>>>------------------')
	@(echo '-----------------------------------------------------------------------------')

	@(if cat ${VIVADO_LOG} | grep Errors|grep -v '0 Errors'|grep -v '|Errors'; \
	then cat ${VIVADO_LOG} | grep Errors|grep -v '0 Errors'|grep it-v '|Errors';\
	else echo "No Error found";\
	fi)

	@(if cat ${VIVADO_LOG} | grep -i 'Critical Warning' | grep -i -v '0 Critical Warnings'; \
	then cat ${VIVADO_LOG} | grep -i 'Critical Warning' | grep -i -v '0 Critical Warnings'; \
	else echo "No Critical Warning found";\
	fi)

	@(echo '-----------------------------------------------------------------------------')
	@(echo '-----------------------------------------------------------------------------')
	@(if [ -f ${TIMING_REPORT} ]; then (cat ${TIMING_REPORT} | grep "Design Timing Summary" -B 2 -A 10); fi)
	@(echo '-----------------------------------------------------------------------------')
endif

check_timing:
	python ${CHECK_TIMING_SCRIPT} ${TIMING_REPORT}

batch: batch_create_run_all check_vivado check_timing cp

upgrade: batch_create_run_all_upgrade check_vivado check_timing cp

gui: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode gui -source "scripts/create_project_vivado.tcl" $(NOTRACE) \
	-tclargs $(filter-out $@,$(MAKECMDGOALS)))

create_filelist:
ifeq ($(OS),Windows_NT)
	python $(CREATE_FILELIST_SCRIPT) $(shell cd)
else
	python $(CREATE_FILELIST_SCRIPT) $(shell pwd)
endif

# Compile simlib for ncsim
compile_simlib_ius:
	(echo "trying to create $(SIMLIB_IUS_PATH). Please check for permission...")
	([ -d $(SIMLIB_IUS_PATH) ] || mkdir $(SIMLIB_IUS_PATH))
	($(VIV_KIT) && cd $(RUN_DIR) && (echo "INCLUDE $(IUS_PATH)/../inca/files/cds.lib" > cds.lib) && \
	(vivado -mode batch -source ../$(SIMLIB_IUS_SCRIPT) -tclargs $(SIMLIB_IUS_PATH) $(IUS_PATH)) && \
	(sed -i '/INCLUDE/d' $(SIMLIB_IUS_PATH)/cds.lib))

compile_simlib_modelsim:
	($(VIV_KIT) && cd $(RUN_DIR) && (vivado -mode batch -source ../$(SIMLIB_MODELSIM_SCRIPT) \
	-tclargs $(SIMLIB_MODELSIM_PATH) modelsim $(MODELSIM_PATH)))

compile_simlib_questasim:
	($(VIV_KIT) && cd $(RUN_DIR) && (vivado -mode batch -source ../$(SIMLIB_MODELSIM_SCRIPT) \
	-tclargs $(SIMLIB_MODELSIM_PATH) questa $(MODELSIM_PATH) $(MODELSIM_PATH)/../gcc64/bin))


ci_lint_check:
	find . -iname "*.py" ! -path '*/obsolete/*' | xargs pylint --rcfile=.pylintrc --errors-only

ci_lint_all:
	find . -iname "*.py"  ! -path '*/obsolete/*' | xargs pylint --rcfile=.pylintrc

generate_verilog_netlists:
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode tcl -source "../modules/common/software/tcl/create_post_synth_netlist.tcl")

bug_report:
	(echo -e 'Head:\n'>$(BUG_REPORT_FILE) && git log -1 --decorate >> $(BUG_REPORT_FILE) && echo -e "\n\nStatus:\n" >> $(BUG_REPORT_FILE) && git status --porcelain >> $(BUG_REPORT_FILE) && echo -e "\n\nDiff:\n" >> $(BUG_REPORT_FILE) && git diff >> $(BUG_REPORT_FILE) && echo -e "\nDone! You can find the bur report in "$(BUG_REPORT_FILE))

help:
	(cat Makefile | grep '##')

environment:
	($(VIV_KIT) && /bin/bash)

%:
	@:
