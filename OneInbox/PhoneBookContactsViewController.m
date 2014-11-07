//
//  PhoneBookContactsViewController.m
//  Ripple
//
//  Created by Ed Rex on 25/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "PhoneBookContactsViewController.h"
#import <AddressBook/AddressBook.h>
#import <Parse/Parse.h>

@interface PhoneBookContactsViewController () {
    int _numberOfContactsSelected;
}

@property (nonatomic, retain) NSMutableArray* contactsList;
@property (nonatomic, retain) NSMutableDictionary* contactsTableSections;

@end

@implementation PhoneBookContactsViewController

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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _contactsTableSections = [NSMutableDictionary dictionary];
    _sendButton.hidden = YES;
    _numberOfContactsSelected = 0;
    
    // Get contacts from address book - not yet being used
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // We are on iOS 6
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(semaphore);
        });
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    else { // We are on iOS 5 or Older
        accessGranted = YES;
        [self getContactsWithAddressBook:addressBook];
    }
    
    if (accessGranted) {
        [self getContactsWithAddressBook:addressBook];
//        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[_contactsTableSections allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.contactsTableSections valueForKey:[[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"addressBookCell";
    
    UITableViewCell* cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary* contact = [[self.contactsTableSections valueForKey:[[[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
//    NSDictionary* contact = [self.contactsList objectAtIndex:indexPath.row];
    cell.textLabel.text = [contact objectForKey:@"name"];
    if ([contact objectForKey:@"Phone"]) {
        cell.detailTextLabel.text = [contact objectForKey:@"Phone"];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:18.0];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:14.0];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
//    cell->delegate = self;
//    cell->_index = indexPath.row;
    
    //------------------------------------------------------------
    // Display contact as selected or not selected as approapriate
    //------------------------------------------------------------
    if ([[contact objectForKey:@"Selected"] boolValue] == YES){
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else{
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    //------------------------------
    // Fetch current user's contacts
    //------------------------------
//    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSMutableArray* contacts = [appDelegate getRelationContacts];
//    BOOL isContact = NO;
//    for (PFUser* contact in contacts) {
//        if ([contact.objectId isEqualToString:user.objectId]) {
//            isContact = YES;
//        }
//    }
//    if (isContact) {
//        [cell displayIsContactButton];
//    } else {
//        
//        // Check whether the current user has already sent them a request
//        PFQuery* friendRequestsQuery = [PFQuery queryWithClassName:@"FriendRequest"];
//        [friendRequestsQuery whereKey:@"Sender" equalTo:[PFUser currentUser]];
//        [friendRequestsQuery whereKey:@"Recipient" equalTo:user];
//        NSArray* requests = [friendRequestsQuery findObjects];
//        if ([requests count] == 0) {
//            // The current user has not sent them a request
//            [cell displayAddContactButton];
//        } else {
//            // The current user has already sent them a request
//            [cell displayPendingButton];
//        }
//    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //--------------------------------------------------------
    // Mark contact as selected or not selected as appropriate
    //--------------------------------------------------------
    BOOL selected;
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
    
    [tableView reloadData];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Getting contacts from address book
// Get contacts from address book
- (void)getContactsWithAddressBook:(ABAddressBookRef )addressBook {
    
    //-----------------------------
    // Get contacts from phone book
    //-----------------------------
    self.contactsList = [[NSMutableArray alloc] init];
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    
    //--------------------------
    // Get info for all contacts
    //--------------------------
    for (int i=0;i < nPeople;i++) {
        NSMutableDictionary *dOfPerson=[NSMutableDictionary dictionary];
        
        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople,i);
        
        //For username and surname
        ABMultiValueRef phones =(__bridge ABMultiValueRef)((__bridge NSString*)ABRecordCopyValue(ref, kABPersonPhoneProperty));
        
        CFStringRef firstName, lastName;
        firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        
        if (firstName || lastName) {
            
            // Build full name
            NSMutableString* fullName = [NSMutableString string];
            if (firstName) {
                fullName = [NSMutableString stringWithFormat:@"%@", firstName];
            }
            if (lastName) {
                if (firstName) {
                    [fullName appendString:@" "];
                }
                [fullName appendString:[NSString stringWithFormat:@"%@", lastName]];
            }
            
            [dOfPerson setObject:fullName forKey:@"name"];
            
            //        //For Email ids
            //        ABMutableMultiValueRef eMail  = ABRecordCopyValue(ref, kABPersonEmailProperty);
            //        if(ABMultiValueGetCount(eMail) > 0) {
            //            [dOfPerson setObject:(__bridge NSString *)ABMultiValueCopyValueAtIndex(eMail, 0) forKey:@"email"];
            //
            //        }
            
            //For Phone number
            NSString* mobileLabel;
            
            BOOL phoneFound = NO;
            for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
                mobileLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(phones, i);
                if([mobileLabel isEqualToString:(NSString *)kABPersonPhoneMobileLabel])
                {
                    [dOfPerson setObject:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i) forKey:@"Phone"];
                    phoneFound = YES;
                }
                else if ([mobileLabel isEqualToString:(NSString*)kABPersonPhoneIPhoneLabel])
                {
                    [dOfPerson setObject:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i) forKey:@"Phone"];
                    phoneFound = YES;
                    break ;
                }
                
            }
            if (phoneFound) {
                [self.contactsList addObject:dOfPerson];
            }
        }
        
    }
    NSLog(@"Contacts = %@",self.contactsList);
    
    
    
    //----------------------------------------
    // Create a section for each letter needed
    //----------------------------------------
    for (NSMutableDictionary* contact in _contactsList) {
        
        NSString *c = [[contact objectForKey:@"name"] substringToIndex:1];
        
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
    for (NSMutableDictionary* contact in _contactsList)
    {
        [[self.contactsTableSections objectForKey:[[contact objectForKey:@"name"] substringToIndex:1]] addObject:contact];
    }
    
    //------------------------
    // Sort each section array
    //------------------------
    for (NSString *key in [self.contactsTableSections allKeys])
    {
        [[self.contactsTableSections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
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
        [self hideSendButton];
    }
}

-(void)hideSendButton {
    
    _sendButton.hidden = YES;
    
    // Remove footer from table view
    self.contactsTableView.tableFooterView = nil;
}

-(IBAction)sendInvitationButtonPressed:(id)sender {
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    
    //--------------------------
    // Build array of recipients
    //--------------------------
    NSMutableArray* recipients = [NSMutableArray array];
    
    for (NSString *key in [self.contactsTableSections allKeys]) {
        for (NSMutableDictionary* contact in [self.contactsTableSections objectForKey:key]){
            if ([[contact objectForKey:@"Selected"] boolValue] == YES){
                [recipients addObject:[contact objectForKey:@"Phone"]];
            }
        }
    }
    
    NSString *message = [NSString stringWithFormat:@"Add me on Ripple! Get the app here - http://bit.ly/1hOBjjN. My username is %@", [PFUser currentUser].username];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipients];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

#pragma mark - Message Controller delegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to invite friends" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
        {
            // Deselect selected contacts
            [self deselectAllUsers];
            
            // Show success
            UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Invites sent!" message:@"A message has been sent to your friends." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [successAlert show];
            
            break;
        }
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)deselectAllUsers {
    //----------------------------
    // Deselect all selected users
    //----------------------------
    for (NSMutableDictionary* contact in _contactsList) {
        if ([[contact objectForKey:@"Selected"] boolValue] == YES) {
            [contact setObject:[NSNumber numberWithBool:NO] forKey:@"Selected"];
        }
    }
    [self.contactsTableView reloadData];
    _numberOfContactsSelected = 0;
    [self hideSendButton];
}

@end
