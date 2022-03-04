"""Include paths for external module files"""

import importlib.util
import sys,os

_MODULES_FOLDER_PATH = os.path.split(os.path.realpath(__file__))[0] + "/../../../"
_MODULES = [
    # (<module_name>, <relative path (from modules folder)>)
    ('communication', 'usb_if/software/usb_communication/communication.py'),
    ('can_hlp', 'dcs_canbus/software/can_hlp/can_hlp.py'),
    ('ecc_functions', 'board_support_software/software/py/ecc_conversion/ecc_functions.py'),
    ('generateScrubbingFile', 'board_support_software/software/py/ecc_conversion/generateScrubbingFile.py'),
    ('makeparameters', 'board_support_software/software/py/ecc_conversion/makeparameters.py')
]


for module_name,module_path in _MODULES:
    spec = importlib.util.spec_from_file_location(module_name, _MODULES_FOLDER_PATH + module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    sys.modules[module_name] = module
