//
//  WebEnabledViewController.h
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LinkObject.h"
//#import "ContactsViewController.h"
#import "LinkObjectView.h"
#import "WebViewController.h"

@interface WebEnabledViewController : UIViewController<ShowWebViewDelegate, SearchDelegate> {
    
    @public
    NSURL* _url;
    NSString* _html;
    NSString* _linkTitle;
    BOOL _originalLink;
    CGFloat _offsetForTextField;
}

@property (nonatomic, retain) IBOutlet UIView* movingView;
@property (nonatomic, retain) IBOutlet LinkObjectView* linkObjectView;
@property (nonatomic, retain) LinkObject* linkObject;

-(NSURL*)getURLFromString:(NSString*)string;
-(void)getLinkDataFromURLString:(NSString*)link;
-(void)clearLinkData;
-(void)hideLinkElements;

-(void)fetchImageForLink;
-(void)displayImageFromURL:(NSURL*)imageURL;

@end
