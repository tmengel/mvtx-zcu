# Fx3 Slave Fifo with Uart enabled

This firmware is a modified version of the Firmware example "SlFifoSync" from Cypress. The following modifications were made:

- Modified VID and PID
- Added additional Endpoints for Master -> Slave Data transfer
- Modified Watermarks for partial Fifo full flags (Watermark value of 4)
- Added Uart modem as additional Usb Interface
- Added serial number to distinguish different RUv0

The default parameters are as follows:
- VID = 04B4
- PID = 0008
- Serial number: "000000"
- Number of Interfaces: 3
- Interface 0 (+interface 1)
  - Uart (cdc modem)
- Interface 2
  - Data interface
  - Endpoints
    - 0x03 EP3 Control PC -> USB
    - 0x83 EP3 Control USB -> PC
    - 0x84 EP4 Data 0  USB -> PC
    - 0x85 EP5 DATA 1  USB -> PC

- GPIF
  - Flags (see Cypress AN65974 - Designing with the EZ-USB 8.3 for details)
    - FLAGA - Empty Flag Address 0
    - FLAGB - Partial Full Flag Address 1, Watermark value: 4
    - FLAGC - Partial Full Flag Address 2, Watermark value: 4
    - FLAGD - Partial Full Flag Address 3, Watermark value: 4

## Source Files

- cyfxslfifousbdscr.c: Usb descriptor definition
- cyfxgpif2config.h: Generated GPIF Designer file for GPIF setup
- cyfxslfifosync.h, cyfxslfifosync.c: Application code implementation

## Change serial number
The serial number consists of 6 characters, which can be set in cyfxslfifosync.h.
Each character can be set by changing the makros FX_SERIAL_NUMBER0 to FX_SERIAL_NUMBER5



## Building the project

### Cypress Eclipse

A Eclipse project file is provided, which can be imported to a
workspace, using the Cypress Eclipse version. When building, automatic
makefile generation has to be used (Project properties, C/C++
Build). Running the build will generate an image file which can be
programmed to the Fx3. Depending on the target of the image, different
Build configurations are provided, which can be switched in the
project context menu (Select project, right-click, Build
configurations -> Set Active -> <config>)

- Release - For Flashing per USB
- i2c - For flashing into I2C memory
- spi - For flashing into SPI memory

These configurations will change the header of the generated .img file
to the correct values.

### Makefile

A makefile is provided which builds the sources locally and generates
image files to program the fx3 device. This requires the
FX3_INSTALL_PATH set correctly in the environment (Path to the sdk,
for linux installs this is described in the setup process). The build
can be started by calling make in the local directory.

## Flashing the Firmware

After running all build steps, a .img file is created, which can be
used by the programmer to upload the firmware to the device. This is
done by the programming software provided by the SDK. (cyusb_linux or
Usb Control Center).

### Flashing to Memory (Spi or I2C)

Storing the firmware image in a flash memory, connected by I2C or SPI,
is supported by the SDK tools, but as a multistep process.

#### Generation of the Image file.

Images for SPI or I2C flash require a different header in the .img
file. This header is added automatically by using the elf2img tool
from the Cypress SDK. When converting the .elf binary to the image
file, additional parameters for creating a flash image are required.

```
elf2img -i slfifo_uart.elf -o slfifo_uart_flash.img -i2cconf <param_byte>
```

The value of param_byte depends on the flash storage hardware and has
the following values (copied from the elf2img.txt documentation):

- I2C Parameters:
      - Bit      0: Must be zero.
      - Bits 3 - 1: EEPROM size( 7 = 128 KB (Microchip), 6 = 64 KB, 5 = 32 KB, 4 = 16 KB, 3 = 8 KB, 2 = 4 KB)
      - Bits 5 - 4: EEPROM speed(0 = 100 KHz, 1 = 400 KHz, 2 = 1 MHz)
      - Bits 7 - 6: Must be zero.
- SPI Parameters:
      - Bit      0: Must be zero.
      - Bits 3 - 1: Don't care
      - Bits 5 - 4: SPI operating frequency (0 = 10 MHz, 1 = 20 MHz, 2 = 30 MHz)
      - Bits 7 - 6: Must be zero.

#### Loading the flash programmer firmware

For Loading the firmware to the flash memories a special firmware has
to be loaded to the FX3. The firmware is provided by Cypress and can
be used directly.

- In case of Windows, the USB Control Center tool does this
  automatically when selecting I2C EEPROM or SPI Flash as Program
  target in Program/Fx3/<type>.

- For Linux, a cyfxflashprog.img image is provided, which can be
  programmed with the cyusb_linux tool. The image is located within
  the cyusb_linux installation
  ($Cypress_DIR/cyusb_linux_<ver>/fx3_images).

The correct firmware will register as VID=04B4 and PID=4720.

#### Loading the image

When the correct programming firmware is loaded, the corresponding
.img file can be selected and programmed to the device.

For RUv1 this is the slfifo_uart.img to be stored in the I2C EEPROM

#### Changing the boot source on the board

To tell the FX3 to boot from SPI or I2C, the state of the PMODE[2:0]
pins has to be modified:

        Boot Type      |PMODE[2]|PMODE[1]|PMODE[0]
-----------------------|--------|--------|--------
USB Boot               |   Z    |   1    |   1
I2C Boot (Usb Fallback)|   Z    |   1    |   Z
SPI Boot (Usb Fallback)|   0    |   Z    |   1

To configure the I2C, the Boot type has to be set to USB Boot
Then, it should be switched back to I2C Boot (with USB fallback)

On the RUv0 the PMODE[2:0] is controlled via resistors: (R269 shorts PMODE[0] to 1)

On the RUv1 the PMODE[2:0] is controlled via dip switches on component S9

## Connecting to Software

Given the configuration for interfaces and Endpoints, the usb_comm
software can communicate with the firmware by starting it with the
following parameters:

```
./usb_comm --product_id 0008 --interface 2 --endpoint_control_out 3 --endpoint_control_in 3 --endpoint_data0_in 4 --endpoint_data1_in 5 --v=2
```

This will open TCP ports at Port numbers 30000 (Control), 30001
(Data0) and 30002 (Data1).

For the Uart, the device should be registered as a default Serial Port
(COMx for Windows, or ttyACMx for Linux). The baudrate is free to
choose, and is setup between USB and the Fx3 chip automatically.

# Known Problems

## The device is constantly reconnecting

On some board/PC combinations the Fx3 chip flickers on and off,
causing the usb device to be re-enumerated constantly. The reason is
probably a power issue with the USB Port; connecting the device to a
different Port solved the issue.
