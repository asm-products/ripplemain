//
//  MFRDateTime.h
//  Ripple
//
//  Created by Ed Rex on 27/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFRDateTime : NSObject

//+(NSString*)getCurrentDateTime;
+(NSDate*)getCurrentGMTDateTime;
+(NSString*)getCurrentGMTDateTimeString;

+(NSString*)convertNSDateToString:(NSDate*)date;
+(NSDate*)convertStringToNSDate:(NSString*)dateString;

+(NSDate*)getLocalDateTimeFromGMTDateTime:(NSDate*)gmtDate;
+(NSDate*)getLocalDateTimeFromGMTDateString:(NSString*)dateString;

@end
