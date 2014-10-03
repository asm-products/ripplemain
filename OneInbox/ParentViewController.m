//
//  ParentViewController.m
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "ParentViewController.h"
#import "ContactsViewController.h"
#import "InboxViewController.h"
#import "MFRAnalytics.h"

@interface ParentViewController () {
    
    BOOL _usingGestures;
}

@end

@implementation ParentViewController

@synthesize pageViewController = _pageViewController;
@synthesize modelArray = _modelArray;
@synthesize composeNavigationController = _composeNavigationController;
@synthesize inboxNavigationController = _inboxNavigationController;
@synthesize contactsNavigationController = _contactsNavigationController;
@synthesize navigationControllers = _navigationControllers;

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
	
    self.modelArray = [NSMutableArray array];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
    //----------------------------
    // Set initial view controller
    //----------------------------
    _inboxNavigationController = (NonRotatingNavigationController*)[mainStoryboard
                                                                    instantiateViewControllerWithIdentifier: @"inboxNavigationController"];
    
    NSArray *viewControllers = [NSArray arrayWithObject:_inboxNavigationController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    self.pageViewController.view.frame = self.view.frame;
    
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    
    //--------------------------------
    // Add additional view controllers
    //--------------------------------
    _composeNavigationController = (NonRotatingNavigationController*)[mainStoryboard
                                                                      instantiateViewControllerWithIdentifier: @"composeNavigationController"];
    
    _contactsNavigationController = (NonRotatingNavigationController*)[mainStoryboard
                                                                           instantiateViewControllerWithIdentifier: @"contactsNavigationController"];
    
    NSArray *inboxViewControllers = self.inboxNavigationController.viewControllers;
    ((InboxViewController*)[inboxViewControllers objectAtIndex:0])->parentDelegate = self;
    
    NSArray *composeViewControllers = self.composeNavigationController.viewControllers;
    ((ComposeViewController*)[composeViewControllers objectAtIndex:0])->_originalLink = YES;
    ((ComposeViewController*)[composeViewControllers objectAtIndex:0])->parentDelegate = self;
    
    NSArray *contactsViewControllers = self.contactsNavigationController.viewControllers;
    ((ContactsViewController*)[contactsViewControllers objectAtIndex:0])->_sendingLink = NO;
    ((ContactsViewController*)[contactsViewControllers objectAtIndex:0])->parentDelegate = self;
    
    _navigationControllers = [NSMutableArray arrayWithObjects:_inboxNavigationController, _composeNavigationController, _contactsNavigationController, nil];
    
    _usingGestures = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Page View Controller delegate
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    int currentIndex = [_navigationControllers indexOfObject:(NonRotatingNavigationController*)viewController];
    if (currentIndex == 0)
    {
        return nil;
    }
    currentIndex--;
    NonRotatingNavigationController *contentViewController = [_navigationControllers objectAtIndex:currentIndex];
    
    [MFRAnalytics trackEvent:@"Page navigation - swiped"];
    
    return contentViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    int currentIndex = [_navigationControllers indexOfObject:(NonRotatingNavigationController*)viewController];
    if (currentIndex == 2)
    {
        return nil;
    }
    currentIndex++;
    NonRotatingNavigationController *contentViewController = [_navigationControllers objectAtIndex:currentIndex];
    
    [MFRAnalytics trackEvent:@"Page navigation - swiped"];
    
    return contentViewController;
}

#pragma mark - Parent view control delegate
-(void)navigateLeftToInbox {
    NSArray *viewControllers = [NSArray arrayWithObject:_inboxNavigationController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionReverse
                                       animated:YES
                                     completion:nil];
    
    [MFRAnalytics trackEvent:@"Page navigation - button used"];
}

-(void)navigateLeftToCompose {
    NSArray *viewControllers = [NSArray arrayWithObject:_composeNavigationController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionReverse
                                       animated:YES
                                     completion:nil];
    
    [MFRAnalytics trackEvent:@"Page navigation - button used"];
}

-(void)navigateRightToCompose {
    NSArray *viewControllers = [NSArray arrayWithObject:_composeNavigationController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
    
    [MFRAnalytics trackEvent:@"Page navigation - button used"];
}

-(void)navigateRightToContacts {
    NSArray *viewControllers = [NSArray arrayWithObject:_contactsNavigationController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
    
    [MFRAnalytics trackEvent:@"Page navigation - button used"];
}

-(void)addSwipeGesture {
    for (UIScrollView *view in self.pageViewController.view.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            view.scrollEnabled = YES;
        }
    }
}

-(void)removeSwipeGesture {
    for (UIScrollView *view in self.pageViewController.view.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            view.scrollEnabled = NO;
        }
    }
}

-(BOOL)shouldAutorotate {
    
    id currentInboxController = self.inboxNavigationController.topViewController;
    id currentComposeController = self.composeNavigationController.topViewController;
    
    // Allow rotation if web view controller displayed
    if (
        ([currentInboxController isKindOfClass:[WebViewController class]])
        ||
        ([currentComposeController isKindOfClass:[WebViewController class]])
        ) {
        return YES;
    }
    
    return NO;
}

-(void)displayInboxAndScrollToTop:(BOOL)inboxExists {
    // Display inbox
    NSArray *viewControllers = [NSArray arrayWithObject:_inboxNavigationController];
    [self.pageViewController setViewControllers:viewControllers
                                      direction:UIPageViewControllerNavigationDirectionReverse
                                       animated:NO
                                     completion:nil];
    
    if (inboxExists) {
        // Scroll to top of inbox
        NSArray *inboxViewControllers = self.inboxNavigationController.viewControllers;
        [((InboxViewController*)[inboxViewControllers objectAtIndex:0]) scrollToTopOfInbox];
    }
}

@end
