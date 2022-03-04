# Update netlist of test_micro
set scriptDir [file dirname [info script]]
update_design -cells [get_cells -hier TEST_MICRO_inst] -from_file $scriptDir/../../source/edif/cfg_generic.edf
write_checkpoint -force -noxdef RUv1_top.dcp