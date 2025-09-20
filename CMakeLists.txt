cmake_minimum_required(VERSION 3.16)
project(Joycon2BLEViewer)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ビルドタイプに応じて定義を追加
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-DDEBUG)
endif()

# Find Core Bluetooth framework
find_library(CORE_BLUETOOTH CoreBluetooth REQUIRED)
find_library(FOUNDATION Foundation REQUIRED)

# Source files
set(SOURCES
    src/main.mm
    src/Joycon2BLEViewer.mm
)

# Include directories
include_directories(include)

# Create executable
add_executable(Joycon2BLEViewerApp ${SOURCES})

# Link libraries
target_link_libraries(Joycon2BLEViewerApp
    ${CORE_BLUETOOTH}
    ${FOUNDATION}
)