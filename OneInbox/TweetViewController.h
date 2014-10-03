//
//  TweetViewController.h
//  Ripple
//
//  Created by Ed Rex on 07/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFRMessageEntryView.h"
#import "WebEnabledViewController.h"

@interface TweetViewController : WebEnabledViewController <UIAlertViewDelegate>

@property (nonatomic, retain) MFRMessageEntryView* tweetView;
@property (nonatomic, retain) IBOutlet UILabel* characterLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* loadingWheel;

@end
