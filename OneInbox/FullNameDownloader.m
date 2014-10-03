//
//  FullNameDownloader.m
//  Ripple
//
//  Created by Ed Rex on 06/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "FullNameDownloader.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"

@interface FullNameDownloader ()
//@property (nonatomic, strong) NSMutableData *activeDownload;
//@property (nonatomic, strong) NSURLConnection *fullNameConnection;
@end


@implementation FullNameDownloader

#pragma mark

- (void)startDownload
{
    [self performSelectorInBackground:@selector(downloadFullName) withObject:nil];
    
//    self.activeDownload = [NSMutableData data];
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_imageURL]];
//    
//    // alloc+init and start an NSURLConnection; release on completion/failure
//    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//    
//    self.imageConnection = conn;
}

-(void)downloadFullName {
    
    PFQuery* userQuery = [PFQuery queryWithClassName:@"_User"];
    [userQuery whereKey:@"objectId" equalTo:self.username];
    PFObject* user = [userQuery getFirstObject];
    if (user) {
        NSString* fullName = [user objectForKey:@"additional"];
        
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate storeFullName:fullName forUsername:self.username];
        
        // Call our delegate and tell it that our icon is ready for display
        if (self.completionHandler)
            self.completionHandler();
    }
}

- (void)cancelDownload
{
//    [self.imageConnection cancel];
//    self.imageConnection = nil;
//    self.activeDownload = nil;
}

#pragma mark - NSURLConnectionDelegate

//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    [self.activeDownload appendData:data];
//}
//
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
//{
//	// Clear the activeDownload property to allow later attempts
//    self.activeDownload = nil;
//    
//    // Release the connection now that it's finished
//    self.imageConnection = nil;
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    // Set appIcon and clear temporary data/image
//    UIImage *image = [[UIImage alloc] initWithData:self.activeDownload];
//    
//    if (image) {
//        if (image.size.width != kAppIconSize || image.size.height != kAppIconSize)
//        {
//            // Store small image
//            CGSize itemSize = CGSizeMake(kAppIconSize, kAppIconSize);
//            
//            UIImage* croppedImage = [MFRImageResizer resizeAndCropImage:image toSize:itemSize];
//            
//            AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//            [appDelegate storeImage:croppedImage forURL:_imageURL];
//            
//            // Store large image
//            UIImage* largerImage = [MFRImageResizer resizeAndCropImage:image toSize:CGSizeMake(86.0, 86.0)];
//            [appDelegate storeLargeImage:largerImage forURL:_imageURL];
//        }
//        else
//        {
//            AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//            [appDelegate storeImage:image forURL:_imageURL];
//        }
//    }
//    
//    self.activeDownload = nil;
//    
//    // Release the connection now that it's finished
//    self.imageConnection = nil;
//    
//    // call our delegate and tell it that our icon is ready for display
//    if (self.completionHandler)
//        self.completionHandler();
//}

@end

