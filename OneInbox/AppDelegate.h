//
//  AppDelegate.h
//  OneInbox
//
//  Created by Ed Rex on 02/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "NonRotatingNavigationController.h"
#import "MFRLoginViewController.h"
#import "MySignUpViewController.h"
#import "ParentViewController.h"
#import "ContactsViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) ParentViewController* parentViewController;
@property (strong, nonatomic) MFRLoginViewController* loginViewController;
@property (strong, nonatomic) MySignUpViewController* signUpViewController;
@property (nonatomic, retain) NSMutableDictionary* linkImages;
@property (nonatomic, retain) NSMutableDictionary* largeLinkImages;
@property (nonatomic, retain) NSMutableDictionary* usernameFullNames;
@property (nonatomic, retain) NSMutableArray* friendRequests;
@property (nonatomic, retain) NSMutableDictionary* currentUserDefaults;
@property (nonatomic, retain) NSMutableArray* localMessageThreads;
@property (nonatomic, retain) NSNumber* friendInvitePromptTally;
@property (nonatomic, assign) BOOL inboxShouldRefresh;

- (void)showInboxNavigationController;
- (void)showComposeNavigationController;
- (void)showContactsNavigationController;
- (void)showLoginViewController;

-(void)showLoginViewControllerIfNotLoggedIn;

-(PFUser*)getUserInfo;
-(PFObject*)getUserLinks;
-(void)storeUserLinks:(PFObject*)uL;

-(void)clearContacts;

-(BOOL)inboxTableShouldReload;
-(void)setInboxToReload:(BOOL)b;

-(void)markInboxAsCreated;
-(void)markContactsVCAsCreated;

-(NSMutableArray*)getRelationContacts;

//-(void)addNewMessageThreadInInbox:(NSMutableDictionary*)messageThread;

-(void)storeImage:(UIImage*)image forURL:(NSString*)imageURL;
-(void)storeLargeImage:(UIImage*)image forURL:(NSString*)imageURL;
-(UIImage*)getImage:(NSString*)imageURL;
-(UIImage*)getLargeImage:(NSString*)imageURL;

-(void)storeFullName:(NSString*)fullName forUsername:(NSString*)username;
-(NSString*)getFullNameForUsername:(NSString*)username;

-(NSMutableArray*)getFriendRequests;

-(void)addContact:(PFUser*)contact;

-(BOOL)contactsNeedRefreshing;
-(void)fetchUserLinksFromCloud;

-(void)setShouldReloadContacts:(BOOL)b;
-(BOOL)shouldReloadContacts;
-(ContactsViewController*)getContactsVC;

-(BOOL)shouldReloadFriendRequestsVC;
-(void)setShouldReloadFriendRequestsVC:(BOOL)b;

-(BOOL)inboxHasBeenCreated;

-(void)setBadgeAccordingToInbox;
-(void)updateBadgeWithUnreadMessages:(int)unreadCount;

-(void)notifyViewControllersOfReplySuccess:(BOOL)success forMessageThreadID:(NSString*)messageThreadID;
-(void)notifyViewControllersOfReplySuccess:(BOOL)success forOldMessageThreadID:(NSString*)oldMessageThreadID andNewMessageThreadID:(NSString*)newMessageThreadID;

-(NSMutableArray*)getLocalMessageThreads;
-(void)storeLocalMessageThreads:(NSMutableArray*)messageThreads;

-(NSNumber*)getFriendInvitePromptTally;
-(void)setFriendInvitePromptTally:(NSNumber*)tally;

-(void)displayInboxAndScrollToTop;

-(void)reloadInboxViewController;

-(void)clearUserData;

//-(BOOL)newUser;
//-(void)setNewUser:(BOOL)b;

@end
