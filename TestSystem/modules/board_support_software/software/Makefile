VIVADO_VERSION=2016.4
VIVADO_FLAVOUR=Vivado_Lab
VIVADO_PATH=/opt/Xilinx/$(VIVADO_FLAVOUR)/bin/

help:
	(/opt/Xilinx/Vivado_Lab/$(VIVADO_VERSION)/bin/vivado_lab -help)

program_CRU:
	(cd tcl/ && /opt/Xilinx/Vivado_Lab/$(VIVADO_VERSION)/bin/vivado_lab -mode tcl -source program_cru.tcl)

program_RUv1:
	(cd sh/ && python hameg_power.py 0 && cd ../tcl && \
	/opt/Xilinx/Vivado_Lab/$(VIVADO_VERSION)/bin/vivado_lab -mode tcl -source program_RUv1.tcl)
