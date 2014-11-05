//
//  ViewController.h
//  OneInbox
//
//  Created by Ed Rex on 02/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebEnabledViewController.h"
#import <Parse/Parse.h>
#import "MFRMessageEntryView.h"

@protocol DeleteMessageDelegate
-(void)updateMessageAsRead:(NSDictionary*)readDict;
-(void)updateMessageOrder;
//-(void)replaceMessageThread:(int)inboxEntry withMessageThread:(NSMutableDictionary*)messageThread;
@end

@interface ViewController : WebEnabledViewController <UIActionSheetDelegate, UIAlertViewDelegate> {
    
    @public
    id <DeleteMessageDelegate> deleteMessageDelegate;
    NSInteger inboxEntry;
}

@property (nonatomic, retain) IBOutlet UITextView* messageView;
@property (nonatomic, retain) IBOutlet UILabel* fromLabel;
@property (nonatomic, retain) IBOutlet UILabel* nameLabel;
@property (nonatomic, retain) IBOutlet UIButton* discardButton;
@property (nonatomic, retain) NSMutableDictionary* messageThread;
@property (nonatomic, retain) NSString* messageText;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* loadingWheel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* forwardButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* markAsUnreadButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* fixedSpace;
@property (nonatomic, retain) MFRMessageEntryView* replyView;
@property (nonatomic, retain) UIScrollView* scrollView;

@property (nonatomic, retain) UIProgressView* progressView;
@property (nonatomic, retain) NSTimer* replyTimer;

-(IBAction)clickOutsideTextField:(id)sender;
-(IBAction)switchUnread:(id)sender;

-(void)showLinkElements;

-(void)notifyReplySuccess:(BOOL)success updatedMessageID:(NSString*)updatedMessageID;
-(NSString*)getMessageThreadID;

@end
