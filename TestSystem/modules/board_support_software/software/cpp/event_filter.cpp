//-----------------------------------------------------------------------------
// Title      : ALPIDE Event Filter
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : event_filter.cpp
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2016-10-11
// Last update: 2016-10-11
// Platform   : CERN 7 (CentOs)
// Target     : Simulation
// Standard   : SystemC 2.3
//-----------------------------------------------------------------------------
// Description: Fast Filter events on the data stream
//-----------------------------------------------------------------------------
// Copyright (c)   2016
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2016-10-11  1.0      mbonora        Created
//-----------------------------------------------------------------------------

#include "AlpideDecoder.h"

#include <array>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <exception>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <map>
#include <memory>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include <boost/circular_buffer.hpp>
#include <boost/format.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

// Boost write compressed stream
#include <boost/iostreams/device/file.hpp>
#include <boost/iostreams/filtering_stream.hpp>
#include <boost/iostreams/copy.hpp>
#include <boost/iostreams/filter/gzip.hpp>

// logging
#define ELPP_THREAD_SAFE
#define ELPP_FORCE_USE_STD_THREAD
#define ELPP_STL_LOGGING
#include "easylogging++.h"

INITIALIZE_EASYLOGGINGPP

bool constexpr WRITE_GBT_COUNTER_FILE = false;

int constexpr LOOKBACK_BUFFER_SIZE = 1024 * 100;
int constexpr READOUT_SIZE = 1024 * 1024 * 12;

static_assert(READOUT_SIZE % 12 == 0, "READOUT_SIZE must me multiple of 12");

size_t constexpr MAX_BAD_EVENTS = ~0;

// Continue on event errors (does not print a notification for each event)
bool constexpr SILENT_MODE = true;
bool constexpr VLOGGING_ON = false;

size_t constexpr TRIGGER_HANDLER_TIMER = 2760;
size_t constexpr TRIGGER_TIMER_COUNT_FREQ = 160315880;
size_t constexpr estimate_runtime(size_t packetId) {
  return static_cast<double>(packetId * TRIGGER_HANDLER_TIMER) /
         TRIGGER_TIMER_COUNT_FREQ;
}

constexpr std::array<size_t, 9> CHANNEL_BYTE_ORDER{
  8, 9, 10, 11, 4, 5, 6, 7, 0
};
constexpr std::array<size_t, 10> GBT_BYTE_ORDER{
  1, 0, 7, 6, 5, 4, 11, 10, 9, 8
};

constexpr uint8_t GBT_CTRL_SOP = 0x1;
constexpr uint8_t GBT_CTRL_EOP = 0x2;



using boost::format;
using boost::property_tree::ptree;
using boost::property_tree::write_json;

using gbtword_t = std::array<uint8_t, 10>;

class EndOfStreamException : public std::exception {
public:
  using std::exception::exception;
};

struct EventError {
  size_t gbtIdFirst;
  size_t gbtIdLast;
  size_t gbtCounterFirst;
  size_t gbtCounterLast;
  size_t count;
  EventError(size_t gbtId, size_t gbtCounter) :
      gbtIdFirst(gbtId), gbtIdLast(gbtId),
      gbtCounterFirst(gbtCounter), gbtCounterLast(gbtCounter),
      count(1) {}
  void updateError(size_t gbtId, size_t gbtCounter) {
    gbtCounterLast = gbtId;
    gbtCounterLast = gbtCounter;
    ++count;
  }
};

struct GbtStreamResults {
  size_t sopCount = 0;
  size_t eopCount = 0;
  size_t unknownCount = 0;
  size_t byteErrorCount = 0;
  std::vector<std::pair<size_t,size_t>> byteErrorsIds;

  std::map<size_t, std::vector<uint8_t> > unknownList;
  std::map<size_t,size_t> gbtCounterMap;
};

struct GbtDecoder {
  GbtDecoder() : m_packetIdx(0), m_packetCounter(0) {}

  // Process a GBT word (10 bytes within data)
  bool processGbtWord(char *data) {
    bool startOfPacket = false;
    uint8_t ctrl_cmd = data[GBT_BYTE_ORDER[0]] >> 4;
    if (ctrl_cmd == GBT_CTRL_SOP) {
      ++m_packetIdx;
      ++m_results.sopCount;
      checkByteError(data, GBT_CTRL_SOP);
      startOfPacket = true;
      m_results.gbtCounterMap[m_packetIdx] = m_packetCounter;
    } else if (ctrl_cmd == GBT_CTRL_EOP) {
      ++m_results.eopCount;
      checkByteError(data, GBT_CTRL_EOP);
    } else {
      ++m_results.unknownCount;
      for (auto idx : GBT_BYTE_ORDER)
        m_results.unknownList[m_packetIdx].push_back(data[idx]);
    }
    return startOfPacket;
  }

  size_t getPacketIdx() const { return m_packetIdx; }

  size_t getPacketCounter() const { return m_packetCounter; }

  GbtStreamResults const &getResults() const { return m_results; }

private:
  void checkByteError(char *data, uint8_t ctrl_word) {
    bool isError = false;
    // GBT Package: <SOP/EOP> 0 C7 C6 C5 C4 C3 C2 C1 C0

    if (data[GBT_BYTE_ORDER[0]] != (ctrl_word << 4)) {
      isError = true;
    } else if (data[GBT_BYTE_ORDER[1]] != 0) {
      isError = true;
    } else {
      size_t counter = 0;
      for (size_t i = 0; i < 8; ++i) {
        size_t b = uint8_t(data[GBT_BYTE_ORDER[9 - i]]);
        //CLOG(INFO,"main") << "Counter: " << counter << " byte: " << std::hex << int(b) << std::dec << " shift: " << i*8;
        counter = counter |(b << (i * 8));
      }
      if (counter < m_packetCounter) {
        isError = true;
        CLOG_IF(!SILENT_MODE,INFO, "main") << "Packet counter decreased: Old Value: "
                                           << m_packetCounter << ", new value: " << counter;
        if(!SILENT_MODE) {
          std::ostringstream oss;
          for (auto idx : GBT_BYTE_ORDER) {
            oss << std::hex << std::setfill('0') << std::setw(2)
                << uint32_t(uint8_t(data[idx])) << " ";
          }
          oss << std::dec;
          CLOG_IF(!SILENT_MODE,INFO, "main") << oss.str();
        }
      }
      m_packetCounter = counter;
      m_results.gbtCounterMap[m_packetIdx] = m_packetCounter;
    }
    if (isError) {
      ++m_results.byteErrorCount;
      if(m_results.byteErrorsIds.empty() or m_results.byteErrorsIds.back().second + 1 < m_packetIdx) {
        m_results.byteErrorsIds.push_back(std::make_pair(m_packetIdx,m_packetIdx));
      } else {
        m_results.byteErrorsIds.back().second = m_packetIdx;
      }
      // for (auto idx : GBT_BYTE_ORDER)
      //  m_results.byteErrorList[m_packetIdx].push_back(data[idx]);
    }
  }
  GbtStreamResults m_results;
  size_t m_packetIdx;
  size_t m_packetCounter;
};

struct StreamReader {
  static constexpr const char *logger() { return "StreamReader"; }

private:
  void loadDataFromInput() {
    // load data in bytes of 4
    static char data[READOUT_SIZE + 4];
    static size_t dataStartIdx = 0;

    std::cin.read(data + dataStartIdx, READOUT_SIZE);
    int dataRead = std::cin.gcount();
    int i = 0;
    for (; i < dataRead; i += 12) {
      // Word0 : D8,D9,0000_0000,<V000_0000>
      // Word1 : D4,D5,D6,D7
      // Word2 : D0,D1,D2,D3
      bool datavalid = data[i + 3] >> 7;
      size_t channel = data[i + 1];

      if (!datavalid) {
        // GBT word stream (SOP,EOP,...)
        bool isSop = m_decoder.processGbtWord(&data[i]);
        if (isSop) {
          for (auto const &ch : channelWrites) {
            if (m_channels.count(ch.first) > 0) {
              if (!channelGbtPacketIdx[ch.first].empty() &&
                  channelGbtPacketIdx[ch.first].back().first == ch.second) {
                channelGbtPacketIdx[ch.first].back().second =
                    m_decoder.getPacketIdx();
              } else {
                channelGbtPacketIdx[ch.first].push_back(
                    std::make_pair(ch.second, m_decoder.getPacketIdx()));
              }
            }
          }
        }
        protocolBuf.push_back(data[i + 1]);
        for (auto idx : CHANNEL_BYTE_ORDER) {
          protocolBuf.push_back(data[i + idx]);
        }
        // CVLOG(9, logger()) << "Datavalid=0";
      } else if (m_channels.count(channel)) {
        auto &buf = getChannelBuf(channel);
        if (VLOGGING_ON && VLOG_IS_ON(9) && channel > 0)
          CVLOG(9, logger()) << "Datavalid=1, channel=" << channel;

        for (auto idx : GBT_BYTE_ORDER) {
          lookbackBuf[channel].push_back(data[i + idx]);
        }
        for (auto idx : CHANNEL_BYTE_ORDER) {
          buf.push_back(data[i + idx]);
          ++channelWrites[channel];
        }
      } else {
        // Unknown channel, put in lookback buffer
        for (auto idx : GBT_BYTE_ORDER) {
          lookbackBuf[channel].push_back(data[i + idx]);
        }
      }
      if (VLOGGING_ON && VLOG_IS_ON(9)) {
        std::ostringstream oss;
        for (auto idx : CHANNEL_BYTE_ORDER) {
          oss << std::hex << std::setfill('0') << std::setw(2)
              << uint32_t(uint8_t(data[i + idx])) << " ";
        }
        oss << std::dec;
        CVLOG(9, logger()) << oss.str();
      }
    }

    if (!std::cin) {
      CLOG(INFO, logger()) << "Stream exhausted";
      m_isExhausted = true;
    }
  }

  void waitForData(size_t channel) {
    if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
      CVLOG(5, logger()) << "Channel: " << channel << " waitForData";
    std::unique_lock<std::mutex> lk(m_loadDataReadyMutex);
    ++m_threadsWaiting;
    if (m_threadsWaiting >= m_channels.size()) {
      if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
        CVLOG(5, logger())
            << "Channel: " << channel
            << ", all other threads are waiting. Load new data from input";
      loadDataFromInput();
      m_threadsWaiting = 0;
      m_dataLoadedCond.notify_all();
    } else {
      if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
        CVLOG(5, logger()) << "Channel " << channel << " waits, "
                           << m_threadsWaiting << "/" << m_channels.size()
                           << " threads waiting for input";
      m_dataLoadedCond.wait(lk);
      if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
        CVLOG(5, logger()) << "Channel " << channel << " Continue";
    }
  }

  boost::circular_buffer<unsigned char> &getChannelBuf(size_t channel) {
    return channelBuf[channel];
  }
  bool isExhausted() const { return m_isExhausted; }

public:
  void dumpLookback(size_t channel, std::string const &filename) {
    CLOG(INFO, logger()) << "Channel " << channel
                         << ": Write lookback buffer, size: "
                         << lookbackBuf[channel].size();
    std::ofstream file(filename, std::ios::binary | std::ios::out);
    file.write(reinterpret_cast<char *>(lookbackBuf[channel].linearize()),
               lookbackBuf[channel].size());
    file.close();
  }

  void loadData(size_t const &channel, unsigned char *data, size_t size) {
    auto &dataBuf = getChannelBuf(channel);
    while (dataBuf.size() < size) {
      if (isExhausted()) {
        if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
          CVLOG(5, logger()) << "Lane " << channel << ": "
                             << "No more data, stop processing";
        throw EndOfStreamException();
      }
      if (dataBuf.size() < size)
        waitForData(channel);
    }
    for (size_t i = 0; i < size; ++i) {
      data[i] = dataBuf.front();
      dataBuf.pop_front();
      ++channelReads[channel];
    }
  }

  size_t getGbtPacketId(size_t const &channel) {
    while (channelGbtPacketIdx[channel].size() > 1 &&
           channelReads[channel] > channelGbtPacketIdx[channel][1].first) {
      channelGbtPacketIdx[channel].pop_front();
    }
    if (channelGbtPacketIdx[channel].empty()) {
      CLOG(ERROR, logger()) << "Channel " << channel
                            << ": Tried to read GBT Packet index, but no "
                               "packet index past this point";
      return 0;
    } else {
      return channelGbtPacketIdx[channel].front().second;
    }
  }

  GbtStreamResults const &getGbtStreamResults() const {
    return m_decoder.getResults();
  }

  GbtDecoder const &gbtDecoder() const { return m_decoder; }

  void addChannel(size_t channel) {
    if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
      CVLOG(5, logger()) << "Add Channel " << channel << " to list";
    std::unique_lock<std::mutex> lk(m_loadDataReadyMutex);
    m_channels.insert(channel);
    channelBuf[channel].set_capacity(READOUT_SIZE + 4);
    lookbackBuf[channel].set_capacity(LOOKBACK_BUFFER_SIZE);
  }
  void removeChannel(size_t channel) {
    {
      if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
        CVLOG(5, logger()) << "Remove Channel " << channel << " from list. ";
      std::unique_lock<std::mutex> lk(m_loadDataReadyMutex);
      if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
        CVLOG(5, logger()) << "Channels: " << m_channels.size() << ", "
                           << m_threadsWaiting << " threads waiting for input";
      m_channels.erase(channel);
      if (m_threadsWaiting >= m_channels.size()) {
        if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
          CVLOG(5, logger())
              << "After removing channel " << channel
              << ", all other threads are waiting. Load new data from input";
        loadDataFromInput();
        m_threadsWaiting = 0;
        m_dataLoadedCond.notify_all();
        if (VLOGGING_ON && VLOG_IS_ON(5) && channel > 0)
          CVLOG(5, logger()) << "Channel " << channel
                             << " removed from list. Continue";
      }
    }
  }

  std::set<size_t> const &getActiveChannels() const { return m_channels; }

  StreamReader()
      : protocolBuf(READOUT_SIZE + 4), m_isExhausted(false),
        m_threadsWaiting(0) {
    el::Loggers::getLogger(logger());
  }

private:
  GbtDecoder m_decoder;
  boost::circular_buffer<unsigned char> protocolBuf;
  std::map<size_t, boost::circular_buffer<unsigned char> > channelBuf;
  std::map<size_t, boost::circular_buffer<unsigned char> > lookbackBuf;
  std::map<size_t, std::deque<std::pair<size_t, size_t> > > channelGbtPacketIdx;
  std::map<size_t, size_t> channelWrites, channelReads;

  bool m_isExhausted;
  std::mutex m_loadDataReadyMutex;
  std::condition_variable m_dataLoadedCond;
  size_t m_threadsWaiting;
  std::set<size_t> m_channels;
};

struct ChannelReader {
  static constexpr char const *logger() { return "ChannelReader"; }
  ChannelReader(StreamReader &streamReader, size_t channel)
      : m_streamReader(streamReader), m_channel(channel),
        m_lookbackBuf(LOOKBACK_BUFFER_SIZE) {
    m_streamReader.addChannel(channel);
    el::Loggers::getLogger(logger());
  }
  ~ChannelReader() { m_streamReader.removeChannel(m_channel); }

  ChannelReader(ChannelReader const &) = delete;
  ChannelReader &operator=(ChannelReader const &) = delete;
  ChannelReader(ChannelReader const &&) = delete;
  ChannelReader &operator=(ChannelReader const &&) = delete;

  void dumpLookback(std::string const &filename) {
    std::ofstream file(filename, std::ios::binary | std::ios::out);
    file.write(reinterpret_cast<char *>(m_lookbackBuf.linearize()),
               m_lookbackBuf.size());
    file.close();
  }

  AlpideDecoder::TByteVector operator()(size_t size) {
    unsigned char *data = m_data.data();
    m_streamReader.loadData(m_channel, data, size);
    for (int i = 0; i < size; ++i)
      m_lookbackBuf.push_back(data[i]);
    if (VLOGGING_ON && VLOG_IS_ON(8)) {
      std::ostringstream oss;
      for (size_t i = 0; i < size; ++i) {
        oss << std::hex << std::setfill('0') << std::setw(2)
            << uint32_t(uint8_t(data[i])) << " ";
      }
      oss << std::dec;
      CVLOG(8, logger()) << oss.str();
    }
    return data;
  }
  std::array<unsigned char, 4> m_data;
  StreamReader &m_streamReader;
  size_t const m_channel;
  boost::circular_buffer<unsigned char> m_lookbackBuf;
};

namespace std {
template <> struct less<TPixHit> {
  bool operator()(const TPixHit &lhs, const TPixHit &rhs) const {
    uint32_t lid = lhs.address | lhs.dcol << 10 | lhs.region << 14 | lhs.chipId
                                                                         << 19;
    uint32_t rid = rhs.address | rhs.dcol << 10 | rhs.region << 14 | rhs.chipId
                                                                         << 19;
    return lid < rid;
  }
};
}

struct TriggerResults {
  std::atomic<uint64_t> triggerCount;
  std::atomic<uint64_t> validTriggers;
  std::atomic<uint64_t> invalidTriggers;
  std::map<size_t,size_t> triggerTypeMap;
  size_t gbtIdLastTrigger;

  std::vector<EventError> errorList;

  TriggerResults() : triggerCount(0), gbtIdLastTrigger(0), validTriggers(0), invalidTriggers(0) {}
};

struct TriggerDecoder {
  TriggerDecoder() : m_done(false), m_success(false) {
    el::Loggers::getLogger(logger());
  }

  void processTrigger(StreamReader &streamReader) {
    m_success = process(streamReader);
    m_done = true;
  }
  TriggerResults const &results() const { return m_results; }
  bool done() const { return m_done; }
private:
  bool process(StreamReader &streamReader) {
    ChannelReader m_channelReader(streamReader, 0);
    bool result = true;
    try {
      std::vector<TPixHit> hits;
      CLOG(INFO, logger()) << "Trigger decoder start";
      std::array<uint8_t,9> triggerData;
      bool bad_event_streak = false;
      while (true) {
        streamReader.loadData(0, triggerData.data(), 9);
        auto gbtId = streamReader.getGbtPacketId(0);
        auto gbtCounter = streamReader.getGbtStreamResults().gbtCounterMap.at(gbtId);

        size_t triggerType = triggerData[0] | (triggerData[1]<<8);
        m_results.triggerTypeMap[triggerType]++;
        if(validTrigger(triggerType)) {
          ++m_results.validTriggers;
          bad_event_streak = false;
        } else {
          ++m_results.invalidTriggers;
          if(bad_event_streak) {
            m_results.errorList.back().updateError(gbtId,gbtCounter);
          } else {
            m_results.errorList.push_back(EventError(gbtId,gbtCounter));
          }
          bad_event_streak = true;
        }
        m_results.triggerCount++;
        m_results.gbtIdLastTrigger = streamReader.getGbtPacketId(0);
      }
    }
    catch (EndOfStreamException &eos) {
      result = true;
    }
    catch (std::exception &e) {
      CLOG(ERROR, logger()) << "Exception in Trigger: " << e.what();
      result = false;
    }
    CLOG(INFO, logger()) << "Trigger: "
                         << "finished with Result=" << result;
  }
  static constexpr bool validTrigger(uint64_t triggerType) {
    return triggerType == 0xc0 || triggerType == 0x80 || triggerType == 0x8 || triggerType == 0x2 ||
        triggerType == 0x4 || triggerType == 0x140 || triggerType == 0x100;
  }
  static constexpr char const *logger() { return "TriggerDecoder"; }

private:
  TriggerResults m_results;
  std::atomic<bool> m_done;
  bool m_success;
  std::string m_loggerName;
};

struct LaneResults {
  std::atomic<uint64_t> goodEvents;
  std::atomic<uint64_t> badEvents;
  std::map<int, int> chipIdHist;
  std::map<int, int> bunchCounterHist;
  std::map<int, int> hitCountHist;
  std::map<int, int> flagHist;
  std::map<TPixHit, uint32_t> hitMap;
  size_t gbtIdLastEvent;
  size_t gbtIdLastGoodEvent;
  size_t gbtIdDeltaSum;
  size_t gbtCounterLastEvent;
  size_t gbtCounterLastGoodEvent;
  size_t gbtCounterDeltaSum;

  std::vector<EventError> errorList;
};

struct LaneDecoder {
  LaneDecoder(size_t nr = 1) : m_nr(nr), m_done(false), m_success(false) {
    el::Loggers::getLogger(logger());
  }

  void processLane(StreamReader &streamReader) {
    m_success = process(streamReader);
    m_done = true;
  }
  LaneResults const &results() const { return m_results; }
  bool done() const { return m_done; }
  size_t nr() const { return m_nr; }

private:
  bool process(StreamReader &streamReader) {
    ChannelReader m_channelReader(streamReader, m_nr);
    AlpideDecoder decoder(std::ref(m_channelReader), m_nr, !SILENT_MODE);
    bool result = true;
    try {
      std::vector<TPixHit> hits;
      CLOG(INFO, logger()) << "Lane " << m_nr << " start";
      bool bad_event_streak = false;
      while (m_results.badEvents < MAX_BAD_EVENTS) {
        AlpideEvent result = decoder.DecodeEvent(&hits);
        result.gbtPacketId = streamReader.getGbtPacketId(m_nr);
        result.gbtPacketCounter = streamReader.getGbtStreamResults().gbtCounterMap.at(result.gbtPacketId);

        m_results.gbtIdDeltaSum +=
            (result.gbtPacketId - m_results.gbtIdLastEvent);
        m_results.gbtIdLastEvent = result.gbtPacketId;
        m_results.gbtCounterLastEvent = result.gbtPacketCounter;

        m_results.gbtCounterDeltaSum +=
            (result.gbtPacketCounter - m_results.gbtCounterLastEvent);

        if (result.error) {
          ++m_results.badEvents;
          size_t eventNr = m_results.goodEvents + m_results.badEvents;
          if(bad_event_streak) {
            m_results.errorList.back().updateError(result.gbtPacketId,result.gbtPacketCounter);
          } else {
            m_results.errorList.push_back(EventError(result.gbtPacketId, result.gbtPacketCounter));
          }

          bad_event_streak = true;

          CLOG_IF(!SILENT_MODE,WARNING, logger()) << "Lane " << m_nr << ": "
                                                               << "Event Nr. " << std::dec << eventNr
                                                               << " is bad. GbtPacketId: "
                                                               << result.gbtPacketId;
        } else {
          m_results.gbtIdLastGoodEvent = m_results.gbtIdLastEvent;
          m_results.gbtCounterLastGoodEvent = m_results.gbtCounterLastEvent;
          ++m_results.goodEvents;
          ++m_results.hitCountHist[hits.size()];

          bad_event_streak = false;

          if (VLOGGING_ON && VLOG_IS_ON(8))
            CVLOG(8, logger()) << "Lane " << m_nr << ": "
                               << "Good event ";

          for (auto const &hit : hits)
            m_results.hitMap[hit] += 1;
        }
        ++m_results.flagHist[result.flags];
        ++m_results.chipIdHist[result.chipId];
        ++m_results.bunchCounterHist[result.bunchCounter];

        hits.clear();
      }
      CLOG(INFO, logger()) << "Lane " << m_nr << ": "
                           << "End of channel: too many bad events";
      std::string lookback_filename =
          (boost::format("channel_%d_data.dat") % m_nr).str();
      m_channelReader.dumpLookback(lookback_filename);
      std::string lookback_gbt_filename =
          (boost::format("channel_%d_gbt_data.dat") % m_nr).str();
      streamReader.dumpLookback(m_nr, lookback_gbt_filename);
      result = false;
    }
    catch (EndOfStreamException &eos) {
      result = true;
    }
    catch (std::exception &e) {
      CLOG(ERROR, logger()) << "Exception in Lane " << m_nr << ": " << e.what();
      result = false;
    }
    CLOG(INFO, logger()) << "Lane " << m_nr << ": "
                         << "finished with Result=" << result;
  }
  static constexpr char const *logger() { return "LaneDecoder"; }

private:
  LaneResults m_results;
  size_t m_nr;
  std::atomic<bool> m_done;
  bool m_success;
  std::string m_loggerName;
};

int main(int argc, char **argv) {

  START_EASYLOGGINGPP(argc, argv);
  el::Configurations defaultConf;
  defaultConf.setToDefault();
  defaultConf.set(el::Level::Global, el::ConfigurationType::Format,
                  "%datetime [%logger] %level - %msg");
  defaultConf.set(el::Level::Verbose, el::ConfigurationType::Format,
                  "%datetime [%logger] %level-%vlevel - Line %line - %msg");

  el::Loggers::reconfigureAllLoggers(defaultConf);

  el::Loggers::getLogger("main");
  // Files for hitmap
  std::ofstream ofhitmap("hitmap.csv");
  std::ofstream ofbcmap("bunch_counters.csv");
  std::ofstream ofresults("results.json");
  std::ofstream oflaneerrors("lane_errors.csv");
  std::ofstream ofstreamerrors("stream_errors.csv");

  oflaneerrors << "lane;count;gbtidstart;gbtidend;gbtcounterstart;gbtcounterend\n";
  ofstreamerrors << "count;gbtidstart;gbtidend;gbtcounterstart;gbtcounterend\n";

  typedef std::chrono::duration<float> fsec;
  StreamReader sr;

  std::vector<std::shared_ptr<LaneDecoder> > lanes;
  for (int i = 1; i <= 9; ++i) {
    lanes.push_back(std::make_shared<LaneDecoder>(i));
  }
  TriggerDecoder triggerDecoder;

  uint64_t tEvents = 0;

  std::vector<std::thread> threads;
  // create threads
  for (auto &lane : lanes) {
    threads.emplace_back([&lane, &sr]() { lane->processLane(sr); });
  }
  threads.emplace_back([&triggerDecoder,&sr](){triggerDecoder.processTrigger(sr);});

  auto start = std::chrono::high_resolution_clock::now();
  auto tSegment = start;
  auto reportTime = std::chrono::seconds(10);
  bool allDone = false;
  size_t allTriggers = 0;
  while (!allDone) {
    auto stop = std::chrono::high_resolution_clock::now();

    allDone = true;
    uint64_t goodEvents = 0;
    uint64_t badEvents = 0;
    for (auto const &lane : lanes) {
      allDone = allDone && lane->done();
      goodEvents += lane->results().goodEvents;
      badEvents += lane->results().badEvents;
    }

    if (stop - tSegment > reportTime) {
      int dEvents = goodEvents - tEvents;
      auto dTime = std::chrono::duration_cast<fsec>(stop - tSegment).count();
      CLOG(INFO, "main") << "Events: " << std::dec << goodEvents << " good, "
                         << badEvents << " bad, Rate: "
                         << boost::format("%.0f") % (dEvents / dTime)
                         << " Events/s";
      CLOG(INFO, "main") << "GBT Protocol stats: SOP: "
                         << sr.getGbtStreamResults().sopCount
                         << ", EOP: " << sr.getGbtStreamResults().eopCount
                         << ", Unknown: "
                         << sr.getGbtStreamResults().unknownCount
                         << ", Errors: "
                         << sr.getGbtStreamResults().byteErrorCount;
      CLOG(INFO, "main") << "Active Channels: " << sr.getActiveChannels();


      CLOG(INFO, "main") << "Triggers: "
                         << " Total: " <<  triggerDecoder.results().triggerCount
                         << " Valid: " << triggerDecoder.results().validTriggers
                         << " Invalid: " << triggerDecoder.results().invalidTriggers
                         << ", Current: " << (triggerDecoder.results().triggerCount - allTriggers)
                         << ", rate: " << (triggerDecoder.results().triggerCount - allTriggers)/dTime;

          allTriggers = triggerDecoder.results().triggerCount;

      auto packet_idx = sr.gbtDecoder().getPacketIdx();
      double estimated_uptime = estimate_runtime(packet_idx);

      CLOG(INFO, "main") << "GBT Packet Index: " << packet_idx
                         << ", estimated uptime: "
                         << boost::format("%.2f min") % (estimated_uptime / 60) << ", Realtime window:" << dTime << "s\n";

      tSegment = stop;
      tEvents = goodEvents;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  uint64_t goodEvents = 0;
  uint64_t badEvents = 0;
  std::map<TPixHit, uint32_t> hitMap;
  std::map<size_t, std::map<int, int> > bunchCounterHists;
  for (auto const &lane : lanes) {
    goodEvents += lane->results().goodEvents;
    badEvents += lane->results().badEvents;
    bunchCounterHists[lane->nr()] = lane->results().bunchCounterHist;
    for (auto &hit : lane->results().hitMap) {
      hitMap[hit.first] += hit.second;
    }
  }

  auto stop = std::chrono::high_resolution_clock::now();
  auto ftime = std::chrono::duration_cast<fsec>(stop - start).count();
  CLOG(INFO, "main") << ftime << "s"
                     << " Events: " << goodEvents << " good, " << badEvents
                     << " bad";

  CLOG(INFO, "main") << "Rate: " << (goodEvents / ftime) << " Events/s";

  CLOG(INFO, "main") << "Stream finished. Showing Results";

  for (auto const &lane : lanes) {
    CLOG(INFO, "main") << "Lane " << lane->nr() << " Results:";
    CLOG(INFO, "main") << "  Good Events: " << lane->results().goodEvents;
    double last_good_estimate =
        estimate_runtime(lane->results().gbtIdLastGoodEvent) / 60.0;
    CLOG(INFO, "main") << "  Estimated uptime: " << boost::format("%.2f min") %
                                                        last_good_estimate;
    CLOG(INFO, "main") << "  Bad Events: " << lane->results().badEvents;
    if (lane->results().badEvents > 0) {
      double fail_estimate =
          estimate_runtime(lane->results().errorList.front().gbtIdFirst) / 60.0;
      CLOG(INFO, "main") << "  First Bad Event: " << boost::format("%.2f min") %
                                                         fail_estimate;
    }
    double event_per_gbt_word =
        (lane->results().goodEvents + lane->results().badEvents) /
        static_cast<double>(lane->results().gbtIdDeltaSum);
    CLOG(INFO, "main") << boost::format("  Events per GBT word: %.3f") %
                              event_per_gbt_word;

    CLOG(INFO, "main") << "  ChipIds registered in lane: "
                       << lane->results().chipIdHist;
    CLOG(INFO, "main") << "  Nr Of Hits distribution: "
                       << lane->results().hitCountHist;
    CLOG(INFO, "main") << "  Flags registered: " << lane->results().flagHist;
  }

  CLOG(INFO, "main") << "Trigger: ";
  CLOG(INFO, "main") << "  Triggers registered: " << triggerDecoder.results().triggerCount;
  CLOG(INFO, "main") << "  Valid: " << triggerDecoder.results().validTriggers << ", "
                     << "Invalid: " << triggerDecoder.results().invalidTriggers;
  double last_good_estimate =
      estimate_runtime(triggerDecoder.results().gbtIdLastTrigger) / 60.0;
  CLOG(INFO, "main") << "  Estimated uptime: " << boost::format("%.2f min") %
      last_good_estimate;
  CLOG(INFO, "main") << "  TriggerTypes received:" << triggerDecoder.results().triggerTypeMap.size();


  auto const &gbt_results = sr.getGbtStreamResults();
  auto packet_idx = sr.gbtDecoder().getPacketIdx();
  double estimated_uptime = estimate_runtime(packet_idx);
  CLOG(INFO, "main") << "GBT Stream:";
  CLOG(INFO, "main") << "  Estimated Uptime: " << boost::format("%.2f min") %
                                                      (estimated_uptime / 60);
  CLOG(INFO, "main") << "  Start Of Packet: " << gbt_results.sopCount;
  CLOG(INFO, "main") << "  End Of Packet: " << gbt_results.eopCount;
  CLOG(INFO, "main") << "  Unknown Packet: " << gbt_results.unknownCount;
  CLOG(INFO, "main") << "  Byte Errors: " << gbt_results.byteErrorCount;

  // Write results to file
  CLOG(INFO, "main") << "Write Result Files";
  ptree results;
  for (auto const &lane : lanes) {
    std::string lane_name = (boost::format("Lane_%d") % lane->nr()).str();
    results.add(lane_name + ".goodEvents", lane->results().goodEvents);
    results.add(lane_name + ".badEvents", lane->results().badEvents);
    for (auto const &chid : lane->results().chipIdHist)
      results.add(lane_name + ".chipIds." + std::to_string(chid.first),
                  chid.second);
    for (auto const &chid : lane->results().hitCountHist)
      results.add(lane_name + ".hitCounts." + std::to_string(chid.first),
                  chid.second);
    for (auto const &chid : lane->results().flagHist)
      results.add(lane_name + ".flags." + std::to_string(chid.first),
                  chid.second);
    results.add(lane_name + ".gbtIdLastEvent", lane->results().gbtIdLastEvent);
    results.add(lane_name + ".gbtIdLastGoodEvent",
                lane->results().gbtIdLastGoodEvent);
    results.add(lane_name + ".gbtCounterLastEvent", lane->results().gbtCounterLastEvent);
    results.add(lane_name + ".gbtCounterLastGoodEvent",
                lane->results().gbtCounterLastGoodEvent);
    results.add(lane_name + ".gbtIdDeltaSum", lane->results().gbtIdDeltaSum);
    results.add(lane_name + ".gbtCounterDeltaSum", lane->results().gbtCounterDeltaSum);

    for(auto const &e : lane->results().errorList) {
      oflaneerrors << lane->nr() << ";"
                   << e.count << ";"
                   << e.gbtIdFirst << ";"
                   << e.gbtIdLast << ";"
                   << e.gbtCounterFirst << ";"
                   << e.gbtCounterLast << "\n";
    }

  }

  ptree gbt_tree;
  gbt_tree.add("sopCount", gbt_results.sopCount);
  gbt_tree.add("eopCount", gbt_results.eopCount);
  gbt_tree.add("unknownCount", gbt_results.unknownCount);

  for(auto const & ch : gbt_results.byteErrorsIds) {
    ofstreamerrors << ch.first << ";" << ch.second << "\n";
  }

  results.add_child("GbtStream", gbt_tree);

  ptree trigger_tree;
  trigger_tree.add("triggerCount", triggerDecoder.results().triggerCount);
  trigger_tree.add("validTriggerCount", triggerDecoder.results().validTriggers);
  trigger_tree.add("invalidTriggerCount", triggerDecoder.results().invalidTriggers);
  for (auto const &ttype : triggerDecoder.results().triggerTypeMap)
    trigger_tree.add(std::string("triggerType.") + std::to_string(ttype.first),
                ttype.second);
  results.add_child("TriggerData",trigger_tree);

  for(auto const &e : triggerDecoder.results().errorList) {
    oflaneerrors << 0 << ";"
                 << e.count << ";"
                 << e.gbtIdFirst << ";"
                 << e.gbtIdLast << ";"
                 << e.gbtCounterFirst << ";"
                 << e.gbtCounterLast << "\n";
  }

  write_json(ofresults, results, true);

  /*
    for(auto const& cntr : gbt_results.gbtCounterMap) {
    gbt_tree.add(std::string("counterMap.") + std::to_string(cntr.first), cntr.second);
    }*/
  if (WRITE_GBT_COUNTER_FILE) {
    namespace bio = boost::iostreams;
    bio::file_sink outfile("gbt_counters.csv.gz");
    bio::filtering_ostream out;
    out.push(bio::gzip_compressor(bio::gzip_params(bio::gzip::best_compression)));
    out.push(outfile);

    out << "GBT_PACKET_IDX,GBT_COUNTER\n";
    for(auto const& cntr : gbt_results.gbtCounterMap)
      out << cntr.first << "," << cntr.second << "\n";
  }
  ofbcmap << "Bunchcounter";
  for (auto const &bch : bunchCounterHists) {
    ofbcmap << ","
            << "Lane_" << bch.first;
  }
  ofbcmap << "\n";

  for (int i = 0; i < 256; ++i) {
    ofbcmap << i;
    for (auto const &bch : bunchCounterHists) {
      auto bc = bch.second.find(i);
      if (bc == end(bch.second)) {
        ofbcmap << "," << 0;
      } else {
        ofbcmap << "," << bc->second;
      }
    }
    ofbcmap << "\n";
  }

  ofhitmap << "ChipId,region,dcol,address,hitcount\n";
  for (auto const &ent : hitMap) {
    auto hit = ent.first;
    auto val = ent.second;
    ofhitmap << hit.chipId << "," << hit.region << "," << hit.dcol << ","
             << hit.address << "," << val << "\n";
  }
  ofbcmap.close();
  ofhitmap.close();

  for (auto &t : threads) {
    t.join();
  }

  CLOG(INFO, "main") << " Closed " << std::endl;
}
