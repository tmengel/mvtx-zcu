import time
import socket
import datetime
from datetime import datetime

UDP_IP = "PIEPAID1" # hostname of PI device on cern net
UDP_PORT = 5005
MAGIC_WORD = "ping"

class CharmTrigger(object):
    def __init__(self, hostname=UDP_IP,port=UDP_PORT):
        self.hostname = hostname
        self.port = port
        self.sock = socket.socket(socket.AF_INET, # Internet
                                  socket.SOCK_DGRAM) # UDP
        self.sock.bind(("", UDP_PORT))
        self.sock.settimeout(1) # 1 sec timeout
        self.last_spill = None

    def initialize_trigger(self):
        self.get_last_spill()

    def get_last_spill(self):
        """Returns data:
        {Y|N}:<last_spill_timestamp>"""
        try:
          self.sock.sendto(MAGIC_WORD.encode("utf8"), (self.hostname, self.port))
          data, (addr_in, port_in) = self.sock.recvfrom(100)
        except socket.timeout:
          print("No answer from trigger capturer")
        self._store_last_spill(data)
        return data

    def _store_last_spill(self, data):
        """stores the last spill internally to the class"""
        wasSpill = data[0] == b'Y'[0]
        if wasSpill:
            self.last_spill = data[2:].decode('utf-8')

    def check_spill(self):
        return self.get_last_spill()[0] == b'Y'[0]

def main():
    trigger = CharmTrigger()

    NR_TESTS = 10000
    start = time.time()
    spillCount = 0
    spills = []
    spillsRec = []
    for i in range(NR_TESTS):
        data = trigger.get_last_spill()
        wasSpill = data[0] == b'Y'[0]
        if wasSpill:
            spillsRec.append(datetime.now())
            spillCount += 1
            spill_str = data[2:].decode('utf-8')
            #2017-10-20 18:25:38.321089
            spill_ts = datetime.strptime(spill_str,'%Y-%m-%d %H:%M:%S.%f')
            spills.append(spill_ts)
        #time.sleep(0.01)
    end = time.time()

    elapsed = end - start
    avg_time = elapsed/NR_TESTS
    print("{0} Spills counted".format(spillCount))
    print("Time for {0} Reads: {1:.2f}s, average call time: {2:.4f}s".format(NR_TESTS,elapsed,avg_time))

    spill_delay = [(tr-ts).total_seconds()*1000 for tr,ts in zip(spillsRec,spills)]

    print("Time between spill and recognition by script [ms]")
    print(spill_delay)

if __name__ == '__main__':
    main()
