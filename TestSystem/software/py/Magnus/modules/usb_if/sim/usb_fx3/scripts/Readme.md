## Usb Fx3 Interface simulation

This test bench simulates the usb_if compontent, which is the interface to the Fx3 usb chip.

The simulation files are located in

RUv0a/source/bench/usb_fx3

and use the following files:

- usb_top.vhd: Vhdl Wrapper to access the usb_if.vhd top module. This
  wrapper translates the wishbone records to standard std_logic
  signals.

- gpif_ii.sv: Definition of the GPIF2 Interface
- usb_fx3_buffer.sv: Bhv Implementation of DMA Buffer logic on the Fx3 chip.
- usb_fx3.sv: Bhv model of Fx3 Chip, running in GPIF2 slave mode.
- usb_tb.sv: Top level testbench, providing test stimuli and checking results.

In addition, this folder includes a default GPIF2 master implementation provided by cypress:

- cypress_slfifo_tb.sv: Testbench which tests the usb_fx3
  implementation against the cypress gpif master

- slaveFIFO2b/*: Implementation files of the Cypress gpif master

Additional files used:

- RUv0a/source/bench/wishbone/wishbone_slave.sv: A BHV model of a simple Wishbone slave memory.

### Run the simulation

The following script files can be used to start the simulation fo the usb_if interface:

- usb_if_sim.tcl [--cover]: Simulates the usb_if top level entity with
  the usb_fx3 Bhv model. An optional --cover argument can be set to
  check the code coverage.

- usb_if_sim_cypress.tcl: Simulates the usb_fx3 Bhv model against a
  default cypress implementation of a GPIF2 master.

These scripts can be sourced from a running modelsim instance or started with teh provided makefile:

- make : Runs the simulation of the usb_if module
- make coverage : Runs the usb_if simulation with coverage enabled
- make cypress: Runs the simulation of the cypress GPIF2 master implementation

### Results

This is an automatic self checking testbench. Errors will be reported
on the console. If no error occures, the simulation finishes after all
tests run through.