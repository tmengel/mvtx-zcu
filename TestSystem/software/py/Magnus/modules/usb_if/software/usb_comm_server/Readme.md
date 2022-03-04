# Usb Chip Interface program

A simple interface between the USB interface and client programs.
For communication, sockets for each endpoint are provided.

## Build requirements

To build the software, the following tools and libraries are
required.

- C++11 compatible compiler (tested with gcc 4.8.3)
- cmake (tested with 2.8.11)
- boost libraries (tested with 1.53.0-23)
- libusb 1.0 (tested with libusb-1.0.15-4)
- easylogging++ (v9.8, downloaded automatically)

## Build instructions Linux

### Download required libraries

All libraries used should be easily available from package managers in
at least the required version. For example, the following packages are
required on CC7

```
#yum group install "Development Tools"
#yum install cmake boost-devel libusbx
```

and on Debian/Ubuntu

```
#apt-get install build-essential cmake libboost-all-dev libusb-1.0-0-dev
```

### Configure build environment and start build

Configuration is handled by cmake. To create a new build, configure cmake from the build directory:

```
$cd <sourcedir>
$mkdir build
$cd build
$cmake ..
$make
```

This checks all requirements and generates the build files. If it
finishes successfully, the program can be built with make.


### Build on SLC6
On SLC6, the required compiler environment can be installed using the devtoolset version 2.0 (http://linux.web.cern.ch/linux/devtoolset/#dts2 ) and precompiled boost libraries on afs. Libusb can be found in the default repositories. To find the correct Boost version, cmake has to be called with additional definitions.

```
$wget -O /etc/yum.repos.d/slc6-devtoolset.repo http://linuxsoft.cern.ch/cern/devtoolset/slc6-devtoolset.repo
$sudo yum install devtoolset-2 libusb1-devel
$export BOOST_ROOT=/afs/cern.ch/sw/lcg/external/Boost/1.53.0_python2.7/x86_64-slc6-gcc48-opt/
$cd <sourcedir>
$mkdir build
$cd build
$cmake -DBoost_NO_BOOST_CMAKE=TRUE ..
$make
```

## Build instructions Windows
Tested with Visual Studio Community 2017

### Download required libraries

Download latest version of

* Boost http://www.boost.org/
* libusb https://github.com/libusb/libusb/releases

### Configure build environment and start build

Run `bootstrap.bat` from the folder you installed Boost into, then run 
`b2.exe` and then `bjam.exe` from same folder.  
Open `libusb\msvc\libusb_2017.sln`with Visual Studio, select *Release* 
and *Build -> Build Solution*.  
Open `usb_comm.sln` from this project with Visual Studio.  
Go to *Project -> C/C++ -> General* and change configuration (upper left) 
to *All Configurations* and change the path in *Additional Include Directories* 
to point to where you put boost and libusb, eg. `C:\Program Files\boost\boost_1_65_1\;C:\Program Files\libusb`  
In *Linker -> General* edit *Additional Include Directories* to point to 
where you put \<boostdir>\\stage\lib and \<libusbdir>\\Win32\Release\lib, eg. 
`C:\Program Files\boost\boost_1_65_1\stage\lib;C:\Program Files\libusb\Win32\Release\lib`  
Select *Release* and *Build -> Build Solution*

## Driver Setup

To communicate with a usb device, libusb is used. On linux this works
without the need to install additional drivers, but windows requires
the installation of a default WinUsb driver for the interface libusb
should communicate with. A documentation on how this driver can be
found at doc/driver_installation.pdf or the [Twiki page](https://twiki.cern.ch/twiki/bin/view/ALICE/SwReadoutUnitUsbConnection). The
instruction is targeted for use with the SlaveFifo / Uart firmware,
but can be used for other firmware images as well.


## Run instructions

Some Usb and network options can be modified by program arguments. The
different flags are described by the program, by printing its help
message:

```
./usb_comm -h
Usb Communication Interface

Basic options:
  -h [ --help ]         Print this help message
  -v [ --verbose ]      Enable Verbose output

Network:
  --port_control arg (=30000) Port for control communication
  --port_data0 arg (=30001)   Port for Data communication on Dataport 0
  --port_data1 arg (=30002)   Port for Data communication on Dataport 1

Usb Device options:
  --vendor_id arg (=04B4)         Vendor Id
  --product_id arg (=00F0)        Product Id
  --interface arg (=0)            Interface number
  --serial_number                 Device serial number
  --endpoint_control_out arg (=1) Control endpoint OUT (write)
  --endpoint_control_in arg (=1)  Control endpoint IN (read)
  --endpoint_data0_in arg (=2)    Data endpoint 0 IN (read)
  --endpoint_data1_in arg (=3)    Data endpoint 1 IN (read)
```
