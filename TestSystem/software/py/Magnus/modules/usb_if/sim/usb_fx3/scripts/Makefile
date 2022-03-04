# Makefile

#Paths
RUN_DIR ="../run"
MODELSIM=vsim


#targets
main:
	(cd $(RUN_DIR) && $(MODELSIM) -do ../scripts/usb_if_sim.tcl)
coverage:
	(cd $(RUN_DIR) && $(MODELSIM) -do "do ../scripts/usb_if_sim.tcl --cover")

smart:
	(cd $(RUN_DIR) && $(MODELSIM) -do ../scripts/usb_if_sim_smartproducer.tcl)

cypress:
	(cd $(RUN_DIR) && $(MODELSIM) -do ../scripts/usb_if_sim_cypress.tcl)
