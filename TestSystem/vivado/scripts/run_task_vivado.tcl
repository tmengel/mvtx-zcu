#-----------------------------------------------------------
# Run Vivado tasks
#
# execute this from within Vivado's tcl console as:
#
# source ./run_task_vivado.tcl
#
#-----------------------------------------------------------
#
#start_gui

set Projname RUv1
set Proj_top RUv1_top
set TargetDevice xcku060-ffva1156-1-c

if {[info exists env(DEBUG_VIVADO)]} {
    set notrace {}
} else {
    set notrace {-notrace }
}

set vivado_script_dir [file normalize [file dirname [info script]]]

open_project $vivado_script_dir/../$Projname/$Projname.xpr

if {$argc > 0} {
    if {$notrace ne ""} {
      eval source $notrace$vivado_script_dir/../../modules/common/software/tcl/suppress_msg_vivado.tcl
    }
    set compile_arg [lindex $argv 0]
    eval source $notrace$vivado_script_dir/../../modules/common/software/tcl/compile_project_vivado.tcl
} else {
    puts "No task provided, y = syntax check, s = synth, i = implementation, b = bitstream gen"
}