set prj_name $Projname

set murax_regex "*murax_tmr?_ecc?_inst"
set soc_insts [get_cells -hier $murax_regex]

set mmidir "mmi"

# file delete -force $mmidir
file mkdir  $mmidir
# file delete -force $mmidir/murax
file mkdir  $mmidir/murax
# file delete -force $mmidir/murax_ecc
file mkdir  $mmidir/murax_ecc
# file delete -force $mmidir/test_bram
file mkdir  $mmidir/test_bram

set core 0
foreach soc_inst $soc_insts {
  set tmr [regexp "_tmr1" $soc_inst]
  set ecc [regexp "_ecc1" $soc_inst]

  set core_insts [list]
  if {$tmr} {
    set core_insts [lappend core_insts  "TMR0/WRP"]
    set core_insts [lappend core_insts  "TMR1/WRP"]
    set core_insts [lappend core_insts  "TMR2/WRP"]
  } else {
    set core_insts [lappend core_insts  "WRP"]
  }

  set typemems [list]
  if {!$ecc} {
    set typemems [lappend typemems "ram_symbol"]
  } else {
    set typemems [lappend typemems "data_mem"]
    set typemems [lappend typemems "ecc_mem"]
  }
  foreach typemem $typemems {
    foreach core_inst $core_insts {
      source $vivado_script_dir/bram_mmi_light.tcl
      incr core
    }
  }
}

set typemems [list]
set typemems [lappend typemems "data_mem"]
set typemems [lappend typemems "ecc_mem"]

## Save MMI file for microblaze cores
set mmifile $prj_name/$prj_name.runs/impl_1/${prj_name}_top.mmi
if {[file exist $mmifile]} {
  # file delete $mmidir/microblaze -force
  file mkdir  $mmidir/microblaze
  file copy -force $mmifile $mmidir/microblaze/top.mmi
}

