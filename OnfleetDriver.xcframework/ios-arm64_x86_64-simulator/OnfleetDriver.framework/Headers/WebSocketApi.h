//
//  WebSocketAPI.h
//  trak
//
//  Created by Addy on 1/31/14.
//  Copyright (c) 2014 Addy. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WebsocketAuthError) {
    /// don't know what this means, perhaps disconnect client
    WebsocketAuthErrorClientNotSupported,
    /// auth expired, we can attempt to refresh access token
    WebsocketAuthErrorTokenExpired,
    /// connection severed with code 1003 and must disconnect and force logout
    WebsocketAuthErrorTokenFailed
};

@class WebSocketApi;

typedef void (^WebSocketApiProceedHandler)(void);

@protocol WebSocketApiDelegate<NSObject>

- (void)websocket: (WebSocketApi *)client didReceiveSyncDiff: (NSDictionary <NSString *, NSObject *>*)update;
- (void)websocket: (WebSocketApi *)client didChangeSubscription: (BOOL)isSubscribed;
- (void)websocket: (WebSocketApi *)client didDetectAuthError: (WebsocketAuthError)code;

@end

@protocol WebSocketApiDataSource<NSObject>

/// WS client will ask the datasource for access token at some point. If connection severes with invalid access token then method first
/// -websocket:didDetectAuthError: will be called with a handler that will later invoke this method to get new access token.
- (nullable NSString *)accessTokenForWebsocket: (WebSocketApi *)client;

@end

@interface WebSocketApi : NSObject {
    
}

@property (nonatomic, weak, nullable) id<WebSocketApiDelegate> delegate;
@property (nonatomic, weak, nullable) id<WebSocketApiDataSource> dataSource;

@property (nonatomic, copy) NSURL *webSocketURL;
@property (nonatomic, copy, nullable) NSString *userAgent;
@property (nonatomic, copy) NSString *version;

@property (nonatomic, readonly, nullable) NSDate *lastSubscribedTime;
@property (nonatomic, readonly) BOOL hasActiveSession;

#if DEBUG
@property (nonatomic, assign) BOOL isIgnoringPings;
#endif

- (void)connect;
- (BOOL)isConnected;
- (void)disconnect:(BOOL)endsSession;
- (BOOL)sendMessage:(NSDictionary *)message;
- (BOOL)isSubscribed;
- (void)subscribeOnceConnected;

- (void)disableEnforceDisconnection;

@end

NS_ASSUME_NONNULL_END
