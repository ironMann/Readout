####################################
# General project definition
####################################

CMAKE_MINIMUM_REQUIRED(VERSION 3.5.2 FATAL_ERROR)

### CMP0025   Compiler id for Apple Clang is now AppleClang.
### CMP0042   MACOSX_RPATH is enabled by default.

FOREACH (p
        CMP0025 # CMake 3.0
        CMP0042 # CMake 3.0
        )
    IF (POLICY ${p})
        cmake_policy(SET ${p} NEW)
    ENDIF ()
endforeach ()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake) # project specific cmake dir
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)

project(Readout)

# Load some basic macros which are needed later on
include(O2Utils)
include(ReadoutDependencies)

# Set the default build type to "RelWithDebInfo"
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "RelWithDebInfo"
            CACHE
            STRING "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel Coverage."
            FORCE)
endif (NOT CMAKE_BUILD_TYPE)

# Set the version number of your project here (format is MAJOR.MINOR.PATCHLEVEL - e.g. 1.0.0)
set(VERSION_MAJOR "0")
set(VERSION_MINOR "0")
set(VERSION_PATCH "0")
set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})

# C++14
IF (CMAKE_VERSION VERSION_LESS 3.1)
    include(CheckCXXCompilerFlag)
    CHECK_CXX_COMPILER_FLAG(-std=c++14 COMPILER_SUPPORTS_CXX14)
    if (COMPILER_SUPPORTS_CXX14)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
    else ()
        message(ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++14 support. Please use a different C++ compiler.")
    endif ()
ELSE ()
    set(CMAKE_CXX_STANDARD 14)  # proper way in CMake >= 3.1
ENDIF ()

# Add compiler flags for warnings and (more importantly) fPIC and debug symbols
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic -Wextra -fPIC")

####################################
# Module, library and executable definition
####################################

set(MODULE_NAME "Readout")

O2_SETUP(NAME ${MODULE_NAME})

set(SRCS
        src/Consumer.cxx
        src/ConsumerStats.cxx
        src/ConsumerFileRecorder.cxx
        src/ConsumerDataChecker.cxx
        src/ConsumerDataSampling.cxx
        #    src/ConsumerFMQ.cxx
        src/ReadoutEquipment.cxx
        src/ReadoutEquipmentDummy.cxx
        src/ReadoutEquipmentRORC.cxx
        src/DataBlockAggregator.cxx
        src/mainReadout.cxx
        src/ReadoutUtils.cxx
        )

include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/../RORC/include
        ${Boost_INCLUDE_DIRS}
        ${Monitoring_INCLUDE_DIRS}
        ${FAIRROOT_INCLUDE_DIR}
        ${FAIRROOT_INCLUDE_DIR}/fairmq
        ${ZeroMQ_INCLUDE_DIR}
        ${Common_INCLUDE_DIRS}
        ${Configuration_INCLUDE_DIRS}
        ${InfoLogger_INCLUDE_DIRS}
        ${ReadoutCard_INCLUDE_DIRS}
)

add_library(
        objReadoutEquipment OBJECT
        src/ReadoutEquipment.cxx
        src/ReadoutEquipmentDummy.cxx
        src/ReadoutEquipmentRORC.cxx
        src/ReadoutEquipmentCruEmulator.cxx
)
add_library(
        objReadoutAggregator OBJECT
        src/DataBlockAggregator.cxx
)
add_library(
        objReadoutUtils OBJECT
        src/ReadoutUtils.cxx
        src/RdhUtils.cxx
        src/CounterStats.cxx
        src/MemoryHandler.cxx
)
set(CONSUMERS_SRCS
        src/Consumer.cxx
        src/ConsumerStats.cxx
        src/ConsumerFileRecorder.cxx
        src/ConsumerDataChecker.cxx
        src/ConsumerDataSampling.cxx
        )
if (FAIRROOT_FOUND)
    list(APPEND CONSUMERS_SRCS src/ConsumerFMQ.cxx)
    list(APPEND CONSUMERS_SRCS src/ConsumerFMQchannel.cxx)
endif ()
add_library(
        objReadoutConsumers OBJECT
        ${CONSUMERS_SRCS}
)


set(LIBRARY_NAME ${MODULE_NAME})
set(BUCKET_NAME o2_readout_bucket)

if (FAIRROOT_FOUND)
    list(APPEND SRCS src/ConsumerFMQ.cxx)
    set(BUCKET_NAME o2_readout_with_fair)
endif ()

O2_GENERATE_LIBRARY()

add_subdirectory(doc)

O2_GENERATE_EXECUTABLE(
        EXE_NAME readout.exe
        SOURCES src/mainReadout.cxx $<TARGET_OBJECTS:objReadoutEquipment> $<TARGET_OBJECTS:objReadoutAggregator> $<TARGET_OBJECTS:objReadoutConsumers> $<TARGET_OBJECTS:objReadoutUtils>
        BUCKET_NAME ${BUCKET_NAME}
)

O2_GENERATE_EXECUTABLE(
        EXE_NAME receiverFMQ.exe
        SOURCES src/receiverFMQ.cxx $<TARGET_OBJECTS:objReadoutUtils>
        BUCKET_NAME ${BUCKET_NAME}
)

O2_GENERATE_EXECUTABLE(
        EXE_NAME testTxFMQ.exe
        SOURCES src/testTxFMQ.cxx $<TARGET_OBJECTS:objReadoutUtils>
        BUCKET_NAME ${BUCKET_NAME}
)

O2_GENERATE_EXECUTABLE(
        EXE_NAME testRxFMQ.exe
        SOURCES src/testRxFMQ.cxx $<TARGET_OBJECTS:objReadoutUtils>
        BUCKET_NAME ${BUCKET_NAME}
)

O2_GENERATE_EXECUTABLE(
        EXE_NAME readRaw.exe
        SOURCES src/readRaw.cxx $<TARGET_OBJECTS:objReadoutUtils>
        BUCKET_NAME ${BUCKET_NAME}
)

# Install some extra files
install(
        FILES readout.cfg
        DESTINATION ${CMAKE_INSTALL_PREFIX}/etc
        PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)

