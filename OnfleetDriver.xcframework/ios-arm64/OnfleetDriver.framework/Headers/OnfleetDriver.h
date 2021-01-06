//
//  Onfleet.h
//  Onfleet
//
//  Created by Peter Stajger on 15/10/2020.
//  Copyright © 2020 Onfleet Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for Onfleet.
FOUNDATION_EXPORT double OnfleetVersionNumber;

//! Project version string for Onfleet.
FOUNDATION_EXPORT const unsigned char OnfleetVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Onfleet/PublicHeader.h>
#import <OnfleetDriver/Logger.h>
#import <OnfleetDriver/HttpApi.h>
#import <OnfleetDriver/WebSocketApi.h>
#import <OnfleetDriver/LegacyAuthInfo.h>

extern NSString* const OnfleetErrorDomain;
extern const NSInteger OnfleetErrorCodeOperationNotDetermined;
extern const NSInteger OnfleetErrorCodeOperationCancelled;
extern const NSInteger OnfleetErrorCodeOperationFailed;
extern const NSInteger OnfleetErrorCodeOperationCanNotBeStarted;

extern const NSInteger OnfleetErrorCodeInvalidPhoneNumber;

extern const NSInteger OnfleetErrorCodeAuthAccountUnaccessible;
extern const NSInteger OnfleetErrorCodeAuthInvalidCredentials;
extern const NSInteger OnfleetErrorCodeAuthNoAccountsAvailable;
extern const NSInteger OnfleetErrorCodeAuthNoOrganizations;
extern const NSInteger OnfleetErrorCodeAuthNoOrganizations;
extern const NSInteger OnfleetErrorCodeAuthInvalidVerificationCode;
extern const NSInteger OnfleetErrorCodeAuthTooManyAttempts;
extern const NSInteger OnfleetErrorCodeAuthBadTime;
extern const NSInteger OnfleetErrorCodePasswordUpdateFail;
