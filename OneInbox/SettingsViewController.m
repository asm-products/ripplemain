//
//  SettingsViewController.m
//  Ripple
//
//  Created by Ed Rex on 03/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsTableViewCell.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"
#import "TwitterViewController.h"
#import "MFRAnalytics.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize navBar = _navBar;
@synthesize settingsTableView = _settingsTableView;

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
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (animated) {
        [self.settingsTableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

-(IBAction)dismissSettingsViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UINavigationBarDelegate

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    
    return UIBarPositionTopAttached;
}

#pragma mark - UITableViewDataSource methods and related helpers
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 4;
    } else if (section == 1) {
        return 2;
    } else {
        return 0;
    }
}

//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
//    return [[self.contactsTableSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    SettingsTableViewCell* cell = (SettingsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Username";
            cell.detailLabel.text = [PFUser currentUser].username;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Name";
//            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.detailLabel.text = [[PFUser currentUser] objectForKey:@"additional"];
            
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"Email";
//            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.detailLabel.text = [PFUser currentUser].email;
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"Twitter";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                cell.detailLabel.text = [PFTwitterUtils twitter].screenName;
            } else {
                cell.detailLabel.text = @"Not connected";
            }
        }
        cell.textLabel.textColor = [UIColor blackColor];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Contact us";
            cell.textLabel.textColor = [UIColor purpleColor];
        } else {
            cell.textLabel.text = @"Logout";
            cell.textLabel.textColor = [UIColor redColor];
        }
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:16.0];
    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"My account";
    } else if (section == 1) {
        return @"Actions";
    } else {
        return @"";
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        if (indexPath.row == 3) {
            [self performSegueWithIdentifier:@"EditTwitterAssociation" sender:self];
            [MFRAnalytics trackEvent:@"Twitter cell pressed in Settings screen"];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self contactButtonPressed];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Logout"
                                        message:@"Are you sure you want to log out?"
                                       delegate:self
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Logout", nil] show];
            [MFRAnalytics trackEvent:@"Logout cell pressed in Settings screen"];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        
        [MFRAnalytics trackEvent:@"Logout confirmed in Settings screen"];
        
        // Logout
        [PFUser logOut];
        
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        // Clear contacts, compose screen and friendRequests
        [appDelegate clearUserData];
        
        // Display login screen
        [self dismissViewControllerAnimated:YES completion:nil];
        [appDelegate showLoginViewController];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"EditTwitterAssociation"]){
        
        TwitterViewController* controller = segue.destinationViewController;
        controller->shouldProgressToTweetView = NO;
    }
}

#pragma mark - Contacting us
-(void)contactButtonPressed
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:@"Ripple feedback"];
        NSArray *toRecipients = [NSArray arrayWithObjects:@"edmundrex@gmail.com", nil];
        [mailer setToRecipients:toRecipients];
        NSString *emailBody = @"";
        [mailer setMessageBody:emailBody isHTML:NO];
        [self presentViewController:mailer animated:YES completion:nil];
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Mail unavailable at this time"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
