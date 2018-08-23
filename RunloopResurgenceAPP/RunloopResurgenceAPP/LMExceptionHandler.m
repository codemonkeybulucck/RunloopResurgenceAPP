//
//  LMExceptionHandler.m
//  testImageSourceCode
//
//  Created by lemon on 2018/8/22.
//  Copyright © 2018年 Lemon. All rights reserved.
//

#import "LMExceptionHandler.h"
//#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <UIKit/UIKit.h>

static NSString *LMCrashExceptionCallStack = @"LMCrashCallStack";
static NSString *LMSignalException = @"LMSignalException";
static NSString *LMSignalNameKey = @"LMSignalName";

@interface LMExceptionHandler()
@property (nonatomic, assign) BOOL isExit;
@end

@implementation LMExceptionHandler
+ (instancetype)shareExceptionHandler{
    static id instance = nil;
    static dispatch_once_t once_Token;
    dispatch_once(&once_Token, ^{
        instance = [[self alloc]init];
    });
    return instance;
}
- (void)startListenException{
    //捕捉crash类型的错误
    NSSetUncaughtExceptionHandler(&CrashExceptionHandler);
    
    //捕捉sinal类型的错误
    signal(SIGABRT, SignalExceptionHandler);
    signal(SIGILL, SignalExceptionHandler);
    signal(SIGSEGV, SignalExceptionHandler);
    signal(SIGFPE, SignalExceptionHandler);
    signal(SIGBUS, SignalExceptionHandler);
    signal(SIGPIPE, SignalExceptionHandler);
}

#pragma mark - 处理异常
void CrashExceptionHandler(NSException *exception){
    NSArray *callStack = [exception callStackSymbols];
    NSString *reson = [exception reason];
    NSString *name = [exception name];
    NSDictionary *dict = @{LMCrashExceptionCallStack:callStack};
    NSException *customException = [NSException exceptionWithName:name reason:reson userInfo:dict];
    [[LMExceptionHandler shareExceptionHandler] performSelectorOnMainThread:@selector(handleException:) withObject:customException waitUntilDone:YES];
}

void SignalExceptionHandler(int signal){
    NSArray *callStack = [LMExceptionHandler backtrace];
    NSLog(@"信号捕获崩溃，堆栈信息：%@",callStack);
    NSString *name = LMSignalException;
    NSString *reson = [NSString stringWithFormat:@"signal %d was raised",signal];
    NSDictionary *dict = @{LMSignalNameKey:@(signal)};
    NSException *customException = [NSException exceptionWithName:name reason:reson userInfo:dict];
    [[LMExceptionHandler shareExceptionHandler] performSelectorOnMainThread:@selector(handleException:) withObject:customException waitUntilDone:YES];
}

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (int i = 0; i < frames; i++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}

- (void)handleException:(NSException *)exception{
    NSString *message = [NSString stringWithFormat:@"崩溃原因如下:\n%@\n%@\n%@",
                         [exception name],
                         [exception reason],
                         [exception userInfo]];
    NSLog(@"%@",message);
    
    [self showAlertWithException:exception];
    
    //获得当前的runloop并且重新启动
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    NSArray *modes = CFBridgingRelease(CFRunLoopCopyAllModes(runloop));
    while (!self.isExit) {
        for (NSString *mode in modes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    //释放资源
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    if ([[exception name] isEqual:LMSignalException]) {
        kill(getpid(), [[[exception userInfo] objectForKey:LMSignalNameKey] intValue]);
    } else {
        [exception raise];
    }
}

- (void)showAlertWithException:(NSException *)exception{
    UIWindow *currenWindow = [UIApplication sharedApplication].delegate.window;
    UIViewController *vc = currenWindow.rootViewController;
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"系统捕获到了某些异常，即将退出应用或者帮助我们上传错误信息" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertVc addAction:[UIAlertAction actionWithTitle:@"发送异常信息" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"发送或者异常数据");
        //发送异常信息到服务器或者保存到本地下次发送
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.isExit = YES;
        });
    }]];
    [alertVc addAction:[UIAlertAction actionWithTitle:@"退出应用" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"退出应用");
        self.isExit = YES;
    }]];
    [vc presentViewController:alertVc animated:YES completion:nil];
}

@end
