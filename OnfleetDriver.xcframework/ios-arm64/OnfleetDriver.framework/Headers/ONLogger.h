//
//  ONLogger.h
//  Onfleet
//
//  Created by Peter Stajger on 04/07/2018.
//  Copyright © 2018 Onfleet Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ONLogD(tagName, args, ...)    	_ONLog(ONLogLevelDebug, tagName, args, ##__VA_ARGS__)
#define ONLog(tagName, args, ...)       _ONLog(ONLogLevelDefault, tagName, args, ##__VA_ARGS__)
#define ONLogS(tagName, args, ...)      _ONLogS(ONLogLevelDefault, tagName, args, ##__VA_ARGS__)
#define ONLogWarn(tagName, args, ...)   _ONLog(ONLogLevelWarning, tagName, args, ##__VA_ARGS__)
#define ONLogWarnS(tagName, args, ...)  _ONLogS(ONLogLevelWarning, tagName, args, ##__VA_ARGS__)
#define ONLogErr(tagName, args, ...)    _ONLog(ONLogLevelError, tagName, args, ##__VA_ARGS__)
#define ONLogErrS(tagName, args, ...)   _ONLogS(ONLogLevelError, tagName, args, ##__VA_ARGS__)

#define _ONLog(logLevel, tagName, fmt, ...) \
[ONLogger logWithLineNumber:__LINE__ method:[NSString stringWithFormat:@"%s",__PRETTY_FUNCTION__] file:[[NSString stringWithFormat:@"%s",__FILE__] lastPathComponent] level:logLevel tag:tagName message:fmt == nil ? @"" : [NSString stringWithFormat:fmt, ##__VA_ARGS__]]
#define _ONLogS(logLevel, tagName, fmt, ...) \
[ONLogger logIfStagingWithLineNumber:__LINE__ method:[NSString stringWithFormat:@"%s",__PRETTY_FUNCTION__] file:[[NSString stringWithFormat:@"%s",__FILE__] lastPathComponent] level:logLevel tag:tagName message:fmt == nil ? @"" : [NSString stringWithFormat:fmt, ##__VA_ARGS__]]

#define ONNotify(tagName, args, ...)          _ONNotify(tagName, args, ##__VA_ARGS__)
#define ONNotifyS(tagName, args, ...)         _ONNotify(tagName, args, ##__VA_ARGS__)
#define ONNotifySB(tagName, args, ...)        [ONLogger notifyIfStagingOnBackgroundWithTag:tagName message:args == nil ? @"" : [NSString stringWithFormat:args, ##__VA_ARGS__]]
#define _ONNotify(tagName, fmt, ...) \
[ONLogger notifyIfStagingWithTag:tagName message:fmt == nil ? @"" : [NSString stringWithFormat:fmt, ##__VA_ARGS__]]

typedef NS_CLOSED_ENUM(NSUInteger, ONLogLevel) {
    ONLogLevelDebug         = 0,
    ONLogLevelDefault       = 1,
    ONLogLevelWarning       = 2,
    ONLogLevelError         = 3,
};

@protocol LoggerDestination
- (void)logWithLineNumber:(NSInteger)lineNumber method:(nonnull NSString*)method file:(nonnull NSString*)file level:(ONLogLevel)lvl tag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(log(lineNumber:method:file:level:tag:message:));
@end

@interface ONLogger : NSObject
+ (void)addDestination:(id<LoggerDestination>_Nonnull)destination;
+ (void)logWithLineNumber:(NSInteger)lineNumber method:(nonnull NSString*)method file:(nonnull NSString*)file level:(ONLogLevel)lvl tag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(log(lineNumber:method:file:level:tag:message:));
+ (void)logIfStagingWithLineNumber:(NSInteger)lineNumber method:(nonnull NSString*)method file:(nonnull NSString*)file level:(ONLogLevel)lvl tag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(logIfStaging(lineNumber:method:file:level:tag:message:));

+ (void)notifyWithTag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(notify(tag:message:));
+ (void)notifyIfStagingWithTag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(notifyIfStaging(tag:message:));
+ (void)notifyIfStagingOnBackgroundWithTag:(nonnull NSString*)tag message:(nonnull NSString*)message NS_SWIFT_NAME(notifyIfStagingOnBackground(tag:message:));

@end
