#-----------------------------------------------------------
# Vivado project compilation script.
# Synthesise, Implement, Bitstream generation
#-----------------------------------------------------------

set arg $compile_arg
    set run_impl [string match "*i*" $arg]
    set run_synth [string match "*s*" $arg]
    set run_syntax [string match "*l*" $arg]

if {$run_syntax} {
# Check syntax first since errors from the synthesis might be cryptic
    check_syntax -fileset sources_1
}

if {$run_synth} {
# launch synthesis and wait for it to finish
    reset_run synth_1
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
}

if {$run_impl} {
    # launch implementation and wait for it to finish
    launch_runs impl_1 -to_step write_bitstream -jobs 8
    wait_on_run impl_1
}

# check_timing -verbose -file my_timing_report.txt
