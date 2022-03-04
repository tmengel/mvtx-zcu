"""File describing the trigger types while the trigger hanlder class is not present"""

from enum import IntFlag

class BitMap(IntFlag):
    """Trigger bit mapping as from gbtx_pkg.vhd"""
    ORBIT   = 0  # Orbit
    HBa     = 1  # Heartbeat accept
    HBr     = 2  # Heartbeat reject
    HBc     = 3  # Health check
    PHYSICS = 4  # Physics Trigger
    PP      = 5  # Prepulse
    CAL     = 6  # Calibration
    SOT     = 7  # Start of triggered data
    EOT     = 8  # End of triggered data
    SOC     = 9  # Stpfart of Continuous Data
    EOC     = 10 # End of Continuous Data
    TF      = 11 # Time Frame delimiter
