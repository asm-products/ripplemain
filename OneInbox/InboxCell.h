//
//  InboxCell.h
//  Ripple
//
//  Created by Ed Rex on 21/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFRLocalMessageThread.h"

@interface InboxCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel* senderLabel;
@property (nonatomic, retain) IBOutlet UILabel* messageLabel;
@property (nonatomic, retain) IBOutlet UILabel* dateLabel;
@property (nonatomic, retain) IBOutlet UIImageView* unreadImageView;
@property (nonatomic, retain) IBOutlet UIImageView* linkImageView;
@property (nonatomic, retain) UIActivityIndicatorView* sendingWheel;

-(void)markAsUnread:(BOOL)unread;
-(void)displayLinkImage:(UIImage*)image;
-(void)displayFullName:(NSString*)fullName;
-(void)displayPlaceholderName;
-(void)removeLinkImageAndMoveText;
-(void)setSendingStatus:(MFRLocalMessageStatus)sendingStatus;

@end
