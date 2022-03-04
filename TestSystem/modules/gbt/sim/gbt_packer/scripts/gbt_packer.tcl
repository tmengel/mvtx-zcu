set ::coverage 0
for {set i 0} {$i < $argc} {incr i} {
    if {[string compare $1 "--cover"] == 0 } {
        set ::coverage 1
    }
    # shift arguments to the left ($2 is now $1)
    shift
}

quietly set vivado_libs $::env(SIMLIB_MODELSIM_PATH)
quietly set XILINX_LIBS {
    unisim
    secureip
    xpm
}

quietly set LIBS ""
foreach lib $XILINX_LIBS {
    append LIBS " -L " $lib
    vmap $lib $vivado_libs/$lib
}



set top_dir "../../.."
set lib_dir "../libs"

set COM_FLAGS "+cover=f -64 -lint"
set OPT_FLAGS "-64 +acc +cover=f"
set SIM_FLAGS "-fsmdebug"

if { $::coverage == 1 } {
    set COM_FLAGS "$COM_FLAGS -coverall -coveropt 1"
    set SIM_FLAGS "$SIM_FLAGS -coverage"
}

set COM_FLAGS_VHDL "$COM_FLAGS -2008"
set COM_FLAGS_VLOG "$COM_FLAGS -incr -warning 1957 -override_timescale \"1 ps / 10 fs\""

#file delete -force $lib_dir/worklib
vlib $lib_dir/worklib
vmap work $lib_dir/worklib

eval vlog $COM_FLAGS_VLOG $top_dir/../common/source/rtl/common/assertions/common_assertions.sv

eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../common_tmr/source/rtl/tmr_pkg.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_wrapper2.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_triplicated_wrapper.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_triplicated_array_wrapper.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_array_wrapper.vhd

eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_packed.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_array.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_triplicated.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/mmr_registers/majority_voter_triplicated_array.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/regnbit/regnbit_1to3.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/regnbit/regnbit_3to1.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/mmr_registers/assertions/mmr_general_assertions.sv
eval vlog $COM_FLAGS_VLOG $top_dir/../common_tmr/source/rtl/mmr_registers/assertions/majority_voter_assertions.sv

eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../wishbone/source/rtl/intercon_pkg.vhd

eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../alpide_frontend/source/rtl/alpide_readout/protocol_tracker.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../alpide_frontend/source/rtl/alpide_readout/alpide_datapath.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/../alpide_frontend/source/rtl/alpide_readout/data_packager.vhd
eval vlog +incdir+../../../../common/source/rtl $COM_FLAGS_VLOG $top_dir/../alpide_frontend/source/rtl/alpide_readout/protocol_checker.sv


eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/source/rtl/gbtx/gbtx_pkg.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/source/rtl/gbtx/gbt_packer/gbt_packer.vhd
eval vcom $COM_FLAGS_VHDL -check_synthesis $top_dir/source/rtl/gbtx/gbt_packer/tmr_wrappers/gbt_packer_tmr_wrapper.vhd

eval vcom $COM_FLAGS_VHDL $top_dir/source/rtl/gbtx/gbt_packer/tmr_wrappers/gbt_packer_tmr_wrapper.vhd
eval vcom $COM_FLAGS_VHDL $top_dir/source/bench/gbt_packer/gbt_packer_error_inject.vhd
eval vlog $COM_FLAGS_VLOG $top_dir/source/bench/gbt_packer/gbt_packer_tb.sv

eval vopt $OPT_FLAGS $LIBS top -o opttop
eval vsim $SIM_FLAGS $LIBS -voptargs="+acc"  opttop

if [file exists wave.do] {
    do wave.do
}
