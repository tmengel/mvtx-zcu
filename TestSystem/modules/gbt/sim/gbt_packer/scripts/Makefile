# Makefile

include ../../../../../env_var.mk
-include ../../../../../env_var_local.mk

#Paths
RUN_DIR ="../run"
MODELSIM=$(MODELSIM_PATH)/vsim

MODELSIM_CMD = $(MODELSIM) -do "do ../scripts/gbt_packer.tcl"
MODELSIM_CMD_COVER = $(MODELSIM) -do "do ../scripts/gbt_packer.tcl --cover"

#MODELSIM_CMD = $(MODELSIM)  -do
#MODELSIM_CMD_COVER = $(MODELSIM) -modelsimini $(VIVADO_SIMLIB)/modelsim.ini -do "


#targets
main: gui

gui:
	(cd $(RUN_DIR) && $(MODELSIM_CMD))
console:
	(cd $(RUN_DIR) && $(MODELSIM_CMD) -c)

coverage:
	(cd $(RUN_DIR) && $(MODELSIM_CMD_COVER))
