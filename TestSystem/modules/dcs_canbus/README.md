# CANbus DCS interface

This module includes the DCS High Level Protocol (HLP), which is a master on the wishbone bus in the RU firmware. In addition to the master interface, it also has a WB slave interface with a few status/count registers available.

It uses the [OpenCores CAN controller](https://opencores.org/project,can) for the CANbus interface, and communicates with the CAN controller via an internal wishbone bus.


## CANbus DCS HLP simulation

The standalone testbench for CAN HLP has a simple BFM for the [Bitvis UVVM utility library](https://github.com/UVVM/UVVM_All) CAN HLP, with can\_hlp\_read and can\_hlp\_write procedures that uses an instance of the OpenCores CAN controller to actually send and receive the data over CAN bus.

### Running the simulation

Change directory to the top level repo directory (ie. RUv1\_Test/), and run:

```bash
make environment
cd modules/dcs_canbus/sim
vsim -do 07-compile_and_run_can_hlp.do
```

The simulation test bench is also ran as part of the continuous integration tests.

## OpenCores CAN controller simulation

The standalone testbench for the CAN controller uses a Wishbone BFM for the [Bitvis UVVM utility library](https://github.com/UVVM/UVVM_All). The testbench sets up 2 CAN controllers, connected together via their CANbus signals, and each with a dedicated wishbone interface. It runs some simple read/write tests to verify that registers in the controller can be accessed, sets up a CANbus transmission from one controller, and verifies that the package is correctly received by the other controller.

### Running the simulation

From the modules/dcs\_canbus/sim directory, run:

```bash
vsim -do 07-compile_and_run_can_ctrl.do
```

## Using the DCS CAN HLP module in RUv1 hardware

### RUv1 hardware setup

#### CAN-bus termination

The CAN-bus lines requires 120 ohm termination at each end of the line. The CAN adapter needs to have internal termination enabled, or in the case of the PEAK CAN to USB adapter there are some solder links to enable termination (refer to the manual).

The RUv1 must be modified with a 120 ohm resistor. Refer to doc/RUv1\_CAN\_termination.png for more details.

#### CAN HLP Device ID

The device ID for the CAN HLP module is set by DIPSWITCH(7:0) in the firmware. However, this corresponds to signals DIPSWITCH9 to DIPSWITCH2 on the actual RUv1 board, as the DIPSWITCH IO assignments in the RUv1 constraint file appears to be mirrored compared to the RUv1 schematics. So keep in mind that the switches marked 10 to 3 on the DIP switch are the ones to use, and that switch 10 is LSB.

### RUv1 firmware

In addition to building the Vivado project and programming the UltraScale with the DCS CAN HLP firmware, the PA3 also needs to be programmed with a firmware to pass the CAN signals through the PA3. This firmware version can currently be found in the [CAN_PASSTHROUGH branch](https://gitlab.cern.ch/alice-its-wp10-firmware/RUv1_auxFPGA/tree/CAN_PASSTHROUGH) in the [RUv1_auxFPGA](https://gitlab.cern.ch/alice-its-wp10-firmware/RUv1_auxFPGA) repository (it will eventually be merged into the master branch).

The bitrate for CAN bus is currently hardcoded in the file modules/dcs\_canbus/source/rtl/can\_hlp/can\_hlp\_glue\_pkg.vhd. The lower 6 bits of the constant C\_CAN\_BTR0\_RESET_VAL sets the bitrate (default is 250kbit).
The bitrate is calculated in this way: SYS\_CLK / (10*2*(C\_CAN\_BTR0\_RESET\_VAL[5:0]+1)). SYS\_CLK is 160 MHz.


### Communicating with CAN HLP

Scripts are provided in the modules/dcs\_canbus/software/can\_hlp/ directory for communicating with the CAN\_HLP module via CAN-bus using a SocketCAN interface, and should work with the PEAK CAN to USB adapter on linux, which supports SocketCAN natively (some python packages may be necesary).
The AnaGate CAN controller does not support SocketCAN natively, but AnaGate provides a little program that acts as a bridge between the controller's TCP/IP interface and a virtual SocketCAN interface.


#### PEAK CAN to USB

To set up a can0 network interface at 1Mbps for the CAN adapter, run:

```bash
modules/dcs_canbus/software/can_hlp/setup_socketcan.sh
```

You only have to do this one time (but it will not persist after reboots).

To test communication, run this python script (you may have to edit the interface name to match your setup, ie. can0 or vcan0):

```bash
modules/dcs_canbus/software/can_hlp/can_hlp_test.py
```

This will read out the git hash, read out some counter registers in the CAN HLP WB slave, and test writing to a TEST register in the CAN HLP WB slave.

The CanHLP class provides readHLP() and writeHLP() functions that can be used to read/write to other registers.

#### AnaGate CAN controller

Connect the AnaGate controller and set up ethernet on the computer so that they are on the same network. The AnaGate controller is configured with the IP address 192.168.1.254 by default, so the following settings for ethernet can be used on the computer:

IP: 192.168.1.2
Mask: 255.255.255.0
Gateway: 0.0.0.0

Run the script to set up the virtual CAN bus interface:

```bash
modules/dcs_canbus/software/can_hlp/SocketCANGateway/InitVCAN.sh
```

Next run the bridge:

```bash
modules/dcs_canbus/software/can_hlp/SocketCANGateway/x86_64_Release/SocketCANGateway vcan0 --baudrate=250000 --termination=1 --highspeed=1 --canport=0
```

That will configure the AnaGate controller to use the vcan0 interface, run at 250kbit, use internal termination, highspeed CAN, and use the first CAN port on the AnaGate (CAN A port on AnaGate Quattro).

Now the test script can be run (edit vcan0/can0 in the script to reflect the SocketCAN interface you are using).

```bash
modules/dcs_canbus/software/can_hlp/can_hlp_test.py
```

#### Test loop script

The script can\_hlp\_test\_loop.py continuously reads and verifies the git hash value over CAN, writes a random number to a test register over CAN, and reads it back and verifies the value. The script can be stopped by pressing CTRL+C, then it will print the number of attempted and successful CAN transactions.

The CAN interface must be edited in this script to match your setup, and the githash must also be edited to match the githash of the firmware that is running on the RU board (it does not retrieve it automatically with git).
