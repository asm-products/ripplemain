//
//  NonRotatingNavigationController.m
//  Ripple
//
//  Created by Ed Rex on 23/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "NonRotatingNavigationController.h"
#import "WebViewController.h"

@interface NonRotatingNavigationController ()

@end

@implementation NonRotatingNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// NB This is no longer called now that NonRotatingNavigationControllers are stored in the ParentViewController
-(BOOL)shouldAutorotate {
    
    id currentViewController = self.topViewController;
    
    // Allow rotation if web view controller displayed
    if ([currentViewController isKindOfClass:[WebViewController class]]) {
        return YES;
    }
    
    return NO;
}

@end
