//
//  TwitterViewController.h
//  Ripple
//
//  Created by Ed Rex on 06/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterViewController : UIViewController {
    
    @public
    BOOL shouldProgressToTweetView;
    NSURL* _url;
    
}

@property (nonatomic, retain) IBOutlet UILabel* notConnectedLabel;
@property (nonatomic, retain) IBOutlet UIButton* linkButton;
@property (nonatomic, retain) IBOutlet UIButton* unlinkButton;
@property (nonatomic, retain) IBOutlet UILabel* usernameLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* loadingWheel;

-(IBAction)connectToTwitter:(id)sender;
-(IBAction)disconnectToTwitter:(id)sender;

@end
