//
//  TwitterViewController.m
//  Ripple
//
//  Created by Ed Rex on 06/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "TwitterViewController.h"
#import "TweetViewController.h"
#import "MFRAnalytics.h"
#import <Parse/Parse.h>

@interface TwitterViewController ()

@end

@implementation TwitterViewController

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
    
    self.loadingWheel.hidden = YES;
    
    [self.linkButton.titleLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:16.0]];
    [self.unlinkButton.titleLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:16.0]];
    [self.linkButton setTitleColor:[UIColor colorWithRed:41/255.0 green:128/255.0 blue:185/255.0 alpha:1.0] forState:UIControlStateNormal];
    [self.unlinkButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    [self.usernameLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:16.0]];
    [self.notConnectedLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:14.0]];
    [self.notConnectedLabel setTextColor:[UIColor lightGrayColor]];
    
    [self displayCorrectUIElements];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Displaying according to Twitter user status
-(void)displayCorrectUIElements {
    if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        [self displayTwitterInfo];
    } else {
        [self displayTwitterEntry];
    }
}

-(void)displayTwitterInfo {
    self.usernameLabel.text = [PFTwitterUtils twitter].screenName;
    self.usernameLabel.hidden = NO;
    self.linkButton.hidden = YES;
    self.unlinkButton.hidden = NO;
    self.notConnectedLabel.hidden = YES;
}

-(void)displayTwitterEntry {
    self.usernameLabel.hidden = YES;
    self.linkButton.hidden = NO;
    self.unlinkButton.hidden = YES;
    self.notConnectedLabel.hidden = NO;
}

#pragma mark - Twitter connection/deconnection

-(IBAction)connectToTwitter:(id)sender {
    [MFRAnalytics trackEvent:@"Connect to Twitter button pressed"];
    if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        [self showLoadingWheel:YES];
        [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            [self showLoadingWheel:NO];
            if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                [self displayTwitterInfo];
                NSLog(@"Woohoo, user logged in with Twitter!");
                [MFRAnalytics trackEvent:@"Connecting to Twitter succeeded"];
                
                if (shouldProgressToTweetView) {
                    [self performSegueWithIdentifier:@"ShowTweetViewController" sender:self];
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Couldn't connect"
                                            message:@"Sorry - unable to connect to Twitter at this time."
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil] show];
            }
        }];
    }
}

-(IBAction)disconnectToTwitter:(id)sender {
    [MFRAnalytics trackEvent:@"Disconnect from Twitter button pressed"];
    [self showLoadingWheel:YES];
    [PFTwitterUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
        [self showLoadingWheel:NO];
        if (!error && succeeded) {
            NSLog(@"The user is no longer associated with their Twitter account.");
            [MFRAnalytics trackEvent:@"Disconnecting from Twitter succeeded"];
            [self displayTwitterEntry];
        }
    }];
}

#pragma mark - Loading Wheel
-(void)showLoadingWheel:(BOOL)show
{
    self.loadingWheel.hidden = !show;
    if (show) {
        [self.loadingWheel startAnimating];
    } else {
        [self.loadingWheel stopAnimating];
    }
}

#pragma mark - Segue
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"ShowTweetViewController"]){
        
        TweetViewController* controller = segue.destinationViewController;
        controller->_url = _url;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
