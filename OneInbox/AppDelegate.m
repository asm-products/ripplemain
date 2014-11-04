//
//  AppDelegate.m
//  OneInbox
//
//  Created by Ed Rex on 02/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "AppDelegate.h"
#import "ComposeViewController.h"
#import "InboxViewController.h"
#import "MFRAnalytics.h"
#import "MFRLocalMessageThread.h"

@implementation AppDelegate {
    
    PFUser* _user;
    PFObject* _userLinks;
    BOOL _shouldRefreshInbox;
    BOOL _shouldReloadInboxTable;
    NSMutableArray* _contacts;
    BOOL _usingFriendRelations;
    BOOL _inboxHasBeenCreated;
    BOOL _contactsVCHasBeenCreated;
    BOOL _shouldFetchFriendRequests;
    BOOL _shouldFetchContacts;
    BOOL _shouldReloadContacts;
    BOOL _shouldReloadFriendRequestsVC;
//    BOOL _newUser;
}

@synthesize linkImages = _linkImages;
@synthesize largeLinkImages = _largeLinkImages;
@synthesize parentViewController = _parentViewController;
@synthesize usernameFullNames = _usernameFullNames;
@synthesize friendRequests = _friendRequests;
@synthesize currentUserDefaults = _currentUserDefaults;
@synthesize localMessageThreads = _localMessageThreads;
@synthesize friendInvitePromptTally = _friendInvitePromptTally;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"XuohdddavQAhrcL2JTBy7ulGcx9ypwRHI3ym74BA"
                  clientKey:@"UQaPfzhh1YnBEGw9c3ClnBwwNlusYczcIoQSSw4N"];
    
    [PFTwitterUtils initializeWithConsumerKey:@"EPEH2vUnvDRQuvfX26Fw"
                               consumerSecret:@"rt6FAqYBBvCnTJpg3o7ygazXmRS5rJaHdGqd8Au58"];
    
    [MFRAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Empty array of contacts until fetched from cloud
    _contacts = [NSMutableArray array];
    _usingFriendRelations = NO;
    _linkImages = [NSMutableDictionary dictionary];
    _largeLinkImages = [NSMutableDictionary dictionary];
    _inboxHasBeenCreated = NO;
    _friendRequests = [NSMutableArray array];
    _shouldFetchFriendRequests = NO;
    _contactsVCHasBeenCreated = NO;
    _shouldFetchContacts = NO;
    _shouldReloadContacts = NO;
    _shouldReloadFriendRequestsVC = NO;
//    _newUser = NO;
    
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
//    _parentViewController = (ParentViewController*)[mainStoryboard
//                                                    instantiateViewControllerWithIdentifier: @"parentViewController"];
    
    
    
    // HACK
    // Make a call to the parentViewController so that its subviews are retained when the app enters the background
//    [_parentViewController view];
    
    /*
    // Set up views
    self.composeNavigationController = (NonRotatingNavigationController*)[mainStoryboard
                                                                   instantiateViewControllerWithIdentifier: @"composeNavigationController"];
    
    self.contactsNavigationController = (NonRotatingNavigationController*)[mainStoryboard
                                                                  instantiateViewControllerWithIdentifier: @"contactsNavigationController"];
    
    NSArray *viewControllers = self.composeNavigationController.viewControllers;
    ((ComposeViewController*)[viewControllers objectAtIndex:0])->_originalLink = YES;
    
    NSArray *contactsViewControllers = self.contactsNavigationController.viewControllers;
    ((ContactsViewController*)[contactsViewControllers objectAtIndex:0])->_sendingLink = NO;
    */
    
    // Create the log in view controller
    self.loginViewController = [[MFRLoginViewController alloc] init];
    [self.loginViewController setFields:PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsSignUpButton | PFLogInFieldsPasswordForgotten];
    [self.loginViewController setDelegate:self];
    
    // Create the sign up view controller
    self.signUpViewController = [[MySignUpViewController alloc] init];
    [self.signUpViewController setDelegate:self];
    [self.signUpViewController setFields:PFSignUpFieldsDefault | PFSignUpFieldsAdditional];
    [self.loginViewController setSignUpController:self.signUpViewController];

    //---------------------------------------
    // Uncomment to logout on loading the app
    //---------------------------------------
//    if ([PFUser currentUser]){
//        [PFUser logOut];
//    }
    
    [[self window] makeKeyAndVisible];
    
    self.parentViewController = (ParentViewController*)self.window.rootViewController;
    
    /*
    self.inboxNavigationController = (NonRotatingNavigationController*)self.window.rootViewController;
    */
    
    if ([PFUser currentUser]){
        _user = [PFUser currentUser];
        [self refreshUserFromCloud];
        [self getCurrentUserDefaultsFromNSUserDefaults];
    }
    
    _shouldRefreshInbox = NO;
    _shouldReloadInboxTable = NO;
    
    //--------------------------------------
    // Choose which ViewController to launch
    //--------------------------------------
    if (![PFUser currentUser]) { // No user logged in
        // Present the log in view controller
        [self showLoginViewController];
//    } else if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
//        // Opening app from a remote notification
//        NSArray *viewControllers = self.inboxNavigationController.viewControllers;
//        [((ViewController*)[viewControllers objectAtIndex:0]) refreshInbox];
//        // Might not need to do anything here, as the inbox is meant to be the landing screen anyway... test this
    }

    // Set navigation bar title font
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0],
      NSForegroundColorAttributeName,
      [UIFont fontWithName:@"Titillium-Regular" size:18.0],
      NSFontAttributeName,
      nil]];
    
    // Set bar button item font
    NSDictionary *textAttributes = @{
                                     NSForegroundColorAttributeName:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0],
                                     NSFontAttributeName:[UIFont fontWithName:@"Titillium-Regular" size:17.0]
                                      };
    [[UIBarButtonItem appearanceWhenContainedIn: [UINavigationController class],nil]
     setTitleTextAttributes:textAttributes
     forState:UIControlStateNormal];
    
    // Set text field cursor color
    [[UITextField appearance] setTintColor:[UIColor whiteColor]];
    
    // Set text field cursor color
    [[UITextView appearance] setTintColor:[UIColor whiteColor]];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Refresh inbox
    if ([self inboxHasBeenCreated]) {
        NSArray *viewControllers = self.parentViewController.inboxNavigationController.viewControllers;
        [((InboxViewController*)[viewControllers objectAtIndex:0]) refreshInbox:self];
    }
    else {
        _shouldRefreshInbox = YES;
    }
    
    // Refresh contacts
    if (_contactsVCHasBeenCreated) {
        [self fetchUserLinksFromCloud];
    } else {
        _shouldFetchContacts = YES;
    }
    
    // Refresh friend requests
    [self fetchFriendRequests];
    
//    if (_shouldFetchFriendRequests) {
//        [self fetchFriendRequests];
//    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Switching views
//- (void)showInboxNavigationController
//{
//    [self.window setRootViewController:self.inboxNavigationController];
//}
//
//- (void)showComposeNavigationController
//{
//    [self.window setRootViewController:self.composeNavigationController];
//}
//
//- (void)showContactsNavigationController
//{
//    [self.window setRootViewController:self.contactsNavigationController];
//}

-(void)showParentViewController {
    [self.window setRootViewController:self.parentViewController];
}

-(void)showLoginViewController
{
    [self.window setRootViewController:self.loginViewController];
    self.loginViewController.logInView.usernameField.text = @"";
    self.loginViewController.logInView.passwordField.text = @"";
}

-(void)showLoginViewControllerIfNotLoggedIn
{
    if (![PFUser currentUser]) { // No user logged in
        [self showLoginViewController];
    }
}

#pragma mark - PFLogInViewController delegate
// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    
    _user = user;
    
    PFInstallation* installation = [PFInstallation currentInstallation];
//    if (...) {
//        installation[@"user"] = user;
    installation[@"UserID"] = user.objectId;
        [installation saveInBackground];
//    }
    
    // Get locally stored messages from NSUserDefaults
    // TESTING THIS:
    _shouldReloadInboxTable = YES;
    
//    [self fetchUserLinksFromCloud];
    // TRYING INSTEAD OF THE ABOVE:
    [self refreshUserFromCloud];
    
    
    [self showParentViewController];
    [self getCurrentUserDefaultsFromNSUserDefaults];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
//    [self.navigationController popViewControllerAnimated:YES];
    [self showParentViewController];
}

#pragma mark - PFSignupViewController Delegate
// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
//    _newUser = YES;
    [self.loginViewController dismissModalViewControllerAnimated:YES]; // Dismiss the PFSignUpViewController
    
    //---------------------------
    // Send user their first link
    //---------------------------
    //-------------------------------------------------------------------------------------------
    // In the cloud, delete the current user from the deleted selected friend's WantToSeeMe array
    //-------------------------------------------------------------------------------------------
    NSDictionary* params = [[NSDictionary alloc] initWithObjectsAndKeys:user.objectId, @"recipientId", nil];
    
    NSLog(@"Params set");
    
    [PFCloud callFunctionInBackground:@"sendLinkOnSignup"
                       withParameters:params
                                block:^(NSNumber *ratings, NSError *error) {
                                    if (!error) {
                                        NSLog(@"First link successfully sent to user from The Ripple Team");
                                    }
                                }];
    
    NSLog(@"Cloud code called");
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}

#pragma mark - User Info
-(PFUser*)getUserInfo {
    return _user;
}

-(PFObject*)getUserLinks {
    return _userLinks;
}

-(NSMutableArray*)getRelationContacts {
    if (_usingFriendRelations) {
        return _contacts;
    }
    return nil;
}

-(void)refreshUserFromCloud {
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        _user = [PFUser currentUser];
        
        //-----------------------------------------------------------------
        // Convert contacts list to PFRelation friends list if not yet done
        //-----------------------------------------------------------------
        PFRelation* relation = [[PFUser currentUser] objectForKey:@"Friendship"];
        
        PFQuery* relationQuery = [relation query];
        [relationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            if (
                !error
                &&
                ([objects count] == 0)
                ) {
                //-----------------------------------------------------------------------
                // Friends yet to be stored, so we must get contacts and store as friends
                //-----------------------------------------------------------------------
                NSMutableArray* friendUsernames = [NSMutableArray array];
                NSMutableArray* contacts = [[_user objectForKey:@"Contacts"] mutableCopy];
                for (NSMutableDictionary* contact in contacts){
                    NSString* username = [contact objectForKey:@"Name"];
                    [friendUsernames addObject:username];
                }
                
                PFQuery* query = [PFUser query];
                [query whereKey:@"username" containedIn:friendUsernames];
                [query findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
                    if (!error) {
                        for (PFUser* user in userObjects) {
                            [relation addObject:user];
                        }
                        [[PFUser currentUser] saveInBackground];
                        
                        _usingFriendRelations = YES;
                    }
                }];
            } else if (!error && ([objects count] > 0)) {
                _usingFriendRelations = YES;
            }
        }];
        
        /*
//!!!!!! NB THIS DOES NOT WORK - IT REPLACES ALL CONTACTS. FIX IT BEFORE USING IT. !!!!!!
        //--------------------------------------------
        // Uncomment to add specific users to contacts
        //--------------------------------------------
        PFRelation* relationTwo = [[PFUser currentUser] objectForKey:@"Friendship"];
        
        PFQuery* relationQueryTwo = [relationTwo query];
        [relationQueryTwo findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            if (!error) {
                //-----------------------------------------------------------------------
                // Friends yet to be stored, so we must get contacts and store as friends
                //-----------------------------------------------------------------------
                NSMutableArray* friendUsernames = [NSMutableArray array];
               [friendUsernames addObject:@"edrexipad"];
                
                PFQuery* query = [PFUser query];
                [query whereKey:@"username" containedIn:friendUsernames];
                [query findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
                    if (!error) {
                        for (PFUser* user in userObjects) {
                            [relationTwo addObject:user];
                        }
                        [[PFUser currentUser] saveInBackground];
                        
                        // Store contacts locally
                        _contacts = [userObjects mutableCopy];
                        _usingFriendRelations = YES;
                    }
                }];
            } else if (!error && ([objects count] > 0)) {
                _contacts = [objects mutableCopy];
                _usingFriendRelations = YES;
            }
        }];
        */
        
        [self fetchUserLinksFromCloud];
        [self fetchFriendRequests];
    }];
}

-(void)fetchUserLinksFromCloud {
    if (_shouldFetchContacts) {
        _shouldFetchContacts = NO;
    }
    PFQuery* query = [PFQuery queryWithClassName:@"UserLinks"];
    [query whereKey:@"UserID" equalTo:_user.objectId];
     [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
         if (!error){
             if ([objects count] > 0){
                 _userLinks = [objects objectAtIndex:0];
                 
                 //--------------------------------------------------------------------------------------
                 // Transfer contacts from User to UserLinks if it hasn't already been done for this user
                 //--------------------------------------------------------------------------------------
                 PFRelation* userLinksContacts = [_userLinks objectForKey:@"Friendships"];
                 PFQuery* userLinksContactsQuery = [userLinksContacts query];
                 NSArray* userLinksContactObjects = [userLinksContactsQuery findObjects];
                 if ([userLinksContactObjects count] == 0) {
                     
                     PFRelation* relation = [[PFUser currentUser] objectForKey:@"Friendship"];
                     PFQuery* relationQuery = [relation query];
                     NSArray* contacts = [relationQuery findObjects];
                     for (PFUser* contact in contacts) {
                         [userLinksContacts addObject:contact];
                         [_contacts addObject:contact];
                     }
                     [_userLinks saveInBackground];
                 } else {
                     _contacts = [userLinksContactObjects mutableCopy];
                 }
                 
             } else {
                 [self createUserLinksObject];
             }
             
         } else {
             // Indicate that there is no internet connection
             // TEMPORARY:
             _userLinks = nil;
         }
         
         [self performSelectorOnMainThread:@selector(refreshInboxViewController) withObject:nil waitUntilDone:NO];
         
         [self performSelectorOnMainThread:@selector(refreshContactsViewController) withObject:nil waitUntilDone:NO];
     }];
}

-(void)fetchFriendRequests {
    //---------------------------------
    // Fetch friend requests from cloud
    //---------------------------------
    PFQuery* friendRequestsQuery = [PFQuery queryWithClassName:@"FriendRequest"];
    [friendRequestsQuery whereKey:@"Recipient" equalTo:[PFUser currentUser]];
    [friendRequestsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            _friendRequests = [objects mutableCopy];
            
            // Update views that are affected by the number of friend requests
            [self updateViewsForFetchedFriendRequests];
        }
    }];
}

-(void)updateViewsForFetchedFriendRequests {
    [(ComposeViewController*)[self.parentViewController.composeNavigationController.viewControllers objectAtIndex:0] updateFriendRequestsLabel:[NSNumber numberWithInteger:[_friendRequests count]]];
    
    // Indicate that the friend requests VC should reload
    _shouldReloadFriendRequestsVC = YES;
}

-(NSMutableArray*)getFriendRequests {
    return _friendRequests;
}

-(void)getCurrentUserDefaultsFromNSUserDefaults {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    _currentUserDefaults = [[defaults objectForKey:[PFUser currentUser].objectId] mutableCopy];
    if (_currentUserDefaults) {
        
        _localMessageThreads = [[_currentUserDefaults objectForKey:@"MessageThreads"] mutableCopy];
        if (!_localMessageThreads) {
            _localMessageThreads = [NSMutableArray array];
        } else {
//            // TEMPORARY - DELETE LOCAL MESSAGE THREADS
//            _localMessageThreads = [NSMutableArray array];
//            
//            [self storeLocalMessageThreads:_localMessageThreads];
            
            //--------------------------------------------------------------------------------
            // If there are any messages still marked 'sending', mark them as 'sending failed'
            //--------------------------------------------------------------------------------
            NSMutableDictionary* messageThreadsToHaveMessagesReplaced = [NSMutableDictionary dictionary];
            for (int i = 0; i < [_localMessageThreads count]; i++) {
                
                NSMutableArray* messages = [[[_localMessageThreads objectAtIndex:i] objectForKey:@"Messages"] mutableCopy];
                
                NSMutableArray* messageNumbersToMarkAsFailed = [NSMutableArray array];
                
                for (int j = 0; j < [messages count]; j++) {
                    if (
                        [[messages objectAtIndex:j] objectForKey:@"SendingStatus"]
                        &&
                        ([[[messages objectAtIndex:j] objectForKey:@"SendingStatus"] intValue] == MFRLocalMessageStatusSending)
                        ) {
                        [messageNumbersToMarkAsFailed addObject:[NSNumber numberWithInt:j]];
                    }
                }
                for (NSNumber* entry in messageNumbersToMarkAsFailed) {
                    NSMutableDictionary* message = [[messages objectAtIndex:[entry intValue]] mutableCopy];
                    [message setObject:[NSNumber numberWithInt:MFRLocalMessageStatusSendingFailed] forKey:@"SendingStatus"];
                    [messages replaceObjectAtIndex:[entry intValue] withObject:message];
                }
                
                if ([messageNumbersToMarkAsFailed count] > 0) {
                    [messageThreadsToHaveMessagesReplaced setObject:messages forKey:[NSString stringWithFormat:@"%d", i]];
                }
            }
            
            if ([messageThreadsToHaveMessagesReplaced count] > 0) {
                NSArray* keys = [messageThreadsToHaveMessagesReplaced allKeys];
                for (NSString* key in keys) {
                    int entry = [key intValue];
                    
                    NSMutableDictionary* messageThread = [[_localMessageThreads objectAtIndex:entry] mutableCopy];
                    [messageThread setObject:[messageThreadsToHaveMessagesReplaced objectForKey:key] forKey:@"Messages"];
                    [_localMessageThreads replaceObjectAtIndex:entry withObject:messageThread];
                }
                
                [self storeLocalMessageThreads:_localMessageThreads];
            }
        }
        
        _usernameFullNames = [[_currentUserDefaults objectForKey:@"UsernameFullNames"] mutableCopy];
        if (!_usernameFullNames) {
            _usernameFullNames = [NSMutableDictionary dictionary];
        }
        
        _friendInvitePromptTally = [_currentUserDefaults objectForKey:@"FriendInvitePromptTally"];
        if (!_friendInvitePromptTally) {
            _friendInvitePromptTally = [NSNumber numberWithInt:0];
        }
    } else {
        _currentUserDefaults = [NSMutableDictionary dictionary];
        _localMessageThreads = [NSMutableArray array];
        _usernameFullNames = [NSMutableDictionary dictionary];
        _friendInvitePromptTally = [NSNumber numberWithInt:0];
    }
}

-(void)refreshInboxViewController{
    
    if (_inboxHasBeenCreated) {
//        [(InboxViewController*)[self.parentViewController.inboxNavigationController.viewControllers objectAtIndex:0] getMessageThreadsForUser:self];
        [(InboxViewController*)[self.parentViewController.inboxNavigationController.viewControllers objectAtIndex:0] refreshInbox:self];
    
//    if ((InboxViewController*)[self.parentViewController.inboxNavigationController.viewControllers objectAtIndex:0]) {
//        [(InboxViewController*)[self.parentViewController.inboxNavigationController.viewControllers objectAtIndex:0] getMessageThreadsForUser:self];
    } else {
        _shouldRefreshInbox = YES;
    }
}

-(void)reloadInboxViewController {
    if (_inboxHasBeenCreated) {
        [(InboxViewController*)[self.parentViewController.inboxNavigationController.viewControllers objectAtIndex:0] getLocalMessageThreadsAndReloadInboxTableView];
    } else {
        _shouldReloadInboxTable = YES;
    }
}

-(void)refreshContactsViewController{
    if (_contactsVCHasBeenCreated) {
        [(ContactsViewController*)[self.parentViewController.contactsNavigationController.viewControllers objectAtIndex:0] refreshContactsFromAppDelegate];
    }
}

-(void)createUserLinksObject {
    _userLinks = [PFObject objectWithClassName:@"UserLinks"];
    [_userLinks setObject:_user.objectId forKey:@"UserID"];
    [_userLinks saveInBackground];
}

-(void)storeUserLinks:(PFObject*)uL {
    _userLinks = uL;
}

#pragma mark - Push Notifications
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
//    currentInstallation[@"user"] = [PFUser currentUser];
//    [currentInstallation setObject:_user.objectId forKey:@"UserID"];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    [self fetchFriendRequests];
    [self fetchUserLinksFromCloud];
    [self refreshInboxViewController];
    
//    ...
//    if (
//        [userInfo objectForKey:@"MFRPushType"]
//        &&
//        [[userInfo objectForKey:@"MRDPushType"] isEqualToString:@"FriendRequest"]
//        ) {
//        // Friend request push
//        if (application.applicationState == UIApplicationStateActive) {
//            [self fetchFriendRequests];
//        } else {
//            _shouldFetchFriendRequests = YES;
//        }
//    }
//    
//    else if (
//             [userInfo objectForKey:@"MFRPushType"]
//             &&
//             [[userInfo objectForKey:@"MRDPushType"] isEqualToString:@"FriendAcceptance"]
//             ) {
//        // Friend request push
//        if (application.applicationState == UIApplicationStateActive) {
//            // Refresh contacts from cloud
//            [self fetchUserLinksFromCloud];
//        } else {
//            _shouldFetchContacts = YES;
//        }
//    }
//    
//    else if (
//        (application.applicationState == UIApplicationStateActive)
//        &&
//        [self inboxHasBeenCreated]
//        ) {
//        // Inbox is displayed, so refresh
//        NSArray *viewControllers = self.parentViewController.inboxNavigationController.viewControllers;
//        [((InboxViewController*)[viewControllers objectAtIndex:0]) refreshInbox:self];
//    } else {
//        // Inbox is not displayed, so mark that it should be refreshed when it's next displayed
//        _shouldRefreshInbox = YES;
//    }
}

-(void)markInboxAsCreated {
    _inboxHasBeenCreated = YES;
}

-(BOOL)inboxHasBeenCreated {
    
    return _inboxHasBeenCreated;
}

-(void)markContactsVCAsCreated {
    _contactsVCHasBeenCreated = YES;
}

-(BOOL)inboxShouldRefresh {
    return _shouldRefreshInbox;
}

-(void)setShouldInboxRefresh:(BOOL)b {
    _shouldRefreshInbox = b;
}

-(BOOL)inboxTableShouldReload {
    return _shouldReloadInboxTable;
}

-(void)setInboxToReload:(BOOL)b {
    _shouldReloadInboxTable = b;
}

/*
-(void)addNewMessageThreadInInbox:(NSMutableDictionary*)messageThread {
    
    NSArray *viewControllers = self.parentViewController.inboxNavigationController.viewControllers;
    [((InboxViewController*)[viewControllers objectAtIndex:0]) addNewMessageThread:messageThread];
}
*/

-(void)storeImage:(UIImage*)image forURL:(NSString*)imageURL {
    [_linkImages setObject:image forKey:imageURL];
}

-(void)storeLargeImage:(UIImage*)image forURL:(NSString*)imageURL {
    [_largeLinkImages setObject:image forKey:imageURL];
}

-(UIImage*)getImage:(NSString*)imageURL {
    if ([_linkImages objectForKey:imageURL]) {
        return [_linkImages objectForKey:imageURL];
    }
    return nil;
}

-(UIImage*)getLargeImage:(NSString*)imageURL {
    if ([_largeLinkImages objectForKey:imageURL]) {
        return [_largeLinkImages objectForKey:imageURL];
    }
    return nil;
}

-(void)storeFullName:(NSString*)fullName forUsername:(NSString*)username {
    
    [_usernameFullNames setObject:fullName forKey:username];
    
    [self performSelectorOnMainThread:@selector(updateUsernameFullNamesInNSUserDefaults) withObject:nil waitUntilDone:NO];
}

-(void)updateUsernameFullNamesInNSUserDefaults {
    // Store in NSUserDefaults
    [_currentUserDefaults setObject:_usernameFullNames forKey:@"UsernameFullNames"];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_currentUserDefaults forKey:[PFUser currentUser].objectId];
    [defaults synchronize];
}

-(NSString*)getFullNameForUsername:(NSString*)username {
    if ([_usernameFullNames objectForKey:username]) {
        return [_usernameFullNames objectForKey:username];
    }
    return nil;
}

-(void)addContact:(PFUser*)contact {
    if (!_contacts) {
        _contacts = [NSMutableArray array];
    }
    [_contacts addObject:contact];
}

//-(void)decrementBadgeNumber {
//    if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
//        [UIApplication sharedApplication].applicationIconBadgeNumber--;
//        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//        currentInstallation.badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
//        [currentInstallation saveEventually];
//    }
//}
//
//-(void)incrementBadgeNumber {
//    [UIApplication sharedApplication].applicationIconBadgeNumber++;
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    currentInstallation.badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
//    [currentInstallation saveEventually];
//}

-(BOOL)contactsNeedRefreshing {
    return _shouldFetchContacts;
}

-(void)setShouldReloadContacts:(BOOL)b {
    _shouldReloadContacts = b;
}

-(BOOL)shouldReloadContacts {
    return _shouldReloadContacts;
}

-(ContactsViewController*)getContactsVC {
    if (_contactsVCHasBeenCreated) {
        return (ContactsViewController*)[self.parentViewController.contactsNavigationController.viewControllers objectAtIndex:0];
    }
    return nil;
}

-(BOOL)shouldReloadFriendRequestsVC {
    return _shouldReloadFriendRequestsVC;
}

-(void)setShouldReloadFriendRequestsVC:(BOOL)b {
    _shouldReloadFriendRequestsVC = b;
}

-(void)setBadgeAccordingToInbox {
    if (_inboxHasBeenCreated) {
        [(InboxViewController*)[self.parentViewController.inboxNavigationController.viewControllers objectAtIndex:0] updateBadge];
    }
}

-(void)updateBadgeWithUnreadMessages:(int)unreadCount {
    [UIApplication sharedApplication].applicationIconBadgeNumber = unreadCount;
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = unreadCount;
    [currentInstallation saveEventually];

}

-(void)notifyViewControllersOfReplySuccess:(BOOL)success forMessageThreadID:(NSString*)messageThreadID {
    
    if (
        [[self.parentViewController.inboxNavigationController topViewController] isKindOfClass:[ViewController class]]
        &&
        [[(ViewController*)[self.parentViewController.inboxNavigationController topViewController] getMessageThreadID] isEqualToString:messageThreadID]
        ) {
        // Message VC is displayed (for the same messageThread as has been successfully replied to), so notify it of reply success
        [(ViewController*)[self.parentViewController.inboxNavigationController topViewController] notifyReplySuccess:success updatedMessageID:messageThreadID];
    }
    
    // Refresh the inbox to show the change in sending status of the message
    [self performSelectorOnMainThread:@selector(reloadInboxViewController) withObject:nil waitUntilDone:NO];
}

-(void)notifyViewControllersOfReplySuccess:(BOOL)success forOldMessageThreadID:(NSString*)oldMessageThreadID andNewMessageThreadID:(NSString*)newMessageThreadID {
    
    if (
        [[self.parentViewController.inboxNavigationController topViewController] isKindOfClass:[ViewController class]]
        &&
        (
        [[(ViewController*)[self.parentViewController.inboxNavigationController topViewController] getMessageThreadID] isEqualToString:oldMessageThreadID]
         ||
         [[(ViewController*)[self.parentViewController.inboxNavigationController topViewController] getMessageThreadID] isEqualToString:newMessageThreadID]
         )
        ) {
        // Message VC is displayed (for the same messageThread as has been successfully replied to), so notify it of reply success
        [(ViewController*)[self.parentViewController.inboxNavigationController topViewController] notifyReplySuccess:success updatedMessageID:newMessageThreadID];
    }
    
    // Refresh the inbox to show the change in sending status of the message
    [self performSelectorOnMainThread:@selector(reloadInboxViewController) withObject:nil waitUntilDone:NO];
}

#pragma mark - Accessing and storing user defaults
-(NSMutableArray*)getLocalMessageThreads {
    return _localMessageThreads;
}

-(void)storeLocalMessageThreads:(NSMutableArray*)messageThreads {
    // Store locally
    _localMessageThreads = messageThreads;
    
    [self performSelectorOnMainThread:@selector(updateLocalMessageThreadsInNSUserDefaults) withObject:nil waitUntilDone:NO];
}

-(NSNumber*)getFriendInvitePromptTally {
    return _friendInvitePromptTally;
}

-(void)setFriendInvitePromptTally:(NSNumber*)tally {
    _friendInvitePromptTally = tally;
    [self performSelectorOnMainThread:@selector(updateFriendInvitePromptTallyInNSUserDefaults) withObject:nil waitUntilDone:NO];
}

-(void)updateLocalMessageThreadsInNSUserDefaults {
    // Store in NSUserDefaults
    if ([PFUser currentUser]) {
        [_currentUserDefaults setObject:_localMessageThreads forKey:@"MessageThreads"];
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:_currentUserDefaults forKey:[PFUser currentUser].objectId];
        [defaults synchronize];
    }
}

-(void)updateFriendInvitePromptTallyInNSUserDefaults {
    // Store in NSUserDefaults
    if ([PFUser currentUser]) {
        [_currentUserDefaults setObject:_friendInvitePromptTally forKey:@"FriendInvitePromptTally"];
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:_currentUserDefaults forKey:[PFUser currentUser].objectId];
        [defaults synchronize];
    }
}

-(void)displayInboxAndScrollToTop {
    
    [self.parentViewController displayInboxAndScrollToTop:_inboxHasBeenCreated];
}

-(void)clearUserData {
    
    // NB Messages really cleared in LogoutDelegate
    
    [(InboxViewController*)[self.parentViewController.inboxNavigationController.viewControllers objectAtIndex:0] removeAllMessagesInApp];
    
    [_contacts removeAllObjects];
    [_friendRequests removeAllObjects];
    [_localMessageThreads removeAllObjects];
    
    [(ComposeViewController*)[self.parentViewController.composeNavigationController.viewControllers objectAtIndex:0] clearTextFieldAndDiscardLinkInfo];
}

//-(BOOL)newUser {
//    return _newUser;
//}
//
//-(void)setNewUser:(BOOL)b {
//    _newUser = b;
//}

@end
