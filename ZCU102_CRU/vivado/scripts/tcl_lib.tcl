proc create_dport {nets probe_number} {
  set nets  [get_nets $nets]
  set nnets [llength $nets]
  # set_property mark_debug true $nets
  if {$probe_number != 0} {
    # Create debug probe only if it is not the first
    create_debug_port u_ila_0 probe
  }
  set_property port_width $nnets [get_debug_ports u_ila_0/probe${probe_number}]
  set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe${probe_number}]
  connect_debug_port u_ila_0/probe${probe_number} $nets
  return [incr probe_number]
}

proc wsplit {str sep} {
  split [string map [list $sep \0] $str] \0
}

proc list_ord_word {list_i word} {
  set  nlist   0
  set  list_in [list]
  foreach object $list_i {
    set temp  [lindex [split $object "\["] 0]
    set temp1 [lindex [wsplit $temp ${word}] 0]
    set temp2 [lindex [wsplit $temp ${word}] 1]
    if {[string index ${temp1} [expr [string length $temp1] - 1]]=="/" && $temp2 == ""} {
      incr nlist
      set  list_in [lappend list_in ${object}]
    }
  }
  set list_o [list]
  set c      0
  while {$c!=$nlist} {
    foreach object $list_in {
      set length [string length $object]
      set i      [lindex [split $object "\["] 1]
      set i      [lindex [split $i "\]"] 0]
      if {$i==$c} {
        puts "INFO: Connecting to debug core net ${object}"
        set list_o      [lappend list_o $object]
        incr c
      }
    }
  }
  return $list_o
}

proc debug_test_circuitry {probe_number murax_insts} {
  foreach murax ${murax_insts} {
    set pins          [get_pins -of_objects [get_cells $murax/test_circuitry_inst]]
    set write_pins    [list_ord_word $pins "write"]
    set read_pins     [list_ord_word $pins "read"]
    set write_en_pins [list_ord_word $pins "write_en"]
    set probe_number  [create_dport  $write_pins    $probe_number]
    set probe_number  [create_dport  $write_en_pins $probe_number]
    set probe_number  [create_dport  $read_pins     $probe_number]
  }
  return $probe_number
}

proc get_instance_paths {mmi_path} {
  set mmi_file [open $mmi_path]
  set mmi_data [split [read $mmi_file]]
  close $mmi_file

  set mmi_inst [list]

  foreach line $mmi_data {
    ## Match content of processor instance
    if {[string match "*InstPath*" $line]} {
      lappend mmi_inst [lindex [split $line \"] 1]
    }
  }

  return $mmi_inst
}

proc list_match {list_i pattern} {
  set matches [list]

  foreach elem $list_i {
    if {[string match *$pattern* $elem]} {
      lappend matches $elem
    }
  }

  return $matches
}
