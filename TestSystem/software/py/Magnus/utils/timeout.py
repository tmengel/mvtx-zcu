from __future__ import print_function
from timeout_decorator import timeout_decorator
from threading import Thread
import functools
import os

# timeout decorator is not working on windows.
if os.name == 'nt':
    # workaround for windows
    def timeout(timeout):
        def deco(func):
            @functools.wraps(func)
            def wrapper(*args, **kwargs):
                res = [Exception('function [%s] timeout [%s seconds] exceeded!' % (func.__name__, timeout))]

                def newFunc():
                    try:
                        res[0] = func(*args, **kwargs)
                    except Exception as e:
                        res[0] = e

                t = Thread(target=newFunc)
                t.daemon = True
                try:
                    t.start()
                    t.join(timeout)
                except Exception as je:
                    print('error starting thread')
                    raise je
                ret = res[0]
                if isinstance(ret, BaseException):
                    raise ret
                return ret

            return wrapper

        return deco
else:
    def timeout(timeout):
        return timeout_decorator.timeout(timeout)

if __name__ == '__main__':
    import time


    @timeout(1.11)
    def foo():
        while True:
            print("lalalalalala")
            time.sleep(0.1)


    while True:
        foo()
