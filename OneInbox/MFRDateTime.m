//
//  MFRDateTime.m
//  Ripple
//
//  Created by Ed Rex on 27/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRDateTime.h"

@implementation MFRDateTime

//--------------------
// Return current time
//--------------------
//+(NSString*)getCurrentDateTime
//{
//    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
//    [DateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZZZ"];
//    NSString* dateString = [NSString stringWithFormat:@"%@",[DateFormatter stringFromDate:[NSDate date]]];
//    return dateString;
//}

+(NSDate*)getCurrentGMTDateTime
{
    NSDate* localDate = [NSDate date];
    NSTimeZone *tz = [NSTimeZone localTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate:localDate];
    NSDate* gmtDateTime = [NSDate dateWithTimeInterval:seconds sinceDate:localDate];
    return gmtDateTime;
}

+(NSString*)getCurrentGMTDateTimeString
{
    NSDate* currentGMTTime = [self getCurrentGMTDateTime];
    NSString* timeString = [self convertNSDateToString:currentGMTTime];
    return timeString;
}

+(NSString*)convertNSDateToString:(NSDate*)date
{
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* dateString = [NSString stringWithFormat:@"%@",[DateFormatter stringFromDate:date]];
    return dateString;
}

+(NSDate*)convertStringToNSDate:(NSString*)dateString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate* date = [formatter dateFromString:dateString];
    return date;
}

//-------------------------------
// Convert GMT time to local time
//-------------------------------
+(NSDate*)getLocalDateTimeFromGMTDateTime:(NSDate*)gmtDate
{
    NSTimeZone* tz = [NSTimeZone localTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:gmtDate];
    NSDate* localDate = [NSDate dateWithTimeInterval:seconds sinceDate:gmtDate];
    
    return localDate;
}

+(NSDate*)getLocalDateTimeFromGMTDateString:(NSString*)dateString
{
    // Get the date in its original form
    NSDate* date = [self convertStringToNSDate:dateString];
    
    NSDate* localDate = [self getLocalDateTimeFromGMTDateTime:date];
    
//    NSTimeZone* tz = [NSTimeZone localTimeZone];
//    NSInteger seconds = [tz secondsFromGMTForDate:date];
//    NSDate* localDate = [NSDate dateWithTimeInterval:seconds sinceDate:date];
    
    return localDate;
}

@end
