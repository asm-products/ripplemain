//
//  MultipleFullNamesDownloader.m
//  Ripple
//
//  Created by Ed Rex on 06/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MultipleFullNamesDownloader.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"

@implementation MultipleFullNamesDownloader

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
    [userQuery whereKey:@"objectId" containedIn:self.usernames];
    NSArray* userIDsToStore = [userQuery findObjects];
    
    if ([userIDsToStore count] > 0) {
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        for (PFObject* user in userIDsToStore) {
            NSString* fullName = [user objectForKey:@"additional"];
            NSString* userID = user.objectId;
            [appDelegate storeFullName:fullName forUsername:userID];
        }
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

@end
