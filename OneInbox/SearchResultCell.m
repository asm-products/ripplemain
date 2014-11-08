//
//  SearchResultCell.m
//  Ripple
//
//  Created by Ed Rex on 03/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "SearchResultCell.h"

#define LABEL_X_ORIGIN 22.0
#define TITLE_LABEL_Y_ORIGIN 5.0
#define URL_LABEL_Y_ORIGIN 30.0
#define TITLE_LABEL_WIDTH 240
#define URL_LABEL_WIDTH 240
#define LABEL_HEIGHT 15.0

@implementation SearchResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.linkTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_X_ORIGIN, TITLE_LABEL_Y_ORIGIN, TITLE_LABEL_WIDTH, LABEL_HEIGHT)];
        self.urlLabel = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_X_ORIGIN, URL_LABEL_Y_ORIGIN, URL_LABEL_WIDTH, LABEL_HEIGHT)];
        
        // Configure Main Label
        [self.linkTitleLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:16.0]];
        [self.linkTitleLabel setTextAlignment:NSTextAlignmentLeft];
        [self.linkTitleLabel setTextColor:[UIColor blackColor]];
        [self.linkTitleLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        
        [self.urlLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:14.0]];
        [self.urlLabel setTextAlignment:NSTextAlignmentLeft];
        [self.urlLabel setTextColor:[UIColor lightGrayColor]];
        [self.urlLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        
        // Add UI elements to Content View
        [self.contentView addSubview:self.linkTitleLabel];
        [self.contentView addSubview:self.urlLabel];
        
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    return self;
}

@end
