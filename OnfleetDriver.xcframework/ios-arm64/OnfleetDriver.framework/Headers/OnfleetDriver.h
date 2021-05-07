//
//  OnfleetDriverSDK.h
//  OnfleetDriverSDK
//
//  Created by Peter Stajger on 07/01/2021.
//

#import <Foundation/Foundation.h>

//! Project version number for OnfleetDriverSDK.
FOUNDATION_EXPORT double OnfleetDriverSDKVersionNumber;

//! Project version string for OnfleetDriverSDK.
FOUNDATION_EXPORT const unsigned char OnfleetDriverSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OnfleetDriverSDK/PublicHeader.h>

#import <OnfleetDriver/ONLogger.h>
#import <OnfleetDriver/HttpApi.h>
#import <OnfleetDriver/WebSocketApi.h>
#import <OnfleetDriver/LegacyAuthInfo.h>

extern NSString* const OnfleetErrorDomain;
extern const NSInteger OnfleetErrorCodeOperationNotDetermined;
extern const NSInteger OnfleetErrorCodeOperationCancelled;
extern const NSInteger OnfleetErrorCodeOperationFailed;
extern const NSInteger OnfleetErrorCodeOperationCanNotBeStarted;

extern const NSInteger OnfleetErrorCodeAuthAccountUnaccessible;
extern const NSInteger OnfleetErrorCodeAuthInvalidCredentials;
extern const NSInteger OnfleetErrorCodeAuthNoAccountsAvailable;
extern const NSInteger OnfleetErrorCodeAuthNoOrganizations;
extern const NSInteger OnfleetErrorCodeAuthNoOrganizations;
extern const NSInteger OnfleetErrorCodeAuthInvalidVerificationCode;
extern const NSInteger OnfleetErrorCodeAuthTooManyAttempts;
extern const NSInteger OnfleetErrorCodeAuthBadTime;
extern const NSInteger OnfleetErrorCodePasswordUpdateFail;

