"""
@author: magnus.ersdal@uib.no
"""
SMAP_CMD 	= 24 #	RW 	Selectmap Interface: Command register
SMAP_DATA_TX 	= 25 #	R 	Selectmap Interface: Data TX register
SMAP_DATA_RX 	= 26 #	RW 	Selectmap Interface: Data RX register
SMAP_STATUS 	= 27 #	R 	Selectmap interface: Status register
#SMAP_C ={'INIT':0x01, 'STARTUP':0x02, 'WRITE':0x04, 'STREAM_WR':0x08, 'READ':0x10,
#'STREAM_RD':0x20, 'ABORT':0x40, 'RDWR_DONE':0x80
#}
SMAP_C ={'WRITE':0x84,'READ':0x88,'ABORT':0x90, 'RDWR_DONE':0xA0} # commands are (0x80 | (instruction in pkg file))
XIL_ADDR={'CRC':0, 'FAR': 1, 'FDRI':2, 'FDRO':3, 'CMD':4, 'CTL0':5, 'MASK':6, 'STAT':7, 'LOUT':8, 'COR0':9,
'MFWR':10, 'CBC':11, 'IDCODE':12, 'AXSS':13, 'COR1':14, 'WBSTAR':16, 'TIMER':17, 'BOOTSTS':22, 'CTL1':24, 'BSPI':31}
NOOP = 0x20000000
# INIT deletes Xilinx
# RD PAGE : READ
# WRITE : WRITE
# scubbing ISx_bytes * write
# startup at END of transactions
# writes to the CTL register is masked by the MASK register.

import copy
from PA3 import PA3
import fire



class Smap():
    def __init__(self,pa3):
        self.pa3 = pa3

    def rd_frames(self,addresses):
        """write each frame to a list in a list"""
        data=[]
        i = 0
        for k in range(len(addresses)):
            data.append([])
        #print("rd_frames_empty:")
        #print(data)
        for adr in addresses:
            retval = self.CMRP(adr)
            data[i] = retval
            i+=1
        return data

    def wr_frames(self,addresses,datali):
        """use this function to write (a) frame(s)"""
        # [[d1],[d2]] and [adr1, adr2]
        for adr,data in zip(addresses,datali):
            self.CMWP(data,adr)

    def  CMWP(self,framedata,address):
        """writes a frame"""
        return self.oldschool_write(framedata,address)

    def write(self,data):
        self.pa3.write(SMAP_DATA_RX,data) # insert data
        self.pa3.write(SMAP_CMD, SMAP_C['WRITE']) # GO

    def read(self):
        self.pa3.write(SMAP_CMD, SMAP_C['READ'])
        data = self.pa3.read(SMAP_DATA_TX) 
        return data

    def write4bytes(self,data=0x00000000):
        sequence = [(data >> i*8) & 0xff for i in range(4)]
        sequence.reverse()
        #print(["{0:02X}".format(item) for item in sequence])
        for item in sequence:
            self.write(item)
            
    def read4bytes(self):
        data =0
        dlist = []
        for i in range(4):
            dlist.append(self.read())
            #print("data {} = {:02X}".format(i,data))
        #print([hex(i) for i in dlist])
        data = dlist[0] << 8*3  |  dlist[1] << 8*2 |  dlist[2] << 8*1 |  dlist[3]
        return data
  
    def sm_write(self, addr, data):
        sequence1 =[0xFFFFFFFF,0xFFFFBB11,
                    0xFFFFFFFF,0xAA995566,0x20000000] #launch?
        primary= 0x30000001 | (addr << 13) #LSB IS bit pos 13. 5 bits long addr
        #print("made addr 0x{0:0x} from input 0x{1:0x}".format(primary, addr))
        secondary = data
        sequence2 = [primary, secondary, 0x20000000,0x20000000] #register and data
        sq1 = sequence1 + sequence2
        sequence3 =[0x30008001,0x0000000D,0x20000000,0x20000000] # fini? 

        for item in (sq1):
            self.write4bytes(item) # WRITE
        return data

    def sm_read(self, addr):
        sequence1 =[0xFFFFFFFF,0xFFFFBB11,
                    0xFFFFFFFF,0xAA995566,0x20000000] #launch?
        #sequence2 =[0x28018001,0x20000000,0x20000000] #IDCODEregister
        primary= 0x28000001 | (addr << 13) #LSB IS bit pos 13. 5 bits long addr
        #print("made addr 0x{0:0x} from input 0x{1:0x}".format(primary, addr))
        sequence2 = [primary, 0x20000000,0x20000000] #register and data
        sequence3 =[0x30008001,0x0000000D,0x20000000,0x20000000] # fini? 

        for item in (sequence1 + sequence2):
            self.write4bytes(item) # WRITE
        data = self.read4bytes() # READ
        for item in(sequence3):
            self.write4bytes(item)
        return data

    def type1_w(self,addr, size=1):
        return 0x30000000 | (addr << 13) | size
    def type1_r(self, addr, size=1):
        return  0x28000000 | (addr << 13) | size
    def type2_r(self, nframes):
        # in manual:
        # kintex ultrascale: 
        # FDRO read length = (words per frame)*(frames to read +1) +10
        # 123 * 2 + 10 
        # use only ONE value
        wordcount = 123*(nframes+1) +10
        return 0b01001 << 27 | wordcount

    def type2_w(self, nframes):
        # on this chip there are 49030 frames
        # equating to 6030690 words
        wordcount = (nframes +1)* 123 + 10 # maybewrong
        #print("Wordcount: {}".format(wordcount))
        return 0b01010 << 27 | wordcount

    def readstatusreg(self):
        print("status is:")
        status = self.sm_read(XIL_ADDR['STAT'])
        print(bin(status))
        if status & 0b1:
            print("CRC ERROR")
        if status & (0b1 << 2):
            print("MMCM_PLL_LOCKED")
        if status & (0b1 << 15):
            print("IDCODE ERROR")
        if status & (0b1 << 16):
            print("SECURITY ERROR")
        bwd = (status & (0b11 << 25)) >> 25 
        print("bus width det= {0:02b}".format(bwd))

    def CMRP(self, startaddr=0, nframes=1, ignorefs=0):
        """Configuration Memory Read Procedure (SelectMAP)"""
        data=[]
        CMD = self.type1_w(XIL_ADDR['CMD'])
        #1 bus detection sequence and synchro word
        steps = [0xFFFFFFFF,0xFFFFBB11,0xFFFFFFFF,0xAA995566] # removed a noop
        #2 write shutdown (in documentation, disabled for us)
        steps += [NOOP] #[CMD,0xB,NOOP]
        #3 write RCRC
        #step3 = [CMD,0x7,NOOP] # reset CRC
        #4 write 5 noop
        #step4 = [NOOP]*5
        #5 write RFCG 
        steps += [CMD,0x4, NOOP, NOOP]
        # 6 write 1 word FAR (ADDRESS!)
        steps += [self.type1_w(XIL_ADDR['FAR']),startaddr]
        # 7 readcommand
        steps += [self.type1_r(XIL_ADDR['FDRO'],size=0), self.type2_r(nframes)]
        # 8 flush the packet buffer
        steps += [NOOP]#[NOOP]*64 # flush the packet buffer

        for item in (steps):
            self.write4bytes(item) # WRITE
        for i in range(123 + 11): # whaaaaaaa???
            _junk = self.read4bytes()
        for i in range(123):
            retval = self.read4bytes()
            data.append(retval)

        # 9 write start (in documentation, disabled for us.)
        steps1 = [NOOP]#[NOOP, CMD, 0x5, NOOP]
        # 10 write RCRC
        steps1 += [CMD,0x7,NOOP]
        # 11 write DESYNC
        steps1 += [CMD,0xD,NOOP,NOOP,NOOP,NOOP]
        #last_steps = step9 + step10 + step11
        last_steps = steps1
        for item in (last_steps):
                 self.write4bytes(item) # WRITE
        #print([hex(x) for x in data])
        return data
    

    
 
            

    def oldschool_write(self,framedata, address, nframes=1):
        CMD = self.type1_w(XIL_ADDR['CMD'])

        steps = [0xFFFFFFFF,0xFFFFBB11,0xFFFFFFFF,0xAA995566]
        steps += [CMD,0x7]
        steps += [self.type1_w(XIL_ADDR['IDCODE']), 0x13919093]
        #DROPsteps += [0x300016001, 123] # frame length
        steps += [CMD,0x1, NOOP]
        steps += [self.type1_w(XIL_ADDR['FAR']), address, NOOP]
        steps += [self.type1_w(XIL_ADDR['FDRI'],size=0), self.type2_w(nframes)]
        steps += framedata + [0]*(123 +10)
        #print("write is len {}".format(len(framedata + [0]*(123+10))))
        # default CRC ?????
        steps += [CMD,0x7] # reset CRC
        steps += [CMD,0xD,NOOP,NOOP,NOOP,NOOP]
        for item in steps:
            #print(hex(item))
            self.write4bytes(item)    


    def end(self):
        self.pa3.write(SMAP_CMD, SMAP_C['RDWR_DONE'])

    def abort(self):
        self.pa3.write(SMAP_CMD, SMAP_C['ABORT'])

    def enable_glutmask(self):
        self.sm_write(XIL_ADDR['MASK'], 0b1 << 23)
        #print(hex(self.sm_read(XIL_ADDR['MASK'])))
        self.sm_write(XIL_ADDR['CTL1'], 0xFFFFFFFF)


    def corrupt_frame(self):
        tframes = [makeadr(row=0,col=0,minor=0), makeadr(row=0,col=20,minor=1), makeadr(row=0,col=21,minor=2), makeadr(row=0,col=1,minor=3), makeadr(row=0,col=1,minor=4)]
        data = self.rd_frames(tframes)
        print(get2dhex(data))
        data2 = copy.deepcopy(data)
        data2[0][48]=0xAB
        data2[1][60]=0xAA
        data2[2][20]=0xAA
        data2[3][60]=0xAA
        data2[4][60]=0xAA
        assert data != data2
        self.wr_frames(tframes, data2)
        print("should be modded:")
        print(get2dhex(self.rd_frames(tframes)))
        #sm.wr_frames(tframes, data)
        #print("should be restored:")
        #print(get2dhex(sm.rd_frames(tframes)))    # make a fucked frame
        # read fr

    def read_modded_frames(self):
        tframes = [makeadr(row=0,col=0,minor=0), makeadr(row=0,col=20,minor=1), makeadr(row=0,col=21,minor=2), makeadr(row=0,col=1,minor=3), makeadr(row=0,col=1,minor=4)]
        data = self.rd_frames(tframes)
        print(get2dhex(data))


def listofsets(data):
    setlist =[]
    for j in range(len(data)):
            setlist.append([])
    #print("=================")
    i =0
    for row in data:
        #print(list(set(row)))
        setlist[i] = list(set(row))
        i+=1
        #print("=================")
    return setlist

def rel_entropy(listofsets):
    lengths = []
    for item in listofsets:
        lengths.append(len(item))
    maxlen = max(lengths)
    entropy=[]
    for l in lengths:
        entropy.append(int(float(l)/maxlen * 100))
    return entropy

def get_lengths(listofsets):
    lengths = []
    for item in listofsets:
        lengths.append(len(item))
    return lengths

def makeadr(row=0,col=0,minor=0):
    # row is 6 bits
    # col is 10 bits
    # minor is 7 bits
    assert row <= 0b111111
    assert col <= 0b1111111111
    assert minor <= 0b1111111
    adr = 0b000 << 23 | (row << 17) | (col << 7) | minor
    return adr

def test_sm_rw(sm):
    rwadrlist=['FAR', 'CMD', 'CTL0', 'MASK', 'COR0', 'AXSS', 'COR1', 'CTL1']
    for rwadr in rwadrlist:
        #rwadr = 'FAR'
        a1 =sm.sm_read(XIL_ADDR[rwadr])
        b =abs(a1 -0x3)
        sm.sm_write(XIL_ADDR[rwadr],b)
        a2 =sm.sm_read(XIL_ADDR[rwadr])
        try:
            assert a1 != a2
        except AssertionError:
            if rwadr.find('CTL') == 0: # if CTL0 or CTL1 reg:
                print("CTL adress is masked")
            else:
                print("adr {} failed simple write ({})".format(rwadr,hex(a1)))
        if a1 != a2:
            print("adr {} 1:{}, 2:{}".format(rwadr, hex(a1), hex(a2)))
        sm.sm_write(XIL_ADDR[rwadr],a1) # reset setting..


def test_frame_rw(sm):
    tframe = makeadr(row=0,col=0,minor=0)
    print("adr:" + hex(tframe))
    refdata = sm.rd_frames([tframe])
    print(refdata)
    print("len: {}".format(len(refdata[0])))
    chdata = copy.deepcopy(refdata) # remember, 2d
    #chdata[0][-1] = 0xAFFFFFFA # change word in chdata
    #chdata[0]= [6]*len(refdata[0]) # should nbe 123
    no = 48
    print("changing no {}, which is {} into 0xAA".format(no, hex(chdata[0][no])))
    chdata[0][no] =0xAA

    #chdata[0][-11] = 0xAA
    print(chdata)
    assert chdata != refdata
    # write data !!!
    sm.continuous_write(chdata[0], tframe)
    readoutdata = sm.rd_frames([tframe])
    if readoutdata == chdata:
        print("success in changing the data")
    sm.readstatusreg()
    print("readoutdata::::::::::::::::")
    #print(readoutdata)
    print(readoutdata)
    print([hex(x) for x in list(set(readoutdata[0]))])
    print("chdata:::::::::::::::::::::")
    print(chdata)
    print([hex(x) for x in list(set(chdata[0]))])
    return refdata, tframe

def get2dhex(data):
    return [[hex(x) for x in row] for row in data]

def test_multiframe_rw(sm):
    tframes = [makeadr(row=0,col=0,minor=0), makeadr(row=0,col=1,minor=1), makeadr(row=0,col=1,minor=2), makeadr(row=0,col=1,minor=3), makeadr(row=0,col=1,minor=4)]
    data = sm.rd_frames(tframes)
    print(get2dhex(data))
    data2 = copy.deepcopy(data)
    data2[0][48]=0xAB
    data2[1][60]=0xAA
    data2[2][20]=0xAA
    data2[3][60]=0xAA
    data2[4][60]=0xAA
    assert data != data2
    sm.wr_frames(tframes, data2)
    print("should be modded:")
    print(get2dhex(sm.rd_frames(tframes)))
    sm.wr_frames(tframes, data)
    print("should be restored:")
    print(get2dhex(sm.rd_frames(tframes)))

if __name__ == "__main__":
    #we need to initialize the PA3 here. if this is main...
    debug = None
    id_card = "21:00.0"
    gbt_ch = 0
    board = 'CRU'
    
    pa3 = PA3(id_card, 2, gbt_ch, board, debug)
    pa3.init()
    sm = Smap(pa3)

    fire.Fire(sm)

#if __name__ == "__main__":
    # do some testing
 #   try:
 #       sm = Smap(pa3)
        #print("starting test")
        #sm = Smap(pa3)
        #steps = [sm.sm_read(XIL_ADDR['CTL1'])
        #sm.sm_write(XIL_ADDR['MASK'], 0b1 << 23)
        #print(hex(sm.sm_read(XIL_ADDR['MASK'])))
        #sm.sm_write(XIL_ADDR['CTL1'], 0xFFFFFFFF)
        #print("CTL1:")
        #print(hex(sm.sm_read(XIL_ADDR['CTL1']))) # sm.sm_read(XIL_ADDR[rwadr])

 #   except KeyboardInterrupt:
 #       print("C-C detected")
  #      sm.abort()
  #  finally:
    #    sm.end()
