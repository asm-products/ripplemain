//
//  ComposeViewController.m
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "ComposeViewController.h"
#import "AppDelegate.h"
#import "ContactsViewController.h"
#import "MFRAnalytics.h"
#import "SearchResultCell.h"
#import "NSString+HTML.h"

#define DISTANCE_OF_SEARCH_NAVIGATION_BUTTONS_FROM_BOTTOM 40

@interface ComposeViewController () {
    
    NSTimeInterval _animationDuration;
    UIViewAnimationCurve _animationCurve;
    CGFloat _keyboardTop;
    CGFloat _viewPositionWhenKeyboardRevealed;
}

@end

@implementation ComposeViewController

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
    
    _viewPositionWhenKeyboardRevealed = 0;
    
    // Add share toolbar
    _shareView = [[MFRMessageEntryView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44) title:@"Send"];
    [_shareView.sendButton addTarget:self action:@selector(sendButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _shareView.messageView.delegate = self;
    [self.view addSubview:_shareView];
    
    [self displayLoadingWheel:NO];
    
    if (_originalLink) {
        // Composing from scratch
        [self showInboxButton];
        [self hideLinkElements];
        [self hideMessageToolbar];
    } else {
        // Forwarding
        _linkTextField.hidden = YES;
        [self displayLink];
    }
    
    _searchResultsMaskView = [[UIView alloc] initWithFrame:_searchResultsTableView.frame];
    _searchResultsMaskView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    _linkTextField.tag = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    // Fallback keyboard animation curve
    _animationDuration = 0.25;
    _animationCurve = 7;
    
    [self.searchResultsTableView registerClass:[SearchResultCell class] forCellReuseIdentifier:@"SearchCell"];
    
    [_linkTextField setPlaceholderText:@"Paste a link or search"];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [parentDelegate addSwipeGesture];
    if (_originalLink) {
        [self checkFriendRequestCount];
    }
}

-(void)sendButtonPressed {
    [self performSegueWithIdentifier:@"SendLink" sender:self];
}

#pragma mark - Hiding and showing elements
-(void)hideMessageToolbar
{
    _shareView.hidden = YES;
    _shareView.messageView.text = @"";
}

-(void)showInboxButton {
    
    // Inbox button
    UIButton *bt=[UIButton buttonWithType:UIButtonTypeCustom];
    [bt setFrame:CGRectMake(0, 0, 25, 25)];
    [bt setImage:[UIImage imageNamed:@"Inbox-128"] forState:UIControlStateNormal];
    [bt addTarget:self action:@selector(pushInboxViewController) forControlEvents:UIControlEventTouchUpInside];
    bt.showsTouchWhenHighlighted = YES;
    _inboxButton = [[UIBarButtonItem alloc] initWithCustomView:bt];
    self.navigationController.navigationBar.topItem.leftBarButtonItem = _inboxButton;
    
    // Contacts button
    UIButton *btTwo=[UIButton buttonWithType:UIButtonTypeCustom];
    [btTwo setFrame:CGRectMake(0, 0, 25, 25)];
    [btTwo setImage:[UIImage imageNamed:@"User-Group-128"] forState:UIControlStateNormal];
    [btTwo addTarget:self action:@selector(pushContactsViewController) forControlEvents:UIControlEventTouchUpInside];
    btTwo.showsTouchWhenHighlighted = YES;
    _contactsButton = [[UIBarButtonItem alloc] initWithCustomView:btTwo];
    self.navigationController.navigationBar.topItem.rightBarButtonItem = _contactsButton;
}

#pragma mark - Loading Activity Indicator
-(void)displayLoadingWheel:(BOOL)b {
    if (b) {
        [_loadingWheel startAnimating];
    } else {
        [_loadingWheel stopAnimating];
    }
    _loadingWheel.hidden = !b;
}

-(void)clearTextFieldAndDiscardLinkInfo {
    [self clearLinkData];
    [self hideLinkElements];
    [self hideMessageToolbar];
    self.linkTextField.text = @"";
}

#pragma mark - TextField delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.tag == 0) {
        [self clearLinkData];
        [self hideLinkElements];
        [self hideMessageToolbar];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (textField.tag == 0) {
        _keyboardTop = 0;
        [self moveShareView];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == 0) {
        
        // If a link has been entered, try to display it
        if (![textField.text isEqualToString:@""]){
            [self displayLoadingWheel:YES];
            [self performSelectorInBackground:@selector(displayLinkOrSearchResultsFromString:) withObject:_linkTextField.text];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField.tag == 0) {
        
        if (
            ([string length] > 1)
            &&
            (range.length == 0)
            ) {
            // Fetch link after paste
            textField.text = string;
            [textField resignFirstResponder];
            [MFRAnalytics trackEvent:@"Text pasted into link text field"];
        }
    }
    
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Displaying link
-(void)displayLinkOrSearchResultsFromString:(NSString*)linkString {
    [self getLinkDataFromURLString:_linkTextField.text];
    [self performSelectorOnMainThread:@selector(displayLinkOrSearchResultsIfEitherExist) withObject:nil waitUntilDone:NO];
}

-(void)displayLinkOrSearchResultsIfEitherExist {
    [self displayLoadingWheel:NO];
    if (_html) {
        [MFRAnalytics trackEvent:@"Text entered in text field is link"];
        [self displayLink];
        [self saveLinkObject];
    }
    else if ([_linkTextField.text length] > 0) {
        
        [MFRAnalytics trackEvent:@"Text entered in text field is search"];
        
        // Show UIWebView with Google Search
        NSString *searchString = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", [_linkTextField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        _url = [NSURL URLWithString:searchString];
        [self saveLinkObject];
        BOOL presentedFromSearch = YES;
        [self presentWebView:presentedFromSearch];
    }
    else{
        [self hideLinkElements];
        [self hideMessageToolbar];
        self.linkObject = nil;
    }
}

-(void)displayLink {
    [self showLinkElements];
    _shareView.hidden = NO;
    
    if (_originalLink) {
        // Composing original message, so get and display image for link
        self.linkObjectView.editImageButton.hidden = NO;
        [self performSelectorInBackground:@selector(fetchImageForLink) withObject:nil];
    } else {
        // Forwarding message, so display link if there is one
        if (self.linkObject.imageURL) {
            [self.linkObjectView setLoading:YES];
            [self performSelectorInBackground:@selector(displayImageFromURL:) withObject:self.linkObject.imageURL];
        } else {
            self.linkObjectView.linkImageView.hidden = YES;
            [self.linkObjectView showSmallTitle:NO];
        }
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
    
    [self.movingView addSubview:self.linkObjectView];
}

#pragma mark - Sliding the text field when editing
-(void)keyboardWillShow:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    
    // Get keyboard animation
    NSNumber *durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey];
    _animationDuration = durationValue.doubleValue;
    
    NSNumber *curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey];
    _animationCurve = curveValue.intValue;
    
    CGRect keyboardRect = [[aNotification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardTop = keyboardRect.size.height;
    
    [self moveShareView];
}

#pragma mark - Dismissing text view
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    // Any new character added is passed in as the "text" parameter
    if ([text isEqualToString:@"\n"]) {
        // Be sure to test for equality using the "isEqualToString" message
        [textView resignFirstResponder];
        
        // Return FALSE so that the final '\n' character doesn't get added
        return FALSE;
    }
    // For any other character return TRUE so that the text gets added to the view
    return TRUE;
}

-(IBAction)clickOutsideTextField:(id)sender {
    [_linkTextField resignFirstResponder];
    [_shareView.messageView resignFirstResponder];
}

#pragma mark - Swapping views
-(IBAction)pushInboxViewController
{
    [parentDelegate navigateLeftToInbox];
}

-(IBAction)pushContactsViewController
{
    [parentDelegate navigateRightToContacts];
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"SendLink"]){
        
        //----------------------------------------------------
        // Hack that accepts whatever autocorrect is suggested
        //----------------------------------------------------
        [_shareView.messageView.internalTextView resignFirstResponder];
        [_shareView.messageView.internalTextView becomeFirstResponder];
        
        [parentDelegate removeSwipeGesture];
        
        // Dismiss keyboard
        [self clickOutsideTextField:self];
        
        //--------------------------------
        // Create Contacts View Controller
        //--------------------------------
        ContactsViewController* controller = segue.destinationViewController;
        controller.linkObject = self.linkObject;
        controller->_originalLink = _originalLink;
        controller->pushedFromWebView = NO;
        controller->_sendingLink = YES;
        controller.messageBody = _shareView.messageView.text;
    }
}

#pragma mark - Saving linkObject
-(void)saveLinkObject {
    self.linkObject = [[LinkObject alloc] initWithURL:_url
                                            title:_linkTitle];
}

#pragma mark - Search delegate methods
-(void)selectSearchResultWithURL:(NSURL*)url title:(NSString*)title html:(NSString*)html {
    [MFRAnalytics trackEvent:@"Search result chosen to send"];
    _url = url;
    _html = html;
    _linkTitle = title;
    [self saveLinkObject];
    [self displayLink];
}

#pragma mark - HPGrowingTextViewDelegate
- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView {
    
    [MFRAnalytics trackEvent:@"Started editing message in compose screen"];
    
    [self moveShareView];
    return YES;
}


- (void) moveShareView {
    void (^animations)() = ^() {
        self.shareView.frame = CGRectMake(self.shareView.frame.origin.x, self.shareView.superview.bounds.size.height - self.shareView.frame.size.height - _keyboardTop, self.shareView.frame.size.width, self.shareView.frame.size.height);
    };
    
    [UIView animateWithDuration:_animationDuration
                          delay:0.0
                        options:(_animationCurve << 16)
                     animations:animations
                     completion:nil];
}

- (BOOL)growingTextViewShouldEndEditing:(HPGrowingTextView *)growingTextView {

    _keyboardTop = 0;
    [self moveShareView];

    return YES;
}

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView {
    
}

- (void)growingTextViewDidEndEditing:(HPGrowingTextView *)growingTextView {
    
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView {
    
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height {
    
    float diff = (growingTextView.frame.size.height - height);
    CGRect r = _shareView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	_shareView.frame = r;
    
    self.movingView.frame = CGRectMake(self.movingView.frame.origin.x, self.movingView.frame.origin.y + diff, self.movingView.frame.size.width, self.movingView.frame.size.height - diff);
    
//    MUST SCROLL DOWN/UP WHEN LARGE TEXT VIEW IS DISMISSED/RECALLED
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView didChangeHeight:(float)height {
    
}

- (void)growingTextViewDidChangeSelection:(HPGrowingTextView *)growingTextView {
    
}

- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView {
    return YES;
}

#pragma mark - Nav bar
-(void)checkFriendRequestCount {
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [self updateFriendRequestsLabel:[NSNumber numberWithInteger:[[appDelegate getFriendRequests] count]]];
}

-(void)updateFriendRequestsLabel:(NSNumber*)friendRequestsCount {
    
    // Contacts button
    UIButton *bt=[UIButton buttonWithType:UIButtonTypeCustom];
    [bt setFrame:CGRectMake(0, 0, 25, 25)];
    [bt setImage:[UIImage imageNamed:@"User-Group-128"] forState:UIControlStateNormal];
    
    if ([friendRequestsCount intValue] > 0) {
        // Display number of friend requests
        UILabel* contactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, -5, 15, 15)];
        contactsLabel.text = [friendRequestsCount stringValue];
        contactsLabel.textColor = [UIColor whiteColor];
        contactsLabel.backgroundColor = [UIColor colorWithRed:155/255.0 green:89/255.0 blue:182/255.0 alpha:1.0];
        contactsLabel.textAlignment = NSTextAlignmentCenter;
        contactsLabel.layer.cornerRadius = 8;
        contactsLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:8.0];
        [bt addSubview:contactsLabel];
    }
    
    [bt addTarget:self action:@selector(pushContactsViewController) forControlEvents:UIControlEventTouchUpInside];
    bt.showsTouchWhenHighlighted = YES;
    _contactsButton = [[UIBarButtonItem alloc] initWithCustomView:bt];
    self.navigationController.navigationBar.topItem.rightBarButtonItem = _contactsButton;
}


@end
