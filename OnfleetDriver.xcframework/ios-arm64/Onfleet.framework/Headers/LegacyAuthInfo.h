//
//  AuthInfo.h
//  Onfleet Driver
//
//  Created by Andrii Cherkashyn on 7/13/17.
//  Copyright © 2017 Onfleet Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AccountStatus) {
    AccountStatusUnknown,
    AccountStatusAccepted,
    AccountStatusInvited,
    AccountStatusDeclined
};

@interface LegacyAuthInfo : NSObject <NSSecureCoding>

@property(nonatomic, copy) NSString *userId;
@property(nonatomic, copy) NSString *organizationId;
@property(nonatomic, copy) NSString *organizationName;
@property(nonatomic, copy) NSString *organizationImage;
@property(nonatomic) BOOL onDuty;
@property(nonatomic, copy) NSString * phoneNumber;
@property(nonatomic) AccountStatus accountStatus;

+ (LegacyAuthInfo*)fromDictionary:(NSDictionary*)dictionary;

- (NSString*)fullOrgImageUrl;

@end

NS_ASSUME_NONNULL_END
