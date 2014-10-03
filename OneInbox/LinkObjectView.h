//
//  LinkObjectView.h
//  Ripple
//
//  Created by Ed Rex on 14/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ShowWebViewDelegate
-(void)presentWebView:(BOOL)presentedFromSearch;
-(void)displayNextImage;
-(void)displayPreviousImage;
-(void)removeImage;
@end

@interface LinkObjectView : UIView {
    
    @public
    id <ShowWebViewDelegate> delegate;
}

@property (nonatomic, retain) IBOutlet UIView* view;
@property (nonatomic, retain) IBOutlet UITextView* titleTextView;
@property (nonatomic, retain) IBOutlet UITextView* smallTitleTextView;
@property (nonatomic, retain) IBOutlet UIImageView* linkImageView;
@property (nonatomic, retain) IBOutlet UIButton* previousImageButton;
@property (nonatomic, retain) IBOutlet UIButton* nextImageButton;
@property (nonatomic, retain) IBOutlet UIButton* removeImageButton;
@property (nonatomic, retain) IBOutlet UIButton* editImageButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* imageLoadingWheel;

-(id)initWithFrame:(CGRect)frame title:(NSString*)title delegate:(id)del;

-(void)showSmallTitle:(BOOL)show;

-(IBAction)displayNextImage:(id)sender;
-(IBAction)displayPreviousImage:(id)sender;
-(IBAction)removeImage:(id)sender;
-(IBAction)editImageButtonPressed:(id)sender;
-(void)setLoading:(BOOL)loading;

@end
