onerror {resume}
quietly WaveActivateNextPane {} 0
add wave  -noupdate -radix hexadecimal *
configure wave -signalnamewidth 1
configure wave -timelineunits ns
update
