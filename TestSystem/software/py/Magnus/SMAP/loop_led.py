from PA3 import PA3
import sys
import fire
from time import sleep

LEDS = 67

debug = None
id_card = "21:00.0"
gbt_ch = 0
board = 'CRU'
    
pa3 = PA3(id_card, 2, gbt_ch, board, debug)

pa3.init()
try:
    print("starting LED looop")
    i = 0
    pattern=[1,0,2,0]
    while True: # I want 1 - 0 - 2 - 0
        pa3.write(LEDS, pattern[i])
        sleep(0.25)
        i += 1
        if i>3:
            i =0
except KeyboardInterrupt:
    print("C-C detected")
