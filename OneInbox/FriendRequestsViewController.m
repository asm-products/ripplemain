//
//  FriendRequestsViewController.m
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "FriendRequestsViewController.h"
#import <Parse/Parse.h>
#import "MFRParseFriendRequests.h"
#import "AppDelegate.h"

@interface FriendRequestsViewController ()

@end

@implementation FriendRequestsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _receivedRequests = [appDelegate getFriendRequests];
    
    [self.friendRequestsTableView registerClass:[AddContactCell class] forCellReuseIdentifier:@"FriendRequestCell"];
    
    _maskView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _maskView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    [self showAddingFriendWheel:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if ([appDelegate shouldReloadFriendRequestsVC]) {
        _receivedRequests = [appDelegate getFriendRequests];
        [_friendRequestsTableView reloadData];
        [updateFriendRequestTitleDelegate setFriendRequestCountInTitle:[NSNumber numberWithInteger:[_receivedRequests count]]];
        [appDelegate setShouldReloadFriendRequestsVC:NO];
    }
    
    // Set the application's badge according to the number of unread messages in the inbox
    [appDelegate setBadgeAccordingToInbox];
}

#pragma mark - Table view delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_receivedRequests count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendRequestCell";
    
    AddContactCell* cell = (AddContactCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AddContactCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    PFObject* friendRequest = [_receivedRequests objectAtIndex:indexPath.row];
    PFUser* sender = [friendRequest objectForKey:@"Sender"];
    [sender fetchIfNeeded];
    cell.usernameLabel.text = sender.username;
    cell.backgroundColor = [UIColor clearColor];
    cell->delegate = self;
    cell->_index = indexPath.row;
    
    [cell displayAddContactButton];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    /*
     [MFRAnalytics trackEvent:@"Search result clicked"];
     
     //-----------------------------------
     // Display web view for selected link
     //-----------------------------------
     NSMutableDictionary* searchResult = [self.specificSearchResults objectAtIndex:indexPath.row];
     
     _url = [self getURLFromString:[searchResult objectForKey:@"unescapedUrl"]];
     //    vc->html = _html;
     _linkTitle = [searchResult objectForKey:@"titleNoFormatting"];
     [self saveLinkObject];
     
     // Show web view
     BOOL presentedFromSearch = YES;
     [self presentWebView:presentedFromSearch];
     */
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Add Contact Cell delegate
-(void)addContactAtIndex:(NSInteger)index {
    
    [self performSelectorOnMainThread:@selector(showAddingFriendWheel:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
    
    [self performSelectorInBackground:@selector(addSelectedContact:) withObject:[NSNumber numberWithInteger:index]];
}

-(void)addSelectedContact:(NSNumber*)index {
    
    // Add friend
    PFObject* friendRequest = [_receivedRequests objectAtIndex:[index intValue]];
    PFUser* friend = [friendRequest objectForKey:@"Sender"];
    MFRFriendRequestStatus friendStatus = [MFRParseFriendRequests addContact:friend];
    
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:friendStatus], @"friendStatusNumber", index, @"indexNumber", friend, @"Friend", friendRequest, @"FriendRequest", nil];
    
    [self performSelectorOnMainThread:@selector(respondToAddingContact:) withObject:dict waitUntilDone:NO];
}

-(void)respondToAddingContact:(NSDictionary*)dict {
    
    MFRFriendRequestStatus friendStatus = (MFRFriendRequestStatus)[[dict objectForKey:@"friendStatusNumber"] intValue];
    int index = [[dict objectForKey:@"indexNumber"] intValue];
    PFObject* friendRequest = [dict objectForKey:@"FriendRequest"];
    PFUser* friend = [dict objectForKey:@"Friend"];
    
    if (friendStatus == MFRFriendRequestAccepted) {
        // Delete friend request from the cloud
        [friendRequest delete];
        
        // Delete friend request from the table
        [_receivedRequests removeObjectAtIndex:index];
        //        [_friendRequestsTableView reloadData];
        
        // Display the added friend as accepted
        AddContactCell *cell = (AddContactCell*)[self.friendRequestsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [cell displayIsContactButton];
        
        // Alter the Friend Requests title in the MHTabBarController to reflect the updated number of friend requests
        [updateFriendRequestTitleDelegate setFriendRequestCountInTitle:[NSNumber numberWithInteger:[_receivedRequests count]]];
        
        // Add friend to local contacts
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate addContact:friend];
        
        // Refresh contacts view controller
        [self.updateContactsVCDelegate refreshContactsFromAppDelegate];
        
        // Decrement the application's badge number
//        [appDelegate decrementBadgeNumber];
    }
    
    //    [self showAddingFriendWheel:NO];
    [self performSelectorOnMainThread:@selector(showAddingFriendWheel:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
}

-(void)showAddingFriendWheel:(NSNumber*)show {
    
    if ([show boolValue] == YES) {
        [_addingFriendWheel startAnimating];
        [self.navigationController.view insertSubview:_maskView aboveSubview:_addingFriendWheel];
    } else {
        [_addingFriendWheel stopAnimating];
        [_maskView removeFromSuperview];
    }
    
    _addingFriendWheel.hidden = ![show boolValue];
}

@end
