//
//  WebEnabledViewController.m
//  OneInbox
//
//  Created by Ed Rex on 03/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "WebEnabledViewController.h"
#import "AppDelegate.h"
#import "NSString+HTML.h"
#import "ComposeViewController.h"
#import "MFRAnalytics.h"
#import "MFRImageResizer.h"

#define SEARCH_ALLOWED YES

@interface WebEnabledViewController ()<NSURLConnectionDelegate> {
    
    BOOL _hasTextField;
    BOOL _imageHasBeenRemoved;
}

@end

@implementation WebEnabledViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    if (
        [self isKindOfClass:[ComposeViewController class]]
        &&
        _originalLink
        ) {
        _hasTextField = YES;
    } else {
        _hasTextField = NO;
    }
    
    if (!_hasTextField) {
        _offsetForTextField = 80;
    } else {
        _offsetForTextField = 0;
    }
    
    _imageHasBeenRemoved = NO;
}

#pragma mark - Swapping views
-(void)presentWebView:(BOOL)presentedFromSearch
{
    CATransition *animation = [CATransition animation];
    [animation setDuration:2];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromTop];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    UIStoryboard*  sb = [UIStoryboard storyboardWithName:@"Main"
                                                  bundle:nil];
    WebViewController* vc = [sb instantiateViewControllerWithIdentifier:@"WebViewController"];
    vc->url = _url;
    vc->html = _html;
    vc->title = _linkTitle;
    vc.linkObject = _linkObject;
    vc->_originalLink = _originalLink;
    vc->_displayedFromSearch = presentedFromSearch;
    if (presentedFromSearch) {
        vc->searchDelegate = self;
    }
    
    UINavigationController *nav = [[UINavigationController alloc]
                                   initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
    
    //    [self.navigationController pushViewController:vc animated:YES];
//    [self presentViewController:vc animated:YES completion:nil];
    [[vc.view layer] addAnimation:animation forKey:@"SwitchToView1"];
}

#pragma mark - Accessing and reading URL/HTML
-(void)getLinkDataFromURLString:(NSString*)link
{
    BOOL searchRequired = YES;
    //-----------------------------------------
    // Check whether this is a link or a search
    //-----------------------------------------
    if (
        !SEARCH_ALLOWED
        ||
        [self textIsLink:link]
        ) {
        //--------------------------------
        // Check the link starts with http
        //--------------------------------
        NSString* httpLink = [self getHttpLinkFromLink:link];
        
        //-------------------
        // Get the link's URL
        //-------------------
        _url = [self getURLFromString:httpLink];
        
        //---------------------
        // Get the link's title
        //---------------------
        _html = [self getHTMLFromURL:_url];
        if (_html){
            searchRequired = NO;
            _linkTitle = [self getTitleFromHTML:_html];
            if (_linkTitle == nil) {
                _linkTitle = [NSString stringWithString:httpLink];
            }
        }
        else{
            _linkTitle = nil;
        }
    }
}

-(BOOL)textIsLink:(NSString*)text {
    // Figure out whether the link is a web address or not
    if (
        ([text rangeOfString:@"."].location != NSNotFound)
        &&
        ([text rangeOfString:@" "].location == NSNotFound)
        ) {
        return YES;
    }
    return NO;
}

-(NSString*)getHttpLinkFromLink:(NSString*)link {
    
    if (
        ![link hasPrefix:@"http://"]
        &&
        ![link hasPrefix:@"https://"]
        ) {
        NSString *updatedLink = [NSString stringWithFormat:@"http://%@", link];
        return updatedLink;
    } else {
        return link;
    }
}

-(NSURL*)getURLFromString:(NSString*)string
{
    NSString* hashlessURL = [self removeHashFromURLStringIfNecessary:string];
    
    NSString *escapedUrl = [hashlessURL
                            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    
    
    NSURL *URL = [NSURL URLWithString:escapedUrl];
    
    return URL;
}

-(NSString*)removeHashFromURLStringIfNecessary:(NSString*)urlString {
    
    NSString* hashlessString;
    NSScanner *theScanner = [NSScanner scannerWithString:urlString];
    while (![theScanner isAtEnd]) {
        [theScanner scanUpToString:@"#" intoString:&hashlessString];
        if (![theScanner isAtEnd]) {
            // Hash found, so return string up to hash
            return hashlessString;
        }
    }
    return urlString;
}

-(NSString*)getHTMLFromURL:(NSURL*)url
{
    NSError *error;
    NSString *HTML = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
    if (!error){
        return HTML;
    }
    else{
        return nil;
    }
}

-(NSString*)getTitleFromHTML:(NSString*)html
{
    NSArray* components = [html componentsSeparatedByString:@"<title>"];
    if ([components count] > 1) {
        NSArray* reducedComponents = [[components objectAtIndex:1] componentsSeparatedByString:@"</title>"];
        if ([reducedComponents count] > 0) {
            NSString* plainTextTitle = [[reducedComponents objectAtIndex:0] stringByConvertingHTMLToPlainText];
            return plainTextTitle;
        }
    }
    return nil;
}

-(void)clearLinkData
{
    _url = nil;
    _html = nil;
    _linkTitle = nil;
}

#pragma mark - Display
-(void)hideLinkElements
{
    [self.linkObjectView removeFromSuperview];
    _linkObjectView = nil;
}

#pragma mark - Fetching and displaying image
-(void)fetchImageForLink {
    
    _imageHasBeenRemoved = NO;
    
    [_linkObjectView setLoading:YES];
    [self getImageURLOptions];
    
    if (
        [_linkObject hasPossibleHTMLImageURLs]
        &&
        !_imageHasBeenRemoved
        ) {
        
        // Display first possible image url
        [self displayImageFromURL:[_linkObject getSelectedPossibleHTMLImageURL]];
        
        // Display image selection buttons
//        [self performSelectorOnMainThread:@selector(displayImageSelectionControls) withObject:nil waitUntilDone:NO];
    } else {
        // No image, so hide link image view
        [_linkObjectView setLoading:NO];
        _linkObjectView.linkImageView.hidden = YES;
        _linkObjectView.removeImageButton.hidden = YES;
        _linkObjectView.editImageButton.hidden = YES;
        [_linkObjectView showSmallTitle:NO];
    }
}

-(void)displayImageFromURL:(NSURL*)imageURL {
    
    // Save image url on link object
    [_linkObject setImageURL:imageURL];
    
    UIImage* croppedImage;
    
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIImage* storedImage = [appDelegate getLargeImage:[imageURL absoluteString]];
    if (storedImage) {
        // Image already stored, so fetch from App Delegate
        croppedImage = storedImage;
    } else {
        // Image not already stored, so get from URL
        UIImage* linkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
        
        croppedImage = [MFRImageResizer resizeAndCropImage:linkImage toSize:CGSizeMake(_linkObjectView.linkImageView.frame.size.width, _linkObjectView.linkImageView.frame.size.height)];
    }
    
    [self performSelectorOnMainThread:@selector(updateLinkImage:) withObject:croppedImage waitUntilDone:NO];
}

-(void)displayNextImage {
    [_linkObject moveToNextPossibleImage];
    [self displayImageFromURL:[_linkObject getSelectedPossibleHTMLImageURL]];
}

-(void)displayPreviousImage {
    [_linkObject moveToPreviousPossibleImage];
    [self displayImageFromURL:[_linkObject getSelectedPossibleHTMLImageURL]];
}

-(void)removeImage {
    [_linkObject setImageURL:nil];
    _imageHasBeenRemoved = YES;
}

-(void)updateLinkImage:(UIImage*)image {
    
    [_linkObjectView setLoading:NO];
    
    // Display image
    _linkObjectView.linkImageView.image = image;
    
    // Move text
    [_linkObjectView showSmallTitle:YES];
}

-(void)getImageURLOptions {
    
    [self getOGImageFromHTML:_html];
    if (![_linkObject hasPossibleHTMLImageURLs]) {
        // No OG image, so get html images on this thread
        [self getHTMLImagesFromHTML:_html];
    } else {
        // OG image exists, so get html images in the background
        [self performSelectorInBackground:@selector(getHTMLImagesFromHTML:) withObject:_html];
    }
}

-(void)getOGImageFromHTML:(NSString*)html {
    
    BOOL ogImageFound = NO;
    
    // Prepare regular expression to find text
    NSError *error   = nil;
    NSRegularExpression *regexp =
    [NSRegularExpression regularExpressionWithPattern:
     @"<meta property='og:image' content=\".+\""
                                              options:0
                                                error:&error];
    
    @try {
        // Find by regular expression
        NSTextCheckingResult *match =
        [regexp firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
        
        // Get the first result
        NSRange resultRange = [match rangeAtIndex:0];
        NSLog(@"match=%@", [html substringWithRange:resultRange]);
        
        if (match) {
            
            // Get the og:image URL from the find result
            NSRange urlRange = NSMakeRange(resultRange.location + 35, resultRange.length - 35 - 1);
            NSURL* urlOgImage = [NSURL URLWithString:[html substringWithRange:urlRange]];
            
            [_linkObject addPossibleImageURL:urlOgImage];
            
            ogImageFound = YES;
        }
    }
    @catch (NSException* e) {
        NSLog(@"Exception: %@", e);
    }
    @finally {
        NSLog(@"finally");
    }
    
    if (!ogImageFound) {
        // Prepare regular expression to find text
        NSError *errorTwo   = nil;
        NSRegularExpression *regexpTwo =
        [NSRegularExpression regularExpressionWithPattern:
         @"<meta property=\"og:image\" content=\".+\""
                                                  options:0
                                                    error:&errorTwo];
        
        @try {
            // Find by regular expression
            NSTextCheckingResult *matchTwo =
            [regexpTwo firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
            
            // Get the first result
            NSRange resultRangeTwo = [matchTwo rangeAtIndex:0];
            NSLog(@"match=%@", [html substringWithRange:resultRangeTwo]);
            
            if (matchTwo) {
                
                // Get the og:image URL from the find result
                NSRange urlRangeTwo = NSMakeRange(resultRangeTwo.location + 35, resultRangeTwo.length - 35 - 1);
                NSURL* urlOgImageTwo = [NSURL URLWithString:[html substringWithRange:urlRangeTwo]];
                
                [_linkObject addPossibleImageURL:urlOgImageTwo];
            }
        }
        @catch (NSException* e) {
            NSLog(@"Exception: %@", e);
        }
        @finally {
            NSLog(@"finally");
        }
    }
}

-(void*)getHTMLImagesFromHTML:(NSString*)html {
    
    //-------------------------------------
    // Get all image urls from the web page
    //-------------------------------------
    NSMutableArray* imageURLs = [NSMutableArray array];
    NSScanner *theScanner = [NSScanner scannerWithString:html];
    while (![theScanner isAtEnd]) {
        [theScanner scanUpToString:@"<img" intoString:nil];
        if (![theScanner isAtEnd]) {
            
            NSScanner* endScanner = [NSScanner scannerWithString:html];
            [endScanner setScanLocation:[theScanner scanLocation]];
            NSString* countingEndString;
            NSCharacterSet *endCharSet = [NSCharacterSet characterSetWithCharactersInString:@">"];
            [endScanner scanUpToCharactersFromSet:endCharSet intoString:&countingEndString];
            
            NSScanner* srcScanner = [NSScanner scannerWithString:html];
            [srcScanner setScanLocation:[theScanner scanLocation]];
            NSString* countingSrcString;
            [srcScanner scanUpToString:@"src" intoString:&countingSrcString];
            
            if ([countingSrcString length] < [countingEndString length]) {
                // The image has a src, so save it
                [theScanner scanUpToString:@"src" intoString:nil];
                if (![theScanner isAtEnd]) {
                    NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
                    [theScanner scanUpToCharactersFromSet:charset intoString:nil];
                    [theScanner scanCharactersFromSet:charset intoString:nil];
                    NSString *urlString = nil;
                    [theScanner scanUpToCharactersFromSet:charset intoString:&urlString];
                    if (urlString) {
                        NSURL* url = [NSURL URLWithString:urlString];
                        if (url) {
                            [imageURLs addObject:url];
                        }
                    }
                }
            } else {
                // The image has no src, so skip it
                [theScanner scanUpToString:@">" intoString:nil];
            }
        }
    }
    
    if ([imageURLs count] > 0) {
        //---------------------
        // Order images by size
        //---------------------
        NSMutableArray* orderedImageURLs = [self orderArrayOfImageURLsBySize:imageURLs];
        
        [_linkObject addPossibleImageURLs:orderedImageURLs];
    }
    
    return nil;
}

-(NSMutableArray*)orderArrayOfImageURLsBySize:(NSMutableArray*)originalURLs {
    
    NSMutableArray* imageDictionaries = [NSMutableArray array];
    for (int i = 0; i < [originalURLs count]; i++) {
        
        NSURL* url = [originalURLs objectAtIndex:i];
        UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        if (image) {
            NSNumber* imageArea = [NSNumber numberWithFloat:image.size.width * image.size.height];
            NSDictionary* imageDict = [[NSDictionary alloc] initWithObjectsAndKeys:imageArea, @"Area", [url absoluteString], @"URL", nil];
            [imageDictionaries addObject:imageDict];
        }
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"Area"  ascending:NO];
    NSArray* sortedImageURLDictionaries = [imageDictionaries sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    NSMutableArray* sortedImageURLs = [NSMutableArray array];
    for (NSDictionary* dict in sortedImageURLDictionaries) {
        [sortedImageURLs addObject:[NSURL URLWithString:[dict objectForKey:@"URL"]]];
    }
    
    // TEMPORARY:
    return sortedImageURLs;
}

@end
