//
//  MFRLocalMessageThread.m
//  Ripple
//
//  Created by Ed Rex on 13/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRLocalMessageThread.h"
#import <Parse/Parse.h>
#import "MFRLocalUniqueID.h"
#import "AppDelegate.h"
#import "MFRDateTime.h"

@implementation MFRLocalMessageThread

#pragma mark - Creating local MessageThread
//-------------------------------
// Create and send message thread
//-------------------------------
+(NSMutableDictionary*)createMessageThreadWithMessage:(NSDictionary*)message recipients:(NSMutableArray*)recipients urlString:(NSString*)messageURLString titleString:(NSString*)titleString imageURLString:(NSString*)imageURLString originatorId:(NSString*)originatorId delegate:(id)delegate originalMessageThread:(NSMutableDictionary*)originalMessageThread originalMessagesToAdd:(NSMutableArray*)originalMessages {
    
    // COPIED:
    //----------------------
    // Create message thread
    //----------------------
    // If no title provided, create blank title
    if (!titleString) {
        titleString = @"";
    }
    
    // Mark that message is unread by repcipients
    NSMutableDictionary* unreadMarkers = [[NSMutableDictionary alloc] init];
    for (NSString* recipientId in recipients) {
        [unreadMarkers setObject:[NSNumber numberWithBool:YES] forKey:recipientId];
    }
    [unreadMarkers setObject:[NSNumber numberWithBool:NO] forKey:[PFUser currentUser].objectId];
    
    // Create message thread
    NSMutableDictionary* messageThread = [NSMutableDictionary dictionary];
    NSMutableArray* messages = [NSMutableArray array];
    if (originalMessages) {
        // This is a reply to an original, group message, so add the original message
        for (NSDictionary* originalMessage in originalMessages) {
            [messages addObject:originalMessage];
        }
    }
    [messages addObject:message];
    [messageThread setObject:messages forKey:@"Messages"];
    [messageThread setObject:unreadMarkers forKey:@"UnreadMarkers"];
    [messageThread setObject:originatorId forKey:@"originatorId"];
    [messageThread setObject:messageURLString forKey:@"linkString"];
    [messageThread setObject:imageURLString forKey:@"imageURL"];
    [messageThread setObject:titleString forKey:@"titleString"];
    [messageThread setObject:[MFRDateTime getCurrentGMTDateTime] forKey:@"createdAt"];
    [messageThread setObject:[MFRLocalUniqueID uuid] forKey:@"objectId"];
    
    if (originalMessageThread) {
        [messageThread setObject:[originalMessageThread objectForKey:@"objectId"] forKey:@"originalMessageThreadID"];
    }
    
    return messageThread;
}

//-------------------------------------------------
// Create a new message object given a message body
//-------------------------------------------------
+(NSDictionary*)buildMessageWithBody:(NSString*)body {
    
    //---------------
    // Create message
    //---------------
    NSDictionary* sender = [[NSDictionary alloc] initWithObjectsAndKeys:[PFUser currentUser].username, @"Username", nil];
    
    // Date/time
//    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
//    [DateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSString* dateString = [NSString stringWithFormat:@"%@",[DateFormatter stringFromDate:[NSDate date]]];
    
    NSString* gmtDateString = [MFRDateTime getCurrentGMTDateTimeString];
    
    NSDictionary* message = [[NSDictionary alloc] initWithObjectsAndKeys:body, @"Message", sender, @"Sender", gmtDateString, @"Date", [NSNumber numberWithInt:MFRLocalMessageStatusUnsent], @"SendingStatus", nil];
    
    return message;
}

#pragma mark - Replying to local MessageThread
+(NSMutableDictionary*)addReplyToLocalMessageThread:(NSMutableDictionary*)messageThread withMessage:(NSString*)message {
    //------------------------
    // Get message thread info
    //------------------------
    NSMutableArray* messages = [[messageThread objectForKey:@"Messages"] mutableCopy];
    NSMutableDictionary* unreadMarkers = [[messageThread objectForKey:@"UnreadMarkers"] mutableCopy];
    
    //---------------------
    // Create a new message
    //---------------------
    NSDictionary* messageToSend = [self buildMessageWithBody:message];
    NSString* originatorId = [messageThread objectForKey:@"originatorId"];
    
    if (
        ([[unreadMarkers allKeys] count] > 2)
        &&
        ![originatorId isEqualToString:[PFUser currentUser].objectId]
        ) {
        //--------------------------------------------------------------------------------------------------------
        // Original message thread was group message thread and requires replacement with one-to-one conversation.
        // Replace old message thread with new message thread, and send it to recipients.
        //--------------------------------------------------------------------------------------------------------
        NSArray* recipients = [NSArray arrayWithObject:originatorId];
        NSMutableDictionary* updatedMessageThread = [MFRLocalMessageThread createMessageThreadWithMessage:messageToSend recipients:(NSMutableArray*)recipients urlString:[messageThread objectForKey:@"linkString"] titleString:[messageThread objectForKey:@"titleString"] imageURLString:[messageThread objectForKey:@"imageURL"] originatorId:originatorId delegate:nil originalMessageThread:messageThread originalMessagesToAdd:messages];
        
        // Store new messageThread in NSUserDefaults
        [MFRLocalMessageThread storeMessageThread:updatedMessageThread];
        
        // Remove old messageThread from NSUserDefaults
        [MFRLocalMessageThread removeMessageThread:messageThread];
        
        return updatedMessageThread;
    } else {
        //---------------------------------
        // Reply to existing message thread
        //---------------------------------
        [messages addObject:messageToSend];
        [messageThread setObject:messages forKey:@"Messages"];
        
        // Get recipients
        NSMutableArray* recipients;
        if (![originatorId isEqualToString:[PFUser currentUser].objectId]) {
            recipients = [NSMutableArray arrayWithObject:originatorId];
        } else {
            recipients = [[unreadMarkers allKeys] mutableCopy];
            int currentUserEntry;
            for (int i = 0; i < [recipients count]; i++) {
                NSString* userID = [recipients objectAtIndex:i];
                if ([userID isEqualToString:[PFUser currentUser].objectId]) {
                    currentUserEntry = i;
                    break;
                }
            }
            [recipients removeObjectAtIndex:currentUserEntry];
        }
        
        // Update unread markers
        for (NSString* recipient in recipients) {
            [unreadMarkers setObject:[NSNumber numberWithBool:YES] forKey:recipient];
        }
        [messageThread setObject:unreadMarkers forKey:@"UnreadMarkers"];
        
        // Update messageThread in NSUserDefaults
        [MFRLocalMessageThread updateMessageThread:messageThread shouldUpdateTime:YES];
        
        return messageThread;
    }
}

#pragma mark - Storing, updating, and removing local MessageThread
+(void)storeMessageThread:(NSMutableDictionary*)messageThread {
    
    //------------------
    // Get user defaults
    //------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
    
    // Update 'updatedAt' date
    [messageThread setObject:[MFRDateTime getCurrentGMTDateTime] forKey:@"updatedAt"];
    
    //--------------------------------------------------------------
    // Insert messageThread at start of user defaults messageThreads
    //--------------------------------------------------------------
    [localMessageThreads insertObject:messageThread atIndex:0];
    
    //--------------------
    // Save NSUserDefaults
    //--------------------
    [appDelegate storeLocalMessageThreads:localMessageThreads];
}

+(void)removeMessageThread:(NSMutableDictionary*)messageThread {
    
    //------------------
    // Get user defaults
    //------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
    
    //-------------------------------------------------------
    // Remove messageThread from user defaults messageThreads
    //-------------------------------------------------------
    [localMessageThreads removeObject:messageThread];
    
    //--------------------
    // Save NSUserDefaults
    //--------------------
    [appDelegate storeLocalMessageThreads:localMessageThreads];
}

+(void)removeMessageThreadWithID:(NSString*)messageThreadID {
    //------------------
    // Get user defaults
    //------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
    
    int entryToUpdate;
    BOOL entryFound = NO;
    for (int i = 0; i < [localMessageThreads count]; i++) {
        if ([[[localMessageThreads objectAtIndex:i] objectForKey:@"objectId"] isEqualToString:messageThreadID]) {
            entryToUpdate = i;
            entryFound = YES;
            break;
        }
    }
    if (entryFound) {
        
        // Update messageThread in user defaults messageThreads
        [localMessageThreads removeObjectAtIndex:entryToUpdate];
        
        //--------------------
        // Save NSUserDefaults
        //--------------------
        [appDelegate storeLocalMessageThreads:localMessageThreads];
    }
}

+(void)updateMessageThread:(NSMutableDictionary*)messageThread shouldUpdateTime:(BOOL)shouldUpdateTime {
    
    //------------------
    // Get user defaults
    //------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
    
    //-----------------------------------------------------
    // Update messageThread in user defaults messageThreads
    //-----------------------------------------------------
    int entryToUpdate;
    BOOL entryFound = NO;
    for (int i = 0; i < [localMessageThreads count]; i++) {
        if ([[[localMessageThreads objectAtIndex:i] objectForKey:@"objectId"] isEqualToString:[messageThread objectForKey:@"objectId"]]) {
            entryToUpdate = i;
            entryFound = YES;
            break;
        }
    }
    if (entryFound) {
        
        if (shouldUpdateTime) {
            // Update 'updatedAt' date
            [messageThread setObject:[MFRDateTime getCurrentGMTDateTime] forKey:@"updatedAt"];
        }
        
        // Update messageThread in user defaults messageThreads
        [localMessageThreads replaceObjectAtIndex:entryToUpdate withObject:messageThread];
        
        //--------------------
        // Save NSUserDefaults
        //--------------------
        [appDelegate storeLocalMessageThreads:localMessageThreads];
    }
}

#pragma mark - Reading local MessageThread
//----------------------------------------------------------------------
// Return true if the given message thread is unread by the current user
//----------------------------------------------------------------------
+(BOOL)messageThreadIsUnread:(NSDictionary*)messageThread {
    return [[[messageThread objectForKey:@"UnreadMarkers"] objectForKey:[PFUser currentUser].objectId] boolValue];
}

+(NSDictionary*)getLatestMessageFromMessageThread:(NSMutableDictionary*)messageThread {
    NSMutableArray* messages = [[messageThread objectForKey:@"Messages"] mutableCopy];
    if ([messages count] > 0) {
        NSDictionary* latestMessage = [messages lastObject];
        return latestMessage;
    }
    return nil;
}

// Get immutable message thread with given ID
+(NSDictionary*)getMessageThreadWithId:(NSString*)messageId {
    
    //------------------
    // Get user defaults
    //------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
    
    int entryToFetch;
    BOOL entryFound = NO;
    for (int i = 0; i < [localMessageThreads count]; i++) {
        if ([[[localMessageThreads objectAtIndex:i] objectForKey:@"objectId"] isEqualToString:messageId]) {
            entryToFetch = i;
            entryFound = YES;
            break;
        }
    }
    if (entryFound) {
        return [localMessageThreads objectAtIndex:entryToFetch];
    }
    return nil;
}

#pragma mark - Altering local MessageThread ID
+(void)setNewObjectId:(NSString*)newObjectId forCurrentObjectId:(NSString*)oldObjectId {
    //------------------
    // Get user defaults
    //------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
    
    //-----------------------------------------------------
    // Update messageThread in user defaults messageThreads
    //-----------------------------------------------------
    int entryToUpdate;
    BOOL entryFound = NO;
    for (int i = 0; i < [localMessageThreads count]; i++) {
        if ([[[localMessageThreads objectAtIndex:i] objectForKey:@"objectId"] isEqualToString:oldObjectId]) {
            entryToUpdate = i;
            entryFound = YES;
            break;
        }
    }
    if (entryFound) {
        
        NSMutableDictionary* localMessageThread = [[localMessageThreads objectAtIndex:entryToUpdate] mutableCopy];
        [localMessageThread setObject:newObjectId forKey:@"objectId"];
        
        // Update messageThread in user defaults messageThreads
        [localMessageThreads replaceObjectAtIndex:entryToUpdate withObject:localMessageThread];
        
        //--------------------
        // Save NSUserDefaults
        //--------------------
        [appDelegate storeLocalMessageThreads:localMessageThreads];
    }
}

#pragma mark - Sending Status of message
+(void)setSendingStatus:(MFRLocalMessageStatus)sendingStatus forLatestMessageInMessageThreadWithId:(NSString*)messageThreadId {
    
    //------------------
    // Get user defaults
    //------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
    
    //---------------------------------------------------
    // Find messageThread in user defaults messageThreads
    //---------------------------------------------------
    int entryToUpdate;
    BOOL entryFound = NO;
    for (int i = 0; i < [localMessageThreads count]; i++) {
        if ([[[localMessageThreads objectAtIndex:i] objectForKey:@"objectId"] isEqualToString:messageThreadId]) {
            entryToUpdate = i;
            entryFound = YES;
            break;
        }
    }
    if (entryFound) {
        
        NSMutableDictionary* updatedMessageThread = [[localMessageThreads objectAtIndex:entryToUpdate] mutableCopy];
        NSMutableArray* messages = [[updatedMessageThread objectForKey:@"Messages"] mutableCopy];
        if ([messages count] > 0) {
            NSMutableDictionary* message = [[messages lastObject] mutableCopy];
            [message setObject:[NSNumber numberWithInt:sendingStatus] forKey:@"SendingStatus"];
            [messages replaceObjectAtIndex:([messages count] - 1) withObject:message];
            [updatedMessageThread setObject:messages forKey:@"Messages"];
            
            // Update messageThread in user defaults messageThreads
            [localMessageThreads replaceObjectAtIndex:entryToUpdate withObject:updatedMessageThread];
            
            //--------------------
            // Save NSUserDefaults
            //--------------------
            [appDelegate storeLocalMessageThreads:localMessageThreads];
        }
    }
}

+(MFRLocalMessageStatus)getSendingStatusForMessageNumber:(int)messageNumber inMessageThreadWithId:(NSString*)messageId {
    
    // Get message thread
    NSDictionary* messageThread = [MFRLocalMessageThread getMessageThreadWithId:messageId];
    
    if (messageThread) {
        // Get message
        NSArray* messages = [messageThread objectForKey:@"Messages"];
        if ([messages count] > 0) {
            // Get sending status
            NSDictionary* message = [messages objectAtIndex:messageNumber];
            return [MFRLocalMessageThread getSendingStatusFromMessage:message];
        }
    }
    
    // If no sending status, return MFRLocalMessageStatusSent as default (because the message must have been downloaded from the internet)
    return MFRLocalMessageStatusSent;
}

+(MFRLocalMessageStatus)getSendingStatusFromMessage:(NSDictionary*)message {
    if ([message objectForKey:@"SendingStatus"]) {
        NSNumber* sendingStatusNumber = [message objectForKey:@"SendingStatus"];
        return [sendingStatusNumber intValue];
    }
    return MFRLocalMessageStatusSent;
}

+(BOOL)messageThreadHasBeenSentToCloud:(NSMutableDictionary*)messageThread {
    
    for (NSDictionary* message in [messageThread objectForKey:@"Messages"]) {
        if (
            (![[[message objectForKey:@"Sender"] objectForKey:@"Username"] isEqualToString:[PFUser currentUser].username])
            ||
            (
             [message objectForKey:@"SendingStatus"]
             &&
             ([[message objectForKey:@"SendingStatus"] intValue] == MFRLocalMessageStatusSent)
             )
            ) {
            // There is a message that was sent by another user or that was successfully sent by the current user
            return YES;
        }
    }
    return NO;
    
//    if (
//        ([_messages count] == 1)
//        &&
//        [[[_messages objectAtIndex:0] objectForKey:@"Message"] isEqualToString:@""]
//        ) {
//        return YES;
//    }
//    return NO;
}

@end
