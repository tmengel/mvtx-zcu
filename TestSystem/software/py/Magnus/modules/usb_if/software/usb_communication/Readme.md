# Communication

The class Communication provides basic communication functionality to
the board. This includes access to the data ports (DP2 and DP3) as
well as access to the control port; using single write/read operations
or a batch mode.

### System Requirements

- Python >=3.4
- pyusb 1.0.0rc1 or later

### Functions
- comm.single\_write(module,address,data) : Send a single write command to the board
- comm.single\_read(module,address,adat) : Send a single read command to the board
- comm.register\_write(module,address,data): Schedule a write command (Not executed immediately)
- comm.register\_read(module,address,adat): Schedule a read command (Not executed immediately)
- comm.flush(): Send all scheduled commands in order to the board.
- comm.read\_results(): Read results from the DP1 port (control IN). Expects one result per register\_read scheduled

### Extension
An implementation (which implements the actual communication) for a different interface (e.g. Uart) needs to subclass the Communication class and implement the following functions:

- \_do\_write\_DP0(data): write <data> to the boards control port
- \_do\_read\_DP1(size): read <size> bytes from the boards control port
- \_do\_read\_DP2(size): read <size> bytes from the boards fifo data port 0
- \_do\_read\_DP3(size): read <size> bytes from the boards fifo data port 1

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
