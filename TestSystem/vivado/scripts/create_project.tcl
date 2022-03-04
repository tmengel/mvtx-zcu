#

set scriptDir [file dirname [file normalize [info script]]]
set topDir [file normalize $scriptDir/../../ ]

set vhdlSources \
    [list \
	 "[file normalize "$topDir/source/rtl/top/io_ips.vhd"]"\
	 "[file normalize "$topDir/source/rtl/top/clock_generator.vhd"]"\
	 "[file normalize "$topDir/source/rtl/top/fabric_top.vhd"]"\
	 "[file normalize "$topDir/source/rtl/top/RUv1top.vhd"]"\
	]

set ipSources \
    [list \
	 "[file normalize "$topDir/source/ip/gtwizard_ultrascale_0.xcix"]"\
	 "[file normalize "$topDir/source/ip/dcfifo_80x32.xcix"]"\
	 "[file normalize "$topDir/source/ip/scfifo81x16.xcix"]"\
	]

set constraintSources \
    [list \
	 "[file normalize "$topDir/source/constraints/PinConstraints.xdc"]"\
	 "[file normalize "$topDir/source/constraints/TimingConstraints.xdc"]"\
	]


set projName RUv1

cd $topDir/vivado

#-- if the project directory exists, delete it and create a new one
if {[file exists $topDir/vivado/$projName]} {
    file delete -force $topDir/vivado/$projName
    # wait a second to let windows filesystem catch up
    after 1000
}
file mkdir $topDir/vivado/$projName

# Create project
create_project $projName $topDir/vivado/$projName -part xcku060-ffva1156-1-c


# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

#-- Add the vhdl sources
add_files -fileset [get_filesets sources_1] -norecurse $vhdlSources


#-- Add IP cores
add_files -fileset [get_filesets sources_1] -norecurse  $ipSources

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

#-- Add constraints
add_files -fileset [get_filesets constrs_1] -norecurse $constraintSources

#-- Generate the IPs, if there are any
generate_target all [get_ips]

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "design_mode" "RTL" $obj
set_property "loop_count" "1000" $obj
set_property "name" "sources_1" $obj
set_property "top" "RUv1" $obj
set_property "verilog_define" "" $obj
set_property "verilog_uppercase" "0" $obj


# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part xcku060-ffva1156-1-c -flow {Vivado Synthesis 2016} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2016" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property "constrset" "constrs_1" $obj
set_property "description" "Vivado Synthesis Defaults" $obj
set_property "flow" "Vivado Synthesis 2016" $obj
set_property "name" "synth_1" $obj
set_property "needs_refresh" "0" $obj
set_property "part" "xcku060-ffva1156-1-c" $obj
set_property "srcset" "sources_1" $obj
set_property "strategy" "Vivado Synthesis Defaults" $obj
set_property "incremental_checkpoint" "" $obj
set_property "include_in_archive" "1" $obj
set_property "steps.synth_design.tcl.pre" "" $obj
set_property "steps.synth_design.tcl.post" "" $obj
set_property "steps.synth_design.args.flatten_hierarchy" "rebuilt" $obj
set_property "steps.synth_design.args.gated_clock_conversion" "off" $obj
set_property "steps.synth_design.args.bufg" "12" $obj
set_property "steps.synth_design.args.fanout_limit" "10000" $obj
set_property "steps.synth_design.args.directive" "Default" $obj
set_property "steps.synth_design.args.retiming" "0" $obj
set_property "steps.synth_design.args.fsm_extraction" "auto" $obj
set_property "steps.synth_design.args.keep_equivalent_registers" "0" $obj
set_property "steps.synth_design.args.resource_sharing" "auto" $obj
set_property "steps.synth_design.args.control_set_opt_threshold" "auto" $obj
set_property "steps.synth_design.args.no_lc" "0" $obj
set_property "steps.synth_design.args.no_srlextract" "0" $obj
set_property "steps.synth_design.args.shreg_min_size" "3" $obj
set_property "steps.synth_design.args.max_bram" "-1" $obj
set_property "steps.synth_design.args.max_uram" "-1" $obj
set_property "steps.synth_design.args.max_dsp" "-1" $obj
set_property "steps.synth_design.args.max_bram_cascade_height" "-1" $obj
set_property "steps.synth_design.args.max_uram_cascade_height" "-1" $obj
set_property "steps.synth_design.args.cascade_dsp" "auto" $obj
set_property "steps.synth_design.args.assert" "0" $obj
set_property -name {steps.synth_design.args.more options} -value {} -objects $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part xcku060-ffva1156-1-c -flow {Vivado Implementation 2016} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2016" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property "constrset" "constrs_1" $obj
set_property "description" "Default settings for Implementation." $obj
set_property "flow" "Vivado Implementation 2016" $obj
set_property "name" "impl_1" $obj
set_property "needs_refresh" "0" $obj
set_property "part" "xcku060-ffva1156-1-c" $obj
set_property "pr_configuration" "" $obj
set_property "srcset" "sources_1" $obj
set_property "strategy" "Vivado Implementation Defaults" $obj
set_property "incremental_checkpoint" "" $obj
set_property "include_in_archive" "1" $obj
set_property "steps.opt_design.is_enabled" "1" $obj
set_property "steps.opt_design.tcl.pre" "" $obj
set_property "steps.opt_design.tcl.post" "" $obj
set_property "steps.opt_design.args.verbose" "0" $obj
set_property "steps.opt_design.args.directive" "Default" $obj
set_property -name {steps.opt_design.args.more options} -value {} -objects $obj
set_property "steps.power_opt_design.is_enabled" "0" $obj
set_property "steps.power_opt_design.tcl.pre" "" $obj
set_property "steps.power_opt_design.tcl.post" "" $obj
set_property -name {steps.power_opt_design.args.more options} -value {} -objects $obj
set_property "steps.place_design.tcl.pre" "" $obj
set_property "steps.place_design.tcl.post" "" $obj
set_property "steps.place_design.args.directive" "Default" $obj
set_property -name {steps.place_design.args.more options} -value {} -objects $obj
set_property "steps.post_place_power_opt_design.is_enabled" "0" $obj
set_property "steps.post_place_power_opt_design.tcl.pre" "" $obj
set_property "steps.post_place_power_opt_design.tcl.post" "" $obj
set_property -name {steps.post_place_power_opt_design.args.more options} -value {} -objects $obj
set_property "steps.phys_opt_design.is_enabled" "0" $obj
set_property "steps.phys_opt_design.tcl.pre" "" $obj
set_property "steps.phys_opt_design.tcl.post" "" $obj
set_property "steps.phys_opt_design.args.directive" "Default" $obj
set_property -name {steps.phys_opt_design.args.more options} -value {} -objects $obj
set_property "steps.route_design.tcl.pre" "" $obj
set_property "steps.route_design.tcl.post" "" $obj
set_property "steps.route_design.args.directive" "Default" $obj
set_property -name {steps.route_design.args.more options} -value {} -objects $obj
set_property "steps.post_route_phys_opt_design.is_enabled" "0" $obj
set_property "steps.post_route_phys_opt_design.tcl.pre" "" $obj
set_property "steps.post_route_phys_opt_design.tcl.post" "" $obj
set_property "steps.post_route_phys_opt_design.args.directive" "Default" $obj
set_property -name {steps.post_route_phys_opt_design.args.more options} -value {} -objects $obj
set_property "steps.write_bitstream.tcl.pre" "" $obj
set_property "steps.write_bitstream.tcl.post" "" $obj
set_property "steps.write_bitstream.args.raw_bitfile" "0" $obj
set_property "steps.write_bitstream.args.mask_file" "0" $obj
set_property "steps.write_bitstream.args.no_binary_bitfile" "0" $obj
set_property "steps.write_bitstream.args.bin_file" "0" $obj
set_property "steps.write_bitstream.args.readback_file" "0" $obj
set_property "steps.write_bitstream.args.logic_location_file" "0" $obj
set_property "steps.write_bitstream.args.verbose" "0" $obj
set_property -name {steps.write_bitstream.args.more options} -value {} -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:RUv1"
