//
//  LinkObject.m
//  OneInbox
//
//  Created by Ed Rex on 04/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "LinkObject.h"
#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "MFRAnalytics.h"
#import "MFRLocalMessageThread.h"

@implementation LinkObject {
    
    NSUInteger _selectedImageNumber;
}

-(id)initWithURL:(NSURL*)url title:(NSString*)title
{
    self = [super init];
    if(self)
    {
        self.messageURL = url;
        self.messageTitle = title;
        _possibleImageURLs = [NSMutableArray array];
        _selectedImageNumber = 0;
    }
    return self;
}

-(id)initWithURL:(NSURL*)url title:(NSString*)title imageURL:(NSURL*)imageURL
{
    self = [super init];
    if(self)
    {
        self.messageURL = url;
        self.messageTitle = title;
        self.imageURL = imageURL;
        _possibleImageURLs = [NSMutableArray array];
        _selectedImageNumber = 0;
    }
    return self;
}

-(void)storeRecipients:(NSMutableArray*)recipients {
    
    // Store recipients
    self.recipients = [NSMutableArray arrayWithArray:recipients];
    
    // Build array of UserIDs
    self.userIDs = [NSMutableArray array];
    for (NSDictionary* contact in recipients){
        [self.userIDs addObject:[contact objectForKey:@"objectId"]];
    }
}

-(NSMutableDictionary*)createLocalMessageThreadWithMessageBody:(NSString*)messageBody {
    //---------------
    // Create message
    //---------------
    NSDictionary* message = [MFRLocalMessageThread buildMessageWithBody:messageBody];
    
    //---------------------
    // Create messageThread
    //---------------------
    // Title
    NSString* messageTitle;
    if (!_messageTitle) {
        messageTitle = @"";
    } else {
        messageTitle = _messageTitle;
    }
    
    // Image URL
    NSString* imageURLString;
    if (_imageURL) {
        imageURLString = [_imageURL absoluteString];
    } else {
        imageURLString = @"";
    }
    
    //---------------------
    // Create messageThread
    //---------------------
    NSMutableDictionary* messageThread = [MFRLocalMessageThread createMessageThreadWithMessage:message recipients:self.userIDs urlString:[_messageURL absoluteString] titleString:messageTitle imageURLString:imageURLString originatorId:[PFUser currentUser].objectId delegate:nil originalMessageThread:nil originalMessagesToAdd:nil];
    
    return messageThread;
}

/*
-(void)sendToContacts
{
    // Add link to each contact's inbox
    PFQuery* query = [PFQuery queryWithClassName:@"UserLinks"];
    [query whereKey:@"UserID" containedIn:self.userIDs];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Found contacts to send link to
            NSDictionary* sender = [[NSDictionary alloc] initWithObjectsAndKeys:[PFUser currentUser].username, @"Username", nil];
            NSString* message;
            if (_messageBody) {
                message = [NSString stringWithFormat:@"%@", _messageBody];
            } else {
                message = [NSString stringWithFormat:@""];
            }
            
            // Date/time
            NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
            [DateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString* dateString = [NSString stringWithFormat:@"%@",[DateFormatter stringFromDate:[NSDate date]]];
            
            // Image URL
            NSString* imageURLString;
            if (_imageURL) {
                imageURLString = [_imageURL absoluteString];
            } else {
                imageURLString = @"";
            }
            
            NSDictionary* link = [[NSDictionary alloc] initWithObjectsAndKeys:[_messageURL absoluteString], @"linkString", message, @"Message", sender, @"Sender", [NSNumber numberWithBool:YES], @"Unread", dateString, @"Date", imageURLString, @"imageURL", nil];
            for (PFObject* pfObj in objects) {
                [pfObj addObject:link forKey:@"ReceivedLinks"];
            }
//            [PFObject saveAllInBackground:objects];
            [PFObject saveAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    if (succeeded) {
                        // Inform History View that sending was successful
                        [self performSelectorOnMainThread:@selector(informSuccess:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
                    } else {
                        // Inform History View that sending was not successful
                        [self performSelectorOnMainThread:@selector(informSuccess:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
                    }
                } else {
                    // Inform History View that sending was not successful
                    [self performSelectorOnMainThread:@selector(informSuccess:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
                }
            }];
        } else {
            // ...
            [self performSelectorOnMainThread:@selector(informSuccess:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
        }
    }];
    
    // Send all contacts a push notification
    
//    // Inner query to find users
//    PFQuery* innerQuery = [PFUser query];
//    [innerQuery whereKey:@"objectId" containedIn:userIDs];
//    
//    // Actual push notification query
//    PFQuery *pushQuery = [PFInstallation query];
//    [pushQuery whereKey:@"user" matchesQuery:innerQuery];
//    
//    // Send push notification to query
//    PFPush* push = [[PFPush alloc] init];
//    [push setQuery:pushQuery];
//    [push setMessage:@"You've got a new message"];
//    [push sendPushInBackground];
    
    PFQuery* pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"UserID" containedIn:self.userIDs];
    
    // Send push notification to query
    PFPush* push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
//    [push setMessage:@"You've got a new message"];
    
    // Build message string
    NSString* messageString = [NSString stringWithFormat:@"%@ sent you a link", [PFUser currentUser].username];
    
    NSDictionary* data = [[NSDictionary alloc] initWithObjectsAndKeys:messageString, @"alert", @"Increment", @"badge", @"default", @"sound", nil];
    [push setData:data];
    [push sendPushInBackground];
}
*/

-(void)storeRecipientsWithRelations:(NSMutableArray*)recipients {
    
    // Store recipients
    self.recipients = [NSMutableArray arrayWithArray:recipients];
    
    // Build array of UserIDs
    self.userIDs = [NSMutableArray array];
    for (PFUser* contact in recipients){
        [self.userIDs addObject:contact.objectId];
    }
}

//-(void)informSuccess:(NSNumber*)b {
//    [delegate informSendingSuccess:[b boolValue]];
//}

-(void)addPossibleImageURL:(NSURL*)imageURL {
    [_possibleImageURLs addObject:imageURL];
}

-(void)addPossibleImageURLs:(NSMutableArray*)imageURLs {
    for (NSURL* imageURL in imageURLs) {
        
        /*
        // Check image URL is not already stored
        BOOL alreadyStored = NO;
        for (NSURL* storedURL in _possibleImageURLs) {
            if ([[storedURL absoluteString] isEqualToString:[imageURL absoluteString]]) {
                alreadyStored = YES;
                break;
            }
        }
        
        if (!alreadyStored) {
        */
            // URL not already stored, so add to array
            [_possibleImageURLs addObject:imageURL];
        /*
        }
        */
    }
}

-(BOOL)hasPossibleHTMLImageURLs {
    if ([_possibleImageURLs count] > 0) {
        return YES;
    }
    return NO;
}

-(NSURL*)getSelectedPossibleHTMLImageURL {
    return [_possibleImageURLs objectAtIndex:_selectedImageNumber];
}

-(void)moveToNextPossibleImage {
    _selectedImageNumber++;
    if (_selectedImageNumber >= [_possibleImageURLs count]) {
        _selectedImageNumber = 0;
    }
}

-(void)moveToPreviousPossibleImage {
    if (_selectedImageNumber == 0) {
        _selectedImageNumber = [_possibleImageURLs count] - 1;
    } else {
        _selectedImageNumber--;
    }
}

@end
