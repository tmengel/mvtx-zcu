// (c) new-alpide-software
// Git:
// https://gitlab.cern.ch/alice-its-alpide-software/new-alpide-software/blob/master/AlpideDecoder.h
// Hash: 35af2c981a3e99007a1c183736faaff1429e0111
// MBonora modified

#include "AlpideDecoder.h"
#include <stdint.h>

// using namespace AlpideDecoder;
#define ELPP_THREAD_SAFE
#define ELPP_FORCE_USE_STD_THREAD
#include "easylogging++.h"

// Max number of hits before an event is flagged as bad
// (Hit matrix size, factor 10 for catching incorrectly parsed events)
const size_t MAX_HITS_PER_EVENT = 1024 * 512 * 10;



AlpideDecoder::AlpideDecoder(TGetByteFunc getBytesFunc, int laneNr, bool enableLogging) :
    m_getBytes(getBytesFunc), m_laneNr(laneNr), m_enableLogging(enableLogging), m_busyOnCounter(0), m_busyOffCounter(0), newEvent(false) {
  el::Loggers::getLogger(logger());
}

TDataType AlpideDecoder::GetDataType(unsigned char dataWord) {

  if (dataWord == 0xff)
    return DT_IDLE;
  else if (dataWord == 0xf1)
    return DT_BUSYON;
  else if (dataWord == 0xf0)
    return DT_BUSYOFF;
  else if ((dataWord & 0xf0) == 0xa0)
    return DT_CHIPHEADER;
  else if ((dataWord & 0xf0) == 0xb0)
    return DT_CHIPTRAILER;
  else if ((dataWord & 0xf0) == 0xe0)
    return DT_EMPTYFRAME;
  else if ((dataWord & 0xe0) == 0xc0)
    return DT_REGIONHEADER;
  else if ((dataWord & 0xc0) == 0x40)
    return DT_DATASHORT;
  else if ((dataWord & 0xc0) == 0x0)
    return DT_DATALONG;
  else
    return DT_UNKNOWN;
}

void AlpideDecoder::DecodeChipHeader(unsigned char data, int &chipId,
                                     unsigned int &bunchCounter) {
  TByteVector data2 = m_getBytes(1);

  bunchCounter = data2[0] << 3;
  chipId = data & 0xf;
  newEvent = true;
}

void AlpideDecoder::DecodeChipTrailer(unsigned char data, int &flags) {
  flags = data & 0xf;
}

void AlpideDecoder::DecodeRegionHeader(unsigned char data, int &region) {
  region = data & 0x1f;
}

void AlpideDecoder::DecodeEmptyFrame(unsigned char data, int &chipId,
                                     unsigned int &bunchCounter) {
  TByteVector data2 = m_getBytes(1);

  bunchCounter = data2[0] << 3;
  chipId = data & 0xf;
}

void AlpideDecoder::DecodeDataWord(unsigned char data, int chip, int region,
                                   std::vector<TPixHit> &hits, bool datalong,
                                   uint64_t &hitCount) {
  TPixHit hit;
  int address, hitmap_length;

  TByteVector data2 = m_getBytes(1);
  unsigned char hitmap2 = 0;

  int16_t data_field = (((int16_t)data) << 8) + data2[0];

  hit.chipId = chip;
  hit.region = region;
  hit.dcol = (data_field & 0x3c00) >> 10;
  address = (data_field & 0x03ff);

  if (datalong) {
    hitmap_length = 7;
    TByteVector data3 = m_getBytes(1);
    hitmap2 = data3[0];
  } else {
    hitmap_length = 0;
  }

  for (int i = -1; i < hitmap_length; i++) {
    if ((i >= 0) && (!(hitmap2 >> i)) & 0x1)
      continue;
    hit.address = address + (i + 1);
    if(hits.capacity() == hits.size()) {
      CLOG_IF(m_enableLogging, INFO,logger())<< "Lane " << m_laneNr << ": " << "Hits capacity reached: " << hits.capacity();
    }
    hits.push_back(hit);
    ++hitCount;
  }
  newEvent = false;
}

AlpideEvent
AlpideDecoder::DecodeEvent(std::vector<TPixHit> *hits) {
  int region = -1;
  int chip = -1;
  int flags = 0;
  uint64_t hitCount = 0;
  bool started = false;  // event has started, i.e. chip header has been found
  bool finished = false; // event trailer found
  TDataType type;
  static std::vector<unsigned char> bytes;

  unsigned int bunchCounter;
  bool error = false;

  while (!finished) {
    TByteVector data = m_getBytes(1);
    type = GetDataType(data[0]);

    switch (type) {
    case DT_IDLE:
      ++m_idleCounter;
      break;
    case DT_BUSYON:
      ++m_busyOnCounter;
      break;
    case DT_BUSYOFF:
      ++m_busyOffCounter;
      break;
    case DT_EMPTYFRAME:
      started = true;
      DecodeEmptyFrame(data[0], chip, bunchCounter);
      finished = true;
      break;
    case DT_CHIPHEADER:
      started = true;
      DecodeChipHeader(data[0], chip, bunchCounter);
      break;
    case DT_CHIPTRAILER:
      if (!started) {
        CLOG_IF(m_enableLogging, ERROR, logger()) << "Error, chip trailer found before chip header";
        error = true;
      }
      if (finished) {
        CLOG_IF(m_enableLogging, ERROR, logger())
            << "Error, chip trailer found after event was finished";
        error = true;
      }
      DecodeChipTrailer(data[0], flags);
      finished = true;
      break;
    case DT_REGIONHEADER:
      if (!started) {
        CLOG_IF(m_enableLogging, ERROR, logger())
            << "Error, region header found before chip header or after "
               "chip trailer";
        error = true;
      }
      DecodeRegionHeader(data[0], region);
      break;
    case DT_DATASHORT:
      if (!started) {
        CLOG_IF(m_enableLogging, ERROR, logger())
            << "Error, hit data found before chip header or after chip "
            "trailer: " << std::hex << int(data[0]) << std::dec;
        error = true;
      }
      if (hits) {
        DecodeDataWord(data[0], chip, region, *hits, false, hitCount);
      }
      break;
    case DT_DATALONG:
      if (data[0] == 0x0 and !started) {
        // Padding byte
        m_paddingCounter++;
      } else if (!started) {
        CLOG_IF(m_enableLogging, ERROR, logger())
            << "Error, hit data found before chip header or after chip trailer"
            << std::hex << int(data[0]) << std::dec;
        error = true;
      } else {
        if (hits) {
          DecodeDataWord(data[0], chip, region, *hits, true, hitCount);
        }
      }
      break;
    case DT_UNKNOWN:
      CLOG_IF(m_enableLogging, ERROR, logger()) << "Error, data of unknown type 0x" << std::hex
                            << int(data[0]) << std::dec;
      error = true;
    }
    // Check number of hits
    if(hits->size() >= MAX_HITS_PER_EVENT) {
      CLOG_IF(m_enableLogging, ERROR, logger()) << "Error, too many Hits registered on event: " << hits->size()
                            << ", ChipId: " << chip;
      error = true;
    }

    if (error)
      break;
  }
  // std::cout << "Found " << hits.size() - NOldHits << " hits" ;
  if (started && !finished) {
    CLOG_IF(m_enableLogging, WARNING, logger()) << "Warning, event not finished at end of data";
    error = true;
  }
  if (!started && finished) {
    CLOG_IF(m_enableLogging, WARNING, logger()) << "Warning, event not started at end of data";
    error = true;
  }
  AlpideEvent event;

  event.chipId = chip;
  event.bunchCounter = bunchCounter;
  event.flags = flags;
  event.hitCount = hitCount;
  event.error = error;

  chip = -1;

  return event;
}
