nolog -all

quietly set NumericStdNoWarnings 1
quietly set StdArithNoWarnings 1

onbreak { echo "Break in simulation, quitting";quit -force -code 1 }
onerror { echo "Error in simulation, quitting";quit -force -code 1 }
onElabError { echo "Elaboration error in simulation, quitting";quit -force -code 1 }

run 1000 ms
error "Timeout (1 s) waiting for end of simulation"
