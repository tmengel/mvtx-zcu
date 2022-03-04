cmake_minimum_required (VERSION 2.6)

set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

if (NOT CMAKE_BUILD_TYPE)
  message(STATUS "No build type selected, default to Release")
  set(CMAKE_BUILD_TYPE "Release")
endif()

set(PROJECT_NAME usb_comm)

project (${PROJECT_NAME})

set(BOOST_LIB_LIST system program_options)
set (ADDITIONAL_LIBS pthread)
if(WIN32)
  list(APPEND ADDITIONAL_LIBS ws2_32 wsock32)
  list(APPEND BOOST_LIB_LIST date_time regex)
endif(WIN32)

find_package(Boost
  REQUIRED             # Fail with error if Boost is not found
  COMPONENTS ${BOOST_LIB_LIST} # Boost libraries by their canonical name
  )

find_package(libusb-1.0 MODULE REQUIRED)

set(EASYLOGGING_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/easylogging)
SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -std=c++11" )

#add debug flags for release mode
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -g")

include_directories(${EASYLOGGING_INCLUDE})
include_directories(${EASYLOGGING_INCLUDE})
include_directories(${Boost_INCLUDE_DIRS})
include_directories(${LIBUSB_1_INCLUDE_DIR})

add_executable (${PROJECT_NAME} usb_comm.cpp)

target_link_libraries (${PROJECT_NAME} ${LIBUSB_1_LIBRARIES} 
${Boost_LIBRARIES} ${ADDITIONAL_LIBS})
