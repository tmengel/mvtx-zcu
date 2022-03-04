set top_dir "../../.."
set lib_dir "../libs"

source "$top_dir/sim/common/scripts/common_settings.tcl"

#design
eval vlog $COM_FLAGS $sim_files/usb_fx3/slaveFIFO2b/fifo.v
eval vlog $COM_FLAGS $sim_files/usb_fx3/slaveFIFO2b/slaveFIFO2b_loopback.v
eval vlog $COM_FLAGS $sim_files/usb_fx3/slaveFIFO2b/slaveFIFO2b_ZLP.v
eval vlog $COM_FLAGS $sim_files/usb_fx3/slaveFIFO2b/slaveFIFO2b_partial.v
eval vlog $COM_FLAGS $sim_files/usb_fx3/slaveFIFO2b/slaveFIFO2b_streamIN.v
eval vlog $COM_FLAGS $sim_files/usb_fx3/slaveFIFO2b/slaveFIFO2b_streamOUT.v
eval vlog $COM_FLAGS $sim_files/usb_fx3/slaveFIFO2b/slaveFIFO2b_fpga_top.v


#Simulation sources
eval vlog $COM_FLAGS -sv -lint +incdir+$sim_files/usb_fx3 $sim_files/usb_fx3/fx3.sv

#testbench
eval vlog $COM_FLAGS -sv -lint +incdir+$sim_files/usb_fx3 $sim_files/usb_fx3/cypress_slfifo_tb.sv

eval vsim $SIM_FLAGS top
