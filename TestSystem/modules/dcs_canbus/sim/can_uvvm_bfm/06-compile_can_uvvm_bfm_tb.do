# Compile sources for CAN HLP module

# Set up util_part_path and lib_name
#------------------------------------------------------
quietly set lib_name "work"
quietly set part_name "dcs_canbus"
# path from mpf-file in sim
quietly set util_part_path "../../../$part_name"

vlib $util_part_path/sim/$lib_name
vmap $lib_name $util_part_path/sim/$lib_name

quietly set compdirectives_vhdl "-2008 -lint -work $lib_name"

quietly set compdirectives_vlog "-mixedsvvh s -93 -suppress 1346,1236 -quiet -work $lib_name +incdir+$util_part_path/source/bench/can_controller/ +incdir+$util_part_path/source/rtl/can_controller/"

echo "\n\n\n=== Compiling $lib_name source\n"

eval vcom  $compdirectives_vhdl   $util_part_path/source/bench/can_bfm/can_uvvm_bfm_tb.vhd
