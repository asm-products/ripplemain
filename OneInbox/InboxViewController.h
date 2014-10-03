//
//  InboxViewController.h
//  Ripple
//
//  Created by Ed Rex on 21/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//
//  The InboxViewController displays all of a user's message threads, both sent and received. Data downloaded from Parse
//      (images and full names) loads in the background.

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "ComposeViewController.h"
#import "SettingsViewController.h"

@interface InboxViewController : UITableViewController<DeleteMessageDelegate, UIAlertViewDelegate> {
    
    @public
    id <ParentViewControlDelegate> parentDelegate;
}

@property (nonatomic, retain) UIBarButtonItem* composeButton;
@property (nonatomic, retain) UIBarButtonItem* settingsButton;
@property (nonatomic, retain) IBOutlet UIView* noMessagesView;
@property (nonatomic, retain) IBOutlet UILabel* noMessagesLabelOne;
@property (nonatomic, retain) IBOutlet UILabel* noMessagesLabelTwo;

-(void)refreshInbox:(id)sender;
-(void)getLocalMessageThreadsAndReloadInboxTableView;
//-(void)getMessageThreadsForUser:(id)sender;
//-(void)addNewMessageThread:(NSMutableDictionary*)messageThread;

-(void)updateBadge;

-(void)scrollToTopOfInbox;

-(void)removeAllMessagesInApp;

@end
