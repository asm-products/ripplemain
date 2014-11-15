//
//  RippleTextField.m
//  Ripple
//
//  Created by Ed Rex on 13/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "RippleTextField.h"

@implementation RippleTextField

-(id) initWithCoder:(NSCoder *)coder {
    
    self = [super initWithCoder:coder];
    if (self) {
        
        // Font
        [self setFont:[UIFont fontWithName:@"Titillium-Regular" size:18]];
        
        // Background image
        self.borderStyle = UITextBorderStyleNone;
        UIImage* backgroundImage = [UIImage imageNamed:@"TextField@2x.png"];
        [self setBackground:backgroundImage];
        
        // Padding
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
        self.leftView = paddingView;
        self.leftViewMode = UITextFieldViewModeAlways;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImage *fieldBGImage = [[UIImage imageNamed:@"Ripple120.png"] stretchableImageWithLeftCapWidth:20 topCapHeight:20];
        [self setBackground:fieldBGImage];
    }
    return self;
}

-(void)setPlaceholderText:(NSString*)placeholderText {
    
    // Placeholder color
    if ([self respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
        self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:@{NSForegroundColorAttributeName: color}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
}

@end
