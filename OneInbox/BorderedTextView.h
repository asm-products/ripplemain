//
//  BorderedTextView.h
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BorderedTextView : UITextView

@property (nonatomic, retain) UILabel *placeHolderLabel;
@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
