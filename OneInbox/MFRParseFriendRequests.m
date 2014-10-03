//
//  MFRParseFriendRequests.m
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRParseFriendRequests.h"
#import "AppDelegate.h"
#import "MFRAnalytics.h"

@implementation MFRParseFriendRequests

+(MFRFriendRequestStatus)addContact:(PFUser*)contactToAdd {
    
    //---------------------------------------------------------------------
    // Establish whether the other user has sent this user a request or not
    //---------------------------------------------------------------------
    PFQuery* friendRequestsQuery = [PFQuery queryWithClassName:@"FriendRequest"];
    [friendRequestsQuery whereKey:@"Sender" equalTo:contactToAdd];
    [friendRequestsQuery whereKey:@"Recipient" equalTo:[PFUser currentUser]];
    NSArray* requests = [friendRequestsQuery findObjects];
    if ([requests count] == 0) {
        //----------------------------------------------------------------------------------
        // The other user has not sent a request to the current user, so send them a request
        //----------------------------------------------------------------------------------
        PFObject* friendRequest = [[PFObject alloc] initWithClassName:@"FriendRequest"];
        [friendRequest setObject:[PFUser currentUser] forKey:@"Sender"];
        [friendRequest setObject:contactToAdd forKey:@"Recipient"];
        
        NSError* error;
        [friendRequest save:&error];
        if (!error) {
            [MFRParseFriendRequests notifyUserOfFriendRequest:contactToAdd];
            
            [MFRAnalytics trackEvent:@"Friend request sent"];
            
            return MFRFriendRequestPending;
        } else {
            
            [MFRAnalytics trackEvent:@"Friend request sending failed"];
            
            return MFRFriendRequestSendingFailed;
        }
    } else {
        //--------------------------------------------------------------------------------
        // The other user has sent a request to the current user, so create the friendship
        //--------------------------------------------------------------------------------
        AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        PFObject* userLinks = [appDelegate getUserLinks];
        
        // Add the other user as a contact for the current user
        PFRelation* relation = [userLinks objectForKey:@"Friendships"];
        [relation addObject:contactToAdd];
        [userLinks saveInBackground];
        
        // Add the current user as a contact for the other user
        PFQuery* contactToAddQuery = [PFQuery queryWithClassName:@"UserLinks"];
        [contactToAddQuery whereKey:@"UserID" equalTo:contactToAdd.objectId];
        PFObject* contactToAddUserLinks = [contactToAddQuery getFirstObject];
        PFRelation* friendRelation = [contactToAddUserLinks objectForKey:@"Friendships"];
        [friendRelation addObject:[PFUser currentUser]];
        [contactToAddUserLinks saveInBackground];
        
        // Delete the friend request
        PFObject* friendRequest = [requests objectAtIndex:0];
        [friendRequest delete];
        
        [MFRParseFriendRequests notifyUserOfFriendAcceptance:contactToAdd];
        
        [MFRAnalytics trackEvent:@"Friend request accepted"];
        
        return MFRFriendRequestAccepted;
    }
}

+(void)notifyUserOfFriendRequest:(PFUser*)user {
    
    // Send all recipients a push notification
    PFQuery* pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"UserID" equalTo:user.objectId];
    
    // Send push notification to query
    PFPush* push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    
    // Build message string
    NSString* messageString = [NSString stringWithFormat:@"%@ wants to add you as a friend", [PFUser currentUser].username];
    
    NSDictionary* data = [[NSDictionary alloc] initWithObjectsAndKeys:messageString, @"alert", @"Increment", @"badge", @"default", @"sound", @"FriendRequest", @"MFRPushType", nil];
    [push setData:data];
    [push sendPushInBackground];
}

+(void)notifyUserOfFriendAcceptance:(PFUser*)user {
    
    // Send all recipients a push notification
    PFQuery* pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"UserID" equalTo:user.objectId];
    
    // Send push notification to query
    PFPush* push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    
    // Build message string
    NSString* messageString = [NSString stringWithFormat:@"%@ accepted your friend request", [PFUser currentUser].username];
    
    NSDictionary* data = [[NSDictionary alloc] initWithObjectsAndKeys:messageString, @"alert", @"default", @"sound", @"FriendAcceptance", @"MFRPushType", nil];
    [push setData:data];
    [push sendPushInBackground];
}

@end
