//
//  MFRLoginViewController.m
//  Ripple
//
//  Created by Ed Rex on 04/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRLoginViewController.h"

@interface MFRLoginViewController ()

@end

@implementation MFRLoginViewController

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
    
    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RippleLogo200"]]];
}

@end
