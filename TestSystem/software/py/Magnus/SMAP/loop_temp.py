from PA3 import PA3
import sys
import fire
from time import sleep
from math import sqrt

LEDS = 67

debug = None
id_card = "21:00.0"
gbt_ch = 0
board = 'CRU'

ADC_GO =  0x14000002
W_INSEL = 0x14000050
R_INSEL = 0x14000051
TEMP_1 = 23
TEMP_2 = 24
    
pa3 = PA3(id_card, 2, gbt_ch, board, debug)

gain = {}
pa3.init()
pa3.sca.adcEn() # enable SCA adc
pa3.sca.wr(0x14030050,TEMP_1)
pa3.sca.wr(0x14030011,0)
gain[TEMP_1] = pa3.sca.rd()
pa3.sca.wr(0x14030050,TEMP_2)
pa3.sca.wr(0x14030011,0)
gain[TEMP_2] = pa3.sca.rd()

def convADCtoTemp(voltage, ch=1):
    v = voltage
    i = 100e-6 # 100uA
    r = v/i # U = RI -> R = U / I
    if r == 0:
        print("Error in R value. maybe SCA is weird")
        r = 1300
    if r > 2000:
        print("Error in R value. maybe SCA is weird")
        r = 1300
    if ch==1:
        comp = 0.8469 * 1.003512293# measured compensation value..
    if ch==2: 
        comp = 0.8469 * 1.003512293
    r = r * comp
    #print("R{1} is {0:.3f} ohms".format(r,ch))
    r0 = 1000
    A = 3.9083E-3 * r0
    B = -5.775E-7 * r0
    t =( -A + sqrt((A * A) - 4* B * (r0 - r)) ) / (2 * B)
    # ~ 4 ohms per C.. 1000 ohm at 0 C so
   
    temp = t #basically(r - 1000) / 4
    return temp

def readpt1000(channel):
    # 1 enable current source 
    # 2 read voltage 
    # 3 disable current source
    pa3.sca.wr(0x14030060, 1 << channel)
    val = pa3.sca.adcRd(channel)
    pa3.sca.wr(0x14030060, 0)
    val = float(val)/gain[channel]
    return val

# stats taken from https://stackoverflow.com/questions/15389768/standard-deviation-of-a-list
def mean(data):
    """Return the sample arithmetic mean of data."""
    n = len(data)
    if n < 1:
        raise ValueError('mean requires at least one data point')
    return sum(data)/n # in Python 2 use sum(data)/float(n)

def _ss(data):
    """Return sum of square deviations of sequence data."""
    c = mean(data)
    ss = sum((x-c)**2 for x in data)
    return ss

def stddev(data, ddof=0):
    """Calculates the population standard deviation
    by default; specify ddof=1 to compute the sample
    standard deviation."""
    n = len(data)
    if n < 2:
        raise ValueError('variance requires at least two data points')
    ss = _ss(data)
    pvar = ss/(n-ddof)
    return pvar**0.5

try:
    print("starting loop")
    i = 0
    alltemps = []
    while True: # I want 1 - 0 - 2 - 0
        sleep(0.1)
        v1 = readpt1000(TEMP_1)
        v2 = readpt1000(TEMP_2)
        temp1 = convADCtoTemp(v1,ch=1)
        temp2 = convADCtoTemp(v2,ch=2)
        alltemps.append((temp1,temp2))
        avgt1 =sum([t[0] for t in alltemps])/len(alltemps)
        avgt2 =sum([t[1] for t in alltemps])/len(alltemps)
        #print("temperatures are:")
        #print("1: {0:.3f}, 2: {1:.3f} ".format(temp1,temp2))
        i += 1
        if i%20 == 0:
            std1 = stddev([t[0] for t in alltemps])
            std2 = stddev([t[1] for t in alltemps])
            print("avg1: {0:.1f}+/-{2:.2f}, avg2: {1:.1f}+/-{3:.2f} ".format(avgt1,avgt2,std1,std2))
            alltemps = []
except KeyboardInterrupt:
    print("C-C detected")
