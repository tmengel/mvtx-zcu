"""
@author: magnus.ersdal@uib.no

flips a bit in an array of 32bit numbers
"""

def flip(array, index, bitnumber):
    tnum = array[index]
    bitmask = 0b1 << bitnumber    
    newnum = tnum ^ bitmask# (XOR) 
    array[index] = newnum
    print("flip bit", hex(tnum), "into", hex(newnum))
    return array


##tests
def test_flip():
    array =[0x1, 0x2, 0xFFFFFFFF]
    def hxar(array):
        return [hex(x) for x in array]
    print(hxar(array))
    print(hxar(flip(array, 2, 31)))
    print(hxar(flip(array, 2, 0)))
    print(hxar(flip(array, 2, 1)))
    print(hxar(flip(array, 2, 1)))
    print(hxar(array))
    print(hxar(flip(array, 0, 0)))
    print(hxar(flip(array, 0, 0)))

if __name__ == "__main__":
    test_flip()
