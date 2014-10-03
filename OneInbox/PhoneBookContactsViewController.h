//
//  PhoneBookContactsViewController.h
//  Ripple
//
//  Created by Ed Rex on 25/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMessageComposeViewController.h>

@interface PhoneBookContactsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate>

@property (nonatomic, retain) IBOutlet UITableView* contactsTableView;
@property (nonatomic, retain) IBOutlet UIButton* sendButton;

-(IBAction)sendInvitationButtonPressed:(id)sender;

@end
