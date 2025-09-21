#import "Joycon2BLEReceiver.h"
#import "Joycon2VirtualHID.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Joycon2BLEReceiver *viewer = [[Joycon2BLEReceiver alloc] init];
        Joycon2VirtualHID *hid = [[Joycon2VirtualHID alloc] init];
        if (viewer && hid) {
            [viewer startScan];
            CFRunLoopRun();
            [viewer release];
            [hid release];
        }
    }
    return 0;
}