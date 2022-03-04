"""File to define the user-defined exceptions, to be imported"""

class ChipError(Exception):
    """defines a basic class for ALPIDE exceptions"""
    def __init__(self):
        super(ChipError, self).__init__()

class ChipidMismatchError(ChipError):
    """basic class to handle the chipid mismatch exception when reading back from the chip"""
    def __init__(self, value="", requested_chipid=-1, rd_chipid=-1):
        super(ChipidMismatchError, self).__init__()
        self.value = value.format(rd_chipid, requested_chipid)
        self.requested_chipid = requested_chipid
        self.rd_chipid = rd_chipid

    def __str__(self):
        return repr(self.value)

    def __requested_chipid__(self):
        return repr(self.requested_chipid)

    def __rd_chipid__(self):
        return repr(self.rd_chipid)

class DataReadbackMismatchError(ChipError):
    """basic class to handle the data readback mismatch exception when writing to the chip"""
    def __init__(self, value="", written_data="", rd_data=""):
        super(DataReadbackMismatchError, self).__init__()
        self.value = value.format(written_data, rd_data)
        self.written_data = written_data
        self.rd_data = rd_data

    def __str__(self):
        return repr(self.value)

    def __written_data__(self):
        return repr(self.written_data)

    def __rd_data__(self):
        return repr(self.rd_data)

class ExternalShutdownError(Exception):
    """basic class to handle the external shutdown of the deamon"""
    def __init__(self, signum):
        super(ExternalShutdownError, self).__init__()
        self.signum = signum

    def __signum__():
        return repr(self.signum)
