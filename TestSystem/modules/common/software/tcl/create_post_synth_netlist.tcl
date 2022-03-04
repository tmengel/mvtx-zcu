open_project RUv1/RUv1.xpr

foreach mode [list synth impl] {
    open_run ${mode}_1
    write_verilog -force ../sim/src/post_${mode}/RUv1_top_post_${mode}.v
}
close_project
exit
