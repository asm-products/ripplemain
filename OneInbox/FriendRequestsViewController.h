//
//  FriendRequestsViewController.h
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddContactCell.h"
#import "AddContactsViewController.h"

@protocol UpdateFriendRequestTitleDelegate
-(void)setFriendRequestCountInTitle:(NSNumber*)friendRequestCount;
@end

@interface FriendRequestsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, AddContactCellDelegate> {
    @public
    id <UpdateFriendRequestTitleDelegate> updateFriendRequestTitleDelegate;
}

@property (nonatomic, retain) IBOutlet UITableView* friendRequestsTableView;
@property (nonatomic, retain) IBOutlet NSMutableArray* receivedRequests;
@property (nonatomic, retain) id<UpdateContactsVCDelegate> updateContactsVCDelegate;

// Copied from ContactsViewController
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* addingFriendWheel;
@property (nonatomic, retain) UIView* maskView;

@end
