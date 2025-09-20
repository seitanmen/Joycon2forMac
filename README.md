# Joycon2 BLE Viewer (macOS)

A macOS application that connects to Nintendo Joy-Con 2 controllers via Bluetooth Low Energy (BLE) and displays real-time sensor data.

## Features

- **Real-time Data Display**: Shows live data from Joy-Con controllers including:
  - Button states (A, B, X, Y, L, R, ZL, ZR, etc.)
  - Analog stick positions (Left/Right stick X/Y values)
  - Motion sensors (Accelerometer, Gyroscope)
  - IR camera data (Mouse tracking)
  - Battery voltage and current
  - Temperature sensor
  - Trigger positions

- **Clean Output**: Displays parsed data in a readable format with Python-compatible structure
- **Auto-discovery**: Automatically detects and connects to Joy-Con 2 controllers
- **Cross-platform Compatible**: Data format matches the Python implementation

## Requirements

- **macOS 10.15 or later**
- **Xcode Command Line Tools** (for compilation)
- **CMake 3.10 or later**
- **Nintendo Joy-Con 2 controller** (L or R)

## Building

1. **Clone or download** this repository
2. **Navigate to the project directory**:
   ```bash
   cd Joycon2test
   ```
3. **Create build directory**:
   ```bash
   mkdir build && cd build
   ```
4. **Configure with CMake**:
   ```bash
   cmake ..
   ```
5. **Build the project**:
   ```bash
   make
   ```

## Running

1. **Ensure Bluetooth is enabled** on your Mac
2. **Put your Joy-Con into pairing mode** (press and hold the SYNC button)
3. **Run the application**:
   ```bash
   ./Joycon2BLEViewerApp
   ```
4. **The app will**:
   - Scan for Joy-Con devices
   - Automatically connect when found
   - Display real-time sensor data

## Output Format

The application displays data in the following format:

```
==================================================
Joycon2 Data:
==================================================
PacketID: 1991
Buttons: 00000000
Pressed: None
LeftStick: X=2041, Y=2154
RightStick: X=2047, Y=2047
Mouse: X=0, Y=0, DeltaX=0, DeltaY=0, Unk=0, Distance=0
Mag: X=0, Y=0, Z=0
Battery: 3.11V, 2.56mA
Temperature: 25.0°C (Raw: 0)
Accel: X=0, Y=0, Z=0
Gyro: X=0, Y=0, Z=0
Triggers: L=0, R=0
```

## Data Fields

- **PacketID**: Sequential packet identifier
- **Buttons**: Raw button state (hex format)
- **Pressed**: List of currently pressed buttons
- **LeftStick/RightStick**: Analog stick positions (0-4095 range)
- **Mouse**: IR camera tracking data
- **Mag**: Magnetometer readings
- **Battery**: Voltage (V) and current (mA)
- **Temperature**: Controller temperature in Celsius
- **Accel**: Accelerometer readings (X, Y, Z axes)
- **Gyro**: Gyroscope readings (X, Y, Z axes)
- **Triggers**: Analog trigger positions (L/R)

## Troubleshooting

### Connection Issues
- Ensure your Joy-Con is charged and in pairing mode
- Check that Bluetooth is enabled on your Mac
- Make sure no other device is connected to the Joy-Con

### Build Issues
- Install Xcode Command Line Tools: `xcode-select --install`
- Ensure CMake is installed: `brew install cmake` (if using Homebrew)
- Clean build: `rm -rf build && mkdir build && cd build && cmake .. && make`

### Permission Issues
- The app requires Bluetooth permissions (automatically granted)
- If you see permission errors, check System Preferences > Security & Privacy > Bluetooth

## Architecture

This application is built using:
- **Objective-C++**: For Core Bluetooth integration
- **Core Bluetooth Framework**: macOS native BLE support
- **CMake**: Cross-platform build system

## Code Architecture

This application is built using Objective-C++ and leverages macOS's Core Bluetooth framework for BLE communication. The codebase is organized into the following key components:

### Main Classes

#### `Joycon2BLEViewer` (Joycon2BLEViewer.h / Joycon2BLEViewer.mm)
The core class that handles all BLE operations and data processing.

**Key Properties:**
- `centralManager`: CBCentralManager for BLE device discovery and connection
- `connectedPeripheral`: Currently connected Joy-Con device
- `writeCharacteristic`: BLE characteristic for sending commands to Joy-Con
- `subscribeCharacteristic`: BLE characteristic for receiving sensor data
- `connectingPeripherals` / `connectedPeripherals`: Sets tracking connection states
- `deviceType`: Detected device type (L/R/Pro Controller)
- `dataTimeoutTimer`: Timer for detecting data reception timeouts
- `commandTimer`: Timer for periodic command sending
- `displayInterval`: Controls how often data packets are displayed
- `skipInitCommands`: Flag to skip initialization commands

**Key Methods:**
- `startScan()`: Begins scanning for BLE devices
- `stopScan()`: Stops the scanning process
- `connectToDevice(address)`: Connects to a specific device by UUID
- `disconnect()`: Disconnects from the current device
- `sendInitializationCommandsOnce()`: Sends required initialization commands to Joy-Con

### Data Parsing Functions

The application includes several utility functions for parsing binary data from Joy-Con:

- `parseJoycon2Data(data)`: Main data parsing function that extracts all sensor values
- `parseStick(data, offset)`: Parses analog stick positions (X/Y coordinates)
- `parseButtons(buttons)`: Converts button bitmask to human-readable button names
- `toInt16/toUint16/toUint24/toUint32`: Byte array to numeric value conversion functions

### Data Fields Parsed

The application parses the following data fields from each 60-byte packet:

| Field | Offset | Type | Description |
|-------|--------|------|-------------|
| PacketID | 0x00 | uint24 | Sequential packet identifier |
| Buttons | 0x03 | uint32 | Button state bitmask |
| LeftStick | 0x0A | uint16×2 | Left analog stick X/Y (0-4095) |
| RightStick | 0x0D | uint16×2 | Right analog stick X/Y (0-4095) |
| Mouse | 0x10 | int16×4 | IR camera tracking data |
| Magnetometer | 0x18 | int16×3 | Magnetic field sensor X/Y/Z |
| Battery | 0x1F/0x28 | uint16/int16 | Voltage (mV) and current (mA) |
| Temperature | 0x2E | int16 | Controller temperature |
| Accelerometer | 0x30 | int16×3 | Acceleration X/Y/Z |
| Gyroscope | 0x36 | int16×3 | Angular velocity X/Y/Z |
| Triggers | 0x3C | uint8×2 | Analog trigger positions L/R |

### Initialization Process

When a Joy-Con is connected, the application follows this sequence:

1. **Device Discovery**: Scans for BLE devices with manufacturer ID 0x0553 (Nintendo)
2. **Service Discovery**: Discovers available BLE services on the device
3. **Characteristic Discovery**: Finds write and subscribe characteristics
4. **Initialization Commands**: Sends two specific commands to enable data streaming:
   - Command 1: `0c91010200040000FF000000` (enables standard data)
   - Command 2: `0c91010400040000FF000000` (enables extended data)
5. **Notification Setup**: Enables notifications for real-time data reception
6. **Data Reception**: Begins receiving and parsing 60-byte data packets

### Connection Management

The application implements robust connection management:

- **Auto-reconnection**: Automatically retries connection on failure
- **Timeout Handling**: 30-second data timeout with program termination
- **State Tracking**: Maintains sets of connecting and connected devices
- **Error Recovery**: Handles various BLE error conditions gracefully

### Command Line Interface

The main.mm file provides a command-line interface with options:

- `--display-interval N`: Display data every N packets (default: 1)
- `--help/-h`: Show usage information
- `[address]`: Connect to specific device UUID

### Logging System

The application includes a comprehensive logging system with timestamps and log levels:
- `log(level, message)`: Main logging function
- `getTimestamp()`: Generates formatted timestamps with milliseconds
- Log levels: SECTION, INFO, SUCCESS, ERROR, DATA

## License

MIT License

Copyright (c) 2025 seitanmen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contributing

Feel free to submit issues or pull requests for improvements.

##Notes

**Disclaimer:** Nintendo Joy-Con is a registered trademark of Nintendo Co., Ltd. This project is not affiliated with, endorsed by, or sponsored by Nintendo in any way.
