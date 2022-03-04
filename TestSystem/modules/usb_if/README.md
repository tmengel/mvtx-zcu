# USB_IF FPGA Firmware README
10/12/2015

krzysztof.sielewicz@cern.ch

## Dependencies
- common
- wishbone


## GENERAL INFORMATION:

1) FX3 GPIF II Bus operates in SLAVE_FIFO mode (Cypress AN65974)
2) IN PACKETS [DP1/2/3] (toward the HOST PC) are maximum 1024bytes=256*4B words
3) IN PACKETS [DP1/2/3] can be either short or full packets (short = less than 1024B, full = 1024B). Both short and full packets are ended with the PKTENDn asserted low during the transmission of the last 4B word.

## IMPLEMENTATION:
1) fx3_ctrl.v is the module that includes the following modules:
  - dp_arbtr.v  - an arbiter that grants the access to the GPIF II Bus between DP0/1/2/3
  - dpi_fsm.v   - an FSM that controlls the DP0 operation
  - dpo_fsm.v   - an FSM that controlls the DP1/2/3 operation
2) usb_if_wrpr.v is the wrapper module that includes the following modules:
  - fx3_ctrl.v  - descibed above
  - wbmstr.v    - a wishbone bus master. It reads the data from the DP0 FIFO and performs WRITE or READ operation. Then it writes back the result of READ operation to the DP1 FIFO.
  - fifo32x1024 - a dual clock FIFO, word=4B, depth=1024
3) usb_if.vhd is the USB interface top module that is included in the top_fabric.vhd module

The general overview and FSM diagrams of individual modules can be found here -> CERNBOX/ITS/FIRMWARE/USB_IF_ITSRUv0a/USB_ITS_RUv0a.pdf
