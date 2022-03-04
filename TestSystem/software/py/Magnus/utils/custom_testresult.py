"""
custom_testresult.py:
A modification of the unittest.TestResult class so that we can dump
the PA3 registers on test failure
usage:
runner = unittest.TextTestRunner(verbosity=3, resultclass=Pa3_test_result)
result = runner.run(suite)
__author__ = Magnus (magnus.ersdal@uib.no)
"""
import unittest
import logging
from utils.setup_registers import get_register_set_for_pa3


class Pa3_test_result(unittest.TestResult):
    def addFailure(self, test, err):
        print("should log some stuff")
        print("dumpregs")
        registers = get_register_set_for_pa3()
        logger = logging.getLogger("DumpRegisters")
        logger.setLevel("INFO")

        logger.info("Dumping Registers as cause of fault")
        logger.info(
            registers.get_all_registers_string()
        )
        super(Pa3_test_result, self).addFailure(test, err)

    def addError(self, test, err):
        # here you can do what you want to do when a test case raises an error
        super(Pa3_test_result, self).addError(test, err)
