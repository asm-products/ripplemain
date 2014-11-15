//
//  InboxViewController.m
//  Ripple
//
//  Created by Ed Rex on 21/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "InboxViewController.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"
#import "InboxCell.h"
#import "MFRAnalytics.h"
#import "MFRParseMessageThread.h"
#import "ImageDownloader.h"
#import "FullNameDownloader.h"
#import "MultipleFullNamesDownloader.h"
#import "MFRLocalMessageThread.h"
#import "MFRDateTime.h"
#import "PhoneBookContactsViewController.h"
#import "MHTabBarController.h"
#import "NonRotatingNavigationController.h"

#define LABEL_FONT @"Titillium-Regular"
#define LABEL_FONT_SIZE 17.0

@interface InboxViewController () {
    
    BOOL _messagesHaveBeenFetched;
    BOOL _refreshing;
    BOOL _newlyComposedMessageAdded;
}

@property (nonatomic, retain) NSMutableArray* messages;
@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;
@property (nonatomic, strong) NSMutableDictionary *fullNameDownloadsInProgress;

@end

@implementation InboxViewController

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
    
    [self setUpViewAndHelpers];
    
    [self getMessageThreadsFromUserDefaults];
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate markInboxAsCreated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //-----------------------------------------------------------
    // When returning to the view, check scroll gesture is active
    //-----------------------------------------------------------
    [parentDelegate addSwipeGesture];
    
    //----------------------------------------------------
    // Refresh links / reload inbox table view as required
    //----------------------------------------------------
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.inboxShouldRefresh) {
        [self refreshInbox:self];
        appDelegate.inboxShouldRefresh = NO;
    } else if ([appDelegate inboxTableShouldReload]) {
        [self getLocalMessageThreadsAndReloadInboxTableView];
        [appDelegate setInboxToReload:NO];
    } else if (_newlyComposedMessageAdded) {
        [self getLocalMessageThreadsAndReloadInboxTableView];
        _newlyComposedMessageAdded = NO;
    }
    
    if ([PFUser currentUser]) {
        [self considerPromptingFriendInvite];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //-------------------------------------
    // Stop refreshing when view disappears
    //-------------------------------------
    [self.refreshControl endRefreshing];
    _refreshing = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    //-------------------------------------------
    // Terminate all pending download connections
    //-------------------------------------------
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.imageDownloadsInProgress removeAllObjects];
    
    NSArray *allFullNameDownloads = [self.fullNameDownloadsInProgress allValues];
    [allFullNameDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.fullNameDownloadsInProgress removeAllObjects];
}

#pragma mark - View setup
-(void)setUpViewAndHelpers {
    
    [_noMessagesLabelOne setFont:[UIFont fontWithName:LABEL_FONT size:LABEL_FONT_SIZE]];
    [_noMessagesLabelTwo setFont:[UIFont fontWithName:LABEL_FONT size:LABEL_FONT_SIZE]];
    [self.view addSubview:_noMessagesView];
    _noMessagesView.hidden = YES;
    
    [self.tableView registerClass:[InboxCell class] forCellReuseIdentifier:@"MessageCell"];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self addNavBarButtons];
    [self addRefreshControl];
    
    _messagesHaveBeenFetched = NO;
    _refreshing = NO;
    _newlyComposedMessageAdded = NO;
    
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    self.fullNameDownloadsInProgress = [NSMutableDictionary dictionary];
    
    // Display image in Navigation Bar
    UIImage *image = [UIImage imageNamed:@"RippleNavBarLogo.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithImage:image];
    [self.navigationController.navigationBar.topItem setTitleView:titleView];
}

-(void)addRefreshControl {
    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshInbox:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
}

#pragma mark - Nav bar
-(void)addNavBarButtons {
    
    // Compose button
    UIButton *bt=[UIButton buttonWithType:UIButtonTypeCustom];
    [bt setFrame:CGRectMake(0, 0, 25, 25)];
    [bt setImage:[UIImage imageNamed:@"Pencil-128"] forState:UIControlStateNormal];
    [bt addTarget:self action:@selector(pushComposeViewController) forControlEvents:UIControlEventTouchUpInside];
    bt.showsTouchWhenHighlighted = YES;
    _composeButton = [[UIBarButtonItem alloc] initWithCustomView:bt];
    self.navigationController.navigationBar.topItem.rightBarButtonItem = _composeButton;
    
    // Settings button
    UIButton *settingsBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    [settingsBtn setFrame:CGRectMake(0, 0, 25, 25)];
    [settingsBtn setImage:[UIImage imageNamed:@"Settings-128"] forState:UIControlStateNormal];
    [settingsBtn addTarget:self action:@selector(pushSettingsViewController) forControlEvents:UIControlEventTouchUpInside];
    settingsBtn.showsTouchWhenHighlighted = YES;
    _settingsButton = [[UIBarButtonItem alloc] initWithCustomView:settingsBtn];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = _settingsButton;
}

#pragma mark - Inbox message order
-(void)updateMessageOrder {
    NSArray* unorderedMessageThreads = [_messages mutableCopy];
    _messages = [self orderMessageThreadsByTime:unorderedMessageThreads dateAscending:NO];
}

#pragma mark - Refreshing inbox
-(void)refreshInbox:(id)sender {
    if (!_refreshing) {
        
        _refreshing = YES;
        
        //-------------------------------------------------------
        // Fetch message threads from the cloud in the background
        //-------------------------------------------------------
        AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        PFObject* userLinks = [appDelegate getUserLinks];
        
        if (userLinks.objectId) {
            
            // userLinks has been saved to the cloud
            [userLinks fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error) {
                    
                    NSMutableArray* localMessageThreads = [appDelegate getLocalMessageThreads];
                    
                    //------------------------------------------------------------------------------------------------------
                    // Fetch all this user's message threads that have been updated since the version that is stored locally
                    //------------------------------------------------------------------------------------------------------
                    PFRelation* relation = [userLinks objectForKey:@"MessageThreads"];
                    PFQuery* relationQuery = [relation query];
                    relationQuery.limit = 1000;
                    
                    if (localMessageThreads) {
                        // This user has message threads stored, so only fetch message threads that are new or have been updated
                        if ([localMessageThreads count] > 0) {
                            NSDictionary* messageThread = [localMessageThreads objectAtIndex:0];
                            NSDate* latestUpdate = [messageThread objectForKey:@"updatedAt"];
                            [relationQuery whereKey:@"updatedAt" greaterThan:latestUpdate];
                        }
                    }
                    //                }
                    [relationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        
                        if (
                            !error
                            &&
                            ([objects count] > 0)
                            ) {
                            
                            //-------------------------------------------------
                            // Sort the fetched message threads into time order
                            //-------------------------------------------------
                            NSMutableArray* unorderedMessageThreads = [objects mutableCopy];
                            NSMutableArray* orderedMessageThreads = [self orderMessageThreadsByTime:unorderedMessageThreads dateAscending:YES];
                            
                            //----------------------------------------------------------------------------------------------
                            // Add the fetched message threads to NSUserDefaults, replacing old message threads if necessary
                            //----------------------------------------------------------------------------------------------
                            //                        NSMutableArray* localMessageThreads;
                            //                        if (currentUserDefaultsExist) {
                            //                            localMessageThreads = [[currentUserDefaults objectForKey:@"MessageThreads"] mutableCopy];
                            //                        }
                            //                        if (!localMessageThreads) {
                            //                            localMessageThreads = [NSMutableArray array];
                            //                        }
                            for (PFObject* fetchedMessageThread in orderedMessageThreads) {
                                int localMessageThreadEntry;
                                BOOL localMessageThreadExistsAlready = NO;
                                for (int i = 0; i < [localMessageThreads count]; i++) {
                                    if ([fetchedMessageThread.objectId isEqualToString:[[localMessageThreads objectAtIndex:i] objectForKey:@"objectId"]]) {
                                        
                                        localMessageThreadEntry = i;
                                        localMessageThreadExistsAlready = YES;
                                        break;
                                    }
                                }
                                BOOL shouldStoreFetchedMessageThread = YES;
                                if (localMessageThreadExistsAlready) {
                                    
                                    //                                POTENTIAL PROBLEM - CLOUD / LOCAL TIMES MAY DIFFER SLIGHTLY, SO ANY MESSAGETHREADS THAT HAVE BEEN UPDATED IN THE CLOUD WILL BE TAKEN AS RECENT
                                    //
                                    //                                SO HOW TO CHECK WHETHER CLOUD MESSAGESTHREAD HAS NEW MESSAGES?
                                    
                                    if (![MFRParseMessageThread cloudMessageThread:fetchedMessageThread hasSameLastMessageTimeAsLocalMessageThread:[localMessageThreads objectAtIndex:localMessageThreadEntry]]) {
                                        // Fetched messageThread has a new message, so remove old version of messageThread
                                        [localMessageThreads removeObjectAtIndex:localMessageThreadEntry];
                                    } else {
                                        // Fetched messageThread has no new message, so no need to update local messageThread
                                        shouldStoreFetchedMessageThread = NO;
                                    }
                                }
                                
                                if (shouldStoreFetchedMessageThread) {
                                    PFObject* originator = [fetchedMessageThread objectForKey:@"Originator"];
                                    
                                    NSMutableDictionary* fetchedMessageDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[fetchedMessageThread objectForKey:@"Messages"], @"Messages", [fetchedMessageThread objectForKey:@"UnreadMarkers"], @"UnreadMarkers", originator.objectId, @"originatorId", [fetchedMessageThread objectForKey:@"linkString"], @"linkString", fetchedMessageThread.objectId, @"objectId", fetchedMessageThread.updatedAt, @"updatedAt", fetchedMessageThread.createdAt, @"createdAt", nil];
                                    
                                    if ([fetchedMessageThread objectForKey:@"titleString"]) {
                                        [fetchedMessageDict setObject:[fetchedMessageThread objectForKey:@"titleString"] forKey:@"titleString"];
                                    }
                                    if ([fetchedMessageThread objectForKey:@"imageURL"]) {
                                        [fetchedMessageDict setObject:[fetchedMessageThread objectForKey:@"imageURL"] forKey:@"imageURL"];
                                    }
                                    
                                    [localMessageThreads insertObject:fetchedMessageDict atIndex:0];
                                }
                            }
                            
                            //--------------------
                            // Save NSUserDefaults
                            //--------------------
                            [appDelegate storeLocalMessageThreads:localMessageThreads];
                            
                            //                        [currentUserDefaults setObject:localMessageThreads forKey:@"MessageThreads"];
                            //                        [defaults setObject:currentUserDefaults forKey:[PFUser currentUser].objectId];
                            //                        [defaults synchronize];
                            
                            //-----------------------------------------------------------------
                            // Store message threads in view controller to be used in tableview
                            //-----------------------------------------------------------------
                            _messages = [localMessageThreads mutableCopy];
                            
                            [self performSelectorOnMainThread:@selector(reloadInboxTableView) withObject:nil waitUntilDone:NO];
                        }
                        if ([sender isKindOfClass:[UIRefreshControl class]]) {
                            [MFRAnalytics trackEvent:@"Inbox refreshed by user"];
                            [(UIRefreshControl*)sender endRefreshing];
                        }
                        _refreshing = NO;
                    }];
                    
                    // Store new userLinks in AppDelegate
                    [appDelegate storeUserLinks:userLinks];
                    
                    // Refresh the table view of messages
                    //                [self getMessageThreadsForUser:sender];
                } else {
                    if ([sender isKindOfClass:[UIRefreshControl class]]) {
                        [MFRAnalytics trackEvent:@"Inbox refreshing failed"];
                        [(UIRefreshControl*)sender endRefreshing];
                    }
                    _refreshing = NO;
                }
            }];
        } else {
            // userLinks has not yet been saved to the cloud, so don't refresh
            _refreshing = NO;
        }
    }
}

-(void)getMessageThreadsFromUserDefaults {
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    _messages = [self orderMessageThreadsByTime:[appDelegate getLocalMessageThreads] dateAscending:NO];
    
    [appDelegate storeLocalMessageThreads:_messages];
}

-(void)getLocalMessageThreadsAndReloadInboxTableView {
    [self getMessageThreadsFromUserDefaults];
    [self reloadInboxTableView];
}

-(void)reloadInboxTableView {
    if ([_messages count] == 0) {
        _noMessagesView.hidden = NO;
    } else {
        _noMessagesView.hidden = YES;
        [self.tableView reloadData];
    }
    [self updateBadge];
}

/*
-(void)getMessageThreadsForUser:(id)sender
{
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    PFObject* userLinks = [appDelegate getUserLinks];
    
    PFRelation* relation = [userLinks objectForKey:@"MessageThreads"];
    PFQuery* relationQuery = [relation query];
    relationQuery.limit = 1000;
    [relationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSArray* unorderedMessageThreads = [objects mutableCopy];
        [self orderMessageThreadsByTime:unorderedMessageThreads];
        
        [self performSelectorOnMainThread:@selector(reloadInboxTableView) withObject:nil waitUntilDone:NO];
        
        if ([sender isKindOfClass:[UIRefreshControl class]]) {
            [MFRAnalytics trackEvent:@"Inbox refreshed by user"];
            [(UIRefreshControl*)sender endRefreshing];
        }
        _refreshing = NO;
    }];
}
*/

-(NSMutableArray*)orderMessageThreadsByTime:(NSArray*)unorderedMessageThreads dateAscending:(BOOL)dateAscending {
    //------------------------------------------------------------------------------
    // Order message threads by the time of their latest message (most recent first)
    //------------------------------------------------------------------------------
    NSMutableArray* times = [NSMutableArray array];
    int count = 0;
    for (NSMutableDictionary* messageThread in unorderedMessageThreads) {
        NSDictionary* latestMessage = [MFRLocalMessageThread getLatestMessageFromMessageThread:messageThread];
        
        NSDate* localDateTime;
        if (latestMessage) {
            // Message thread has messages
            
            localDateTime = [MFRDateTime getLocalDateTimeFromGMTDateString:[latestMessage objectForKey:@"Date"]];
            
//            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
//            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//            date = [formatter dateFromString:[latestMessage objectForKey:@"Date"]];
        } else {
            // Message thread has no messages, so use 'createdAt' value
//            date = [messageThread objectForKey:@"createdAt"];
            localDateTime = [MFRDateTime getLocalDateTimeFromGMTDateTime:[messageThread objectForKey:@"createdAt"]];
        }
        
        NSDictionary* timeDict = @{@"Date": localDateTime, @"Entry": [NSNumber numberWithInt:count]};
        [times addObject:timeDict];
        count++;
    }
    NSArray *sortedTimesArray = [times sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"Date" ascending:dateAscending]]];
    
    NSMutableArray* orderedMessages = [NSMutableArray array];
    for (NSDictionary* timeDict in sortedTimesArray) {
        [orderedMessages addObject:[unorderedMessageThreads objectAtIndex:[[timeDict objectForKey:@"Entry"] intValue]]];
    }
    
    if (!_messagesHaveBeenFetched) {
        _messagesHaveBeenFetched = YES;
    }
    
    return orderedMessages;
}

-(void)updateBadge {
    //-----------------------------
    // Update app icon/Parse badges
    //-----------------------------
    int unreadCount = 0;
    for (NSDictionary* messageThread in _messages) {
        if ([MFRLocalMessageThread messageThreadIsUnread:messageThread]) {
            unreadCount++;
        }
    }
    
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate updateBadgeWithUnreadMessages:unreadCount];
}

#pragma mark - UITableViewDataSource methods and related helpers
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Show or hide 'no messages' view
    if (
        ([_messages count] == 0)
        &&
        _messagesHaveBeenFetched
        ) {
        _noMessagesView.hidden = NO;
    } else if (!_noMessagesView.hidden) {
        _noMessagesView.hidden = YES;
    }
    
    return [_messages count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MessageCell";
    InboxCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary* messageThread = [_messages objectAtIndex:indexPath.row];
    
    //--------------------------------------------
    // Display other person/people in conversation
    //--------------------------------------------
    // (Only load previously-stored names - defer new downloads until scrolling ends)
    NSString* originatorId = [messageThread objectForKey:@"originatorId"];
    if (![[PFUser currentUser].objectId isEqualToString:originatorId]) {
        //------------------------------------------------------
        // The current user is not the originator of the message
        //------------------------------------------------------
        NSString* fullName = [appDelegate getFullNameForUsername:originatorId];
        if (!fullName) {
            if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
            {
                // Fetch the user's name in the background
                [self startFullNameDownload:originatorId forIndexPath:indexPath];
            } else {
                [cell displayPlaceholderName];
            }
        } else {
            [cell displayFullName:fullName];
        }
    } else {
        //--------------------------------------------------
        // The current user is the originator of the message
        //--------------------------------------------------
        // Query the users involved in the message thread whose names we haven't already stored, and store their names
        NSMutableString* senderLabelText = [NSMutableString stringWithFormat:@""];
        NSMutableArray* unknownUserIDs = [self getUnknownUserIDsFromUnreadMarkers:[messageThread objectForKey:@"UnreadMarkers"] senderLabelText:senderLabelText];
        
        if ([unknownUserIDs count] > 0) {
            
            if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
            {
                [self startMultipleFullNamesDownload:unknownUserIDs forIndexPath:indexPath];
            } else {
                [cell displayPlaceholderName];
            }
        } else {
            [cell displayFullName:senderLabelText];
        }
    }
    
    //------------------------------------------------------------------------------------------------
    // Display the latest message in the conversation (or sending status if sending or sending failed)
    //------------------------------------------------------------------------------------------------
    NSDictionary* latestMessage = [self getLatestMessageFromMessageThread:messageThread];
    
    [cell setSendingStatus:[MFRLocalMessageThread getSendingStatusFromMessage:latestMessage]];
    
    if (
        ([MFRLocalMessageThread getSendingStatusFromMessage:latestMessage] != MFRLocalMessageStatusSending)
        &&
        ([MFRLocalMessageThread getSendingStatusFromMessage:latestMessage] != MFRLocalMessageStatusSendingFailed)
        ) {
        
        NSString* messageLabelText;
        UIColor* messageTextColor;
        
        if ([[latestMessage objectForKey:@"Message"] length] > 0) {
            // Display latest message text
            messageLabelText = [latestMessage objectForKey:@"Message"];
            messageTextColor = [UIColor lightGrayColor];
        } else {
            // Display URL
            messageLabelText = [messageThread objectForKey:@"linkString"];
            messageTextColor = [UIColor lightGrayColor];
        }
        
        [cell.messageLabel setText:messageLabelText];
        [cell.messageLabel setTextColor:messageTextColor];
    }
    
    //----------------------
    // Display the date/time
    //----------------------
    NSString* dateString = @"";
    if ([latestMessage objectForKey:@"Date"]) {
        
        NSDate* localDateTime = [MFRDateTime getLocalDateTimeFromGMTDateString:[latestMessage objectForKey:@"Date"]];
        
//        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
//        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//        NSDate *date = [formatter dateFromString:[latestMessage objectForKey:@"Date"]];
        
        // Check for same day
        NSDateFormatter *dayFormatter = [[NSDateFormatter alloc]init];
        dayFormatter.dateFormat = @"yyyy-MM-dd";
        
        // Today
        NSDate *todayDate = [NSDate date];
        NSString* todayString = [dayFormatter stringFromDate:todayDate];
        
        NSString *dayString = [dayFormatter stringFromDate:localDateTime];
        
        if ([dayString isEqualToString:todayString]) {
            // Message was sent today
            NSDateFormatter *timeFormatter = [[NSDateFormatter alloc]init];
            [timeFormatter setDateFormat:@"HH:mm"];
            dateString = [timeFormatter stringFromDate:localDateTime];
        }
        else {
            // Message was not sent today
            NSDateFormatter *historicalDayFormatter = [[NSDateFormatter alloc]init];
            [historicalDayFormatter setDateFormat:@"dd LLL"];
            dateString = [historicalDayFormatter stringFromDate:localDateTime];
        }
    }
    [cell.dateLabel setText:dateString];
    
    //--------------------
    // Display read/unread
    //--------------------
    [cell markAsUnread:[MFRLocalMessageThread messageThreadIsUnread:messageThread]];
    
    //-------------------
    // Display cell image
    //-------------------
    // (Only load previously-stored images - defer new downloads until scrolling ends)
    if (
        [messageThread objectForKey:@"imageURL"]
        &&
        ![[messageThread objectForKey:@"imageURL"] isEqualToString:@""]
        ) {
        UIImage* image = [appDelegate getImage:[messageThread objectForKey:@"imageURL"]];
        if (!image)
        {
            if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
                [self startImageDownload:[messageThread objectForKey:@"imageURL"] forIndexPath:indexPath];
            } else {
                [cell displayLinkImage:[UIImage imageNamed:@"InboxCellPlaceholder"]];
            }
        }
        else
        {
            [cell displayLinkImage:image];
        }
    } else {
        [cell removeLinkImageAndMoveText];
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [self performSelectorInBackground:@selector(deleteMessage:) withObject:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSNumber* entry = [NSNumber numberWithInteger:indexPath.row];
    
    NSDictionary *dimensions = @{ @"Message number": [NSString stringWithFormat:@"%ld", indexPath.row] };
    [MFRAnalytics trackEvent:@"Selected message in inbox" dimensions:dimensions];
    
    NSMutableDictionary* messageThread = [_messages objectAtIndex:indexPath.row];
    NSMutableDictionary* unreadMarkers = [messageThread objectForKey:@"UnreadMarkers"];
    if ([[unreadMarkers objectForKey:[PFUser currentUser].objectId] boolValue] == YES) {
        // Message is unread, so mark as read
        NSDictionary* readDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"read", entry, @"messageArrayEntry", nil];
        
//        [self performSelectorInBackground:@selector(updateMessageAsRead:) withObject:readDict];
        [self updateMessageAsRead:readDict];
        
        // Set inbox to reload when we return to it
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate setInboxToReload:YES];
    }
    
    //----------------------------------------------
    // Push message view for selected message thread
    //----------------------------------------------
    [self performSegueWithIdentifier:@"DisplayMessage" sender:self];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Inbox table cell image support
- (void)startImageDownload:(NSString*)imageURL forIndexPath:(NSIndexPath *)indexPath
{
    ImageDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        //------------------------------------------------
        // Download message thread image in the background
        //------------------------------------------------
        iconDownloader = [[ImageDownloader alloc] init];
        iconDownloader.imageURL = imageURL;
        [iconDownloader setCompletionHandler:^{
            
            InboxCell *cell = (InboxCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            
            // Display the newly fetched image
            AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            UIImage* image = [appDelegate getImage:imageURL];
            if (image) {
                [cell displayLinkImage:image];
            }
            
            // Remove the ImageDownloader from the in progress list
            [self.imageDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        [self.imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
    }
}

#pragma mark - Table cell full name support
- (void)startFullNameDownload:(NSString*)username forIndexPath:(NSIndexPath *)indexPath
{
    FullNameDownloader *fullNameDownloader = [self.fullNameDownloadsInProgress objectForKey:indexPath];
    if (fullNameDownloader == nil)
    {
        //--------------------------------------------
        // Download user's full name in the background
        //--------------------------------------------
        fullNameDownloader = [[FullNameDownloader alloc] init];
        fullNameDownloader.username = username;
        [fullNameDownloader setCompletionHandler:^{
            
            InboxCell *cell = (InboxCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            
            // Display the newly fetched full name
            AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSString* fullName = [appDelegate getFullNameForUsername:username];
            if (fullName) {
                [cell displayFullName:fullName];
            }
            
            // Remove the FullNameDownloader from the in progress list
            [self.fullNameDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        [self.fullNameDownloadsInProgress setObject:fullNameDownloader forKey:indexPath];
        [fullNameDownloader startDownload];
    }
}

- (void)startMultipleFullNamesDownload:(NSMutableArray*)usernames forIndexPath:(NSIndexPath *)indexPath
{
    MultipleFullNamesDownloader *multipleFullNamesDownloader = [self.fullNameDownloadsInProgress objectForKey:indexPath];
    if (multipleFullNamesDownloader == nil)
    {
        //---------------------------------------------
        // Download users' full names in the background
        //---------------------------------------------
        multipleFullNamesDownloader = [[MultipleFullNamesDownloader alloc] init];
        multipleFullNamesDownloader.usernames = usernames;
        [multipleFullNamesDownloader setCompletionHandler:^{
            
            InboxCell *cell = (InboxCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            
            AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableString* senderLabelText = [NSMutableString stringWithFormat:@""];
            
            for (NSString* userID in usernames) {
                NSString* userName = [appDelegate getFullNameForUsername:userID];
                senderLabelText = [self addName:userName toSenderLabelText:senderLabelText];
            }
            
            // Display the newly fetched list of full names
            [cell displayFullName:senderLabelText];
            
            // Remove the FullNameDownloader from the in progress list
            [self.fullNameDownloadsInProgress removeObjectForKey:indexPath];
        }];
        [self.fullNameDownloadsInProgress setObject:multipleFullNamesDownloader forKey:indexPath];
        [multipleFullNamesDownloader startDownload];
    }
}

//-------------------------------------------------------------------------------------------
// Used if the user scrolls into a set of cells that don't have their images/sender names yet
//-------------------------------------------------------------------------------------------
- (void)loadImagesAndNamesForOnscreenRows
{
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([_messages count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            NSDictionary* messageThread = [_messages objectAtIndex:indexPath.row];
            
            if (
                [messageThread objectForKey:@"imageURL"]
                &&
                ![[messageThread objectForKey:@"imageURL"] isEqualToString:@""]
                &&
                ![appDelegate getImage:[messageThread objectForKey:@"imageURL"]]
                ) {
                
                //-------------------------
                // Load image in background
                //-------------------------
                [self startImageDownload:[messageThread objectForKey:@"imageURL"] forIndexPath:indexPath];
            }
            
            NSString* originatorId = [messageThread objectForKey:@"originatorId"];
            if (![[PFUser currentUser].objectId isEqualToString:originatorId]) {
                //------------------------------------------------------
                // The current user is not the originator of the message
                //------------------------------------------------------
                NSString* fullName = [appDelegate getFullNameForUsername:originatorId];
                if (!fullName) {
                    // Fetch the sender's name in the background
                    [self startFullNameDownload:originatorId forIndexPath:indexPath];
                }
            } else {
                //--------------------------------------------------
                // The current user is the originator of the message
                //--------------------------------------------------
                // Query the users involved in the message thread whose names we haven't already stored, and store their names
                NSMutableString* senderLabelText = [NSMutableString stringWithFormat:@""];
                NSMutableArray* unknownUserIDs = [self getUnknownUserIDsFromUnreadMarkers:[messageThread objectForKey:@"UnreadMarkers"] senderLabelText:senderLabelText];
                
                if ([unknownUserIDs count] > 0) {
                    [self startMultipleFullNamesDownload:unknownUserIDs forIndexPath:indexPath];
                }
            }
        }
    }
}

//-----------------------------------------------------------------------------------
// Establish which users in a message thread we have not yet stored the full name for
//-----------------------------------------------------------------------------------
-(NSMutableArray*)getUnknownUserIDsFromUnreadMarkers:(NSDictionary*)unreadMarkers senderLabelText:(NSMutableString*)senderLabelText {
    
    NSMutableArray* userIDs = [[unreadMarkers allKeys] mutableCopy];
    
    // Remove current user
    for (int i = 0; i < [userIDs count]; i++) {
        if ([[userIDs objectAtIndex:i] isEqualToString:[PFUser currentUser].objectId]) {
            [userIDs removeObjectAtIndex:i];
            break;
        }
    }
    
    // Separate into users whose names we've already stored and users whose names we haven't yet stored
    NSMutableArray* unknownUserIDs = [NSMutableArray array];
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    for (NSString* userID in userIDs) {
        if (![appDelegate getFullNameForUsername:userID]) {
            [unknownUserIDs addObject:userID];
        } else {
            senderLabelText = [self addName:[appDelegate getFullNameForUsername:userID] toSenderLabelText:senderLabelText];
        }
    }
    
    return unknownUserIDs;
}

#pragma mark - UIScrollViewDelegate
//----------------------------------------------------------------------------
// Load images and full names for all onscreen rows when scrolling is finished
//----------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
	{
        [self loadImagesAndNamesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesAndNamesForOnscreenRows];
}

#pragma mark - Building sender name string
-(NSMutableString*)addName:(NSString*)name toSenderLabelText:(NSMutableString*)senderLabelText {
    
    if ([senderLabelText length] > 0) {
        [senderLabelText appendString:@", "];
    }
    if (name) {
        [senderLabelText appendString:name];
    }
    return senderLabelText;
}

#pragma mark - Accessing and updating message thread
-(NSDictionary*)getLatestMessageFromMessageThread:(NSDictionary*)messageThread {
    NSMutableArray* messages = [[messageThread objectForKey:@"Messages"] mutableCopy];
    if ([messages count] > 0) {
        NSDictionary* latestMessage = [messages lastObject];
        return latestMessage;
    }
    return nil;
}

-(void)updateMessageAsRead:(NSDictionary*)readDict {
    BOOL read = [[readDict objectForKey:@"read"] boolValue];
    int messageArrayEntry = [[readDict objectForKey:@"messageArrayEntry"] intValue];
    
    // Mark unread as false locally
    NSMutableDictionary* messageThread = [[_messages objectAtIndex:messageArrayEntry] mutableCopy];
    NSMutableDictionary* unreadMarkers = [[messageThread objectForKey:@"UnreadMarkers"] mutableCopy];
    [unreadMarkers setObject:[NSNumber numberWithBool:!read] forKey:[PFUser currentUser].objectId];
    [messageThread setObject:unreadMarkers forKey:@"UnreadMarkers"];
    
    [_messages replaceObjectAtIndex:messageArrayEntry withObject:messageThread];
    [MFRLocalMessageThread updateMessageThread:messageThread shouldUpdateTime:NO];
    
    [self updateBadge];
    
    NSDictionary* unreadMarkersDict = [NSDictionary dictionaryWithObjectsAndKeys:[messageThread objectForKey:@"objectId"], @"objectId", unreadMarkers, @"unreadMarkers", nil];
    [self performSelectorInBackground:@selector(updateCloudMessageThreadWithUnreadMarkersDict:) withObject:unreadMarkersDict];
    
//    [MFRParseMessageThread updateMessageThreadWithID:[messageThread objectForKey:@"objectId"] withNewUnreadMarkers:unreadMarkers];
}

-(void)updateCloudMessageThreadWithUnreadMarkersDict:(NSDictionary*)unreadMarkersDict {
    [MFRParseMessageThread updateMessageThreadWithID:[unreadMarkersDict objectForKey:@"objectId"] withNewUnreadMarkers:[unreadMarkersDict objectForKey:@"unreadMarkers"]];
}

#pragma mark - Deleting message from inbox
-(void)deleteMessage:(NSIndexPath*)indexPath
{
//    NSInteger entryInt = indexPath.row;
//    
//    // Delete link from Parse User
//    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    PFObject* userLinks = [appDelegate getUserLinks];
//    
//    // Get latest version of userLinks from the cloud
//    [userLinks fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//        
//        // Get latest _messages from cloud object
//        _messages = [[userLinks objectForKey:@"ReceivedLinks"] mutableCopy];
//        if (!_messages){
//            _messages = [NSMutableArray array];
//        }
    
        NSLog(@"MUST UPDATE DELETING FOR NEW LOCAL MESSAGE MODEL");
        
//        // Delete first link from local array
//        [_messages removeObjectAtIndex:entryInt];
//        
//        // Save updated array of links to the cloud
//        [userLinks setObject:_messages forKey:@"ReceivedLinks"];
//        [userLinks saveInBackground];
//        
//        // Delete tableview cell
//        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
//    }];
}

#pragma mark - Replacing group message thread with updated one-to-one message thread
/*
-(void)replaceMessageThread:(int)inboxEntry withMessageThread:(NSMutableDictionary*)messageThread {
    [_messages replaceObjectAtIndex:inboxEntry withObject:messageThread];
}
*/

#pragma mark - Adding new message thread after sending original link/forwarding
/*
-(void)addNewMessageThread:(NSMutableDictionary*)messageThread {
    [_messages insertObject:messageThread atIndex:0];
    _newlyComposedMessageAdded = YES;
}
*/

#pragma mark - Segue and changing views
- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"DisplayMessage"]){
        
        //-------------------------------------------------------
        // Remove swipe gesture since we're leaving the main view
        //-------------------------------------------------------
        [parentDelegate removeSwipeGesture];
        
        ViewController* controller = segue.destinationViewController;
        
        NSInteger messagesArrayEntry = [self.tableView indexPathForSelectedRow].row;
        NSMutableDictionary* messageThread = [[_messages objectAtIndex:messagesArrayEntry] mutableCopy];
        controller.messageThread = messageThread;
        
        InboxCell *cell = (InboxCell*)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
        controller.title = cell.senderLabel.text;
        
        controller->deleteMessageDelegate = self;
        controller->inboxEntry = messagesArrayEntry;
    }
    else if ([[segue identifier] isEqualToString:@"DisplaySettings"]){
        
        //-------------------------------------------------------
        // Remove swipe gesture since we're leaving the main view
        //-------------------------------------------------------
        [parentDelegate removeSwipeGesture];
        
        [MFRAnalytics trackEvent:@"Settings screen displayed"];
    }
}

-(IBAction)pushComposeViewController
{
    [parentDelegate navigateRightToCompose];
}

-(IBAction)pushSettingsViewController
{
    [self performSegueWithIdentifier:@"DisplaySettings" sender:self];
}

-(void)scrollToTopOfInbox {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
}

#pragma mark - Clearing data when logging out
-(void)removeAllMessagesInApp {
    [_messages removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark - Suggestion alerts
-(void)presentAddContactsAlert {
    
    UIAlertView *addContactsAlert = [[UIAlertView alloc] initWithTitle:@"Add your friends" message:@"Ripple is better with friends. Do you want to add them?" delegate:self cancelButtonTitle:@"Not now" otherButtonTitles:@"Add friends", nil];
    [addContactsAlert show];
}

#pragma mark - Alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        //-------------------------------------------------------
        // Remove swipe gesture since we're leaving the main view
        //-------------------------------------------------------
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
        
        NSArray *viewControllers = @[phoneBookContactsVC, friendRequestsViewController, addContactsViewController];
        MHTabBarController *tabBarController = [self.storyboard instantiateViewControllerWithIdentifier:@"addContactsTabBarController"];
        
//        tabBarController.delegate = self;
        tabBarController.viewControllers = viewControllers;
        
//        addContactsViewController.updateContactsVCDelegate = self;
        
        friendRequestsViewController->updateFriendRequestTitleDelegate = tabBarController;
//        friendRequestsViewController.updateContactsVCDelegate = self;
        
        UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
//        [navController pushViewController:tabBarController animated:NO];
        
        // Exit button
//        UIBarButtonItem *exitButton = [[UIBarButtonItem alloc]
//                                       initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(exitContactsButtonPressed)];
//        navController.navigationItem.leftBarButtonItem = exitButton;
        tabBarController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(exitContactsButtonPressed)];
    
        [self presentViewController:navController animated:YES completion:nil];
    }
}

-(void)exitContactsButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
    [parentDelegate addSwipeGesture];
}

#pragma mark - Inviting friends
-(void)considerPromptingFriendInvite {
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSNumber* tally = [appDelegate getFriendInvitePromptTally];
    if (tally) {
        // Invite prompt tally already exists
        int tallyInt = [tally intValue];
        
        // Display friend invite prompt if necessary
        if (
            (tallyInt <= 15)
            &&
            (
             (tallyInt == 1)
             ||
             (
              ((tallyInt % 5) == 0)
              &&
              (tallyInt != 0)
              )
             )
            ) {
            [self presentAddContactsAlert];
        }
        
        // Update tally
        tallyInt++;
        NSNumber* updatedTally = [NSNumber numberWithInt:tallyInt];
        [appDelegate setFriendInvitePromptTally:updatedTally];
    } else {
        // Invite prompt tally does not yet exist
        
//        if ([appDelegate newUser]) {
//            // New user
//            [appDelegate setNewUser:NO];
//        }
//        else {
//            // Pre-existing user using this version of the app for the first time
//            [self presentAddContactsAlert];
//        }
        
        NSNumber* newTally = 0;
        [appDelegate setFriendInvitePromptTally:newTally];
    }
}

@end
