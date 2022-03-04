# Event Filter / Parser

This program provides a means of reading an event stream read from
the CRU emulator (RUv0), parsing it's content and extracting event
information (both meta information and event information).

## Usage

### Requirements
The code can be compiled with any recent compiler with C++11 support
(tested with gcc 4.8). Additionally, the boost libraries need to be
installed.

### Compilation

The project uses cmake as build tool. For compilation, best practice is to create a build folder and build in from there:

- $mkdir build
- $cd build
- $cmake ..
- $make

This will create an event_filter executable, which can then be
executed.

### Running

The program reads binary data from the standard input stdin, parses it
and prints information to a logging file and stdout. The source can be
a stored data file, network port or compressed file. Examples of running:

- cat datafile.bin | ./event_filter # From a local file
- uncompress -c datafile.Z | ./event_filter # compressed local file
- netcat localhost 30001 | ./event_filter # directly from usb_comm_server

### Input Stream

The parsing of the input is designed to be used with the readout chain
Sensor -> RUv1 -> GBTx -> GBT_FPGA (RUv0) -> FX3 -> PC. This gives the
following assumptions on the data stream:

- Packets received from the RUv1 in the RUv0 are as follows:
  - (data_valid) 'D9 D8 D7 ... D1 D0'
- RUv0 packages one GBT word into three USB words:
  - Word0: '<data_valid>000_0000' 00 D9 D8
  - Word1: D7 D6 D5 D4
  - Word2: D3 D2 D1 D0
- The USB interface from RUv0 sends words as integers in little endian to the PC. This shuffles the bytes:
  - Word0: D8 D9 00 '<data_valid>000_0000'
  - Word1: D4 D5 D6 D7
  - Word2: D0 D1 D2 D3
- With this, a single GBT word is located within 12 bytes of the input stream with the following order:
  - #with d as a byte array from the input stream
  - gbt_word0 : d[1],d[0],d[7],d[6],d[5],d[4],d[11],d[10],d[9],d[8]
  - gbt_word1 : d[12+1],d[12+0], ..., d[12+8]
  - ...
  - gbt_word_N : d[12*n+1],d[12*n+0], ..., d[12*n+8]
- For a GBT word containing Channel data, The payload data is as
  follows, with CHAN being the Lane id (1 to N) and D8..D0 being the
  payload from the sensor:
  - CHAN D8 D7 D6 D5 D4 D3 D2 D1 D0
- This gives a Reading order (within 12 bytes of a gbt word) as
  follows:
  - idx = 12*n # n=packet number
  - data_valid = d[idx+3] >> 7
  - channel = d[idx + 1]
  - data = d[idx+1], d[idx+0], d[idx+7], d[idx+6], d[idx+5], d[idx+4], d[idx+11], d[idx+10], d[idx+9], d[idx+8]

### Results
During execution, statistics of the parsing are printed on
stdout. This shows the amount of events parsed, the amount of errors
in events and the amount of GBT protocol parsed between two print
segments. If the input stream is exhausted, a short summary for each
data lane is printed.

In addition, result files are created, which contain the information
in a procassable way:

- hitmap.csv: Stores the accumulated hit count for each hit in a chip as a table
- bunch_counters.csv: A table containing a count of each bunch counter value received by lane
- results.json: Structured storage of the results for each lane:
```
{
    "Lane_1": # Lane number
    {
        "goodEvents": "20555586", # Number of good events
        "badEvents": "0", # Number of Events with Errors
        "chipIds": # Map of chip Ids found in lane
        {
            "8": "20555586"
        },
        "hitCounts": #Number of hits per event ("Number of hits" : count)
        {
            "0": "20555545",
            "1": "41"
        },
        "flags": #Flags found per event
        {
            "0": "20555586"
        },
        "bunchCounter": #Bunch counters found per event
        {
            "0": "91917",
            "8": "92466"
        },
        "gbtIdLastEvent": "61666783", # GBT packet index of the last event recorded
        "gbtIdLastGoodEvent": "61666783", # GBT packet index of the last good event recorded
        "gbtIdDeltaSum": "61666783", # Sum of GBT packet indices occuring between two events
        "event_error_gbt_ids": "" # List of GBT packet indices where an event had an error
    },
    "Lane_2": ...,
    "GbtStream":
    {
        "sopCount": "116829867", # Number of SOP found in event stream
        "eopCount": "116829867", # Number of EOP found in event stream
        "unknownCount": "0", # Number of unknown packets found in Event Stream
        "byteErrorMap": "" # Number of errors found in a packet header
    }
```
