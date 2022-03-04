# Obtain RAM lists

set gram      [split [all_rams] " "]

# Selects only RAMB36 type and saving the sites in an array

set bram      [list ]
set bramsites [list ]

set c    0
set nram 0

foreach ram $gram {
  set temp [get_property PRIMITIVE_TYPE [get_cells $ram]]
  if {$temp == "BLOCKRAM.BRAM.RAMB36E2" && [regexp "${soc_inst}" $ram] && [regexp "${core_inst}" $ram] && [regexp ${typemem} $ram] } {
    puts "INFO: Bram $ram has been found for core ${soc_inst}/soc_inst/${core_inst}"
    incr nram
  }
}

if {$nram==0} {
  puts "ERROR: no BRAM has been found for core ${soc_inst}/soc_inst/${core_inst} instantiation"
  exit
} else {
  puts "INFO: number of BRAM to be mapped for core ${soc_inst}/soc_inst/${core_inst} is: ${nram}"
}

while {$c!=$nram} {
  foreach ram $gram {

    set temp [get_property PRIMITIVE_TYPE [get_cells $ram]]
    if {$temp == "BLOCKRAM.BRAM.RAMB36E2" && [regexp "${soc_inst}" $ram] && [regexp "${core_inst}" $ram] && [regexp ${typemem} $ram]} {
      set length [string length $ram]
      set i      [string index $ram [expr $length - 3]]
      if {$i==$c || $nram==1} {
        set site [lindex [split [get_sites -of_objects [get_cells $ram]] "_"] 1]
        puts "INFO: Mapping $ram with site $site"
        set bram      [lappend bram      $ram]
        set bramsites [lappend bramsites $site]
        incr c
      }
    }
    # puts $c
  }
}

if {$ecc} {
  set MSB 7
} else {
  set MSB 31
}
puts "INFO: MSB of the data is $MSB"

set address_space     65535
set ram_address_space [expr $address_space / [ expr [expr $MSB + 1] * $nram]]

if {$ecc} {
  if {${typemem}=="ecc_mem"} {
    set fp [open "$mmidir/murax_ecc/murax_tmr${tmr}_ecc${ecc}_core${core}.mmi" "w"]
  } else {
    set fp [open "$mmidir/murax/murax_tmr${tmr}_ecc${ecc}_core${core}.mmi" "w"]
  }
} else {
  set fp [open "$mmidir/murax/murax_tmr${tmr}_ecc${ecc}_core${core}.mmi" "w"]
}
puts $fp "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
puts $fp "<!-- The time is: [clock format [clock seconds] -format %H:%M:%S] -->"
puts $fp "<MemInfo Version=\"1\" Minor=\"1\">"
puts $fp "  <Processor Endianness=\"Little\" InstPath=\"soc_inst\">"
puts $fp "    <AddressSpace Name=\"soc_inst_mem\" Begin=\"0\" End=\"[expr $address_space -1]\">"
puts $fp "      <BusBlock>"

set n 0

foreach bram_1bit $bram {
  set length [string length $bram_1bit]
  puts $fp "        <BitLane MemType=\"RAMB36\" Placement=\"[lindex $bramsites $n]\">"
  puts $fp "          <DataWidth MSB=\"$MSB\" LSB=\"0\"/>"
  puts $fp "          <AddressRange Begin=\"[expr $ram_address_space * $n]\" End=\"[expr [expr $ram_address_space * [expr $n + 1]] -1]\"/>"
  puts $fp "          <Parity ON=\"true\" NumBits=\"0\"/>"
  puts $fp "        </BitLane>"
  incr n
}
puts $fp "      </BusBlock>"
puts $fp "    </AddressSpace>"
puts $fp "  </Processor>"
puts $fp "  <Config>"
puts $fp "    <Option Name=\"Part\" Val=\"xcku060-ffva1156-1-c\"/>"
puts $fp "  </Config>"
puts $fp "</MemInfo>"
close $fp
