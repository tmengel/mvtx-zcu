// (c) new-alpide-software
// Git:
// https://gitlab.cern.ch/alice-its-alpide-software/new-alpide-software/blob/master/AlpideDecoder.h
// Hash: 35af2c981a3e99007a1c183736faaff1429e0111
#ifndef ALPIDEDECODER_H
#define ALPIDEDECODER_H

#include <cstdint>
#include <vector>
#include <functional>
#include <memory>

enum TDataType {
  DT_IDLE,
  DT_CHIPHEADER,
  DT_CHIPTRAILER,
  DT_EMPTYFRAME,
  DT_REGIONHEADER,
  DT_DATASHORT,
  DT_DATALONG,
  DT_BUSYON,
  DT_BUSYOFF,
  DT_UNKNOWN
};

typedef struct {
  int chipId;
  int region;
  int dcol;
  int address;
} TPixHit;

struct AlpideEvent {
  int chipId;
  int bunchCounter;
  int flags;
  int hitCount;
  bool error;
  size_t gbtPacketId;
  size_t gbtPacketCounter;
};

class AlpideDecoder {
public:
  typedef unsigned char const *TByteVector;
  typedef std::function<TByteVector(size_t)> TGetByteFunc;

private:
  TDataType GetDataType(unsigned char dataWord);
  void DecodeChipHeader(unsigned char data, int &chipId,
                        unsigned int &bunchCounter);
  void DecodeChipTrailer(unsigned char data, int &flags);
  void DecodeRegionHeader(unsigned char data, int &region);
  void DecodeEmptyFrame(unsigned char data, int &chipId,
                        unsigned int &bunchCounter);
  void DecodeDataWord(unsigned char data, int chip, int region,
                      std::vector<TPixHit> &hits, bool datalong,
                      uint64_t &hitCount);
  static constexpr char const *logger() { return "AlpideDecoder"; }

  TGetByteFunc m_getBytes;
  size_t m_laneNr;
  bool m_enableLogging;
  size_t m_busyOnCounter;
  size_t m_busyOffCounter;
  bool newEvent;
  size_t m_paddingCounter;
  size_t m_idleCounter;

protected:
public:
  AlpideDecoder(TGetByteFunc getBytesFunc, int laneNr = -1, bool enableLogging=true);
  AlpideEvent DecodeEvent(std::vector<TPixHit> *hits);
};

#endif
