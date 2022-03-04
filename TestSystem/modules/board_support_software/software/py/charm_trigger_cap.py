import socket
#import RPi.GPIO as GPIO # For Raspberry PI
import OPi.GPIO as GPIO # For Orange PI
import datetime
from datetime import datetime
import time
import signal
import sys
from threading import Timer,Thread,Event

TRIGGER_PIN = 5 #GPIO03

# Global vars for sharing state, only write on one process
global trigger
trigger = False
global trigger_prev
trigger_prev = False
global timestamp
timestamp = datetime.utcnow()

# Logfile
filename = "spill_log_" + str(timestamp.time()).replace(':','-') + ".csv"
logfile = open(filename, "w", -1)

# Ctrl-C handler
def signal_handler(signal, frame):
        logfile.close()
        GPIO.cleanup()
        sys.exit(0)
signal.signal(signal.SIGINT, signal_handler)

# Setup pin
GPIO.setmode(GPIO.BOARD)
GPIO.setup(TRIGGER_PIN, GPIO.IN)
print "Trigger pin on pin " + str(TRIGGER_PIN) + " initial state " + str(GPIO.input(TRIGGER_PIN))

# Setup event handling of edge detection
def trigger_event(TRIGGER_PIN):
  global timestamp
  global trigger
  timestamp2 = datetime.utcnow()
  if trigger_prev == trigger:
    trigger = ~trigger
  print "Trigger at " + str(timestamp2.time()) + " delta " + str((timestamp2-timestamp).total_seconds())
  logfile.write(str(timestamp2.date()) + ";" + str(timestamp2.time()) + ";" + str((timestamp2-timestamp).total_seconds())+"\n")
  timestamp = timestamp2
  #time.sleep(0.1) # 100ms to prevent bounce

GPIO.add_event_detect(TRIGGER_PIN, GPIO.FALLING, callback=trigger_event)

# class perpetualTimer():

   # def __init__(self,t,hFunction):
      # self.t=t
      # self.hFunction = hFunction
      # self.thread = Timer(self.t,self.handle_function)

   # def handle_function(self):
      # self.hFunction()
      # self.thread = Timer(self.t,self.handle_function)
      # self.thread.start()

   # def start(self):
      # self.thread.start()

   # def cancel(self):
      # self.thread.cancel()
      
# def printer():
  # global timestamp
  # global trigger
  # timestamp2 = datetime.utcnow()
  # if trigger_prev == trigger:
    # trigger = ~trigger
  # print "Trigger at " + str(timestamp2.time()) + " delta " + str((timestamp2-timestamp).total_seconds())
  # logfile.write(str(timestamp2.date()) + ";" + str(timestamp2.time()) + ";" + str((timestamp2-timestamp).total_seconds())+"\n")
  # timestamp = timestamp2

# Setup UDP
UDP_PORT = 5005
MAGIC_WORD = "ping"
sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
sock.bind(("", UDP_PORT))

# For testing
# t = perpetualTimer(5,printer)
# t.start()

# Main loop
while True:
  data, (addr_in, port_in) = sock.recvfrom(20)
  if data == MAGIC_WORD:
    if trigger != trigger_prev: # New trigger
      trigger_prev = trigger
      sock.sendto("Y:"+str(timestamp), (addr_in, UDP_PORT))
    else:
      sock.sendto("N:"+str(timestamp), (addr_in, UDP_PORT))
