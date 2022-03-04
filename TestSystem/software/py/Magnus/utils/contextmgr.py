"""
@author = magnus.ersdal@uib.no
"""
from functools import wraps
from colorama import Fore, Style
import logging
from logging.config import fileConfig


# return "<b>" + fn() + "</b>"

def logonly(exceptions):
    """
    Decorator wrapper to make test cases warn instead of failing.
    :type exceptions: tuple (or single exception)
    """
    fileConfig('logging_config.ini', disable_existing_loggers=False)
    logger = logging.getLogger(__name__)

    def decorator(function):
        @wraps(function)
        def wrapper(*args, **kwargs):
            try:
                function(*args, **kwargs)
            except exceptions as e:
                estr =str ( "\n" + Fore.RED + "FAILURE" + Style.RESET_ALL + "\n"
                        + Fore.MAGENTA + " there was an exception in "
                      + function.__name__ + "\n" + str(e) + Style.RESET_ALL)
                logger.debug(estr)
                logger.info(estr)
                print(estr)

        return wrapper

    return decorator


def call_then_raise(f_to_call):
    """
    calls function then raises exception
    """
    fileConfig('logging_config.ini', disable_existing_loggers=False)
    logger = logging.getLogger(__name__)

    def decorator(function):
        @wraps(function)
        def wrapper(*args, **kwargs):
            try:
                function(*args, **kwargs)
            except Exception as e:
                estr =str ( "\n" + Fore.RED + "FAILURE" + Style.RESET_ALL + "\n"
                        + Fore.MAGENTA + " there was an exception in "
                      + function.__name__ + "\n" + str(e) + Style.RESET_ALL)
                logger.debug(estr)
                logger.info(estr)
                print(estr)
                f_to_call()
                raise

        return wrapper

    return decorator
