//
//  ComposeViewController.h
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebEnabledViewController.h"
#import "BorderedTextView.h"
#import "LinkObject.h"
#import "RippleTextField.h"
#import "MFRMessageEntryView.h"
#import "HPGrowingTextView.h"

@protocol ParentViewControlDelegate
-(void)navigateLeftToInbox;
-(void)navigateLeftToCompose;
-(void)navigateRightToCompose;
-(void)navigateRightToContacts;
-(void)addSwipeGesture;
-(void)removeSwipeGesture;
@end

@interface ComposeViewController : WebEnabledViewController<UITextFieldDelegate, UITextViewDelegate, HPGrowingTextViewDelegate> {
    
    @public
//    id <DeleteLinkDelegate> deleteLinkDelegate;
    id <ParentViewControlDelegate> parentDelegate;
}

@property (nonatomic, retain) IBOutlet RippleTextField* linkTextField;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* loadingWheel;

@property (nonatomic, retain) IBOutlet MFRMessageEntryView* shareView;

@property (nonatomic, retain) IBOutlet UIBarButtonItem* inboxButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* contactsButton;
@property (nonatomic, retain) IBOutlet UITableView* searchResultsTableView;
@property (nonatomic, retain) IBOutlet UIButton* displayNextSearchResultsButton;
@property (nonatomic, retain) IBOutlet UIButton* displayPreviousSearchResultsButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* searchingWheel;
@property (nonatomic, retain) UIView* searchResultsMaskView;

//@property (nonatomic, retain) LinkObject* linkObject;

-(IBAction)pushContactsViewController;
-(IBAction)clickOutsideTextField:(id)sender;

-(void)showLinkElements;

-(void)updateFriendRequestsLabel:(NSNumber*)friendRequestsCount;

-(void)clearTextFieldAndDiscardLinkInfo;

@end
