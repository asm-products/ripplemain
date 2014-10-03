//
//  HistoryViewController.m
//  Frisbee
//
//  Created by Ed Rex on 12/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "HistoryViewController.h"
#import "AppDelegate.h"

@interface HistoryViewController ()

@end

@implementation HistoryViewController

@synthesize historyTableView = _historyTableView;
@synthesize sendingWheel = _sendingWheel;
@synthesize sendingLabel = _sendingLabel;

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
    
    [self showSendingWheel:NO];
    [self showSendingLabel:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource methods and related helpers
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MessageCell";
    
    UITableViewCell* cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = @"Test";
//    cell.textLabel.textColor = [UIColor redColor];
    
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0];
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Swapping views
-(IBAction)pushInboxViewController
{
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showInboxNavigationController];
}

#pragma mark - Updating view for sending status
-(void)displaySending {
    _sendingLabel.text = @"Sending...";
    [self showSendingLabel:YES];
    [self showSendingWheel:YES];
}

-(void)informSuccess:(NSNumber*)success {
    [self showSendingWheel:NO];
    if ([success boolValue] == YES) {
        _sendingLabel.text = @"Link sent!";
    } else {
        _sendingLabel.text = @"Sending failed";
    }
    [self performSelector:@selector(showSendingLabel:) withObject:NO afterDelay:2];
}

-(void)showSendingWheel:(BOOL)show {
    
    if (show) {
        [_sendingWheel startAnimating];
    } else {
        [_sendingWheel stopAnimating];
    }
    _sendingWheel.hidden = !show;
}

-(void)showSendingLabel:(BOOL)show {
    _sendingLabel.hidden = !show;
}

@end
