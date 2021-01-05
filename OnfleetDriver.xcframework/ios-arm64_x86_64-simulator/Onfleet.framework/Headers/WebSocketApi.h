//
//  WebSocketAPI.h
//  trak
//
//  Created by Addy on 1/31/14.
//  Copyright (c) 2014 Addy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SocketStateHandler)(void);

@protocol WebSocketSubscriptionDelegate<NSObject>

- (void)subscriptionChanged:(BOOL)isSubscribed;

@end

@interface WebSocketApi : NSObject {
    
}

@property (nonatomic, weak, nullable) id<WebSocketSubscriptionDelegate> delegate;
@property (nonatomic, readonly, nullable) NSDate *lastSubscribedTime;
@property (nonatomic, readonly) BOOL hasActiveSession;
@property (nonatomic, copy) NSURL *webSocketURL;
@property (nonatomic, copy, nullable) NSString *userAgent;

- (void)connect;
- (BOOL)isConnected;
- (void)disconnect:(BOOL)endsSession;
- (BOOL)sendMessage:(NSDictionary *)message;
- (BOOL)isSubscribed;

@end

NS_ASSUME_NONNULL_END
