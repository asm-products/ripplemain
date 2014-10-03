//
//  MultipleFullNamesDownloader.h
//  Ripple
//
//  Created by Ed Rex on 06/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MultipleFullNamesDownloader : NSObject

@property (nonatomic, strong) NSMutableArray* usernames;
@property (nonatomic, copy) void (^completionHandler)(void);

- (void)startDownload;
- (void)cancelDownload;

@end
