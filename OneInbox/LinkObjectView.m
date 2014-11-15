//
//  LinkObjectView.m
//  Ripple
//
//  Created by Ed Rex on 14/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "LinkObjectView.h"

@implementation LinkObjectView {
    
    BOOL _imageEditingToolsDisplayed;
}


-(id)initWithFrame:(CGRect)frame title:(NSString*)title delegate:(id)del {
    
    self = [super initWithFrame:frame];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"LinkObjectView" owner:self options:NULL];
        
        self.titleTextView.text = title;
        [self.titleTextView setFont:[UIFont fontWithName:@"Titillium-Regular" size:14.0]];
        
        self.smallTitleTextView.text = title;
        self.smallTitleTextView.hidden = YES;
        [self.smallTitleTextView setFont:[UIFont fontWithName:@"Titillium-Regular" size:14.0]];
        
        // Background image
        UIImage *img = [UIImage imageNamed:@"LinkRect.png"];
        UIImageView* imageView = [[UIImageView alloc] initWithImage:img];
        [self addSubview:imageView ];
        [self sendSubviewToBack:imageView ];
        
        // Tap gesture on view
        UITapGestureRecognizer* viewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:viewTap];
        
        // Tap gesture on title
        UITapGestureRecognizer* titleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self.titleTextView addGestureRecognizer:titleTap];
        
        [self addSubview:_view];
        
        _previousImageButton.hidden = YES;
        _nextImageButton.hidden = YES;
        _removeImageButton.hidden = YES;
        _editImageButton.hidden = YES;
        _imageEditingToolsDisplayed = NO;
        [self setLoading:NO];
        [self showSmallTitle:YES];
        
        delegate = del;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(IBAction)handleSingleTap:(id)sender {
    BOOL presentedFromSearch = NO;
    [delegate presentWebView:presentedFromSearch];
}

-(void)showSmallTitle:(BOOL)show {
    _smallTitleTextView.hidden = !show;
    _titleTextView.hidden = show;
}

-(IBAction)displayNextImage:(id)sender {
    [delegate displayNextImage];
}

-(IBAction)displayPreviousImage:(id)sender {
    [delegate displayPreviousImage];
}

-(IBAction)removeImage:(id)sender {
    [delegate removeImage];
    _linkImageView.hidden = YES;
    _previousImageButton.hidden = YES;
    _nextImageButton.hidden = YES;
    _removeImageButton.hidden = YES;
    _editImageButton.hidden = YES;
    [self setLoading:NO];
    [self showSmallTitle:NO];
}

-(IBAction)editImageButtonPressed:(id)sender {
    
    [self displayImageSelectionControls:!_imageEditingToolsDisplayed];
    _imageEditingToolsDisplayed = !_imageEditingToolsDisplayed;
}

-(void)displayImageSelectionControls:(BOOL)show {
    self.previousImageButton.hidden = !show;
    self.nextImageButton.hidden = !show;
    self.removeImageButton.hidden = !show;
}

-(void)setLoading:(BOOL)loading {
    _imageLoadingWheel.hidden = !loading;
    if (loading) {
        [_imageLoadingWheel startAnimating];
    } else {
        [_imageLoadingWheel stopAnimating];
    }
}

@end
