//
//  ParentViewController.h
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NonRotatingNavigationController.h"
#import "ComposeViewController.h"

@interface ParentViewController : UIViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate, ParentViewControlDelegate>

@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, strong) NSMutableArray* navigationControllers;

@property (nonatomic, retain) NonRotatingNavigationController* composeNavigationController;
@property (nonatomic, retain) NonRotatingNavigationController* inboxNavigationController;
@property (nonatomic, retain) NonRotatingNavigationController* contactsNavigationController;

-(void)displayInboxAndScrollToTop:(BOOL)inboxExists;

@end
