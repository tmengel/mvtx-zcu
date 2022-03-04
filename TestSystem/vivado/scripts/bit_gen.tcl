source $vivado_script_dir/tcl_lib.tcl

set prj_name $Projname

set bitdir "bit"
set mmidir "mmi"
set swtdir "../source/elf_mem"
file mkdir $bitdir
file mkdir $mmidir

set bitpath ${prj_name}/${prj_name}.runs/impl_1

if {[file exist $bitpath/${prj_name}_top.ltx]} {
  file copy -force $bitpath/${prj_name}_top.ltx $bitdir/
}

if {[file exist $bitpath/${prj_name}_top.bit]} {
  file copy -force $bitpath/${prj_name}_top.bit $bitdir/
} else {
  puts "ERROR: no bitstream present"
  exit
}

set bit_file "$bitdir/${prj_name}_top"
## List mem files for murax
set mem_files [list]
set mem_files [split [glob -nocomplain -path $swtdir/murax/ *.mem] " "]

## List mmi files for murax
set mmi_files [list]
set mmi_files [split [glob -nocomplain -path $mmidir/murax/ *] " "]

file copy -force "${bit_file}.bit" "${bit_file}_prog.bit"

set debug 0

foreach mmi_file ${mmi_files} {
  set temp [split  ${mmi_file} "_"]
  set tmr  [lindex ${temp} 1]
  set ecc  [lindex ${temp} 2]
  puts "INFO: Searching mem file for mmi file: ${mmi_file}"
  foreach mem_file ${mem_files} {
    if {[regexp ${tmr} ${mem_file}] && [regexp ${ecc} ${mem_file}]} {
      puts "INFO: Updating mmi file: ${mmi_file}"
      incr debug
      exec updatemem -debug -force --meminfo "${mmi_file}" --data "${mem_file}" --bit "${bit_file}_prog.bit"  --proc soc_inst --out "${bit_file}_prog.bit" > debug${debug}.log
    }
  }
}

## List mem files for murax ecc
set mem_files [list]
set mem_files [split [glob -nocomplain -path $swtdir/murax_ecc/ *.mem] " "]

## List mmi files for murax ecc
set mmi_files [list]
set mmi_files [split [glob -nocomplain -path $mmidir/murax_ecc/ *] " "]

foreach mmi_file ${mmi_files} {
  set temp [split  ${mmi_file} "_"]
  set tmr  [lindex ${temp} 2]
  set ecc  [lindex ${temp} 3]
  puts "INFO: Searching mem file for mmi file: ${mmi_file}"
  foreach mem_file ${mem_files} {
    if {[regexp ${tmr} ${mem_file}] && [regexp ${ecc} ${mem_file}]} {
      puts "INFO: Updating mmi file: ${mmi_file}"
      incr debug
      exec updatemem -debug -force --meminfo "${mmi_file}" --data "${mem_file}" --bit "${bit_file}_prog.bit"  --proc soc_inst --out "${bit_file}_prog.bit" > debug${debug}.log
    }
  }
}

## Update bitstream for Microblaze Cores
set mb_mmi $mmidir/microblaze/top.mmi
if {[file exist $mb_mmi]} {
  set mb_insts [get_instance_paths $mb_mmi]
  foreach mb [list_match $mb_insts mb_tmr0_ecc0] {
    puts "INFO: Updating bitstream for mb_tmr0_ecc0 ($debug)"
    exec updatemem -force -debug \
                   -meminfo $mb_mmi \
                   -data $swtdir/mb_tmr0_ecc0.elf \
                   -bit ${bit_file}_prog.bit \
                   -proc $mb \
                   -out ${bit_file}_prog.bit > mb_t0e0_$debug.log

    incr debug
  }

  foreach mb [list_match $mb_insts mb_tmr1_ecc0] {
    puts "INFO: Updating bitstream for mb_tmr1_ecc0 ($debug)"
    exec updatemem -force -debug \
                   -meminfo $mb_mmi \
                   -data $swtdir/mb_tmr1_ecc0.elf \
                   -bit ${bit_file}_prog.bit \
                   -proc $mb \
                   -out ${bit_file}_prog.bit > mb_t1e0_$debug.log

    incr debug
  }
}

