set top_dir "../../.."
set lib_dir "../libs"

source "$top_dir/sim/common/scripts/common_settings.tcl"

map_vivado_libraries $top_dir $lib_dir
map_fifo_32_1024 $top_dir $lib_dir

#design
eval vlog $COM_FLAGS -lint $design_files/usb_if/cntnbit.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/datagen.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/dp_arbtr.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/dpi_fsm.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/dpo_fsm.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/fx3_ctrl.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/regnbit.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/usb_if_wrpr.v
eval vlog $COM_FLAGS -lint $design_files/usb_if/wbmstr.v

eval vcom $COM_FLAGS -lint $design_files/wishbone/wishbone_pkg.vhd  
eval vcom $COM_FLAGS -lint $design_files/usb_if/usb_if.vhd

#Simulation sources
eval vcom $COM_FLAGS -lint $sim_files/usb_fx3/usb_top.vhd  
eval vlog $COM_FLAGS -sv -lint +incdir+$sim_files/usb_fx3 $sim_files/usb_fx3/fx3.sv
eval vlog $COM_FLAGS -sv -lint $sim_files/wishbone/wishbone_slave.sv

#testbench
eval vlog $COM_FLAGS -sv -lint +incdir+$sim_files/usb_fx3 $sim_files/usb_fx3/usb_tb.sv

eval vsim $SIM_FLAGS top
