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

set Projname RUv1
set Proj_top RUv1_top
set TargetDevice xcku060-ffva1156-1-c

if {[info exists env(DEBUG_VIVADO)]} {
    set notrace {}
} else {
    set notrace {-notrace }
}

set vivado_script_dir [file normalize [file dirname [info script]]]
eval source $notrace$vivado_script_dir/../../modules/common/software/tcl/create_project_vivado.tcl


if {$argc > 0} {
    if {$notrace ne ""} {
      eval source $notrace$vivado_script_dir/../../modules/common/software/tcl/suppress_msg_vivado.tcl
    }
    set compile_arg [lindex $argv 0]
    eval source $notrace$vivado_script_dir/../../modules/common/software/tcl/compile_project_vivado.tcl
}
#else {
#    exit 0
#}
