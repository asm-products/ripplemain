//
//  AddContactsViewController.m
//  Ripple
//
//  Created by Ed Rex on 03/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "AddContactsViewController.h"
#import <Parse/Parse.h>
#import "MFRParseFriendRequests.h"
#import "AppDelegate.h"
#import "MFRAnalytics.h"

@interface AddContactsViewController ()

@end

@implementation AddContactsViewController

@synthesize usernameTextField = _usernameTextField;
@synthesize usersFound = _usersFound;
@synthesize foundUsersTable = _foundUsersTable;
@synthesize loadingWheel = _loadingWheel;

@synthesize addingFriendWheel = _addingFriendWheel;
@synthesize maskView = _maskView;

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
    
    [_usernameTextField setPlaceholderText:@"Search for a username"];
    _usernameTextField.returnKeyType = UIReturnKeySearch;
    
    _foundUsersTable.hidden = YES;
    _loadingWheel.hidden = YES;
    
    // This will remove extra separators from tableview
    self.foundUsersTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self.foundUsersTable registerClass:[AddContactCell class] forCellReuseIdentifier:@"AddContactCell"];
    
//    _maskView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _maskView = [[UIView alloc] initWithFrame:[self.view bounds]];
    _maskView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    [self showAddingFriendWheel:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Text field delegate
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // If a link has been entered, try to display it
    if (![textField.text isEqualToString:@""]){
        [self displayLoadingWheel:YES];
        [self performSelectorInBackground:@selector(searchForUsername:) withObject:textField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Display
-(void)displayLoadingWheel:(BOOL)loading {
    _loadingWheel.hidden = !loading;
    if (loading) {
        [_loadingWheel startAnimating];
    } else {
        [_loadingWheel stopAnimating];
    }
}

#pragma mark - Searching for users
-(void)searchForUsername:(NSString*)username {
    [MFRAnalytics trackEvent:@"User searched for contact by username"];
    PFQuery* usernameQuery = [PFQuery queryWithClassName:@"_User"];
    [usernameQuery whereKey:@"username" equalTo:username];
    _usersFound = [[usernameQuery findObjects] mutableCopy];
    [self performSelectorOnMainThread:@selector(reloadFoundUsersTable) withObject:nil waitUntilDone:NO];
}

#pragma mark - Found users table view
-(void)reloadFoundUsersTable {
    [self displayLoadingWheel:NO];
    if ([_usersFound count] > 0) {
        _foundUsersTable.hidden = NO;
    } else {
        _foundUsersTable.hidden = YES;
    }
    [_foundUsersTable reloadData];
}

#pragma mark - Table view delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_usersFound count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AddContactCell";
    
    AddContactCell* cell = (AddContactCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AddContactCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    PFObject* user = [_usersFound objectAtIndex:indexPath.row];
    cell.usernameLabel.text = [user objectForKey:@"username"];
    cell.backgroundColor = [UIColor clearColor];
    cell->delegate = self;
    cell->_index = indexPath.row;
    
    //------------------------------
    // Fetch current user's contacts
    //------------------------------
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray* contacts = [appDelegate getRelationContacts];
    BOOL isContact = NO;
    for (PFUser* contact in contacts) {
        if ([contact.objectId isEqualToString:user.objectId]) {
            isContact = YES;
        }
    }
    if (isContact) {
        [cell displayIsContactButton];
    } else {
        
        // Check whether the current user has already sent them a request
        PFQuery* friendRequestsQuery = [PFQuery queryWithClassName:@"FriendRequest"];
        [friendRequestsQuery whereKey:@"Sender" equalTo:[PFUser currentUser]];
        [friendRequestsQuery whereKey:@"Recipient" equalTo:user];
        NSArray* requests = [friendRequestsQuery findObjects];
        if ([requests count] == 0) {
            // The current user has not sent them a request
            [cell displayAddContactButton];
        } else {
            // The current user has already sent them a request
            [cell displayPendingButton];
        }
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Add Contact Cell delegate
-(void)addContactAtIndex:(int)index {
    
    [self performSelectorOnMainThread:@selector(showAddingFriendWheel:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
    
    [self performSelectorInBackground:@selector(addSelectedContact:) withObject:[NSNumber numberWithInt:index]];
}

#pragma mark - Adding contact
-(void)addSelectedContact:(NSNumber*)index {
    // Add contact in cloud
    MFRFriendRequestStatus friendStatus = [MFRParseFriendRequests addContact:[_usersFound objectAtIndex:[index intValue]]];
    
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:friendStatus], @"friendStatusNumber", index, @"indexNumber", nil];
    
    [self performSelectorOnMainThread:@selector(respondToAddingContact:) withObject:dict waitUntilDone:NO];
}

-(void)respondToAddingContact:(NSDictionary*)dict {
    
    MFRFriendRequestStatus friendStatus = (MFRFriendRequestStatus)[[dict objectForKey:@"friendStatusNumber"] intValue];
    int index = [[dict objectForKey:@"indexNumber"] intValue];
    
    if (friendStatus == MFRFriendRequestPending) {
        [_foundUsersTable reloadData];
    } else if (friendStatus == MFRFriendRequestAccepted) {
        
        // Add friend to local contacts
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate addContact:[_usersFound objectAtIndex:index]];
        
        [_foundUsersTable reloadData];
        
        // Refresh contacts view controller
        [self.updateContactsVCDelegate refreshContactsFromAppDelegate];
        
    } else if (friendStatus == MFRFriendRequestSendingFailed) {
        
    }
    
    //    [self showAddingFriendWheel:NO];
    [self performSelectorOnMainThread:@selector(showAddingFriendWheel:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
}

-(void)showAddingFriendWheel:(NSNumber*)show {
    
    if ([show boolValue] == YES) {
        [_addingFriendWheel startAnimating];
        [self.navigationController.view insertSubview:_maskView aboveSubview:_addingFriendWheel];
//        [self.view addSubview:_maskView];
    } else {
        [_addingFriendWheel stopAnimating];
        [_maskView removeFromSuperview];
    }
    
    _addingFriendWheel.hidden = ![show boolValue];
}

#pragma mark - Clicking outside text field
-(IBAction)clickOutsideTextField:(id)sender {
    [_usernameTextField resignFirstResponder];
}

@end
