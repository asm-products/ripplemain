//
//  MFRAnalytics.m
//  Ripple
//
//  Created by Ed Rex on 24/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRAnalytics.h"
#import <Parse/Parse.h>

@implementation MFRAnalytics

+(void)trackAppOpenedWithLaunchOptions:(NSDictionary*)launchOptions {
    
    if (
        ![PFUser currentUser]
        ||
        (
         ![[PFUser currentUser].username isEqualToString:@"edrex"]
         &&
         ![[PFUser currentUser].username isEqualToString:@"edrexsimulator"]
         &&
         ![[PFUser currentUser].username isEqualToString:@"edrexipad"]
         )
        ) {
        [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    }
}

+(void)trackEvent:(NSString*)event {
    
    if (
        ![PFUser currentUser]
        ||
        (
         ![[PFUser currentUser].username isEqualToString:@"edrex"]
         &&
         ![[PFUser currentUser].username isEqualToString:@"edrexsimulator"]
         &&
         ![[PFUser currentUser].username isEqualToString:@"edrexipad"]
         )
        ) {
        [PFAnalytics trackEvent:event];
    }
}

+(void)trackEvent:(NSString*)event dimensions:(NSDictionary*)dimensions {
    
    if (
        ![PFUser currentUser]
        ||
        (
         ![[PFUser currentUser].username isEqualToString:@"edrex"]
         &&
         ![[PFUser currentUser].username isEqualToString:@"edrexsimulator"]
         &&
         ![[PFUser currentUser].username isEqualToString:@"edrexipad"]
         )
        ) {
        [PFAnalytics trackEvent:event dimensions:dimensions];
    }
}

@end
