
//-----------------------------------------------------------------------------
// Title      : Usb Communication module
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : usb_comm.cpp
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-11-23
// Last update: 2015-11-23
// Platform   : CERN 7 (CentOs)
// Target     : Linux/Windows
// Standard   : C++11
//-----------------------------------------------------------------------------
// Description: Software interface between Usb connection and clients
//              Use: <program name> [parameters]
//              See Readme for valid parameters.
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-23  1.0      mbonora        Created
//-----------------------------------------------------------------------------

// Std libs
#include <chrono>
#include <condition_variable>
#include <exception>
#include <functional>
#include <future>
#include <memory>
#include <mutex>
#include <sstream>
#include <thread>

using std::placeholders::_1;

// Boost libs
#include <boost/asio.hpp>
#include <boost/format.hpp>
#include <boost/program_options.hpp>

using boost::format;
using boost::asio::ip::tcp;

// logging
#define ELPP_THREAD_SAFE
#define ELPP_FORCE_USE_STD_THREAD
#include "easylogging/easylogging++.h"

// Usb abstraction
#include "UsbDev.hpp"

INITIALIZE_EASYLOGGINGPP
// Constants

/* Default Buffer size for Data buffers (read from libusb) */
size_t const DATA_BUFFER_SIZE = 1024 * 60;
/* Default Timeout for Data Read (from libusb) */
size_t const DATA_READ_TIMEOUT = 1000;

const std::chrono::milliseconds USB_WRITE_WAIT_TIME{ 5 };

/* Size of a single control word sent to the usb */
size_t const CONTROL_BUFFER_SIZE = 1024;
size_t const CONTROL_WORD_SIZE = 4;
size_t const CONTROL_READ_TIMEOUT = 1000;
size_t const CONTROL_WRITE_TIMEOUT = 1000;

/* Usb Config */
int const VID = 0x04B4;
int const PID = 0x0008;
int const INTERFACE_NUMBER = 2;

uint8_t const EP_CTL_OUT = 3;
uint8_t const EP_CTL_IN = 3;
uint8_t const EP_DATA0_IN = 4;
uint8_t const EP_DATA1_IN = 5;

/* Network config */
uint16_t const PORT_CONTROL = 30000;
uint16_t const PORT_DATA_0 = 30001;
uint16_t const PORT_DATA_1 = 30002;

/*! Abstract Usb Server class.

  Listens to a client connection. If a client connects, the
  implementations of this class perform a custom action with the
  client. When the client disconnects or an error occures, the
  connection is closed and the class waits for the next connection.
 */
class UsbServer {

public:
  /* Construct the UsbServer with references to a Usb device, the
     boost io_service and a port the server listens to */
  UsbServer(UsbDev &usb, boost::asio::io_service &io_service, size_t port,
            std::string loggerName)
      : m_usbDevice(usb), m_io_service(io_service), m_port(port),
        m_acceptor(m_io_service, tcp::endpoint(tcp::v4(), m_port)),
        m_socket(io_service), m_running(true), m_loggerName(loggerName) {
    el::Loggers::getLogger(m_loggerName);
  }

  virtual ~UsbServer() = default;

  /*! Virtual handleConnection function.

    To be implemented in the subclass.  This function shall implement a
    execution loop which runs until the client is finished, an error
    occurs or the server is stopped (isRunning() returns false)
   */
  virtual void handleConnection(tcp::socket sock) = 0;

  /* Returns if the server is still running or a stop request was
     sent. To be polled by work loops */
  bool isRunning() const { return m_running; }

  /* Sends stop signal; implementations should stop execution at earliest
   * convenience */
  void stop() { m_running = false; }
  UsbDev &usb() { return m_usbDevice; }
  uint16_t port() const { return m_port; }
  boost::asio::io_service &io_service() { return m_io_service; }

  /* run the server loop */
  void run() {
    acceptConnection();
    m_io_service.run();

    if (m_connectionThread.joinable())
      m_connectionThread.join();
  }

protected:
  const char *logger() const { return m_loggerName.c_str(); }

  void readFromUsb(tcp::socket &sock, bool &running, uint8_t epOut) {
    UsbDev::DataBuffer data(DATA_BUFFER_SIZE);
    std::chrono::time_point<std::chrono::steady_clock> start, end;
    size_t bytesSent = 0;
    start = std::chrono::steady_clock::now();

    while (isRunning() && running) {

      CVLOG(9, logger()) << "Start Read From Usb";
      data.resize(DATA_BUFFER_SIZE);
      int actualRead = usb().readData(epOut, data, CONTROL_READ_TIMEOUT);
      data.resize(static_cast<size_t>(actualRead));
      CVLOG(9, logger()) << format("Finished Read From Usb, read: %d bytes") %
                                actualRead;

      if (VLOG_IS_ON(2)) {
        bytesSent += actualRead;
        end = std::chrono::steady_clock::now();
        if (std::chrono::duration_cast<std::chrono::seconds>(end - start)
                .count() > 0) {
          double MBSent = bytesSent / (1024.0 * 1024.0);
          CVLOG_IF(bytesSent > 0, 2, logger())
              << format("Port %d Send: %d MB") % port() % MBSent;
          bytesSent = 0;
          start = end;
        }
      }

      if (VLOG_IS_ON(9) && !data.empty()) {
        CVLOG(9, logger()) << format("Read %d bytes from USB") % data.size();
      }

      if (!data.empty()) {
        CVLOG(9, logger()) << "Write data to socket";
        writeToSocket(sock, data);
        CVLOG(9, logger()) << "Finished writing to socket";
      }
    }
  }

  /* Read Data from a socket connection */
  boost::system::error_code readFromSocket(tcp::socket &sock,
                                           UsbDev::DataBuffer &data) {
    std::promise<boost::system::error_code> bytesReadPromise;
    auto bytesReadFuture = bytesReadPromise.get_future();
    sock.async_read_some(boost::asio::buffer(data),
                         [&](const boost::system::error_code &ec,
                             std::size_t bytes_transferred) {
      std::lock_guard<std::mutex> lock(m_dataMutex);
      if (isRunning()) {
        data.resize(bytes_transferred);
      }
      bytesReadPromise.set_value(ec);
    });

    std::future_status status;
    do {
      status = bytesReadFuture.wait_for(std::chrono::milliseconds(500));
      if (status != std::future_status::ready && !isRunning()) {
        std::lock_guard<std::mutex> lock(m_dataMutex);
        data.resize(0);
        return boost::system::error_code();
      }
    } while (status != std::future_status::ready);

    return bytesReadFuture.get();
  }

private:
  /*! Accepts a connection. When a client connects, blocks until the
      client is handled and then waits for the next connection */
  void acceptConnection() {
    if (isRunning()) {
      CLOG(INFO, logger()) << str(format(
                                      "Wait for connection on port %d (%d)") %
                                  m_port % m_running);

      m_acceptor.async_accept(m_socket, [this](boost::system::error_code ec) {
        try {
          boost::asio::detail::throw_error(ec);

          if (m_connectionThread.joinable())
            m_connectionThread.join();

          m_connectionThread =
              std::thread([this]() {
                CLOG(INFO, logger())
                    << str(format("Connection established on port %d") %
                           m_port);
                try {
                  handleConnection(std::move(m_socket));
                }
                catch (std::exception const &e) {
                  CLOG(ERROR, logger())
                      << format("Execption in handleConnection (what: %s") %
                             e.what();
                }
                CLOG(INFO, logger()) << "Connection closed";
                // Wait for next connection
                if (isRunning()) {
                  try {
                    usb().checkDeviceStatus();
                    acceptConnection();
                  }
                  catch (std::exception const &e) {
                    CLOG(ERROR, logger())
                        << format("Error while checking device Status: %s") %
                               e.what();
                    stop();
                    m_io_service.stop();
                  }
                }
              });
        }
        catch (std::exception const &e) {
          CLOG(ERROR, logger())
              << format("Socket listener returned with error: %s") % e.what();
        }
      });
    }
  }

  /* Writes Data to a socket connection */
  void writeToSocket(tcp::socket &sock, UsbDev::DataBuffer const &data) {
    // write to socket
    if (!data.empty()) {
      // write data to socket
      size_t dataSize = data.size();
      std::promise<size_t> writePromise;
      std::future<size_t> writeFuture = writePromise.get_future();

      boost::asio::async_write(sock, boost::asio::buffer(data),
                               [&writePromise, this, dataSize](
                                   const boost::system::error_code &ec,
                                   std::size_t bytes_transferred) {
        try {
          boost::asio::detail::throw_error(ec);
          writePromise.set_value(bytes_transferred);
          CVLOG(9, logger()) << format("Written to socket: %d bytes") %
                                    bytes_transferred;
        }
        catch (std::exception const &e) {
          CVLOG(2, logger())
              << format("async_write stopped due to exception: %s") % e.what();
          writePromise.set_exception(std::current_exception());
          CLOG_IF(bytes_transferred < dataSize, WARNING, logger())
              << format("Socket error on write, written: %d/%d, %d bytes "
                        "dropped") %
                     bytes_transferred % dataSize %
                     (dataSize - bytes_transferred);
        }
      });

      std::future_status status;
      do {
        status = writeFuture.wait_for(std::chrono::milliseconds(500));
      } while (status != std::future_status::ready && isRunning());

      if (status == std::future_status::ready) {
        writeFuture.get();
      }
    }
  }

  UsbDev &m_usbDevice;
  boost::asio::io_service &m_io_service;
  uint16_t m_port;
  tcp::acceptor m_acceptor;
  tcp::socket m_socket;
  bool m_running;
  std::string m_loggerName;

  std::thread m_connectionThread;
  std::mutex m_dataMutex;
};

/* Implementation of UsbServer, handling the Control endpoints.

   Control uses a single Socket, forwards incomming traffic to the USB
   Endpoint for Input, and sends Control Output from the USB Output
   endpoint to the socket.
 */
class UsbControlServer : public UsbServer {
public:
  /*! Construct the control server, listining to a port for the
      network and endpointIn + endpointOut for the Usb */
  UsbControlServer(UsbDev &usb, uint8_t endpointIn, uint8_t endpointOut,
                   boost::asio::io_service &io_service, size_t port)
      : UsbServer(usb, io_service, port, str(format("ctrl_%d") % port)),
        m_endpointIn(endpointIn), m_endpointOut(endpointOut) {}
  ~UsbControlServer() = default;

  /*! Runs the connection loop.  Manages two execution loops in
    different threads, one for handling Socket -> Usb, the other for
    handling Usb -> Socket traffic.
   */
  virtual void handleConnection(tcp::socket sock) {

    bool controlRunning = true;

    // Thread for control write

    std::thread writeControl([&]() {
      CVLOG(9, logger()) << "Start write control thread";
      try {
        UsbDev::DataBuffer dataIn(CONTROL_BUFFER_SIZE);
        UsbDev::DataBuffer dataUsb;
        UsbDev::DataBuffer incompleteWord;
        std::chrono::time_point<std::chrono::steady_clock> start, end;
        size_t bytesSent = 0;

        std::chrono::time_point<std::chrono::steady_clock> writeTimer =
            std::chrono::steady_clock::now();

        while (isRunning() && controlRunning) {

          // read from Socket
          CVLOG(9, logger()) << "Read data from Socket";
          dataIn.resize(CONTROL_BUFFER_SIZE);
          boost::system::error_code ec = readFromSocket(sock, dataIn);
          CVLOG(9, logger()) << format("Received %d bytes") % dataIn.size();

          if (ec) {
            CVLOG(2, logger())
                << format("Error while calling Socket read: %s. "
                          "Shutting down connection after Usb transfer") %
                       ec.message();
          }

          dataUsb.assign(incompleteWord.begin(), incompleteWord.end());
          dataUsb.insert(dataUsb.end(), dataIn.begin(), dataIn.end());

          // only write a multiple of Controlword size to Usb
          // store the rest in a temporary buffer (for next read)
          size_t incomplete = dataUsb.size() % CONTROL_WORD_SIZE;
          if (incomplete > 0) {
            incompleteWord.assign(dataUsb.end() - incomplete, dataUsb.end());
            dataUsb.resize(dataUsb.size() - incomplete);
          }

          // Write data to usb device. If not transmitted in one
          // transfer, send all chunks until the data buffer is empty
          try {
            CVLOG(9, logger()) << format(
                                      "Start Usb Write transfer (%d bytes)") %
                                      dataUsb.size();
            while (isRunning() && controlRunning && !dataUsb.empty()) {
              CVLOG(9, logger()) << "Write chunk";
              CLOG_IF(dataUsb.size() % 4 > 0, ERROR, logger())
                  << "Write non modulo 4 byte to usb";
              using namespace std::chrono;
              if (steady_clock::now() < writeTimer) {
                std::this_thread::sleep_until(writeTimer);
              }
              int chunk =
                  usb().writeData(m_endpointIn, dataUsb, CONTROL_WRITE_TIMEOUT);
              writeTimer = steady_clock::now() + USB_WRITE_WAIT_TIME;

              if (VLOG_IS_ON(9)) {
                CVLOG(9, logger()) << format("Wrote %d/%d bytes") % chunk %
                                          dataUsb.size();
              }

              if (VLOG_IS_ON(2)) {
                bytesSent += chunk;
                end = std::chrono::steady_clock::now();
                if (std::chrono::duration_cast<std::chrono::seconds>(
                        end - start).count() > 0) {
                  double MBSent = bytesSent / (1024.0 * 1024.0);
                  CVLOG_IF(bytesSent > 0, 2, logger())
                      << format("Data sent to EP %d: %d MiB") %
                             (int)m_endpointOut % MBSent;
                  bytesSent = 0;
                  start = end;
                }
              }

              dataUsb.assign(dataUsb.begin() + chunk, dataUsb.end());
            }
            CVLOG(9, logger()) << "Write Usb transfer finished";
          }
          catch (std::exception const &e) {
            CLOG(ERROR, logger())
                << format("Error while writing to USB: %m. - Shutdown Write") %
                       e.what();
            CLOG_IF(!dataUsb.empty(), WARNING, logger())
                << format("USB Error while writing to USB, not all data "
                          "transferred, missing: %d bytes") %
                       dataUsb.size();
            controlRunning = false;
          }
          catch (...) {
            CLOG(ERROR, logger())
                << "Unknown Error while writing to USB. - Shutdown Write";
            controlRunning = false;
          }
          if (ec) {
            CVLOG(9, logger())
                << "Shut down Socket due to earlier socket error";
            controlRunning = false;
          }
        }
      }
      catch (std::exception const &e) {
        CLOG(ERROR, logger()) << format("Error in ControlWrite: %s") % e.what();
        controlRunning = false;
        CVLOG(9, logger()) << "Shutdown socket from Write Thread";
        boost::system::error_code ec;
        sock.shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);
        if (ec) {
          CVLOG(2, logger()) << format("Closing socket failed with error: %s") %
                                    ec.message();
        }
      }
      catch (...) {
        CLOG(ERROR, logger()) << "Unknown error in ControlWrite";
      }
      CVLOG(9, logger()) << "Close Write Control thread";
    });

    // Control read in this thread
    try {
      CVLOG(9, logger()) << "Start read Control Thread";
      readFromUsb(sock, controlRunning, m_endpointOut);
    }

    catch (std::exception const &e) {
      CLOG(ERROR, logger()) << format("Error in Read: %s") % e.what();
      controlRunning = false;
    }
    CVLOG(9, logger()) << "Shutdown socket";
    boost::system::error_code ec;
    sock.shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);
    if (ec) {
      CVLOG(2, logger()) << format("Closing socket failed with error: %s") %
                                ec.message();
    }

    CVLOG(9, logger()) << "Wait for Write Control thread to finish";
    writeControl.join();
    sock.close(ec);
    CVLOG(9, logger()) << "Close Read Control thread";
    if (ec) {
      CVLOG(2, logger()) << format("Close socket failed with error: %s") %
                                ec.message();
    }
  }

private:
  uint8_t m_endpointIn;
  uint8_t m_endpointOut;
};

/*! Implementation of UsbServer, handling Data Endpoint connections.

  Server listens to a single endpoint and socket, sending all data
  receiving from the endpoint to the socket.
 */
class UsbDataServer : public UsbServer {
public:
  /* Construct the UsbdataServer with a given endpoint and socket */
  UsbDataServer(UsbDev &usb, uint8_t endpoint,
                boost::asio::io_service &io_service, size_t port)
      : UsbServer(usb, io_service, port, str(format("data_%d") % port)),
        m_endpointOut(endpoint) {}

  ~UsbDataServer() = default;

  virtual void handleConnection(tcp::socket sock) {
    bool running = true;

    CVLOG(9, logger()) << "Start read data";
    readFromUsb(sock, running, m_endpointOut);
    CVLOG(9, logger()) << "Read data finished";
    boost::system::error_code ec;
    sock.shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);
    if (ec) {
      CVLOG(2, logger()) << format("Shutdown socket failed with error: %s") %
                                ec.message();
    }
    sock.close(ec);
    if (ec) {
      CVLOG(2, logger()) << format("Close socket failed with error: %s") %
                                ec.message();
    }
  }

private:
  uint8_t m_endpointOut;
};

// Return codes
namespace {
const size_t SUCCESS = 0;
const size_t SUCCESS_HELP = 1;
const size_t ERROR_IN_COMMAND_LINE = 2;
const size_t ERROR_EXCEPTION = 3;

} // namespace

/* Application configuration */
struct appConfig {
  uint16_t controlPort, data0Port, data1Port;
  int interface, vid, pid;
  uint16_t epCtlOut, epCtlIn, epData0In, epData1In;
  std::string serialNumber;
  appConfig()
      : controlPort(0), data0Port(0), data1Port(0), interface(0), vid(0),
        pid(0), epCtlOut(0), epCtlIn(0), epData0In(0), epData1In(0) {}
};

int parseCmdOptions(int argc, char **argv, appConfig &config);

int main(int argc, char **argv) {

  try {

    // Setup logging
    START_EASYLOGGINGPP(argc, argv);
    el::Configurations defaultConf;
    defaultConf.setToDefault();
    defaultConf.set(el::Level::Global, el::ConfigurationType::Format,
                    "%datetime [%logger] %level - %msg");
    defaultConf.set(el::Level::Verbose, el::ConfigurationType::Format,
                    "%datetime [%logger] %level-%vlevel - Line %line - %msg");

    el::Loggers::reconfigureAllLoggers(defaultConf);

    appConfig config;

    int ret = parseCmdOptions(argc, argv, config);
    if (ret != SUCCESS) {
      if (ret == SUCCESS_HELP)
        return SUCCESS;
      return ret;
    }
    el::Loggers::getLogger("main");

    CVLOG(9, "main") << "Loggers configured";

    CLOG(INFO, "main") << "Starting application with following parameters set";
    CLOG(INFO, "main")
        << format("Network Ports: Control(%d), Data0(%d), Data1(%d)") %
               config.controlPort % config.data0Port % config.data1Port;
    CLOG(INFO, "main")
        << format("Usb Device: VID(%04X), PID(%04X), Interface(%d)") %
               config.vid % config.pid % config.interface;
    CLOG(INFO, "main")
        << format("Endpoints: Control Out(%d), Control In(%d), Data0 "
                  "In(%d), Data1 In(%d)") %
               config.epCtlOut % config.epCtlIn % config.epData0In %
               config.epData1In;
    if(!config.serialNumber.empty())
        CLOG(INFO, "main")
            << "Serial Number: " << config.serialNumber;

    // Create Usb device object and boost Io service (network)
    UsbDev usb(config.vid, config.pid, config.interface, config.serialNumber);
    boost::asio::io_service io_service;
    boost::asio::io_service::work work(io_service);

    /* Server list.

       Create a unique_ptr<UsbServer> for each server to run.
     */
    auto servers = { std::unique_ptr<UsbServer>(new UsbControlServer(
                         usb, config.epCtlIn, config.epCtlOut, io_service,
                         config.controlPort)),
                     std::unique_ptr<UsbServer>(new UsbDataServer(
                         usb, config.epData0In, io_service, config.data0Port)),
                     std::unique_ptr<UsbServer>(
                         new UsbDataServer(usb, config.epData1In, io_service,
                                           config.data1Port)) };

    bool stopProg = false;

    // Run a thread for each server, start server in thread.
    std::vector<std::thread> threads;
    for (auto &serv : servers) {
      threads.emplace_back([&serv, &stopProg]() {
        try {
          serv->run();

          CLOG(INFO, "main") << "thread stopped";
        }
        catch (std::exception &e) {
          CLOG(WARNING, "main")
              << format("Thread stopped with execption. (what: %s)") % e.what();
        }
        stopProg = true;
      });
    }

    // start a thread for running a seperate network loop
    // threads.emplace_back([&io_service](){io_service.run()});

    std::thread consolInputThread([&stopProg]() {
      // Wait for stop signal
      CLOG(INFO, "main") << "Wait for stop";
      std::string stop;
      std::getline(std::cin, stop);

      stopProg = true;
    });

    // watchdog for usb device
    std::thread usbWatchDog([&usb, &stopProg]() {
      try {
        while (!stopProg) {
          std::this_thread::sleep_for(std::chrono::milliseconds(1000));
          if (!stopProg)
            usb.checkDeviceStatus(true);
        }
      }
      catch (std::exception &e) {
        CLOG(INFO, "main") << "Usb watchdog recognized invalid connection, "
                              "stopped application";
        stopProg = true;
      }
    });

    while (stopProg == false) {
      std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }

    CLOG(INFO, "main") << "Stopping Servers and waiting to close";
    // Stop servers and wait for threads to finish
    for (auto &serv : servers) {
      serv->stop();
    }

    io_service.stop();

    for (auto &thread : threads) {
      thread.join();
    }

    consolInputThread.detach();
    usbWatchDog.join();

    CLOG(INFO, "main") << "Application closed";
  }
  catch (std::exception const &e) {
    CLOG(ERROR, "main")
        << format("Unhandled exception reached top of main (what: %s). "
                  "Application stopped") %
               e.what();
    return ERROR_EXCEPTION;
  }
  catch (...) {
    CLOG(ERROR, "main") << "Unknown unhandled exception reached top of main. "
                           "Application stopped";
    return ERROR_EXCEPTION;
  }

  return SUCCESS;
}

/* Create Options menu, fill appConfig structure with loaded or default options
 */
int parseCmdOptions(int argc, char **argv, appConfig &config) {

  std::string strVid = str(format("%04X") % VID);
  std::string strPid = str(format("%04X") % PID);
  namespace po = boost::program_options;
  po::options_description desc("Basic options");
  desc.add_options()("help,h", "Print this help message")(
      "verbose,v", "Enable Verbose output")(
      "v", po::value<int>(), "Verbose output up to level x (call with --v=x)");

  po::options_description network("Network");
  network.add_options()("port_control", po::value<uint16_t>(&config.controlPort)
                                            ->default_value(PORT_CONTROL),
                        "Port for control communication")(
      "port_data0",
      po::value<uint16_t>(&config.data0Port)->default_value(PORT_DATA_0),
      "Port for Data communication on Dataport 0")(
      "port_data1",
      po::value<uint16_t>(&config.data1Port)->default_value(PORT_DATA_1),
      "Port for Data communication on Dataport 1");

  po::options_description usbOpt("Usb Device options");
  usbOpt.add_options() // options
      ("vendor_id", po::value<std::string>(&strVid)->default_value(strVid),
       "Vendor Id") // VID
      ("product_id", po::value<std::string>(&strPid)->default_value(strPid),
       "Product Id") // PID
      ("interface",
       po::value<int>(&config.interface)->default_value(INTERFACE_NUMBER),
       "Interface number") // IF
      ("serial_number", po::value<std::string>(&config.serialNumber)
                            ->default_value(std::string()),
       "Serial number") // Serial Number
      ("endpoint_control_out",
       po::value<uint16_t>(&config.epCtlOut)->default_value(EP_CTL_OUT),
       "Control endpoint OUT (write)") // EP ctrl out
      ("endpoint_control_in",
       po::value<uint16_t>(&config.epCtlIn)->default_value(EP_CTL_IN),
       "Control endpoint IN (read)") // EP ctrl in
      ("endpoint_data0_in",
       po::value<uint16_t>(&config.epData0In)->default_value(EP_DATA0_IN),
       "Data endpoint 0 IN (read)") // EP data0 in
      ("endpoint_data1_in",
       po::value<uint16_t>(&config.epData1In)->default_value(EP_DATA1_IN),
       "Data endpoint 1 IN (read)"); // EP data1 in

  po::options_description cmdline_options;
  cmdline_options.add(desc).add(network).add(usbOpt);

  po::variables_map vm;
  try {
    po::parsed_options parsed = po::command_line_parser(argc, argv)
                                    .options(cmdline_options)
                                    .allow_unregistered()
                                    .run();
    po::store(parsed, vm); // can throw

    /** --help option
     */
    if (vm.count("help")) {
      std::cout << "Usb Communication module" << std::endl << cmdline_options
                << std::endl;
      return SUCCESS_HELP;
    }
    po::notify(vm); // throws on error, so do after help in case
                    // there are any problems

    try {
      config.vid = std::stoul(strVid, 0, 16);
    }
    catch (std::exception const &e) {
      CLOG(ERROR, "main") << format("Could not convert VID to int (%s)") %
                                 strVid;
      return ERROR_IN_COMMAND_LINE;
    }
    try {
      config.pid = std::stoul(strPid, 0, 16);
    }
    catch (std::exception const &e) {
      CLOG(ERROR, "main") << format("Could not convert PID to int (%s)") %
                                 strPid;
      return ERROR_IN_COMMAND_LINE;
    }
  }
  catch (po::error const &e) {
    std::cout << "ERROR: " << e.what() << std::endl << std::endl;
    std::cout << desc << std::endl;
    return ERROR_IN_COMMAND_LINE;
  }
  return SUCCESS;
}
