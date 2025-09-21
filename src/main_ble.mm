#import "Joycon2BLEReceiver.h"
#ifndef HID_ENABLE
#import "Joycon2VirtualHID.h"
#endif

int main(int argc, const char * argv[]) {
    EmulationMode mode = MODE_BOTH; // Default to both

    // Parse command line arguments
    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--mouse") == 0) {
            mode = MODE_MOUSE;
        } else if (strcmp(argv[i], "--gamepad") == 0) {
            mode = MODE_GAMEPAD;
        } else {
            fprintf(stderr, "Usage: %s [--mouse | --gamepad]\n", argv[0]);
            fprintf(stderr, "  --mouse: Emulate mouse only\n");
            fprintf(stderr, "  --gamepad: Emulate gamepad only (not implemented yet)\n");
            fprintf(stderr, "  No option: Emulate both (default)\n");
            return 1;
        }
    }

    @autoreleasepool {
        Joycon2BLEReceiver *viewer = [[Joycon2BLEReceiver alloc] init];
#ifndef HID_ENABLE
        Joycon2VirtualHID *hid = [[Joycon2VirtualHID alloc] initWithMode:mode];
#endif
        if (viewer
#ifndef HID_ENABLE
            && hid
#endif
            ) {
            [viewer startScan];
            CFRunLoopRun();
            [viewer release];
#ifndef HID_ENABLE
            [hid release];
#endif
        }
    }
    return 0;
}