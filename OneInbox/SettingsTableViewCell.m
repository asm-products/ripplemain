//
//  SettingsTableViewCell.m
//  Ripple
//
//  Created by Ed Rex on 03/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#define CELL_DETAIL_LABEL_WIDTH 200

#import "SettingsTableViewCell.h"

@implementation SettingsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        _detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 35 - CELL_DETAIL_LABEL_WIDTH, 0, CELL_DETAIL_LABEL_WIDTH, self.contentView.frame.size.height)];
        _detailLabel.textAlignment = NSTextAlignmentRight;
        _detailLabel.font = [UIFont fontWithName:@"Titillium-Regular" size:16.0];
        _detailLabel.textColor = [UIColor darkGrayColor];
        [self.contentView addSubview:_detailLabel];
    }
    return self;
}

@end
