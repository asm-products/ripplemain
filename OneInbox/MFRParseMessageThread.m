//
//  MFRParseMessageThread.m
//  Ripple
//
//  Created by Ed Rex on 27/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRParseMessageThread.h"
#import "AppDelegate.h"
#import "MFRAnalytics.h"
#import "MFRLocalMessageThread.h"
#import "MFRDateTime.h"

@implementation MFRParseMessageThread

#pragma mark - Replying to a cloud MessageThread
//------------------------------------------------------------
// Reply to a given message thread with a given message string
//------------------------------------------------------------
+(void)replyToMessageThread:(PFObject*)messageThread withMessage:(NSString*)message delegate:(id)replyDelegate localMessageThreadId:(NSString *)localMessageThreadId {
    
    //-----------------------------------------------------------------------------------
    // Check this is the latest version of the message thread and get message thread info
    //-----------------------------------------------------------------------------------
    [messageThread fetch];
    NSMutableArray* messages = [[messageThread objectForKey:@"Messages"] mutableCopy];
    NSMutableDictionary* unreadMarkers = [messageThread objectForKey:@"UnreadMarkers"];
    
    //---------------------
    // Create a new message
    //---------------------
    NSDictionary* messageToSend = [MFRParseMessageThread buildMessageWithBody:message];
    PFUser* originator = [messageThread objectForKey:@"Originator"];
    
    if (
        ([[unreadMarkers allKeys] count] > 2)
        &&
        ![originator.objectId isEqualToString:[PFUser currentUser].objectId]
        ) {
        //--------------------------------------------------------------------------------------------------------
        // Original message thread was group message thread and requires replacement with one-to-one conversation.
        // Replace old message thread with new message thread, and send it to recipients.
        //--------------------------------------------------------------------------------------------------------
        NSArray* recipients = [NSArray arrayWithObject:originator.objectId];
        [MFRParseMessageThread createAndOverwriteMessageThreadWithMessage:messageToSend recipients:(NSMutableArray*)recipients urlString:[messageThread objectForKey:@"linkString"] titleString:[messageThread objectForKey:@"titleString"] imageURLString:[messageThread objectForKey:@"imageURL"] originator:originator delegate:nil replyDelegate:replyDelegate originalMessageThread:messageThread originalMessagesToAdd:messages localMessageThreadId:localMessageThreadId];
    } else {
        //---------------------------------
        // Reply to existing message thread
        //---------------------------------
        [messages addObject:messageToSend];
        [messageThread setObject:messages forKey:@"Messages"];
        
        [MFRParseMessageThread updateExistingMessageThreadAndNotifyRecipients:messageThread originator:originator unreadMarkers:unreadMarkers replyDelegate:replyDelegate];
    }
}

//---------------------------------------------------------
// Create and send message thread, overwriting the original
//---------------------------------------------------------
+(void)createAndOverwriteMessageThreadWithMessage:(NSDictionary*)message recipients:(NSMutableArray*)recipients urlString:(NSString*)messageURLString titleString:(NSString*)titleString imageURLString:(NSString*)imageURLString originator:(PFUser*)originator delegate:(id)delegate replyDelegate:(id)replyDelegate originalMessageThread:(PFObject*)originalMessageThread originalMessagesToAdd:(NSMutableArray*)originalMessages localMessageThreadId:(NSString*)localMessageThreadId {
    
    //---------------------------------------------
    // Create and store message thread in the cloud
    //---------------------------------------------
    // If no title provided, create blank title
    if (!titleString) {
        titleString = @"";
    }
    
    // Mark that message is unread by recipients
    NSMutableDictionary* unreadMarkers = [[NSMutableDictionary alloc] init];
    for (NSString* recipientId in recipients) {
        [unreadMarkers setObject:[NSNumber numberWithBool:YES] forKey:recipientId];
    }
    [unreadMarkers setObject:[NSNumber numberWithBool:NO] forKey:[PFUser currentUser].objectId];
    
    // Create and store message thread in the cloud
    PFObject* messageThread = [[PFObject alloc] initWithClassName:@"MessageThread"];
    
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
    [messageThread setObject:originator forKey:@"Originator"];
    [messageThread setObject:messageURLString forKey:@"linkString"];
    [messageThread setObject:imageURLString forKey:@"imageURL"];
    [messageThread setObject:titleString forKey:@"titleString"];
    
    [MFRParseMessageThread saveOrOverwriteMessageThreadAndNotifyRecipients:messageThread recipients:recipients replyDelegate:replyDelegate originalMessageThread:originalMessageThread delegate:delegate localMessageThreadId:localMessageThreadId];
}

//-------------------------------------------------------------------------------------
// Update in the cloud a given locally-altered message thread and notify the recipients
//-------------------------------------------------------------------------------------
+(void)updateExistingMessageThreadAndNotifyRecipients:(PFObject*)messageThread originator:(PFUser*)originator unreadMarkers:(NSMutableDictionary*)unreadMarkers replyDelegate:(id)replyDelegate {
    // Get recipients
    NSMutableArray* recipients;
    if (![originator.objectId isEqualToString:[PFUser currentUser].objectId]) {
        recipients = [NSMutableArray arrayWithObject:originator.objectId];
    } else {
        recipients = [[unreadMarkers allKeys] mutableCopy];
        for (int i = 0; i < [recipients count]; i++) {
            NSString* userID = [recipients objectAtIndex:i];
            if ([userID isEqualToString:[PFUser currentUser].objectId]) {
                [recipients removeObjectAtIndex:i];
                break;
            }
        }
    }
    
    // Update unread markers
    for (NSString* recipient in recipients) {
        [unreadMarkers setObject:[NSNumber numberWithBool:YES] forKey:recipient];
    }
    [messageThread setObject:unreadMarkers forKey:@"UnreadMarkers"];
    
//    [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSending forLatestMessageInMessageThreadWithId:messageThread.objectId];
    
    //----------------------
    // Save message to cloud
    //----------------------
    [messageThread saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        if (!error && succeeded) {
            
            [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSent forLatestMessageInMessageThreadWithId:messageThread.objectId];
            
            // Send all recipients a notification
            NSString* messageString = [NSString stringWithFormat:@"%@ replied to your message", [PFUser currentUser].username];
            [MFRParseMessageThread sendPushNotificationWithMessage:messageString toRecipients:recipients];
            
            NSNumber* recipientCount= [NSNumber numberWithInteger:[recipients count]];
            NSDictionary *dimensions = @{ @"Number of recipients": [recipientCount stringValue] };
            [MFRAnalytics trackEvent:@"Reply sent successfully" dimensions:dimensions];
            
            // Notify sender of success
            [appDelegate notifyViewControllersOfReplySuccess:YES forMessageThreadID:messageThread.objectId];
//            [replyDelegate notifyReplySuccess:YES];
        } else {
            
            [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSendingFailed forLatestMessageInMessageThreadWithId:messageThread.objectId];
            
            [MFRAnalytics trackEvent:@"Reply sending failed"];
            
            [appDelegate notifyViewControllersOfReplySuccess:NO forMessageThreadID:messageThread.objectId];
//            [replyDelegate notifyReplySuccess:NO];
        }
    }];
}

#pragma mark - Creating messageThread
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
    
    NSDictionary* message = [[NSDictionary alloc] initWithObjectsAndKeys:body, @"Message", sender, @"Sender", gmtDateString, @"Date", nil];
    
    return message;
}

#pragma mark - Creating cloud message thread from local message thread
+(void)createAndSendParseMessageThreadWithLocalMessageThread:(NSMutableDictionary*)localMessageThread recipients:(NSMutableArray*)recipients delegate:(id)delegate {
    //---------------------------------------------
    // Create and store message thread in the cloud
    //---------------------------------------------
    PFObject* messageThread = [[PFObject alloc] initWithClassName:@"MessageThread"];
    
    // Create versions of messages without SendingStatus (which is purely for local purposes)
    NSArray* localMessages = [localMessageThread objectForKey:@"Messages"];
    NSMutableArray* cloudMessages = [NSMutableArray array];
    for (NSDictionary* localMessage in localMessages) {
        NSDictionary* cloudMessage = [NSDictionary dictionaryWithObjectsAndKeys:[localMessage objectForKey:@"Message"], @"Message", [localMessage objectForKey:@"Sender"], @"Sender", [localMessage objectForKey:@"Date"], @"Date", nil];
        [cloudMessages addObject:cloudMessage];
    }
    
    [messageThread setObject:cloudMessages forKey:@"Messages"];
    [messageThread setObject:[localMessageThread objectForKey:@"UnreadMarkers"] forKey:@"UnreadMarkers"];
    [messageThread setObject:[localMessageThread objectForKey:@"linkString"] forKey:@"linkString"];
    [messageThread setObject:[localMessageThread objectForKey:@"imageURL"] forKey:@"imageURL"];
    [messageThread setObject:[localMessageThread objectForKey:@"titleString"] forKey:@"titleString"];
    [messageThread setObject:[PFUser currentUser] forKey:@"Originator"];
    
    [MFRParseMessageThread saveOrOverwriteMessageThreadAndNotifyRecipients:messageThread recipients:recipients replyDelegate:nil originalMessageThread:nil delegate:delegate localMessageThreadId:[localMessageThread objectForKey:@"objectId"]];
}

#pragma mark - Sending messageThread
//--------------------------------------------------------------------------
// Save a message thread in the cloud, overwriting the original if necessary
//--------------------------------------------------------------------------
+(void)saveOrOverwriteMessageThreadAndNotifyRecipients:(PFObject*)messageThread recipients:(NSArray*)recipients replyDelegate:(id)replyDelegate originalMessageThread:(PFObject*)originalMessageThread delegate:(id)delegate localMessageThreadId:(NSString*)localMessageThreadId {
    
//    [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSending forLatestMessageInMessageThreadWithId:localMessageThreadId];
    
    // Save the messageThread
    [messageThread saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        // Helper
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        if (succeeded && !error) {
            
            //-----------------------------------------------
            // Set objectId of local version of messageThread
            //-----------------------------------------------
            [MFRLocalMessageThread setNewObjectId:messageThread.objectId forCurrentObjectId:localMessageThreadId];
            
            //----------------------------------------------------------------------
            // Store reference to message thread in the inbox of every user involved
            //----------------------------------------------------------------------
            // Create array of sender and recipients
            NSMutableArray* messageUsers = [NSMutableArray arrayWithArray:recipients];
            AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [messageUsers addObject:[PFUser currentUser].objectId];
            
            PFQuery* query = [PFQuery queryWithClassName:@"UserLinks"];
            [query whereKey:@"UserID" containedIn:messageUsers];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                for (PFObject* pfObj in objects) {
                    PFRelation* relation = [pfObj objectForKey:@"MessageThreads"];
                    [relation addObject:messageThread];
                    if ([[pfObj objectForKey:@"UserID"] isEqualToString:[PFUser currentUser].objectId]) {
                        
                        if (replyDelegate) {
                            // This is a reply to a group message, so remove the original message thread from this user's inbox in the cloud
                            PFQuery* relationQuery = [relation query];
                            NSMutableArray* messageThreads = [[relationQuery findObjects] mutableCopy];
                            for (PFObject* pfObj in messageThreads) {
                                if ([pfObj.objectId isEqualToString:originalMessageThread.objectId ]) {
                                    [relation removeObject:pfObj];
                                }
                            }
                            [pfObj save];
                        }
                        
                        // Store sender's new info locally
                        //                [appDelegate storeUserLinks:pfObj];
                    }
                }
                [PFObject saveAllInBackground:objects block:^(BOOL savingRecipientsSucceeded, NSError *saveRecipientsError) {
                    
                    if (
                        !saveRecipientsError
                        &&
                        savingRecipientsSucceeded
                        ) {
                        
                        // Build message string
                        NSString* messageString;
                        if (delegate) {
                            // Original link
                            messageString = [NSString stringWithFormat:@"%@ sent you a link", [PFUser currentUser].username];
                        } else {
                            // Reply
                            messageString = [NSString stringWithFormat:@"%@ replied to your message", [PFUser currentUser].username];
                        }
                        
                        // Send all recipients a notification
                        [MFRParseMessageThread sendPushNotificationWithMessage:messageString toRecipients:recipients];
                        
                        [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSent forLatestMessageInMessageThreadWithId:messageThread.objectId];
                        
                        if (delegate) {
                            // Inform Compose Screen that sending was successful
//                            [delegate performSelectorOnMainThread:@selector(informSuccess:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
//                            [appDelegate performSelectorOnMainThread:@selector(reloadInboxViewController) withObject:nil waitUntilDone:NO];
                            [appDelegate notifyViewControllersOfReplySuccess:YES forOldMessageThreadID:localMessageThreadId andNewMessageThreadID:messageThread.objectId];
                            
                            // Tell AppDelegate to add new MessageThread to the inbox
                            //                    [appDelegate addNewMessageThreadInInbox:messageThread];
                            
                            NSNumber* recipientCount= [NSNumber numberWithInteger:[recipients count]];
                            NSDictionary *dimensions = @{ @"Number of recipients": [recipientCount stringValue] };
                            [MFRAnalytics trackEvent:@"Link sent successfully" dimensions:dimensions];
                            
                        } else {
                            //                    [MFRParseMessageThread deleteReferenceToOriginalMessageThread:messageThread replyDelegate:replyDelegate];
                            
//                            [appDelegate notifyViewControllersOfReplySuccess:YES forMessageThreadID:messageThread.objectId];
                            [appDelegate notifyViewControllersOfReplySuccess:YES forOldMessageThreadID:localMessageThreadId andNewMessageThreadID:messageThread.objectId];
//                            [replyDelegate notifyReplySuccess:YES];
                            
                            NSNumber* recipientCount= [NSNumber numberWithInteger:[recipients count]];
                            NSDictionary *dimensions = @{ @"Number of recipients": [recipientCount stringValue] };
                            [MFRAnalytics trackEvent:@"Reply sent successfully" dimensions:dimensions];
                        }
                    }
                    else {
                        [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSendingFailed forLatestMessageInMessageThreadWithId:messageThread.objectId];
                        
                        if (delegate) {
                            // Inform Compose Screen that sending was not successful
//                            [delegate performSelectorOnMainThread:@selector(informSuccess:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
//                            [appDelegate performSelectorOnMainThread:@selector(reloadInboxViewController) withObject:nil waitUntilDone:NO];
                            [appDelegate notifyViewControllersOfReplySuccess:NO forOldMessageThreadID:localMessageThreadId andNewMessageThreadID:messageThread.objectId];
                            
                            [MFRAnalytics trackEvent:@"Link sending failed"];
                        } else {
//                            [appDelegate notifyViewControllersOfReplySuccess:NO forMessageThreadID:messageThread.objectId];
                            [appDelegate notifyViewControllersOfReplySuccess:NO forOldMessageThreadID:localMessageThreadId andNewMessageThreadID:messageThread.objectId];
//                            [replyDelegate notifyReplySuccess:NO];
                            
                            [MFRAnalytics trackEvent:@"Reply sending failed"];
                        }
                    }
                }];
            }];
        } else {
            [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSendingFailed forLatestMessageInMessageThreadWithId:localMessageThreadId];
            
            if (delegate) {
                // Inform Compose Screen that sending was not successful
//                [delegate performSelectorOnMainThread:@selector(informSuccess:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
//                [appDelegate performSelectorOnMainThread:@selector(reloadInboxViewController) withObject:nil waitUntilDone:NO];
                [appDelegate notifyViewControllersOfReplySuccess:NO forMessageThreadID:localMessageThreadId];
                
                [MFRAnalytics trackEvent:@"Link sending failed"];
            } else {
                [appDelegate notifyViewControllersOfReplySuccess:NO forMessageThreadID:localMessageThreadId];
//                [replyDelegate notifyReplySuccess:NO];
                
                [MFRAnalytics trackEvent:@"Reply sending failed"];
            }
        }
    }];
}

#pragma mark - Push notifications
//------------------------------------------
// Send given recipients a push notification
//------------------------------------------
+(void)sendPushNotificationWithMessage:(NSString*)messageString toRecipients:(NSArray*)recipients {
    
    PFQuery* pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"UserID" containedIn:recipients];
    PFPush* push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    
    NSDictionary* data = [[NSDictionary alloc] initWithObjectsAndKeys:messageString, @"alert", @"Increment", @"badge", @"default", @"sound", nil];
    [push setData:data];
    [push sendPushInBackground];
}

#pragma mark - Accessing messageThread
//----------------------------------------------------------------------
// Fetch from the cloud the Parse MessageThread object with the given ID
//----------------------------------------------------------------------
+(PFObject*)getParseMessageThreadWithID:(NSString*)objectId {
    PFQuery* query = [[PFQuery alloc] initWithClassName:@"MessageThread"];
    [query whereKey:@"objectId" equalTo:objectId];
    PFObject* parseMessageThread = [query getFirstObject];
    return parseMessageThread;
}

+(NSDictionary*)getLatestMessageFromMessageThread:(PFObject*)messageThread {
    NSMutableArray* messages = [[messageThread objectForKey:@"Messages"] mutableCopy];
    if ([messages count] > 0) {
        NSDictionary* latestMessage = [messages lastObject];
        return latestMessage;
    }
    return nil;
}

//--------------------------------------------------------------------------------------------------------------
// Check whether a cloud message thread and a local message thread have the same timestamp on their last message
//--------------------------------------------------------------------------------------------------------------
+(BOOL)cloudMessageThread:(PFObject*)cloudMessageThread hasSameLastMessageTimeAsLocalMessageThread:(NSMutableDictionary*)localMessageThread {
    
    NSDictionary* latestCloudMessage = [MFRParseMessageThread getLatestMessageFromMessageThread:cloudMessageThread];
    NSDictionary* latestLocalMessage = [MFRLocalMessageThread getLatestMessageFromMessageThread:localMessageThread];
    
    if (
        !latestCloudMessage
        &&
        !latestLocalMessage
        ) {
        return YES;
    } else if (
               latestCloudMessage
               &&
               latestLocalMessage
               ) {
        
        NSDate* latestCloudMessageGMTDate = [MFRDateTime convertStringToNSDate:[latestCloudMessage objectForKey:@"Date"]];
        NSDate* latestLocalMessageGMTDate = [MFRDateTime convertStringToNSDate:[latestLocalMessage objectForKey:@"Date"]];
        
//        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
//        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//        
//        NSDate* latestCloudMessageDate = [formatter dateFromString:[latestCloudMessage objectForKey:@"Date"]];
//        NSDate* latestLocalMessageDate = [formatter dateFromString:[latestLocalMessage objectForKey:@"Date"]];
        
        if ([latestCloudMessageGMTDate isEqualToDate:latestLocalMessageGMTDate]) {
            return YES;
        }
        return NO;
    }
    return NO;
}

#pragma mark - Updating messageThread
+(void)updateMessageThreadWithID:(NSString*)objectId withNewUnreadMarkers:(NSMutableDictionary*)unreadMarkers {
    
    PFObject* messageThread = [MFRParseMessageThread getParseMessageThreadWithID:objectId];
    [messageThread setObject:unreadMarkers forKey:@"UnreadMarkers"];
    [messageThread saveInBackground];
}

@end
