# Intel NUC Setup Guide
###### Emanuele Canessa (<e.canessa@cern.ch>)

## Operating System
The chosen operating system is Centos 7, all the following commands are tested
on this operating system.

### Hostname
During the installation process, the hostname for the machine was chosen:
`pcistnuc`.

To change the machine hostname after the installation process edit the following
file as root: `/etc/hostname`.

The PC was also registered on CERN Network the first time that was connected to
the internal net.

### Common User
To allow the PC to be used by multiple individuals, a **common** user account was
created.

To create a new user, issue this command as root:

`adduser -mG wheel <username>`

A password must be set in order to finalize the process, this is accomplished by
running as root:

`passwd <username>`

### Disable X11 Autostart
Being the NUC an *headless* PC, it is useless to autostart `gdm`, the Gnome
Display Manager at startup. To disable it, issue the following command as root:

`systemctl disable gdm.service && systemctl stop gdm.service`

**Attention:** This will not disable the X11 forwarding over ssh, as the
components for the graphical user interface are still there.

### Required Packages
The following packages are needed in order to use the common tools used by WP10.
To install them, issue the following command as root:

```
yum install -y automake bash-completion boost boost-devel cmake ctags emacs
gcc git glibc.i686 libXext.i686 libXrender.i686 libXtst.i686 libusb libusb-devel
libusbx libusbx-devel lua lua-devel luajit luajit-devel make ncurses-devel perl
perl-ExtUtils-CBuilder perl-ExtUtils-Embed perl-ExtUtils-ParseXS
perl-ExtUtils-XSpp perl-devel python python-devel python3 python3-devel ruby
ruby-devel screen tcl-devel tmux
```


## Vivado Hardware Server
This tool is needed in order to flash remotely the Xilinx FPGAs.

### Installation
1. Download the chosen version of Vivado Hardware Server for Linux.
2. Extract it using the following command: `tar xf <file>`
3. Change the current directory to the newly created one, then run the setup as
   root: `./xsetup`. Leave the default settings during installation.

### Drivers
Drivers are needed in order to operate the JTAG programmers. To install the
drivers follow these steps:

1. Change directory to
   `/opt/Xilinx/HWSRVR/2016.4/data/xicom/cable_drivers/lin64/install_script/install_drivers`
2. Execute drivers installation as root, `./install_drivers`.
3. Reload the udev rules, by running this command as root: `udevadm control
   --reload-rules && udevadm trigger`

**Attention:** The Vivado Hardware Server version may differ, pay attention to
use the correct path.

### Firewall Rules
To access the Vivado Hardware Server from PCs in the CERN Network, the firewall
must be instructed to enable the traffic on port 3121 TCP. To do so, run this
command as root:

`firewall-cmd --zone=public --permanent --add-port=3121/tcp && firewall-cmd
--reload`

### Startup Script
Finally, the Vivado Hardware Server must be enable at startup. To do so, follow
these steps, executing commands as root:

1. `chmod +x /etc/rc.d/rc.local`
2. `echo '/opt/Xilinx/HWSRVR/2016.4/bin/hw_server -d' | tee -a
   /etc/rc.d/rc.local`

**Attention:** The Vivado Hardware Server version may differ, pay attention to
use the correct path.


## Udev Rules
To control most of the available hardware equipment, the Udev rules must be
configured.

The Udev rules are currently located in the [RUv1\_Test
repository](https://gitlab.cern.ch/alice-its-wp10-firmware/RUv1_Test), inside
the folder `RUv1_test/modules/board_support_software/doc/udev_rules/`.

To enable them, execute these commands as root:

1. `cp *.rules /etd/udev/rules.d/`
2. `udevadm control --reload-rules && udevadm trigger`


## Anaconda3
To provide the correct version of python and most of the packages required for
the scripts, it is suggested to install the latest version of Anaconda3.

### Download and Installation (All Users)
Suggested method, as it will enable python for all users, including root.

1. Download the latest version of Anaconda3 for Linux from
   [https://www.anaconda.com/download/](https://www.anaconda.com/download/).
2. Run the setup as root: `sh Anaconda3-5.0.1-Linux-x86_64.sh`.
  - Change the installation path to `/opt/anaconda3`.
3. Change the write permission for the installation folder, allowing non-root
   users to install packages if needed.
  - Run `chmod -R a+rw /opt/anaconda3` as root.
4. Execute this command as root: `echo 'export PATH="/opt/anaconda3/bin:$PATH"'
   | tee /etc/profile.d/anaconda3.sh`
5. Reload the variables: `source /etc/profile.d/anaconda3.sh`.

### Download and Installation (Current User Only)
1. Download the latest version of Anaconda3 for Linux from
   [https://www.anaconda.com/download/](https://www.anaconda.com/download/).
2. Run the setup as root: `sh Anaconda3-5.0.1-Linux-x86_64.sh`.
  - Let the setup add anaconda to the path in `.bashrc`.
3. Reload the variables: `source ~/.bashrc`.

