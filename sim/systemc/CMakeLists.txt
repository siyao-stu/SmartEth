cmake_minimum_required(VERSION 3.16)
project(smarteth_sc LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# SystemC install prefix (local build)
set(SYSTEMC_HOME "/home/wangsiyao/tools/systemc/install" CACHE PATH "SystemC installation prefix")

find_path(SYSTEMC_INCLUDE_DIR systemc.h
    PATHS ${SYSTEMC_HOME}/include
    NO_DEFAULT_PATH)
find_library(SYSTEMC_LIBRARY systemc
    PATHS ${SYSTEMC_HOME}/lib
    NO_DEFAULT_PATH)

if(NOT SYSTEMC_INCLUDE_DIR OR NOT SYSTEMC_LIBRARY)
    message(FATAL_ERROR "SystemC not found at ${SYSTEMC_HOME}")
endif()

message(STATUS "SystemC include: ${SYSTEMC_INCLUDE_DIR}")
message(STATUS "SystemC library: ${SYSTEMC_LIBRARY}")

set(SOURCES
    src/main.cpp
    src/pcie_bridge.cpp
    src/nic.cpp
    src/reg_block.cpp
    src/dma_engine.cpp
    src/pkt_proc.cpp
)

add_executable(smartnic_sc ${SOURCES})
target_include_directories(smartnic_sc PRIVATE src ${SYSTEMC_INCLUDE_DIR})
target_link_libraries(smartnic_sc PRIVATE ${SYSTEMC_LIBRARY} pthread)

# TLM-2.0 headers are part of SystemC includes
target_compile_definitions(smartnic_sc PRIVATE SC_INCLUDE_DYNAMIC_PROCESSES)
