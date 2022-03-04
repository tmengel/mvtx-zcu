"""
@author: magnus.ersdal@uib.no

read frads file from other software into nicer format
"""

fn = "xcku060_frads.txt"
fn2 = "fradsread.txt"

with open(fn,"r") as infile, open(fn2, "w+") as outfile:
    outfile.write("FAR, col, row\n")
    for line in infile:
        #print(line.split())
        items = line.split()
        if len(items) == 5:
            id = dict([x.split('=') for x in items])
            if id['type'] == '0':
                print("shouldprint")
                fstring ="{},{},{}\n".format(
                    id['FAR'], id['column'], id['row'])
                print("writing" + fstring)
                outfile.write(fstring)
