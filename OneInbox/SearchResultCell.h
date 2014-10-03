//
//  SearchResultCell.h
//  Ripple
//
//  Created by Ed Rex on 03/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchResultCell : UITableViewCell

@property (nonatomic, retain) UILabel* linkTitleLabel;
@property (nonatomic, retain) UILabel* urlLabel;
@property (nonatomic, retain) UITextView* blurbTextView;

@end
