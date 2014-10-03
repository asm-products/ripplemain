//
//  AddContactsViewController.h
//  Ripple
//
//  Created by Ed Rex on 03/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RippleTextField.h"
#import "AddContactCell.h"

@protocol UpdateContactsVCDelegate
-(void)refreshContactsFromAppDelegate;
@end

@interface AddContactsViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, AddContactCellDelegate>

@property (nonatomic, retain) IBOutlet RippleTextField* usernameTextField;
@property (nonatomic, retain) NSMutableArray* usersFound;
@property (nonatomic, retain) IBOutlet UITableView* foundUsersTable;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* loadingWheel;
@property (nonatomic, retain) id<UpdateContactsVCDelegate> updateContactsVCDelegate;

// Copied from ContactsViewController
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* addingFriendWheel;
@property (nonatomic, retain) UIView* maskView;

-(IBAction)clickOutsideTextField:(id)sender;

@end
