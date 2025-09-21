#import "Joycon2VirtualHID.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Joycon2VirtualHID *emulator = [[Joycon2VirtualHID alloc] init];
        if (emulator) {
            [emulator startEmulation];
            CFRunLoopRun();
        }
    }
    return 0;
}