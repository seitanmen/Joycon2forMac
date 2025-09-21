# Joycon2 BLE Viewer (macOS)

A macOS application that connects to Nintendo Joy-Con 2 controllers via Bluetooth Low Energy (BLE) and displays real-time sensor data.

## Features

- **Real-time Data Display**: Shows live data from Joy-Con controllers including:
  - Button states (A, B, X, Y, →, ↓, ↑, ←, L, R, ZL, ZR, LS, RS, SL(L), SR(L), SL(R), SR(R), SELECT(-), START(+), CAMERA, HOME, CHAT)
  - Trigger positions (Can be detected with the NGC controller)
  - Analog stick positions (Left/Right stick X/Y values)
  - Motion sensors (Accelerometer, Gyroscope, Magnetometer)
  - IR camera data (Mouse tracking)
  - Battery voltage and current
  - Temperature sensor

- **Auto-discovery**: Automatically detects and connects to Joy-Con 2 controllers

## Requirements

- **macOS 10.15 or later**
- **Xcode Command Line Tools** (for compilation)
- **CMake 3.10 or later**
- **Nintendo Switch2 controller** (L or R)

## Building

1. **Clone or download** this repository
2. **Navigate to the project directory**:
   ```bash
   cd Joycon2forMac
   ```
3. **Run the build script**:
   ```bash
   ./build.sh [BUILD_MODE] [BUILD_TYPE]
   ```
   - `BUILD_MODE`: `FULL` (default, includes BLE and HID emulation) or `BLE_ONLY` (BLE communication only)
   - `BUILD_TYPE`: `debug` (default) or `release`

   Examples:
   ```bash
   ./build.sh FULL debug    # Build full version in debug mode
   ./build.sh BLE_ONLY release  # Build BLE-only version in release mode
   ```

   The executables will be created in the `build/` directory:
   - `Joycon2VirtualHID` (FULL mode)
   - `Joycon2BLEReceiver` (BLE_ONLY mode)

## Running

1. **Ensure Bluetooth is enabled** on your Mac
2. **Put your Switch2 Controller into pairing mode** (press and hold the SYNC button)
3. **Run the application**:
   ```bash
   ./build/Joycon2VirtualHID  # For full mode (BLE + HID emulation)
   # or
   ./build/Joycon2BLEReceiver  # For BLE-only mode (data display only)
   ```
4. **The app will**:
   - Scan for Switch2 Controller devices
   - Automatically connect when found
   - Display real-time sensor data (BLE_ONLY mode)
   - Emulate HID inputs (FULL mode)

## Output Format

The application displays data in the following format:

```
=================================================
Joy-Con 2 (R) Data:
=================================================
Elapsed: 7555 ms
Packet_HEX: 4F 24 0 0 0 0 0 E0 FF F FF F7 7F C 28 79 0 0 0 0 FF 11 9 C 0 47 FF 8A 2 45 FE B E 0 76 7 0 0 0 0 0 1 62 D2 60 0 8 0 E1 FA E2 4 76 E 7 0 FF FF 13 0 0 0 0
PacketID: 9295
Buttons: 00000000
Pressed: None
Analog_Triggers: L=0, R=0
LeftStick: X=2047, Y=2047
RightStick: X=2060, Y=1938
Accel: X=-1311, Y=1250, Z=3702
Gyro: X=7, Y=-1, Z=19
Mag: X=18176, Y=-29953, Z=17666
Mouse: X=0, Y=0, DeltaX=0, DeltaY=0
Battery: 3.60V, 2.56mA
Temperature: 25.1°C
```

## Data Fields

- **Packet_HEX**: The data obtained by subscribing to AB7DE9BE-89FE-49AD-828F-118F09DF7FD2.
- **PacketID**: Sequential packet identifier
- **Buttons**: Raw button state (hex format)
- **Pressed**: List of currently pressed buttons
- **Analog_Triggers**: Analog trigger positions (L/R)
- **LeftStick/RightStick**: Analog stick positions
- **Mouse**: IR camera tracking data
- **Accel**: Accelerometer readings (X, Y, Z axes)
- **Gyro**: Gyroscope readings (X, Y, Z axes)
- **Mag**: Magnetometer readings (X, Y, Z axes)
- **Battery**: Voltage (V) and current (mA)
- **Temperature**: Controller temperature in Celsius

## Troubleshooting

### Connection Issues
- Ensure your Joy-Con is charged and in pairing mode
- Check that Bluetooth is enabled on your Mac
- Make sure no other device is connected to the Joy-Con

### Build Issues
- Install Xcode Command Line Tools: `xcode-select --install`
- Ensure clang++ is available (included with Xcode Command Line Tools)
- Clean build: `rm -rf build && ./build.sh`

### Permission Issues
- The app requires Bluetooth permissions (automatically granted)
- If you see permission errors, check System Preferences > Security & Privacy > Bluetooth

## Architecture

This application is built using:
- **Objective-C++**: For Core Bluetooth integration
- **Core Bluetooth Framework**: macOS native BLE support
- **IOKit Framework**: For HID device emulation
- **ApplicationServices Framework**: For mouse event simulation
- **clang++**: Compiler for building the executables

## Code Architecture

This application is built using Objective-C++ and leverages macOS's Core Bluetooth framework for BLE communication. The codebase is organized into the following key components:

### Main Classes

#### `Joycon2BLEReceiver` (Joycon2BLEReceiver.h / Joycon2BLEReceiver.mm)
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

### Source Files Description

#### English
- **include/Joycon2BLEReceiver.h**: Header file for the Joycon2BLEReceiver class. Defines interfaces for BLE communication with Joy-Con devices, including properties, delegate methods, and utility functions.
- **include/Joycon2VirtualHID.h**: Header file for the Joycon2VirtualHID class. Defines interfaces for emulating virtual HID devices, handling mouse and gamepad inputs.
- **src/Joycon2BLEReceiver.mm**: Implementation of the Joycon2BLEReceiver class. Handles BLE scanning, connection, data reception, parsing, logging, and sending initialization commands.
- **src/Joycon2VirtualHID.mm**: Implementation of the Joycon2VirtualHID class. Converts Joy-Con data to HID reports and simulates mouse movements, clicks, and scrolling using CGEvent.
- **src/main_ble.mm**: Main function for BLE receiver mode. Initializes Joycon2BLEReceiver and Joycon2VirtualHID, starts scanning.
- **src/main_hid.mm**: Main function for HID emulation mode. Initializes Joycon2VirtualHID and starts emulation.

#### 日本語
- **include/Joycon2BLEReceiver.h**: Joycon2BLEReceiverクラスのヘッダーファイル。Joy-ConデバイスとのBLE通信のためのインターフェースを定義。プロパティ、デリゲートメソッド、ユーティリティ関数を含む。
- **include/Joycon2VirtualHID.h**: Joycon2VirtualHIDクラスのヘッダーファイル。仮想HIDデバイスをエミュレートするためのインターフェースを定義。マウスやゲームパッドの入力を扱う。
- **src/Joycon2BLEReceiver.mm**: Joycon2BLEReceiverクラスの実装。BLEスキャン、接続、データ受信、パース、ログ出力、初期化コマンド送信を行う。
- **src/Joycon2VirtualHID.mm**: Joycon2VirtualHIDクラスの実装。Joy-ConデータをHIDレポートに変換し、CGEventでマウス移動、クリック、スクロールをシミュレート。
- **src/main_ble.mm**: BLE受信モードのメイン関数。Joycon2BLEReceiverとJoycon2VirtualHIDを初期化し、スキャンを開始。
- **src/main_hid.mm**: HIDエミュレーションモードのメイン関数。Joycon2VirtualHIDを初期化し、エミュレーションを開始。

## Acknowledgments

This project is based on the work from

[yujimny/Joycon2test](https://github.com/yujimny/Joycon2test)
[TheFrano/joycon2cpp](https://github.com/TheFrano/joycon2cpp)
[Tamagosushio/joycon2cpp](https://github.com/Tamagosushio/joycon2cpp)

We thank the authors for their contributions to the Joy-Con BLE communication implementation.

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
