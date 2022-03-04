"""
@author: magnus.ersdal@gmail.com
readout all frames to individual files
"""
from PA3 import PA3
from read_selmap import Smap
import h5py as h5

#we need to initialize the PA3 here. if this is main...
debug = None
id_card = "21:00.0"
gbt_ch = 0
board = 'CRU'

pa3 = PA3(id_card, 2, gbt_ch, board, debug)
pa3.init()

sm = Smap(pa3)

fradsfile="fradsread.txt"
with open(fradsfile, "r") as fradf:
    addresses = []
    next(fradf) # skip header
    for line in fradf:
        adr = line.split(',')[0]
        adr = int(adr, 16)
        addresses.append(adr)
    print("{} addresses to read".format(len(addresses)))
    hugedata = sm.rd_frames(addresses)
    #hugedata = [[1,2,3],[4,5,6]]
    #print(hugedata)
    # here comes H5.
    # Groups work like dictionaries, and datasets work like NumPy arrays
    # so 1 group per array.
    #addresses = [0,1]
    print("writing to file")
    with h5.File('testds.hdf5', 'w') as f:
        g =f.create_group("frames")
        for adr in addresses:
            no = addresses.index(adr)
            ds = g.create_dataset(str(adr),data=hugedata[no], dtype='i')
            #print(ds[:])
