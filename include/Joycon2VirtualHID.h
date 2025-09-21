#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/IOKitLib.h>
#import <ApplicationServices/ApplicationServices.h>
#ifndef HID_ENABLE
#import "Joycon2BLEReceiver.h"
#endif

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