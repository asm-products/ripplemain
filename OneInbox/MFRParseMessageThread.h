//
//  MFRParseMessageThread.h
//  Ripple
//
//  Created by Ed Rex on 27/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//
//  The MFRParseMessageThread class is used to send messages to other users.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@protocol ReplyDelegate
//-(void)notifyReplySuccess:(BOOL)success;
//-(void)replaceMessageThreadWithMessageThread:(NSMutableDictionary*)messageThread;
@end

@protocol LinkObjectDelegate
//-(void)informSuccess:(NSNumber*)b;
@end

@interface MFRParseMessageThread : NSObject

+(void)replyToMessageThread:(PFObject*)messageThread withMessage:(NSString*)message delegate:(id)replyDelegate  localMessageThreadId:(NSString*)localMessageThreadId;

+(PFObject*)getParseMessageThreadWithID:(NSString*)objectId;

+(void)createAndSendParseMessageThreadWithLocalMessageThread:(NSMutableDictionary*)localMessageThread recipients:(NSMutableArray*)recipients delegate:(id)delegate;

+(void)saveOrOverwriteMessageThreadAndNotifyRecipients:(PFObject*)messageThread recipients:(NSArray*)recipients replyDelegate:(id)replyDelegate originalMessageThread:(PFObject*)originalMessageThread delegate:(id)delegate localMessageThreadId:(NSString*)localMessageThreadId;

+(void)updateMessageThreadWithID:(NSString*)objectId withNewUnreadMarkers:(NSMutableDictionary*)unreadMarkers;

+(BOOL)cloudMessageThread:(PFObject*)cloudMessageThread hasSameLastMessageTimeAsLocalMessageThread:(NSMutableDictionary*)localMessageThread;

@end
