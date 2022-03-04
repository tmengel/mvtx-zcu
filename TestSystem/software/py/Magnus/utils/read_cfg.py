"""
@author = magnus,ersdal@uib.no
"""
import os
import sys

if sys.version_info < (3, 0):
    # We are in python 2 :(
    import ConfigParser as configparser
else:
    import configparser


def get_cfg(filename='hardware_config.ini'):
    cfg = configparser.ConfigParser()
    cfg.read(filename)
    pkg_path = cfg.get("keys", "pkg_path")
    dk = {"pkg_path": "placeholder",
          "id_card": cfg.get("keys", "id_card"),
          "gbt_ch": cfg.getint("keys", "gbt_ch")
          }
    if "./" in pkg_path:
        # we have a relative path
        dirname = os.path.dirname(__file__)
        dirname = os.path.dirname(dirname)
        pkg_path = pkg_path[2:]
        filename = os.path.join(dirname, pkg_path)
        dk["pkg_path"] = filename
    else:
        dk["pkg_path"] = pkg_path
    return dk


if __name__ == "__main__":
    d = get_cfg("../hardware_config.ini")
    for a, b in d.items():
        print(a, b)
