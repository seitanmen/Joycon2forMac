#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>
#import <IOKit/IOKitLib.h>
#import <ApplicationServices/ApplicationServices.h>
#ifndef HID_ONLY
#import "Joycon2BLEReceiver.h"
#endif

@interface Joycon2VirtualHID : NSObject {
#ifndef HID_ONLY
    Joycon2BLEReceiver *joyconClient;
#endif
    bool initialized;
}

@property bool initialized;

#ifndef HID_ONLY
- (void)handleMouseMovement:(int16_t)deltaX deltaY:(int16_t)deltaY;
- (void)handleMouseButtons:(uint8_t)mouseBtnState;
- (void)handleMouseWheel:(int8_t)wheel;
#endif

- (instancetype)init;
- (void)startEmulation;
- (void)stopEmulation;
// - (void)sendHIDReportFromJoyconData:(NSDictionary *)joyconData;

@end