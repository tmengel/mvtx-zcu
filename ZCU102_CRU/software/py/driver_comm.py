#!/usr/bin/env python

import socket
import logging

# -------------------------------------------------------------
#  -------------- Class DriverComm (driver-layer) ------------
# -------------------------------------------------------------


class DriverComm:

    def __init__(self, ip='192.168.1.2', port=9001, end=0):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.settimeout(10)
        self.s.connect((ip, port))
        self.logger = logging.getLogger('ttc_pon')
        self.logger.debug('Opening socket at port:' + str(port) + ", ip:" + ip)
        self.end_msg = end

    def send(self, data):
        data = data.encode('utf-8')
        if self.end_msg == 0:
            if data[-1] != b'\n':
                data += b'\n'
        self.s.send(data)

    def disableTimeout(self):
        self.s.settimeout(None)

    def enableTimeout(self, timeout):
        self.s.settimeout(timeout)

    def recv(self, delimiter):
        r = ' '
        data = ''

        while r != delimiter:
            data += self.s.recv(4 * 1024)
            r = data[-1]

        return data[:-1]

    def query(self, data):
        self.send(data)
        return self.s.recv(2048)

    def close(self):
        self.s.close()
