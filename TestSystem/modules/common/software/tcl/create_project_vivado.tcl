#-----------------------------------------------------------
# Vivado project generation script.
#
# execute this from within Vivado's tcl console as:
#
# source ./create_project_vivado.tcl
#
#-----------------------------------------------------------
#
#start_gui

# set some default directories used
set scriptDir [file normalize [file dirname [info script]]]
eval source $notrace$scriptDir/set_defaults.tcl

# Generate a tcl list from a x_sources.txt list.
# Expects one source per line
proc listFromFile {filename} {

    set f [open $filename r]
    set data [split [string trim [read $f]] "\n"]
    set data_filtered {}
    foreach item $data {
        set matches [string match "#*" $item]
        if {$matches == 0} {
            regsub -all {\+incdir\+[^ ]* } $item "" item_replaced
            lappend data_filtered $item_replaced
        }
    }
    close $f
    return $data_filtered
}

set synSources_vhdl [listFromFile $topDir/vhdl_sources.txt]
set synSources_vlog [listFromFile $topDir/vlog_sources.txt]
set includeDirectories [listFromFile $topDir/vlog_includes.txt]
set simSources_vhdl [listFromFile $topDir/vhdl_sources_sim.txt]
set simSources_vlog [listFromFile $topDir/vlog_sources_sim.txt]
set ipSources [listFromFile $topDir/ip_sources.txt]
set constraintSources [listFromFile $topDir/sdc_sources.txt]

set synSources [list {*}$synSources_vhdl {*}$synSources_vlog]
#set simSources [list {*}$simSources_vhdl {*}$simSources_vlog]

cd $topDir/vivado

# If the project directory exists, delete it and create a new one
if {[file exists $topDir/vivado/$Projname]} {
    file delete -force $topDir/vivado/$Projname
    # wait a second to let windows filesystem catch up
    after 1000
}
file mkdir $topDir/vivado/$Projname

# If the bit directory exists, delete it and create a new one
if {[file exists $topDir/vivado/bit]} {
    file delete -force $topDir/vivado/bit
    # wait a second to let windows filesystem catch up
    after 1000
}
file mkdir $topDir/vivado/bit

# Create the project and set properties
create_project $Projname $topDir/vivado/$Projname -part $TargetDevice

set_property target_language VHDL [current_project]
set_property simulator_language MIXED [current_project]
set_property target_simulator ModelSim [current_project]

# https://www.xilinx.com/support/answers/67235.html
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]


if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Add IP Source Files
read_ip $ipSources

# Generate the IPs, if there are any so referenced files in filelist can be included
#generate_target all [get_ips]

# Add rest of source files
add_files -fileset [get_filesets sources_1] -norecurse $synSources
#add_files -fileset [get_filesets sim_1] -norecurse $simSources

set_property "file_type" "Verilog Header" [get_files */wrapper_functions.v]

# Set all VHDL to 2008, *.v is default v-2005 and .sv is sv
set_property file_type {VHDL 2008} [get_files -filter {IS_GENERATED == FALSE} *.vhd]

set_property include_dirs $includeDirectories [current_fileset]
set_property include_dirs $includeDirectories [get_filesets sim_1]


# Create 'utils_1' fileset (if not found)
if {[string equal [get_filesets -quiet utils_1] ""]} {
  create_fileset -constrset utils_1
}

# Add pre-post hook tcl script
add_files -fileset [get_filesets utils_1] $scriptDir/create_git_hash.tcl


# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Add constraints
add_files -fileset [get_filesets constrs_1] -norecurse $constraintSources

# some constraints seem to cause issues during synthesis, so don't use them in synthesis
set_property USED_IN_SYNTHESIS false [get_files  */TimingConstraints.xdc]
#set_property USED_IN_SYNTHESIS false [get_files  */Bitstream_settings.xdc]
#set_property USED_IN_SYNTHESIS false [get_files  */debug_cores.xdc]
#set_property USED_IN_SYNTHESIS false [get_files  */xclk_reg.xdc]

# Set top entity and update compile order
set_property top $Proj_top [current_fileset]
update_compile_order -fileset sources_1
set_property top $Proj_top [get_filesets sim_1]
update_compile_order -fileset sim_1

# Sets severity for inferred latch to ERROR
#syntax: set_msg_config -severity warning -string "Synth" -id "8-327" -new_severity error
# Inferred Latch
set_msg_config -id {Synth 8-327} -new_severity {ERROR}
# signal not in sensitivity list
set_msg_config -id {Synth 8-614} -new_severity {ERROR}
# Timing loop
set_msg_config -id {Synth 8-295} -new_severity {ERROR}

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -flow {Vivado Synthesis $::env(VIVADO_YEAR)} \
        -strategy "Vivado Synthesis Defaults" -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis $::env(VIVADO_YEAR)" [get_runs synth_1]
}

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -flow {Vivado Implementation $::env(VIVADO_YEAR)} \
        -strategy "Vivado Implementation Defaults" -constrset constrs_1 \
        -parent_run synth_1
} else {
    set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
    set_property flow "Vivado Implementation $::env(VIVADO_YEAR)" [get_runs impl_1]
}
set_property report_strategy {UltraFast Design Methodology Reports} [get_runs impl_1]

# synth properties to avoid FSM extraction automatically done by the tool.
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION sequential [get_runs synth_1]
# synth properties to avoid equivalent registers to be removed.
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
# properties for Synth to avoid automatic SRL extract.
set_property STEPS.SYNTH_DESIGN.ARGS.NO_SRLEXTRACT true [get_runs synth_1]

# Readback files generation added
#set_property STEPS.WRITE_BITSTREAM.ARGS.MASK_FILE true [get_runs impl_1]
#set_property STEPS.WRITE_BITSTREAM.ARGS.READBACK_FILE true [get_runs impl_1]
#set_property STEPS.WRITE_BITSTREAM.ARGS.LOGIC_LOCATION_FILE true [get_runs impl_1]

# setup the generics for Git Hash
eval source $notrace$scriptDir/create_git_hash.tcl

# set property of githash and date at compilation time
puts [file dirname [info script]]
set_property STEPS.SYNTH_DESIGN.TCL.PRE $scriptDir/create_git_hash.tcl [get_runs synth_1]
