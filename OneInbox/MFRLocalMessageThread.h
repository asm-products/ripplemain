//
//  MFRLocalMessageThread.h
//  Ripple
//
//  Created by Ed Rex on 13/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MFRLocalMessageStatusUnsent = 0,
    MFRLocalMessageStatusSending,
    MFRLocalMessageStatusSent,
    MFRLocalMessageStatusSendingFailed
} MFRLocalMessageStatus;

@interface MFRLocalMessageThread : NSObject

+(BOOL)messageThreadIsUnread:(NSDictionary*)messageThread;

+(NSMutableDictionary*)addReplyToLocalMessageThread:(NSMutableDictionary*)messageThread withMessage:(NSString*)message;

+(NSDictionary*)buildMessageWithBody:(NSString*)body;

+(NSMutableDictionary*)createMessageThreadWithMessage:(NSDictionary*)message recipients:(NSMutableArray*)recipients urlString:(NSString*)messageURLString titleString:(NSString*)titleString imageURLString:(NSString*)imageURLString originatorId:(NSString*)originatorId delegate:(id)delegate originalMessageThread:(NSMutableDictionary*)originalMessageThread originalMessagesToAdd:(NSMutableArray*)originalMessages;

+(void)storeMessageThread:(NSMutableDictionary*)messageThread;
+(void)removeMessageThread:(NSMutableDictionary*)messageThread;
+(void)removeMessageThreadWithID:(NSString*)messageThreadID;
+(void)updateMessageThread:(NSMutableDictionary*)messageThread shouldUpdateTime:(BOOL)shouldUpdateTime;

+(NSDictionary*)getLatestMessageFromMessageThread:(NSMutableDictionary*)messageThread;

+(NSDictionary*)getMessageThreadWithId:(NSString*)messageId;

+(void)setNewObjectId:(NSString*)newObjectId forCurrentObjectId:(NSString*)oldObjectId;

+(void)setSendingStatus:(MFRLocalMessageStatus)sendingStatus forLatestMessageInMessageThreadWithId:(NSString*)messageThreadId;
+(MFRLocalMessageStatus)getSendingStatusForMessageNumber:(int)messageNumber inMessageThreadWithId:(NSString*)messageId;
+(MFRLocalMessageStatus)getSendingStatusFromMessage:(NSDictionary*)message;

+(BOOL)messageThreadHasBeenSentToCloud:(NSMutableDictionary*)messageThread;

@end
