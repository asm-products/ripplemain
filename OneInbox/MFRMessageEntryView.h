//
//  MFRMessageEntryView.h
//  Ripple
//
//  Created by Ed Rex on 28/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"

@interface MFRMessageEntryView : UIView

@property (nonatomic, retain) IBOutlet HPGrowingTextView *messageView;
@property (nonatomic, retain) IBOutlet UIButton* sendButton;

- (id)initWithFrame:(CGRect)frame title:(NSString*)title;

@end
