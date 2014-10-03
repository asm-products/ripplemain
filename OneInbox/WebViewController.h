//
//  WebViewController.h
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LinkObject.h"
//#include "ContactsViewController.h"

@protocol SearchDelegate
-(void)selectSearchResultWithURL:(NSURL*)url title:(NSString*)title html:(NSString*)html;
@end

@interface WebViewController : UIViewController<UIWebViewDelegate, UINavigationBarDelegate, UIWebViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>{
    @public
    NSURL* url;
    NSString* html;
    NSString* title;
    BOOL _originalLink;
    BOOL _displayedFromSearch;
    id <SearchDelegate> searchDelegate;
}

@property (strong, nonatomic) IBOutlet UIWebView *linkWebView;
@property (strong, nonatomic) LinkObject* linkObject;
@property (strong, nonatomic) IBOutlet UIToolbar* toolbar;
@property (strong, nonatomic) UIBarButtonItem* webBackButton;
@property (strong, nonatomic) UIBarButtonItem* webForwardButton;
@property (strong, nonatomic) UIBarButtonItem* shareButton;
@property (strong, nonatomic) UIActivityIndicatorView* loadingWheel;

-(IBAction)backButtonPressed:(id)sender;
-(IBAction)forwardButtonPressed:(id)sender;

-(IBAction)sendButtonPressed:(id)sender;
//-(IBAction)discardButtonPressed:(id)sender;

@end
