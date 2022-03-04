# Makefile

#Paths
RUN_DIR =../run
#MODELSIM=/opt/mentor/modelsim/105c/modeltech/bin/vsim
MODELSIM=/opt/intelFPGA/17.0/modelsim_ae/bin/vsim
#VIVADO_SIMLIB = /opt/Xilinx/Vivado/2016.4/simlib_modelsim
VIVADO_SIMLIB = /opt/intelFPGA/xilinx64

MODELSIM_CMD = $(MODELSIM) -modelsimini $(VIVADO_SIMLIB)/modelsim.ini -do "do ../scripts/1_all_incl_sim.do"


#targets
main: gui

gui:
	(cd $(RUN_DIR) && $(MODELSIM_CMD))

console:
	(cd $(RUN_DIR) && $(MODELSIM_CMD) -c)

update_filelist:
	(make -C ../../ create_filelist)
