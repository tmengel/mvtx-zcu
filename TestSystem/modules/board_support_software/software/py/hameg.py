#!/usr/bin/env python

import logging
import os
import re
import serial
import time
import fire
import errno

DEFAULT_PORT = '/dev/ttyHAMEG'
#DEFAULT_PORT = '/dev/ttyHAMEG1PRAGUE' # RUv1, ALPIDE_AV, ALPIDE_DV
#DEFAULT_PORT = '/dev/ttyHAMEG2PRAGUE' # CRU, Fan, JCM

STANDALONE_RUN = False


class Hameg:
    """Control of HAMEG power supply"""

    def __init__(self, port=DEFAULT_PORT):
        self.logger = None

        self.link = serial.Serial(port=port, baudrate=9600, timeout=0.5)
        self.logger = logging.getLogger("HAMEG power supply")

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
            'logs/Hameg')
        try:
            os.makedirs(self.logdir)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        # setup logging
        logger = logging.getLogger()
        logger.setLevel(logging.DEBUG)

        log_file = os.path.join(self.logdir, "hameg.log")
        log_file_errors = os.path.join(self.logdir,
                                       "hameg_errors.log")

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
        model_nr = re.search('HMP(\d+)', model)
        if not model_nr:
            self.logger.error("Could not identify model. Model string: %s",model)
            raise Exception("Could not identify Hameg model : {0}".format(model))
        if model_nr.group(1) == '4040':
            self.number_channels = 4
        elif model_nr.group(1) == '2030':
            self.number_channels = 3
        else:
            self.logger.error("Model number not yet implemented. Check number of channels: %s",
                              model_nr.group(1))
            raise NotImplementedError("Model not implemented")

    def reset(self):
        """Returns all settings to factory default"""
        self._write('*RST\n')

    def get_model(self):
        """Return model and type"""
        self._write('*IDN?\n')
        return self._read()

    def configure_channel(self, channel, voltage, current):
        """Configure channel N with given voltage, current. Fuses are on and
        linked to the same channel. Channel gets activated"""
        assert channel > 0 & channel <= self.number_channels
        self._write('INST OUT{0}\n'.format(channel))
        self._write('VOLT {0}\n'.format(voltage))
        self._write('CURR {0}\n'.format(current))
        self._write('FUSE ON\n')
        self._write('FUSE:DELAY 100\n')
        self._write('FUSE:LINK {0}\n'.format(channel))

    def get_channel_config(self, channel):
        """Get the channel configuration"""
        assert channel > 0 & channel <= self.number_channels
        self._write('INST OUT{0}\n'.format(channel))
        time.sleep(0.05)
        self._write('CURR?\n')
        curr = self._read()
        self._write('VOLT?\n')
        volt = self._read()
        self._write('INST OUT{0}\nOUTP:SEL?\n'.format(channel))
        active = self._read()
        return float(volt),float(curr),int(active)

    def get_channel_config_all(self):
        """Get configuratoin for all channels"""
        active_str = {0:"OFF", 1: "ON"}
        for channel in range(1,self.number_channels+1):
            voltage,current,active = self.get_channel_config(channel)
            msg = "Channel {0}: {1:.4f}V, {2:.4f}A, {3}".format(channel,voltage,current,active_str[active])
            self.logger.info(msg)
            print(msg)

    def activate_channel(self, channel):
        """Activate given channel"""
        self.activate_channels([channel])

    def deactivate_channel(self, channel):
        """Deactivate given channel"""
        self.deactivate_channels([channel])

    def activate_channels(self, channels):
        """Activate a list of given channels"""
        assert max(channels) <= self.number_channels
        assert min(channels) > 0
        cmd = ""
        for channel in channels:
            cmd += 'INST OUT{0}\nOUTP:SEL ON\n'.format(channel)
        self._write(cmd)

    def deactivate_channels(self, channels):
        """Deactivate a list of given channels"""
        assert max(channels) <= self.number_channels
        assert min(channels) > 0
        cmd = ""
        for channel in channels:
            cmd += 'INST OUT{0}\nOUTP:SEL OFF\n'.format(channel)
        self._write(cmd)

    def activate_output(self, activate=True):
        """Activates voltage output"""
        if activate:
            self.logger.info("Turn on power supply")
            self._write('OUTP:GEN ON\n')
        else:
            self.logger.info("Turn off power supply")
            self._write('OUTP:GEN OFF\n')

    def deactivate_output(self):
        """Deactivates voltage output"""
        self.logger.info("Turn off power supply")
        self._write('OUTP:GEN OFF\n')

    def is_channel_on(self,channel):
        """Reports if a channel is active"""
        channel_voltage = self.get_voltage(channel)
        return channel_voltage > 0.0

    def get_fuse_triggered(self, channel):
        """Returns whether or not a fuse was triggered"""
        assert channel > 0 & channel <= self.number_channels
        self._write('STAT:QUES:INST:ISUM{0}:COND?\n'.format(channel))
        status = int(self._read())
        return (status & 1024) != 0

    def get_current(self, channel):
        """Get the current of a given channel in mA"""
        assert channel > 0 & channel <= self.number_channels
        self._write('INST:SEL OUT{0}\n'.format(channel))
        time.sleep(0.05)
        self._write('MEAS:CURR?\n')
        current = float(self._read())*1000
        self.logger.debug("Current on channel {0} is {1} mA".format(channel, current))
        return current

    def get_voltage(self, channel):
        """Get the voltage of a given channel in V"""
        assert channel > 0 & channel <= self.number_channels
        self._write('INST:SEL OUT{0}\n'.format(channel))
        time.sleep(0.05)
        self._write('MEAS:SCAL:VOLT?\n')
        voltage = float(self._read())
        self.logger.debug("Voltage on channel {0} is {1} V".format(channel, voltage))
        return voltage

    def get_power(self, channel):
        """Return Voltage, Current, Power of channel"""
        voltage = self.get_voltage(channel)
        current = self.get_current(channel)
        power = voltage*current*0.001
        msg = "Channel {0}: {1:.2f} V, {2:.0f} mA, {3:.2f} W".format(channel, voltage, current, power)
        self.logger.info(msg)
        print(msg)
        return msg

    def get_power_all(self):
        """Gets the voltage, current and power of all channels"""
        for channel in range(1,self.number_channels+1):
            self.get_power(channel)


if __name__ == "__main__":
    STANDALONE_RUN = True
    fire.Fire(Hameg)
