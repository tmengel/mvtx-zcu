#!/usr/bin/env python

import logging
import os
import re
import serial
import time
import fire
import errno

DEFAULT_PORT = '/dev/ttyTTI'
#DEFAULT_PORT = '\\\\.\\COM15'

STANDALONE_RUN = False


class TTI:
    """Control of TTI power supply"""

    def __init__(self, port=DEFAULT_PORT):
        self.logger = None

        self.link = serial.Serial(port=port, baudrate=9600, timeout=0.5)
        self.logger = logging.getLogger("TTI power supply")

        self.number_channels = 0
        self._check_max_channels()
        if STANDALONE_RUN:
            self.setup_standalone()

    def setup_standalone(self):
        self.setup_logging()

    def setup_logging(self):
        """Sets up the logging"""
        # Logging folder
        self.logdir = os.path.join(
            os.getcwd(),
            'logs/tti')
        try:
            os.makedirs(self.logdir)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        # setup logging
        logger = logging.getLogger()
        logger.setLevel(logging.DEBUG)

        log_file = os.path.join(self.logdir, "tti.log")
        log_file_errors = os.path.join(self.logdir,
                                       "tti_errors.log")

        fh = logging.FileHandler(log_file)
        fh.setLevel(logging.DEBUG)

        fh2 = logging.FileHandler(log_file_errors)
        fh2.setLevel(logging.ERROR)

        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s")

        fh.setFormatter(formatter)
        fh2.setFormatter(formatter)

        logger.addHandler(fh)
        logger.addHandler(fh2)

        self.logger = logger

    def _write(self, cmd):
        """Write to serial link"""
        self.link.write(cmd.encode('utf-8'))
        time.sleep(0.05)

    def _read(self):
        """Read from serial link"""
        return self.link.readline().decode('utf-8')[:-1]

    def _check_max_channels(self):
        """Attempt to detect number of channels based on model name"""
        model = self.get_model()
        model_nr = re.search('PL([^,]*)', model)
        if not model_nr:
            self.logger.error("Could not identify model. Model string: %s",model)
            raise Exception("Could not identify TTI model : {0}".format(model))
        if (model_nr.group(1) == '303QMD') | (model_nr.group(1) == '303QMD-P'):
            self.number_channels = 2
        elif (model_nr.group(1) == '303QMT') | (model_nr.group(1) == '303QMT-P'):
            self.number_channels = 3
        else:
            self.number_channels = 1

    def _channel_transform(self, channel):
        """Inverts the order of the channel, from manual:
          "On dual and triple output supplies, ‘1’ is the Master (extreme
          right-hand output) and ‘2’ is the Slave in the four QMD/QMT  modes; ‘3’ is the
          independent extreme left-hand output."
          Since this is opposite to how the Hameg works we invert the channel order"""
        if self.number_channels == 3:
            if channel == 1:
                return 3
            elif channel == 3:
                return 1
        elif self.number_channels == 2:
            if channel == 1:
                return 2
            else:
                return 1

    def reset(self):
        """Returns all settings to factory default"""
        self._write('*RST\n')

    def get_model(self):
        """Return model and type"""
        self._write('*IDN?\n')
        return self._read()

    def configure_channel(self, channel, voltage, current, ovp_ratio=1.05, ocp_ratio=1.05):
        """Configure channel N with given voltage, current. Ratio for the trip point of the over
        voltage and over current can be set."""
        assert channel > 0 & channel <= self.number_channels
        channel = self._channel_transform(channel)
        self._write('V{0} {1}\n'.format(channel, voltage))
        if voltage*ovp_ratio < 0.01: # Avoids unneceseary tripping of fuse
            ovp = 0.01
        else:
            ovp = voltage*ovp_ratio
        self._write('OVP{0} {1}\n'.format(channel, ovp))
        self._write('I{0} {1}\n'.format(channel, current))
        if current*ocp_ratio < 0.001: # Avoids unneceseary tripping of fuse
            ocp = 0.001
        else:
            ocp = current*ocp_ratio
        self._write('OCP{0} {1}\n'.format(channel, ocp))

    def get_channel_config(self,channel):
        """Get the channel configuration"""
        assert channel > 0 & channel <= self.number_channels
        channel = self._channel_transform(channel)
        self._write('I{0}?\n'.format(channel))
        curr = self._read()
        curr = curr.replace('I{0} '.format(channel), '')
        self._write('V{0}?\n'.format(channel))
        volt = self._read()
        volt = volt.replace('V{0} '.format(channel), '')
        self._write('OVP{0}?\n'.format(channel))
        ovp = self._read()
        ovp = ovp.replace('VP{0} '.format(channel), '')
        self._write('OCP{0}?\n'.format(channel))
        ocp = self._read()
        ocp = ocp.replace('CP{0} '.format(channel), '')
        self._write('OP{0}?\n'.format(channel))
        active = self._read()
        return float(volt),float(curr),float(ovp),float(ocp),int(active)

    def get_channel_config_all(self):
        """Get configuratoin for all channels"""
        active_str = {0:"OFF", 1: "ON"}
        for channel in range(1,self.number_channels+1):
            voltage,current,ovp,ocp,active = self.get_channel_config(channel)
            msg = "Channel {0}: {1:.3f}V, {2:.3f}A, OVP:{3:.3f}V, OCP:{4:.4f}A {5}".format(channel,voltage,current,ovp,ocp,active_str[active])
            self.logger.info(msg)
            print(msg)

    def activate_output_channel(self,channel):
        """Activate output of given channel"""
        self.activate_output_channels([channel])

    def deactivate_output_channel(self,channel):
        """Deactivate output of given channel"""
        self.deactivate_output_channels([channel])

    def activate_output_channels(self, channels):
        """Activate the output of a list of given channels"""
        assert max(channels) <= self.number_channels
        assert min(channels) > 0
        cmd = ""
        for channel in channels:
            cmd += 'OP{0} 1\n'.format(self._channel_transform(channel))
        self._write(cmd)

    def deactivate_output_channels(self, channels):
        """Deactivate the output of a list of given channels"""
        assert max(channels) <= self.number_channels
        assert min(channels) > 0
        cmd = ""
        for channel in channels:
            cmd += 'OP{0} 0\n'.format(self._channel_transform(channel))
        self._write(cmd)

    def activate_output_all_channels(self, activate=True):
        """Activates output of all channels"""
        if activate:
            self.logger.info("Turn on power supply")
            self._write('OPALL 1\n')
        else:
            self.logger.info("Turn off power supply")
            self._write('OPALL 0\n')

    def deactivate_output_all_channels(self):
        """Deactivate output of all channels"""
        self.logger.info("Turn off power supply")
        self._write('OPALL 0\n')

    def is_channel_on(self,channel):
        """Reports if a channel is active"""
        channel_voltage = self.get_voltage(channel)
        return channel_voltage > 0.0

    def get_fuse_triggered(self, channel):
        """Returns whether or not a fuse was triggered"""
        assert channel > 0 & channel <= self.number_channels
        self._write('LSR{0}?\n'.format(self._channel_transform(channel)))
        status = int(self._read())
        # LSR bit info, register is cleared after reading
        # Bit 7: Reserved for future use
        # Bit 6: Set when a trip has occurred that can only be reset from the front panel or by removing
        # and reapplying the AC power.
        # Bit 5: Reserved for future use
        # Bit 4: Reserved for future use
        # Bit 3: Set when an output over current trip has occurred
        # Bit 2: Set when an output over voltage trip has occurred.
        # Bit 1: Set when output enters current limit (CC mode)
        # Bit 0: Set when output enters voltage limit (CV mode)
        self.logger.debug("Status on channel {0} is {1:b} mA".format(channel, status))
        return (status & 0b01001100) != 0

    def clear_triggered_fuse(self):
        """Attempts to clear triggered fuses, cannot recover LSR bit 6"""
        self._write('TRIPRST\n')

    def get_current(self, channel):
        """Get the current of a given channel in mA"""
        assert channel > 0 & channel <= self.number_channels
        self._write('I{0}O?\n'.format(self._channel_transform(channel)))
        current = self._read().replace('A', '')
        current = float(current)*1000
        self.logger.debug("Current on channel {0} is {1} mA".format(channel, current))
        return current

    def get_voltage(self, channel):
        """Get the voltage of a given channel in V"""
        assert channel > 0 & channel <= self.number_channels
        self._write('V{0}O?\n'.format(self._channel_transform(channel)))
        voltage = self._read().replace('V', '')
        voltage = float(voltage)
        self.logger.debug("Voltage on channel {0} is {1} V".format(channel, voltage))
        return voltage

    def get_power(self,channel):
        """Return Voltage, Current, Power of channel"""
        voltage = self.get_voltage(channel)
        current = self.get_current(channel)
        power = voltage*current*0.001
        msg = "Channel {0}: {1:.3f} V, {2:.0f} mA, {3:.2f} W".format(channel, voltage, current, power)
        self.logger.info(msg)
        print(msg)
        return msg

    def get_power_all(self):
        """Gets the voltage, current and power of all channels"""
        for channel in range(1,self.number_channels+1):
            self.get_power(self._channel_transform(channel))

if __name__ == "__main__":
    STANDALONE_RUN = True
    fire.Fire(TTI)
