import logging
import copy
from collections import OrderedDict, defaultdict
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import struct


class Event:

    def __init__(self):
        self.chipid = None
        self.frame_data_start = None
        self.readout_flags = None
        self.errors = 0
        self.hit_cnt = 0
        self.hits = OrderedDict()
        self.hitlist = []
        self.currentRegion = None
        self.currentPosition = None

    def __str__(self):
        return """
        \tchipid[3:0] \t\t{0:04b}
        \tframe_data_start \t{1:02X}
        \treadout_flags \t\t{2}
        \terrors \t\t\t{3}
        \thit_cnt \t\t{4}
        """.format(self.chipid,
                   self.frame_data_start,
                   self.readout_flags,
                   self.errors,
                   self.hit_cnt)


class EventDecoder:
    # const logic [6:0] SINGLE_HIT = 7'b1000000
    CHIP_COMMA = 0B10111100  # BC
    CHIP_IDLE = 0B11111111  # FF
    CHIP_BUSY_ON = 0B11110001  # F1
    CHIP_BUSY_OFF = 0B11110000  # F0
    CHIP_HEADER = 0B1010  # A
    CHIP_TRAILER = 0B1011  # B
    CHIP_EMPTY_FRAME = 0B1110  # E
    CHIP_REGION = 0B110  # C / D
    CHIP_DATA_SHORT = 0B01  # 40 - 79
    CHIP_DATA_LONG = 0B00  # 0 - 39
    PADDING_GBTX = 0x00

    def __init__(self):
        self.event = None
        self.error_event = None
        self.events = []
        self.state = "idle"
        self.errors = 0
        self.padding = 0
        self.idleCount = 0
        self.logger = logging.getLogger("events")
        self.max_errors = None
        self.max_errors_reached = False

    def _error(self, msg, gotoErrorState=True):
        """Process an error"""
        self.logger.error(msg)
        if gotoErrorState:
            self.state = "error"
        else:
            self.errors += 1

    def set_max_errors(self, max_errors):
        """Set a maximum of errors before decoder stops processing"""
        self.max_errors = max_errors

    def print_events(self, number):
        for i, event in enumerate(self.events):
            if i <= number:
                print("event {0}".format(i))
                print(event)
            else:
                break

    def get_eventcount_map(self):
        """Return a Event count per chipid"""
        event_map = defaultdict(int)
        for event in self.events:
            event_map[event.chipid] += 1
        return event_map

    def process(self, data):
        """Process a single byte of the protocol. Skip if max errors is reached"""

        if self.max_errors and self.errors > self.max_errors:
            if not self.max_errors_reached:
                self.max_errors_reached = True
                self.logger.error(
                    "Decoding aborted for too many errors: {0}".format(self.errors))
            return False
        self.logger.debug("Process byte: %#02X, state: %s", data, self.state)
        betweenWords = False
        if (self.state == "header" or
            self.state == "datashort" or
            self.state == "datalong" or
            self.state == "datalong2" or
                self.state == "emptyframe"):
            betweenWords = True

        if data == self.CHIP_IDLE and not betweenWords:
            if self.state == 'trailer' or self.state == 'emptyframe2':
                self.state = 'idle'
        elif data == self.PADDING_GBTX and (self.state == 'idle' or self.state == 'trailer' or self.state == 'emptyframe2'):
            self.padding += 1
            self.logger.debug("Ignore padding 0 byte")
        elif data == self.CHIP_BUSY_ON and not betweenWords:
            self.logger.warning("BUSY on received")
        elif data == self.CHIP_BUSY_OFF and not betweenWords:
            self.logger.warning("BUSY off received")
        else:
            if self.state == "idle" or self.state == "trailer" or self.state == "emptyframe2":
                self.state = "idle"
                if data >> 4 == self.CHIP_HEADER:
                    self.state = "header"
                elif data >> 4 == self.CHIP_EMPTY_FRAME:
                    self.state = "emptyframe"
                else:
                    self._error("Unexpected Transition " +
                                "from idle, expected chip header or empty frame, got {0:02X}".format(data), False)
            elif self.state == "header":
                self.state = "header2"
            elif self.state == "header2":
                if data >> 5 == self.CHIP_REGION:
                    self.state = "region"
                elif data >> 4 == self.CHIP_TRAILER:
                    self.state = "trailer"
                else:
                    self._error(
                        "Unexpected Transition from Header, expected Region, got {0:02X}".format(data))
            elif self.state == "region":
                if data >> 6 == self.CHIP_DATA_SHORT:
                    self.state = "datashort"
                elif data >> 6 == self.CHIP_DATA_LONG:
                    self.state = "datalong"
                else:
                    self._error(
                        "Wrong format for data word, expected DataShort or DataLong, got {0:02X}".format(data))
            elif self.state == "datashort":
                self.state = "datashort2"
            elif self.state == "datashort2":
                if data >> 6 == self.CHIP_DATA_SHORT:
                    self.state = "datashort"
                elif data >> 6 == self.CHIP_DATA_LONG:
                    self.state = "datalong"
                elif data >> 5 == self.CHIP_REGION:
                    self.state = "region"
                elif data >> 4 == self.CHIP_TRAILER:
                    self.state = "trailer"
                else:
                    self._error("Data short2, unexpected data word." +
                                " Expect Trailer, Region, DataShort, got {0:02X}".format(data))

            elif self.state == "datalong":
                self.state = "datalong2"
            elif self.state == "datalong2":
                self.state = "datalong3"
            elif self.state == "datalong3":
                if data >> 6 == self.CHIP_DATA_SHORT:
                    self.state = "datashort"
                elif data >> 6 == self.CHIP_DATA_LONG:
                    self.state = "datalong"
                elif data >> 5 == self.CHIP_REGION:
                    self.state = "region"
                elif data >> 4 == self.CHIP_TRAILER:
                    self.state = "trailer"
                else:
                    self._error("Data short2, unexpected data word." +
                                " Expect Trailer, Region, DataShort, got {0:02X}".format(data))
            elif self.state == "emptyframe":
                self.state = "emptyframe2"
            elif self.state == "error":
                if data >> 4 == self.CHIP_HEADER:
                    self.state = "header"
                elif data >> 4 == self.CHIP_EMPTY_FRAME:
                    self.state = "emptyframe"

            last_event = self.event
            # State actions
            if self.state == "idle":
                pass
            elif self.state == "header":
                self.event = Event()
                self.event.chipid = data & 0xF
                last_event = self.event
            elif self.state == "header2":
                self.event.frame_data_start = data
            elif self.state == "region":
                self.event.currentRegion = data & 0x1F
            elif self.state == "datashort" or self.state == "datalong":
                self.event.currentPosition = (data & 0x3F) << 8
            elif self.state == "datashort2":
                self.event.currentPosition |= data
                self.event.hits[
                    (self.event.currentRegion, self.event.currentPosition)] = 0
                self.event.hitlist.extend(self.hit2xy(
                    self.event.currentRegion, self.event.currentPosition, 0))
                self.event.hit_cnt += 1
            elif self.state == "datalong2":
                self.event.currentPosition |= data
            elif self.state == "datalong3":
                d = data & 0x7F
                self.event.hits[
                    (self.event.currentRegion, self.event.currentPosition)] = d
                self.event.hitlist.extend(self.hit2xy(
                    self.event.currentRegion, self.event.currentPosition, d))
                self.event.hit_cnt += bin(d).count("1") + 1
            elif self.state == "trailer":
                self.event.readout_flags = data & 0xF

                self.logger.info(
                    "Chip event registered with {0:02X} hits, {1} errors".format(
                        self.event.hit_cnt, self.event.errors))
                self.events.append(copy.copy(self.event))
                self.event = None

            elif self.state == "emptyframe":
                self.event = Event()
                self.event.chipid = data & 0xF
                last_event = self.event
            elif self.state == "emptyframe2":
                self.event.frame_data_start = data

                self.logger.info(
                    "Chip Empty event registered with %d hits, %d errors", self.event.hit_cnt, self.event.errors)
                self.events.append(copy.copy(self.event))
                self.event = None
            elif self.state == "error":
                self.logger.debug("Error state, byte: %#02X", data)
                self.errors += 1
                if self.error_event is not None:
                    self.error_event.errors += 1
                elif self.event is not None:
                    self.event.errors += 1
                    self.logger.info(
                        "Incomplete Event registered with %d hits, %d errors", self.event.hit_cnt,
                        self.event.errors)
                    self.events.append(copy.copy(self.event))
                    self.error_event = self.event
                    self.event = None
        return True

    def hit2xy(self, region, current_pos, hitmap):
        assert region | 0x1F == 0x1F
        assert current_pos | 0x3FFF == 0x3FFF
        assert hitmap | 0x7F == 0x7F

        enc_id = current_pos >> 10 & 0xF
        address = current_pos & 0x3FF
        y = address >> 1
        pe_subcol = 0
        if address % 4 in [1, 2]:
            pe_subcol = 1
        x = region << 5 | enc_id << 1 | pe_subcol
        coordinates = []
        coordinates.append((x, y))
        # print("Region {0:02d}, pos {1:05d}, index N is at Pos X: {2}, Y:
        # {3}".format(region,current_pos,x,y))
        if hitmap != 0:
            for i in range(0, 7):
                bit = hitmap >> i & 1
                if bit:
                    pixel_address = address + 1 + i
                    pe_subcol = 0
                    if pixel_address % 4 in [1, 2]:
                        pe_subcol = 1
                    y = pixel_address >> 1
                    x = region << 5 | enc_id << 1 | pe_subcol
                    coordinates.append((x, y))
                    # print("Region {0:02d}, pos {1:05d}, index {4} is at Pos
                    # X: {2}, Y: {3}".format(region,current_pos,x,y,i))
        return coordinates


class EventPlotter(object):

    def __init__(self):
        pass

    def plot(self, coordinates_list):
        xlist, ylist = zip(*coordinates_list)
        plt.scatter(xlist, ylist)
        plt.axis([0, 1023, 512, 0])
        plt.show()

    def heatmap_events(self, event_list):
        all_coordinates = []
        for event in event_list:
            all_coordinates.extend(event.hitlist)
        self.heatmap(all_coordinates)

    def heatmap_encoder(self, address_list):
        rows = 512
        cols = 1024
        hit_map = np.zeros((rows, cols), dtype=np.uint)
        for region, enc_id, address, hitcnt in address_list:
            y = address >> 1
            pe_subcol = 0
            if address % 4 in [1, 2]:
                pe_subcol = 1
            x = region << 5 | enc_id << 1 | pe_subcol
            hit_map[y][x] = hitcnt
        self.plot_heatmap(hit_map)

    def plot_heatmap(self, hit_matrix, max_events=None):

        if max_events is None:
            max_events = 0
            for row in hit_matrix:
                for col in row:
                    max_events = max(max_events, col)

        fig = plt.figure(figsize=(18, 9))

        ax = fig.add_subplot(111)
        ax.set_title('Hit list')
        plt.imshow(hit_matrix, vmin=0, vmax=max_events,
                   interpolation='none', cmap=mpl.cm.Reds)
        ax.set_aspect('equal')

#        cax.get_xaxis().set_visible(False)
#        cax.get_yaxis().set_visible(False)
#        cax.patch.set_alpha(0)
#        cax.set_frame_on(False)

        cbar = plt.colorbar(orientation='vertical', norm=mpl.colors.Normalize(vmin=0,
                                                                              vmax=max_events))
        cbar.set_clim(0, max_events)
        plt.show()

    def heatmap(self, coordinates_list, max_events=None):
        rows = 512
        cols = 1024
        hit_map = np.zeros((rows, cols), dtype=np.uint)
        for x, y in coordinates_list:
            hit_map[y][x] += 1
        self.plot_heatmap(hit_map)


class GbtEvent(object):
    """Single GBT Event packet"""

    def __init__(self):
        self.header_version = None
        self.header_size = None
        self.block_length = None
        self.fee_id = None
        self.priority_bit = None
        self.trigger_orbit = None
        self.hb_orbit = None
        self.trigger_bc = None
        self.hb_bc = None
        self.trigger_type = None
        self.pages_counter = None
        self.stop_bit = None
        self.par = None
        self.detector_field = None

        self.packet_index2 = None
        self.active_lanes = None

        self.packet_status_raw = None
        self.packet_status = None
        self.lane_timeouts = None
        self.lane_stops = None

        self.word_count = None
        self.checksum = None

        self.events = OrderedDict()

        self.error_words = 0

    def set_packet_status(self,packet_status):
        self.packet_status_raw = packet_status
        self.packet_status = {}
        self.packet_status['lane_timeouts'] = bool(packet_status & (1<<4))
        self.packet_status['lane_starts_violation'] = bool(packet_status & (1<<3))
        self.packet_status['max_packets_reached'] = bool(packet_status & (1<<2))
        self.packet_status['transmission_timeout'] = bool(packet_status & (1<<1))
        self.packet_status['packet_done'] = bool(packet_status & (1<<0))

def _hexify_word(data):
    return ' '.join(format(x, '02x') for x in data)


class GbtEventDecoder(object):
    """Decodes GBT Events"""

    SOP_ID = 0x10
    EOP_ID = 0x20
    HEADER_ID = 0xE0
    TRAILER_ID = 0xF0

    def __init__(self):
        self.events = []
        self.logger = logging.getLogger("GbtEventDecoder")
        self.results = []
        self.decoders = OrderedDict()

        self.error_words = 0

    def finalise_event(self, event):
        for channel, decoder in self.decoders.items():
            event.events[channel] = decoder.events
            decoder.events = []
        for channel, events in event.events:
            if len(events) != 1:
                self.logger.warning("Expected 1 Event in Channel {0}, but got {1}".format(channel,len(events)))

    def fill_sop(self, event, sop):
        self.logger.debug("SOP: {0} {1}"
                          .format(sop[0], _hexify_word(sop[1])))
        has_error = False
        if(sop[0] != 0):
            self.logger.warning("Expected SOP, but DV!= 0")
            has_error = True
        if(sop[1][0] != SOP_ID):
            self.logger.warning("Expected SOP, but No SOP identifier: {0}".format(sop[1][0]))
            has_error = True

        if any([data != 0 for data in sop[1][1:]]):
            self.logger.warning("SOP word has illegal words set: {0}".format(sop[1][1:]))
            has_error = True
        if has_error:
            event.error_words += 1

    def fill_cdr0(self, event, cdr0):
        self.logger.debug("CDR0: {0} {1}".format(
            cdr0[0], _hexify_word(cdr0[1])))
        has_error = False
        if(cdr0[0] != 1):
            self.logger.warning("Expected CDR0, but DV!= 1")
            has_error = True

        values = struct.unpack('>HBB>H>HBB',cdr0)
        event.header_version = values[6]
        event.header_size = values[5]
        event.block_length = values[4]
        event.fee_id = values[3]
        event.priority_bit = values[2]

        if values[0] != 0 or values[1] != 0:
            self.logger.warning("CDR0, incorrect values for 0 padding: {0}, {1}".format(values[0], values[1]))

        if has_error:
            event.error_words += 1


    def fill_cdr1(self, event, cdr1):
        self.logger.debug("CDR1: {0} {1}".format(
            cdr1[0], _hexify_word(cdr1[1])))
        has_error = False
        if(cdr1[0] != 1):
            self.logger.warning("Expected CDR1, but DV!= 1")
            has_error = True

        values = struct.unpack('>H>I>I',cdr1)
        event.hb_orbit = values[1]
        event.trigger_orbit = values[2]

        if values[0] != 0:
            self.logger.warning("CDR2, incorrect values for 0 padding: {0}".format(values[0]))


        if has_error:
            event.error_words += 1

    def fill_cdr2(self, event, cdr2):
        self.logger.debug("CDR2: {0} {1}".format(
            cdr2[0], _hexify_word(cdr2[1])))
        has_error = False
        if(cdr2[0] != 1):
            self.logger.warning("Expected CDR2, but DV!= 1")
            has_error = True

        values = struct.unpack('>H>I>H>H',cdr2)
        event.trigger_type = values[1]
        event.hb_bc = values[2]
        event.trigger_bc = values[3]

        if values[0] != 0:
            self.logger.warning("CDR2, incorrect values for 0 padding: {0}".format(values[0]))

        if has_error:
            event.error_words += 1

    def fill_cdr3(self, event, cdr3):
        self.logger.debug("CDR3: {0} {1}".format(
            cdr3[0], _hexify_word(cdr3[1])))
        has_error = False
        if(cdr3[0] != 1):
            self.logger.warning("Expected CDR3, but DV!= 1")
            has_error = True

        values = struct.unpack('>HB>HB>H>H',cdr3)
        event.pages_counter = values[2]
        events.stop_bit = values[3]
        events.par = values[4]
        event.detector_field = values[5]

        if values[0] != 0 or values[1] != 0:
            self.logger.warning("CDR3, incorrect values for 0 padding: {0}, {1}".format(values[0], values[1]))

        if has_error:
            event.error_words += 1

    def fill_header(self, event, header):
        self.logger.debug("HEADER: {0} {1}".format(
            header[0], _hexify_word(header[1])))
        has_error = False
        if(header[0] != 1):
            self.logger.warning("Expected HEADER, but DV!= 1")
            has_error = True

        values = struct.unpack('B>HB>I>H',header)
        if(values[0] != HEADER_ID):
            self.logger.warning("Expected SOP, but No SOP identifier: {0}".format(sop[1][0]))
            has_error = True

        event.active_lanes = values[3]
        event.packet_index2= values[4]

        if values[1] != 0 or values[2] != 0:
            self.logger.warning("HEADER, incorrect values for 0 padding: {0}, {1}".format(values[1], values[2]))

        if has_error:
            event.error_words += 1

    def fill_trailer(self, event, trailer):
        self.logger.debug("TRAILER: {0} {1}".format(
            trailer[0], _hexify_word(trailer[1])))
        has_error = False
        if(trailer[0] != 1):
            self.logger.warning("Expected TRAILER, but DV!= 1")
            has_error = True

        values = struct.unpack('BB>I>I',header)
        if(values[0] != HEADER_ID):
            self.logger.warning("Expected SOP, but No SOP identifier: {0}".format(sop[1][0]))
            has_error = True

        event.set_packet_status(values[1])
        event.lane_timeouts = values[2]
        event.lane_stops    = values[3]

        if has_error:
            event.error_words += 1

    def fill_eop(self, event, eop):
        self.logger.debug("EOP: {0} {1}".format(eop[0], _hexify_word(eop[1])))
        has_error = False
        if(eop[0] != 0):
            self.logger.warning("Expected EOP, but DV!= 0")
            has_error = True
        values = struct.unpack('B>IB>H>H',header)
        if(values[0] != EOP_ID):
            self.logger.warning("Expected EOP, but No EOP identifier: {0}".format(eop[1][0]))
            has_error = True

        event.checksum = values[3]
        event.word_count = values[4]

        if values[1] != 0 or values[2] != 0:
            self.logger.warning("EOP, incorrect values for 0 padding: {0}, {1}".format(values[1], values[2]))

        if has_error:
            event.error_words += 1

    def process_event_start(self, readout_board, event):
        # Start of Event data
        if len(self.results) < 6:
            self.results = self.results + \
                readout_board.read_gbtx_data_from_usb(6 - len(self.results))
        if len(self.results) < 6:
            msg = "Out of event data: Received {0}/6 GBT words".format(
                len(results))
            logger.error(msg)
            raise RuntimeError(msg)

        self.fill_sop(event, results[0])
        self.fill_cdr0(event, results[1])
        self.fill_cdr1(event, results[2])
        self.fill_cdr2(event, results[3])
        self.fill_cdr3(event, results[4])
        self.fill_header(event, results[5])

    def process_event_data(self, readout_board):
        # Read Event data
        self.results = self.results[6:]
        event_done = False
        while not event_done:
            # load next word
            if not self.results:
                self.results = readout_board.read_gbtx_data_from_usb(1)
            if len(self.results) < 1:
                msg = "Out of event data: Received {0}/1 GBT words".format(
                    len(results))
                logger.error(msg)
                raise RuntimeError(msg)

            while self.results:
                datavalid, data = self.results.pop(0)
                if datavalid:
                    channel = data[0]
                    if channel == 0xF0:
                        event_done = True
                        self.results.insert(0, (datavalid, data))
                        break

                    if not channel in self.decoders:
                        self.decoders[channel] = EventDecoder()
                    payload = data[1:][::-1]
                    self.logger.debug("DATA CH{0}: {1}"
                                      .format(channel, ' '.join(format(x, '02x') for x in payload)))
                    for d in payload:
                        decoders[channel].process(d)

    def process_event_end(self, readout_board, event):
        # End of Event data
        trailer = self.results.pop(0)
        if not self.results:
            self.results = readout_board.read_gbtx_data_from_usb(1)
        if len(self.results) < 1:
            msg = "Out of event data: Received {0}/1 GBT words".format(
                len(results))
            logger.error(msg)
            raise RuntimeError(msg)

        eop = self.results.pop(0)

        event.fill_trailer(trailer)
        event.fill_eop(eop)

    def processEvent(self, readout_board):
        event = GbtEvent()

        self.process_event_start(readout_board, event)
        self.process_event_data(readout_board)
        self.process_event_end(readout_board, event)

        if event.packet_status['packet_done']:
            self.finalise_event(event)

        self.error_words += event.error_words

        return event

class GbtEvent(object):
    """Single GBT Event packet"""

    def __init__(self):
        self.header_version = None
        self.header_size = None
        self.block_length = None
        self.fee_id = None
        self.priority_bit = None
        self.trigger_orbit = None
        self.hb_orbit = None
        self.trigger_bc = None
        self.hb_bc = None
        self.trigger_type = None
        self.pages_counter = None
        self.stop_bit = None
        self.par = None
        self.detector_field = None

        self.packet_index2 = None
        self.active_lanes = None

        self.packet_status_raw = None
        self.packet_status = None
        self.lane_timeouts = None
        self.lane_stops = None

        self.word_count = None
        self.checksum = None

        self.events = OrderedDict()

        self.error_words = 0
        self.raw_data = []

    def print_event(self):
        msg = "GBT Event Version {0:#X}, Header Size {1}\n".format(self.header_version,self.header_size)
        msg += "    Block length: {0}, FEE ID: {1:#X}, Priority: {2:#X}\n".format(self.block_length,self.fee_id,self.priority_bit)
        msg += "    PAR: {0:X}, Detector field: {1:X}\n".format(self.par,self.detector_field)
        msg += "    Heartbeat - Orbit: {0:#X}, BC: {1:#X}\n".format(self.hb_orbit,self.hb_bc)
        msg += "    Trigger   - Orbit: {0:#X}, BC: {1:#X}\n".format(self.trigger_orbit,self.trigger_bc)
        msg += "    Trigger Type: {0:#X}\n".format(self.trigger_type)
        msg += "    Pages Counter: {0}, Stop Bit: {1}\n".format(self.pages_counter,self.stop_bit)
        msg += "  Header - Packet Index: {0}, Active Lanes: {1:028b}\n".format(self.packet_index2,self.active_lanes)

        event_count = 0
        error_count = 0
        hit_count = 0
        for lane,ev in self.events.items():
            event_count += len(ev)
            error_count += sum([e.errors for e in ev])
            hit_count += sum([e.hit_cnt for e in ev])

        msg += "  Events: {0}, Hits: {1}, Errors: {2}\n".format(event_count,hit_count,error_count)
        msg += "  Trailer - Status: {0:05b}\n    Lane Timeouts: {1:028b}\n    Lane Stops: {2:028b}\n".format(self.packet_status_raw,self.lane_timeouts,self.lane_stops)
        msg += "    " + "\n    ".join(["{0}: {1}".format(word,val) for word,val in self.packet_status.items()])

        print(msg)

    def set_packet_status(self,packet_status):
        self.packet_status_raw = packet_status
        self.packet_status = OrderedDict()
        self.packet_status['lane_timeouts'] = bool(packet_status & (1<<4))
        self.packet_status['lane_starts_violation'] = bool(packet_status & (1<<3))
        self.packet_status['max_packets_reached'] = bool(packet_status & (1<<2))
        self.packet_status['transmission_timeout'] = bool(packet_status & (1<<1))
        self.packet_status['packet_done'] = bool(packet_status & (1<<0))

def _hexify_word(data):
    return ' '.join(format(x, '02x') for x in data)

class GbtEventDecoder(object):
    """Decodes GBT Events"""

    SOP_ID = 0x10
    EOP_ID = 0x20
    HEADER_ID = 0xE0
    TRAILER_ID = 0xF0

    def __init__(self):
        self.events = []
        self.logger = logging.getLogger("GbtEventDecoder")
        self.results = []
        self.decoders = OrderedDict()

        self.error_words = 0

    def finalise_event(self, event):
        for channel, decoder in self.decoders.items():
            event.events[channel] = decoder.events
            decoder.events = []
        bunch_counters = set()
        for channel, eventlist in event.events.items():
            if len(eventlist) != 1:
                self.logger.warning("Expected 1 Event in Channel {0}, but got {1}".format(channel,len(eventlist)))
            for ev in eventlist:
                bunch_counters.add(ev.frame_data_start)
        if len(bunch_counters) > 1:
            self.logger.warning("Multiple bunch counters registered: %r",bunch_counters)

    def fill_sop(self, event, sop):
        self.logger.debug("SOP: {0} {1}"
                          .format(sop[0], _hexify_word(sop[1])))
        has_error = False
        if(sop[0] != 0):
            self.logger.warning("Expected SOP, but DV!= 0")
            has_error = True
        if(sop[1][0] != self.SOP_ID):
            self.logger.warning("Expected SOP, but No SOP identifier: {0}".format(sop[1][0]))
            has_error = True

        if any([data != 0 for data in sop[1][1:]]):
            self.logger.warning("SOP word has illegal words set: {0}".format(sop[1][1:]))
            has_error = True
        if has_error:
            event.error_words += 1

    def fill_cdr0(self, event, cdr0):
        self.logger.debug("CDR0: {0} {1}".format(
            cdr0[0], _hexify_word(cdr0[1])))
        has_error = False
        if(cdr0[0] != 1):
            self.logger.warning("Expected CDR0, but DV!= 1")
            has_error = True

        values = struct.unpack('>HBBHHBB',cdr0[1])
        event.header_version = values[6]
        event.header_size = values[5]
        event.block_length = values[4]
        event.fee_id = values[3]
        event.priority_bit = values[2]

        if values[0] != 0 or values[1] != 0:
            self.logger.warning("CDR0, incorrect values for 0 padding: {0}, {1}".format(values[0], values[1]))

        if has_error:
            event.error_words += 1

    def fill_cdr1(self, event, cdr1):
        self.logger.debug("CDR1: {0} {1}".format(
            cdr1[0], _hexify_word(cdr1[1])))
        has_error = False
        if(cdr1[0] != 1):
            self.logger.warning("Expected CDR1, but DV!= 1")
            has_error = True

        values = struct.unpack('>HII',cdr1[1])
        event.hb_orbit = values[1]
        event.trigger_orbit = values[2]

        if values[0] != 0:
            self.logger.warning("CDR2, incorrect values for 0 padding: {0}".format(values[0]))


        if has_error:
            event.error_words += 1

    def fill_cdr2(self, event, cdr2):
        self.logger.debug("CDR2: {0} {1}".format(
            cdr2[0], _hexify_word(cdr2[1])))
        has_error = False
        if(cdr2[0] != 1):
            self.logger.warning("Expected CDR2, but DV!= 1")
            has_error = True

        values = struct.unpack('>HIHH',cdr2[1])
        event.trigger_type = values[1]
        event.hb_bc = values[2]
        event.trigger_bc = values[3]

        if values[0] != 0:
            self.logger.warning("CDR2, incorrect values for 0 padding: {0}".format(values[0]))

        if has_error:
            event.error_words += 1

    def fill_cdr3(self, event, cdr3):
        self.logger.debug("CDR3: {0} {1}".format(
            cdr3[0], _hexify_word(cdr3[1])))
        has_error = False
        if(cdr3[0] != 1):
            self.logger.warning("Expected CDR3, but DV!= 1")
            has_error = True

        values = struct.unpack('>HBHBHH',cdr3[1])
        event.pages_counter = values[2]
        event.stop_bit = values[3]
        event.par = values[4]
        event.detector_field = values[5]

        if values[0] != 0 or values[1] != 0:
            self.logger.warning("CDR3, incorrect values for 0 padding: {0}, {1}".format(values[0], values[1]))

        if has_error:
            event.error_words += 1

    def fill_header(self, event, header):
        self.logger.debug("HEADER: {0} {1}".format(
            header[0], _hexify_word(header[1])))
        has_error = False
        if(header[0] != 1):
            self.logger.warning("Expected HEADER, but DV!= 1")
            has_error = True

        values = struct.unpack('>BHBIH',header[1])
        if(values[0] != self.HEADER_ID):
            self.logger.warning("Expected HEADER, but No HEADER identifier: {0}".format(header[1][0]))
            has_error = True

        event.active_lanes = values[3]
        event.packet_index2= values[4]

        if values[1] != 0 or values[2] != 0:
            self.logger.warning("HEADER, incorrect values for 0 padding: {0}, {1}".format(values[1], values[2]))

        if has_error:
            event.error_words += 1

    def fill_trailer(self, event, trailer):
        self.logger.debug("TRAILER: {0} {1}".format(
            trailer[0], _hexify_word(trailer[1])))
        has_error = False
        if(trailer[0] != 1):
            self.logger.warning("Expected TRAILER, but DV!= 1")
            has_error = True

        values = struct.unpack('>BBII',trailer[1])
        if(values[0] != self.TRAILER_ID):
            self.logger.warning("Expected SOP, but No SOP identifier: {0}".format(sop[1][0]))
            has_error = True

        event.set_packet_status(values[1])
        event.lane_timeouts = values[2]
        event.lane_stops    = values[3]

        if has_error:
            event.error_words += 1

    def fill_eop(self, event, eop):
        self.logger.debug("EOP: {0} {1}".format(eop[0], _hexify_word(eop[1])))
        has_error = False
        if(eop[0] != 0):
            self.logger.warning("Expected EOP, but DV!= 0")
            has_error = True
        values = struct.unpack('>BIBHH',eop[1])
        if(values[0] != self.EOP_ID):
            self.logger.warning("Expected EOP, but No EOP identifier: {0}".format(eop[1][0]))
            has_error = True

        event.checksum = values[3]
        event.word_count = values[4]

        if values[1] != 0 or values[2] != 0:
            self.logger.warning("EOP, incorrect values for 0 padding: {0}, {1}".format(values[1], values[2]))

        if has_error:
            event.error_words += 1

    def process_event_start(self, readout_board, event):
        # Start of Event data
        if len(self.results) < 6:
            self.results = self.results + \
                readout_board.read_gbtx_data_from_usb(6 - len(self.results))
        if len(self.results) < 6:
            msg = "Out of event data: Received {0}/6 GBT words".format(
                len(self.results))
            self.logger.error(msg)
            raise RuntimeError(msg)

        self.fill_sop(event, self.results[0])
        self.fill_cdr0(event, self.results[1])
        self.fill_cdr1(event, self.results[2])
        self.fill_cdr2(event, self.results[3])
        self.fill_cdr3(event, self.results[4])
        self.fill_header(event, self.results[5])

        event.raw_data.extend(self.results[0:6])

    def process_event_data(self, readout_board,event):
        # Read Event data
        self.results = self.results[6:]
        event_done = False
        while not event_done:
            # load next word
            if not self.results:
                self.results = readout_board.read_gbtx_data_from_usb(1)
            if len(self.results) < 1:
                msg = "Out of event data: Received {0}/1 GBT words".format(
                    len(results))
                logger.error(msg)
                raise RuntimeError(msg)

            while self.results:
                datavalid, data = self.results.pop(0)
                event.raw_data.append( (datavalid,data) )
                if datavalid:
                    channel = data[0]
                    if channel == 0xF0:
                        event_done = True
                        self.results.insert(0, (datavalid, data))
                        break

                    if not channel in self.decoders:
                        self.decoders[channel] = EventDecoder()
                    payload = data[1:][::-1]
                    self.logger.debug("DATA CH{0}: {1}"
                                      .format(channel, ' '.join(format(x, '02x') for x in payload)))
                    for d in payload:
                        self.decoders[channel].process(d)

    def process_event_end(self, readout_board, event):
        # End of Event data
        trailer = self.results.pop(0)
        if not self.results:
            self.results = readout_board.read_gbtx_data_from_usb(1)
        if len(self.results) < 1:
            msg = "Out of event data: Received {0}/1 GBT words".format(
                len(results))
            logger.error(msg)
            raise RuntimeError(msg)

        eop = self.results.pop(0)

        self.fill_trailer(event,trailer)
        self.fill_eop(event,eop)

        event.raw_data.append(eop)

    def processEvent(self, readout_board):
        event = GbtEvent()

        self.process_event_start(readout_board, event)
        self.process_event_data(readout_board,event)
        self.process_event_end(readout_board, event)

        if event.packet_status['packet_done']:
            self.finalise_event(event)

        self.error_words += event.error_words

        return event


def check_event_readout(cru, nr_events, nr_triggers, lanes,
                        verbose=False, raw_data_file=None):
    logger = logging.getLogger("events")
    logger.setLevel(logging.INFO)
    MAX_NR_TRIES = 100
    nr_tries = 0
    decoder_range = [i + 1 for i in lanes]
    decoders = {i: EventDecoder() for i in decoder_range}

    events_received = 0

    if verbose:
        logger.setLevel(logging.INFO)

    for dec in decoders.values():
        if verbose:
            dec.logger.setLevel(logging.INFO)
        else:
            dec.logger.setLevel(logging.WARNING)

    data_dump = []
    results = []
    while events_received < nr_triggers and nr_tries < MAX_NR_TRIES:
        if len(results) < 6:
            results = results + cru.read_gbtx_data_from_usb(6 - len(results))
        if len(results) < 6:
            logger.error(
                "Out of event data: Received %d/6 GBT words", len(results))
            break
        sop = results[0]
        cdr0 = results[1]
        cdr1 = results[2]
        cdr2 = results[3]
        cdr3 = results[4]
        header = results[5]
        if verbose:
            logger.info("SOP: {0} {1}"
                        .format(sop[0], ' '.join(format(x, '02x') for x in sop[1])))
            logger.info("CDR0: {0} {1}"
                        .format(cdr0[0], ' '.join(format(x, '02x') for x in cdr0[1])))
            logger.info("CDR1: {0} {1}"
                        .format(cdr1[0], ' '.join(format(x, '02x') for x in cdr1[1])))
            logger.info("CDR2: {0} {1}"
                        .format(cdr2[0], ' '.join(format(x, '02x') for x in cdr2[1])))
            logger.info("CDR3: {0} {1}"
                        .format(cdr3[0], ' '.join(format(x, '02x') for x in cdr3[1])))
            logger.info("HEADER: {0} {1}"
                        .format(header[0], ' '.join(format(x, '02x') for x in header[1])))
        # data
        results = results[6:]
        event_done = False
        while not event_done:
            # load next word
            if not results:
                results = cru.read_gbtx_data_from_usb(1)
            while results:
                datavalid, data = results.pop(0)
                if datavalid:
                    channel = data[0]
                    if channel == 0xF0:
                        event_done = True
                        results.insert(0, (datavalid, data))
                        break
                    if channel in decoder_range:
                        payload = data[1:][::-1]
                        if verbose:
                            logger.info("DATA CH{0}: {1}"
                                        .format(channel, ' '.join(format(x, '02x') for x in payload)))
                        for d in payload:
                            decoders[channel].process(d)
                    else:
                        logger.error(
                            "Channel {0} not in decoder list. Word: {1}".format(channel, data))
        trailer = results.pop(0)
        if verbose:
            logger.info("TRAILER: {0} {1}"
                        .format(trailer[0], ' '.join(format(x, '02x') for x in trailer[1])))
        if not results:
            results = cru.read_gbtx_data_from_usb(1)
        eop = results.pop(0)
        if verbose:
            logger.info("EOP: {0} {1}"
                        .format(eop[0], ' '.join(format(x, '02x') for x in eop[1])))

        events_received += 1

    total_events = 0
    total_errors = 0
    for ch, dec in decoders.items():
        total_events += len(dec.events)
        total_errors += dec.errors
        for chid, eventcount in dec.get_eventcount_map().items():
            if eventcount != nr_events:
                logger.error("Channel {0:d}, chipid {1:x}, Event mismatch: Received {2:d}/{3:d}"
                             .format(ch, chid, eventcount, nr_triggers))
            else:
                logger.info(
                    "Channel {0:d}, chipid {1:x}. All events registered".format(ch, chid))
            if dec.errors != 0:
                logger.error(
                    "Channel {0:d}, Event errors registered: {1:d}".format(ch, dec.errors))

    return total_events, total_errors
