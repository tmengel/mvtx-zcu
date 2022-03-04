SHELL:=/bin/bash
# Makefile

################################################################################
## Title        : RUv1 Makefile
## Project      : RUv1
################################################################################
## File         : Makefile
## Author       : Matteo Lupi (matteo.lupi@cern.ch)
## Company      : Goethe Universitaet Frankfurt am Main / CERN
## Author       : Matthias Bonora (matthias.bonora@cern.ch)
## Company      : University of Salzburg / CERN
## Created      : 2015-07-05
## Last update  : 2016-07-21
################################################################################
## Description: Makefile
##
## targets:
##
##    restore
##      Opens the vivado project in gui
##    cp
##      Copies the actual fw with the current date/name/githash in name
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
##    gui
##      Erases the old project and regenerates it
##      (executes create_project_vivado) in gui mode
##    create_filelist
##      Generates file lists used in synthesis and simulation
##    alpide_lightweight
##      Generates alpide leightweight filelist used in simulation
##    compile_simlib_ius
##      Compiles vivado sim libs for CADENCE ncsim
##    compile_simlib_modelsim
##      Compiles vivado sim libs for questasim
##    compile_simlib_modelsim
##      Compiles vivado sim libs for questasim
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
##-----------------------------------------------------------------------------
#xterm -e emacs +[line number] [file name]
#Paths
RUN_DIR ="vivado"
include env_var.mk
-include env_var_local.mk
PRJ_NAME=RUv1
TOP_NAME=$(PRJ_NAME)_top
GIT_TOP_FOLDER=`git rev-parse --show-toplevel`

# Set DEBUG_VIVADO in environment to make scripts echo commands and to turn off
# message suppression in Vivado
ifndef DEBUG_VIVADO
  NOTRACE="-notrace"
else
  NOTRACE=""
endif

CREATE_FILELIST_SCRIPT="modules/common/software/py/create_filelist.py"
LWMODEL_PATH=modules/alpide_lightweight
LWMODEL_FILELIST_SCRIPT=$(LWMODEL_PATH)/sim/rtl_sim/scripts/
SIM_RUN_DIR="sim/run"
SIMLIB_IUS_SCRIPT="modules/common/software/tcl/compile_simlib_ius.tcl"
SIMLIB_IUS_PATH="${VIVADO_PATH}/${VIVADO_VER}/simlib_ius"
SIMLIB_MODELSIM_SCRIPT="modules/common/software/tcl/compile_simlib_modelsim.tcl"


ifeq ($(OS),Windows_NT)
  VIV_KIT="${VIVADO_PATH}/${VIVADO_VER}/settings64.bat"
else
  VIV_KIT=source ${VIVADO_PATH}/${VIVADO_VER}/settings64.sh
endif

IMPL_NR=1
CP_FROM_PATH=vivado/${PRJ_NAME}/${PRJ_NAME}.runs/impl_${IMPL_NR}/
CP_BF_FROM_PATH=vivado/bit/
CP_TO_PATH=${PRJ_NAME}_top_`date -r ${CP_FROM_PATH}${PRJ_NAME}_top.bit +%y%m%d_%H%M`_`git log -1 --pretty=%h``source modules/common/software/sh/git_check.sh`.

VIVADO_LOG='vivado/vivado.log'
TIMING_REPORT=${CP_FROM_PATH}route_report_timing_summary_0.rpt
CHECK_TIMING_SCRIPT=modules/common/software/py/verify_timing.py

MODULES = alpide_frontend common common_tmr gbt i2c usb_if wishbone
SUBMODULE_PUSH_BRANCH=RUv1_dev

#targets
restore:
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode gui $(PRJ_NAME)/$(PRJ_NAME).xpr)

cp:
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.bit ]; then cp ${CP_FROM_PATH}${TOP_NAME}.bit ${CP_TO_PATH}bit; fi
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.mcs ]; then cp ${CP_FROM_PATH}${TOP_NAME}.mcs ${CP_TO_PATH}mcs; fi
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.prm ]; then cp ${CP_FROM_PATH}${TOP_NAME}.prm ${CP_TO_PATH}prm; fi
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.ebd ]; then cp ${CP_FROM_PATH}${TOP_NAME}.ebd ${CP_TO_PATH}ebd; fi
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.ebc ]; then cp ${CP_FROM_PATH}${TOP_NAME}.ebc ${CP_TO_PATH}ebc; fi
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.msd ]; then cp ${CP_FROM_PATH}${TOP_NAME}.msd ${CP_TO_PATH}msd; fi
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.rbd ]; then cp ${CP_FROM_PATH}${TOP_NAME}.rbd ${CP_TO_PATH}rbd; fi
	if [ -f ${CP_FROM_PATH}${TOP_NAME}.ll  ]; then cp ${CP_FROM_PATH}${TOP_NAME}.ll  ${CP_TO_PATH}ll ; fi
	if [ -f ${CP_FROM_PATH}debug_nets.ltx ]; then cp ${CP_FROM_PATH}debug_nets.ltx ${CP_TO_PATH}ltx; fi

batch_create_run: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode batch -source "scripts/create_project_vivado.tcl" $(NOTRACE) \
	-tclargs $(word 2, $(MAKECMDGOALS)))

batch_create_run_all: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode batch -source "scripts/create_project_vivado.tcl" $(NOTRACE) \
	-tclargs "lsi")

batch_run: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode batch -source "scripts/run_task_vivado.tcl" $(NOTRACE) \
	-tclargs $(word 2, $(MAKECMDGOALS)))

check_vivado:
	(echo '-----------------------------------------------------------------------------')
	(echo '-----------------------------------------------------------------------------')
	(echo '---------<<<<<<---REPORTING ERRORS/WARNINGS/TIMING--->>>>>>------------------')
	(echo '-----------------------------------------------------------------------------')

	(if cat ${VIVADO_LOG} | grep Errors|grep -v '0 Errors'|grep -v '|Errors'; \
	then cat ${VIVADO_LOG} | grep Errors|grep -v '0 Errors'|grep it-v '|Errors';\
	else echo "No Errors Founds";\
	fi)

	(if cat ${VIVADO_LOG} | grep Critical|grep -v '0 Critical Warnings'; \
	then cat ${VIVADO_LOG} | grep Critical|grep -v '0 Critical Warnings'; \
	else echo "No Critical Warning Founds";\
	fi)

	(echo '-----------------------------------------------------------------------------')
	(echo '-----------------------------------------------------------------------------')
	if [ -f ${TIMING_REPORT} ]; then (cat ${TIMING_REPORT} | grep "Design Timing Summary" -B 2 -A 10); fi
	(echo '-----------------------------------------------------------------------------')

check_timing:
	python ${CHECK_TIMING_SCRIPT} ${TIMING_REPORT}

batch: batch_create_run_all check_vivado check_timing cp

gui: create_filelist
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode gui -source "scripts/create_project_vivado.tcl" $(NOTRACE) \
	-tclargs $(filter-out $@,$(MAKECMDGOALS)))

create_filelist:
ifeq ($(OS),Windows_NT)
	python $(CREATE_FILELIST_SCRIPT) $(shell cd)
else
	python $(CREATE_FILELIST_SCRIPT) $(shell pwd)
endif

alpide_lightweight:
ifeq ($(OS),Windows_NT)
	(cd ./$(LWMODEL_FILELIST_SCRIPT) && gen_compile_list.sh  ".")
else
	$(shell pwd)/$(LWMODEL_FILELIST_SCRIPT)gen_compile_list.sh  $(shell pwd)/$(LWMODEL_PATH)/sim/rtl_sim/scripts
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
	-tclargs $(SIMLIB_MODELSIM_PATH) questa $(MODELSIM_PATH)))


git_subtree_update_all:
	($(foreach module,$(MODULES),git subtree pull -m "Update submodule $(module)" --prefix=modules/$(module) --squash submodule_$(module) master;))

git_subtree_push_all:
	($(foreach module,$(MODULES),git subtree push -P modules/$(module) submodule_$(module) $(SUBMODULE_PUSH_BRANCH);))

git_subtree_add_remote_all:
	($(foreach module,$(MODULES),git remote add submodule_$(module) ssh://git@gitlab.cern.ch:7999/alice-its-wp10-firmware/submodule_$(module).git;))
	(git remote update)

ebd_analyse:
	(source modules/common/software/sh/essential_bits.sh $(filter-out $@, $(MAKECMDGOALS)))

generate_verilog_netlists:
	($(VIV_KIT) && cd $(RUN_DIR) && vivado -mode tcl -source "../modules/common/software/tcl/create_post_synth_netlist.tcl")

help:
	(cat Makefile | grep '##')

environment:
	($(VIV_KIT) && /bin/bash)

%:
	@:
