#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/IOKitLib.h>
#import <ApplicationServices/ApplicationServices.h>
// #import <libusb-1.0/libusb.h> // Commented out for compilation without libusb
#ifndef HID_ENABLE
#import "Joycon2BLEReceiver.h"
#endif

// HID report descriptor for a game controller and mouse based on Joy-Con data
static const uint8_t reportDescriptor[] = {
    // Game Controller Collection (Report ID 0x01)
    0x05, 0x01,        // Usage Page (Generic Desktop)
    0x09, 0x05,        // Usage (Game Pad)
    0xA1, 0x01,        // Collection (Application)
    0x85, 0x01,        // Report ID (1)
    0x05, 0x09,        // Usage Page (Button)
    0x19, 0x01,        // Usage Minimum (1)
    0x29, 0x10,        // Usage Maximum (16)
    0x15, 0x00,        // Logical Minimum (0)
    0x25, 0x01,        // Logical Maximum (1)
    0x75, 0x01,        // Report Size (1)
    0x95, 0x10,        // Report Count (16)
    0x81, 0x02,        // Input (Data, Variable, Absolute)
    0x05, 0x01,        // Usage Page (Generic Desktop)
    0x09, 0x30,        // Usage (X)
    0x09, 0x31,        // Usage (Y)
    0x15, 0x00,        // Logical Minimum (0)
    0x25, 0xFF,        // Logical Maximum (255)
    0x75, 0x08,        // Report Size (8)
    0x95, 0x02,        // Report Count (2)
    0x81, 0x02,        // Input (Data, Variable, Absolute)
    0x05, 0x01,        // Usage Page (Generic Desktop)
    0x09, 0x32,        // Usage (Z)
    0x09, 0x35,        // Usage (Rz)
    0x15, 0x00,        // Logical Minimum (0)
    0x25, 0xFF,        // Logical Maximum (255)
    0x75, 0x08,        // Report Size (8)
    0x95, 0x02,        // Report Count (2)
    0x81, 0x02,        // Input (Data, Variable, Absolute)
    0x05, 0x02,        // Usage Page (Simulation Controls)
    0x09, 0xC4,        // Usage (Accelerator)
    0x09, 0xC5,        // Usage (Brake)
    0x15, 0x00,        // Logical Minimum (0)
    0x25, 0xFF,        // Logical Maximum (255)
    0x75, 0x08,        // Report Size (8)
    0x95, 0x02,        // Report Count (2)
    0x81, 0x02,        // Input (Data, Variable, Absolute)
    0xC0,              // End Collection

    // Mouse Collection (Report ID 0x02)
     0x05, 0x01,        // Usage Page (Generic Desktop)
     0x09, 0x02,        // Usage (Mouse)
     0xA1, 0x01,        // Collection (Application)
     0x85, 0x02,        // Report ID (2)
     0x05, 0x09,        // Usage Page (Button)
     0x19, 0x01,        // Usage Minimum (1)
     0x29, 0x03,        // Usage Maximum (3)
     0x15, 0x00,        // Logical Minimum (0)
     0x25, 0x01,        // Logical Maximum (1)
     0x75, 0x01,        // Report Size (1)
     0x95, 0x03,        // Report Count (3)
     0x81, 0x02,        // Input (Data, Variable, Absolute)
     0x75, 0x05,        // Report Size (5)
     0x95, 0x01,        // Report Count (1)
     0x81, 0x03,        // Input (Constant)
     0x05, 0x01,        // Usage Page (Generic Desktop)
     0x09, 0x30,        // Usage (X)
     0x09, 0x31,        // Usage (Y)
     0x16, 0x00, 0x80,  // Logical Minimum (-32768)
     0x26, 0xFF, 0x7F,  // Logical Maximum (32767)
     0x75, 0x10,        // Report Size (16)
     0x95, 0x02,        // Report Count (2)
     0x81, 0x06,        // Input (Data, Variable, Relative)
     0x09, 0x38,        // Usage (Wheel)
     0x15, 0x81,        // Logical Minimum (-127)
     0x25, 0x7F,        // Logical Maximum (127)
     0x75, 0x08,        // Report Size (8)
     0x95, 0x01,        // Report Count (1)
     0x81, 0x06,        // Input (Data, Variable, Relative)
     0xC0               // End Collection
};

typedef enum {
    MODE_BOTH,
    MODE_MOUSE,
    MODE_GAMEPAD
} EmulationMode;

@interface Joycon2VirtualHID : NSObject {
#ifndef HID_ENABLE
    Joycon2BLEReceiver *joyconClient;
#endif
    bool _initialized;
    EmulationMode _emulationMode;
    CFMachPortRef _eventTap;
}

@property bool initialized;
@property EmulationMode emulationMode;

#ifndef HID_ENABLE
- (void)handleMouseMovement:(int16_t)deltaX deltaY:(int16_t)deltaY;
- (void)handleMouseButtons:(uint8_t)mouseBtnState;
- (void)handleMouseWheel:(int8_t)wheel;
#endif

- (instancetype)initWithMode:(EmulationMode)mode;
- (void)startEmulation;
- (void)stopEmulation;
#ifndef HID_ENABLE
- (void)sendHIDReportFromJoyconData:(NSDictionary *)joyconData;
#endif

@end

CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);

@implementation Joycon2VirtualHID

@synthesize initialized = _initialized;
@synthesize emulationMode = _emulationMode;

- (instancetype)initWithMode:(EmulationMode)mode {
    self = [super init];
    if (self) {
        self.emulationMode = mode;
        // HID event injection setup
        NSLog(@"HID event injection ready in mode: %ld", (long)mode);

#ifndef HID_ENABLE
        joyconClient = [Joycon2BLEReceiver sharedInstance];
        if (!joyconClient) {
            NSLog(@"Failed to get Joy-Con client");
            return nil;
        }

        self.initialized = false;

        // Set up Joy-Con callbacks
        __block Joycon2VirtualHID *blockSelf = self;
        joyconClient.onDataReceived = ^(NSDictionary* data) {
            [blockSelf sendHIDReportFromJoyconData:data];
        };
        joyconClient.onConnected = ^{
            // Reset initial values on reconnection
            blockSelf.initialized = false;
        };
        joyconClient.onError = ^(NSString* error) {
            // Handle error if needed
        };
#endif
    }
    return self;
}

- (void)startEmulation {
    // Placeholder for virtual HID setup
    NSLog(@"Starting virtual HID emulation in mode: %ld", (long)self.emulationMode);

    // Start Joy-Con scanning
#ifndef HID_ENABLE
    [joyconClient startScan];
#endif

    // Set up keyboard event tap for mode switching
    [self setupKeyboardEventTap];
}

- (void)stopEmulation {
#ifndef HID_ENABLE
    [joyconClient disconnect];
#endif
    if (_eventTap) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0), kCFRunLoopCommonModes);
        CFMachPortInvalidate(_eventTap);
        CFRelease(_eventTap);
        _eventTap = NULL;
    }
}

CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    Joycon2VirtualHID *self = (__bridge Joycon2VirtualHID *)refcon;

    if (type == kCGEventKeyDown) {
        CGKeyCode keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        CGEventFlags flags = CGEventGetFlags(event);

        // Check for Shift + M (mouse mode)
        if ((flags & kCGEventFlagMaskShift) && keyCode == 46) { // 'm' key
            self.emulationMode = MODE_MOUSE;
            NSLog(@"Switched to mouse mode");
            return NULL; // Consume the event
        }
        // Check for Shift + G (gamepad mode)
        else if ((flags & kCGEventFlagMaskShift) && keyCode == 5) { // 'g' key
            self.emulationMode = MODE_GAMEPAD;
            NSLog(@"Switched to gamepad mode");
            return NULL; // Consume the event
        }
    }

    return event;
}

- (void)setupKeyboardEventTap {
    CGEventMask eventMask = CGEventMaskBit(kCGEventKeyDown);
    _eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, eventTapCallback, (__bridge void *)self);

    if (!_eventTap) {
        NSLog(@"Failed to create event tap");
        return;
    }

    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CFRelease(runLoopSource);

    CGEventTapEnable(_eventTap, true);
}

#ifndef HID_ENABLE
- (void)sendHIDReportFromJoyconData:(NSDictionary *)joyconData {
    NSLog(@"Sending HID report from Joy-Con data in mode: %ld", (long)self.emulationMode);

    if (self.emulationMode == MODE_GAMEPAD || self.emulationMode == MODE_BOTH) {
        // Send Game Controller HID report (placeholder for future implementation)
        uint8_t gamepadReport[9] = {0x01}; // Report ID 0x01

        // Buttons (32 bits)
        uint32_t buttons = 0;
        NSNumber *buttonsNum = joyconData[@"Buttons"];
        if (buttonsNum) {
            buttons = (uint32_t)[buttonsNum floatValue];
        }
        gamepadReport[1] = buttons & 0xFF;
        gamepadReport[2] = (buttons >> 8) & 0xFF;

        // Left Stick (X, Y)
        NSNumber *leftStickX = joyconData[@"LeftStickX"];
        NSNumber *leftStickY = joyconData[@"LeftStickY"];
        if (leftStickX) gamepadReport[3] = [leftStickX unsignedCharValue];
        if (leftStickY) gamepadReport[4] = [leftStickY unsignedCharValue];

        // Right Stick (Z, Rz)
        NSNumber *rightStickX = joyconData[@"RightStickX"];
        NSNumber *rightStickY = joyconData[@"RightStickY"];
        if (rightStickX) gamepadReport[5] = [rightStickX unsignedCharValue];
        if (rightStickY) gamepadReport[6] = [rightStickY unsignedCharValue];

        // Triggers (Accelerator, Brake)
        NSNumber *triggerL = joyconData[@"TriggerL"];
        NSNumber *triggerR = joyconData[@"TriggerR"];
        if (triggerL) gamepadReport[7] = [triggerL unsignedCharValue];
        if (triggerR) gamepadReport[8] = [triggerR unsignedCharValue];

        // Log HID report (gamepad implementation pending)
        NSLog(@"Gamepad HID report: %02x %02x %02x %02x %02x %02x %02x %02x %02x",
              gamepadReport[0], gamepadReport[1], gamepadReport[2], gamepadReport[3], gamepadReport[4],
              gamepadReport[5], gamepadReport[6], gamepadReport[7], gamepadReport[8]);
    }

    if (self.emulationMode == MODE_MOUSE || self.emulationMode == MODE_BOTH) {
        // Send Mouse HID report
        uint8_t mouseReport[7] = {0x02}; // Report ID 0x02

        // Mouse buttons: map Joy-Con buttons to mouse clicks
        uint8_t mouseBtn = 0;
        NSNumber *buttonsNum = joyconData[@"Buttons"];
        uint32_t buttons = buttonsNum ? (uint32_t)[buttonsNum floatValue] : 0;
        if (buttons & (1 << 14) || buttons & (1LL << 31)) mouseBtn |= 1; // Left click (R or ZL)
        if (buttons & (1 << 15) || buttons & (1LL << 30)) mouseBtn |= 2; // Right click (ZR or L)
        if (buttons & (1 << 18) || buttons & (1 << 19)) mouseBtn |= 4; // Middle click (RS or LS)
        mouseReport[1] = mouseBtn;

        // Mouse movement (DeltaX, DeltaY from Joy-Con mouse data)
        NSNumber *mouseDeltaX = joyconData[@"MouseDeltaX"];
        NSNumber *mouseDeltaY = joyconData[@"MouseDeltaY"];
        NSNumber *mouseX = joyconData[@"MouseX"];
        NSNumber *mouseY = joyconData[@"MouseY"];

        // Use DeltaX and DeltaY if available, otherwise calculate from X and Y
        int16_t rawDeltaX = mouseDeltaX ? [mouseDeltaX intValue] : 0;
        int16_t rawDeltaY = mouseDeltaY ? [mouseDeltaY intValue] : 0;

        // If DeltaX and DeltaY are 0, calculate from X and Y difference
        static int16_t lastMouseX = 0;
        static int16_t lastMouseY = 0;

        if (mouseX && mouseY) {
            int16_t currentMouseX = [mouseX intValue];
            int16_t currentMouseY = [mouseY intValue];
            if (rawDeltaX == 0 && rawDeltaY == 0) {
                if (currentMouseX != lastMouseX || currentMouseY != lastMouseY) {
                    rawDeltaX = currentMouseX - lastMouseX;
                    rawDeltaY = currentMouseY - lastMouseY;
                }
            }
            lastMouseX = currentMouseX;
            lastMouseY = currentMouseY;
        }

        // Scale to 16-bit range
        int16_t scaledDeltaX = rawDeltaX;
        int16_t scaledDeltaY = rawDeltaY;

        // Clamp to -32768 to 32767
        if (scaledDeltaX > 32767) scaledDeltaX = 32767;
        else if (scaledDeltaX < -32768) scaledDeltaX = -32768;

        if (scaledDeltaY > 32767) scaledDeltaY = 32767;
        else if (scaledDeltaY < -32768) scaledDeltaY = -32768;

        // Use 16-bit deltas
        mouseReport[2] = scaledDeltaX & 0xFF;
        mouseReport[3] = (scaledDeltaX >> 8) & 0xFF;
        mouseReport[4] = scaledDeltaY & 0xFF;
        mouseReport[5] = (scaledDeltaY >> 8) & 0xFF;

        // Wheel: 20 levels based on deviation from initial Y position
        static int16_t initialLeftY = 2047;
        static int16_t initialRightY = 2047;

        NSNumber *leftStickY = joyconData[@"LeftStickY"];
        NSNumber *rightStickY = joyconData[@"RightStickY"];
        int16_t currentLeftY = leftStickY ? [leftStickY intValue] : 2047;
        int16_t currentRightY = rightStickY ? [rightStickY intValue] : 2047;

        if (!self.initialized) {
            initialLeftY = currentLeftY;
            initialRightY = currentRightY;
            self.initialized = true;
        }

        int16_t wheelSpeed = 0;

        // Left stick
        int16_t deviationLeft = currentLeftY - initialLeftY;
        int levelLeft = abs(deviationLeft) / 60;
        levelLeft = (levelLeft > 20) ? 20 : levelLeft;
        int speedLeft = levelLeft * 5; // Max 100 at level 20
        if (abs(deviationLeft) > 30) { // Deadzone
            wheelSpeed += (deviationLeft > 0) ? -speedLeft : speedLeft; // Up positive, down negative
        }

        // Right stick
        int16_t deviationRight = currentRightY - initialRightY;
        int levelRight = abs(deviationRight) / 60;
        levelRight = (levelRight > 20) ? 20 : levelRight;
        int speedRight = levelRight * 5;
        if (abs(deviationRight) > 30) {
            wheelSpeed += (deviationRight > 0) ? -speedRight : speedRight;
        }

        // Clamp to -127 to 127
        if (wheelSpeed > 127) wheelSpeed = 127;
        else if (wheelSpeed < -127) wheelSpeed = -127;

        mouseReport[6] = (int8_t)wheelSpeed;

        // Send Mouse HID event using CGEvent
        int16_t deltaX = (int16_t)((mouseReport[3] << 8) | mouseReport[2]);
        int16_t deltaY = (int16_t)((mouseReport[5] << 8) | mouseReport[4]);
        int8_t wheel = (int8_t)mouseReport[6];
        uint8_t mouseBtnState = mouseReport[1];

        static uint8_t lastMouseBtnState = 0;

        // マウス関連の処理を分離
        [self handleMouseMovement:deltaX deltaY:deltaY];
        [self handleMouseButtons:mouseBtnState];
        [self handleMouseWheel:wheel];

        lastMouseBtnState = mouseBtnState;

        // Log Mouse HID report
        NSLog(@"Mouse HID report: %02x %02x %02x %02x %02x %02x %02x",
              mouseReport[0], mouseReport[1], mouseReport[2], mouseReport[3], mouseReport[4], mouseReport[5], mouseReport[6]);
    }
}
#endif

#ifndef HID_ENABLE
- (void)dealloc {
    [self stopEmulation];
    [super dealloc];
}

- (void)handleMouseMovement:(int16_t)deltaX deltaY:(int16_t)deltaY {
    if (deltaX != 0 || deltaY != 0) {
        // 急激な差分を検知してログ
        const int threshold = 1000;
        if (abs(deltaX) > threshold || abs(deltaY) > threshold) {
            NSLog(@"Large delta detected: deltaX=%d, deltaY=%d", deltaX, deltaY);
        }

        // 現在のマウス座標を取得
        CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
        CGEventRef tempEvent = CGEventCreate(eventSource);
        CGPoint currentPos = CGEventGetLocation(tempEvent);
        CFRelease(tempEvent);
        CFRelease(eventSource);

        // deltaX, deltaY をスケーリング（制限なしで滑らかに）
        const double scale = 5.0;
        currentPos.x += (double)deltaX / scale;
        currentPos.y += (double)deltaY / scale;

        // 画面境界内に座標を制限
        CGRect screenBounds = CGDisplayBounds(CGMainDisplayID());
        currentPos.x = fmax(screenBounds.origin.x, fmin(currentPos.x, screenBounds.origin.x + screenBounds.size.width));
        currentPos.y = fmax(screenBounds.origin.y, fmin(currentPos.y, screenBounds.origin.y + screenBounds.size.height));

        // マウスカーソルを新しい座標に移動
        CGWarpMouseCursorPosition(currentPos);
    }
}

- (void)handleMouseButtons:(uint8_t)mouseBtnState {
    static uint8_t lastMouseBtnState = 0;

    // 現在のマウス座標を取得
    CGEventRef tempEvent = CGEventCreate(NULL);
    CGPoint currentPos = CGEventGetLocation(tempEvent);
    CFRelease(tempEvent);

    // Left button
    if ((mouseBtnState & 1) && !(lastMouseBtnState & 1)) {
        CGEventRef clickEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, currentPos, kCGMouseButtonLeft);
        CGEventPost(kCGHIDEventTap, clickEvent);
        CFRelease(clickEvent);
    } else if (!(mouseBtnState & 1) && (lastMouseBtnState & 1)) {
        CGEventRef clickEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, currentPos, kCGMouseButtonLeft);
        CGEventPost(kCGHIDEventTap, clickEvent);
        CFRelease(clickEvent);
    }

    // Right button
    if ((mouseBtnState & 2) && !(lastMouseBtnState & 2)) {
        CGEventRef clickEvent = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, currentPos, kCGMouseButtonRight);
        CGEventPost(kCGHIDEventTap, clickEvent);
        CFRelease(clickEvent);
    } else if (!(mouseBtnState & 2) && (lastMouseBtnState & 2)) {
        CGEventRef clickEvent = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, currentPos, kCGMouseButtonRight);
        CGEventPost(kCGHIDEventTap, clickEvent);
        CFRelease(clickEvent);
    }

    // Middle button
    if ((mouseBtnState & 4) && !(lastMouseBtnState & 4)) {
        CGEventRef clickEvent = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseDown, currentPos, kCGMouseButtonCenter);
        CGEventPost(kCGHIDEventTap, clickEvent);
        CFRelease(clickEvent);
    } else if (!(mouseBtnState & 4) && (lastMouseBtnState & 4)) {
        CGEventRef clickEvent = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseUp, currentPos, kCGMouseButtonCenter);
        CGEventPost(kCGHIDEventTap, clickEvent);
        CFRelease(clickEvent);
    }

    lastMouseBtnState = mouseBtnState;
}

- (void)handleMouseWheel:(int8_t)wheel {
    if (wheel != 0) {
        CGEventRef wheelEvent = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 1, -wheel);
        CGEventPost(kCGHIDEventTap, wheelEvent);
        CFRelease(wheelEvent);
    }
}
#endif

@end