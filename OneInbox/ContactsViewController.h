//
//  ContactsViewController.h
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LinkObject.h"
#import "MHTabBarController.h"
#import "ComposeViewController.h"

//@protocol DeleteLinkDelegate
//-(void)deleteFirstLink;
//@end

@protocol WebViewDelegate
-(IBAction)dismissWebView;
@end

@interface ContactsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, SendingSuccessDelegate, UIAlertViewDelegate, MHTabBarControllerDelegate, UpdateContactsVCDelegate> {
    
    @public
    BOOL _sendingLink;
    BOOL _originalLink;
    BOOL pushedFromWebView;
//    id <DeleteLinkDelegate> deleteLinkDelegate;
    id <WebViewDelegate> webViewDelegate;
    id <ParentViewControlDelegate> parentDelegate;
}

@property (nonatomic, retain) LinkObject* linkObject;
@property (nonatomic, retain) IBOutlet UITableView* contactsTableView;
@property (nonatomic, retain) IBOutlet UIButton* sendButton;

@property (nonatomic, retain) UIBarButtonItem* composeButton;
@property (nonatomic, retain) UIBarButtonItem* addContactsButton;

@property (nonatomic, retain) NSString* messageBody;

-(IBAction)sendButtonPressed:(id)sender;

-(IBAction)pushComposeViewController;
-(IBAction)addContactsButtonPressed;

@end
