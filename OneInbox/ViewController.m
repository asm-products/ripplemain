//
//  ViewController.m
//  OneInbox
//
//  Created by Ed Rex on 02/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "ViewController.h"
#import "ComposeViewController.h"
#import "AppDelegate.h"
#import "LinkObject.h"
#import "ComposeViewController.h"
#import <Parse/Parse.h>
#import "MFRAnalytics.h"
#import "MFRParseMessageThread.h"
#import "MFRLocalMessageThread.h"
#import "MFRMessageBubbleView.h"
#import "TweetViewController.h"
#import "TwitterViewController.h"
#import "MFRDateTime.h"

#define MESSAGES_STARTING_Y_COORDINATE 220
#define SPACE_BETWEEN_MESSAGES 15
#define MESSAGE_BUBBLE_HEIGHT 40
#define UNSENT_INDICATOR_GAP 15.0
#define RETRY_BUTTON_LENGTH 20.0
#define SENDING_PROGRESS_TIME 2.0
#define SENDING_PROGRESS_TOTAL_DISPLAYED_TIME 3.0
#define SENDING_FAILED_BUTTON_HEIGHT 40.0
#define SENDING_FAILED_LABEL_Y_POSITION 250

@interface ViewController ()<ReplyDelegate, HPGrowingTextViewDelegate> {
    
    BOOL _unreadStatusChanged;
    NSTimeInterval _animationDuration;
    UIViewAnimationCurve _animationCurve;
    CGFloat _keyboardTop;
    CGFloat _combinedMessageViewHeight;
    CGFloat _maxScrollViewHeight;
    BOOL _replyButtonEnabled;
    CGFloat _keyboardOverlap;
    BOOL _originalMessagesDisplayed;
    float _timerCount;
    NSInteger _retryButtonPressedForMessageNumber;
    BOOL _mustRedisplayAllMessages;
}

@property (nonatomic, retain) NSMutableArray* messages;
@property (nonatomic, retain) NSMutableDictionary* bubbleViews;
@property (nonatomic, retain) NSMutableDictionary* messageViews;
@property (nonatomic, retain) NSMutableDictionary* retryButtons;
@property (nonatomic, retain) NSMutableDictionary* oldMessageThreads;

@property (nonatomic, retain) UILabel* sendingFailedLabel;
@property (nonatomic, retain) UIButton* sendingFailedRetryButton;
@property (nonatomic, retain) UIButton* sendingFailedDeleteButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _unreadStatusChanged = NO;
    _keyboardOverlap = 0;
    _originalMessagesDisplayed = NO;
    _mustRedisplayAllMessages = NO;
    
    _messages = [NSMutableArray array];
    _bubbleViews = [NSMutableDictionary dictionary];
    _messageViews = [NSMutableDictionary dictionary];
    _retryButtons = [NSMutableDictionary dictionary];
    _oldMessageThreads = [NSMutableDictionary dictionary];
    
    // Add a small amount of blank space at the top of the scroll view
    _combinedMessageViewHeight = MESSAGES_STARTING_Y_COORDINATE + SPACE_BETWEEN_MESSAGES;
    
    // Add reply toolbar
    _replyView = [[MFRMessageEntryView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44) title:@"Send"];
    [_replyView.sendButton addTarget:self action:@selector(replyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _replyView.messageView.delegate = self;
    [self.view addSubview:_replyView];
    
    // Show forward button
    [self addNavigationButtons];
    
    _messageView.editable = YES;
    [_messageView setFont:[UIFont fontWithName:@"Titillium-Regular" size:14.0]];
    _messageView.editable = NO;
    _messageView.text = _messageText;
    
    [self hideLinkElements];
    [self enableActionButtons:NO];
    [self showLoadingWheel:YES];
    
    [self performSelectorInBackground:@selector(displayMessageThread) withObject:nil];
    
    _originalLink = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    // Fallback keyboard animation curve
    _animationDuration = 0.25;
    _animationCurve = 7;
    
    _maxScrollViewHeight = self.view.frame.size.height;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, _maxScrollViewHeight)];
    UIEdgeInsets insets = { .left = 0, .right = 0, .top = 0, .bottom = self.replyView.frame.size.height };
    _scrollView.contentInset = insets;
    
    // Add tap gesture to scroll view
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOutsideTextField:)];
    [self.scrollView addGestureRecognizer:singleTap];
    
    [self.movingView addSubview:_scrollView];
    
    _replyView.sendButton.enabled = NO;
    
    //------------------------------
    // Add progress view and hide it
    //------------------------------
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height - 2, self.view.frame.size.width, 2);
    [self.navigationController.navigationBar addSubview:self.progressView];
    self.progressView.progress = 0;
    self.progressView.hidden = YES;
    
    _sendingFailedLabel = [[UILabel alloc] initWithFrame:CGRectMake(
                                                                    120,
                                                                    SENDING_FAILED_LABEL_Y_POSITION,
                                                                    120,
                                                                    SENDING_FAILED_BUTTON_HEIGHT
                                                                    )];
    [_sendingFailedLabel setText:@"Sending failed"];
    [_sendingFailedLabel setTextAlignment:NSTextAlignmentCenter];
    [_sendingFailedLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:16.0]];
    [_sendingFailedLabel setTextColor:[UIColor grayColor]];
    _sendingFailedLabel.center = CGPointMake(self.movingView.center.x, SENDING_FAILED_LABEL_Y_POSITION);
    
    _sendingFailedRetryButton = [[UIButton alloc] initWithFrame:CGRectMake(
                                                                           80,
                                                                           SENDING_FAILED_LABEL_Y_POSITION + (SENDING_FAILED_BUTTON_HEIGHT / 2) + 10,
                                                                           80,
                                                                           SENDING_FAILED_BUTTON_HEIGHT
                                                                           )];
    [_sendingFailedRetryButton setTitle:@"Retry" forState:UIControlStateNormal];
    [_sendingFailedRetryButton setTitleColor:[UIColor colorWithRed:52/255.0 green:152/255.0 blue:219/255.0 alpha:1.0] forState:UIControlStateNormal];
    [_sendingFailedRetryButton.titleLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:17.0]];
    [_sendingFailedRetryButton addTarget:self action:@selector(retrySendOfLinkWithNoMessage:) forControlEvents:UIControlEventTouchUpInside];
    
    _sendingFailedDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(
                                                                            160,
                                                                            SENDING_FAILED_LABEL_Y_POSITION + (SENDING_FAILED_BUTTON_HEIGHT / 2) + 10,
                                                                            80,
                                                                            SENDING_FAILED_BUTTON_HEIGHT
                                                                            )];
    [_sendingFailedDeleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [_sendingFailedDeleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_sendingFailedDeleteButton.titleLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:17.0]];
    [_sendingFailedDeleteButton addTarget:self action:@selector(deleteMessageThreadLocallyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

// COPIED FROM CONTACTS VIEW CONTROLLER:
-(void)changeSendingStatus:(NSNumber*)sendingStatus {
    if ([sendingStatus integerValue] == 0) {
        //        [_sendingStatusView removeFromSuperview];
    } else if ([sendingStatus integerValue] == 1) {
        
        // Sending
        
        // Progress bar
        self.progressView.progress = 0.0;
        self.progressView.hidden = NO;
        
        // Reply timer
        _timerCount = 0;
        self.replyTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgressView:) userInfo:nil repeats:YES];
        
    } else if ([sendingStatus integerValue] == 2) {
        // Sent
        
        // Progress bar
        self.progressView.progress = 1.0;
        
        // Reply timer
        [self.replyTimer invalidate];
        self.replyTimer = nil;
        
    } else if ([sendingStatus integerValue] == 3) {
        // Progress bar
        self.progressView.hidden = YES;
        
    } else if ([sendingStatus integerValue] == 4) {
        // Progress bar
        self.progressView.hidden = YES;
    }
}

//--------------------------------
// Update the sending progress bar
//--------------------------------
- (void)updateProgressView:(NSTimer *)timer
{
    _timerCount+=0.1;
    
    if (_timerCount <= SENDING_PROGRESS_TIME)
    {
        self.progressView.progress = (float)_timerCount / SENDING_PROGRESS_TOTAL_DISPLAYED_TIME;
    } else
    {
        [self.replyTimer invalidate];
        self.replyTimer = nil;
    } 
}

-(void)replyButtonPressed {
    
    [MFRAnalytics trackEvent:@"Reply button pressed"];
    
//    [_replyView.messageView.internalTextView reloadInputViews];
    //----------------------------------------------------
    // Hack that accepts whatever autocorrect is suggested
    //----------------------------------------------------
    [_replyView.messageView.internalTextView resignFirstResponder];
    [_replyView.messageView.internalTextView becomeFirstResponder];
    
    //---------------------------------
    // Add reply to local messageThread
    //---------------------------------
    _messageThread = [MFRLocalMessageThread addReplyToLocalMessageThread:_messageThread withMessage:_replyView.messageView.text];
    
    //--------------------
    // Show latest message
    //--------------------
    [self performSelectorOnMainThread:@selector(displayNewMessages) withObject:nil waitUntilDone:NO];
    
    //---------------------------------------
    // Alter inbox for updated message thread
    //---------------------------------------
    [deleteMessageDelegate updateMessageOrder];
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setInboxToReload:YES];
    
    //--------------------------------
    // Send the reply to the recipient
    //--------------------------------
    [self performSelectorInBackground:@selector(replyToMessage:) withObject:_replyView.messageView.text];
    
    //-----------------------------------------------------
    // Dismiss reply text field and delete text it contains
    //-----------------------------------------------------
    _replyView.messageView.text = @"";
    _replyView.sendButton.enabled = NO;
    [_replyView.messageView resignFirstResponder];
    [self changeSendingStatus:[NSNumber numberWithInteger:1]];
}

//---------------------------------------------
// Send updated message thread to the recipient
//---------------------------------------------
-(void)replyToMessage:(NSString*)messageBody {
    
    [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSending forLatestMessageInMessageThreadWithId:[_messageThread objectForKey:@"objectId"]];
    
    //-------------------------------------------------------------------------------
    // Get cloud messageThread objects that correspond to local messageThread objects
    //-------------------------------------------------------------------------------
    PFObject* parseMessageThread;
    if ([_messageThread objectForKey:@"originalMessageThreadID"]) {
        parseMessageThread = [MFRParseMessageThread getParseMessageThreadWithID:[_messageThread objectForKey:@"originalMessageThreadID"]];
    } else {
        parseMessageThread = [MFRParseMessageThread getParseMessageThreadWithID:[_messageThread objectForKey:@"objectId"]];
    }
    
    if (parseMessageThread) {
        //-----------------------
        // Reply to messageThread
        //-----------------------
        [MFRParseMessageThread replyToMessageThread:parseMessageThread withMessage:messageBody delegate:self localMessageThreadId:[_messageThread objectForKey:@"objectId"]];
    } else {
        //------------------------------------
        // Display that message sending failed
        //------------------------------------
        [MFRLocalMessageThread setSendingStatus:MFRLocalMessageStatusSendingFailed forLatestMessageInMessageThreadWithId:[_messageThread objectForKey:@"objectId"]];
        
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate notifyViewControllersOfReplySuccess:NO forMessageThreadID:[_messageThread objectForKey:@"objectId"]];
//        [self notifyReplySuccess:NO];
    }
}

#pragma mark - On reply success/failure
-(void)notifyReplySuccess:(BOOL)success updatedMessageID:(NSString*)updatedMessageID {
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:success], @"Success", updatedMessageID, @"UpdatedMessageID", nil];
    [self performSelectorOnMainThread:@selector(returnFromReplyWithSuccess:) withObject:dict waitUntilDone:NO];
}

-(void)returnFromReplyWithSuccess:(NSDictionary*)dict {
    
    BOOL success = [[dict objectForKey:@"Success"] boolValue];
    NSString* updatedMessageID = [dict objectForKey:@"UpdatedMessageID"];
    
    if (success) {
        
        [self changeSendingStatus:[NSNumber numberWithInteger:2]];
        [self performSelector:@selector(changeSendingStatus:) withObject:[NSNumber numberWithInteger:3] afterDelay:1.5];
        
        // Get latest version of MessageThread from User Defaults
        _messageThread = [[MFRLocalMessageThread getMessageThreadWithId:updatedMessageID] mutableCopy];
        
        // Remove oldMessageThreadID from local messageThread
        [_messageThread removeObjectForKey:@"originalMessageThreadID"];
        
        [MFRLocalMessageThread updateMessageThread:_messageThread shouldUpdateTime:NO];
        
        if (_mustRedisplayAllMessages) {
            //----------------------------------------------------------------------------------------------------------------
            // We were resending a message that wasn't the last message in the messageThread, so reload the message views etc.
            //----------------------------------------------------------------------------------------------------------------
            [self removeMessagesFromView];
            _mustRedisplayAllMessages = NO;
        }
        
        //---------------------------------------
        // Remove retryButton if this was a retry
        //---------------------------------------
        [self displayNewMessages];
        
    } else {
        [self changeSendingStatus:[NSNumber numberWithInteger:3]];
        //---------------------------------------------
        // Mark the failed message with an unsent label
        //---------------------------------------------
        [self displayNewMessages];
    }
}

/*
-(void)replaceMessageThreadWithMessageThread:(NSMutableDictionary*)messageThread {
    _messageThread = messageThread;
    ...UPDATE NSUSERDEFAULTS?...
    [deleteMessageDelegate replaceMessageThread:inboxEntry withMessageThread:messageThread];
}
*/

-(void)viewWillDisappear:(BOOL)animated {
    if (
        ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound)
        &&
        _unreadStatusChanged
        &&
        [MFRLocalMessageThread messageThreadIsUnread:_messageThread]
        ) {
        // Back button was pressed - update unread status of message in inbox and cloud
        NSDictionary* readDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"read", [NSNumber numberWithInteger:inboxEntry], @"messageArrayEntry", nil];
        [deleteMessageDelegate updateMessageAsRead:readDict];
        
        // Set inbox to reload when we return to it
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate setInboxToReload:YES];
    }
    
    // Remove progress bar and reply timer
    [self.progressView removeFromSuperview];
    [self.replyTimer invalidate];
    self.replyTimer = nil;
    
    [super viewWillDisappear:animated];
}

#pragma mark - Sliding the view when editing
-(void)keyboardWillShow:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    
    // Get keyboard animation
    NSNumber *durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey];
    _animationDuration = durationValue.doubleValue;
    
    NSNumber *curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey];
    _animationCurve = curveValue.intValue;
    
    CGRect keyboardRect = [[aNotification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardTop = keyboardRect.size.height;
    
    [self moveReplyView];
}

-(IBAction)clickOutsideTextField:(id)sender {
    [_replyView.messageView resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Unread button
-(void)addNavigationButtons {
    
    // Add unread button
    UIButton *unreadBt=[UIButton buttonWithType:UIButtonTypeCustom];
    [unreadBt setFrame:CGRectMake(0, 0, 22, 22)];
    [unreadBt setImage:[UIImage imageNamed:@"Flag-LightGray"] forState:UIControlStateNormal];
    [unreadBt addTarget:self action:@selector(switchUnread:) forControlEvents:UIControlEventTouchUpInside];
    unreadBt.showsTouchWhenHighlighted = YES;
    _markAsUnreadButton = [[UIBarButtonItem alloc] initWithCustomView:unreadBt];
    
    _forwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed)];
    
    _fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    _fixedSpace.width = 12;
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_forwardButton, _fixedSpace, _markAsUnreadButton, nil];
}

-(void)shareButtonPressed {
    
    [MFRAnalytics trackEvent:@"Share button pressed in Message view"];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Share"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Forward link",@"Copy link",@"Tweet link",
                                  nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.tag = 0;
    [actionSheet showInView:[self.view window]];
}

-(IBAction)switchUnread:(id)sender {
    
    if (!_unreadStatusChanged) {
        _unreadStatusChanged = YES;
    }
    
    bool updatedUnreadStatus;
    if (![MFRLocalMessageThread messageThreadIsUnread:_messageThread]) {
        // Mark as unread
        updatedUnreadStatus = YES;
    } else {
        // Mark as read
        updatedUnreadStatus = NO;
    }
    
    // Update unread markers in messageThread
    NSMutableDictionary* unreadMarkers = [[_messageThread objectForKey:@"UnreadMarkers"] mutableCopy];
    [unreadMarkers setObject:[NSNumber numberWithBool:updatedUnreadStatus] forKey:[PFUser currentUser].objectId];
    [_messageThread setObject:unreadMarkers forKey:@"UnreadMarkers"];
    [MFRLocalMessageThread updateMessageThread:_messageThread shouldUpdateTime:NO];
    
    // Update image
    UIButton* bt = [UIButton buttonWithType:UIButtonTypeCustom];
    [bt setFrame:CGRectMake(0, 0, 22, 22)];
    if (updatedUnreadStatus) {
        // Display as unread
        [bt setImage:[UIImage imageNamed:@"Flag-Purple"] forState:UIControlStateNormal];
        [MFRAnalytics trackEvent:@"Message marked as unread in Message VC"];
        
    } else {
        // Display as read
        [bt setImage:[UIImage imageNamed:@"Flag-LightGray"] forState:UIControlStateNormal];
    }
    [bt addTarget:self action:@selector(switchUnread:) forControlEvents:UIControlEventTouchUpInside];
    bt.showsTouchWhenHighlighted = YES;
    _markAsUnreadButton = [[UIBarButtonItem alloc] initWithCustomView:bt];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_forwardButton, _fixedSpace, _markAsUnreadButton, nil];
    
}

-(void)displayMessageThread {
    
    NSString* linkString = [_messageThread objectForKey:@"linkString"];
    if ([_messageThread objectForKey:@"titleString"]) {
        // Message thread has all necessary info
        _url = [NSURL URLWithString:[_messageThread objectForKey:@"linkString"]];
        _linkTitle = [_messageThread objectForKey:@"titleString"];
    } else {
        // Message thread is missing title info, so get html and get title info from there
        [self getLinkDataFromURLString:linkString];
    }
    
    [self saveLinkObject];
    
    [self performSelectorOnMainThread:@selector(displayCompleteLinkAndMessages) withObject:nil waitUntilDone:NO];
}

-(void)displayCompleteLinkAndMessages {
    [self showLinkElements];
    [self displayNewMessages];
    [self enableActionButtons:YES];
    [self showLoadingWheel:NO];
    
    if (
        [_messageThread objectForKey:@"imageURL"]
        &&
        ![[_messageThread objectForKey:@"imageURL"] isEqualToString:@""]
        ) {
        [self.linkObjectView setLoading:YES];
        [self performSelectorInBackground:@selector(displayImageFromURL:) withObject:[NSURL URLWithString:[_messageThread objectForKey:@"imageURL"]]];
    } else {
        self.linkObjectView.linkImageView.hidden = YES;
        [self.linkObjectView showSmallTitle:NO];
    }
}

-(void)showLinkElements
{
    // Add link summary view
    self.linkObjectView = [[LinkObjectView alloc] initWithFrame:CGRectMake(20, 170 - _offsetForTextField, 280, 120) title:_linkTitle delegate:self];
    
    // Add shadow
    UIBezierPath* shadowPath = [UIBezierPath bezierPathWithRect:self.linkObjectView.bounds];
    self.linkObjectView.layer.masksToBounds = NO;
    self.linkObjectView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.linkObjectView.layer.shadowOffset = CGSizeMake(0.0f, 3.0f);
    self.linkObjectView.layer.shadowRadius = 1;
    self.linkObjectView.layer.shadowOpacity = 0.4f;
    self.linkObjectView.layer.shadowPath = shadowPath.CGPath;
    
    [self.scrollView addSubview:self.linkObjectView];
}

-(void)displayNewMessages {
    
    // HACK - shouldn't need to do this every time
    [self showSendingFailedOptionsForLinkWithoutMessages:NO];
    
    // Helper
    NSString* messageThreadId = [_messageThread objectForKey:@"objectId"];
    
    NSArray* messages = [_messageThread objectForKey:@"Messages"];
    NSInteger oldMessagesCount = [_messages count];
    for (int i = 0; i < [messages count]; i++) {
        
        NSDictionary* message = [messages objectAtIndex:i];
        
        if (i >= oldMessagesCount) {
            
            //----------------------------------------------------------------------------------
            // This message is not yet displayed, so create and display a new message text field
            //----------------------------------------------------------------------------------
            if (![[message objectForKey:@"Message"] isEqualToString:@""]) {
                
                UITextView* messageView = [[UITextView alloc] initWithFrame:CGRectMake(20, _combinedMessageViewHeight, 200, MESSAGE_BUBBLE_HEIGHT)];
                messageView.text = [message objectForKey:@"Message"];
                messageView.font = [UIFont fontWithName:@"Titillium-Regular" size:14.0];
                messageView.textColor = [UIColor whiteColor];
                messageView.backgroundColor = [UIColor clearColor];
                messageView.editable = NO;
                messageView.scrollEnabled = NO;
                
                // Calculate optimal size of message view
                CGSize optimalSize = [messageView sizeThatFits:CGSizeMake(messageView.frame.size.width, 800)];
                
                // Increase height of scroll view if necessary
                if ((messageView.frame.origin.y + optimalSize.height) > (_scrollView.contentSize.height)) {
                    
                    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, messageView.frame.origin.y + optimalSize.height + SPACE_BETWEEN_MESSAGES);
                }
                
                [messageView sizeToFit];
                
                // Align correctly on the screen according to sender
                BOOL fromUser;
                CGFloat xAlteration;
                if ([[[message objectForKey:@"Sender"] objectForKey:@"Username"] isEqualToString:[PFUser currentUser].username]) {
                    messageView.textAlignment = NSTextAlignmentRight;
                    float xPosition = self.view.frame.size.width - messageView.frame.size.width - 20;
                    messageView.frame = CGRectMake(xPosition, messageView.frame.origin.y, messageView.frame.size.width, messageView.frame.size.height);
                    fromUser = YES;
                    xAlteration = 5;
                } else {
                    fromUser = NO;
                    xAlteration = 0;
                }
                
                // Add message bubble view
                CGRect bubbleFrame = CGRectMake(messageView.frame.origin.x - 10 + xAlteration, messageView.frame.origin.y - 5, messageView.frame.size.width + 15, messageView.frame.size.height + 5);
                MFRMessageBubbleView* bubbleView = [[MFRMessageBubbleView alloc] initWithFrame:bubbleFrame fromUser:fromUser];
                [_scrollView addSubview:bubbleView];
                
                [self.scrollView addSubview:messageView];
                _combinedMessageViewHeight += messageView.frame.size.height + SPACE_BETWEEN_MESSAGES;
                
                // Helper
                NSString* countString = [NSString stringWithFormat:@"%d", i];
                
                // Store messageView and bubbleView so that we can access them later to move them horizontally
                [_messageViews setObject:messageView forKey:countString];
                [_bubbleViews setObject:bubbleView forKey:countString];
            }
            
            // Store message locally
            [_messages addObject:message];
        }
        
        // Helper
        NSString* countString = [NSString stringWithFormat:@"%d", i];
        
        MFRLocalMessageStatus sendingStatus = [MFRLocalMessageThread getSendingStatusForMessageNumber:i inMessageThreadWithId:messageThreadId];
        
        if (
            (sendingStatus == MFRLocalMessageStatusSending)
            &&
            !_originalMessagesDisplayed
            &&
            self.progressView.hidden
            ) {
            // Message is still sending on loading view, so show progress view
            self.progressView.progress = SENDING_PROGRESS_TIME / SENDING_PROGRESS_TOTAL_DISPLAYED_TIME;
            self.progressView.hidden = NO;
        }
        
        if (
            (sendingStatus == MFRLocalMessageStatusSendingFailed)
            &&
            ([messages count] == 1)
            &&
            [[message objectForKey:@"Message"] isEqualToString:@""]
            ) {
            //-------------------------------------------------------------------------------------------
            // Message sending failed but no messages to display, so display Sending Failed label/buttons
            //-------------------------------------------------------------------------------------------
            [self showSendingFailedOptionsForLinkWithoutMessages:YES];
        }
        
        else if (
            (sendingStatus == MFRLocalMessageStatusSendingFailed)
            &&
            ![_retryButtons objectForKey:countString]
            ) {
            //----------------------
            // Display unsent button
            //----------------------
            CGFloat bubbleXAlteration;
            CGFloat unsentButtonXPosition;
            if ([[[message objectForKey:@"Sender"] objectForKey:@"Username"] isEqualToString:[PFUser currentUser].username]) {
                // Right hand side of screen
                bubbleXAlteration = -UNSENT_INDICATOR_GAP - RETRY_BUTTON_LENGTH;
                unsentButtonXPosition = self.view.frame.size.width - 20 - RETRY_BUTTON_LENGTH;
            } else {
                // Left hand side of screen
                bubbleXAlteration = UNSENT_INDICATOR_GAP + RETRY_BUTTON_LENGTH;
                unsentButtonXPosition = 20;
            }
            
            // Move bubble view and message view
            UITextView* messageView = [_messageViews objectForKey:countString];
            messageView.frame = CGRectMake(
                                           messageView.frame.origin.x + bubbleXAlteration,
                                           messageView.frame.origin.y,
                                           messageView.frame.size.width,
                                           messageView.frame.size.height);
            MFRMessageBubbleView* bubbleView = [_bubbleViews objectForKey:countString];
            bubbleView.frame = CGRectMake(bubbleView.frame.origin.x + bubbleXAlteration,
                                          bubbleView.frame.origin.y,
                                          bubbleView.frame.size.width,
                                          bubbleView.frame.size.height);
            
            // Display unsent button
            CGFloat yPosition = bubbleView.frame.origin.y + 15 - (RETRY_BUTTON_LENGTH / 2);
            UIButton* retryButton = [[UIButton alloc] initWithFrame:CGRectMake(unsentButtonXPosition, yPosition, RETRY_BUTTON_LENGTH, RETRY_BUTTON_LENGTH)];
            [retryButton addTarget:self action:@selector(displayRetryActionSheet:) forControlEvents:UIControlEventTouchUpInside];
            retryButton.tag = i;
            // TEMPORARY:
            [retryButton setImage:[UIImage imageNamed:@"ErrorCircle"] forState:UIControlStateNormal];
            [self.scrollView addSubview:retryButton];
            
            // Store retryButton
            [_retryButtons setObject:retryButton forKey:countString];
        }
        else if (
                 [_retryButtons objectForKey:countString]
                 &&
                 (sendingStatus == MFRLocalMessageStatusSent)
                 ) {
            //--------------------
            // Remove retry button
            //--------------------
            CGFloat bubbleXAlteration;
            if ([[[message objectForKey:@"Sender"] objectForKey:@"Username"] isEqualToString:[PFUser currentUser].username]) {
                // Right hand side of screen
                bubbleXAlteration = UNSENT_INDICATOR_GAP + RETRY_BUTTON_LENGTH;
            } else {
                // Left hand side of screen
                bubbleXAlteration = -UNSENT_INDICATOR_GAP - RETRY_BUTTON_LENGTH;
            }
            
            // Move bubble view and message view
            UITextView* messageView = [_messageViews objectForKey:countString];
            messageView.frame = CGRectMake(
                                           messageView.frame.origin.x + bubbleXAlteration,
                                           messageView.frame.origin.y,
                                           messageView.frame.size.width,
                                           messageView.frame.size.height);
            MFRMessageBubbleView* bubbleView = [_bubbleViews objectForKey:countString];
            bubbleView.frame = CGRectMake(bubbleView.frame.origin.x + bubbleXAlteration,
                                          bubbleView.frame.origin.y,
                                          bubbleView.frame.size.width,
                                          bubbleView.frame.size.height);
            
            // Remove unsent button
            [[_retryButtons objectForKey:countString] removeFromSuperview];
            [_retryButtons removeObjectForKey:countString];
        }
    }
    
    if (_combinedMessageViewHeight < (_maxScrollViewHeight - self.replyView.frame.size.height)) {
        //-------------------------------------
        // All messages fit above the reply bar
        //-------------------------------------
        _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _combinedMessageViewHeight);
        _scrollView.frame = CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y, _scrollView.frame.size.width, _combinedMessageViewHeight);
        UIEdgeInsets insets = { .left = 0, .right = 0, .top = 0, .bottom = 0 };
        _scrollView.contentInset = insets;
    } else {
        //--------------------------------------------
        // Messages do not all fit above the reply bar
        //--------------------------------------------
        // Only animate scrolling if some messages were already displayed
        BOOL animated;
        if (oldMessagesCount == 0) {
            animated = NO;
        } else {
            animated = YES;
        }
        
        // If the scroll view frame was previously not extended to its maximum possible height, extend it now
        if (_scrollView.frame.size.height < _maxScrollViewHeight) {
            _scrollView.frame = CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y, _scrollView.frame.size.width, _maxScrollViewHeight);
        }
        
        UIEdgeInsets insets = { .left = 0, .right = 0, .top = 0, .bottom = self.replyView.frame.size.height };
        _scrollView.contentInset = insets;
        
        [_scrollView setContentOffset:CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom) animated:animated];
    }
    
    if (!_originalMessagesDisplayed) {
        _originalMessagesDisplayed = YES;
    }
}

//--------------------------------------------------
// Retry sending a reply that did not manage to send
//--------------------------------------------------
-(IBAction)retrySend {
    [MFRAnalytics trackEvent:@"Retry button pressed on unsent message"];
    
    //----------------------------
    // Update timestamp on message
    //----------------------------
    NSMutableDictionary* message = [[[_messageThread objectForKey:@"Messages"] objectAtIndex:_retryButtonPressedForMessageNumber] mutableCopy];
//    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
//    [DateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSString* dateString = [NSString stringWithFormat:@"%@",[DateFormatter stringFromDate:[NSDate date]]];
    
    NSString* gmtDateString = [MFRDateTime getCurrentGMTDateTimeString];
    
    [message setObject:gmtDateString forKey:@"Date"];
    
    //------------------------------------------------------------------------------
    // Delete old version of message and insert new version at end of messages array
    //------------------------------------------------------------------------------
    NSMutableArray* messages = [[_messageThread objectForKey:@"Messages"] mutableCopy];
    [messages removeObjectAtIndex:_retryButtonPressedForMessageNumber];
    [messages addObject:message];
    
    [_messageThread setObject:messages forKey:@"Messages"];
    
    if (_retryButtonPressedForMessageNumber != ([_messages count] - 1)) {
        //-------------------------------------------------------------------------------
        // We are re-sending a message that is not the last message in the messageThread,
        // so mark that all the messages will need to be re-displayed
        //-------------------------------------------------------------------------------
        _mustRedisplayAllMessages = YES;
    }
    
    //--------------------------------------
    // Update local version of messageThread
    //--------------------------------------
    [MFRLocalMessageThread updateMessageThread:_messageThread shouldUpdateTime:YES];
    
    //------------------------
    // Attempt to send message
    //------------------------
    if (
        ![MFRLocalMessageThread messageThreadHasBeenSentToCloud:_messageThread]
        ) {
        //---------------------------------
        // Send messageThread to recipients
        //---------------------------------
        [self performSelectorInBackground:@selector(sendOriginalMessage) withObject:nil];
        
    } else {
        [self performSelectorInBackground:@selector(replyToMessage:) withObject:[message objectForKey:@"Message"]];
    }
    [self changeSendingStatus:[NSNumber numberWithInteger:1]];
}

-(void)sendOriginalMessage {
    //------------------------
    // Get intended recipients
    //------------------------
    NSMutableDictionary* unreadMarkers = [[_messageThread objectForKey:@"UnreadMarkers"] mutableCopy];
    [unreadMarkers removeObjectForKey:[PFUser currentUser].objectId];
    NSMutableArray* recipients = [[unreadMarkers allKeys] mutableCopy];
    
    //----------------------------------
    // Attempt to send the messageThread
    //----------------------------------
    [MFRParseMessageThread createAndSendParseMessageThreadWithLocalMessageThread:_messageThread recipients:recipients delegate:self];
}

-(IBAction)retrySendOfLinkWithNoMessage:(id)sender {
    _retryButtonPressedForMessageNumber = 0;
    [self retrySend];
}

-(IBAction)deleteMessageThreadLocallyButtonPressed:(id)sender {
    //-----------------------------
    // Delete messageThread locally
    //-----------------------------
    [MFRLocalMessageThread removeMessageThreadWithID:[_messageThread objectForKey:@"objectId"]];
    
    //------------------------------
    // Mark that inbox should reload
    //------------------------------
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate setInboxToReload:YES];
    
    //------------------
    // Pop back to inbox
    //------------------
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)share{
    [self performSegueWithIdentifier:@"ShowContacts" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"ForwardLink"]){
        
        NSDictionary *dimensions = @{ @"Number message in inbox view": [NSString stringWithFormat:@"%ld", (long)inboxEntry] };
        [MFRAnalytics trackEvent:@"Forward button pressed" dimensions:dimensions];
        
        //--------------------------------
        // Create Compose View Controller
        //--------------------------------
        ComposeViewController* controller = segue.destinationViewController;
        controller.linkObject = [[LinkObject alloc] initWithURL:self.linkObject.messageURL title:self.linkObject.messageTitle imageURL:self.linkObject.imageURL];
        controller->_url = _url;
        controller->_html = _html;
        controller->_linkTitle = _linkTitle;
        controller->_originalLink = _originalLink;
        controller.title = @"Forward";
//        controller->_originalLink = _originalLink;
    } else if ([[segue identifier] isEqualToString:@"Tweet"]){
        
        //-----------------------------
        // Create Tweet View Controller
        //-----------------------------
        TweetViewController* controller = segue.destinationViewController;
        controller->_url = _url;
    } else if ([[segue identifier] isEqualToString:@"ConnectToTwitter"]){
        //----------------------------------------
        // Create ConnectToTwitter View Controller
        //----------------------------------------
        TwitterViewController* controller = segue.destinationViewController;
        controller->shouldProgressToTweetView = YES;
        controller->_url = _url;
    }
}

-(void)enableActionButtons:(BOOL)enabled {
    _discardButton.enabled = enabled;
//    _forwardButton.enabled = enabled;
}

-(void)displayLinkExtras
{
    _discardButton.hidden = NO;
//    _forwardButton.hidden = NO;
}

-(void)hideLinkExtras
{
    _discardButton.hidden = YES;
//    _forwardButton.hidden = YES;
}

-(void)showLoadingWheel:(BOOL)show {
    if (show) {
        [_loadingWheel startAnimating];
    } else {
        [_loadingWheel stopAnimating];
    }
    _loadingWheel.hidden = !show;
}

#pragma mark - Saving linkObject
-(void)saveLinkObject {
    self.linkObject = [[LinkObject alloc] initWithURL:_url
                                            title:_linkTitle];
}

//#pragma mark - Speech bubbles
//-(void)drawSpeechBubbleForRect:(CGRect)currentFrame{
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGFloat strokeWidth = 3;
//    CGFloat borderRadius = 8;
//    CGFloat HEIGHTOFPOPUPTRIANGLE = 20;
//    CGFloat WIDTHOFPOPUPTRIANGLE = 40;
//    
//    CGContextSetLineJoin(context, kCGLineJoinRound);
//    CGContextSetLineWidth(context, strokeWidth);
//    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
//    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
//    
//    // Draw and fill the bubble
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, borderRadius + strokeWidth + 0.5f, strokeWidth + HEIGHTOFPOPUPTRIANGLE + 0.5f);
//    CGContextAddLineToPoint(context, round(currentFrame.size.width / 2.0f - WIDTHOFPOPUPTRIANGLE / 2.0f) + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f);
//    CGContextAddLineToPoint(context, round(currentFrame.size.width / 2.0f) + 0.5f, strokeWidth + 0.5f);
//    CGContextAddLineToPoint(context, round(currentFrame.size.width / 2.0f + WIDTHOFPOPUPTRIANGLE / 2.0f) + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f);
//    CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, strokeWidth + HEIGHTOFPOPUPTRIANGLE + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
//    CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, round(currentFrame.size.width / 2.0f + WIDTHOFPOPUPTRIANGLE / 2.0f) - strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
//    CGContextAddArcToPoint(context, strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, strokeWidth + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f, borderRadius - strokeWidth);
//    CGContextAddArcToPoint(context, strokeWidth + 0.5f, strokeWidth + HEIGHTOFPOPUPTRIANGLE + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f, borderRadius - strokeWidth);
//    CGContextClosePath(context);
//    CGContextDrawPath(context, kCGPathFillStroke);
//    
//    // Draw a clipping path for the fill
//    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, borderRadius + strokeWidth + 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f);
//    CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
//    CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, round(currentFrame.size.width / 2.0f + WIDTHOFPOPUPTRIANGLE / 2.0f) - strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
//    CGContextAddArcToPoint(context, strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, strokeWidth + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f, borderRadius - strokeWidth);
//    CGContextAddArcToPoint(context, strokeWidth + 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f, borderRadius - strokeWidth);
//    CGContextClosePath(context);
//    CGContextClip(context);
//    
//}

-(void)growScrollViewFrameHeightByHeight:(float)diff {
    
    CGPoint oldOffset = CGPointMake(0, self.scrollView.contentOffset.y);
    CGFloat oldFrameHeight = self.scrollView.frame.size.height;
    
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height + diff);
    
    CGFloat newScrollViewFrameHeight = self.scrollView.frame.size.height;
    
    CGFloat updatedOffsetYPosition = oldOffset.y + oldFrameHeight - newScrollViewFrameHeight;
    if (updatedOffsetYPosition < 0) {
        updatedOffsetYPosition = 0;
    } else if (updatedOffsetYPosition > (self.scrollView.contentSize.height - self.scrollView.bounds.size.height)) {
        updatedOffsetYPosition = self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom;
    }
    CGPoint updatedOffset = CGPointMake(0, updatedOffsetYPosition);
    
    [_scrollView setContentOffset:updatedOffset animated:YES];
}

#pragma mark - HPGrowingTextViewDelegate
- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView {
    
    [MFRAnalytics trackEvent:@"Started editing message in reply screen"];
    
    [self moveReplyView];
    return YES;
}

- (void) moveReplyView {
    void (^animations)() = ^() {
        self.replyView.frame = CGRectMake(self.replyView.frame.origin.x, self.replyView.superview.bounds.size.height - self.replyView.frame.size.height - _keyboardTop, self.replyView.frame.size.width, self.replyView.frame.size.height);
        
        CGRect scrollFrame = self.scrollView.frame;
        scrollFrame.size.height = self.replyView.frame.origin.y;
        BOOL scrollToBottom = NO;
        if (scrollFrame.size.height < self.scrollView.frame.size.height) {
            scrollToBottom = YES;
        }
        self.scrollView.frame = scrollFrame;

        if (scrollToBottom) {
            CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
            self.scrollView.contentOffset = bottomOffset;
        }
    };
    [UIView animateWithDuration:_animationDuration
                          delay:0.0
                        options:(_animationCurve << 16)
                     animations:animations
                     completion:^(BOOL finished) {
                     }];
}

- (BOOL)growingTextViewShouldEndEditing:(HPGrowingTextView *)growingTextView {
    
    _keyboardTop = 0;

    [self moveReplyView];
    
    return YES;
}

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView {
    
}

- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView {
    
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *testString = [growingTextView.internalTextView.text stringByReplacingCharactersInRange:range withString:text];
    if ([testString length] == 0) {
        growingTextView.internalTextView.text = text;
        _replyView.sendButton.enabled = NO;
    } else if (
               !_replyView.sendButton.enabled
               &&
               ([growingTextView.internalTextView.text length] == 0)
               ) {
        _replyView.sendButton.enabled = YES;
    }
    
    return TRUE;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView {
    
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height {
    
    float diff = (growingTextView.frame.size.height - height);
    CGRect r = _replyView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	_replyView.frame = r;
    
    [self growScrollViewFrameHeightByHeight:diff];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView didChangeHeight:(float)height {
    
}

- (void)growingTextViewDidChangeSelection:(HPGrowingTextView *)growingTextView {
    
}

- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView {
    return YES;
}

//- (BOOL)textFieldShouldClear:(UITextField *)textField{
//    _replyView.sendButton.enabled = NO;
//    //    _replyButtonEnabled = NO;
//    //    _replyToolbar.sendButton.action = nil;
//    return YES;
//}

#pragma mark - Action sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 0)
    {
        switch (buttonIndex) {
            case 0:
            {
                // Forward
                [self performSegueWithIdentifier:@"ForwardLink" sender:self];
                [MFRAnalytics trackEvent:@"Forward button pressed in Share action sheet"];
                break;
            }
            case 1:
            {
                // Copy link
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = [self.linkObject.messageURL absoluteString];
                [MFRAnalytics trackEvent:@"Copy link button pressed in Share action sheet"];
                break;
            }
            case 2:
            {
                [MFRAnalytics trackEvent:@"Tweet button pressed in message view"];
                // Tweet link
                if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                    // Connected to Twitter, so display Tweet view controller
                    [self performSegueWithIdentifier:@"Tweet" sender:self];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"No Twitter account" message: @"You haven't set up Twitter yet. Connect with Twitter now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
                    alert.tag = 1;
                    [alert show];
                    [MFRAnalytics trackEvent:@"'No Twitter account' message displayed in message view"];
                }
                break;
            }
//            case 3:
//            {
//                // Share link to Facebook
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Sorry" message: @"You can't share links to social media yet. But I'm working on it!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
//                [alert show];
//                [MFRAnalytics trackEvent:@"Share to Facebook button pressed"];
//                break;
//            }
        }
    } else if (actionSheet.tag == 1) {
        switch (buttonIndex) {
            case 0:
            {
                // Retry send
                [self retrySend];
                [MFRAnalytics trackEvent:@"Retry button pressed in Reply action sheet"];
                break;
            }
            case 1:
            {
                if (
                    ![MFRLocalMessageThread messageThreadHasBeenSentToCloud:_messageThread]
                    &&
                    ([_messages count] == 1)
                    ) {
                    //-------------------------------------------------------------
                    // This is the only message, so delete the entire messageThread
                    //-------------------------------------------------------------
                    [self deleteMessageThreadLocallyButtonPressed:self];
                } else {
                    //-------------------------
                    // Delete only this message
                    //-------------------------
                    // Delete message locally
                    NSMutableArray* messages = [[_messageThread objectForKey:@"Messages"] mutableCopy];
                    [messages removeObjectAtIndex:_retryButtonPressedForMessageNumber];
                    [_messageThread setObject:messages forKey:@"Messages"];
                    
                    // Update local version of messageThread
                    [MFRLocalMessageThread updateMessageThread:_messageThread shouldUpdateTime:NO];
                    
                    // Re-display messages
                    [self removeMessagesFromView];
                    [self displayNewMessages];
                    
                    // Mark that inbox should reload
                    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    [appDelegate setInboxToReload:YES];
                }
                
                [MFRAnalytics trackEvent:@"Delete button pressed in Reply action sheet"];
                break;
            }
        }
    }
}

-(void)removeMessagesFromView {
    // HACK - Remove all messageViews and bubbleViews, to be re-drawn
    for(NSString* key in _messageViews) {
        UITextView* messageView = [_messageViews objectForKey:key];
        [messageView removeFromSuperview];
    }
    for(NSString* key in _bubbleViews) {
        MFRMessageBubbleView* bubbleView = [_bubbleViews objectForKey:key];
        [bubbleView removeFromSuperview];
    }
    [_messages removeAllObjects];
    [_messageViews removeAllObjects];
    [_bubbleViews removeAllObjects];
    [_retryButtons removeAllObjects];
    [self resetCombinedMessageViewHeight];
}

-(void)resetCombinedMessageViewHeight {
    _combinedMessageViewHeight = MESSAGES_STARTING_Y_COORDINATE + SPACE_BETWEEN_MESSAGES;
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    [MFRAnalytics trackEvent:@"Cancel button pressed in Share action sheet"];
}

#pragma mark - Accessing messageThread ID
-(NSString*)getMessageThreadID {
    return [_messageThread objectForKey:@"objectId"];
}

#pragma mark - Retry action sheet
-(void)displayRetryActionSheet:(id)sender {
    
    [MFRAnalytics trackEvent:@"Retry button pressed"];
    
    _retryButtonPressedForMessageNumber = ((UIButton*)sender).tag;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Message sending failed"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Retry",@"Delete",nil
                                  ];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.tag = 1;
    [actionSheet showInView:[self.view window]];
}

#pragma mark - Displaying Sending Failed label/buttons when there are no displayed messages
-(void)showSendingFailedOptionsForLinkWithoutMessages:(BOOL)show {
    
    if (show) {
        [self.movingView addSubview:_sendingFailedLabel];
        [self.movingView addSubview:_sendingFailedRetryButton];
        [self.movingView addSubview:_sendingFailedDeleteButton];
    } else {
        [_sendingFailedLabel removeFromSuperview];
        [_sendingFailedRetryButton removeFromSuperview];
        [_sendingFailedDeleteButton removeFromSuperview];
    }
}

#pragma mark - Alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {
        // No Twitter user connected alert view
        if (buttonIndex == 1) {
            // Display Connect To Twitter view controller
            [self performSegueWithIdentifier:@"ConnectToTwitter" sender:self];
            [MFRAnalytics trackEvent:@"Connect to Twitter button pressed in message view"];
        }
    }
}

@end


