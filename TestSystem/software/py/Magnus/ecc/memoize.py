"""
@author: Magnus Rentsch Ersdal (magnus.ersdal@uib.no)
stolen from python-course.eu/python3_memoization.php
cannot be used with mutable args
use with decorator...
"""

class Memoize:
    """cannot be used with mutable args"""
    def __init__(self,fn):
        self.fn = fn
        self.memo = {}

    def __call__(self, *args):
        if args not in self.memo:
            self.memo[args] = self.fn(*args)
        return self.memo[args]
