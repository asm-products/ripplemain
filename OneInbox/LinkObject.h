//
//  LinkObject.h
//  OneInbox
//
//  Created by Ed Rex on 04/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFRParseMessageThread.h"

@protocol SendingSuccessDelegate
//-(void)informSendingSuccess:(BOOL)b;
@end

@interface LinkObject : NSObject<LinkObjectDelegate> {
    
@public
    id <SendingSuccessDelegate> delegate;
}

@property (nonatomic, retain) NSURL* messageURL;
@property (nonatomic, retain) NSString* messageTitle;
@property (nonatomic, retain) NSURL* imageURL;
@property (nonatomic, retain) NSMutableArray* recipients;
@property (nonatomic, retain) NSMutableArray* userIDs;
@property (nonatomic, retain) NSMutableArray* possibleImageURLs;

-(id)initWithURL:(NSURL*)url title:(NSString*)title;
-(id)initWithURL:(NSURL*)url title:(NSString*)title imageURL:(NSURL*)imageURL;

-(void)storeRecipients:(NSMutableArray*)recipients;

-(NSMutableDictionary*)createLocalMessageThreadWithMessageBody:(NSString*)messageBody;

// Transition between contacts and relations
-(void)storeRecipientsWithRelations:(NSMutableArray*)recipients;

-(void)addPossibleImageURL:(NSURL*)imageURL;
-(void)addPossibleImageURLs:(NSMutableArray*)imageURLs;
-(BOOL)hasPossibleHTMLImageURLs;
-(NSURL*)getSelectedPossibleHTMLImageURL;
-(void)moveToNextPossibleImage;
-(void)moveToPreviousPossibleImage;

@end
