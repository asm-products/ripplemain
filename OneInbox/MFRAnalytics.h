//
//  MFRAnalytics.h
//  Ripple
//
//  Created by Ed Rex on 24/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFRAnalytics : NSObject

+(void)trackAppOpenedWithLaunchOptions:(NSDictionary*)launchOptions;
+(void)trackEvent:(NSString*)event;
+(void)trackEvent:(NSString*)event dimensions:(NSDictionary*)dimensions;

@end
