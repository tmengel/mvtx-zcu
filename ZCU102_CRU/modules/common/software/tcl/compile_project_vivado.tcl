#-----------------------------------------------------------
# Vivado project compilation script.
# Synthesise, Implement, Bitstream generation
#-----------------------------------------------------------

set arg $compile_arg
    set run_impl [string match "*i*" $arg]
    set run_synth [string match "*s*" $arg]
    set run_syntax [string match "*l*" $arg]
    set run_ip_upgrade [string match "*u*" $arg]

if {$run_ip_upgrade} {
# Upgrade IP cores in the design, only needs to be done with a new Vivado release
    upgrade_ip [get_ips *]
    generate_target all [get_ips *]
    synth_ip [get_ips *]
}

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
