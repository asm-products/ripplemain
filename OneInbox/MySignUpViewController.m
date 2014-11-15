//
//  MySignUpViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MySignUpViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MySignUpViewController ()
@property (nonatomic, strong) UIImageView *fieldsBackground;
@end

@implementation MySignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    // Change "Additional" textfield to match our use - Full name
    [self.signUpView.additionalField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    if ([self.signUpView.additionalField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor* color = [UIColor lightGrayColor];
        self.signUpView.additionalField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Name" attributes:@{NSForegroundColorAttributeName: color}];
    } else {
        NSLog(@"Cannot set signup view placeholder colour, because deployment target is earlier than iOS 6.0");
        [self.signUpView.additionalField setPlaceholder:@"Name"];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
