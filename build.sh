#!/bin/bash

# Joy-Con2 BLE Client Build Script
# This script automates the build process for the Joy-Con2 BLE Client project

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're in the project root directory
if [ ! -f "CMakeLists.txt" ]; then
    print_error "CMakeLists.txt not found. Please run this script from the project root directory."
    exit 1
fi

# Parse command line arguments
CLEAN=false
BUILD_TYPE="Release"

while [[ $# -gt 0 ]]; do
    case $1 in
        clean)
            CLEAN=true
            shift
            ;;
        debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        release)
            BUILD_TYPE="Release"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  clean     Clean build directory before building"
            echo "  debug     Build in Debug mode"
            echo "  release   Build in Release mode (default)"
            echo "  -h, --help Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use '$0 --help' for usage information."
            exit 1
            ;;
    esac
done

# Clean build directory if requested
if [ "$CLEAN" = true ]; then
    print_status "Cleaning build directory..."
    rm -rf build
    print_success "Build directory cleaned."
fi

# Create build directory if it doesn't exist
if [ ! -d "build" ]; then
    print_status "Creating build directory..."
    mkdir -p build
    print_success "Build directory created."
fi

# Change to build directory
cd build

# Run CMake
print_status "Running CMake with build type: $BUILD_TYPE..."
if ! cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE ..; then
    print_error "CMake configuration failed."
    exit 1
fi
print_success "CMake configuration completed."

# Run make
print_status "Building project..."
if ! make -j$(sysctl -n hw.ncpu 2>/dev/null || echo 4); then
    print_error "Build failed."
    exit 1
fi
print_success "Build completed successfully!"

# Check if executable exists
if [ -f "Joycon2BLEViewerApp" ]; then
    print_success "Executable created: $(pwd)/Joycon2BLEViewerApp"
    print_status "You can run the application with: ./Joycon2BLEViewerApp"
else
    print_error "Executable not found after build."
    exit 1
fi

print_success "Build script completed successfully!"