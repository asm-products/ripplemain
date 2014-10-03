//
//  TweetViewController.m
//  Ripple
//
//  Created by Ed Rex on 07/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "TweetViewController.h"
#import "MFRAnalytics.h"
#import <Parse/Parse.h>
#import "MFRAnalytics.h"

@interface TweetViewController () {
    NSTimeInterval _animationDuration;
    UIViewAnimationCurve _animationCurve;
    CGFloat _viewPositionWhenKeyboardRevealed;
}

@end

@implementation TweetViewController

@synthesize tweetView = _tweetView;
@synthesize characterLabel = _characterLabel;
@synthesize loadingWheel = _loadingWheel;

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
    
    // Add reply toolbar
    _tweetView = [[MFRMessageEntryView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44) title:@"Tweet"];
    [_tweetView.sendButton addTarget:self action:@selector(tweetButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    _tweetView.messageView.delegate = self;
    [self.view addSubview:_tweetView];
    
    // Add tap gesture to view
//    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOutsideTextField:)];
//    [self.view addGestureRecognizer:singleTap];
    
    _viewPositionWhenKeyboardRevealed = 0;
    
    // Fallback keyboard animation curve
    _animationDuration = 0.25;
    _animationCurve = 7;
    
    // Display suggested tweet
    NSString* tweetString = [NSString stringWithFormat:@"Check out this link - %@", [_url absoluteString]];
    _tweetView.messageView.text = tweetString;
    
    [_characterLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:32.0]];
    [self updateCharacterLabel];
    
    [_tweetView.messageView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Character label
-(void)updateCharacterLabel {
    int characterCount = 140 - [_tweetView.messageView.text length];
    _characterLabel.text = [NSString stringWithFormat:@"%i", characterCount];
    
    if (characterCount < 0) {
        [_characterLabel setTextColor:[UIColor redColor]];
        if (_tweetView.sendButton.enabled) {
            _tweetView.sendButton.enabled = NO;
        }
    } else if (characterCount < 140) {
        [_characterLabel setTextColor:[UIColor darkGrayColor]];
        if (!_tweetView.sendButton.enabled) {
            _tweetView.sendButton.enabled = YES;
        }
    } else {
        if (_tweetView.sendButton.enabled) {
            _tweetView.sendButton.enabled = NO;
        }
    }
}

#pragma mark - Tweet button
-(void)tweetButtonPressed {
    [MFRAnalytics trackEvent:@"Tweet button pressed in Tweet view"];
    [self showLoadingWheel:[NSNumber numberWithBool:YES]];
    [self performSelectorInBackground:@selector(postStatus:) withObject:_tweetView.messageView.text];
}

#pragma mark - Post to Twitter
- (void)postStatus:(NSString *)status {
    
    // Construct the parameters string. The value of "status" is percent-escaped.
//    NSString *bodyString = [NSString stringWithFormat:@"status=%@", [status stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *bodyString = [NSString stringWithFormat:@"status=%@", [self urlEncodeValue:status]];
    
    // Explicitly percent-escape the '!' character.
    bodyString = [bodyString stringByReplacingOccurrencesOfString:@"!" withString:@"%21"];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    NSMutableURLRequest *tweetRequest = [NSMutableURLRequest requestWithURL:url];
    tweetRequest.HTTPMethod = @"POST";
    tweetRequest.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    [[PFTwitterUtils twitter] signRequest:tweetRequest];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    // Post status synchronously.
    NSData *data = [NSURLConnection sendSynchronousRequest:tweetRequest
                                         returningResponse:&response
                                                     error:&error];
    
    // Handle response.
    [self performSelectorInBackground:@selector(showLoadingWheel:) withObject:[NSNumber numberWithBool:NO]];
    if (!error) {
        // Present UIAlertView
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Tweet sent!" message: @"Your Tweet has been sent." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        NSLog(@"Error: %@", error);
        NSLog(@"Response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        [MFRAnalytics trackEvent:@"Tweet sent successfully"];
    } else {
        // Present UIAlertView
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Could not connect" message: @"Your Tweet couldn't be sent at this time - please try again later." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        NSLog(@"Error: %@", error);
        [MFRAnalytics trackEvent:@"Tweet sending failed"];
    }
}

-(NSString*)urlEncodeValue:(NSString*)str {
    NSString* result = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8)); return result;
}

//-(IBAction)clickOutsideTextField:(id)sender {
//    [_tweetView.messageView resignFirstResponder];
//}

#pragma mark - HPGrowingTextViewDelegate
- (BOOL)growingTextViewShouldBeginEditing:(HPGrowingTextView *)growingTextView {
    
    [MFRAnalytics trackEvent:@"Started editing text in tweet screen"];
    
    void (^animations)() = ^() {
        _tweetView.frame = CGRectMake(_tweetView.frame.origin.x, _tweetView.frame.origin.y - 215, _tweetView.frame.size.width, _tweetView.frame.size.height);
        
        if (_viewPositionWhenKeyboardRevealed != 0) {
            self.movingView.frame = CGRectMake(self.movingView.frame.origin.x, _viewPositionWhenKeyboardRevealed, self.movingView.frame.size.width, self.movingView.frame.size.height + _viewPositionWhenKeyboardRevealed);
        }
    };
    
    [UIView animateWithDuration:_animationDuration
                          delay:0.0
                        options:(_animationCurve << 16)
                     animations:animations
                     completion:nil];
    
    return YES;
}
- (BOOL)growingTextViewShouldEndEditing:(HPGrowingTextView *)growingTextView {
    
    void (^animations)() = ^() {
        _tweetView.frame = CGRectMake(_tweetView.frame.origin.x, _tweetView.frame.origin.y + 215, _tweetView.frame.size.width, _tweetView.frame.size.height);
        
        if (self.movingView.frame.origin.y != 0) {
            _viewPositionWhenKeyboardRevealed = self.movingView.frame.origin.y;
            self.movingView.frame = CGRectMake(self.movingView.frame.origin.x, 0, self.movingView.frame.size.width, self.movingView.frame.size.height - _viewPositionWhenKeyboardRevealed);
        } else {
            _viewPositionWhenKeyboardRevealed = 0;
        }
    };
    
    [UIView animateWithDuration:_animationDuration
                          delay:0.0
                        options:(_animationCurve << 16)
                     animations:animations
                     completion:nil];
    
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
    [self updateCharacterLabel];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height {
    
    float diff = (growingTextView.frame.size.height - height);
    CGRect r = _tweetView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	_tweetView.frame = r;
    
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

#pragma mark - Loading Wheel
-(void)showLoadingWheel:(NSNumber*)show
{
    BOOL showBool = [show boolValue];
    self.loadingWheel.hidden = !showBool;
    self.characterLabel.hidden = showBool;
    if (showBool) {
        [self.loadingWheel startAnimating];
    } else {
        [self.loadingWheel stopAnimating];
    }
}

#pragma mark - Alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        // Dismiss Tweet View Controller
        [self.navigationController popViewControllerAnimated:YES];
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
