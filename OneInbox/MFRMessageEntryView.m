//
//  MFRMessageEntryView.m
//  Ripple
//
//  Created by Ed Rex on 28/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRMessageEntryView.h"

@implementation MFRMessageEntryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame title:(NSString*)title
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendButton setTitle:title forState:UIControlStateNormal];
        _sendButton.frame = CGRectMake(260, 5, 50, 40);
        _sendButton.titleLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:16.0];
//        _sendButton.titleLabel.textColor = [UIColor blackColor];
        [_sendButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        
        _messageView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 10, 240, 40)];
        _messageView.isScrollable = NO;
        _messageView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        
        _messageView.minNumberOfLines = 1;
        _messageView.maxNumberOfLines = 6;
        // you can also set the maximum height in points with maxHeight
        // _messageView.maxHeight = 200.0f;
        _messageView.returnKeyType = UIReturnKeyDefault; //just as an example
        _messageView.font = [UIFont fontWithName:@"Titillium-Regular" size:14.0];
        _messageView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        _messageView.backgroundColor = [UIColor clearColor];
        _messageView.placeholder = @"Message";
        [_messageView.internalTextView setTintColor:[UIColor blackColor]];
        
        self.backgroundColor = [UIColor colorWithRed:236/255.0 green:240/255.0 blue:241/255.0 alpha:0.98];
        
        // _messageView.text = @"test\n\ntest";
        // _messageView.animateHeightChange = NO; //turns off animation
        
//        [self.view addSubview:containerView];
        
//        UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageEntryInputField.png"];
//        UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
//        UIImageView *entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
//        entryImageView.frame = CGRectMake(5, 0, 248, 40);
//        entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//        
//        UIImage *rawBackground = [UIImage imageNamed:@"MessageEntryBackground.png"];
//        UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
//        UIImageView *imageView = [[UIImageView alloc] initWithImage:background];
//        imageView.frame = CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height);
//        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        _messageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // view hierachy
//        [containerView addSubview:imageView];
//        [containerView addSubview:textView];
//        [containerView addSubview:entryImageView];
        [self addSubview:_messageView];
        [self addSubview:_sendButton];
        
//        UIImage *sendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
//        UIImage *selectedSendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
//        
//        UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        doneBtn.frame = CGRectMake(containerView.frame.size.width - 69, 8, 63, 27);
//        doneBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
//        [doneBtn setTitle:@"Done" forState:UIControlStateNormal];
//        
//        [doneBtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.4] forState:UIControlStateNormal];
//        doneBtn.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
//        doneBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
//        
//        [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        [doneBtn addTarget:self action:@selector(resignTextView) forControlEvents:UIControlEventTouchUpInside];
//        [doneBtn setBackgroundImage:sendBtnBackground forState:UIControlStateNormal];
//        [doneBtn setBackgroundImage:selectedSendBtnBackground forState:UIControlStateSelected];
//        [containerView addSubview:doneBtn];
//        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
