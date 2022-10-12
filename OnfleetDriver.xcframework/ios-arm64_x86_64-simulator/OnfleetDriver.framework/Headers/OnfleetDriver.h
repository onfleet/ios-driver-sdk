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
//TODO: remove these from here and add them to Swift
extern NSString* const OnfleetErrorDomain;
extern const NSInteger OnfleetErrorCodeOperationNotDetermined;
extern const NSInteger OnfleetErrorCodeOperationCancelled;
extern const NSInteger OnfleetErrorCodeOperationFailed;
extern const NSInteger OnfleetErrorCodeOperationCanNotBeStarted;
