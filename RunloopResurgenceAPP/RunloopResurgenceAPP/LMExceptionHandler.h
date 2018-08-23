//
//  LMExceptionHandler.h
//  testImageSourceCode
//
//  Created by lemon on 2018/8/22.
//  Copyright © 2018年 Lemon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMExceptionHandler : NSObject
+ (instancetype)shareExceptionHandler;
- (void)startListenException;
@end
