find_package(Boost COMPONENTS unit_test_framework program_options system REQUIRED)
find_package(Git QUIET)
find_package(FairRoot)
find_package(Monitoring REQUIRED)
find_package(Configuration REQUIRED)
find_package(Common REQUIRED)
find_package(InfoLogger REQUIRED)
find_package(ReadoutCard REQUIRED)
find_package(DataSampling REQUIRED)
find_package(ZeroMQ REQUIRED)

if (NOT ZeroMQ_INCLUDE_DIR)
    set(ZeroMQ_INCLUDE_DIR ${ZEROMQ_INCLUDE_DIR})
    set(ZeroMQ_LIBRARIES ${ZEROMQ_LIBRARIES})
endif ()

if (FAIRROOT_FOUND)
    # this should go away when fairrot provides a proper Find script or proper config scripts
    # See : http://www.cmake.org/cmake/help/v3.0/command/link_directories.html
    link_directories(${FAIRROOT_LIBRARY_DIR})
    set(FAIRROOT_LIBRARIES Base FairMQ BaseMQ)
    ADD_DEFINITIONS(-DWITH_FAIRMQ)
else (FAIRROOT_FOUND)
    message(WARNING "FairRoot not found, corresponding classes will not be compiled.")
endif (FAIRROOT_FOUND)

ADD_DEFINITIONS(-DWITH_DATASAMPLING)

o2_define_bucket(
        NAME
        o2_readout_bucket

        DEPENDENCIES
        pthread
        ${Boost_LOG_LIBRARY}
        ${Boost_THREAD_LIBRARY}
        ${Boost_SYSTEM_LIBRARY}
        ${Boost_PROGRAM_OPTIONS_LIBRARY}
        ${Configuration_LIBRARIES}
        ${Monitoring_LIBRARIES}
        ${Common_LIBRARIES}
        ${InfoLogger_LIBRARIES}
        ${ReadoutCard_LIBRARIES}
        ${DataSampling_LIBRARIES}

        SYSTEMINCLUDE_DIRECTORIES
        ${Boost_INCLUDE_DIRS}
        ${Monitoring_INCLUDE_DIRS}
        ${InfoLogger_INCLUDE_DIRS}
        ${ReadoutCard_INCLUDE_DIRS}
        ${DataSampling_INCLUDE_DIRS}
        ${Configuration_INCLUDE_DIRS}
)


o2_define_bucket(
        NAME
        o2_readout_with_fair

        DEPENDENCIES
        o2_readout_bucket
        ${FAIRROOT_LIBRARIES}
        ${ROOT_LIBRARIES}

        SYSTEMINCLUDE_DIRECTORIES
        ${FAIRROOT_INCLUDE_DIR}
        ${FAIRROOT_INCLUDE_DIR}/fairmq
)

