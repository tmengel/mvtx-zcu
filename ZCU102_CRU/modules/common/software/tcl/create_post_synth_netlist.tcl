open_project ZCU102_CRU/ZCU102_CRU.xpr

foreach mode [list synth impl] {
    open_run ${mode}_1
    write_verilog -force ../sim/src/post_${mode}/ZCU102_CRU_top_post_${mode}.v
}
close_project
exit
