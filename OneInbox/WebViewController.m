//
//  WebViewController.m
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "WebViewController.h"
#import "ComposeViewController.h"
#import "ContactsViewController.h"
#import "MFRAnalytics.h"
#import "TweetViewController.h"
#import "TwitterViewController.h"

@interface WebViewController () {
    int _pageIndex;
    int _maxReachedPageIndex;
}

@end

@implementation WebViewController

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
    
    _linkWebView.scalesPageToFit = YES;
    
    // 'Loading...' label on nav bar
    [self setViewTitle:@"Loading..."];
    
    // Dismiss button
    UIBarButtonItem *button = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                               target:self
                               action:@selector(dismissWebView)];
    
    [self addLoadingWheelToNavBar];
                               
    self.navigationItem.leftBarButtonItem = button;
    
    // Toolbar
    NSMutableArray *items = [NSMutableArray array];
    
    // Back button
    UIButton *bt=[UIButton buttonWithType:UIButtonTypeCustom];
    [bt setFrame:CGRectMake(0, 0, 25, 25)];
    [bt setImage:[UIImage imageNamed:@"BackArrow-128"] forState:UIControlStateNormal];
    [bt addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _webBackButton = [[UIBarButtonItem alloc] initWithCustomView:bt];
    [items addObject:_webBackButton];
    
    UIButton *btTwo=[UIButton buttonWithType:UIButtonTypeCustom];
    [btTwo setFrame:CGRectMake(0, 0, 25, 25)];
    [btTwo setImage:[UIImage imageNamed:@"ForwardArrow-128"] forState:UIControlStateNormal];
    [btTwo addTarget:self action:@selector(forwardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _webForwardButton = [[UIBarButtonItem alloc] initWithCustomView:btTwo];
    [items addObject:_webForwardButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexibleSpace];
    
    if (_originalLink) {
        // Forward button
        UIButton *btThree=[UIButton buttonWithType:UIButtonTypeCustom];
        [btThree setFrame:CGRectMake(0, 0, 35, 35)];
        [btThree setImage:[UIImage imageNamed:@"Arrow-Black-128"] forState:UIControlStateNormal];
        [btThree addTarget:self action:@selector(forwardMessageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _shareButton = [[UIBarButtonItem alloc] initWithCustomView:btThree];
    } else {
        // Share button
        _shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)];
    }
    [items addObject:_shareButton];
    
    _toolbar.items = items;
    
    _pageIndex = 0;
    _maxReachedPageIndex = 0;
    [self setWebBackButtonEnabled:NO];
    [self setWebForwardButtonEnabled:NO];
    
    [self showLoadingWheel:YES];
    
    [self displaySite];
}

-(void)addLoadingWheelToNavBar {
    _loadingWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _loadingWheel.frame = CGRectMake(100, 12, _loadingWheel.frame.size.width, _loadingWheel.frame.size.height);
    [self.navigationController.navigationBar addSubview:_loadingWheel];
    _loadingWheel.hidden = YES;
}

-(void)showLoadingWheel:(BOOL)show {
    _loadingWheel.hidden = !show;
    if (show) {
        [_loadingWheel startAnimating];
    } else {
        [_loadingWheel stopAnimating];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Displaying site
-(void)displaySite
{
    //----------------------
    // Load url into webview
    //----------------------
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [_linkWebView loadRequest:urlRequest];
    _linkWebView.delegate = self;
}

#pragma mark - Controlling the page
-(IBAction)dismissWebView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Web View delegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Set nav bar title
    self.navigationController.navigationBar.topItem.title = [_linkWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    [self showLoadingWheel:NO];
}

-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        [self setViewTitle:@"Loading..."];
        
        // Update back button
        _pageIndex++;
        if (_pageIndex > _maxReachedPageIndex) {
            _maxReachedPageIndex = _pageIndex;
        }
        if (!_webBackButton.enabled) {
            [self setWebBackButtonEnabled:YES];
        }
    }
    return YES;
}

#pragma mark - Nav bar
-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

#pragma mark - Toolbar
-(IBAction)backButtonPressed:(id)sender{
    
    // Update page index
    _pageIndex--;
    
    // Go back
    [_linkWebView goBack];
    
    // Update back and forward buttons
    if (_pageIndex == 0) {
        [self setWebBackButtonEnabled:NO];
    }
    if (!_webForwardButton.enabled) {
        [self setWebForwardButtonEnabled:YES];
    }
}

-(IBAction)forwardButtonPressed:(id)sender{
    
    // Update page index
    _pageIndex++;
    if (_pageIndex > _maxReachedPageIndex) {
        _maxReachedPageIndex = _pageIndex;
    }
    
    // Go forward
    [_linkWebView goForward];
    
    // Update back and forward buttons
    if (!_webBackButton.enabled) {
        [self setWebBackButtonEnabled:YES];
    }
    if (_pageIndex == _maxReachedPageIndex) {
        [self setWebForwardButtonEnabled:NO];
    }
}

-(void)setWebBackButtonEnabled:(BOOL)enabled {
    _webBackButton.enabled = enabled;
}

-(void)setWebForwardButtonEnabled:(BOOL)enabled {
    _webForwardButton.enabled = enabled;
}

#pragma mark - Send
-(IBAction)forwardMessageButtonPressed:(id)sender {
    if (_displayedFromSearch) {
        [MFRAnalytics trackEvent:@"Search result selected in web view"];
        [searchDelegate selectSearchResultWithURL:_linkWebView.request.URL title:[_linkWebView stringByEvaluatingJavaScriptFromString:@"document.title"] html:[_linkWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"]];
        [self dismissWebView];
    } else if (_originalLink) {
        [self performSegueWithIdentifier:@"ContactsSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"ComposeSegue" sender:self];
    }
}

-(IBAction)shareButtonPressed:(id)sender {
    [MFRAnalytics trackEvent:@"Share button pressed in Web view"];
    
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

//-(IBAction)discardButtonPressed:(id)sender {
//    ...
//}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"ContactsSegue"]){
        
        //--------------------------------
        // Create Contacts View Controller
        //--------------------------------
        ContactsViewController* controller = segue.destinationViewController;
        controller.linkObject = _linkObject;
        controller->_originalLink = _originalLink;
        controller->pushedFromWebView = YES;
        controller->webViewDelegate = self;
        controller->_sendingLink = YES;
    }
    else if ([[segue identifier] isEqualToString:@"ComposeSegue"]){
        
        //--------------------------------
        // Create Compose View Controller
        //--------------------------------
        ComposeViewController* controller = segue.destinationViewController;
        controller.linkObject = [[LinkObject alloc] initWithURL:_linkObject.messageURL title:_linkObject.messageTitle imageURL:_linkObject.imageURL];
        controller->_url = url;
        controller->_html = html;
        controller->_linkTitle = _linkObject.messageTitle;
        controller->_originalLink = _originalLink;
//        controller->deleteLinkDelegate = deleteLinkDelegate;
//        controller->pushedFromWebView = YES;
//        controller->webViewDelegate = self;
        controller.title = @"Forward";
    } else if ([[segue identifier] isEqualToString:@"Tweet"]){
        
        //-----------------------------
        // Create Tweet View Controller
        //-----------------------------
        TweetViewController* controller = segue.destinationViewController;
        controller->_url = url;
    } else if ([[segue identifier] isEqualToString:@"ConnectToTwitter"]){
        //----------------------------------------
        // Create ConnectToTwitter View Controller
        //----------------------------------------
        TwitterViewController* controller = segue.destinationViewController;
        controller->shouldProgressToTweetView = YES;
        controller->_url = url;
    }
}

-(void)setViewTitle:(NSString*)title {
    self.navigationController.navigationBar.topItem.title = title;
}

#pragma mark - Action sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 0)
    {
        switch (buttonIndex) {
            case 0:
            {
                // Forward
                [self performSegueWithIdentifier:@"ComposeSegue" sender:self];
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
                [MFRAnalytics trackEvent:@"Tweet button pressed in web view"];
                // Tweet link
                if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                    // Connected to Twitter, so display Tweet view controller
                    [self performSegueWithIdentifier:@"Tweet" sender:self];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"No Twitter account" message: @"You haven't set up Twitter yet. Connect with Twitter now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
                    alert.tag = 1;
                    [alert show];
                    [MFRAnalytics trackEvent:@"'No Twitter account' message displayed in web view"];
                }
                break;
            }
        }
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    [MFRAnalytics trackEvent:@"Cancel button pressed in Share action sheet"];
}

#pragma mark - Alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1) {
        // No Twitter user connected alert view
        if (buttonIndex == 1) {
            // Display Connect To Twitter view controller
            [self performSegueWithIdentifier:@"ConnectToTwitter" sender:self];
            [MFRAnalytics trackEvent:@"Connect to Twitter button pressed in web view"];
        }
    }
}

@end
