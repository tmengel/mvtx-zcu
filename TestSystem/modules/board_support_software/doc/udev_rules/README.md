The rules should be copied to /etc/udev/rules.d

In order to add a new rule for a device
1. copy an existing rule,
2. change the number (between 0 to 99,not present in /etc/udev/rules.d/)
3. lsusb
4. connect the device
5. lsusb
6. The newly appeared device is the one to add. Not down vendor id and product id
7. Choose a name for the device and assign it to SYMLINK, this will create a symlink to /dev/<SYMLINK>
8. Disconnect the device
9. ls /dev/tty*
10. connect the device
11. ls /dev/tty* (usually is /dev/ttyUSB0)
12. udevadm info -a -n /dev/ttyUSB0 | grep '{serial}' | head -n1
13. reload udev rules (sudo udevadm control --reload-rules && udevadm trigger)
