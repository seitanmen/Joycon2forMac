#import "Joycon2BLEReceiver.h"
#ifndef HID_ONLY
#import "Joycon2VirtualHID.h"
#endif

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Joycon2BLEReceiver *viewer = [[Joycon2BLEReceiver alloc] init];
#ifndef HID_ONLY
        Joycon2VirtualHID *hid = [[Joycon2VirtualHID alloc] init];
#endif
        if (viewer
#ifndef HID_ONLY
            && hid
#endif
            ) {
            [viewer startScan];
            CFRunLoopRun();
            [viewer release];
#ifndef HID_ONLY
            [hid release];
#endif
        }
    }
    return 0;
}