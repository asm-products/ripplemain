//
//  ContactsViewController.m
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "ContactsViewController.h"
#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <MessageUI/MessageUI.h>
#import "MFRAnalytics.h"
#import "AddContactsViewController.h"
#import "FriendRequestsViewController.h"
#import "PhoneBookContactsViewController.h"
#import "MFRLocalMessageThread.h"
#import "MFRDateTime.h"

@interface ContactsViewController () {
    
    PFUser* _userInfo;
    BOOL _linkDeleted;
    BOOL _linkSent;
    int _numberOfContactsSelected;
    CGFloat _basicContactsTableHeight;
    BOOL _usingFriendRelations;
}

@property (nonatomic, retain) NSMutableDictionary* contactsTableSections;
@property (nonatomic, retain) NSMutableDictionary* messageThread;

@end

@implementation ContactsViewController

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
    
    _contactsTableSections = [NSMutableDictionary dictionary];
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate markContactsVCAsCreated];
    
    if (!_sendingLink) {
        [self setupNavigationBar];
    }
    
    _linkDeleted = NO;
    _linkSent = NO;
    _numberOfContactsSelected = 0;
    
    _sendButton.hidden = YES;
    
    [self refreshContactsFromAppDelegate];
    
    _basicContactsTableHeight = _contactsTableView.frame.size.height;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [parentDelegate addSwipeGesture];
    [self checkFriendRequestCount];
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if ([appDelegate contactsNeedRefreshing]) {
        // A friend request we sent has been accepted, so get updated list of contacts from the cloud
        [appDelegate fetchUserLinksFromCloud];
    }
    else if (
             [appDelegate getContactsVC]
             &&
             (self == [appDelegate getContactsVC])
             &&
             [appDelegate shouldReloadContacts]
             ) {
        // We have accepted a friend request, so get updated list of contacts from local storage
        [self refreshContactsFromAppDelegate];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    // If view loaded from web view and link has been passed on or deleted, dismiss web view
    if (pushedFromWebView){
        [webViewDelegate dismissWebView];
    }
}

#pragma mark - View setup
-(void)setupNavigationBar {
    self.navigationController.navigationBar.topItem.title = @"Contacts";
    
    // Compose button
    UIButton *bt=[UIButton buttonWithType:UIButtonTypeCustom];
    [bt setFrame:CGRectMake(0, 0, 25, 25)];
    [bt setImage:[UIImage imageNamed:@"Pencil-128"] forState:UIControlStateNormal];
    [bt addTarget:self action:@selector(pushComposeViewController) forControlEvents:UIControlEventTouchUpInside];
    bt.showsTouchWhenHighlighted = YES;
    _composeButton   = [[UIBarButtonItem alloc] initWithCustomView:bt];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = _composeButton;
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [self updateFriendRequestsLabel:[NSNumber numberWithInteger:[[appDelegate getFriendRequests] count]]];
}

#pragma mark - Getting contacts
-(void)refreshContactsFromAppDelegate
{
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSMutableArray* contacts = [appDelegate getRelationContacts];
    
    _usingFriendRelations = YES;
    if (!contacts) {
        contacts = [NSMutableArray array];
    } else {
        [self arrangeContactsInAlphabeticalOrder:contacts];
    }
}

-(void)arrangeContactsInAlphabeticalOrder:(NSMutableArray*)contacts {
    
    _contactsTableSections = [NSMutableDictionary dictionary];
    
    if (_usingFriendRelations) {
        //----------------------------------------
        // Create a section for each letter needed
        //----------------------------------------
        for (PFUser* contact in contacts) {
            
            NSString *c = [[contact objectForKey:@"additional"] substringToIndex:1];
            
            BOOL found = NO;
            
            for (NSString *str in [self.contactsTableSections allKeys])
            {
                if ([str isEqualToString:c])
                {
                    found = YES;
                }
            }
            
            if (!found)
            {
                [self.contactsTableSections setValue:[[NSMutableArray alloc] init] forKey:c];
            }
        }
        
        //------------------------------------------------------------
        // Loop again and sort the contacts into their respective keys
        //------------------------------------------------------------
        for (PFUser* contact in contacts)
        {
            [[self.contactsTableSections objectForKey:[[contact objectForKey:@"additional"] substringToIndex:1]] addObject:contact];
        }
        
        //------------------------
        // Sort each section array
        //------------------------
        for (NSString *key in [self.contactsTableSections allKeys])
        {
            [[self.contactsTableSections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"additional" ascending:YES]]];
        }
        
        //----------------------------------
        // Mark all contacts as not selected
        //----------------------------------
        for (NSString *key in [self.contactsTableSections allKeys]) {
            for (PFUser* contact in [self.contactsTableSections objectForKey:key]){
                [contact setObject:[NSNumber numberWithBool:NO] forKey:@"Selected"];
            }
        }
    } else {
        for (NSMutableDictionary* contact in contacts) {
            
            NSString *c = [[contact objectForKey:@"Name"] substringToIndex:1];
            
            BOOL found = NO;
            
            for (NSString *str in [self.contactsTableSections allKeys])
            {
                if ([str isEqualToString:c])
                {
                    found = YES;
                }
            }
            
            if (!found)
            {
                [self.contactsTableSections setValue:[[NSMutableArray alloc] init] forKey:c];
            }
        }
        
        //------------------------------------------------------------
        // Loop again and sort the contacts into their respective keys
        //------------------------------------------------------------
        for (NSMutableDictionary* contact in contacts)
        {
            [[self.contactsTableSections objectForKey:[[contact objectForKey:@"Name"] substringToIndex:1]] addObject:contact];
        }
        
        //------------------------
        // Sort each section array
        //------------------------
        for (NSString *key in [self.contactsTableSections allKeys])
        {
            [[self.contactsTableSections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"Name" ascending:YES]]];
        }
        
        //----------------------------------
        // Mark all contacts as not selected
        //----------------------------------
        for (NSString *key in [self.contactsTableSections allKeys]) {
            for (NSMutableDictionary* contact in [self.contactsTableSections objectForKey:key]){
                [contact setObject:[NSNumber numberWithBool:NO] forKey:@"Selected"];
            }
        }
    }
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (
        ![appDelegate getContactsVC]
        ||
        (self != [appDelegate getContactsVC])
        ) {
        // This is not the app's main Contacts screen, so mark that that screen needs to be reloaded too
        [appDelegate setShouldReloadContacts:YES];
    }
    
    [self.contactsTableView reloadData];
}

#pragma mark - UITableViewDataSource methods and related helpers
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.contactsTableSections valueForKey:[[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    UITableViewCell* cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (_usingFriendRelations) {
        //---------------------
        // Display contact name
        //---------------------
        PFUser* contact = [[self.contactsTableSections valueForKey:[[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        cell.textLabel.text = [contact objectForKey:@"additional"];
        cell.textLabel.textColor = [UIColor blackColor];
        
        //------------------------------------------------------------
        // Display contact as selected or not selected as approapriate
        //------------------------------------------------------------
        if ([[contact objectForKey:@"Selected"] boolValue] == YES){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        NSDictionary* contact = [[self.contactsTableSections valueForKey:[[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        cell.textLabel.text = [contact objectForKey:@"Name"];
        cell.textLabel.textColor = [UIColor blackColor];
        
        if ([[contact objectForKey:@"Selected"] boolValue] == YES){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:18.0];
    cell.backgroundColor = [UIColor clearColor];
    
    if (_sendingLink) {
        cell.userInteractionEnabled = YES;
    } else {
        cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[_contactsTableSections allKeys] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //--------------------------------------------------------
    // Mark contact as selected or not selected as appropriate
    //--------------------------------------------------------
    BOOL selected;
    if (_usingFriendRelations) {
        PFUser* contact = [[self.contactsTableSections valueForKey:[[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        if ([[contact objectForKey:@"Selected"] boolValue] == NO){
            selected = YES;
        }
        else{
            selected = NO;
        }
        // Update the number of contacts that are selected
        [self increaseNumberOfContactsSelected:selected];
        
        [contact setObject:[NSNumber numberWithBool:selected] forKey:@"Selected"];
    } else {
        NSMutableDictionary* contact = [[self.contactsTableSections valueForKey:[[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        if ([[contact objectForKey:@"Selected"] boolValue] == NO){
            selected = YES;
        }
        else{
            selected = NO;
        }
        // Update the number of contacts that are selected
        [self increaseNumberOfContactsSelected:selected];
        
        [contact setObject:[NSNumber numberWithBool:selected] forKey:@"Selected"];
    }
    [tableView reloadData];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Send button
-(IBAction)sendButtonPressed:(id)sender
{
//    [self performSelectorInBackground:@selector(sendMessage) withObject:nil];
    [self sendMessage];
}

-(void)sendMessage {
    //--------------------------
    // Build array of recipients
    //--------------------------
    NSMutableArray* recipients = [NSMutableArray array];
    
    if (_usingFriendRelations) {
        for (NSString *key in [self.contactsTableSections allKeys]) {
            for (PFUser* contact in [self.contactsTableSections objectForKey:key]){
                if ([[contact objectForKey:@"Selected"] boolValue] == YES){
                    [recipients addObject:contact];
                }
            }
        }
    } else {
        for (NSString *key in [self.contactsTableSections allKeys]) {
            for (NSDictionary* contact in [self.contactsTableSections objectForKey:key]){
                if ([[contact objectForKey:@"Selected"] boolValue] == YES){
                    [recipients addObject:contact];
                }
            }
        }
    }
    
    // Set view controllor as delegate of link object so that it can respond to sending success/failure
    _linkObject->delegate = self;
    
    // Send link
    if (_usingFriendRelations) {
        [_linkObject storeRecipientsWithRelations:recipients];
    } else {
        [_linkObject storeRecipients:recipients];
    }
    
    //-------------------------------------------------------------------------
    // Create message and messageThread, and store the latter in NSUserDefaults
    //-------------------------------------------------------------------------
    _messageThread = [_linkObject createLocalMessageThreadWithMessageBody:_messageBody];
    [MFRLocalMessageThread storeMessageThread:_messageThread];
    
    //--------------------------------------------------------------
    // Tell AppDelegate to reload local message threads in the inbox
    //--------------------------------------------------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setInboxToReload:YES];
    
    [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSending forLatestMessageInMessageThreadWithId:[_messageThread objectForKey:@"objectId"]];
    
    //---------------------------------
    // Send messageThread to recipients
    //---------------------------------
    [self performSelectorInBackground:@selector(sendLocalMessageThreadToCloud) withObject:nil];
    
    //----------------------------
    // Switch to and refresh inbox
    //----------------------------
    if (_originalLink) {
        // Root is Compose VC, so switch to Inbox VC and return this VC to main Compose VC
        [appDelegate performSelectorOnMainThread:@selector(displayInboxAndScrollToTop) withObject:nil waitUntilDone:NO];
        [self performSelectorOnMainThread:@selector(popToMainViewController) withObject:Nil waitUntilDone:NO];
    } else {
        // Root is Inbox VC, so pop to Inbox VC
        [self performSelectorOnMainThread:@selector(popToMainViewController) withObject:Nil waitUntilDone:NO];
    }
}

-(void)sendLocalMessageThreadToCloud {
    [MFRParseMessageThread createAndSendParseMessageThreadWithLocalMessageThread:_messageThread recipients:_linkObject.userIDs delegate:_linkObject];
}

-(void)popToMainViewController {
    // Return the current navigation controller to the view controller at the base of its stack
    NSArray *array = [self.navigationController viewControllers];
    [self.navigationController popToViewController:[array objectAtIndex:0] animated:NO];
}

/*
-(void)changeSendingStatus:(NSNumber*)sendingStatus {
    if ([sendingStatus integerValue] == 1) {
        // Sending
        
    } else if ([sendingStatus integerValue] == 2) {
        // Sent
        
    } else if ([sendingStatus integerValue] == 3) {
        // 'Sent' message should disappear
        [self popToCorrectViewController];
    } else if ([sendingStatus integerValue] == 4) {
        // 'Sent' message should disappear

    }
}
*/

#pragma mark - Deleting link
//-(void)deleteLinkFromInbox {
//    [deleteLinkDelegate deleteFirstLink];
//    _linkDeleted = YES;
//}

#pragma mark - Popping to previous View Controller
-(void)popToCorrectViewController{
    
    if (!_originalLink) {
        // Forwarded message, so pop back to inbox
        [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:0] animated:YES];
    } else {
        // Composed message from scratch, so pop back to compose screen
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Storing selection
-(void)increaseNumberOfContactsSelected:(BOOL)selected{
    
    int oldNumberOfContactsSelected = _numberOfContactsSelected;
    
    //------------------------------------------------
    // Update the number of contacts that are selected
    //------------------------------------------------
    if (selected) {
        _numberOfContactsSelected++;
    } else {
        _numberOfContactsSelected--;
    }
    
    //-----------------------------------------
    // Show or hide the send button accordingly
    //-----------------------------------------
    if (
        (_numberOfContactsSelected == 1)
        &&
        (oldNumberOfContactsSelected == 0)
        ) {
        _sendButton.hidden = NO;
        
        // Add footer to table view so that you can see the lowest cell above the send button
        CGRect footerRect = CGRectMake(0, 0, 320, 44);
        UIView *tableFooter = [[UIView alloc] initWithFrame:footerRect];
        self.contactsTableView.tableFooterView = tableFooter;
        
    } else if (_numberOfContactsSelected == 0) {
        _sendButton.hidden = YES;
        
        // Remove footer from table view
        self.contactsTableView.tableFooterView = nil;
    }
}

/*
#pragma mark - Sending success delegate
-(void)informSendingSuccess:(BOOL)b
{
    if (b) {
        // Indicate that message has been sent
        [self changeSendingStatus:[NSNumber numberWithInteger:2]];
        
        _linkSent = YES;
        
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate setInboxToReload:YES];
        
        // Set the 'sent' message to disappear in one second
        [self performSelector:@selector(changeSendingStatus:) withObject:[NSNumber numberWithInteger:3] afterDelay:1.5];
    } else {
        
        // Display alert offering the opportunity to resend
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Sending failed" message: @"Your link couldn't be sent. Do you want to try again?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try again", nil];
        alert.tag = 0;
        [alert show];
    }
}
*/

#pragma mark - Alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 0) {
        if (buttonIndex == 0) {
            // Cancel send
//            [self changeSendingStatus:[NSNumber numberWithInteger:4]];
        } else if (buttonIndex == 1) {
            //-----------
            // Retry send
            //-----------
            // Update timestamp on message (if there is a message)
            if ([[_messageThread objectForKey:@"Messages"] count] > 0) {
                NSMutableDictionary* message = [[[_messageThread objectForKey:@"Messages"] lastObject] mutableCopy];
                
                NSString* gmtDateTime = [MFRDateTime getCurrentGMTDateTimeString];
                
                [message setObject:gmtDateTime forKey:@"Date"];
                [[_messageThread objectForKey:@"Messages"] replaceObjectAtIndex:([[_messageThread objectForKey:@"Messages"] count] - 1) withObject:message];
            }
            
            // Update local version of messageThread
            [MFRLocalMessageThread updateMessageThread:_messageThread shouldUpdateTime:YES];
            
            [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSending forLatestMessageInMessageThreadWithId:[_messageThread objectForKey:@"objectId"]];
            
            // Attempt to send messageThread to recipients
            [MFRParseMessageThread createAndSendParseMessageThreadWithLocalMessageThread:_messageThread recipients:_linkObject.userIDs delegate:_linkObject];
        }
    }
}

#pragma mark - Swapping views
-(IBAction)pushComposeViewController
{
    [parentDelegate navigateLeftToCompose];
}

#pragma mark - Adding contacts
-(IBAction)addContactsButtonPressed {
    [self performSegueWithIdentifier:@"AddContacts" sender:self];
    [MFRAnalytics trackEvent:@"Add friends button pressed"];
}

#pragma mark - Segue
- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"AddContacts"]){
        
        [parentDelegate removeSwipeGesture];
        
        //-----------------------------------
        // Create AddContacts View Controller
        //-----------------------------------
        UIStoryboard* storyboard = self.storyboard;
        AddContactsViewController *addContactsViewController = [storyboard instantiateViewControllerWithIdentifier:@"AddContacts"];
        FriendRequestsViewController *friendRequestsViewController = [storyboard instantiateViewControllerWithIdentifier:@"FriendRequests"];
        PhoneBookContactsViewController* phoneBookContactsVC = [storyboard instantiateViewControllerWithIdentifier:@"PhoneBookContacts"];
        
        
        addContactsViewController.title = @"Search";
        friendRequestsViewController.title = @"Requests";
        phoneBookContactsVC.title = @"Invite";
        
//        friendRequestsViewController.tabBarItem.imageInsets = UIEdgeInsetsMake(0.0f, -4.0f, 0.0f, 0.0f);
        
        NSArray *viewControllers = @[phoneBookContactsVC, friendRequestsViewController, addContactsViewController];
        MHTabBarController *tabBarController = segue.destinationViewController;
        
        tabBarController.delegate = self;
        tabBarController.viewControllers = viewControllers;
        
        addContactsViewController.updateContactsVCDelegate = self;
        
        friendRequestsViewController->updateFriendRequestTitleDelegate = tabBarController;
        friendRequestsViewController.updateContactsVCDelegate = self;
        
        // Uncomment this to select "Tab 2".
        //tabBarController.selectedIndex = 1;
    }
}

#pragma mark - Nav bar
-(void)checkFriendRequestCount {
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [self updateFriendRequestsLabel:[NSNumber numberWithInteger:[[appDelegate getFriendRequests] count]]];
}

-(void)updateFriendRequestsLabel:(NSNumber*)friendRequestsCount {
    
    // Add Contacts button
    UIButton *bt=[UIButton buttonWithType:UIButtonTypeCustom];
    [bt setFrame:CGRectMake(0, 0, 20, 20)];
    [bt setImage:[UIImage imageNamed:@"Add-New-128"] forState:UIControlStateNormal];
    
    if ([friendRequestsCount intValue] > 0) {
        // Display number of friend requests
        UILabel* contactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, -5, 15, 15)];
        contactsLabel.text = [friendRequestsCount stringValue];
        contactsLabel.textColor = [UIColor whiteColor];
        contactsLabel.backgroundColor = [UIColor colorWithRed:155/255.0 green:89/255.0 blue:182/255.0 alpha:1.0];
        contactsLabel.textAlignment = NSTextAlignmentCenter;
        contactsLabel.layer.cornerRadius = 8;
        contactsLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:8.0];
        [bt addSubview:contactsLabel];
    }
    
    [bt addTarget:self action:@selector(addContactsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    bt.showsTouchWhenHighlighted = YES;
    _addContactsButton = [[UIBarButtonItem alloc] initWithCustomView:bt];
    self.navigationController.navigationBar.topItem.rightBarButtonItem = _addContactsButton;
}

@end
