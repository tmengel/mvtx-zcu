cmake_minimum_required (VERSION 2.6)

project (event_filter)

find_package(Threads REQUIRED)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")
set(EASYLOGGING_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/easylogging)


find_package(Boost REQUIRED COMPONENTS
    system
    date_time
    thread
    iostreams)
include_directories(${EASYLOGGING_INCLUDE})
include_directories(${BOOST_INCLUDE_DIRS})
MESSAGE ( STATUS "BOOST INCLUDE DIRS: ${BOOST_INCLUDE_DIRS}")

add_executable(event_filter event_filter.cpp AlpideDecoder.cpp)
target_link_libraries(event_filter ${Boost_LIBRARIES})
if(THREADS_HAVE_PTHREAD_ARG)
  target_compile_options(event_filter PUBLIC "-pthread")
endif()
if(CMAKE_THREAD_LIBS_INIT)
  target_link_libraries(event_filter "${CMAKE_THREAD_LIBS_INIT}")
endif()
