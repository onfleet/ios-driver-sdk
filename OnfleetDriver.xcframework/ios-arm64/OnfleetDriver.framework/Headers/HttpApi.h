//
//  HttpApi.h
//  trak
//
//  Created by Addy on 1/30/14.
//  Copyright (c) 2014 Addy. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;

@class AFHTTPSessionManager;
@class CLLocation;
@class Account;

typedef void (^AsyncOperationComplete) (id _Nullable error, id _Nullable data);

typedef void (^HttpSuccessBlock) (NSDictionary * _Nullable response);
typedef void (^HttpSuccessNonNullBlock) (NSDictionary<NSString *, id> * _Nonnull response);
typedef void (^HttpErrorBlock) (NSError * _Nonnull error, NSDictionary<NSString *, id> * _Nullable errorBody);

typedef NS_CLOSED_ENUM(NSUInteger, WorkerAnalyticsPeriod) {
    WorkerAnalyticsPeriodToday,
    WorkerAnalyticsPeriodYesterday,
    WorkerAnalyticsPeriodWeek,
    WorkerAnalyticsPeriodMonth,
    WorkerAnalyticsPeriodYear
};

NS_ASSUME_NONNULL_BEGIN

@interface HttpApi : NSObject {
    AFHTTPSessionManager *manager;
}

@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy, nonnull) NSString *deviceId;
@property (nonatomic, copy, nullable) NSString *userAgent;

+ (HttpApi *)sharedInstance;

- (void)refreshAccessToken:(HttpSuccessBlock)successBlock errorBlock:(HttpErrorBlock)errorBlock;
- (void)logout:(HttpSuccessBlock)successBlock errorBlock:(HttpErrorBlock)errorBlock;

- (BOOL)isNetworkReachable;

- (void)submitAPNDeviceToken:(NSString *)token successBlock:(HttpSuccessBlock)successBlock errorBlock:(HttpErrorBlock)errorBlock;
- (void)resetPasswordWithPhone:(NSString *)phone successBlock:(HttpSuccessBlock)successBlock errorBlock:(HttpErrorBlock)errorBlock;
- (void)uploadImageData:(NSData *)data successBlock:(HttpSuccessBlock)successBlock errorBlock:(HttpErrorBlock)errorBlock;

- (void)collectionWithName:(NSString *)name onComplete:(AsyncOperationComplete)onComplete;
- (void)collectionWithName:(NSString *)name parameters: (nullable NSDictionary *)parameters onComplete:(AsyncOperationComplete)onComplete;

- (void)completedTasksInTimeframe:(NSDictionary*)timeframe successBlock:(HttpSuccessBlock)successBlock errorBlock:(HttpErrorBlock)errorBlock;

- (void)uploadImageAttachmentData:(NSData *)imageData attachmentId:(NSString *)attachmentId type:(NSString *)type onComplete:(AsyncOperationComplete)onComplete;

- (void)uploadWorkerLocation:(nonnull NSDictionary<NSString *, id> *)data completion:(AsyncOperationComplete)onComplete;
- (void)uploadWorkerLocationsBatch:(nonnull NSArray<NSDictionary *> *)locationsData completion:(AsyncOperationComplete)onComplete;

- (BOOL)isNetworkError:(NSError*)httpError body:(nullable NSDictionary*)errorBody;

// God request, should have all functionality while all requests above will be removed
- (void)requestWithMethod:(NSString*)method
                 endpoint:(NSString *)endpoint
                   params:(NSDictionary <NSString *, id> *)params
                  headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                  account:(nullable Account *)account
             successBlock:(HttpSuccessNonNullBlock)successBlock
               errorBlock:(HttpErrorBlock)errorBlock NS_SWIFT_NAME(request(_:endpoint:params:headers:account:successBlock:errorBlock:));

@end

NS_ASSUME_NONNULL_END
