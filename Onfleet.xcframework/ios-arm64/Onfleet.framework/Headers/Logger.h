//
//  Logger.h
//  Onfleet
//
//  Created by Peter Stajger on 04/07/2018.
//  Copyright © 2018 Onfleet Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ONLogD(tagName, args, ...)    	_ONLog(LogLevelDebug, tagName, args, ##__VA_ARGS__)
#define ONLog(tagName, args, ...)       _ONLog(LogLevelDefault, tagName, args, ##__VA_ARGS__)
#define ONLogS(tagName, args, ...)      _ONLogS(LogLevelDefault, tagName, args, ##__VA_ARGS__)
#define ONLogWarn(tagName, args, ...)   _ONLog(LogLevelWarning, tagName, args, ##__VA_ARGS__)
#define ONLogWarnS(tagName, args, ...)  _ONLogS(LogLevelWarning, tagName, args, ##__VA_ARGS__)
#define ONLogErr(tagName, args, ...)    _ONLog(LogLevelError, tagName, args, ##__VA_ARGS__)
#define ONLogErrS(tagName, args, ...)   _ONLogS(LogLevelError, tagName, args, ##__VA_ARGS__)

#define _ONLog(logLevel, tagName, fmt, ...) \
[Logger logWithLineNumber:__LINE__ method:[NSString stringWithFormat:@"%s",__PRETTY_FUNCTION__] file:[[NSString stringWithFormat:@"%s",__FILE__] lastPathComponent] level:logLevel tag:tagName message:fmt == nil ? @"" : [NSString stringWithFormat:fmt, ##__VA_ARGS__]]
#define _ONLogS(logLevel, tagName, fmt, ...) \
[Logger logIfStagingWithLineNumber:__LINE__ method:[NSString stringWithFormat:@"%s",__PRETTY_FUNCTION__] file:[[NSString stringWithFormat:@"%s",__FILE__] lastPathComponent] level:logLevel tag:tagName message:fmt == nil ? @"" : [NSString stringWithFormat:fmt, ##__VA_ARGS__]]

#define ONNotify(tagName, args, ...)          _ONNotify(tagName, args, ##__VA_ARGS__)
#define ONNotifyS(tagName, args, ...)         _ONNotify(tagName, args, ##__VA_ARGS__)
#define ONNotifySB(tagName, args, ...)        [Logger notifyIfStagingOnBackgroundWithTag:tagName message:args == nil ? @"" : [NSString stringWithFormat:args, ##__VA_ARGS__]]
#define _ONNotify(tagName, fmt, ...) \
[Logger notifyIfStagingWithTag:tagName message:fmt == nil ? @"" : [NSString stringWithFormat:fmt, ##__VA_ARGS__]]

typedef NS_CLOSED_ENUM(NSUInteger, LogLevel) {
    LogLevelDebug         = 0,
    LogLevelDefault       = 1,
    LogLevelWarning       = 2,
    LogLevelError         = 3,
};

@interface Logger : NSObject

+ (void)logWithLineNumber:(NSInteger)lineNumber method:(nonnull NSString*)method file:(nonnull NSString*)file level:(LogLevel)lvl tag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(log(lineNumber:method:file:level:tag:message:));
+ (void)logIfStagingWithLineNumber:(NSInteger)lineNumber method:(nonnull NSString*)method file:(nonnull NSString*)file level:(LogLevel)lvl tag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(logIfStaging(lineNumber:method:file:level:tag:message:));

+ (void)notifyWithTag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(notify(tag:message:));
+ (void)notifyIfStagingWithTag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(notifyIfStaging(tag:message:));
+ (void)notifyIfStagingOnBackgroundWithTag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(notifyIfStagingOnBackground(tag:message:));

@end
