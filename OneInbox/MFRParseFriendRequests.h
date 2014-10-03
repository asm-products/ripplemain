//
//  MFRParseFriendRequests.h
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

typedef enum {
    MFRFriendRequestPending = 0,
    MFRFriendRequestAccepted,
    MFRFriendRequestRejected,
    MFRFriendRequestSendingFailed
} MFRFriendRequestStatus;

@interface MFRParseFriendRequests : NSObject

+(MFRFriendRequestStatus)addContact:(PFUser*)contactToAdd;

@end
