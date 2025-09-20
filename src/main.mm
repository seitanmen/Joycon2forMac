#import "../include/Joycon2BLEViewer.h"
#import <Foundation/Foundation.h>
#include <iostream>
#include <string>
#include <signal.h>
#include <atomic>
#include <chrono>
#include <iomanip>
#include <sstream>

// Global data counter
extern int dataReceiveCounter;

// グローバル変数で終了フラグ
static std::atomic<bool> shouldExit(false);



// 接続開始時刻を記録
static time_t connectionStartTime = 0;

// シグナルハンドラー
void signalHandler(int signal) {
    if (signal == SIGINT) {
        std::cout << "\n🛑 Received SIGINT (Ctrl+C). Shutting down..." << std::endl;
        shouldExit = true;
        // メインループを停止
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
}

int main(int argc, const char* argv[]) {
    @autoreleasepool {
        // シグナルハンドラーを設定
        signal(SIGINT, signalHandler);

        Joycon2BLEViewer* client = [[Joycon2BLEViewer alloc] init];

        // デフォルトの表示間隔
        int displayInterval = 1; // デフォルト: 毎回表示
        BOOL skipInitCommands = NO; // デフォルト: コマンド送信

        // Parse command line arguments
        for (int i = 1; i < argc; ++i) {
            std::string arg = argv[i];
            if (arg == "--display-interval" && i + 1 < argc) {
                displayInterval = std::atoi(argv[++i]);
                if (displayInterval < 1) displayInterval = 1;
            } else if (arg == "--help" || arg == "-h") {
                std::cout << "Usage: " << argv[0] << " [options] [address]" << std::endl;
                std::cout << "Options:" << std::endl;
                std::cout << "  --display-interval N    Display packet data every N packets (default: 1)" << std::endl;
                std::cout << "  --help, -h              Show this help message" << std::endl;
                return 0;
            } else {
                // Assume it's an address
                NSString* address = [NSString stringWithUTF8String:argv[i]];
                [client connectToDevice:address];
                goto start_client;
            }
        }

        // Set options in client
        client.displayInterval = displayInterval;
        client.skipInitCommands = skipInitCommands;

        // Set up callbacks
        client.onDeviceFound = ^(NSString* name, NSString* address) {
            std::string nameStr = name ? [name UTF8String] : "Unknown";
            std::string addressStr = address ? [address UTF8String] : "Unknown";
            log("INFO", "Device found: " + nameStr + " (" + addressStr + ")");
        };

        client.onConnected = ^{
            std::cout << "✅ Joy-Con connected and ready!" << std::endl;
            std::cout << "🎮 Move the controller to see sensor data. Press Ctrl+C to exit." << std::endl;
            // 接続開始時刻を記録
            connectionStartTime = time(NULL);
        };

        client.onDataReceived = ^(NSDictionary* data) {
            // メイン関数では追加の処理は行わず、BLEクライアント側で表示
        };

        client.onError = ^(NSString* error) {
            std::cout << "Connection error: " << [error UTF8String] << std::endl;
            // エラーが発生したら、一定時間待って再接続を試行
            if (!shouldExit) {
                std::cout << "🔄 Retrying connection in 5 seconds..." << std::endl;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!shouldExit) {
                        std::cout << "🔄 Attempting to reconnect..." << std::endl;
                        [client startScan];
                    }
                });
            }
        };

        // If no address specified, start scanning
        [client startScan];

    start_client:
        std::cout << "🚀 Joy-Con2 BLE Client started at " << time(NULL) << ". Press Ctrl+C to exit." << std::endl;
        std::cout << "📊 Display interval: every " << displayInterval << " packets" << std::endl;

        // Run the run loop until shouldExit is true
        while (!shouldExit) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }

        time_t endTime = time(NULL);
        std::cout << "👋 Shutting down Joy-Con2 BLE Client at " << endTime << "ms..." << std::endl;
        std::cout << "📊 Final data counter: " << dataReceiveCounter << " packets received" << std::endl;

        // 接続時間を計算して表示
        if (connectionStartTime > 0) {
            time_t connectionDuration = endTime - connectionStartTime;
            std::cout << "⏱️ Connection duration: " << connectionDuration << " seconds (" << connectionDuration / 60 << " minutes " << connectionDuration % 60 << " seconds)" << std::endl;
        } else {
            std::cout << "⏱️ No connection was established" << std::endl;
        }

        std::cout << "📊 Final status: Program terminated normally" << std::endl;
        [client disconnect];
    }
    return 0;
}