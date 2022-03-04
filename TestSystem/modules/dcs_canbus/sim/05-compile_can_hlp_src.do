# Compile sources for CAN HLP module

# Set up util_part_path and lib_name
#------------------------------------------------------
quietly set lib_name "work"
quietly set part_name "dcs_canbus"
# path from mpf-file in sim
quietly set util_part_path "../..//$part_name"

vlib $util_part_path/sim/$lib_name
vmap $lib_name $util_part_path/sim/$lib_name

quietly set compdirectives_vhdl "-2008 -lint -work $lib_name"

quietly set compdirectives_vlog "-suppress 1346,1236 -quiet -work $lib_name +incdir+$util_part_path/source/rtl/can_controller/"

echo "\n\n\n=== Compiling $lib_name source\n"

eval vcom  $compdirectives_vhdl   $util_part_path/../common/source/rtl/xpm_cdc_components_pkg.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/../common_tmr/source/rtl/tmr_pkg.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/../wishbone/source/rtl/intercon_pkg.vhd
eval vlog  $compdirectives_vlog   $util_part_path/../wishbone/source/rtl/assertions/wishbone_slave_checker_sv.sv
eval vcom  $compdirectives_vhdl   $util_part_path/../wishbone/source/rtl/assertions/wishbone_slave_checker.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/source/rtl/can_hlp/can_hlp_glue_pkg.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/source/rtl/can_hlp/can_hlp_glue.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/source/rtl/can_hlp/can_hlp_pkg.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/source/rtl/can_hlp/can_hlp.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/source/rtl/can_hlp/can_hlp_wb_slave_regs_pkg.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/source/rtl/can_hlp/can_hlp_wb_slave_regs.vhd
eval vcom  $compdirectives_vhdl   $util_part_path/source/rtl/can_hlp/can_hlp_top.vhd
