set RXMode [get_property RX_OPTIMIZATION [get_cells -hier -filter {NAME =~ *gbtExmplDsgn_inst}]]
set TXMode [get_property RX_OPTIMIZATION [get_cells -hier -filter {NAME =~ *gbtExmplDsgn_inst}]]
set RXClockGen [get_cells -hier -filter {NAME =~ *gbtExmplDsgn_inst*rxFrmClkPhAlgnr*pll*}]

set ClockScheme [get_property CLOCKING_SCHEME [get_cells -hier -filter {NAME =~ *gbtExmplDsgn_inst}]]

if { $RXMode == 1 && $RXClockGen != "" } {
    set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {gbtExmplDsgn_inst/gbtBank_Clk_gen[1].gbtBank_rxFrmClkPhAlgnr/latOpt_pll_phalgnr_gen.pll_inst/pll_inst/inst/mmcme3_adv_inst/CLKOUT0}]]

    set_multicycle_path -from [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *gbtBank*RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *gbtBank_rxFrmClkPhAlgnr*CLKOUT0}]] -setup -start 6
    set_multicycle_path -from [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *gbtBank*RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *gbtBank_rxFrmClkPhAlgnr*CLKOUT0}]] -hold -start 5

} 

if { $ClockScheme == 1 } {
#Only when the FULL MGT clock scheme is used:
	#Hold multicycle of 1 to enabled driven destination registers
	
	if { $RXMode == 1 } {
        #Values depends on the RX_GEARBOXSYNCSHIFT_COUNT constant value defined into the alt_ax_gbt_bank_package.vhd file
        set_multicycle_path 3 -from [get_pins -hier -filter {NAME =~  *gbt_inst*rxGearboxLatOpt_gen*reg*}] -end -setup
        set_multicycle_path 2 -from [get_pins -hier -filter {NAME =~  *gbt_inst*rxGearboxLatOpt_gen*reg*}] -end -hold
	}
	
    if { $RXMode == 0 } {
        #Values depends on the RX_GEARBOXSYNCSHIFT_COUNT constant value defined into the alt_ax_gbt_bank_package.vhd file
        set_multicycle_path 3 -from [get_pins -hier -filter {NAME =~  *gbt_inst*rxGearboxStd_gen*ram*}]  -end -setup
        set_multicycle_path 2 -from [get_pins -hier -filter {NAME =~  *gbt_inst*rxGearboxStd_gen*ram*}]  -end -hold
    }
}