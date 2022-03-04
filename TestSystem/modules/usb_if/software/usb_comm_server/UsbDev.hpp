//-----------------------------------------------------------------------------
// Title      : Usb Device abstraction
// Project    : ALICE ITS WP10
//-----------------------------------------------------------------------------
// File       : UsbDev.hpp
// Author     : Matthias Bonora (matthias.bonora@cern.ch)
// Company    : CERN / University of Salzburg
// Created    : 2015-11-26
// Last update: 2015-11-26
// Platform   : CERN 7 (CentOs)
// Target     : Linux / Windows
// Standard   : C++11
//-----------------------------------------------------------------------------
// Description: simple Class abstraction of libusb library
//-----------------------------------------------------------------------------
// Copyright (c)   2015
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author        Description
// 2015-11-26  1.0      mbonora        Created
//-----------------------------------------------------------------------------

#pragma once

#include <algorithm>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include <boost/format.hpp>

// logging
#define ELPP_THREAD_SAFE
#define ELPP_FORCE_USE_STD_THREAD
#include "easylogging/easylogging++.h"

// libusb
#ifdef _WIN32
#include <libusb/libusb.h>
#else
#include <libusb-1.0/libusb.h>
#endif // _WIN32

/*! Device abstraction for Usb connection
  Encapsulates Device handles, performes allocation and deallocation,
  provides functions to read/write from an endpoint
*/
class UsbDev {
public:
  UsbDev(size_t VID, size_t PID, int interface, std::string serialNumber)
      : m_VID(VID), m_PID(PID), m_interface(interface),
        m_serialNumber(serialNumber), m_deviceConnected(false),
        m_ctx(0, libusb_exit),
        m_device(0, std::bind(&UsbDev::closeDevice, this, _1)) {

    el::Loggers::getLogger("usb");
    initLibUsb();
    initDevice();
    claimInterface();
  }

  typedef std::vector<unsigned char> DataBuffer;

  /*! Read Data from Usb Endpoint and write it to DataBuffer

    \param endpoint Endpoint number

    \param data The data buffer. Initial size describes the data size
                to read from usb. After the tranfer, the buffer is
                resized to the actual size read.

    \throw Exception if an error occures (Timeout does not count as error)
   */
  int readData(uint8_t endpoint, DataBuffer &data, size_t timeout) {
    int actualRead = 0;
    int ret =
        libusb_bulk_transfer(m_device.get(), (endpoint | LIBUSB_ENDPOINT_IN),
                             &data.front(), data.size(), &actualRead, timeout);

    CVLOG(8, "usb") << boost::format(
                           "libusb read transfer: Endpoint: %d, "
                           "data: %d bytes, read: %d bytes, return: %s") %
                           (int)endpoint % data.size() % actualRead %
                           libusb_error_name(ret);

    if (!(ret == 0 || ret == LIBUSB_ERROR_TIMEOUT)) {
      checkError(ret);
    }
    return actualRead;
  }

  /*! Write Data to USB endpoint
    \param endpoint Endpoint number

    \param data The data buffer. Initial size describes the data size
                to write to usb.

    \return the actual number of bytes written to usb
    \throw Exception if an error occures
   */
  int writeData(uint8_t endpoint, DataBuffer &data, size_t timeout) {
    int actualWritten = 0;

    int ret = libusb_bulk_transfer(
        m_device.get(), (endpoint | LIBUSB_ENDPOINT_OUT), &data.front(),
        data.size(), &actualWritten, timeout);

    CVLOG(8, "usb")
        << boost::format("libusb write transfer: Endpoint: %d, "
                         "data: %d bytes, written: %d bytes, return code: %s") %
               (int)endpoint % data.size() % actualWritten %
               libusb_error_name(ret);

    if (!(ret == 0 || ret == LIBUSB_ERROR_TIMEOUT)) {
      checkError(ret);
    }
    return actualWritten;
  }

  /*! Checks and updates the status of the USB device.
    Checks if the device is still connected properly. If not, attempts to
    reconnect the device.
    \param active Actively check device status (dedicated function call). If
    false, relies on previous error codes
    \throw Exeception if device can't be reconnected.
   */
  void checkDeviceStatus(bool activeCheck = false) {
    std::lock_guard<std::recursive_mutex> lock(m_reconnectMutex);

    if (activeCheck) {
      int retCode = libusb_kernel_driver_active(m_device.get(), m_interface);
      if (retCode == LIBUSB_ERROR_NO_DEVICE) {
        m_deviceConnected = false;
      }
    }

    if (!m_deviceConnected) {
      // Try to reconnect device
      CLOG(WARNING, "usb") << "Device disconnected, attempting to reconnect";
      libusb_device_handle *p = m_device.release();
      libusb_close(p); // close

      initDevice();
    }
  }

private:
  size_t m_VID;
  size_t m_PID;
  int m_interface;
  std::string m_serialNumber;
  bool m_deviceConnected;
  std::recursive_mutex m_reconnectMutex;

  /*! Pointer Handle for usb context. Calls libusb_exit on destruction*/
  std::unique_ptr<libusb_context, decltype(&libusb_exit)> m_ctx;

  /*! Pointer Handle for device. On destruction releases the interface and
   * closes the device*/
  std::unique_ptr<libusb_device_handle,
                  std::function<void(libusb_device_handle *)> > m_device;

  /*! Closes device connection.
     This includes releasing the interface and deleting the device handle
   */
  void closeDevice(libusb_device_handle *dev_handle) {
    if (dev_handle != nullptr) {
      int ret = libusb_release_interface(dev_handle, m_interface);
      if (ret != 0) {
        // could not release
        CLOG(ERROR, "usb")
            << format("Could not release Usb Interface (Errorcode: %d)") % ret;
      }
      libusb_close(dev_handle); // close
      CLOG(INFO, "usb") << "Usb Device closed";
    }
  }

  /*! Initialize libUsb environment */
  void initLibUsb() {
    libusb_context *ctx = NULL;
    // Initialize libusb context
    checkError(libusb_init(&ctx));
    m_ctx.reset(ctx);

    if (VLOG_IS_ON(9)) {
      libusb_set_debug(ctx, 4);
    }
  }

  /*! Initializes the USB device */
  void initDevice() {
    libusb_device_handle *dev_handle;

    if (m_serialNumber.empty()) {
      // open device with correct VID and PID
      dev_handle = libusb_open_device_with_vid_pid(m_ctx.get(), m_VID, m_PID);
      if (dev_handle == NULL) {
        throw std::runtime_error(
            str(format("Could not open device with VID = %04X and PID=%04X") %
                m_VID % m_PID));
      }
      m_device.reset(dev_handle);
    } else {
      findDevice();
    }
    m_deviceConnected = true;
  }

  /* Find device with VID, PID and serial number.
     Throw runtime_error if not found.
     Throw runtime_error on usb errors.
     return libusb_device_handle * to correct device
   */
  void findDevice() {
    libusb_device **list = NULL;

    try {
      bool deviceFound = false;
      size_t nrDevices = libusb_get_device_list(m_ctx.get(), &list);
      if (nrDevices < 0) {
        checkError(nrDevices);
      } else {
        CVLOG(1, "usb") << boost::format("Found %d Usb devices") % nrDevices;
      }

      for (size_t idx = 0; idx < nrDevices && !deviceFound; ++idx) {
        libusb_device *device = list[idx];
        libusb_device_descriptor desc = { 0 };
        libusb_device_handle *dev_handle;

        checkError(libusb_get_device_descriptor(device, &desc));

        if (desc.idVendor == m_VID && desc.idProduct == m_PID) {

          checkError(libusb_open(device, &dev_handle));
          m_device.reset(dev_handle);

          size_t maxLen = 256;
          std::string str;
          if (desc.iSerialNumber > 0) {
            std::vector<unsigned char> dataVec(maxLen);
            size_t len = libusb_get_string_descriptor_ascii(
                m_device.get(), desc.iSerialNumber, &dataVec.front(), maxLen);
            if (len < 0) {
              checkError(len);
            } else {
              dataVec.resize(len);
              str.assign(dataVec.begin(), dataVec.end() - 1);
            }
          }
          CVLOG(6, "usb")
              << boost::format(
                     "Device: VID: %04x, PID: %04x, serial number: %s") %
                     desc.idVendor % desc.idProduct % str;

          if (m_serialNumber == str) {

            CLOG(INFO, "usb") << boost::format(
                                     "Found device matching "
                                     "VID=%04x, PID=%04x, serialNumber=%s") %
                                     m_PID % m_VID % m_serialNumber;
            deviceFound = true;
          }
        }
      }
      if (!deviceFound) {
        throw std::runtime_error(
            str(format("Could not open device with VID = %04X, PID=%04X and "
                       "serial number = %s") %
                m_VID % m_PID % m_serialNumber));
      }
      libusb_free_device_list(list, 0);
    }
    catch (std::runtime_error &e) {
      libusb_free_device_list(list, 0);
      throw e;
    }
  }

  /*! Claims the usb interface; if required, detaches a kernel driver */
  void claimInterface() {
    if (libusb_kernel_driver_active(m_device.get(), m_interface) == 1) {
      checkError(libusb_detach_kernel_driver(m_device.get(), 0));
    }

    checkError(libusb_claim_interface(m_device.get(), m_interface));
  }

  /*! Check the return code for errors, throw an exception if the result
    was not OK
   */
  void checkError(int retCode) {
    if (retCode != 0) {
      if (retCode == LIBUSB_ERROR_NO_DEVICE) {
        m_deviceConnected = false;
      }
      throw std::runtime_error(
          str(format("Libusb returned with error code %d") % retCode));
    }
  }
};
