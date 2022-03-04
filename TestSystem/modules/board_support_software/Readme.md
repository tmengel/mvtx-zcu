# A collection of python scripts which can be used as starting point of development

## RUv0a Testsuite

A collection of classes, partly shared with the Alpide characterisation project and the Probecard project.
Provides a set of classes and functions to communicate with periphery on the Readout unit.

### Requirements

- All modules are developed on python 3.5. While downwards
  compatibility might be given or achievable, it is not tested
  thoroughly. A starting point for a recent python version can be found in the anaconda package: https://www.continuum.io/downloads
- Additional libraries required by the communication layer:
  - pyusb
  - fire

### Provided classes (Top down)

This section lists all modules implemented at the current state. Each
module and class has inline documentation, which describes single
functions in more detail.

#### Module ru_board.py

The board module implements the class RUv0a, which is the top module
used to communicate with the Firmware. The implementation provides
functions for communication with the chip (including power control),
access to the wishbone interface and USB control functions (flush,
read_all). While simple communication can be done with the board
class, a set of submodules is provided, which offer functionality
specific to a wishbone slave.

- board.transceiver for the Highspeed link transceiver
- board.chippower for the Chip power control
- board.dctrl for the Chip DCTRL interface
- board.master for the Wishbone master module

#### Module ru_transceiver.py

The ru_transceiver module provides classes related to the Highspeed
link. This includes the GtxTransceiver class (board.transceiver), for
controlling the hslink, as well as the EyeScan class, which provides
functions to perform an eye scan with the transceiver.

The GtxTransceiver class provides functions for controlling alignment,
controlling the readout, communication with the drp port and the
readout of different status counters.

The EyeScan clas abstracts the eye scan procedure, so that only the
functions eye_scan or resume_eye_scan have to be called.

#### Module ru_chip_power.py

The ru_chip_power module provides the ChipPower(board.chippower) class, which is used
to set voltages on the chip power control, enable the chip power and
read ADC values for DVDD/AVDD voltages and currents.

#### Module dctrl.py

The dctrl module provides The Dctrl class(board.dctrl), which
implements slow control communication with the chip. In addition, it
provides additional functions to get internal status counters and set
the sample phase of the receiver.

#### Module wsmaster.py

The wsmaster module provides the class WsMaster, which implements the
Wishbone slave which is monitoring the Wishbone master. The class
provides functions to control the Error counters as well as the data
counters for DP2 and DP3.

#### Module events.py

The events modue provides the EventDecoder class, which implements a
protocol checker for the Highspeed data stream.

#### Module hameg.py

The hameg module provides the Hameg class, a Remote control
implementation to control Hameg 20x0 power supplies used at CERN
labs. It provides functions to set output voltages/currents for
different channels and a activation function.

## Communication

The class Communication provides basic communication functionality to
the board. This includes access to the data ports (DP2 and DP3) as
well as access to the control port; using single write/read operations
or a batch mode.

### System Requirements

- Python >=2.7
- pyusb 1.0.0rc1 or later

### Functions
- comm.single_write(module,address,data) : Send a single write command to the board
- comm.single_read(module,address,adat) : Send a single read command to the board
- comm.register_write(module,address,data): Schedule a write command (Not executed immediately)
- comm.register_read(module,address,adat): Schedule a read command (Not executed immediately)
- comm.flush(): Send all scheduled commands in order to the board.
- comm.read_results(): Read results from the DP1 port (control IN). Expects one result per register_register_read scheduled

### Extension
An implementation (which implements the actual communication) for a different interface (e.G Uart) needs to subclass the Communication class and implement the following functions:

- _do_write_DP0(data): write <data> to the boards control port
- _do_read_DP1(size): read <size> bytes from the boards control port
- _do_read_DP2(size): read <size> bytes from the boards fifo data port 0
- _do_read_DP3(size): read <size> bytes from the boards fifo data port 1

### Class diagram

```
                              +-----------------------+
                              |     Communication     |
                              |-----------------------|
                              | single_write()        |
                              | single_read()         |
                              | register_write()      |
                              | register_read()       |
                              | flush()               |
                              | read_results()        |
                              | read_DP2()            |
                              | read_DP3()            |
                              | #internal functions   |
                              | _do_write_DP0()       |
                              | _do_read_DP1()        |
                              | _do_read_DP2()        |
                              | _do_read_DP3()        |
                              +-----------------------+
                                          .
                                         /_\
                                          |
           +------------------------------+------------------------+
           |                              |                        |
           |                              |                        |
           |                              |                        |
+-----------------------+        +------------------+      +----------------+
|       PyUsbComm       |        |    NetUsbComm    |      |    UartComm    |
|-----------------------|        |------------------|      |----------------|
| _usb_connection       |        | sockets          |      |uart_connection |
|-----------------------|        |------------------|      |----------------|
| _do_write_DP0()       |        | _do_write_DP0    |      | _do_write_DP0  |
| _do_read_DP1()        |        | _do_read_DP1     |      | _do_read_DP1   |
| _do_read_DP2()        |        | _do_read_DP2     |      | _do_read_DP2   |
| _do_read_DP3()        |        | _do_read_DP3     |      | _do_read_DP3   |
+-----------------------+        +------------------+      +----------------+
```
