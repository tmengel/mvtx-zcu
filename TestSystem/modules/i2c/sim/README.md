## I2C Simulation

The test bench source file for this simulation test bench is in:

RUv0a/source/bench/i2c

The RTL code to be simulated is in

RUv0a/source/rtl/i2c

Additional source file needed (for wishbone signals):

RUv0a/source/rtl/wishbone/wishbone_pkg.vhd

This simulation uses the "Bitvis Utility Library (v2.6.0)" which is located in:

../src/

(for documentation on this library, see: http://www.bitvis.no/products/bitvis-utility-library)

Scripts to compile and run the simulation are located in the ./scripts directory, the top
level script "1_all_incl_sim.do" calls all other scripts in turn.

To run the simulation:

1. Open Modelsim (currently using Modelsim SE 10.1c)
2. Create new project in the "run" directory (with the modelsim.ini file located there)
3. execute the top level script:
    
	do ../scripts/1_all_incl_sim.do