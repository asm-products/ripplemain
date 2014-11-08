//
//  MFRLocalUniqueID.m
//  Ripple
//
//  Created by Ed Rex on 14/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRLocalUniqueID.h"

@implementation MFRLocalUniqueID

+(NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return (__bridge_transfer NSString *)uuidStringRef;
}

@end
